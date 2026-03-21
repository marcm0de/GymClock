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
                        ForEach(groupedSessions, id: \.key) { date, daySessions in
                            Section(header: Text(DateFormatters.dateFormatter.string(from: date))) {
                                ForEach(daySessions) { session in
                                    SessionRow(session: session)
                                }
                                .onDelete { indexSet in
                                    deleteSessions(daySessions: daySessions, at: indexSet)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let filtered = filteredSessions
        let totalTime = filtered.reduce(0) { $0 + $1.duration }
        let avgTime = filtered.isEmpty ? 0 : totalTime / Double(filtered.count)

        return HStack(spacing: 16) {
            StatBadge(title: "Sessions", value: "\(filtered.count)", icon: "checkmark.circle")
            StatBadge(title: "Total", value: DateFormatters.formatDuration(totalTime), icon: "clock")
            StatBadge(title: "Average", value: DateFormatters.formatDuration(avgTime), icon: "chart.line.uptrend.xyaxis")
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

    private var groupedSessions: [(key: Date, value: [WorkoutSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.checkInTime)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func deleteSessions(daySessions: [WorkoutSession], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(daySessions[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.gymName)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text(DateFormatters.timeFormatter.string(from: session.checkInTime))
                    if let checkout = session.checkOutTime {
                        Text("–")
                        Text(DateFormatters.timeFormatter.string(from: checkout))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(session.shortDuration)
                .font(.title3.bold())
                .foregroundStyle(.green)
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
