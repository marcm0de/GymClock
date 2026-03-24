import SwiftUI
import SwiftData

@main
struct GymClockWatchApp: App {
    @StateObject private var sessionTracker = SessionTracker()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
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
                .environmentObject(connectivityManager)
                .onAppear {
                    sessionTracker.configure(with: sharedModelContainer.mainContext)
                    connectivityManager.activate()
                    
                    // Handle incoming sessions from iPhone
                    connectivityManager.onSessionReceived = { transfer in
                        // Session data received from iPhone — can be persisted
                        print("Received session from iPhone: \(transfer.gymName)")
                    }
                    
                    connectivityManager.onGoalUpdated = { goal in
                        UserDefaults.standard.set(goal, forKey: "weeklyGoal")
                    }
                    
                    connectivityManager.onPreferencesUpdated = { prefs in
                        if let workoutType = prefs["defaultWorkoutType"] as? String {
                            UserDefaults.standard.set(workoutType, forKey: "defaultWorkoutType")
                        }
                        if let haptic = prefs["hapticEnabled"] as? Bool {
                            UserDefaults.standard.set(haptic, forKey: "hapticFeedbackEnabled")
                            HapticManager.shared.isEnabled = haptic
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
