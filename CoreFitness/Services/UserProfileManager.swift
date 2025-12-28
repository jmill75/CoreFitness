import SwiftUI
import SwiftData
import Combine

// MARK: - User Profile Manager
/// Centralized manager for user settings with iCloud sync via SwiftData
/// Replaces scattered @AppStorage settings for unified sync and management
@MainActor
class UserProfileManager: ObservableObject {

    // MARK: - Model Context
    private var modelContext: ModelContext?
    private var profile: UserProfile?
    private var isSyncing = false

    // MARK: - Published Properties (UI binding)

    // Theme & Appearance
    @Published var selectedThemeRaw: String = "Standard" {
        didSet { updateProfile { $0.selectedThemeRaw = selectedThemeRaw } }
    }
    @Published var colorSchemePreferenceRaw: String = "System" {
        didSet { updateProfile { $0.colorSchemePreferenceRaw = colorSchemePreferenceRaw } }
    }

    // Units
    @Published var useMetricSystem: Bool = false {
        didSet { updateProfile { $0.useMetricSystem = useMetricSystem } }
    }

    // Feedback
    @Published var hapticsEnabled: Bool = true {
        didSet { updateProfile { $0.hapticsEnabled = hapticsEnabled } }
    }
    @Published var soundsEnabled: Bool = true {
        didSet { updateProfile { $0.soundsEnabled = soundsEnabled } }
    }

    // Workout
    @Published var restTimerDuration: Int = 90 {
        didSet { updateProfile { $0.restTimerDuration = restTimerDuration } }
    }
    @Published var autoPlayExerciseVideos: Bool = true {
        didSet { updateProfile { $0.autoPlayExerciseVideos = autoPlayExerciseVideos } }
    }

    // Quick Actions
    @Published var quickActionsData: Data = Data() {
        didSet { updateProfile { $0.quickActionsData = quickActionsData } }
    }

    // Notifications
    @Published var dailyCheckInReminderEnabled: Bool = false {
        didSet { updateProfile { $0.dailyCheckInReminderEnabled = dailyCheckInReminderEnabled } }
    }
    @Published var dailyCheckInTimeRaw: String = "morning" {
        didSet { updateProfile { $0.dailyCheckInTimeRaw = dailyCheckInTimeRaw } }
    }

    // Watch
    @Published var watchMirrorWorkouts: Bool = true {
        didSet { updateProfile { $0.watchMirrorWorkouts = watchMirrorWorkouts } }
    }
    @Published var watchShowHeartRate: Bool = true {
        didSet { updateProfile { $0.watchShowHeartRate = watchShowHeartRate } }
    }
    @Published var watchHapticAlerts: Bool = true {
        didSet { updateProfile { $0.watchHapticAlerts = watchHapticAlerts } }
    }

    // Water Intake
    @Published var waterIntakeEnabled: Bool = true {
        didSet { updateProfile { $0.waterIntakeEnabled = waterIntakeEnabled } }
    }
    @Published var waterGoalOz: Double = 64 {
        didSet { updateProfile { $0.dailyWaterGoal = waterGoalOz } }
    }
    @Published var waterReminderEnabled: Bool = false {
        didSet { updateProfile { $0.waterReminderEnabled = waterReminderEnabled } }
    }
    @Published var waterReminderInterval: Double = 2 {
        didSet { updateProfile { $0.waterReminderInterval = waterReminderInterval } }
    }

    // Music
    @Published var musicEnabled: Bool = true {
        didSet { updateProfile { $0.musicEnabled = musicEnabled } }
    }
    @Published var musicProvider: String = "Apple Music" {
        didSet { updateProfile { $0.musicProviderRaw = musicProvider } }
    }
    @Published var showMusicDuringWorkout: Bool = true {
        didSet { updateProfile { $0.showMusicDuringWorkout = showMusicDuringWorkout } }
    }
    @Published var autoPlayOnWorkoutStart: Bool = false {
        didSet { updateProfile { $0.autoPlayOnWorkoutStart = autoPlayOnWorkoutStart } }
    }

    // HealthKit
    @Published var hasRequestedHealthKit: Bool = false {
        didSet { updateProfile { $0.hasRequestedHealthKit = hasRequestedHealthKit } }
    }

    // Daily Check-In
    @Published var lastCheckInDateString: String = "" {
        didSet { updateProfile { $0.lastCheckInDateString = lastCheckInDateString } }
    }
    @Published var lastCheckInMood: Double = 3 {
        didSet { updateProfile { $0.lastCheckInMood = lastCheckInMood } }
    }
    @Published var lastCheckInSoreness: Double = 2 {
        didSet { updateProfile { $0.lastCheckInSoreness = lastCheckInSoreness } }
    }
    @Published var lastCheckInStress: Double = 2 {
        didSet { updateProfile { $0.lastCheckInStress = lastCheckInStress } }
    }
    @Published var lastCheckInSleep: Double = 3 {
        didSet { updateProfile { $0.lastCheckInSleep = lastCheckInSleep } }
    }
    @Published var lastCheckInEnergy: Double = 3 {
        didSet { updateProfile { $0.lastCheckInEnergy = lastCheckInEnergy } }
    }
    @Published var checkInStreak: Int = 0 {
        didSet { updateProfile { $0.checkInStreak = checkInStreak } }
    }

    // MARK: - Initialization

    /// Set the model context and load profile
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadProfile()
    }

    // MARK: - Profile Loading

    /// Load or create the user profile
    private func loadProfile() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            profile = existing
            syncFromProfile()
        } else {
            let newProfile = UserProfile()
            context.insert(newProfile)
            try? context.save()
            profile = newProfile
        }
    }

    /// Sync published properties from the profile
    private func syncFromProfile() {
        guard let profile = profile else { return }

        // Prevent didSet handlers from triggering saves during sync
        isSyncing = true
        defer { isSyncing = false }

        selectedThemeRaw = profile.selectedThemeRaw
        colorSchemePreferenceRaw = profile.colorSchemePreferenceRaw
        useMetricSystem = profile.useMetricSystem
        hapticsEnabled = profile.hapticsEnabled
        soundsEnabled = profile.soundsEnabled
        restTimerDuration = profile.restTimerDuration
        autoPlayExerciseVideos = profile.autoPlayExerciseVideos
        quickActionsData = profile.quickActionsData
        dailyCheckInReminderEnabled = profile.dailyCheckInReminderEnabled
        dailyCheckInTimeRaw = profile.dailyCheckInTimeRaw
        watchMirrorWorkouts = profile.watchMirrorWorkouts
        watchShowHeartRate = profile.watchShowHeartRate
        watchHapticAlerts = profile.watchHapticAlerts
        waterIntakeEnabled = profile.waterIntakeEnabled
        waterGoalOz = profile.dailyWaterGoal
        waterReminderEnabled = profile.waterReminderEnabled
        waterReminderInterval = profile.waterReminderInterval
        musicEnabled = profile.musicEnabled
        musicProvider = profile.musicProviderRaw
        showMusicDuringWorkout = profile.showMusicDuringWorkout
        autoPlayOnWorkoutStart = profile.autoPlayOnWorkoutStart
        hasRequestedHealthKit = profile.hasRequestedHealthKit
        lastCheckInDateString = profile.lastCheckInDateString
        lastCheckInMood = profile.lastCheckInMood
        lastCheckInSoreness = profile.lastCheckInSoreness
        lastCheckInStress = profile.lastCheckInStress
        lastCheckInSleep = profile.lastCheckInSleep
        lastCheckInEnergy = profile.lastCheckInEnergy
        checkInStreak = profile.checkInStreak
    }

    // MARK: - Profile Updates

    /// Update the profile with a closure
    private func updateProfile(_ update: (UserProfile) -> Void) {
        // Skip saves during sync to prevent save loop
        guard !isSyncing, let profile = profile else { return }
        update(profile)
        profile.markModified()
        try? modelContext?.save()
    }

    // MARK: - Quick Actions Helpers

    /// Decode quick actions from stored data
    func getQuickActions<T: Decodable>(as type: T.Type) -> T? {
        guard !quickActionsData.isEmpty else { return nil }
        return try? JSONDecoder().decode(type, from: quickActionsData)
    }

    /// Encode and store quick actions
    func setQuickActions<T: Encodable>(_ actions: T) {
        if let encoded = try? JSONEncoder().encode(actions) {
            quickActionsData = encoded
        }
    }
}
