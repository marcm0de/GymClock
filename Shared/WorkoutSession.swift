import Foundation
import SwiftData

// MARK: - Workout Type

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case weights = "Weights"
    case cardio = "Cardio"
    case mixed = "Mixed"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weights: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .mixed: return "figure.mixed.cardio"
        case .other: return "figure.cooldown"
        }
    }

    var color: String {
        switch self {
        case .weights: return "blue"
        case .cardio: return "orange"
        case .mixed: return "purple"
        case .other: return "gray"
        }
    }
}

@Model
final class WorkoutSession {
    var id: UUID
    var gymName: String
    var checkInTime: Date
    var checkOutTime: Date?
    var isActive: Bool
    var notes: String
    var workoutTypeRaw: String
    var calories: Int

    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .other }
        set { workoutTypeRaw = newValue.rawValue }
    }

    var duration: TimeInterval {
        let end = checkOutTime ?? Date()
        return end.timeIntervalSince(checkInTime)
    }

    var formattedDuration: String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        }
        return String(format: "%dm %02ds", minutes, seconds)
    }

    var shortDuration: String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }

    /// Rough calorie estimate based on duration and workout type
    var estimatedCalories: Int {
        let minutes = duration / 60.0
        let calPerMin: Double
        switch workoutType {
        case .weights: calPerMin = 5.0
        case .cardio: calPerMin = 8.0
        case .mixed: calPerMin = 6.5
        case .other: calPerMin = 4.0
        }
        return Int(minutes * calPerMin)
    }

    init(
        id: UUID = UUID(),
        gymName: String,
        checkInTime: Date = Date(),
        checkOutTime: Date? = nil,
        isActive: Bool = true,
        notes: String = "",
        workoutType: WorkoutType = .other,
        calories: Int = 0
    ) {
        self.id = id
        self.gymName = gymName
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.isActive = isActive
        self.notes = notes
        self.workoutTypeRaw = workoutType.rawValue
        self.calories = calories
    }

    func checkOut() {
        self.checkOutTime = Date()
        self.isActive = false
        self.calories = estimatedCalories
    }
}
