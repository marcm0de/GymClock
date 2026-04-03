import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @EnvironmentObject var achievementManager: AchievementManager
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    @AppStorage("weeklyGoalDays") private var weeklyGoalDays: Int = 4

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        weeklyGoalProgress
                        streakCards
                        achievementsSummary
                        weeklyChart
                        workoutTypeBreakdown
                        monthlyOverview
                        allTimeStats
                        bestSessionCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Stats")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView(
            "No Stats Yet",
            systemImage: "chart.bar",
            description: Text("Complete your first workout to see stats here")
        )
    }
    
    // MARK: - Achievements Summary
    
    private var achievementsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Achievements")
                    .font(.headline)
                Spacer()
                Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
            
            // Show recent unlocked achievements
            let unlocked = achievementManager.achievements.filter(\.isUnlocked)
            if unlocked.isEmpty {
                Text("Complete workouts to unlock achievements!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(unlocked.sorted(by: { ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }).prefix(8)) { achievement in
                            VStack(spacing: 4) {
                                Text(achievement.icon)
                                    .font(.title2)
                                Text(achievement.title)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(achievement.rarity.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Goal Progress

    private var weeklyGoalProgress: some View {
        let thisWeekCount = sessionTracker.sessionsThisWeek(allSessions: sessions).count
        let progress = weeklyGoalDays > 0 ? min(Double(thisWeekCount) / Double(weeklyGoalDays), 1.0) : 0
        let goalMet = thisWeekCount >= weeklyGoalDays

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: goalMet ? "checkmark.seal.fill" : "target")
                    .foregroundStyle(goalMet ? .green : .orange)
                Text("Weekly Goal")
                    .font(.headline)
                Spacer()
                Text("\(thisWeekCount)/\(weeklyGoalDays) days")
                    .font(.subheadline.bold())
                    .foregroundStyle(goalMet ? .green : .primary)
            }

            ProgressView(value: progress)
                .tint(goalMet ? .green : .orange)
                .scaleEffect(y: 2)

            if goalMet {
                Text("🎉 Goal achieved this week!")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                let remaining = max(0, weeklyGoalDays - thisWeekCount)
                Text("\(remaining) more session\(remaining == 1 ? "" : "s") to hit your goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak Cards

    private var streakCards: some View {
        let dayStreak = sessionTracker.currentStreak(allSessions: sessions)
        let weekStreak = sessionTracker.weeklyStreak(allSessions: sessions)
        let thisWeekCount = sessionTracker.sessionsThisWeek(allSessions: sessions).count

        return HStack(spacing: 16) {
            StreakCard(
                title: "Day Streak",
                value: dayStreak,
                icon: "flame.fill",
                color: dayStreak > 0 ? .orange : .gray
            )

            StreakCard(
                title: "Week Streak",
                value: weekStreak,
                icon: "star.fill",
                color: weekStreak > 0 ? .yellow : .gray
            )

            StreakCard(
                title: "This Week",
                value: thisWeekCount,
                icon: "calendar",
                color: thisWeekCount > 0 ? .green : .gray
            )
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            let data = weeklyChartData

            if data.allSatisfy({ $0.minutes == 0 }) {
                Text("No sessions this week")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(data, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(6)
                }
                .frame(height: 200)
                .chartYAxisLabel("Minutes")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyChartData: [DayData] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let daySessions = sessions.filter { calendar.isDate($0.checkInTime, inSameDayAs: date) }
            let totalMinutes = daySessions.reduce(0.0) { $0 + $1.duration } / 60.0

            return DayData(
                day: weekDays[calendar.component(.weekday, from: date) - 1],
                minutes: totalMinutes
            )
        }
    }
    
    // MARK: - Workout Type Breakdown
    
    private var workoutTypeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Types")
                .font(.headline)
            
            let typeCounts = Dictionary(grouping: sessions) { $0.workoutType }
                .mapValues(\.count)
                .sorted { $0.value > $1.value }
            
            if typeCounts.isEmpty {
                Text("No data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(typeCounts, id: \.key) { type, count in
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.title3)
                            .foregroundStyle(typeColor(type))
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(type.rawValue)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("\(count)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(typeColor(type))
                            }
                            
                            let total = sessions.count
                            let fraction = total > 0 ? Double(count) / Double(total) : 0
                            
                            ProgressView(value: fraction)
                                .tint(typeColor(type))
                            
                            Text("\(Int(fraction * 100))% of workouts")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func typeColor(_ type: WorkoutType) -> Color {
        switch type {
        case .weights: return .blue
        case .cardio: return .orange
        case .mixed: return .purple
        case .other: return .gray
        }
    }

    // MARK: - Monthly Overview

    private var monthlyOverview: some View {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let monthSessions = sessions.filter { $0.checkInTime >= startOfMonth }
        let totalTime = monthSessions.reduce(0.0) { $0 + $1.duration }
        let totalCalories = monthSessions.reduce(0) { $0 + effectiveCalories(for: $1) }
        let avgTime = monthSessions.isEmpty ? 0.0 : totalTime / Double(monthSessions.count)

        return VStack(alignment: .leading, spacing: 12) {
            Text(DateFormatters.monthYearFormatter.string(from: Date()))
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("\(monthSessions.count)")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.green)
                    Text("Sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading) {
                    Text(DateFormatters.formatDuration(totalTime))
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                        .minimumScaleFactor(0.7)
                    Text("Total Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                
                VStack(alignment: .leading) {
                    Text(DateFormatters.formatDuration(avgTime))
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                        .minimumScaleFactor(0.7)
                    Text("Avg Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading) {
                    Text("\(totalCalories)")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                        .minimumScaleFactor(0.7)
                    Text("Calories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - All-Time Stats
    
    private var allTimeStats: some View {
        let totalTime = sessions.reduce(0.0) { $0 + $1.duration }
        let totalCalories = sessions.reduce(0) { $0 + effectiveCalories(for: $1) }
        let avgTime = sessions.isEmpty ? 0.0 : totalTime / Double(sessions.count)
        let avgCalories = sessions.isEmpty ? 0 : totalCalories / sessions.count
        
        // Find most popular gym
        let gymCounts = Dictionary(grouping: sessions) { $0.gymName }.mapValues(\.count)
        let favoriteGym = gymCounts.max(by: { $0.value < $1.value })
        
        // Find most active day of week
        let calendar = Calendar.current
        let dayCounts = Dictionary(grouping: sessions) { calendar.component(.weekday, from: $0.checkInTime) }.mapValues(\.count)
        let favoriteDay = dayCounts.max(by: { $0.value < $1.value })
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "infinity")
                    .foregroundStyle(.green)
                Text("All Time")
                    .font(.headline)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AllTimeStat(label: "Total Workouts", value: "\(sessions.count)", icon: "checkmark.circle", color: .green)
                AllTimeStat(label: "Total Time", value: DateFormatters.formatDuration(totalTime), icon: "clock", color: .blue)
                AllTimeStat(label: "Avg Session", value: DateFormatters.formatDuration(avgTime), icon: "chart.line.uptrend.xyaxis", color: .purple)
                AllTimeStat(label: "Avg Calories", value: "\(avgCalories)", icon: "flame.fill", color: .orange)
                
                if let fav = favoriteGym {
                    AllTimeStat(label: "Top Gym", value: fav.key, icon: "building.2", color: .teal)
                }
                
                if let dayNum = favoriteDay {
                    let name = dayNum.key >= 1 && dayNum.key <= 7 ? dayNames[dayNum.key] : "Unknown"
                    AllTimeStat(label: "Top Day", value: name, icon: "calendar.badge.clock", color: .indigo)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Best Session

    private var bestSessionCard: some View {
        let best = sessions.max(by: { $0.duration < $1.duration })
        let mostCalories = sessions.max(by: { effectiveCalories(for: $0) < effectiveCalories(for: $1) })

        return Group {
            if let best = best {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("Personal Records")
                            .font(.headline)
                    }
                    
                    // Longest session
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🏆 Longest Session")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(best.gymName)
                                    .font(.subheadline)
                                Text(DateFormatters.dateFormatter.string(from: best.checkInTime))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(best.formattedDuration)
                                .font(.title2.bold())
                                .foregroundStyle(.green)
                        }
                    }
                    
                    // Most calories
                    if let mc = mostCalories, effectiveCalories(for: mc) > 0 {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🔥 Most Calories")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(mc.gymName)
                                        .font(.subheadline)
                                    Text(DateFormatters.dateFormatter.string(from: mc.checkInTime))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(effectiveCalories(for: mc)) cal")
                                    .font(.title2.bold())
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func effectiveCalories(for session: WorkoutSession) -> Int {
        session.calories > 0 ? session.calories : session.estimatedCalories
    }
}

// MARK: - Supporting Types

struct DayData {
    let day: String
    let minutes: Double
}

struct StreakCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(value > 0 ? .primary : .secondary)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AllTimeStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    StatsView()
        .environmentObject(SessionTracker())
        .environmentObject(AchievementManager())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
