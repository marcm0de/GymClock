import SwiftUI
import SwiftData

struct WatchHistoryView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]

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
                List {
                    // Streak
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(sessionTracker.currentStreak(allSessions: sessions)) day streak")
                            .font(.caption)
                    }
                    .listRowBackground(Color.clear)

                    // Recent sessions
                    ForEach(sessions.prefix(10)) { session in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(session.gymName)
                                    .font(.caption.bold())
                                Spacer()
                                Text(session.shortDuration)
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }

                            Text(DateFormatters.fullFormatter.string(from: session.checkInTime))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
