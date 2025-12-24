import SwiftUI
import SwiftData

@main
struct CoreFitnessApp: App {

    // MARK: - State
    @StateObject private var authManager = AuthManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var watchConnectivityManager = WatchConnectivityManager.shared
    @AppStorage("hasRequestedHealthKit") private var hasRequestedHealthKit = false

    // MARK: - SwiftData Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSession.self,
            CompletedSet.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
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
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(healthKitManager)
                .environmentObject(workoutManager)
                .environmentObject(watchConnectivityManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    workoutManager.setModelContext(sharedModelContainer.mainContext)
                }
                .task {
                    // Request HealthKit authorization on first launch
                    if !hasRequestedHealthKit {
                        await healthKitManager.requestAuthorization()
                        hasRequestedHealthKit = true
                    } else if healthKitManager.isAuthorized {
                        // Refresh data if already authorized
                        await healthKitManager.fetchTodayData()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// ============================================
// NOTE: When you're ready to add Firebase:
// 1. Add Firebase SDK via Swift Package Manager
// 2. Download GoogleService-Info.plist from Firebase Console
// 3. Uncomment the code below
// 4. Set AuthManager.mockMode = false
// ============================================

/*
import FirebaseCore

// Add this to CoreFitnessApp:
// @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
*/
