import Foundation
import Combine

// MARK: - Challenge Timer Service
@MainActor
class ChallengeTimerService: ObservableObject {

    // MARK: - Timer State
    enum TimerState {
        case idle
        case running
        case paused
    }

    // MARK: - Published Properties
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?

    // MARK: - Private Properties
    private var timer: Timer?
    private var pausedElapsedSeconds: Int = 0
    private var lastResumeTime: Date?

    // MARK: - Computed Properties
    var isRunning: Bool { state == .running }
    var isPaused: Bool { state == .paused }
    var isIdle: Bool { state == .idle }

    var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedTimeWithMilliseconds: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Timer Controls

    func start() {
        guard state == .idle else { return }

        startTime = Date()
        lastResumeTime = startTime
        elapsedSeconds = 0
        pausedElapsedSeconds = 0
        state = .running
        startTimer()
    }

    func pause() {
        guard state == .running else { return }

        // Capture elapsed time at pause
        if let resumeTime = lastResumeTime {
            pausedElapsedSeconds += Int(Date().timeIntervalSince(resumeTime))
        }

        stopTimer()
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }

        lastResumeTime = Date()
        state = .running
        startTimer()
    }

    func stop() -> TimerResult {
        stopTimer()

        // Calculate final elapsed time
        if state == .running, let resumeTime = lastResumeTime {
            pausedElapsedSeconds += Int(Date().timeIntervalSince(resumeTime))
        }

        endTime = Date()
        let finalElapsed = pausedElapsedSeconds

        let result = TimerResult(
            startTime: startTime ?? Date(),
            endTime: endTime ?? Date(),
            durationSeconds: finalElapsed
        )

        reset()
        return result
    }

    func reset() {
        stopTimer()
        state = .idle
        elapsedSeconds = 0
        pausedElapsedSeconds = 0
        startTime = nil
        endTime = nil
        lastResumeTime = nil
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .running, let resumeTime = lastResumeTime else { return }
        let currentRunTime = Int(Date().timeIntervalSince(resumeTime))
        elapsedSeconds = pausedElapsedSeconds + currentRunTime
    }
}

// MARK: - Timer Result
struct TimerResult {
    let startTime: Date
    let endTime: Date
    let durationSeconds: Int

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
