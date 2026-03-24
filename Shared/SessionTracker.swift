import Foundation
import SwiftData
import Combine
import HealthKit

@MainActor
final class SessionTracker: ObservableObject {
    @Published var activeSession: WorkoutSession?
    @Published var isTracking = false
    @Published var elapsedTime: TimeInterval = 0

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
        endHealthKitWorkout(duration: finalDuration, calories: finalCalories)
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
            Task { @MainActor in
                self?.handleGymEntry(regionId: regionId)
            }
        }

        GeofenceManager.shared.onExitGym = { [weak self] _ in
            Task { @MainActor in
                self?.handleGymExit()
            }
        }
    }

    private func handleGymEntry(regionId: String) {
        guard let modelContext = modelContext else { return }

        let id = UUID(uuidString: regionId) ?? UUID()
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
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let workoutType = HKObjectType.workoutType()
        let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let typesToShare: Set<HKSampleType> = [workoutType, activeEnergy]
        let typesToRead: Set<HKObjectType> = [workoutType, activeEnergy]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }

    private func startHealthKitWorkout() {
        // HealthKit workout session is managed by WatchOS extension
        // This is a placeholder for iOS-side tracking
    }

    private func endHealthKitWorkout(duration: TimeInterval, calories: Int = 0) {
        guard HKHealthStore.isHealthDataAvailable() else { return }

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
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        while true {
            let daySessions = sortedSessions.filter {
                calendar.isDate($0.checkInTime, inSameDayAs: currentDate)
            }

            if daySessions.isEmpty {
                break
            }

            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        return streak
    }

    func weeklyStreak(allSessions: [WorkoutSession]) -> Int {
        let calendar = Calendar.current
        let sortedSessions = allSessions
            .filter { !$0.isActive }
            .sorted { $0.checkInTime > $1.checkInTime }

        guard !sortedSessions.isEmpty else { return 0 }

        var streak = 0
        var currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

        while true {
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
            let weekSessions = sortedSessions.filter {
                $0.checkInTime >= currentWeekStart && $0.checkInTime < weekEnd
            }

            if weekSessions.isEmpty {
                break
            }

            streak += 1
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        }

        return streak
    }
}
