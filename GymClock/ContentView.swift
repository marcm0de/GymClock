import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    @EnvironmentObject var achievementManager: AchievementManager

    var body: some View {
        ZStack {
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

                AchievementsView()
                    .tabItem {
                        Label("Achievements", systemImage: "trophy.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .tint(.green)

            // Achievement celebration overlay
            if achievementManager.showCelebration, let achievement = achievementManager.newlyUnlocked {
                AchievementCelebrationOverlay(
                    achievement: achievement,
                    isShowing: $achievementManager.showCelebration
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionTracker())
        .environmentObject(AchievementManager())
        .environmentObject(GeofenceManager.shared)
}
