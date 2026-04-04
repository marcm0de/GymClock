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
            VStack(spacing: 4) {
                // Workout type + gym badge
                if let session = sessionTracker.activeSession {
                    HStack(spacing: 4) {
                        Image(systemName: session.workoutType.icon)
                            .font(.system(size: 10))
                        Text(session.gymName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.green.opacity(0.8))
                    .padding(.top, 2)
                }
                
                // HERO: Maximum-size monospaced timer
                Text(DateFormatters.formatElapsed(sessionTracker.elapsedTime))
                    .font(.system(size: 72, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.green)
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 0)
                    .padding(.vertical, 2)
                
                // Compact info row: calories + time
                HStack(spacing: 14) {
                    if let session = sessionTracker.activeSession {
                        // Calorie counter
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 11))
                            Text("\(session.estimatedCalories)")
                                .font(.system(.caption, design: .monospaced).bold())
                                .foregroundStyle(.orange)
                                .contentTransition(.numericText(value: Double(session.estimatedCalories)))
                        }
                        
                        // Start time
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(DateFormatters.timeFormatter.string(from: session.checkInTime))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer(minLength: 10)
                
                // Stop button — large, clear target
                Button(action: {
                    HapticManager.shared.workoutEnded()
                    sessionTracker.endSession()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.caption)
                        Text("End Workout")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .tint(.red)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 4)
        }
        .onAppear { animateTimer = true }
    }
    
    // MARK: - Idle View
    
    private var idleView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Compact header
                VStack(spacing: 2) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 28))
                        .foregroundStyle(.green)
                        .padding(.top, 4)
                    
                    Text("GymClock")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(.green)
                }
                
                // Workout type selector
                HStack(spacing: 10) {
                    ForEach(Array(workoutTypes.enumerated()), id: \.element.id) { index, type in
                        let isSelected = index == Int(selectedWorkoutIndex) % workoutTypes.count
                        VStack(spacing: 3) {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(.green.opacity(0.15))
                                        .frame(width: 28, height: 28)
                                }
                                Image(systemName: type.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(isSelected ? .green : .gray)
                            }
                            
                            Text(type.rawValue)
                                .font(.system(size: 7, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .green : .secondary)
                        }
                        .onTapGesture {
                            selectedWorkoutIndex = Double(index)
                            HapticManager.shared.crownDetent()
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Quick stats
                let weekSessions = sessionTracker.sessionsThisWeek(allSessions: completedSessions)
                let streak = sessionTracker.currentStreak(allSessions: completedSessions)
                
                HStack(spacing: 14) {
                    VStack(spacing: 1) {
                        Text("\(weekSessions.count)")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(.green)
                        Text("this wk")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 1) {
                        Text("🔥\(streak)")
                            .font(.system(.caption, design: .rounded).bold())
                        Text("streak")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Start button
                Button(action: {
                    HapticManager.shared.workoutStarted()
                    let gymName = gyms.first?.name ?? "Quick Session"
                    sessionTracker.startSession(gymName: gymName)
                    sessionTracker.activeSession?.workoutType = currentWorkoutType
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text(gyms.first != nil ? "Start Workout" : "Quick Start")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .tint(.green)
                .clipShape(Capsule())
                
                if gyms.count > 1 {
                    Menu {
                        ForEach(gyms) { gym in
                            Button(gym.name) {
                                HapticManager.shared.workoutStarted()
                                sessionTracker.startSession(gymName: gym.name)
                                sessionTracker.activeSession?.workoutType = currentWorkoutType
                            }
                        }
                    } label: {
                        Text("Other gyms")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
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
