import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(sort: \GymLocation.name) private var gyms: [GymLocation]
    @State private var selectedGym: GymLocation?
    @State private var selectedWorkoutType: WorkoutType = .other
    @State private var showNotesField = false
    @State private var sessionNotes = ""

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
        VStack(spacing: 24) {
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

            // Workout Type Picker
            HStack(spacing: 12) {
                ForEach(WorkoutType.allCases) { type in
                    Button(action: {
                        selectedWorkoutType = type
                        sessionTracker.activeSession?.workoutType = type
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.title3)
                            Text(type.rawValue)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedWorkoutType == type
                                ? Color.green.opacity(0.2)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedWorkoutType == type ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .foregroundStyle(selectedWorkoutType == type ? .green : .secondary)
                }
            }

            // Check-in time & estimated calories
            if let session = sessionTracker.activeSession {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Checked in at \(DateFormatters.timeFormatter.string(from: session.checkInTime))")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "flame.fill")
                        Text("~\(session.estimatedCalories) cal burned")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                }
            }

            // Notes toggle
            Button(action: { showNotesField.toggle() }) {
                HStack {
                    Image(systemName: "note.text")
                    Text(showNotesField ? "Hide Notes" : "Add Notes")
                }
                .font(.subheadline)
                .foregroundStyle(.green)
            }

            if showNotesField {
                TextField("What did you work on?", text: $sessionNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .onChange(of: sessionNotes) { _, newValue in
                        sessionTracker.activeSession?.notes = newValue
                    }
            }

            Spacer()

            // Check Out Button
            Button(action: {
                sessionTracker.activeSession?.notes = sessionNotes
                sessionTracker.activeSession?.workoutType = selectedWorkoutType
                sessionTracker.endSession()
                sessionNotes = ""
                showNotesField = false
            }) {
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
        VStack(spacing: 24) {
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

            // Motivational Quote
            Text("💪 \"\(MotivationalQuotes.todaysQuote)\"")
                .font(.footnote.italic())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
