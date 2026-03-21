import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var sessionTracker: SessionTracker

    var body: some View {
        TabView {
            WatchActiveSessionView()
            WatchHistoryView()
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    WatchContentView()
        .environmentObject(SessionTracker())
}
