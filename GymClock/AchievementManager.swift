import Foundation
import SwiftUI

// MARK: - Achievement Rarity

enum AchievementRarity: String, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var glowColor: Color {
        switch self {
        case .common: return .green.opacity(0.3)
        case .rare: return .blue.opacity(0.4)
        case .epic: return .purple.opacity(0.5)
        case .legendary: return .orange.opacity(0.6)
        }
    }
}

// MARK: - Achievement Definition

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let rarity: AchievementRarity
    var isUnlocked: Bool
    var unlockedDate: Date?
    /// For progressive achievements, how far along (0.0 to 1.0)
    var progress: Double
    /// The target count for progressive achievements
    let targetCount: Int
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: String, title: String, description: String, icon: String, rarity: AchievementRarity = .common, isUnlocked: Bool = false, unlockedDate: Date? = nil, progress: Double = 0, targetCount: Int = 1) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.rarity = rarity
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
        self.targetCount = targetCount
    }
}

// MARK: - Achievement Manager

@MainActor
final class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var newlyUnlocked: Achievement? = nil
    @Published var showCelebration: Bool = false
    
    private let storageKey = "gymclock_achievements"
    private var dismissTask: Task<Void, Never>?
    
    static let allAchievements: [Achievement] = [
        // Common
        Achievement(id: "first_workout", title: "First Rep", description: "Complete your first workout", icon: "🎉", rarity: .common, targetCount: 1),
        Achievement(id: "early_bird", title: "Early Bird", description: "Work out before 7 AM", icon: "🌅", rarity: .common),
        Achievement(id: "night_owl", title: "Night Owl", description: "Work out after 9 PM", icon: "🦉", rarity: .common),
        Achievement(id: "weekend_warrior", title: "Weekend Warrior", description: "Work out on both Saturday and Sunday", icon: "⚔️", rarity: .common),
        Achievement(id: "note_taker", title: "Note Taker", description: "Add notes to 10 workouts", icon: "📝", rarity: .common, targetCount: 10),
        
        // Rare
        Achievement(id: "streak_7", title: "On Fire", description: "Maintain a 7 day streak", icon: "🔥", rarity: .rare, targetCount: 7),
        Achievement(id: "perfect_week", title: "Perfect Week", description: "Work out every day for a full week", icon: "⭐", rarity: .rare, targetCount: 7),
        Achievement(id: "variety_master", title: "Variety Master", description: "Try all workout types", icon: "🎨", rarity: .rare, targetCount: 4),
        Achievement(id: "marathon", title: "Marathon", description: "Complete a 2+ hour session", icon: "🏃", rarity: .rare),
        Achievement(id: "half_century", title: "Half Century", description: "Complete 50 workouts", icon: "5️⃣0️⃣", rarity: .rare, targetCount: 50),
        Achievement(id: "calories_500", title: "Burner", description: "Burn 500+ calories in one session", icon: "🥵", rarity: .rare),
        
        // Epic
        Achievement(id: "streak_30", title: "Unstoppable", description: "Maintain a 30 day streak", icon: "⚡", rarity: .epic, targetCount: 30),
        Achievement(id: "centurion", title: "Centurion", description: "Complete 100 workouts", icon: "💯", rarity: .epic, targetCount: 100),
        Achievement(id: "calories_1000", title: "Furnace", description: "Burn 1,000+ calories in one session", icon: "🌋", rarity: .epic),
        Achievement(id: "dawn_patrol", title: "Dawn Patrol", description: "Work out before 6 AM five times", icon: "🌄", rarity: .epic, targetCount: 5),
        Achievement(id: "iron_month", title: "Iron Month", description: "Work out 20+ days in a single month", icon: "🗓️", rarity: .epic, targetCount: 20),
        
        // Legendary
        Achievement(id: "streak_100", title: "Legend", description: "Maintain a 100 day streak", icon: "👑", rarity: .legendary, targetCount: 100),
        Achievement(id: "gym_rat", title: "Gym Rat", description: "Complete 365 total workouts", icon: "🐀", rarity: .legendary, targetCount: 365),
        Achievement(id: "triple_threat", title: "Triple Threat", description: "3 sessions in one day", icon: "🏆", rarity: .legendary, targetCount: 3),
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
                    // Keep saved unlock state but update definition fields
                    var merged = definition
                    merged.isUnlocked = saved.isUnlocked
                    merged.unlockedDate = saved.unlockedDate
                    merged.progress = saved.progress
                    return merged
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
        let calendar = Calendar.current
        
        // First Workout
        if completedSessions.count >= 1 {
            unlock("first_workout")
        }
        
        // Half Century (50 workouts)
        updateProgress("half_century", current: completedSessions.count, target: 50)
        if completedSessions.count >= 50 {
            unlock("half_century")
        }
        
        // 7 Day Streak
        updateProgress("streak_7", current: currentStreak, target: 7)
        if currentStreak >= 7 {
            unlock("streak_7")
        }
        
        // 30 Day Streak
        updateProgress("streak_30", current: currentStreak, target: 30)
        if currentStreak >= 30 {
            unlock("streak_30")
        }
        
        // 100 Day Streak
        updateProgress("streak_100", current: currentStreak, target: 100)
        if currentStreak >= 100 {
            unlock("streak_100")
        }
        
        // Early Bird (before 7 AM)
        if completedSessions.contains(where: { calendar.component(.hour, from: $0.checkInTime) < 7 }) {
            unlock("early_bird")
        }
        
        // Night Owl (after 9 PM)
        if completedSessions.contains(where: { calendar.component(.hour, from: $0.checkInTime) >= 21 }) {
            unlock("night_owl")
        }
        
        // Dawn Patrol (before 6 AM, 5 times)
        let dawnCount = completedSessions.filter { calendar.component(.hour, from: $0.checkInTime) < 6 }.count
        updateProgress("dawn_patrol", current: dawnCount, target: 5)
        if dawnCount >= 5 {
            unlock("dawn_patrol")
        }
        
        // Marathon (2+ hours)
        if completedSessions.contains(where: { $0.duration >= 7200 }) {
            unlock("marathon")
        }
        
        // Centurion (100 workouts)
        updateProgress("centurion", current: completedSessions.count, target: 100)
        if completedSessions.count >= 100 {
            unlock("centurion")
        }
        
        // 500 Calories in one session
        let effectiveCalories: (WorkoutSession) -> Int = { session in
            session.calories > 0 ? session.calories : session.estimatedCalories
        }
        if completedSessions.contains(where: { effectiveCalories($0) >= 500 }) {
            unlock("calories_500")
        }
        
        // 1000 Calories in one session
        if completedSessions.contains(where: { effectiveCalories($0) >= 1000 }) {
            unlock("calories_1000")
        }
        
        // Perfect Week (all 7 days in a single calendar week)
        checkPerfectWeek(sessions: completedSessions, calendar: calendar)
        
        // Weekend Warrior (Saturday AND Sunday in the same weekend)
        checkWeekendWarrior(sessions: completedSessions, calendar: calendar)
        
        // Variety Master (all workout types used)
        let usedTypes = Set(completedSessions.map { $0.workoutType })
        updateProgress("variety_master", current: usedTypes.count, target: WorkoutType.allCases.count)
        if usedTypes.count >= WorkoutType.allCases.count {
            unlock("variety_master")
        }
        
        // Note Taker (10 sessions with notes)
        let notedSessions = completedSessions.filter { !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        updateProgress("note_taker", current: notedSessions, target: 10)
        if notedSessions >= 10 {
            unlock("note_taker")
        }
        
        // Iron Month (20+ days in a single month)
        checkIronMonth(sessions: completedSessions, calendar: calendar)
        
        // Triple Threat (3 sessions in one day)
        checkTripleThreat(sessions: completedSessions, calendar: calendar)
        
        // Gym Rat (365 total)
        updateProgress("gym_rat", current: completedSessions.count, target: 365)
        if completedSessions.count >= 365 {
            unlock("gym_rat")
        }
        
        saveAchievements()
    }
    
    private func checkPerfectWeek(sessions: [WorkoutSession], calendar: Calendar) {
        // Group sessions by calendar week, check if any week has all 7 days
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.checkInTime)?.start ?? session.checkInTime
        }

        for (weekStart, weekSessions) in grouped {
            let uniqueDays = Set(weekSessions.map { calendar.startOfDay(for: $0.checkInTime) })
            updateProgress("perfect_week", current: uniqueDays.count, target: 7)
            if uniqueDays.count >= 7 {
                unlock("perfect_week")
                return
            }
        }
    }

    private func checkWeekendWarrior(sessions: [WorkoutSession], calendar: Calendar) {
        // Group sessions by week, check if any week has both Saturday and Sunday
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.checkInTime)?.start ?? session.checkInTime
        }
        
        for (_, weekSessions) in grouped {
            let weekdays = Set(weekSessions.map { calendar.component(.weekday, from: $0.checkInTime) })
            if weekdays.contains(1) && weekdays.contains(7) { // Sunday = 1, Saturday = 7
                unlock("weekend_warrior")
                return
            }
        }
    }
    
    private func checkIronMonth(sessions: [WorkoutSession], calendar: Calendar) {
        // Group by month, count unique days
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .month, for: session.checkInTime)?.start ?? session.checkInTime
        }
        
        var bestMonth = 0
        for (_, monthSessions) in grouped {
            let uniqueDays = Set(monthSessions.map { calendar.startOfDay(for: $0.checkInTime) })
            bestMonth = max(bestMonth, uniqueDays.count)
        }
        
        updateProgress("iron_month", current: bestMonth, target: 20)
        if bestMonth >= 20 {
            unlock("iron_month")
        }
    }
    
    private func checkTripleThreat(sessions: [WorkoutSession], calendar: Calendar) {
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.checkInTime)
        }
        
        var maxInDay = 0
        for (_, daySessions) in grouped {
            maxInDay = max(maxInDay, daySessions.count)
        }
        
        updateProgress("triple_threat", current: maxInDay, target: 3)
        if maxInDay >= 3 {
            unlock("triple_threat")
        }
    }
    
    private func updateProgress(_ id: String, current: Int, target: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == id }),
              !achievements[index].isUnlocked else { return }
        achievements[index].progress = min(Double(current) / Double(target), 1.0)
    }
    
    private func unlock(_ id: String) {
        guard let index = achievements.firstIndex(where: { $0.id == id }),
              !achievements[index].isUnlocked else { return }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        achievements[index].progress = 1.0
        newlyUnlocked = achievements[index]
        showCelebration = true
        
        // Cancel any previous dismiss task
        dismissTask?.cancel()
        
        // Auto-dismiss after 4 seconds — use [weak self] to avoid retain cycle
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            self?.showCelebration = false
            self?.newlyUnlocked = nil
        }
    }
    
    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    var unlockedByRarity: [AchievementRarity: [Achievement]] {
        Dictionary(grouping: achievements.filter(\.isUnlocked)) { $0.rarity }
    }
    
    var nextToUnlock: [Achievement] {
        achievements
            .filter { !$0.isUnlocked && $0.progress > 0 }
            .sorted { $0.progress > $1.progress }
    }
}
