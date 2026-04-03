import SwiftUI
import SwiftData

struct WatchStatsView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 5
    
    private var streak: Int {
        sessionTracker.currentStreak(allSessions: sessions)
    }
    
    private var weekSessions: [WorkoutSession] {
        sessionTracker.sessionsThisWeek(allSessions: sessions)
    }
    
    private var monthSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return sessions.filter { $0.checkInTime >= startOfMonth }
    }
    
    private var bestSession: WorkoutSession? {
        sessions.max(by: { $0.duration < $1.duration })
    }
    
    private var weekProgress: Double {
        guard weeklyGoal > 0 else { return 0 }
        return min(Double(weekSessions.count) / Double(weeklyGoal), 1.0)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    // Streak display
                    streakCard
                    
                    // Weekly progress ring
                    weeklyProgressCard
                    
                    // Month stats
                    monthStatsCard
                    
                    // Best session
                    if let best = bestSession {
                        bestSessionCard(best)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Stats")
        }
    }
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("🔥")
                        .font(.title3)
                    Text("\(streak)")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundStyle(streak > 0 ? .orange : .secondary)
                    Text(streak == 1 ? "day" : "days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Streak flame visualization
            if streak > 0 {
                VStack(spacing: 0) {
                    ForEach(0..<min(streak, 5), id: \.self) { i in
                        Text("🔥")
                            .font(.system(size: CGFloat(8 + i * 2)))
                            .opacity(Double(i + 1) / 5.0)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.orange.opacity(streak > 0 ? 0.1 : 0.05))
                .strokeBorder(.orange.opacity(streak > 0 ? 0.3 : 0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Weekly Progress Card
    
    private var weeklyProgressCard: some View {
        VStack(spacing: 6) {
            Text("This Week")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            ZStack {
                // Background arc
                Circle()
                    .stroke(.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: weekProgress)
                    .stroke(
                        weekProgress >= 1.0 ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: weekProgress)
                
                // Center text
                VStack(spacing: 0) {
                    Text("\(weekSessions.count)/\(weeklyGoal)")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(weekProgress >= 1.0 ? .green : .primary)
                    if weekProgress >= 1.0 {
                        Text("✅")
                            .font(.system(size: 10))
                    }
                }
            }
            
            // Time this week
            Text(DateFormatters.formatDuration(sessionTracker.totalTimeThisWeek(allSessions: sessions)))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue.opacity(0.1))
                .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Month Stats Card
    
    private var monthStatsCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("\(monthSessions.count)")
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundStyle(.green)
                Text("sessions")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(width: 1, height: 24)
            
            VStack(spacing: 2) {
                let totalTime = monthSessions.reduce(0) { $0 + $1.duration }
                Text(DateFormatters.formatDuration(totalTime))
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.green)
                Text("total")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(width: 1, height: 24)
            
            VStack(spacing: 2) {
                let totalCal = monthSessions.reduce(0) { $0 + ($1.calories > 0 ? $1.calories : $1.estimatedCalories) }
                Text("\(totalCal)")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.orange)
                Text("cal")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.green.opacity(0.05))
        )
        .overlay(
            VStack {
                HStack {
                    Text("This Month")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 8)
                        .padding(.top, 2)
                    Spacer()
                }
                Spacer()
            }
        )
    }
    
    // MARK: - Best Session Card
    
    private func bestSessionCard(_ session: WorkoutSession) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("🏆")
                    .font(.caption)
                Text("Personal Best")
                    .font(.system(size: 9).bold())
                    .foregroundStyle(.yellow)
                    .textCase(.uppercase)
                Spacer()
            }
            
            HStack {
                Image(systemName: session.workoutType.icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(session.formattedDuration)
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundStyle(.green)
                
                Spacer()
                
                Text(DateFormatters.shortDateFormatter.string(from: session.checkInTime))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.yellow.opacity(0.05))
                .strokeBorder(.yellow.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    WatchStatsView()
        .environmentObject(SessionTracker())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
