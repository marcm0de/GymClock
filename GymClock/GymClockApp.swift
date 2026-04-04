import SwiftUI
import SwiftData

@main
struct GymClockApp: App {
    @StateObject private var sessionTracker = SessionTracker()
    @StateObject private var achievementManager = AchievementManager()
    @ObservedObject private var geofenceManager = GeofenceManager.shared

    let sharedModelContainer: ModelContainer = {
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
            // This is a truly unrecoverable error — the app cannot function without its data store.
            // In production, consider presenting an error UI or migrating the schema.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionTracker)
                .environmentObject(achievementManager)
                .environmentObject(geofenceManager)
                .onAppear {
                    sessionTracker.configure(with: sharedModelContainer.mainContext)
                    sessionTracker.requestHealthKitAuthorization()
                    WatchConnectivityManager.shared.activate()
                    seedDefaultGymIfNeeded()
                    // Request authorization and start monitoring after gyms are seeded
                    geofenceManager.requestAuthorization()
                    startGeofencingIfNeeded()
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

    private func startGeofencingIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<GymLocation>()
        guard let gyms = try? context.fetch(descriptor), !gyms.isEmpty else { return }
        geofenceManager.startMonitoring(locations: gyms)
    }
}
