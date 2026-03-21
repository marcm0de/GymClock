import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    @State private var selectedPeriod: TimePeriod = .week
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
                .padding()

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
                        // Weekly Summaries
                        ForEach(weeklyGroups, id: \.weekStart) { weekGroup in
                            Section {
                                // Weekly summary header
                                WeeklySummaryRow(group: weekGroup, longestSessionId: longestSessionId)

                                // Individual sessions in that week
                                ForEach(weekGroup.sessions) { session in
                                    SessionRow(
                                        session: session,
                                        isPersonalBest: session.id == longestSessionId
                                    )
                                }
                                .onDelete { indexSet in
                                    deleteSessions(daySessions: weekGroup.sessions, at: indexSet)
                                }
                            } header: {
                                Text(weekGroup.label)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
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
        let totalCals = filtered.reduce(0) { $0 + $1.calories }

        return HStack(spacing: 12) {
            StatBadge(title: "Sessions", value: "\(filtered.count)", icon: "checkmark.circle")
            StatBadge(title: "Total", value: DateFormatters.formatDuration(totalTime), icon: "clock")
            StatBadge(title: "Avg", value: DateFormatters.formatDuration(avgTime), icon: "chart.line.uptrend.xyaxis")
            StatBadge(title: "Cals", value: "\(totalCals)", icon: "flame.fill")
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Filtering

    private var filteredSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return sessions.filter { $0.checkInTime >= start }
        case .month:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return sessions.filter { $0.checkInTime >= start }
        case .all:
            return sessions
        }
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
            let totalCals = sorted.reduce(0) { $0 + $1.calories }

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

// MARK: - Weekly Summary Row

struct WeeklySummaryRow: View {
    let group: WeekGroup
    let longestSessionId: UUID?

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(group.sessions.count) sessions")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                if group.totalCalories > 0 {
                    Text("~\(group.totalCalories) cal")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text(DateFormatters.formatDuration(group.totalTime))
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.green.opacity(0.05))
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: WorkoutSession
    var isPersonalBest: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.gymName)
                        .font(.headline)

                    if let type = WorkoutType(rawValue: session.workoutTypeRaw) {
                        Image(systemName: type.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

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
                    Text(DateFormatters.timeFormatter.string(from: session.checkInTime))
                    if let checkout = session.checkOutTime {
                        Text("–")
                        Text(DateFormatters.timeFormatter.string(from: checkout))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.shortDuration)
                    .font(.title3.bold())
                    .foregroundStyle(.green)

                if session.calories > 0 {
                    Text("\(session.calories) cal")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)

            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
