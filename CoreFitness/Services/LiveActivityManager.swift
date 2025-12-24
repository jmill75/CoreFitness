import ActivityKit
import Foundation

// Note: WorkoutActivityAttributes is defined in SharedModels/WorkoutActivityAttributes.swift
// and shared between the main app and widget extension

/// Manages Live Activities for workout tracking on lock screen and Dynamic Island
@MainActor
class LiveActivityManager: ObservableObject {

    static let shared = LiveActivityManager()

    private var currentActivity: Activity<WorkoutActivityAttributes>?

    private init() {}

    /// Check if Live Activities are supported
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Start a new Live Activity for a workout
    func startWorkoutActivity(workoutName: String, exerciseName: String, totalSets: Int) {
        guard areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }

        // End any existing activity first
        Task {
            await endAllActivities()
        }

        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName,
            startTime: Date()
        )

        let initialState = WorkoutActivityAttributes.ContentState(
            elapsedTime: 0,
            currentExercise: exerciseName,
            currentSet: 1,
            totalSets: totalSets,
            isResting: false,
            restTimeRemaining: nil,
            heartRate: nil,
            isPaused: false
        )

        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("Live Activity started: \(currentActivity?.id ?? "unknown")")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Update the Live Activity with current workout state
    func updateActivity(
        elapsedTime: Int,
        currentExercise: String,
        currentSet: Int,
        totalSets: Int,
        isResting: Bool,
        restTimeRemaining: Int? = nil,
        heartRate: Int? = nil,
        isPaused: Bool = false
    ) {
        guard let activity = currentActivity else { return }

        let updatedState = WorkoutActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            currentExercise: currentExercise,
            currentSet: currentSet,
            totalSets: totalSets,
            isResting: isResting,
            restTimeRemaining: restTimeRemaining,
            heartRate: heartRate,
            isPaused: isPaused
        )

        let content = ActivityContent(state: updatedState, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    /// End the current Live Activity
    func endActivity() {
        guard let activity = currentActivity else { return }

        let finalState = WorkoutActivityAttributes.ContentState(
            elapsedTime: 0,
            currentExercise: "Workout Complete",
            currentSet: 0,
            totalSets: 0,
            isResting: false,
            restTimeRemaining: nil,
            heartRate: nil,
            isPaused: false
        )

        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
            currentActivity = nil
            print("Live Activity ended")
        }
    }

    /// End all workout activities
    func endAllActivities() async {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            let finalState = WorkoutActivityAttributes.ContentState(
                elapsedTime: 0,
                currentExercise: "Complete",
                currentSet: 0,
                totalSets: 0,
                isResting: false,
                restTimeRemaining: nil,
                heartRate: nil,
                isPaused: false
            )
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
