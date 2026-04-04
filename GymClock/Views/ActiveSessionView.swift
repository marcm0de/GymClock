import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @EnvironmentObject var achievementManager: AchievementManager
    @Query(sort: \GymLocation.name) private var gyms: [GymLocation]
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var completedSessions: [WorkoutSession]
    @State private var selectedGym: GymLocation?
    @State private var selectedWorkoutType: WorkoutType = .other
    @State private var showNotesField = false
    @State private var sessionNotes = ""
    @State private var showShareSheet = false
    @State private var lastShareText = ""
    @State private var timerPulse = false

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
        VStack(spacing: 20) {
            Spacer()

            // Gym Name + Live indicator
            if let session = sessionTracker.activeSession {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(timerPulse ? 1.3 : 0.8)
                        .opacity(timerPulse ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: timerPulse)
                    Text(session.gymName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .onAppear { timerPulse = true }
            }

            // Timer Display — hero element
            VStack(spacing: 0) {
                Text(DateFormatters.formatElapsed(sessionTracker.elapsedTime))
                    .font(.system(size: 80, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.green)
                    .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 0)
                    .contentTransition(.numericText())
            }
            .padding(.vertical, 8)

            // Workout Type Picker
            HStack(spacing: 10) {
                ForEach(WorkoutType.allCases) { type in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedWorkoutType = type
                            sessionTracker.activeSession?.workoutType = type
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.title3)
                                .symbolEffect(.bounce, value: selectedWorkoutType == type)
                            Text(type.rawValue)
                                .font(.caption2.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedWorkoutType == type ? Color.green.opacity(0.15) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedWorkoutType == type ? Color.green : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .foregroundStyle(selectedWorkoutType == type ? .green : .secondary)
                }
            }

            // Check-in time & estimated calories
            if let session = sessionTracker.activeSession {
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(DateFormatters.timeFormatter.string(from: session.checkInTime))
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                        Text("~\(session.estimatedCalories) cal")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.orange)
                }
            }

            // Notes with emoji shortcuts
            Button(action: { withAnimation { showNotesField.toggle() } }) {
                HStack(spacing: 4) {
                    Image(systemName: showNotesField ? "note.text.badge.plus" : "note.text")
                    Text(showNotesField ? "Hide Notes" : "Add Notes")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)
            }

            if showNotesField {
                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["💪", "🏋️", "🔥", "😤", "🎯", "⚡", "🦵", "💥", "🏃", "🧘"], id: \.self) { emoji in
                                Button(emoji) {
                                    sessionNotes += emoji
                                    sessionTracker.activeSession?.notes = sessionNotes
                                }
                                .font(.title3)
                                .padding(6)
                                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    
                    TextField("What did you work on?", text: $sessionNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                        .onChange(of: sessionNotes) { _, newValue in
                            sessionTracker.activeSession?.notes = newValue
                        }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()

            // Check Out Button — prominent, tactile feel
            Button(action: handleCheckOut) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                        .font(.body)
                    Text("Check Out")
                        .font(.title3.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Share after checkout
            if showShareSheet {
                ShareLink(item: lastShareText) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Workout")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                }
                .transition(.scale.combined(with: .opacity))
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Idle State

    private var idleContent: some View {
        VStack(spacing: 24) {
            Spacer()

            // Hero icon with subtle glow
            ZStack {
                Circle()
                    .fill(.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 8) {
                Text("Ready to Work Out?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Auto-detection is active. You'll be checked in when you arrive at your gym.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Motivational Quote
            Text("💪 \"\(MotivationalQuotes.todaysQuote)\"")
                .font(.footnote.italic())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Share last workout if available
            if let lastSession = completedSessions.first {
                let streak = sessionTracker.currentStreak(allSessions: completedSessions)
                ShareLink(
                    item: ShareManager.generateShareText(
                        session: lastSession,
                        streak: streak,
                        totalWorkouts: completedSessions.count
                    )
                ) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Last Workout")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.green)
                }
            }

            Spacer()

            // Manual Check In
            VStack(spacing: 12) {
                if gyms.isEmpty {
                    startButton(label: "Quick Start", gymName: "Quick Session")
                    
                    Text("Add a gym in Settings for auto-detection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let gym = gyms.first {
                    startButton(label: "Check In to \(gym.name)", gymName: gym.name)
                }

                if gyms.count > 1 {
                    Menu {
                        ForEach(gyms) { gym in
                            Button(gym.name) {
                                sessionTracker.startSession(gymName: gym.name)
                                showShareSheet = false
                            }
                        }
                    } label: {
                        Text("Choose another gym")
                            .font(.subheadline.weight(.medium))
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

    // MARK: - Helpers

    private func startButton(label: String, gymName: String) -> some View {
        Button(action: {
            sessionTracker.startSession(gymName: gymName)
            showShareSheet = false
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text(label)
                    .font(.title3.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func handleCheckOut() {
        guard let session = sessionTracker.activeSession else { return }
        session.notes = sessionNotes
        session.workoutType = selectedWorkoutType
        
        let streak = sessionTracker.currentStreak(allSessions: completedSessions)
        lastShareText = ShareManager.generateShareText(
            session: session,
            streak: streak,
            totalWorkouts: completedSessions.count + 1
        )
        
        sessionTracker.endSession()
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            achievementManager.checkAchievements(
                sessions: completedSessions,
                currentStreak: streak
            )
            sessionTracker.syncStatsToUserDefaults(allSessions: completedSessions)
        }
        
        sessionNotes = ""
        showNotesField = false
        withAnimation(.spring(response: 0.4)) {
            showShareSheet = true
        }
    }
}

#Preview {
    ActiveSessionView()
        .environmentObject(SessionTracker())
        .environmentObject(AchievementManager())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
