import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    @State private var selectedPeriod: TimePeriod = .week
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var sessionToDelete: WorkoutSession?
    @Environment(\.modelContext) private var modelContext

    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Summary
                summaryCard

                // Sessions List
                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "figure.walk",
                        description: Text("Hit the gym to see your history here")
                    )
                } else {
                    List {
                        ForEach(weeklyGroups, id: \.weekStart) { weekGroup in
                            Section {
                                ForEach(weekGroup.sessions) { session in
                                    SessionRow(
                                        session: session,
                                        isPersonalBest: session.id == longestSessionId,
                                        showFullNotes: true
                                    )
                                }
                                .onDelete { indexSet in
                                    deleteSessions(daySessions: weekGroup.sessions, at: indexSet)
                                }
                            } header: {
                                WeeklySummaryHeader(group: weekGroup)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search notes, gyms...")
        }
    }

    // MARK: - Longest Session ID

    private var longestSessionId: UUID? {
        sessions.max(by: { $0.duration < $1.duration })?.id
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let filtered = filteredSessions
        let totalTime = filtered.reduce(0) { $0 + $1.duration }
        let avgTime = filtered.isEmpty ? 0 : totalTime / Double(filtered.count)
        let totalCals = filtered.reduce(0) { $0 + ($1.calories > 0 ? $1.calories : $1.estimatedCalories) }

        return HStack(spacing: 10) {
            StatBadge(title: "Sessions", value: "\(filtered.count)", icon: "checkmark.circle", color: .green)
            StatBadge(title: "Total", value: DateFormatters.formatDuration(totalTime), icon: "clock.fill", color: .blue)
            StatBadge(title: "Avg", value: DateFormatters.formatDuration(avgTime), icon: "chart.line.uptrend.xyaxis", color: .purple)
            StatBadge(title: "Cals", value: "\(totalCals)", icon: "flame.fill", color: .orange)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Filtering

    private var filteredSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()

        var result: [WorkoutSession]
        switch selectedPeriod {
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            result = sessions.filter { $0.checkInTime >= start }
        case .month:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            result = sessions.filter { $0.checkInTime >= start }
        case .all:
            result = sessions
        }
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { session in
                session.notes.lowercased().contains(query) ||
                session.gymName.lowercased().contains(query) ||
                session.workoutType.rawValue.lowercased().contains(query)
            }
        }
        
        return result
    }

    // MARK: - Weekly Grouping

    private var weeklyGroups: [WeekGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.checkInTime)?.start ?? session.checkInTime
        }

        return grouped.map { weekStart, sessions in
            let sorted = sessions.sorted { $0.checkInTime > $1.checkInTime }
            let totalTime = sorted.reduce(0.0) { $0 + $1.duration }
            let totalCals = sorted.reduce(0) { $0 + ($1.calories > 0 ? $1.calories : $1.estimatedCalories) }

            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let startStr = DateFormatters.shortDateFormatter.string(from: weekStart)
            let endStr = DateFormatters.shortDateFormatter.string(from: weekEnd)
            let label = "\(startStr) – \(endStr)"

            return WeekGroup(
                weekStart: weekStart,
                label: label,
                sessions: sorted,
                totalTime: totalTime,
                totalCalories: totalCals
            )
        }
        .sorted { $0.weekStart > $1.weekStart }
    }

    private func deleteSessions(daySessions: [WorkoutSession], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(daySessions[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Week Group

struct WeekGroup {
    let weekStart: Date
    let label: String
    let sessions: [WorkoutSession]
    let totalTime: TimeInterval
    let totalCalories: Int
}

// MARK: - Weekly Summary Header (promoted to section header)

struct WeeklySummaryHeader: View {
    let group: WeekGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.label)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            HStack(spacing: 16) {
                Label("\(group.sessions.count) sessions", systemImage: "checkmark.circle.fill")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.green)

                Label(DateFormatters.formatDuration(group.totalTime), systemImage: "clock.fill")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.blue)

                if group.totalCalories > 0 {
                    Label("~\(group.totalCalories) cal", systemImage: "flame.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: WorkoutSession
    var isPersonalBest: Bool = false
    var showFullNotes: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Left accent — workout type color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(workoutColor)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: session.workoutType.icon)
                        .font(.caption)
                        .foregroundStyle(workoutColor)

                    Text(session.gymName)
                        .font(.subheadline.bold())

                    if isPersonalBest {
                        Text("🏆 PB")
                            .font(.caption2.bold())
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.yellow.opacity(0.15), in: Capsule())
                    }
                }

                HStack(spacing: 4) {
                    Text(DateFormatters.dayOfWeekFormatter.string(from: session.checkInTime))
                        .foregroundStyle(.primary.opacity(0.6))
                    Text("·")
                    Text(DateFormatters.timeFormatter.string(from: session.checkInTime))
                    if let checkout = session.checkOutTime {
                        Text("–")
                        Text(DateFormatters.timeFormatter.string(from: checkout))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Notes
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(showFullNotes ? 5 : 1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 6))
                }
            }

            Spacer()

            // Right side — duration and calories
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.shortDuration)
                    .font(.title3.bold())
                    .foregroundStyle(.green)

                let effectiveCal = session.calories > 0 ? session.calories : session.estimatedCalories
                if effectiveCal > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("\(effectiveCal)")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var workoutColor: Color {
        switch session.workoutType {
        case .weights: return .blue
        case .cardio: return .orange
        case .mixed: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .green

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
