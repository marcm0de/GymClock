import SwiftUI
import SwiftData

struct WatchHistoryView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    
    @State private var crownValue: Double = 0.0
    
    /// Group sessions by day, returning an array of (date, [sessions]) tuples
    private var groupedSessions: [(date: Date, sessions: [WorkoutSession])] {
        let calendar = Calendar.current
        let limited = Array(sessions.prefix(10))
        let grouped = Dictionary(grouping: limited) { session in
            calendar.startOfDay(for: session.checkInTime)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, sessions: $0.value.sorted { $0.checkInTime > $1.checkInTime }) }
    }
    
    /// ID of the personal best (longest) session
    private var personalBestId: UUID? {
        sessions.max(by: { $0.duration < $1.duration })?.id
    }
    
    /// Weekly summary data
    private var weeklySummary: (sessions: Int, totalTime: TimeInterval, totalCalories: Int) {
        let weekSessions = sessionTracker.sessionsThisWeek(allSessions: sessions)
        let totalTime = weekSessions.reduce(0) { $0 + $1.duration }
        let totalCalories = weekSessions.reduce(0) { $0 + ($1.calories > 0 ? $1.calories : $1.estimatedCalories) }
        return (weekSessions.count, totalTime, totalCalories)
    }
    
    var body: some View {
        NavigationStack {
            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No workouts yet")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Start your first session!")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
    
    // MARK: - Session List
    
    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Weekly summary card
                weeklySummaryCard
                
                // Grouped sessions by day
                ForEach(groupedSessions, id: \.date) { group in
                    daySection(date: group.date, sessions: group.sessions)
                }
            }
            .padding(.horizontal, 4)
        }
        .focusable()
        .digitalCrownRotation($crownValue, from: 0, through: Double(sessions.count), sensitivity: .medium)
        .navigationTitle("History")
    }
    
    // MARK: - Weekly Summary Card
    
    private var weeklySummaryCard: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("This Week")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                Spacer()
            }
            
            HStack(spacing: 0) {
                // Sessions count
                VStack(spacing: 2) {
                    Text("\(weeklySummary.sessions)")
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundStyle(.white)
                    Text("sessions")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 1, height: 24)
                
                // Total time
                VStack(spacing: 2) {
                    Text(DateFormatters.formatDuration(weeklySummary.totalTime))
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(.white)
                    Text("total")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 1, height: 24)
                
                // Calories
                VStack(spacing: 2) {
                    Text("\(weeklySummary.totalCalories)")
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
                .fill(.green.opacity(0.1))
                .strokeBorder(.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Day Section
    
    private func daySection(date: Date, sessions: [WorkoutSession]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day header
            HStack {
                Text(dayLabel(for: date))
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.top, 4)
            
            // Session entries
            ForEach(sessions) { session in
                sessionRow(session)
            }
        }
    }
    
    private func sessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                // Workout type icon
                Image(systemName: session.workoutType.icon)
                    .font(.caption2)
                    .foregroundStyle(workoutColor(session.workoutType))
                    .frame(width: 14)
                
                Text(session.gymName)
                    .font(.caption2.bold())
                    .lineLimit(1)
                
                // Personal best trophy
                if session.id == personalBestId {
                    Text("🏆")
                        .font(.system(size: 10))
                }
                
                Spacer()
                
                // Duration
                Text(session.shortDuration)
                    .font(.system(.caption2, design: .monospaced).bold())
                    .foregroundStyle(.green)
            }
            
            HStack {
                Text(DateFormatters.timeFormatter.string(from: session.checkInTime))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                let effectiveCal = session.calories > 0 ? session.calories : session.estimatedCalories
                if effectiveCal > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                        Text("~\(effectiveCal) cal")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Helpers
    
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return DateFormatters.shortDateFormatter.string(from: date)
        }
    }
    
    private func workoutColor(_ type: WorkoutType) -> Color {
        switch type {
        case .weights: return .blue
        case .cardio: return .orange
        case .mixed: return .purple
        case .other: return .gray
        }
    }
}

#Preview {
    WatchHistoryView()
        .environmentObject(SessionTracker())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
