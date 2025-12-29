import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Navigation State
class NavigationState: ObservableObject {
    static let shared = NavigationState()

    @Published var showWaterIntake: Bool = false
    @Published var showDailyCheckIn: Bool = false
    @Published var showChallenges: Bool = false
    @Published var showExercises: Bool = false
    @Published var pendingDeepLink: DeepLinkDestination?

    // Workout invitation handling
    @Published var pendingInvitationCode: String?
    @Published var showInvitationResponse: Bool = false

    enum DeepLinkDestination {
        case waterIntake
        case dailyCheckIn
        case workout
        case challenges
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
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var watchConnectivityManager = WatchConnectivityManager.shared
    @StateObject private var fitnessDataService = FitnessDataService()
    @StateObject private var socialSharingService = SocialSharingService()
    @StateObject private var waterIntakeManager = WaterIntakeManager()
    @StateObject private var navigationState = NavigationState.shared

    // MARK: - SwiftData Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Workout Models
            Exercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSession.self,
            WorkoutInvitation.self,
            CompletedSet.self,
            // Program Models
            ProgramTemplate.self,
            UserProgram.self,
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
            ChallengeDayLog.self,
            ChallengeActivityData.self,
            ChallengeStrengthSet.self,
            ChallengeWeeklySummary.self,
            // Rest Day Model
            RestDay.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, delete the old store and create a new one
            print("Migration failed, recreating database: \(error)")

            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let storeURL = appSupport.appendingPathComponent("default.store")

            // Delete old store files
            let storePaths = [
                storeURL,
                storeURL.appendingPathExtension("shm"),
                storeURL.appendingPathExtension("wal")
            ]

            for path in storePaths {
                try? fileManager.removeItem(at: path)
            }

            // Try again with fresh database
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(userProfileManager)
                .environmentObject(themeManager)
                .environmentObject(healthKitManager)
                .environmentObject(workoutManager)
                .environmentObject(watchConnectivityManager)
                .environmentObject(fitnessDataService)
                .environmentObject(socialSharingService)
                .environmentObject(waterIntakeManager)
                .environmentObject(navigationState)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    // Connect UserProfileManager to model context (must be first)
                    userProfileManager.setModelContext(context)
                    // Connect ThemeManager to UserProfileManager for synced settings
                    themeManager.setUserProfileManager(userProfileManager)
                    // Connect other managers to model context
                    workoutManager.setModelContext(context)
                    fitnessDataService.setModelContext(context)
                    socialSharingService.setModelContext(context)
                    waterIntakeManager.setModelContext(context)
                    // Connect ThemeManager to WorkoutManager for haptics
                    workoutManager.themeManager = themeManager
                    // Connect WaterIntakeManager to HealthKitManager for syncing
                    waterIntakeManager.setHealthKitManager(healthKitManager)
                    // Connect NotificationManager to UserProfileManager for synced settings
                    NotificationManager.shared.configure(with: userProfileManager)
                    // Seed achievements on first launch
                    AchievementDefinitions.seedAchievements(in: context)
                    // Seed exercises on first launch
                    ExerciseData.seedExercises(in: context)
                    // Seed workout programs on first launch
                    ProgramData.seedPrograms(in: context)
                }
                .task {
                    // Request HealthKit authorization on first launch
                    if !userProfileManager.hasRequestedHealthKit {
                        await healthKitManager.requestAuthorization()
                        userProfileManager.hasRequestedHealthKit = true
                    } else if healthKitManager.isAuthorized {
                        // Refresh data if already authorized
                        await healthKitManager.fetchTodayData()
                    }
                    // Load water intake data from HealthKit
                    await waterIntakeManager.loadTodayDataAsync()
                    // Fetch AI configuration from CloudKit
                    await AIConfigManager.shared.fetchConfig()
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

        // Handle workout invitation links
        // Format: corefitness://invite/CODE
        if url.host == "invite", let inviteCode = pathComponents.first {
            handleInvitationDeepLink(code: inviteCode)
        }
    }

    /// Handle workout invitation acceptance/decline from deep link
    private func handleInvitationDeepLink(code: String) {
        let context = sharedModelContainer.mainContext
        let invitationService = WorkoutInvitationService()
        invitationService.setModelContext(context)

        if let invitation = invitationService.findInvitation(byCode: code) {
            // Store the pending invitation for UI to handle
            navigationState.pendingInvitationCode = code
            navigationState.showInvitationResponse = true

            print("Found invitation: \(invitation.workoutName) from \(invitation.senderDisplayName)")
        } else {
            print("Invitation not found for code: \(code)")
        }
    }
}

// ============================================
// iCloud/CloudKit Setup:
// 1. Enable iCloud capability in Xcode (Signing & Capabilities)
// 2. Enable CloudKit checkbox
// 3. Container identifier: iCloud.com.jmillergroup.CoreFitness
// 4. Enable Background Modes > Remote notifications for sync
// The app uses iCloud for:
// - User authentication (via iCloud account)
// - Challenge data sync between participants
// - User profile and preferences storage
// - AI configuration management (AIConfig record type)
//
// AIConfig Record Type Setup (in CloudKit Dashboard):
// - activeProvider: String ("gemini" or "claude")
// - isEnabled: Int(64) (1 = enabled, 0 = disabled)
// - geminiModel: String (e.g., "gemini-pro")
// - claudeModel: String (e.g., "claude-3-haiku-20240307")
// ============================================
