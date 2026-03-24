import SwiftUI
import SwiftData

struct WatchActiveSessionView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(sort: \GymLocation.name) private var gyms: [GymLocation]
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var completedSessions: [WorkoutSession]
    
    @State private var selectedWorkoutIndex: Double = 0
    @State private var previousWorkoutIndex: Int = 0
    @State private var animateTimer = false
    @State private var calorieCount: Int = 0
    
    private let workoutTypes = WorkoutType.allCases
    
    private var currentWorkoutType: WorkoutType {
        let index = Int(selectedWorkoutIndex) % workoutTypes.count
        return workoutTypes[max(0, min(index, workoutTypes.count - 1))]
    }
    
    var body: some View {
        if sessionTracker.isTracking {
            activeView
        } else {
            idleView
        }
    }
    
    // MARK: - Active Session View
    
    private var activeView: some View {
        ScrollView {
            VStack(spacing: 6) {
                // Workout type badge
                if let session = sessionTracker.activeSession {
                    HStack(spacing: 4) {
                        Image(systemName: session.workoutType.icon)
                            .font(.caption2)
                        Text(session.gymName)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }
                
                // HERO: Large monospaced timer
                Text(DateFormatters.formatElapsed(sessionTracker.elapsedTime))
                    .font(.system(size: 64, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.green)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 0)
                    .scaleEffect(animateTimer ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateTimer)
                    .onAppear { animateTimer = true }
                
                // Heart rate + calories row
                HStack(spacing: 16) {
                    // Heart rate placeholder
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                            .symbolEffect(.pulse)
                        Text("--")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red.opacity(0.7))
                        Text("bpm")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Calorie counter
                    if let session = sessionTracker.activeSession {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("\(session.estimatedCalories)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.orange)
                                .contentTransition(.numericText(value: Double(session.estimatedCalories)))
                            Text("cal")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Duration since
                if let session = sessionTracker.activeSession {
                    Text("Started \(DateFormatters.timeFormatter.string(from: session.checkInTime))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                // Stop button
                Button(action: {
                    HapticManager.shared.workoutEnded()
                    sessionTracker.endSession()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.circle.fill")
                            .font(.body)
                        Text("End Workout")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .tint(.red)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Idle View
    
    private var idleView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // App icon
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                    .padding(.top, 4)
                
                Text("GymClock")
                    .font(.headline.bold())
                    .foregroundStyle(.green)
                
                // Workout type selector with digital crown
                VStack(spacing: 4) {
                    Text("Workout Type")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 12) {
                        ForEach(Array(workoutTypes.enumerated()), id: \.element.id) { index, type in
                            VStack(spacing: 2) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(index == Int(selectedWorkoutIndex) % workoutTypes.count ? .green : .gray)
                                    .scaleEffect(index == Int(selectedWorkoutIndex) % workoutTypes.count ? 1.2 : 0.9)
                                    .animation(.spring(response: 0.3), value: selectedWorkoutIndex)
                                
                                if index == Int(selectedWorkoutIndex) % workoutTypes.count {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .onTapGesture {
                                selectedWorkoutIndex = Double(index)
                                HapticManager.shared.crownDetent()
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Quick stats row
                let weekSessions = sessionTracker.sessionsThisWeek(allSessions: completedSessions)
                let streak = sessionTracker.currentStreak(allSessions: completedSessions)
                
                HStack(spacing: 12) {
                    VStack(spacing: 1) {
                        Text("\(weekSessions.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                        Text("this wk")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 1) {
                        Text("🔥\(streak)")
                            .font(.caption.bold())
                        Text("streak")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Start button
                if let gym = gyms.first {
                    Button(action: {
                        HapticManager.shared.workoutStarted()
                        sessionTracker.startSession(gymName: gym.name)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.body)
                            Text("Start Workout")
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .tint(.green)
                    .clipShape(Capsule())
                } else {
                    Button(action: {
                        HapticManager.shared.workoutStarted()
                        sessionTracker.startSession(gymName: "Quick Session")
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.body)
                            Text("Quick Start")
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .tint(.green)
                    .clipShape(Capsule())
                }
                
                // Motivational quote
                Text(MotivationalQuotes.todaysQuote)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 4)
        }
        .focusable()
        .digitalCrownRotation(
            $selectedWorkoutIndex,
            from: 0,
            through: Double(workoutTypes.count - 1),
            by: 1,
            sensitivity: .low,
            isContinuous: false
        )
        .onChange(of: selectedWorkoutIndex) { oldValue, newValue in
            let newIndex = Int(newValue) % workoutTypes.count
            if newIndex != previousWorkoutIndex {
                HapticManager.shared.crownDetent()
                previousWorkoutIndex = newIndex
            }
        }
    }
}

#Preview {
    WatchActiveSessionView()
        .environmentObject(SessionTracker())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
