import SwiftUI

struct WatchSettingsView: View {
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 5
    @AppStorage("defaultWorkoutType") private var defaultWorkoutType: String = WorkoutType.other.rawValue
    @AppStorage("hapticFeedbackEnabled") private var hapticEnabled: Bool = true
    
    @State private var goalCrownValue: Double = 5
    @State private var previousGoalValue: Int = 5
    
    private let workoutTypes = WorkoutType.allCases
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Weekly goal section
                    weeklyGoalSection
                    
                    // Default workout type
                    workoutTypeSection
                    
                    // Haptic feedback toggle
                    hapticSection
                    
                    // Connectivity status
                    connectivitySection
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Settings")
            .onAppear {
                goalCrownValue = Double(weeklyGoal)
                previousGoalValue = weeklyGoal
            }
        }
    }
    
    // MARK: - Weekly Goal
    
    private var weeklyGoalSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "target")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("Weekly Goal")
                    .font(.caption2.bold())
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text("\(weeklyGoal)")
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(.green)
                    .contentTransition(.numericText(value: Double(weeklyGoal)))
                Text("sessions/week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Visual dots for goal
            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { day in
                    Circle()
                        .fill(day <= weeklyGoal ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .animation(.spring(response: 0.3), value: weeklyGoal)
                }
            }
            
            Text("Use Digital Crown to adjust")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.green.opacity(0.05))
                .strokeBorder(.green.opacity(0.2), lineWidth: 1)
        )
        .focusable()
        .digitalCrownRotation(
            $goalCrownValue,
            from: 1,
            through: 7,
            by: 1,
            sensitivity: .low,
            isContinuous: false
        )
        .onChange(of: goalCrownValue) { oldValue, newValue in
            let newGoal = max(1, min(7, Int(newValue)))
            if newGoal != previousGoalValue {
                weeklyGoal = newGoal
                previousGoalValue = newGoal
                HapticManager.shared.crownDetent()
                
                // Sync to iPhone
                WatchConnectivityManager.shared.syncWeeklyGoal(newGoal)
            }
        }
    }
    
    // MARK: - Workout Type
    
    private var workoutTypeSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "figure.mixed.cardio")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Default Type")
                    .font(.caption2.bold())
                Spacer()
            }
            
            HStack(spacing: 8) {
                ForEach(workoutTypes) { type in
                    Button(action: {
                        defaultWorkoutType = type.rawValue
                        HapticManager.shared.crownDetent()
                        WatchConnectivityManager.shared.syncPreferences(
                            defaultWorkoutType: type.rawValue,
                            hapticEnabled: hapticEnabled
                        )
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: type.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(defaultWorkoutType == type.rawValue ? .green : .gray)
                            
                            Text(type.rawValue)
                                .font(.system(size: 7))
                                .foregroundStyle(defaultWorkoutType == type.rawValue ? .green : .secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(defaultWorkoutType == type.rawValue ? .green.opacity(0.15) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue.opacity(0.05))
        )
    }
    
    // MARK: - Haptic Feedback
    
    private var hapticSection: some View {
        HStack {
            Image(systemName: "waveform.path")
                .font(.caption2)
                .foregroundStyle(.purple)
            
            Text("Haptics")
                .font(.caption2.bold())
            
            Spacer()
            
            Toggle("", isOn: $hapticEnabled)
                .labelsHidden()
                .tint(.green)
                .onChange(of: hapticEnabled) { oldValue, newValue in
                    HapticManager.shared.isEnabled = newValue
                    if newValue {
                        HapticManager.shared.success()
                    }
                }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.purple.opacity(0.05))
        )
    }
    
    // MARK: - Connectivity
    
    private var connectivitySection: some View {
        HStack {
            Image(systemName: "applewatch.and.arrow.forward")
                .font(.caption2)
                .foregroundStyle(.cyan)
            
            Text("Phone Sync")
                .font(.caption2)
            
            Spacer()
            
            HStack(spacing: 3) {
                Circle()
                    .fill(WatchConnectivityManager.shared.isReachable ? .green : .gray)
                    .frame(width: 6, height: 6)
                Text(WatchConnectivityManager.shared.isReachable ? "Connected" : "Offline")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.cyan.opacity(0.05))
        )
    }
}

#Preview {
    WatchSettingsView()
}
