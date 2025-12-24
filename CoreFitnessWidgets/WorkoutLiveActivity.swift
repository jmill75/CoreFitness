import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen / banner UI
            LockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.green)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.currentExercise)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let heartRate = context.state.heartRate {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text("\(heartRate)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        Text(formatTime(context.state.elapsedTime))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                            .monospacedDigit()
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Rest timer or workout name
                        if context.state.isResting, let restTime = context.state.restTimeRemaining {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundStyle(.orange)
                                Text("Rest: \(formatTime(restTime))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        } else {
                            HStack {
                                Text(context.attributes.workoutName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if context.state.isPaused {
                                    Label("Paused", systemImage: "pause.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }

                        // Control buttons
                        HStack(spacing: 12) {
                            Link(destination: URL(string: "corefitness://workout/\(context.state.isPaused ? "resume" : "pause")")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                        .font(.caption2)
                                    Text(context.state.isPaused ? "Resume" : "Pause")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(context.state.isPaused ? Color.green : Color.yellow.opacity(0.8))
                                .clipShape(Capsule())
                            }

                            if context.state.isResting {
                                Link(destination: URL(string: "corefitness://workout/skip-rest")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "forward.fill")
                                            .font(.caption2)
                                        Text("Skip")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                                }
                            }

                            Spacer()

                            Link(destination: URL(string: "corefitness://workout/end")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                    Text("End")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.green)
            } compactTrailing: {
                Text(formatTime(context.state.elapsedTime))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.green)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Top row: Timer and exercise info
            HStack(spacing: 16) {
                // Left: Exercise icon with progress ring
                ZStack {
                    // Progress ring
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: setProgress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(.green)
                }

                // Center: Timer and info
                VStack(alignment: .leading, spacing: 4) {
                    // Main timer - large
                    Text(formatTime(context.state.elapsedTime))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    if context.state.isResting, let restTime = context.state.restTimeRemaining {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text("Rest \(formatTime(restTime))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.orange)
                    } else if context.state.isPaused {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.fill")
                                .font(.caption)
                            Text("PAUSED")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.yellow)
                    } else {
                        Text(context.state.currentExercise)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Right: Set counter
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Set")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Text("\(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }

            // Bottom row: Control buttons
            HStack(spacing: 12) {
                // Pause/Resume Button
                Link(destination: URL(string: "corefitness://workout/\(context.state.isPaused ? "resume" : "pause")")!) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.caption)
                        Text(context.state.isPaused ? "Resume" : "Pause")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(context.state.isPaused ? Color.green : Color.yellow.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // End Workout Button
                Link(destination: URL(string: "corefitness://workout/end")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                        Text("End")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Skip Rest (if resting)
                if context.state.isResting {
                    Link(destination: URL(string: "corefitness://workout/skip-rest")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                                .font(.caption)
                            Text("Skip")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var setProgress: CGFloat {
        guard context.state.totalSets > 0 else { return 0 }
        return CGFloat(context.state.currentSet - 1) / CGFloat(context.state.totalSets)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview("Lock Screen", as: .content, using: WorkoutActivityAttributes(
    workoutName: "Push Day",
    startTime: Date()
)) {
    WorkoutLiveActivity()
} contentStates: {
    // Active workout
    WorkoutActivityAttributes.ContentState(
        elapsedTime: 1847,
        currentExercise: "Bench Press",
        currentSet: 3,
        totalSets: 4,
        isResting: false,
        restTimeRemaining: nil,
        heartRate: 142,
        isPaused: false
    )
    // Resting
    WorkoutActivityAttributes.ContentState(
        elapsedTime: 1900,
        currentExercise: "Bench Press",
        currentSet: 3,
        totalSets: 4,
        isResting: true,
        restTimeRemaining: 45,
        heartRate: 128,
        isPaused: false
    )
    // Paused
    WorkoutActivityAttributes.ContentState(
        elapsedTime: 2100,
        currentExercise: "Incline Dumbbell Press",
        currentSet: 2,
        totalSets: 3,
        isResting: false,
        restTimeRemaining: nil,
        heartRate: 95,
        isPaused: true
    )
}
