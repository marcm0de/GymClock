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
            weeklySessionsThisWeek: 3
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
            weeklySessionsThisWeek: 3
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GymClockEntry>) -> Void) {
        let weeklyGoal = UserDefaults.standard.integer(forKey: "weeklyGoal")
        let effectiveGoal = weeklyGoal > 0 ? weeklyGoal : 5
        
        let entry = GymClockEntry(
            date: Date(),
            isActive: false,
            elapsedTime: 0,
            weeklyTotal: 0,
            streak: 0,
            weeklyGoal: effectiveGoal,
            weeklySessionCount: 0,
            weeklySessionsThisWeek: 0
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
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
    
    // Circular: current streak count with ring
    private var circularView: some View {
        ZStack {
            // Progress ring
            if !entry.isActive {
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
            }
            
            VStack(spacing: 0) {
                if entry.isActive {
                    Image(systemName: "figure.run")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                    Text(DateFormatters.formatDuration(entry.elapsedTime))
                        .font(.system(size: 10, design: .monospaced))
                        .minimumScaleFactor(0.5)
                } else {
                    Text("\(entry.streak)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("🔥")
                        .font(.system(size: 10))
                }
            }
        }
    }
    
    // Rectangular: "3/5 days this week" progress
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                Text("GymClock")
                    .font(.caption.bold())
            }
            
            if entry.isActive {
                Text("Active: \(DateFormatters.formatDuration(entry.elapsedTime))")
                    .font(.caption2)
                    .foregroundStyle(.green)
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
                    Text("🔥 \(entry.streak) day streak")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
    
    // Inline: "🔥 5 day streak"
    private var inlineView: some View {
        HStack {
            if entry.isActive {
                Image(systemName: "figure.run")
                Text("\(DateFormatters.formatDuration(entry.elapsedTime))")
            } else {
                Text("🔥 \(entry.streak) day streak · \(entry.weeklySessionsThisWeek)/\(entry.weeklyGoal) wk")
            }
        }
    }
    
    // Corner: session count this week
    private var cornerView: some View {
        VStack {
            Text("\(entry.weeklySessionsThisWeek)")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(.green)
            Text("this wk")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Quick Start Complication

struct QuickStartProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickStartEntry {
        QuickStartEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickStartEntry) -> Void) {
        completion(QuickStartEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickStartEntry>) -> Void) {
        let entry = QuickStartEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct QuickStartEntry: TimelineEntry {
    let date: Date
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
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("Start")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                }
            }
        case .accessoryRectangular:
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Quick Start")
                        .font(.caption.bold())
                    Text("Tap to begin session")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        case .accessoryInline:
            HStack {
                Image(systemName: "play.fill")
                Text("Quick Start Workout")
            }
        default:
            Image(systemName: "play.circle.fill")
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
        .description("Tap to immediately start a manual gym session.")
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
    GymClockEntry(date: .now, isActive: true, elapsedTime: 2700, weeklyTotal: 7200, streak: 5, weeklyGoal: 5, weeklySessionCount: 3, weeklySessionsThisWeek: 3)
    GymClockEntry(date: .now, isActive: false, elapsedTime: 0, weeklyTotal: 7200, streak: 5, weeklyGoal: 5, weeklySessionCount: 3, weeklySessionsThisWeek: 3)
}
