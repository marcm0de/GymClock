import Foundation
import SwiftData
import Combine
import HealthKit

@MainActor
final class SessionTracker: ObservableObject {
    @Published var activeSession: WorkoutSession?
    @Published var isTracking = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var healthKitAuthorized = false

    private var timer: Timer?
    private var modelContext: ModelContext?
    private let healthStore = HKHealthStore()

    init() {}

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadActiveSession()
        setupGeofencing()
    }

    // MARK: - Session Management

    func startSession(gymName: String) {
        guard activeSession == nil else { return }

        let session = WorkoutSession(gymName: gymName)
        activeSession = session
        isTracking = true

        modelContext?.insert(session)
        try? modelContext?.save()

        startTimer()
        startHealthKitWorkout()
    }

    func endSession() {
        guard let session = activeSession else { return }

        session.checkOut()
        let finalDuration = session.duration
        let finalCalories = session.calories
        activeSession = nil
        isTracking = false
        elapsedTime = 0

        try? modelContext?.save()

        stopTimer()
        if healthKitAuthorized {
            endHealthKitWorkout(duration: finalDuration, calories: finalCalories)
        }
    }

    func manualCheckIn(gymName: String) {
        startSession(gymName: gymName)
    }

    func manualCheckOut() {
        endSession()
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let session = self.activeSession else { return }
                self.elapsedTime = session.duration
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Persistence

    private func loadActiveSession() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.checkInTime, order: .reverse)]
        )

        if let sessions = try? modelContext.fetch(descriptor),
           let active = sessions.first {
            activeSession = active
            isTracking = true
            elapsedTime = active.duration
            startTimer()
        }
    }

    // MARK: - Geofencing Integration

    private func setupGeofencing() {
        GeofenceManager.shared.onEnterGym = { [weak self] regionId in
            Task { @MainActor [weak self] in
                self?.handleGymEntry(regionId: regionId)
            }
        }

        GeofenceManager.shared.onExitGym = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleGymExit()
            }
        }
    }

    private func handleGymEntry(regionId: String) {
        guard let modelContext = modelContext else { return }
        // If regionId is not a valid UUID, ignore (don't generate a random one)
        guard let id = UUID(uuidString: regionId) else {
            print("Invalid region ID received: \(regionId)")
            return
        }

        let descriptor = FetchDescriptor<GymLocation>(
            predicate: #Predicate { $0.id == id }
        )

        if let locations = try? modelContext.fetch(descriptor),
           let gym = locations.first {
            startSession(gymName: gym.name)
        }
    }

    private func handleGymExit() {
        endSession()
    }

    // MARK: - HealthKit

    func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            return
        }

        let workoutType = HKObjectType.workoutType()
        guard let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            print("Could not create activeEnergyBurned quantity type")
            return
        }
        let typesToShare: Set<HKSampleType> = [workoutType, activeEnergy]
        let typesToRead: Set<HKObjectType> = [workoutType, activeEnergy]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            Task { @MainActor in
                self?.healthKitAuthorized = success
            }
            if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            } else if !success {
                print("HealthKit authorization denied by user")
            }
        }
    }

    private func startHealthKitWorkout() {
        // HealthKit workout session is managed by WatchOS extension
        // This is a placeholder for iOS-side tracking
    }

    private func endHealthKitWorkout(duration: TimeInterval, calories: Int = 0) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard duration > 0 else { return }

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-duration)

        let energyBurned: HKQuantity? = calories > 0
            ? HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
            : nil

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: energyBurned,
            totalDistance: nil,
            metadata: [
                "GymClock": true,
                "Source": "GymClock Auto-Track"
            ]
        )

        healthStore.save(workout) { success, error in
            if let error = error {
                print("Failed to save workout to HealthKit: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Statistics

    func sessionsThisWeek(allSessions: [WorkoutSession]) -> [WorkoutSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return allSessions.filter { $0.checkInTime >= startOfWeek }
    }

    func totalTimeThisWeek(allSessions: [WorkoutSession]) -> TimeInterval {
        sessionsThisWeek(allSessions: allSessions)
            .reduce(0) { $0 + $1.duration }
    }

    func currentStreak(allSessions: [WorkoutSession]) -> Int {
        let calendar = Calendar.current
        let sortedSessions = allSessions
            .filter { !$0.isActive }
            .sorted { $0.checkInTime > $1.checkInTime }

        guard !sortedSessions.isEmpty else { return 0 }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check if there's a session today
        let todaySessions = sortedSessions.filter {
            calendar.isDate($0.checkInTime, inSameDayAs: currentDate)
        }

        if todaySessions.isEmpty {
            // No session today, start checking from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return 0
            }
            currentDate = yesterday
        }

        while true {
            let daySessions = sortedSessions.filter {
                calendar.isDate($0.checkInTime, inSameDayAs: currentDate)
            }

            if daySessions.isEmpty {
                break
            }

            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streak
    }

    func weeklyStreak(allSessions: [WorkoutSession]) -> Int {
        let calendar = Calendar.current
        let sortedSessions = allSessions
            .filter { !$0.isActive }
            .sorted { $0.checkInTime > $1.checkInTime }

        guard !sortedSessions.isEmpty else { return 0 }

        guard var currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return 0
        }

        var streak = 0

        while true {
            guard let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
                break
            }
            let weekSessions = sortedSessions.filter {
                $0.checkInTime >= currentWeekStart && $0.checkInTime < weekEnd
            }

            if weekSessions.isEmpty {
                break
            }

            streak += 1
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else {
                break
            }
            currentWeekStart = previousWeek
        }

        return streak
    }
}
