import ActivityKit
import Foundation

/// Defines the data for the workout Live Activity
struct WorkoutActivityAttributes: ActivityAttributes {

    /// Static content that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        var elapsedTime: Int // seconds
        var currentExercise: String
        var currentSet: Int
        var totalSets: Int
        var isResting: Bool
        var restTimeRemaining: Int?
        var heartRate: Int?
        var isPaused: Bool
    }

    /// Fixed data set when activity starts
    var workoutName: String
    var startTime: Date
}
