import ActivityKit
import Foundation

/// Defines the data for the workout Live Activity
/// This file is shared between the main app and widget extension
struct WorkoutActivityAttributes: ActivityAttributes {

    /// Dynamic content that changes during the activity
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

    /// Static data set when activity starts
    var workoutName: String
    var startTime: Date
}
