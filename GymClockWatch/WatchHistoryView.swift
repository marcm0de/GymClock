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

    var body: some View {
        NavigationStack {
            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No history yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        // Streak with color coding
                        let streak = sessionTracker.currentStreak(allSessions: sessions)
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(streak > 0 ? .orange : .gray)
                            Text("\(streak) day streak")
                                .font(.caption)
                                .foregroundStyle(streak > 0 ? .primary : .secondary)
                        }
                        .padding(.bottom, 4)

                        // Personal best ID
                        let bestId = sessions.max(by: { $0.duration < $1.duration })?.id

                        // Recent sessions
                        ForEach(sessions.prefix(15)) { session in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(session.gymName)
                                        .font(.caption.bold())

                                    if session.id == bestId {
                                        Text("🏆")
                                            .font(.caption2)
                                    }

                                    Spacer()

                                    Text(session.shortDuration)
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }

                                HStack {
                                    Text(DateFormatters.fullFormatter.string(from: session.checkInTime))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    if session.calories > 0 {
                                        Text("\(session.calories) cal")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .focusable()
                .digitalCrownRotation($crownValue, from: 0, through: Double(sessions.count), sensitivity: .medium)
                .navigationTitle("History")
            }
        }
    }
}

#Preview {
    WatchHistoryView()
        .environmentObject(SessionTracker())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
