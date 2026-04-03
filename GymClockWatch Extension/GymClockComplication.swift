import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct GymClockTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GymClockEntry {
        GymClockEntry(
            date: Date(),
            isActive: false,
            elapsedTime: 0,
            weeklyTotal: 3600,
            streak: 3,
            weeklyGoal: 5,
            weeklySessionCount: 3,
            weeklySessionsThisWeek: 3,
            todaysCalories: 450
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GymClockEntry) -> Void) {
        let entry = GymClockEntry(
            date: Date(),
            isActive: false,
            elapsedTime: 0,
            weeklyTotal: 5400,
            streak: 5,
            weeklyGoal: 5,
            weeklySessionCount: 3,
            weeklySessionsThisWeek: 3,
            todaysCalories: 320
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GymClockEntry>) -> Void) {
        // Read from both possible keys for compatibility
        let weeklyGoalFromWatch = UserDefaults.standard.integer(forKey: "weeklyGoal")
        let weeklyGoalFromiOS = UserDefaults.standard.integer(forKey: "weeklyGoalDays")
        let effectiveGoal = max(weeklyGoalFromWatch, weeklyGoalFromiOS, 1)
        
        // Check for active session
        let isActive = UserDefaults.standard.bool(forKey: "gymclock_session_active")
        let sessionStart = UserDefaults.standard.double(forKey: "gymclock_session_start")
        let elapsed = isActive && sessionStart > 0 ? Date().timeIntervalSince1970 - sessionStart : 0
        
        // Read cached stats
        let streak = UserDefaults.standard.integer(forKey: "gymclock_streak")
        let weekSessions = UserDefaults.standard.integer(forKey: "gymclock_week_sessions")
        let weeklyTotal = UserDefaults.standard.double(forKey: "gymclock_weekly_total")
        let todaysCalories = UserDefaults.standard.integer(forKey: "gymclock_todays_calories")
        
        let entry = GymClockEntry(
            date: Date(),
            isActive: isActive,
            elapsedTime: elapsed,
            weeklyTotal: weeklyTotal,
            streak: streak,
            weeklyGoal: effectiveGoal,
            weeklySessionCount: weekSessions,
            weeklySessionsThisWeek: weekSessions,
            todaysCalories: todaysCalories
        )
        
        // Refresh more frequently during active sessions
        let refreshInterval: TimeInterval = isActive ? 60 : 900
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(refreshInterval)))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct GymClockEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let elapsedTime: TimeInterval
    let weeklyTotal: TimeInterval
    let streak: Int
    let weeklyGoal: Int
    let weeklySessionCount: Int
    let weeklySessionsThisWeek: Int
    let todaysCalories: Int
}

// MARK: - Complication Views

struct GymClockComplicationEntryView: View {
    var entry: GymClockEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
        default:
            circularView
        }
    }
    
    // Circular: streak with progress ring, or live timer during workout
    private var circularView: some View {
        ZStack {
            if entry.isActive {
                // Active session — show timer with pulsing ring
                Circle()
                    .stroke(.green.opacity(0.3), lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: min(entry.elapsedTime / 3600, 1.0))
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Text(formatCompactDuration(entry.elapsedTime))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                }
            } else {
                // Idle — show weekly goal progress ring
                let progress = entry.weeklyGoal > 0
                    ? Double(entry.weeklySessionsThisWeek) / Double(entry.weeklyGoal)
                    : 0
                
                Circle()
                    .stroke(.gray.opacity(0.3), lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        progress >= 1.0 ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    if entry.streak > 0 {
                        Text("\(entry.streak)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("🔥")
                            .font(.system(size: 10))
                    } else {
                        Text("\(entry.weeklySessionsThisWeek)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("/\(entry.weeklyGoal)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // Rectangular: rich summary with progress bar
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                Text("GymClock")
                    .font(.caption.bold())
                Spacer()
                if entry.isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 5, height: 5)
                }
            }
            
            if entry.isActive {
                HStack {
                    Text(formatCompactDuration(entry.elapsedTime))
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(.green)
                    Spacer()
                    if entry.todaysCalories > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                            Text("\(entry.todaysCalories)")
                                .font(.system(size: 10, design: .monospaced))
                        }
                        .foregroundStyle(.orange)
                    }
                }
            } else {
                // Progress bar
                let progress = entry.weeklyGoal > 0
                    ? Double(entry.weeklySessionsThisWeek) / Double(entry.weeklyGoal)
                    : 0
                
                HStack(spacing: 4) {
                    Text("\(entry.weeklySessionsThisWeek)/\(entry.weeklyGoal)")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(progress >= 1.0 ? .green : .primary)
                    
                    Text("days this week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if progress >= 1.0 {
                        Text("✅")
                            .font(.system(size: 9))
                    }
                }
                
                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(progress >= 1.0 ? Color.green : Color.blue)
                            .frame(width: geo.size.width * min(progress, 1.0), height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    if entry.streak > 0 {
                        Text("🔥 \(entry.streak) day streak")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if entry.todaysCalories > 0 {
                        Text("🔥 \(entry.todaysCalories) cal today")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // Inline: compact text
    private var inlineView: some View {
        HStack {
            if entry.isActive {
                Image(systemName: "figure.run")
                Text("\(formatCompactDuration(entry.elapsedTime))")
            } else if entry.streak > 0 {
                Text("🔥 \(entry.streak)d · \(entry.weeklySessionsThisWeek)/\(entry.weeklyGoal) wk")
            } else {
                Text("💪 \(entry.weeklySessionsThisWeek)/\(entry.weeklyGoal) this week")
            }
        }
    }
    
    // Corner: session count with icon
    private var cornerView: some View {
        VStack {
            Text("\(entry.weeklySessionsThisWeek)")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(entry.weeklySessionsThisWeek >= entry.weeklyGoal ? .green : .blue)
            Text("this wk")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Helpers
    
    private func formatCompactDuration(_ interval: TimeInterval) -> String {
        let total = Int(max(interval, 0))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Quick Start Complication

struct QuickStartProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickStartEntry {
        QuickStartEntry(date: Date(), isActive: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickStartEntry) -> Void) {
        let isActive = UserDefaults.standard.bool(forKey: "gymclock_session_active")
        completion(QuickStartEntry(date: Date(), isActive: isActive))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickStartEntry>) -> Void) {
        let isActive = UserDefaults.standard.bool(forKey: "gymclock_session_active")
        let entry = QuickStartEntry(date: Date(), isActive: isActive)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(isActive ? 60 : 3600)))
        completion(timeline)
    }
}

struct QuickStartEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
}

struct QuickStartComplicationView: View {
    var entry: QuickStartEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: entry.isActive ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(entry.isActive ? .red : .green)
                    Text(entry.isActive ? "Stop" : "Start")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                }
            }
        case .accessoryRectangular:
            HStack {
                Image(systemName: entry.isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(entry.isActive ? .red : .green)
                VStack(alignment: .leading) {
                    Text(entry.isActive ? "End Workout" : "Quick Start")
                        .font(.caption.bold())
                    Text(entry.isActive ? "Tap to stop session" : "Tap to begin session")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        case .accessoryInline:
            HStack {
                Image(systemName: entry.isActive ? "stop.fill" : "play.fill")
                Text(entry.isActive ? "End Workout" : "Quick Start Workout")
            }
        default:
            Image(systemName: entry.isActive ? "stop.circle.fill" : "play.circle.fill")
                .foregroundStyle(entry.isActive ? .red : .green)
        }
    }
}

// MARK: - Main Widget

@main
struct GymClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        GymClockComplication()
        QuickStartComplication()
    }
}

struct GymClockComplication: Widget {
    let kind: String = "GymClockComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymClockTimelineProvider()) { entry in
            GymClockComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("GymClock")
        .description("Track your gym sessions, streaks, and weekly progress.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct QuickStartComplication: Widget {
    let kind: String = "GymClockQuickStart"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickStartProvider()) { entry in
            QuickStartComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Start")
        .description("Tap to immediately start or stop a gym session.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    GymClockComplication()
} timeline: {
    GymClockEntry(date: .now, isActive: true, elapsedTime: 2700, weeklyTotal: 7200, streak: 5, weeklyGoal: 5, weeklySessionCount: 3, weeklySessionsThisWeek: 3, todaysCalories: 450)
    GymClockEntry(date: .now, isActive: false, elapsedTime: 0, weeklyTotal: 7200, streak: 5, weeklyGoal: 5, weeklySessionCount: 3, weeklySessionsThisWeek: 3, todaysCalories: 0)
}
