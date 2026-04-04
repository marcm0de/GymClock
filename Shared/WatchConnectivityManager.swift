import Foundation
import WatchConnectivity
import Combine

/// Manages bidirectional communication between iPhone and Apple Watch
/// Handles immediate messaging, background transfers, and application context
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    @Published var isActivated = false
    @Published var lastReceivedMessage: [String: Any] = [:]
    @Published var receivedSessions: [WorkoutSessionTransfer] = []
    
    /// Callbacks for handling received data
    var onSessionReceived: ((WorkoutSessionTransfer) -> Void)?
    var onGoalUpdated: ((Int) -> Void)?
    var onPreferencesUpdated: (([String: Any]) -> Void)?
    
    private let session: WCSession
    
    private override init() {
        self.session = WCSession.default
        super.init()
    }
    
    // MARK: - Activation
    
    func activate() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity not supported on this device")
            return
        }
        session.delegate = self
        session.activate()
    }
    
    // MARK: - Sending Data
    
    /// Send an immediate message (requires counterpart to be reachable)
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard session.activationState == .activated else {
            print("WCSession not activated, cannot send message")
            return
        }
        guard session.isReachable else {
            print("Watch/Phone not reachable, falling back to application context")
            updateApplicationContext(message)
            return
        }
        
        session.sendMessage(message, replyHandler: replyHandler) { [weak self] error in
            print("Failed to send message: \(error.localizedDescription)")
            // Fallback to application context
            self?.updateApplicationContext(message)
        }
    }
    
    /// Update application context (latest state, delivered when counterpart wakes)
    func updateApplicationContext(_ context: [String: Any]) {
        guard session.activationState == .activated else {
            print("WCSession not activated, cannot update application context")
            return
        }
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error.localizedDescription)")
        }
    }
    
    /// Transfer user info (queued, guaranteed delivery)
    func transferUserInfo(_ userInfo: [String: Any]) {
        guard session.activationState == .activated else {
            print("WCSession not activated, cannot transfer user info")
            return
        }
        session.transferUserInfo(userInfo)
    }
    
    // MARK: - Sync Helpers
    
    /// Sync a completed workout session to the counterpart
    func syncWorkoutSession(_ session: WorkoutSessionTransfer) {
        let data: [String: Any] = [
            "type": "workoutSession",
            "id": session.id.uuidString,
            "gymName": session.gymName,
            "checkInTime": session.checkInTime.timeIntervalSince1970,
            "checkOutTime": session.checkOutTime?.timeIntervalSince1970 ?? 0,
            "duration": session.duration,
            "calories": session.calories,
            "workoutType": session.workoutType,
            "isActive": session.isActive
        ]
        transferUserInfo(data)
    }
    
    /// Sync weekly goal to counterpart
    func syncWeeklyGoal(_ goal: Int) {
        let context: [String: Any] = [
            "type": "goalUpdate",
            "weeklyGoal": goal
        ]
        updateApplicationContext(context)
    }
    
    /// Sync preferences to counterpart
    func syncPreferences(defaultWorkoutType: String, hapticEnabled: Bool) {
        let context: [String: Any] = [
            "type": "preferences",
            "defaultWorkoutType": defaultWorkoutType,
            "hapticEnabled": hapticEnabled
        ]
        updateApplicationContext(context)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            self?.isActivated = (activationState == .activated)
        }
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }
    
    // Immediate messages
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(message)
        }
        replyHandler(["status": "received"])
    }
    
    // Application context
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(applicationContext)
        }
    }
    
    // User info transfers (guaranteed delivery)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(userInfo)
        }
    }
    
    // iOS-only delegates
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated, reactivating...")
        session.activate()
    }
    #endif
    
    // MARK: - Data Handling
    
    private func handleReceivedData(_ data: [String: Any]) {
        lastReceivedMessage = data
        
        guard let type = data["type"] as? String else { return }
        
        switch type {
        case "workoutSession":
            if let transfer = WorkoutSessionTransfer.from(dictionary: data) {
                receivedSessions.append(transfer)
                onSessionReceived?(transfer)
            }
            
        case "goalUpdate":
            if let goal = data["weeklyGoal"] as? Int {
                onGoalUpdated?(goal)
            }
            
        case "preferences":
            onPreferencesUpdated?(data)
            
        default:
            print("Unknown message type: \(type)")
        }
    }
}

// MARK: - Transfer Models

/// Lightweight struct for transferring workout data between devices
struct WorkoutSessionTransfer: Identifiable {
    let id: UUID
    let gymName: String
    let checkInTime: Date
    let checkOutTime: Date?
    let duration: TimeInterval
    let calories: Int
    let workoutType: String
    let isActive: Bool
    
    static func from(dictionary: [String: Any]) -> WorkoutSessionTransfer? {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let gymName = dictionary["gymName"] as? String,
              let checkInTimestamp = dictionary["checkInTime"] as? TimeInterval else {
            return nil
        }
        
        let checkOutTimestamp = dictionary["checkOutTime"] as? TimeInterval
        
        return WorkoutSessionTransfer(
            id: id,
            gymName: gymName,
            checkInTime: Date(timeIntervalSince1970: checkInTimestamp),
            checkOutTime: checkOutTimestamp.map { $0 > 0 ? Date(timeIntervalSince1970: $0) : nil } ?? nil,
            duration: dictionary["duration"] as? TimeInterval ?? 0,
            calories: dictionary["calories"] as? Int ?? 0,
            workoutType: dictionary["workoutType"] as? String ?? "Other",
            isActive: dictionary["isActive"] as? Bool ?? false
        )
    }
}
