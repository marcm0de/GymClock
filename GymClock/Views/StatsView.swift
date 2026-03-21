import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @Query(
        filter: #Predicate<WorkoutSession> { !$0.isActive },
        sort: \WorkoutSession.checkInTime,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakCards
                    weeklyChart
                    monthlyOverview
                    bestSessionCard
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Streak Cards

    private var streakCards: some View {
        HStack(spacing: 16) {
            StreakCard(
                title: "Day Streak",
                value: sessionTracker.currentStreak(allSessions: sessions),
                icon: "flame.fill",
                color: .orange
            )

            StreakCard(
                title: "Week Streak",
                value: sessionTracker.weeklyStreak(allSessions: sessions),
                icon: "star.fill",
                color: .yellow
            )

            StreakCard(
                title: "This Week",
                value: sessionTracker.sessionsThisWeek(allSessions: sessions).count,
                icon: "calendar",
                color: .green
            )
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            let data = weeklyChartData

            if data.isEmpty {
                Text("No sessions this week")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(data, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(6)
                }
                .frame(height: 200)
                .chartYAxisLabel("Minutes")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyChartData: [DayData] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let daySessions = sessions.filter { calendar.isDate($0.checkInTime, inSameDayAs: date) }
            let totalMinutes = daySessions.reduce(0.0) { $0 + $1.duration } / 60.0

            return DayData(
                day: weekDays[calendar.component(.weekday, from: date) - 1],
                minutes: totalMinutes
            )
        }
    }

    // MARK: - Monthly Overview

    private var monthlyOverview: some View {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let monthSessions = sessions.filter { $0.checkInTime >= startOfMonth }
        let totalTime = monthSessions.reduce(0.0) { $0 + $1.duration }

        return VStack(alignment: .leading, spacing: 12) {
            Text(DateFormatters.monthYearFormatter.string(from: Date()))
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("\(monthSessions.count)")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.green)
                    Text("Sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading) {
                    Text(DateFormatters.formatDuration(totalTime))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.green)
                    Text("Total Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading) {
                    let avg = monthSessions.isEmpty ? 0 : totalTime / Double(monthSessions.count)
                    Text(DateFormatters.formatDuration(avg))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.green)
                    Text("Avg Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Best Session

    private var bestSessionCard: some View {
        let best = sessions.max(by: { $0.duration < $1.duration })

        return Group {
            if let best = best {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("Longest Session")
                            .font(.headline)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text(best.gymName)
                                .font(.subheadline)
                            Text(DateFormatters.dateFormatter.string(from: best.checkInTime))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(best.formattedDuration)
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Supporting Types

struct DayData {
    let day: String
    let minutes: Double
}

struct StreakCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.title.bold())

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    StatsView()
        .environmentObject(SessionTracker())
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
