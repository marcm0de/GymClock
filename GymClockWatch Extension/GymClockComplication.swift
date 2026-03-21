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
            streak: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GymClockEntry) -> Void) {
        let entry = GymClockEntry(
            date: Date(),
            isActive: false,
            elapsedTime: 0,
            weeklyTotal: 5400,
            streak: 5
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GymClockEntry>) -> Void) {
        let entry = GymClockEntry(
            date: Date(),
            isActive: false,
            elapsedTime: 0,
            weeklyTotal: 0,
            streak: 0
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

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: entry.isActive ? "figure.run" : "dumbbell.fill")
                    .font(.caption)
                if entry.isActive {
                    Text(DateFormatters.formatDuration(entry.elapsedTime))
                        .font(.system(.caption2, design: .monospaced))
                        .minimumScaleFactor(0.6)
                } else {
                    Text("\(entry.streak)🔥")
                        .font(.caption2)
                }
            }
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                Text("GymClock")
                    .font(.caption.bold())
            }

            if entry.isActive {
                Text("Active: \(DateFormatters.formatDuration(entry.elapsedTime))")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else {
                Text("Week: \(DateFormatters.formatDuration(entry.weeklyTotal))")
                    .font(.caption2)
                Text("Streak: \(entry.streak) days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var inlineView: some View {
        HStack {
            Image(systemName: "figure.run")
            if entry.isActive {
                Text("\(DateFormatters.formatDuration(entry.elapsedTime))")
            } else {
                Text("\(entry.streak)🔥 · \(DateFormatters.formatDuration(entry.weeklyTotal))/wk")
            }
        }
    }

    private var cornerView: some View {
        VStack {
            Image(systemName: entry.isActive ? "figure.run" : "dumbbell.fill")
            if entry.isActive {
                Text(DateFormatters.formatDuration(entry.elapsedTime))
                    .font(.system(.caption2, design: .monospaced))
            }
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
        .description("Track your gym sessions and streaks.")
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
    GymClockEntry(date: .now, isActive: true, elapsedTime: 2700, weeklyTotal: 7200, streak: 5)
    GymClockEntry(date: .now, isActive: false, elapsedTime: 0, weeklyTotal: 7200, streak: 5)
}
