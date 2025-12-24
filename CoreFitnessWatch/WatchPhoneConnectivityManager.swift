import Foundation
import WatchConnectivity

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

    // MARK: - Callbacks
    var onWorkoutStarted: ((_ name: String, _ exercise: String, _ totalSets: Int) -> Void)?
    var onWorkoutEnded: ((_ duration: TimeInterval, _ exercisesCompleted: Int) -> Void)?
    var onExerciseChanged: ((_ exercise: String, _ setNumber: Int, _ totalSets: Int, _ weight: Double?, _ reps: Int?) -> Void)?
    var onRestTimerStarted: ((_ duration: Int) -> Void)?
    var onRestTimerEnded: (() -> Void)?
    var onHealthDataUpdate: ((_ heartRate: Double?) -> Void)?

    // MARK: - Initialization
    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard WCSession.isSupported() else {
            connectionStatus = "Not Supported"
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
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
            session.sendMessage(message, replyHandler: nil) { error in
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
        connectionStatus = session.isReachable ? "Connected" : "Phone Not Reachable"
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
        default:
            break
        }
    }

    private func handleWorkoutStarted(_ message: [String: Any]) {
        let name = message["workoutName"] as? String ?? "Workout"
        let exercise = message["exercise"] as? String ?? ""
        let totalSets = message["totalSets"] as? Int ?? 0
        onWorkoutStarted?(name, exercise, totalSets)
    }

    private func handleWorkoutEnded(_ message: [String: Any]) {
        let duration = message["duration"] as? TimeInterval ?? 0
        let exercisesCompleted = message["exercisesCompleted"] as? Int ?? 0
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
        onHealthDataUpdate?(heartRate)
    }

    private func handleWorkoutUpdate(_ message: [String: Any]) {
        // Full workout state update
        if let name = message["workoutName"] as? String {
            onWorkoutStarted?(name, message["currentExercise"] as? String ?? "", message["totalSets"] as? Int ?? 0)
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
