import SwiftUI
import SwiftData
import Combine
import HealthKit
import UserNotifications

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

    // MARK: - Private Properties
    private var timer: Timer?
    private var restTimer: Timer?
    private var countdownTimer: Timer?
    private var modelContext: ModelContext?

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
        var countdown = 3
        currentPhase = .countdown(remaining: countdown)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                countdown -= 1

                if countdown > 0 {
                    self.currentPhase = .countdown(remaining: countdown)
                    // Haptic on each countdown number
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else {
                    // GO!
                    self.countdownTimer?.invalidate()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
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
            loggedWeight = exercise.targetWeight ?? getLastWeight(for: exercise) ?? 0
        }
        showSetLogger = true
        currentPhase = .loggingSet
    }

    /// Log a completed set
    func logSet(reps: Int, weight: Double, rpe: Int? = nil) {
        guard let exercise = currentExercise,
              let session = currentSession else { return }

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

        showSetLogger = false

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

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
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                } else if self.restTimeRemaining <= 5 {
                    // Countdown haptics for last 5 seconds
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Extend rest timer
    func extendRest(by seconds: Int = 30) {
        restTimeRemaining += seconds
        currentPhase = .resting(remaining: restTimeRemaining)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Move to next exercise
    func nextExercise() {
        guard !isLastExercise else {
            completeWorkout()
            return
        }

        currentExerciseIndex += 1
        currentSetNumber = 1
        prefillFromLastSession()
        currentPhase = .exercising

        notifyWatchExerciseChanged()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Go back to previous exercise
    func previousExercise() {
        guard currentExerciseIndex > 0 else { return }

        currentExerciseIndex -= 1
        currentSetNumber = 1
        currentPhase = .exercising

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Cancel/exit workout
    func cancelWorkout() {
        timer?.invalidate()
        restTimer?.invalidate()
        countdownTimer?.invalidate()

        currentSession?.status = .cancelled
        try? modelContext?.save()

        // Stop HealthKit workout session
        stopHealthKitWorkout()

        // Remove Watch prompt notification
        removeWatchAppNotification()

        // End Live Activity
        liveActivityManager.endActivity()

        resetState()
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
