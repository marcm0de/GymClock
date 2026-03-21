import SwiftUI
import SwiftData

@main
struct GymClockApp: App {
    @StateObject private var sessionTracker = SessionTracker()
    @StateObject private var geofenceManager = GeofenceManager.shared

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
            ContentView()
                .environmentObject(sessionTracker)
                .environmentObject(geofenceManager)
                .onAppear {
                    sessionTracker.configure(with: sharedModelContainer.mainContext)
                    sessionTracker.requestHealthKitAuthorization()
                    geofenceManager.requestAuthorization()
                    seedDefaultGymIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func seedDefaultGymIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<GymLocation>()
        let count = (try? context.fetchCount(descriptor)) ?? 0

        if count == 0 {
            context.insert(GymLocation.planetFitness)
            try? context.save()
        }
    }
}
