import SwiftUI
import Combine
import WatchConnectivity
import HealthKit
import WatchKit

// MARK: - Watch Workout State
@MainActor
class WatchWorkoutState: ObservableObject {
    @Published var isWorkoutActive = false
    @Published var workoutName = ""
    @Published var currentExercise = ""
    @Published var currentSet = 0
    @Published var totalSets = 0
    @Published var targetWeight: Double?
    @Published var targetReps: Int?
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRate: Double?
    @Published var isResting = false
    @Published var restTimeRemaining: Int = 0

    // Countdown state
    @Published var isCountingDown = false
    @Published var countdownValue: Int = 3

    // Health metrics
    @Published var caloriesBurned: Int = 0
    @Published var bloodOxygen: Double?

    // Extended runtime session to keep app alive
    private var extendedSession: WKExtendedRuntimeSession?

    // Timer for elapsed time sync
    private var elapsedTimer: Timer?

    // Start extended runtime session to prevent app from being suspended
    func startExtendedSession() {
        guard extendedSession == nil || extendedSession?.state == .invalid else { return }
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.start()
    }

    func stopExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = nil
    }

    func startCountdown() {
        isCountingDown = true
        countdownValue = 3

        // Countdown timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                if self.countdownValue > 0 {
                    self.countdownValue -= 1
                } else {
                    timer.invalidate()
                    // Short delay then transition
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    self.isCountingDown = false
                }
            }
        }
    }

    func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }

    func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    func reset() {
        isWorkoutActive = false
        workoutName = ""
        currentExercise = ""
        currentSet = 0
        totalSets = 0
        targetWeight = nil
        targetReps = nil
        elapsedTime = 0
        heartRate = nil
        isResting = false
        restTimeRemaining = 0
        isCountingDown = false
        countdownValue = 3
        caloriesBurned = 0
        bloodOxygen = nil
        stopElapsedTimer()
        stopExtendedSession()
    }
}

// MARK: - Watch Phone Connectivity Manager
@MainActor
class WatchPhoneConnectivityManager: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isPhoneReachable = false
    @Published var connectionStatus = "Connecting..."

    // MARK: - Private Properties
    private var session: WCSession?
    private var healthStore: HKHealthStore?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // MARK: - Callbacks
    var onWorkoutStarted: ((_ name: String, _ exercise: String, _ totalSets: Int) -> Void)?
    var onWorkoutEnded: ((_ duration: TimeInterval, _ exercisesCompleted: Int) -> Void)?
    var onExerciseChanged: ((_ exercise: String, _ setNumber: Int, _ totalSets: Int, _ weight: Double?, _ reps: Int?) -> Void)?
    var onRestTimerStarted: ((_ duration: Int) -> Void)?
    var onRestTimerEnded: (() -> Void)?
    var onHealthDataUpdate: ((_ heartRate: Double?, _ calories: Int?, _ bloodOxygen: Double?) -> Void)?
    var onCountdownStarted: (() -> Void)?
    var onElapsedTimeUpdate: ((_ time: TimeInterval) -> Void)?

    // MARK: - Callbacks for Mirrored Sessions
    var onMirroredWorkoutReceived: (() -> Void)?

    // MARK: - Initialization
    override init() {
        super.init()
        setupSession()
        // Don't request HealthKit auth on init - do it when workout starts
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            setupMirroringHandler()
        }
    }

    /// Set up handler to receive mirrored workout sessions from iPhone
    private func setupMirroringHandler() {
        healthStore?.workoutSessionMirroringStartHandler = { [weak self] mirroredSession in
            Task { @MainActor in
                print("Received mirrored workout session from iPhone!")
                self?.workoutSession = mirroredSession
                mirroredSession.delegate = self

                // Notify that a mirrored workout was received
                self?.onMirroredWorkoutReceived?()
            }
        }
    }

    private func setupSession() {
        guard WCSession.isSupported() else {
            connectionStatus = "Not Supported"
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        // Update status after brief delay to allow activation
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                updateConnectionStatus()
            }
        }
    }

    /// Request HealthKit authorization - call this before starting a workout
    func requestHealthKitAuthorization() {
        guard let healthStore = healthStore else { return }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        ]

        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
            }
        }
    }

    // MARK: - HealthKit Workout Session

    func startHealthKitWorkout() {
        guard let healthStore = healthStore else { return }

        // Request authorization first
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        ]

        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            Task { @MainActor in
                self?.startWorkoutSession()
            }
        }
    }

    private func startWorkoutSession() {
        guard let healthStore = healthStore else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            workoutSession?.delegate = self
            workoutBuilder?.delegate = self

            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("Failed to begin workout collection: \(error)")
                }
            }

            startHeartRateQuery()
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }

    func stopHealthKitWorkout() {
        workoutSession?.end()
        heartRateQuery = nil
    }

    private func startHeartRateQuery() {
        guard let healthStore = healthStore,
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            Task { @MainActor in
                self?.processHeartRateSamples(samples)
            }
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            Task { @MainActor in
                self?.processHeartRateSamples(samples)
            }
        }

        healthStore.execute(query)
        heartRateQuery = query
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
              let mostRecent = samples.last else { return }

        let heartRate = mostRecent.quantity.doubleValue(for: HKUnit(from: "count/min"))
        self.onHealthDataUpdate?(heartRate, nil, nil)
    }

    // MARK: - Public Methods

    /// Send set completed to iPhone
    func sendSetCompleted(exerciseId: String, weight: Double, reps: Int) {
        let data: [String: Any] = [
            "type": "set_completed",
            "exerciseId": exerciseId,
            "weight": weight,
            "reps": reps,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessage(data)
    }

    /// Request current workout state from iPhone
    func requestSync() {
        let data: [String: Any] = [
            "type": "request_sync",
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessage(data)
    }

    /// Send workout control action (pause, resume, skip)
    func sendWorkoutAction(_ action: String) {
        let data: [String: Any] = [
            "type": "workout_action",
            "action": action,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessage(data)
    }

    // MARK: - Private Methods

    private func sendMessage(_ message: [String: Any]) {
        guard let session = session else { return }

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                session.transferUserInfo(message)
            }
        } else {
            session.transferUserInfo(message)
        }
    }

    private func updateConnectionStatus() {
        guard let session = session else {
            connectionStatus = "Not Available"
            return
        }

        isPhoneReachable = session.isReachable

        if session.isReachable {
            connectionStatus = "Connected"
        } else if session.activationState == .activated {
            connectionStatus = "Ready"
        } else if session.activationState == .inactive {
            connectionStatus = "Inactive"
        } else {
            connectionStatus = "Not Activated"
        }
    }

    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let typeString = message["type"] as? String else { return }

        switch typeString {
        case "workout_started":
            handleWorkoutStarted(message)
        case "workout_ended":
            handleWorkoutEnded(message)
        case "exercise_changed":
            handleExerciseChanged(message)
        case "rest_timer_started":
            handleRestTimerStarted(message)
        case "rest_timer_ended":
            onRestTimerEnded?()
        case "health_data_update":
            handleHealthDataUpdate(message)
        case "workout_update":
            handleWorkoutUpdate(message)
        case "countdown_started":
            onCountdownStarted?()
        case "elapsed_time_update":
            handleElapsedTimeUpdate(message)
        default:
            break
        }
    }

    private func handleWorkoutStarted(_ message: [String: Any]) {
        let name = message["workoutName"] as? String ?? "Workout"
        let exercise = message["exercise"] as? String ?? ""
        let totalSets = message["totalSets"] as? Int ?? 0
        let showCountdown = message["showCountdown"] as? Bool ?? true

        // Start HealthKit workout session
        startHealthKitWorkout()

        if showCountdown {
            onCountdownStarted?()
        }
        onWorkoutStarted?(name, exercise, totalSets)
    }

    private func handleWorkoutEnded(_ message: [String: Any]) {
        let duration = message["duration"] as? TimeInterval ?? 0
        let exercisesCompleted = message["exercisesCompleted"] as? Int ?? 0

        // Stop HealthKit workout session
        stopHealthKitWorkout()

        onWorkoutEnded?(duration, exercisesCompleted)
    }

    private func handleExerciseChanged(_ message: [String: Any]) {
        let exercise = message["exercise"] as? String ?? ""
        let setNumber = message["setNumber"] as? Int ?? 0
        let totalSets = message["totalSets"] as? Int ?? 0
        let weight = message["targetWeight"] as? Double
        let reps = message["targetReps"] as? Int
        onExerciseChanged?(exercise, setNumber, totalSets, weight, reps)
    }

    private func handleRestTimerStarted(_ message: [String: Any]) {
        let duration = message["duration"] as? Int ?? 60
        onRestTimerStarted?(duration)
    }

    private func handleHealthDataUpdate(_ message: [String: Any]) {
        let heartRate = message["heartRate"] as? Double
        let calories = message["calories"] as? Int
        let bloodOxygen = message["bloodOxygen"] as? Double
        onHealthDataUpdate?(heartRate, calories, bloodOxygen)
    }

    private func handleWorkoutUpdate(_ message: [String: Any]) {
        if let name = message["workoutName"] as? String {
            onWorkoutStarted?(name, message["currentExercise"] as? String ?? "", message["totalSets"] as? Int ?? 0)
        }

        // Sync elapsed time
        if let elapsed = message["elapsedTime"] as? TimeInterval {
            onElapsedTimeUpdate?(elapsed)
        }
    }

    private func handleElapsedTimeUpdate(_ message: [String: Any]) {
        if let elapsed = message["elapsedTime"] as? TimeInterval {
            onElapsedTimeUpdate?(elapsed)
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchPhoneConnectivityManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            updateConnectionStatus()
            if activationState == .activated {
                requestSync()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateConnectionStatus()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            handleReceivedMessage(message)
            replyHandler(["status": "received"])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            handleReceivedMessage(userInfo)
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WatchPhoneConnectivityManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle workout state changes
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WatchPhoneConnectivityManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle collected events
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Process collected data (heart rate, calories, etc.)
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            if let statistics = workoutBuilder.statistics(for: quantityType) {
                Task { @MainActor in
                    switch quantityType {
                    case HKQuantityType.quantityType(forIdentifier: .heartRate):
                        if let heartRate = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                            self.onHealthDataUpdate?(heartRate, nil, nil)
                        }
                    case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                        if let calories = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                            self.onHealthDataUpdate?(nil, Int(calories), nil)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
}
