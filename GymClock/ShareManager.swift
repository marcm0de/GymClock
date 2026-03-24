import Foundation

struct ShareManager {
    
    /// Generate a shareable workout summary string
    static func generateShareText(
        session: WorkoutSession,
        streak: Int,
        totalWorkouts: Int
    ) -> String {
        let durationMinutes = Int(session.duration / 60)
        let workoutType = session.workoutType.rawValue.lowercased()
        let gymName = session.gymName
        let calories = session.calories > 0 ? session.calories : session.estimatedCalories
        
        var text = "🏋️ Just finished a \(durationMinutes)min \(workoutType) session"
        
        if !gymName.isEmpty {
            text += " at \(gymName)!"
        } else {
            text += "!"
        }
        
        var stats: [String] = []
        
        if streak > 1 {
            stats.append("🔥 \(streak) day streak")
        }
        
        if calories > 0 {
            stats.append("\(calories) cal burned")
        }
        
        if totalWorkouts > 0 && totalWorkouts % 10 == 0 {
            stats.append("🎯 \(totalWorkouts) total workouts")
        }
        
        if !stats.isEmpty {
            text += " " + stats.joined(separator: " | ")
        }
        
        text += " | GymClock"
        
        return text
    }
    
    /// Generate a share text for an achievement
    static func generateAchievementShareText(achievement: Achievement) -> String {
        return "🏆 Just unlocked \"\(achievement.title)\" on GymClock! \(achievement.icon) \(achievement.description) #GymClock #Fitness"
    }
}
