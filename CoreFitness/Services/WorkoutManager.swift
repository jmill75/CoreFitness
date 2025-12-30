import SwiftUI
import SwiftData
import Combine
import HealthKit
import UserNotifications

// MARK: - Notification Names
extension Notification.Name {
    static let workoutSaved = Notification.Name("workoutSaved")
    static let showSavedWorkouts = Notification.Name("showSavedWorkouts")
}

// MARK: - Workout Execution Phase
enum WorkoutPhase: Equatable {
    case idle
    case countdown(remaining: Int) // 3-2-1-GO!
    case exercising
    case loggingSet
    case resting(remaining: Int)
    case betweenExercises
    case completed
    case paused
}

// MARK: - Workout Manager
@MainActor
class WorkoutManager: ObservableObject {

    // MARK: - Published State
    @Published var currentPhase: WorkoutPhase = .idle
    @Published var currentSession: WorkoutSession?
    @Published var currentExerciseIndex: Int = 0
    @Published var currentSetNumber: Int = 1
    @Published var elapsedTime: Int = 0 // Total workout time in seconds

    // Set logging state
    @Published var loggedReps: Int = 0
    @Published var loggedWeight: Double = 0
    @Published var showSetLogger: Bool = false

    // Rest timer
    @Published var restTimeRemaining: Int = 0

    // UI State
    @Published var showExitConfirmation: Bool = false
    @Published var showWorkoutComplete: Bool = false

    // PR Celebration
    @Published var showPRCelebration: Bool = false
    @Published var prExerciseName: String = ""
    @Published var prWeight: Double = 0

    // Set/Exercise Completion Feedback
    @Published var showSetCompleteFeedback: Bool = false
    @Published var showExerciseCompleteFeedback: Bool = false
    @Published var completedSetNumber: Int = 0
    @Published var completedExerciseName: String = ""

    // Next Exercise Transition
    @Published var showNextExerciseTransition: Bool = false
    @Published var nextExerciseName: String = ""
    @Published var nextExerciseNumber: Int = 0
    @Published var totalExerciseCount: Int = 0

    // MARK: - Private Properties
    private var timer: Timer?
    private var restTimer: Timer?
    private var countdownTimer: Timer?
    private var modelContext: ModelContext?

    // MARK: - Theme Manager (for haptics)
    weak var themeManager: ThemeManager?

    // MARK: - Watch Connectivity
    private let watchManager = WatchConnectivityManager.shared

    // MARK: - Live Activity
    private let liveActivityManager = LiveActivityManager.shared

    // MARK: - HealthKit (for Watch app auto-launch)
    private var healthStore: HKHealthStore?
    private var hkWorkoutSession: HKWorkoutSession?
    private var hkWorkoutBuilder: HKLiveWorkoutBuilder?

    // MARK: - Computed Properties
    var currentWorkout: Workout? {
        currentSession?.workout
    }

    var currentExercise: WorkoutExercise? {
        guard let exercises = currentWorkout?.sortedExercises,
              currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var totalExercises: Int {
        currentWorkout?.exerciseCount ?? 0
    }

    var exerciseProgress: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(currentExerciseIndex) / Double(totalExercises)
    }

    var setProgress: Double {
        guard let exercise = currentExercise else { return 0 }
        return Double(currentSetNumber - 1) / Double(exercise.targetSets)
    }

    var completedSetsForCurrentExercise: [CompletedSet] {
        guard let exercise = currentExercise,
              let session = currentSession else { return [] }
        return session.completedSets?.filter { $0.workoutExercise?.id == exercise.id }
            .sorted(by: { $0.setNumber < $1.setNumber }) ?? []
    }

    var isLastSet: Bool {
        guard let exercise = currentExercise else { return false }
        return currentSetNumber >= exercise.targetSets
    }

    var isLastExercise: Bool {
        currentExerciseIndex >= totalExercises - 1
    }

    var formattedElapsedTime: String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Whether the workout is currently paused
    var isPaused: Bool {
        currentPhase == .paused
    }

    /// Total sets across all exercises in the workout
    var totalSets: Int {
        currentWorkout?.sortedExercises.reduce(0) { $0 + $1.targetSets } ?? 0
    }

    /// Count of all completed sets in current session
    var completedSetsCount: Int {
        currentSession?.completedSets?.count ?? 0
    }

    // MARK: - Initialization
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        setupWatchCallbacks()
        setupHealthKit()
    }

    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        healthStore = HKHealthStore()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func setupWatchCallbacks() {
        // Handle set logged from Watch
        watchManager.onSetCompleted = { [weak self] exerciseId, weight, reps in
            Task { @MainActor in
                self?.logSet(reps: reps, weight: weight)
            }
        }

        // Handle workout control actions from Watch
        watchManager.onWorkoutControlAction = { [weak self] action in
            Task { @MainActor in
                self?.handleWatchAction(action)
            }
        }

        // Handle sync request from Watch (when Watch app launches or wakes)
        watchManager.onSyncRequested = { [weak self] in
            Task { @MainActor in
                self?.sendWorkoutUpdateToWatch()
            }
        }
    }

    /// Handle actions from Watch
    func handleWatchAction(_ action: String) {
        switch action {
        case "skip_rest":
            skipRest()
        case "extend_rest_30":
            extendRest(by: 30)
        case "pause":
            pauseWorkout()
        case "resume":
            resumeWorkout()
        case "skip_exercise":
            nextExercise()
        case "end_workout":
            completeWorkout()
        default:
            break
        }
    }

    // MARK: - Workout Lifecycle

    /// Start a new workout session
    func startWorkout(_ workout: Workout) {
        // Create new session
        let session = WorkoutSession(startedAt: Date(), status: .inProgress)
        session.workout = workout
        modelContext?.insert(session)

        // Update workout status to in progress
        workout.isActive = true
        workout.status = .inProgress

        currentSession = session
        currentExerciseIndex = 0
        currentSetNumber = 1
        elapsedTime = 0

        // Pre-populate weight from last session if available
        prefillFromLastSession()

        let firstExercise = workout.sortedExercises.first?.exercise?.name ?? "Exercise"
        let totalSets = workout.sortedExercises.first?.targetSets ?? 0

        // Start HealthKit workout session (this auto-launches Watch app)
        startHealthKitWorkout()

        // Notify Watch app with workout data
        watchManager.sendWorkoutStarted(
            workoutName: workout.name,
            firstExercise: firstExercise,
            totalSets: totalSets
        )

        // Send notification to prompt opening Watch app (if not reachable)
        if !watchManager.isReachable {
            sendWatchAppNotification(workoutName: workout.name)
        }

        // Start Live Activity on lock screen
        liveActivityManager.startWorkoutActivity(
            workoutName: workout.name,
            exerciseName: firstExercise,
            totalSets: totalSets
        )

        // Start countdown
        startCountdown()
    }

    // MARK: - HealthKit Workout Session

    /// Start HealthKit workout session - triggers Watch app to launch
    private func startHealthKitWorkout() {
        guard let healthStore = healthStore else {
            print("HealthKit not available")
            return
        }

        // Request authorization
        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            guard success else {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "unknown")")
                return
            }

            Task { @MainActor in
                self?.createAndStartHKWorkoutSession()
            }
        }
    }

    private func createAndStartHKWorkoutSession() {
        guard let healthStore = healthStore else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        do {
            hkWorkoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            hkWorkoutBuilder = hkWorkoutSession?.associatedWorkoutBuilder()

            hkWorkoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            // Start the workout session - this should trigger Watch app launch
            let startDate = Date()
            hkWorkoutSession?.startActivity(with: startDate)
            hkWorkoutBuilder?.beginCollection(withStart: startDate) { success, error in
                if let error = error {
                    print("Failed to begin workout collection: \(error)")
                } else {
                    print("HealthKit workout session started - Watch app should launch")
                }
            }
        } catch {
            print("Failed to create HKWorkoutSession: \(error)")
        }
    }

    /// Stop HealthKit workout session
    private func stopHealthKitWorkout() {
        hkWorkoutSession?.end()
        hkWorkoutBuilder?.endCollection(withEnd: Date()) { [weak self] success, error in
            self?.hkWorkoutBuilder?.finishWorkout { workout, error in
                print("HealthKit workout finished: \(workout?.description ?? "nil")")
            }
        }
        hkWorkoutSession = nil
        hkWorkoutBuilder = nil
    }

    // MARK: - Watch App Notification

    /// Send notification to prompt opening Watch app
    private func sendWatchAppNotification(workoutName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Workout Started"
        content.body = "Open CoreFitness on your Apple Watch to track \(workoutName)"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_STARTED"

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "workout-watch-prompt", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send Watch prompt notification: \(error)")
            }
        }
    }

    /// Remove the Watch prompt notification
    private func removeWatchAppNotification() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["workout-watch-prompt"])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["workout-watch-prompt"])
    }

    /// Start the 3-2-1-GO countdown
    private func startCountdown() {
        currentPhase = .countdown(remaining: 3)
        themeManager?.mediumImpact()

        // Use DispatchQueue for more reliable timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, self.currentPhase != .idle else { return }
            self.currentPhase = .countdown(remaining: 2)
            self.themeManager?.mediumImpact()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.currentPhase != .idle else { return }
                self.currentPhase = .countdown(remaining: 1)
                self.themeManager?.mediumImpact()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.currentPhase != .idle else { return }
                    // GO!
                    self.themeManager?.notifySuccess()
                    self.beginExercising()
                }
            }
        }
    }

    /// Transition to exercising phase
    private func beginExercising() {
        currentPhase = .exercising
        startWorkoutTimer()
        notifyWatchExerciseChanged()
    }

    /// Start the main workout timer
    private func startWorkoutTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.elapsedTime += 1
                // Sync elapsed time to Watch every 5 seconds
                if self.elapsedTime % 5 == 0 {
                    self.watchManager.sendElapsedTimeUpdate(self.elapsedTime)
                }
                // Update Live Activity
                self.updateLiveActivity()
            }
        }
    }

    /// Update Live Activity with current state
    private func updateLiveActivity() {
        guard let exercise = currentExercise else { return }

        let isResting: Bool
        let restRemaining: Int?

        switch currentPhase {
        case .resting(let remaining):
            isResting = true
            restRemaining = remaining
        default:
            isResting = false
            restRemaining = nil
        }

        liveActivityManager.updateActivity(
            elapsedTime: elapsedTime,
            currentExercise: exercise.exercise?.name ?? "Exercise",
            currentSet: currentSetNumber,
            totalSets: exercise.targetSets,
            isResting: isResting,
            restTimeRemaining: restRemaining,
            heartRate: nil,
            isPaused: currentPhase == .paused
        )
    }

    /// Open set logger sheet
    func openSetLogger() {
        // Pre-fill with target values or last logged
        if let exercise = currentExercise {
            loggedReps = exercise.targetReps
            // Only reset weight on first set, otherwise keep the last logged weight
            if currentSetNumber == 1 && loggedWeight == 0 {
                loggedWeight = exercise.targetWeight ?? getLastWeight(for: exercise) ?? 0
            }
        }
        showSetLogger = true
        currentPhase = .loggingSet
    }

    /// Log a completed set
    func logSet(reps: Int, weight: Double, rpe: Int? = nil) {
        guard let exercise = currentExercise,
              let session = currentSession else { return }

        // Check for PR before saving (exclude current set from comparison)
        let exerciseName = exercise.exercise?.name ?? "Exercise"
        let isPR = checkForPR(exerciseName: exerciseName, newWeight: weight)

        let completedSet = CompletedSet(
            setNumber: currentSetNumber,
            reps: reps,
            weight: weight,
            rpe: rpe
        )
        completedSet.workoutExercise = exercise
        completedSet.session = session

        modelContext?.insert(completedSet)
        try? modelContext?.save()

        // Remember the weight for next set
        loggedWeight = weight

        showSetLogger = false

        // Store completed set info for feedback
        completedSetNumber = currentSetNumber
        completedExerciseName = exerciseName

        // Show PR celebration if new record (takes priority)
        if isPR && weight > 0 {
            // Save the new Personal Record
            savePR(exerciseName: exerciseName, weight: weight, reps: reps)

            prExerciseName = exerciseName
            prWeight = weight
            showPRCelebration = true
            // Extra haptic for PR
            themeManager?.notifySuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.themeManager?.notifySuccess()
            }

            // Delay next action to let PR celebration show
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.handlePostSetAction()
            }
        } else if isLastSet {
            // Exercise complete - grand celebration!
            showExerciseCompleteFeedback = true
            triggerExerciseCompleteHaptic()

            // Capture whether this is the last exercise before the delay
            let wasLastExercise = isLastExercise

            // Delay to show exercise complete feedback, then advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                self?.showExerciseCompleteFeedback = false
                if wasLastExercise {
                    self?.completeWorkout()
                } else {
                    self?.nextExercise()
                }
            }
        } else {
            // Regular set complete feedback
            showSetCompleteFeedback = true
            triggerSetCompleteHaptic()

            // Brief feedback then proceed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.showSetCompleteFeedback = false
                self?.handlePostSetAction()
            }
        }
    }

    /// Haptic feedback for set completion
    private func triggerSetCompleteHaptic() {
        themeManager?.heavyImpact()
    }

    /// Haptic feedback for exercise completion (more intense)
    private func triggerExerciseCompleteHaptic() {
        themeManager?.notifySuccess()

        // Double tap pattern for more impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.themeManager?.heavyImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.themeManager?.heavyImpact()
        }
    }

    /// Handle what happens after a set is logged
    private func handlePostSetAction() {
        // Determine next action
        if isLastSet {
            if isLastExercise {
                completeWorkout()
            } else {
                // Move to next exercise
                currentPhase = .betweenExercises
            }
        } else {
            // Start rest timer
            startRestTimer()
        }

        // Update Watch with current state
        sendWorkoutUpdateToWatch()
    }

    /// Check if the weight is a new personal record for this exercise
    private func checkForPR(exerciseName: String, newWeight: Double) -> Bool {
        guard let context = modelContext, newWeight > 0 else { return false }

        // Fetch all completed sets for exercises with this name
        let descriptor = FetchDescriptor<CompletedSet>(
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )

        guard let allSets = try? context.fetch(descriptor) else { return false }

        // Find max weight for this exercise name
        let maxPreviousWeight = allSets
            .filter { $0.workoutExercise?.exercise?.name == exerciseName }
            .map { $0.weight }
            .max() ?? 0

        return newWeight > maxPreviousWeight
    }

    /// Save a new personal record
    private func savePR(exerciseName: String, weight: Double, reps: Int) {
        guard let context = modelContext else { return }

        let pr = PersonalRecord(exerciseName: exerciseName, weight: weight, reps: reps)
        context.insert(pr)
        try? context.save()

        // Post notification for UI updates
        NotificationCenter.default.post(name: .personalRecordAchieved, object: nil, userInfo: [
            "exerciseName": exerciseName,
            "weight": weight,
            "reps": reps
        ])
    }

    /// Start rest timer between sets
    private func startRestTimer() {
        restTimeRemaining = currentExercise?.restDuration ?? 90
        currentPhase = .resting(remaining: restTimeRemaining)

        // Notify Watch
        watchManager.sendRestTimerStarted(duration: restTimeRemaining)

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.restTimeRemaining -= 1
                self.currentPhase = .resting(remaining: self.restTimeRemaining)

                if self.restTimeRemaining <= 0 {
                    self.restTimer?.invalidate()
                    self.currentSetNumber += 1
                    self.currentPhase = .exercising
                    self.watchManager.sendRestTimerEnded()
                    self.notifyWatchExerciseChanged()
                    self.themeManager?.notifyWarning()
                } else if self.restTimeRemaining <= 5 {
                    // Countdown haptics for last 5 seconds
                    self.themeManager?.lightImpact()
                }
            }
        }
    }

    /// Skip rest timer early
    func skipRest() {
        restTimer?.invalidate()
        currentSetNumber += 1
        currentPhase = .exercising
        watchManager.sendRestTimerEnded()
        notifyWatchExerciseChanged()
        themeManager?.mediumImpact()
    }

    /// Extend rest timer
    func extendRest(by seconds: Int = 30) {
        restTimeRemaining += seconds
        currentPhase = .resting(remaining: restTimeRemaining)
        themeManager?.lightImpact()
    }

    /// Move to next exercise
    func nextExercise() {
        guard !isLastExercise else {
            completeWorkout()
            return
        }

        // Get next exercise info for transition
        let exercises = currentSession?.workout?.exercises?.sorted(by: { $0.order < $1.order }) ?? []
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < exercises.count {
            nextExerciseName = exercises[nextIndex].exercise?.name ?? "Next Exercise"
            nextExerciseNumber = nextIndex + 1
            totalExerciseCount = exercises.count
        }

        // Show transition
        showNextExerciseTransition = true
        themeManager?.mediumImpact()

        // After transition, switch to next exercise
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showNextExerciseTransition = false
            self?.currentExerciseIndex += 1
            self?.currentSetNumber = 1
            self?.prefillFromLastSession()
            self?.currentPhase = .exercising
            self?.notifyWatchExerciseChanged()
        }
    }

    /// Go back to previous exercise
    func previousExercise() {
        guard currentExerciseIndex > 0 else { return }

        currentExerciseIndex -= 1
        currentSetNumber = 1
        currentPhase = .exercising

        themeManager?.lightImpact()
    }

    /// Pause the workout
    func pauseWorkout() {
        timer?.invalidate()
        restTimer?.invalidate()
        currentPhase = .paused
        currentSession?.status = .paused
        updateLiveActivity() // Update to show paused state
    }

    /// Resume the workout
    func resumeWorkout() {
        startWorkoutTimer()
        currentPhase = .exercising
        currentSession?.status = .inProgress
        updateLiveActivity() // Update to show resumed state
    }

    /// Complete the workout
    func completeWorkout() {
        timer?.invalidate()
        restTimer?.invalidate()

        currentSession?.completedAt = Date()
        currentSession?.status = .completed
        currentSession?.totalDuration = elapsedTime

        // Update workout status
        if let workout = currentWorkout {
            workout.isActive = false
            workout.status = .completed
        }

        try? modelContext?.save()

        currentPhase = .completed
        showWorkoutComplete = true

        // Notify Watch
        watchManager.sendWorkoutEnded(
            duration: TimeInterval(elapsedTime),
            exercisesCompleted: currentExerciseIndex + 1
        )

        // Stop HealthKit workout session
        stopHealthKitWorkout()

        // Remove Watch prompt notification
        removeWatchAppNotification()

        // End Live Activity
        liveActivityManager.endActivity()

        // Check and update achievements
        checkAchievements()

        // Advance program to next workout if applicable
        advanceProgramProgress()

        // Post notification for data sync across views
        NotificationCenter.default.post(name: .workoutCompleted, object: nil, userInfo: [
            "sessionId": currentSession?.id as Any,
            "workoutId": currentWorkout?.id as Any,
            "duration": elapsedTime,
            "exercisesCompleted": currentExerciseIndex + 1
        ])

        themeManager?.notifySuccess()
    }

    /// Cancel/exit workout
    func cancelWorkout() {
        timer?.invalidate()
        restTimer?.invalidate()
        countdownTimer?.invalidate()

        currentSession?.status = .cancelled

        // Update workout status - reset to created so it can be started again
        if let workout = currentWorkout {
            workout.isActive = false
            workout.status = .created
        }

        try? modelContext?.save()

        // Stop HealthKit workout session
        stopHealthKitWorkout()

        // Remove Watch prompt notification
        removeWatchAppNotification()

        // End Live Activity
        liveActivityManager.endActivity()

        resetState()
    }

    /// Save current workout progress and cancel (for starting a different workout)
    /// Preserves all completed sets for later resumption
    func saveAndCancelWorkout() {
        timer?.invalidate()
        restTimer?.invalidate()
        countdownTimer?.invalidate()

        // Mark as cancelled but save all progress
        currentSession?.status = .cancelled
        currentSession?.completedAt = Date()
        currentSession?.totalDuration = elapsedTime

        // Update workout status - mark as saved in middle for resumption
        if let workout = currentWorkout {
            workout.isActive = false
            workout.status = .savedInMiddle
        }

        // Save notes about progress for later resumption
        let exercisesCompleted = currentExerciseIndex
        let setsCompletedInCurrentExercise = completedSetsForCurrentExercise.count
        let totalExercisesInWorkout = totalExercises

        currentSession?.notes = "Saved at exercise \(exercisesCompleted + 1)/\(totalExercisesInWorkout), set \(setsCompletedInCurrentExercise)"

        try? modelContext?.save()

        // Stop HealthKit workout session
        stopHealthKitWorkout()

        // Remove Watch prompt notification
        removeWatchAppNotification()

        // End Live Activity
        liveActivityManager.endActivity()

        // Post notification for UI updates
        NotificationCenter.default.post(name: .workoutSaved, object: nil, userInfo: [
            "sessionId": currentSession?.id as Any,
            "workoutId": currentWorkout?.id as Any
        ])

        resetState()
    }

    /// Check if there's an active workout in progress
    var hasActiveWorkout: Bool {
        guard let session = currentSession else { return false }
        return session.status == .inProgress || session.status == .paused
    }

    /// Get the name of the current active workout (if any)
    var activeWorkoutName: String? {
        guard hasActiveWorkout else { return nil }
        return currentWorkout?.name
    }

    /// Reset all state
    func resetState() {
        currentPhase = .idle
        currentSession = nil
        currentExerciseIndex = 0
        currentSetNumber = 1
        elapsedTime = 0
        loggedReps = 0
        loggedWeight = 0
        showSetLogger = false
        showWorkoutComplete = false
        showExitConfirmation = false
    }

    // MARK: - Achievement & Progress Tracking

    /// Check and update achievements after workout completion
    private func checkAchievements() {
        guard let context = modelContext else { return }

        // Get total completed workouts
        let sessionsDescriptor = FetchDescriptor<WorkoutSession>()
        guard let allSessions = try? context.fetch(sessionsDescriptor) else { return }
        let completedCount = allSessions.filter { $0.status == .completed }.count

        // Get all achievements to check
        let achievementsDescriptor = FetchDescriptor<Achievement>()
        guard let achievements = try? context.fetch(achievementsDescriptor) else { return }

        // Get already earned achievements
        let userAchievementsDescriptor = FetchDescriptor<UserAchievement>()
        let earnedAchievements = (try? context.fetch(userAchievementsDescriptor)) ?? []
        let earnedIds = Set(earnedAchievements.map { $0.achievementId })

        for achievement in achievements {
            // Skip if already earned
            guard !earnedIds.contains(achievement.id) else { continue }

            var shouldUnlock = false

            switch achievement.id {
            case "first_workout":
                shouldUnlock = completedCount >= 1
            case "5_workouts":
                shouldUnlock = completedCount >= 5
            case "10_workouts":
                shouldUnlock = completedCount >= 10
            case "25_workouts":
                shouldUnlock = completedCount >= 25
            case "50_workouts":
                shouldUnlock = completedCount >= 50
            case "100_workouts":
                shouldUnlock = completedCount >= 100
            default:
                // Check streak achievements
                if achievement.id.contains("streak") {
                    shouldUnlock = checkStreakAchievement(requirement: achievement.requirement, sessions: allSessions)
                }
            }

            if shouldUnlock {
                let userAchievement = UserAchievement(achievementId: achievement.id, progress: achievement.requirement, isComplete: true)
                context.insert(userAchievement)

                // Post notification
                NotificationCenter.default.post(name: .achievementUnlocked, object: nil, userInfo: [
                    "achievementId": achievement.id,
                    "achievementName": achievement.name
                ])
            }
        }

        try? context.save()
    }

    /// Check if streak achievement is met
    private func checkStreakAchievement(requirement: Int, sessions: [WorkoutSession]) -> Bool {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let hasWorkout = sessions.contains {
                guard $0.status == .completed, let completed = $0.completedAt else { return false }
                return calendar.isDate(completed, inSameDayAs: checkDate)
            }
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        return streak >= requirement
    }

    /// Advance to the next workout in the program (if applicable)
    private func advanceProgramProgress() {
        guard let workout = currentWorkout,
              let context = modelContext else { return }

        // Increment the workout's personal records count if any PRs were set
        // Note: The session is already saved with completed status and date

        // If this is the active workout, we may want to advance to next in queue
        // The workout's `lastSessionDate` and `completedSessionsCount` are
        // computed properties that automatically update from sessions

        // Deactivate current workout after completion
        workout.isActive = false

        // Find next workout in library that should become active (if any)
        // This is handled by ProgramsView/HomeView which query for current workout

        try? context.save()
    }

    // MARK: - Helper Methods

    private func prefillFromLastSession() {
        guard let exercise = currentExercise else { return }
        if let lastWeight = getLastWeight(for: exercise) {
            loggedWeight = lastWeight
        } else if let targetWeight = exercise.targetWeight {
            loggedWeight = targetWeight
        }
        loggedReps = exercise.targetReps
    }

    private func getLastWeight(for exercise: WorkoutExercise) -> Double? {
        guard let exerciseId = exercise.exercise?.id,
              let context = modelContext else { return nil }

        // Fetch all completed sets and filter in memory
        // (SwiftData predicates don't support complex optional chaining)
        let descriptor = FetchDescriptor<CompletedSet>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        if let sets = try? context.fetch(descriptor) {
            let matchingSet = sets.first { set in
                set.workoutExercise?.exercise?.id == exerciseId
            }
            return matchingSet?.weight
        }
        return nil
    }

    // MARK: - Watch Connectivity Helpers

    /// Notify Watch of exercise change
    private func notifyWatchExerciseChanged() {
        guard let exercise = currentExercise else { return }

        watchManager.sendExerciseChanged(
            exerciseName: exercise.exercise?.name ?? "Exercise",
            setNumber: currentSetNumber,
            totalSets: exercise.targetSets,
            targetWeight: exercise.targetWeight,
            targetReps: exercise.targetReps
        )
    }

    /// Send full workout state update to Watch
    private func sendWorkoutUpdateToWatch() {
        guard let exercise = currentExercise else { return }

        let isResting: Bool
        let restRemaining: Int?

        switch currentPhase {
        case .resting(let remaining):
            isResting = true
            restRemaining = remaining
        default:
            isResting = false
            restRemaining = nil
        }

        let workoutData = WatchWorkoutData(
            workoutName: currentWorkout?.name ?? "Workout",
            currentExercise: exercise.exercise?.name ?? "Exercise",
            currentSet: currentSetNumber,
            totalSets: exercise.targetSets,
            weight: exercise.targetWeight,
            reps: exercise.targetReps,
            restTimeRemaining: restRemaining,
            elapsedTime: TimeInterval(elapsedTime),
            heartRate: nil,
            isResting: isResting
        )

        watchManager.sendWorkoutUpdate(workoutData)
    }
}
