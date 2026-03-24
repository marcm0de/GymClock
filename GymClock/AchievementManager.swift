import Foundation
import SwiftUI

// MARK: - Achievement Definition

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Achievement Manager

@MainActor
final class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var newlyUnlocked: Achievement? = nil
    @Published var showCelebration: Bool = false
    
    private let storageKey = "gymclock_achievements"
    
    static let allAchievements: [Achievement] = [
        Achievement(id: "first_workout", title: "First Rep", description: "Complete your first workout", icon: "🎉", isUnlocked: false),
        Achievement(id: "streak_7", title: "On Fire", description: "Maintain a 7 day streak", icon: "🔥", isUnlocked: false),
        Achievement(id: "streak_30", title: "Unstoppable", description: "Maintain a 30 day streak", icon: "⚡", isUnlocked: false),
        Achievement(id: "early_bird", title: "Early Bird", description: "Work out before 7 AM", icon: "🌅", isUnlocked: false),
        Achievement(id: "night_owl", title: "Night Owl", description: "Work out after 9 PM", icon: "🦉", isUnlocked: false),
        Achievement(id: "marathon", title: "Marathon", description: "Complete a 2+ hour session", icon: "🏃", isUnlocked: false),
        Achievement(id: "centurion", title: "Centurion", description: "Complete 100 workouts", icon: "💯", isUnlocked: false),
        Achievement(id: "calories_1000", title: "Furnace", description: "Burn 1,000+ calories in one session", icon: "🔥", isUnlocked: false),
        Achievement(id: "perfect_week", title: "Perfect Week", description: "Work out every day for a full week", icon: "⭐", isUnlocked: false),
        Achievement(id: "gym_rat", title: "Gym Rat", description: "Complete 365 total workouts", icon: "🐀", isUnlocked: false),
    ]
    
    init() {
        loadAchievements()
    }
    
    // MARK: - Persistence
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge saved with all achievements (in case new ones were added)
            achievements = Self.allAchievements.map { definition in
                if let saved = saved.first(where: { $0.id == definition.id }) {
                    return saved
                }
                return definition
            }
        } else {
            achievements = Self.allAchievements
        }
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    // MARK: - Check & Unlock
    
    func checkAchievements(sessions: [WorkoutSession], currentStreak: Int) {
        let completedSessions = sessions.filter { !$0.isActive }
        
        // First Workout
        if completedSessions.count >= 1 {
            unlock("first_workout")
        }
        
        // 7 Day Streak
        if currentStreak >= 7 {
            unlock("streak_7")
        }
        
        // 30 Day Streak
        if currentStreak >= 30 {
            unlock("streak_30")
        }
        
        // Early Bird (before 7 AM)
        let calendar = Calendar.current
        if completedSessions.contains(where: { calendar.component(.hour, from: $0.checkInTime) < 7 }) {
            unlock("early_bird")
        }
        
        // Night Owl (after 9 PM)
        if completedSessions.contains(where: { calendar.component(.hour, from: $0.checkInTime) >= 21 }) {
            unlock("night_owl")
        }
        
        // Marathon (2+ hours)
        if completedSessions.contains(where: { $0.duration >= 7200 }) {
            unlock("marathon")
        }
        
        // Centurion (100 workouts)
        if completedSessions.count >= 100 {
            unlock("centurion")
        }
        
        // 1000 Calories in one session
        if completedSessions.contains(where: { ($0.calories > 0 ? $0.calories : $0.estimatedCalories) >= 1000 }) {
            unlock("calories_1000")
        }
        
        // Perfect Week (7 consecutive days)
        if currentStreak >= 7 {
            unlock("perfect_week")
        }
        
        // Gym Rat (365 total)
        if completedSessions.count >= 365 {
            unlock("gym_rat")
        }
        
        saveAchievements()
    }
    
    private func unlock(_ id: String) {
        guard let index = achievements.firstIndex(where: { $0.id == id }),
              !achievements[index].isUnlocked else { return }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        newlyUnlocked = achievements[index]
        showCelebration = true
        
        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showCelebration = false
            newlyUnlocked = nil
        }
    }
    
    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }
    
    var totalCount: Int {
        achievements.count
    }
}
