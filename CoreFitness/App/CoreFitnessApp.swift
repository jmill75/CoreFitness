import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Navigation State
class NavigationState: ObservableObject {
    static let shared = NavigationState()

    @Published var showWaterIntake: Bool = false
    @Published var showDailyCheckIn: Bool = false
    @Published var pendingDeepLink: DeepLinkDestination?

    enum DeepLinkDestination {
        case waterIntake
        case dailyCheckIn
        case workout
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification tap when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier

        // Check if this is a daily check-in notification (for mood logging)
        if identifier.contains("dailyCheckIn") || identifier.contains("mood") || identifier.contains("checkIn") {
            DispatchQueue.main.async {
                NavigationState.shared.showDailyCheckIn = true
            }
        }

        completionHandler()
    }
}

@main
struct CoreFitnessApp: App {

    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - State
    @StateObject private var authManager = AuthManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var watchConnectivityManager = WatchConnectivityManager.shared
    @StateObject private var fitnessDataService = FitnessDataService()
    @StateObject private var socialSharingService = SocialSharingService()
    @StateObject private var navigationState = NavigationState.shared
    @AppStorage("hasRequestedHealthKit") private var hasRequestedHealthKit = false

    // MARK: - SwiftData Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Workout Models
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSession.self,
            CompletedSet.self,
            // Fitness Data Models
            PersonalRecord.self,
            DailyHealthData.self,
            MoodEntry.self,
            StreakData.self,
            Achievement.self,
            UserAchievement.self,
            WorkoutShare.self,
            WeeklySummary.self,
            MonthlySummary.self,
            UserProfile.self,
            // Challenge Models
            Challenge.self,
            ChallengeParticipant.self,
            ChallengeDayLog.self
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
                .environmentObject(fitnessDataService)
                .environmentObject(socialSharingService)
                .environmentObject(navigationState)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    workoutManager.setModelContext(context)
                    fitnessDataService.setModelContext(context)
                    socialSharingService.setModelContext(context)
                    // Seed achievements on first launch
                    AchievementDefinitions.seedAchievements(in: context)
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
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Deep Link Handling

    /// Handle deep links from Live Activity buttons and other sources
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "corefitness" else { return }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // Handle workout control actions from Live Activity
        if url.host == "workout", let action = pathComponents.first {
            switch action {
            case "pause":
                workoutManager.pauseWorkout()
            case "resume":
                workoutManager.resumeWorkout()
            case "end":
                workoutManager.showExitConfirmation = true
            case "skip-rest":
                workoutManager.skipRest()
            default:
                break
            }
        }
    }
}

// ============================================
// NOTE: When you're ready to add Firebase:
// 1. Add Firebase SDK via Swift Package Manager
// 2. Download GoogleService-Info.plist from Firebase Console
// 3. Add `import FirebaseCore` at the top
// 4. Add `FirebaseApp.configure()` to AppDelegate.didFinishLaunchingWithOptions
// 5. Set AuthManager.mockMode = false
// ============================================
