import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionTracker: SessionTracker

    var body: some View {
        TabView {
            ActiveSessionView()
                .tabItem {
                    Label("Session", systemImage: "timer")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionTracker())
        .environmentObject(GeofenceManager.shared)
}
