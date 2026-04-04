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
                    streakCard
                    weeklyProgressCard
                    monthStatsCard
                    
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
            VStack(alignment: .leading, spacing: 3) {
                Text("STREAK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundStyle(streak > 0 ? .orange : .secondary)
                    Text(streak == 1 ? "day" : "days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Flame stack
            if streak > 0 {
                HStack(spacing: -4) {
                    ForEach(0..<min(streak, 5), id: \.self) { _ in
                        Text("🔥")
                            .font(.system(size: 14))
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
            Text("THIS WEEK")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.darkGray), lineWidth: 7)
                    .frame(width: 64, height: 64)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: weekProgress)
                    .stroke(
                        weekProgress >= 1.0
                            ? LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: weekProgress)
                
                VStack(spacing: 0) {
                    Text("\(weekSessions.count)")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(weekProgress >= 1.0 ? .green : .primary)
                    Text("of \(weeklyGoal)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Time this week
            Text(DateFormatters.formatDuration(sessionTracker.totalTimeThisWeek(allSessions: sessions)))
                .font(.system(.caption2, design: .monospaced).bold())
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue.opacity(0.08))
                .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Month Stats Card
    
    private var monthStatsCard: some View {
        VStack(spacing: 6) {
            HStack {
                Text("THIS MONTH")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
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
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.green.opacity(0.05))
                .strokeBorder(.green.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Best Session Card
    
    private func bestSessionCard(_ session: WorkoutSession) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text("🏆")
                    .font(.caption)
                Text("PERSONAL BEST")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.yellow)
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
