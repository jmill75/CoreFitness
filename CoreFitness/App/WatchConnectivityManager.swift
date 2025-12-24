import Foundation
import WatchConnectivity

// MARK: - Watch Workout Data
struct WatchWorkoutData: Codable {
    var workoutName: String
    var currentExercise: String
    var currentSet: Int
    var totalSets: Int
    var weight: Double?
    var reps: Int?
    var restTimeRemaining: Int?
    var elapsedTime: TimeInterval
    var heartRate: Double?
    var isResting: Bool
}

/// Manages communication between iOS and watchOS apps
@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties
    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    @Published var isReachable = false

    // MARK: - Callbacks
    var onSetCompleted: ((_ exerciseId: String, _ weight: Double, _ reps: Int) -> Void)?
    var onWorkoutControlAction: ((_ action: String) -> Void)?

    // MARK: - Computed Properties
    var connectionStatus: String {
        if !isPaired {
            return "Not Paired"
        } else if !isWatchAppInstalled {
            return "App Not Installed"
        } else if isReachable {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }

    // MARK: - Initialization
    private override init() {
        super.init()

        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Public Methods

    /// Send a message to the watch
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        guard WCSession.default.isReachable else {
            errorHandler?(WatchConnectivityError.notReachable)
            return
        }

        WCSession.default.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    /// Transfer user info to the watch (queued, guaranteed delivery)
    func transferUserInfo(_ userInfo: [String: Any]) {
        WCSession.default.transferUserInfo(userInfo)
    }

    /// Update application context (latest state, only most recent is kept)
    func updateApplicationContext(_ context: [String: Any]) throws {
        try WCSession.default.updateApplicationContext(context)
    }

    /// Send workout data to watch
    func sendWorkoutToWatch(_ workout: [String: Any]) {
        transferUserInfo(["workout": workout])
    }

    /// Send settings to watch
    func syncSettings(_ settings: [String: Any]) {
        do {
            try updateApplicationContext(["settings": settings])
        } catch {
            // Silent fail for settings sync
        }
    }

    // MARK: - Workout Methods

    /// Send countdown started notification to Watch (triggers countdown animation)
    func sendCountdownStarted(workoutName: String, firstExercise: String, totalSets: Int) {
        let data: [String: Any] = [
            "type": "workout_started",
            "workoutName": workoutName,
            "exercise": firstExercise,
            "totalSets": totalSets,
            "showCountdown": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessageWithFallback(data)
    }

    /// Send workout started notification to Watch
    func sendWorkoutStarted(workoutName: String, firstExercise: String, totalSets: Int) {
        let data: [String: Any] = [
            "type": "workout_started",
            "workoutName": workoutName,
            "exercise": firstExercise,
            "totalSets": totalSets,
            "showCountdown": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessageWithFallback(data)
    }

    /// Send elapsed time update to Watch
    func sendElapsedTimeUpdate(_ elapsedTime: Int) {
        let data: [String: Any] = [
            "type": "elapsed_time_update",
            "elapsedTime": TimeInterval(elapsedTime),
            "timestamp": Date().timeIntervalSince1970
        ]
        // Use direct message for real-time sync
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil, errorHandler: nil)
        }
    }

    /// Send workout ended notification to Watch
    func sendWorkoutEnded(duration: TimeInterval, exercisesCompleted: Int) {
        let data: [String: Any] = [
            "type": "workout_ended",
            "duration": duration,
            "exercisesCompleted": exercisesCompleted,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessageWithFallback(data)
    }

    /// Send current workout state to Watch
    func sendWorkoutUpdate(_ workoutData: WatchWorkoutData) {
        guard let encoded = try? JSONEncoder().encode(workoutData),
              let dict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            return
        }

        var data = dict
        data["type"] = "workout_update"
        sendMessageWithFallback(data)
    }

    /// Send exercise change notification to Watch
    func sendExerciseChanged(exerciseName: String, setNumber: Int, totalSets: Int, targetWeight: Double?, targetReps: Int?) {
        var data: [String: Any] = [
            "type": "exercise_changed",
            "exercise": exerciseName,
            "setNumber": setNumber,
            "totalSets": totalSets,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let weight = targetWeight {
            data["targetWeight"] = weight
        }
        if let reps = targetReps {
            data["targetReps"] = reps
        }

        sendMessageWithFallback(data)
    }

    /// Send rest timer started notification to Watch
    func sendRestTimerStarted(duration: Int) {
        let data: [String: Any] = [
            "type": "rest_timer_started",
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessageWithFallback(data)
    }

    /// Send rest timer ended notification to Watch
    func sendRestTimerEnded() {
        let data: [String: Any] = [
            "type": "rest_timer_ended",
            "timestamp": Date().timeIntervalSince1970
        ]
        sendMessageWithFallback(data)
    }

    // MARK: - Private Helpers

    private func sendMessageWithFallback(_ message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] _ in
                self?.transferUserInfo(message)
            }
        } else {
            transferUserInfo(message)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
                return
            }
            
            updateConnectionState(session)
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Reactivate the session for quick switching between watches
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateConnectionState(session)
        }
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateConnectionState(session)
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
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            handleReceivedUserInfo(userInfo)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            handleReceivedApplicationContext(applicationContext)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionState(_ session: WCSession) {
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isReachable = session.isReachable
        
        print("Watch connection state - Paired: \(isPaired), App Installed: \(isWatchAppInstalled), Reachable: \(isReachable)")
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        print("Received message from watch: \(message)")

        guard let type = message["type"] as? String else {
            // Handle legacy message types
            if let workoutCompleted = message["workoutCompleted"] as? Bool, workoutCompleted {
                NotificationCenter.default.post(name: .workoutCompletedOnWatch, object: nil, userInfo: message)
            }
            return
        }

        switch type {
        case "set_completed":
            // Handle set logged from Watch
            if let exerciseId = message["exerciseId"] as? String,
               let weight = message["weight"] as? Double,
               let reps = message["reps"] as? Int {
                onSetCompleted?(exerciseId, weight, reps)
            }

        case "workout_action":
            // Handle workout control actions from Watch
            if let action = message["action"] as? String {
                onWorkoutControlAction?(action)
            }

        case "request_sync":
            // Watch is requesting current workout state
            NotificationCenter.default.post(name: .watchRequestedSync, object: nil)

        default:
            break
        }
    }
    
    private func handleReceivedUserInfo(_ userInfo: [String: Any]) {
        print("Received user info from watch: \(userInfo)")
        
        // Handle user info transfer (e.g., workout data)
        if let workoutData = userInfo["completedWorkout"] as? [String: Any] {
            NotificationCenter.default.post(name: .workoutDataReceivedFromWatch, object: nil, userInfo: workoutData)
        }
    }
    
    private func handleReceivedApplicationContext(_ context: [String: Any]) {
        print("Received application context from watch: \(context)")
        
        // Handle application context updates
        NotificationCenter.default.post(name: .watchContextUpdated, object: nil, userInfo: context)
    }
}

// MARK: - Errors

enum WatchConnectivityError: LocalizedError {
    case notReachable
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .notReachable:
            return "Apple Watch is not reachable"
        case .notSupported:
            return "Watch Connectivity is not supported on this device"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let workoutCompletedOnWatch = Notification.Name("workoutCompletedOnWatch")
    static let workoutDataReceivedFromWatch = Notification.Name("workoutDataReceivedFromWatch")
    static let watchContextUpdated = Notification.Name("watchContextUpdated")
    static let watchRequestedSync = Notification.Name("watchRequestedSync")
}
