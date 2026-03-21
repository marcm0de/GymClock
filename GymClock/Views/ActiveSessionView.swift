import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(sort: \GymLocation.name) private var gyms: [GymLocation]
    @State private var selectedGym: GymLocation?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if sessionTracker.isTracking {
                    activeSessionContent
                } else {
                    idleContent
                }
            }
            .padding()
            .navigationTitle("GymClock")
        }
    }

    // MARK: - Active Session

    private var activeSessionContent: some View {
        VStack(spacing: 32) {
            Spacer()

            // Gym Name
            if let session = sessionTracker.activeSession {
                Text(session.gymName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            // Timer Display
            Text(DateFormatters.formatElapsed(sessionTracker.elapsedTime))
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundStyle(.green)
                .contentTransition(.numericText())

            // Check-in time
            if let session = sessionTracker.activeSession {
                HStack {
                    Image(systemName: "clock")
                    Text("Checked in at \(DateFormatters.timeFormatter.string(from: session.checkInTime))")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Check Out Button
            Button(action: { sessionTracker.endSession() }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Check Out")
                }
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red, in: RoundedRectangle(cornerRadius: 16))
            }

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Session Active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Idle State

    private var idleContent: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Ready to Work Out?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Auto-detection is active. You'll be checked in when you arrive at your gym.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Manual Check In
            VStack(spacing: 12) {
                if let gym = gyms.first {
                    Button(action: {
                        sessionTracker.startSession(gymName: gym.name)
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Check In to \(gym.name)")
                        }
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green, in: RoundedRectangle(cornerRadius: 16))
                    }
                }

                if gyms.count > 1 {
                    Menu {
                        ForEach(gyms) { gym in
                            Button(gym.name) {
                                sessionTracker.startSession(gymName: gym.name)
                            }
                        }
                    } label: {
                        Text("Choose another gym")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
            }

            // Geofence status
            HStack(spacing: 8) {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)
                Text("Monitoring \(gyms.count) location\(gyms.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ActiveSessionView()
        .environmentObject(SessionTracker())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
