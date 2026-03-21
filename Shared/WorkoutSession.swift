import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var gymName: String
    var checkInTime: Date
    var checkOutTime: Date?
    var isActive: Bool
    var notes: String

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

    init(
        id: UUID = UUID(),
        gymName: String,
        checkInTime: Date = Date(),
        checkOutTime: Date? = nil,
        isActive: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.gymName = gymName
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.isActive = isActive
        self.notes = notes
    }

    func checkOut() {
        self.checkOutTime = Date()
        self.isActive = false
    }
}
