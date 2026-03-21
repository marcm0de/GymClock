import SwiftUI
import SwiftData

@main
struct GymClockWatchApp: App {
    @StateObject private var sessionTracker = SessionTracker()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutSession.self,
            GymLocation.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(sessionTracker)
                .onAppear {
                    sessionTracker.configure(with: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
