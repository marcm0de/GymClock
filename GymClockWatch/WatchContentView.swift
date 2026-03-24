import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var sessionTracker: SessionTracker
    
    var body: some View {
        TabView {
            WatchActiveSessionView()
            WatchHistoryView()
            WatchStatsView()
            WatchSettingsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    WatchContentView()
        .environmentObject(SessionTracker())
}
