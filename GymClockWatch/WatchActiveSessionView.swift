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
        VStack(spacing: 4) {
            if let session = sessionTracker.activeSession {
                Text(session.gymName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Larger, more prominent timer
            Text(DateFormatters.formatElapsed(sessionTracker.elapsedTime))
                .font(.system(size: 52, weight: .heavy, design: .monospaced))
                .foregroundStyle(.green)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if let session = sessionTracker.activeSession {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("~\(session.estimatedCalories) cal")
                        .foregroundStyle(.orange)
                }
                .font(.caption2)

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
        VStack(spacing: 10) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)

            Text("GymClock")
                .font(.headline)

            // Motivational quote
            Text(MotivationalQuotes.todaysQuote)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 4)

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
