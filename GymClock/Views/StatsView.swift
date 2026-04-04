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
            
            let unlocked = achievementManager.achievements.filter(\.isUnlocked)
            if unlocked.isEmpty {
                Text("Complete workouts to unlock achievements!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(unlocked.sorted(by: { ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }).prefix(8)) { achievement in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(achievement.rarity.glowColor)
                                        .frame(width: 40, height: 40)
                                        .blur(radius: 6)
                                    Text(achievement.icon)
                                        .font(.title2)
                                }
                                Text(achievement.title)
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                            .padding(.vertical, 8)
                            .background(achievement.rarity.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
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

        return VStack(spacing: 16) {
            HStack {
                Image(systemName: goalMet ? "checkmark.seal.fill" : "target")
                    .foregroundStyle(goalMet ? .green : .orange)
                    .symbolEffect(.bounce, value: goalMet)
                Text("Weekly Goal")
                    .font(.headline)
                Spacer()
                Text("\(thisWeekCount)/\(weeklyGoalDays) days")
                    .font(.subheadline.bold())
                    .foregroundStyle(goalMet ? .green : .primary)
            }

            // Custom progress ring instead of flat bar
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            goalMet ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: progress)

                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(goalMet ? .green : .primary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Day dots
                    HStack(spacing: 6) {
                        ForEach(0..<weeklyGoalDays, id: \.self) { i in
                            Circle()
                                .fill(i < thisWeekCount ? Color.green : Color(.systemGray4))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    i < thisWeekCount
                                    ? Image(systemName: "checkmark")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(.white)
                                    : nil
                                )
                        }
                    }

                    if goalMet {
                        Text("🎉 Goal achieved this week!")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    } else {
                        let remaining = max(0, weeklyGoalDays - thisWeekCount)
                        Text("\(remaining) more session\(remaining == 1 ? "" : "s") to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
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

        return HStack(spacing: 12) {
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
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.green)
                Text("This Week")
                    .font(.headline)
            }

            let data = weeklyChartData

            if data.allSatisfy({ $0.minutes == 0 }) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No sessions this week")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(data, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        if item.minutes > 0 {
                            Text("\(Int(item.minutes))m")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                        }
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color(.systemGray4))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption2.bold())
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyChartData: [DayData] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                return nil
            }
            let daySessions = sessions.filter { calendar.isDate($0.checkInTime, inSameDayAs: date) }
            let totalMinutes = daySessions.reduce(0.0) { $0 + $1.duration } / 60.0
            let weekdayIndex = calendar.component(.weekday, from: date) - 1

            return DayData(
                day: weekDays[weekdayIndex],
                minutes: totalMinutes
            )
        }
    }
    
    // MARK: - Workout Type Breakdown
    
    private var workoutTypeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.mixed.cardio")
                    .foregroundStyle(.blue)
                Text("Workout Types")
                    .font(.headline)
            }
            
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
                        ZStack {
                            Circle()
                                .fill(typeColor(type).opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: type.icon)
                                .font(.body)
                                .foregroundStyle(typeColor(type))
                        }
                        
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
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(typeColor(type))
                                        .frame(width: geo.size.width * fraction, height: 6)
                                        .animation(.spring(response: 0.6), value: fraction)
                                }
                            }
                            .frame(height: 6)
                            
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

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.green)
                Text(DateFormatters.monthYearFormatter.string(from: Date()))
                    .font(.headline)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MonthStatTile(
                    value: "\(monthSessions.count)",
                    label: "Sessions",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                MonthStatTile(
                    value: DateFormatters.formatDuration(totalTime),
                    label: "Total Time",
                    icon: "clock.fill",
                    color: .blue
                )
                MonthStatTile(
                    value: DateFormatters.formatDuration(avgTime),
                    label: "Avg Session",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
                MonthStatTile(
                    value: "\(totalCalories)",
                    label: "Calories",
                    icon: "flame.fill",
                    color: .orange
                )
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
        
        let gymCounts = Dictionary(grouping: sessions) { $0.gymName }.mapValues(\.count)
        let favoriteGym = gymCounts.max(by: { $0.value < $1.value })
        
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
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                AllTimeStat(label: "Total Workouts", value: "\(sessions.count)", icon: "checkmark.circle.fill", color: .green)
                AllTimeStat(label: "Total Time", value: DateFormatters.formatDuration(totalTime), icon: "clock.fill", color: .blue)
                AllTimeStat(label: "Avg Session", value: DateFormatters.formatDuration(avgTime), icon: "chart.line.uptrend.xyaxis", color: .purple)
                AllTimeStat(label: "Avg Calories", value: "\(avgCalories)", icon: "flame.fill", color: .orange)
                
                if let fav = favoriteGym {
                    AllTimeStat(label: "Top Gym", value: fav.key, icon: "building.2.fill", color: .teal)
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
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("Personal Records")
                            .font(.headline)
                    }
                    
                    // Longest session
                    HStack {
                        ZStack {
                            Circle()
                                .fill(.yellow.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Text("🏆")
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Longest Session")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(best.gymName)
                                .font(.subheadline)
                            Text(DateFormatters.dateFormatter.string(from: best.checkInTime))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(best.formattedDuration)
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    }
                    
                    // Most calories
                    if let mc = mostCalories, effectiveCalories(for: mc) > 0 {
                        Divider()
                        
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(.orange.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Text("🔥")
                                    .font(.title3)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Most Calories")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(mc.gymName)
                                    .font(.subheadline)
                                Text(DateFormatters.dateFormatter.string(from: mc.checkInTime))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(effectiveCalories(for: mc)) cal")
                                .font(.title2.bold())
                                .foregroundStyle(.orange)
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

struct MonthStatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }
}

struct StreakCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(value > 0 ? .primary : .secondary)

            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(value > 0 ? 0.2 : 0.05), lineWidth: 1)
        )
    }
}

struct AllTimeStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }
            
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
        .padding(10)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StatsView()
        .environmentObject(SessionTracker())
        .environmentObject(AchievementManager())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
