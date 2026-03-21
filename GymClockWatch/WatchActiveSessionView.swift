import SwiftUI
import SwiftData

struct WatchActiveSessionView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(sort: \GymLocation.name) private var gyms: [GymLocation]

    var body: some View {
        if sessionTracker.isTracking {
            activeView
        } else {
            idleView
        }
    }

    // MARK: - Active Session

    private var activeView: some View {
        VStack(spacing: 8) {
            if let session = sessionTracker.activeSession {
                Text(session.gymName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(DateFormatters.formatElapsed(sessionTracker.elapsedTime))
                .font(.system(size: 42, weight: .bold, design: .monospaced))
                .foregroundStyle(.green)
                .minimumScaleFactor(0.6)

            if let session = sessionTracker.activeSession {
                Text("Since \(DateFormatters.timeFormatter.string(from: session.checkInTime))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: { sessionTracker.endSession() }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("End")
                }
                .font(.caption.bold())
            }
            .tint(.red)
        }
        .padding()
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)

            Text("GymClock")
                .font(.headline)

            if let gym = gyms.first {
                Button(action: {
                    sessionTracker.startSession(gymName: gym.name)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Check In")
                    }
                    .font(.caption.bold())
                }
                .tint(.green)
            }

            Text("Auto-detect active")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    WatchActiveSessionView()
        .environmentObject(SessionTracker())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
