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
                    if context.state.isResting, let restTime = context.state.restTimeRemaining {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundStyle(.orange)
                            Text("Rest: \(formatTime(restTime))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("Tap to skip")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                    } else {
                        HStack {
                            Text(context.attributes.workoutName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if context.state.isPaused {
                                Label("Paused", systemImage: "pause.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
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
        HStack(spacing: 16) {
            // Left: Exercise icon
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 50, height: 50)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(.black)
            }

            // Center: Timer and info
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(context.state.elapsedTime))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
                    .monospacedDigit()

                if context.state.isResting, let restTime = context.state.restTimeRemaining {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("Rest \(formatTime(restTime))")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                } else {
                    Text("\(context.state.currentExercise) - Set \(context.state.currentSet)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Right: Pause button indicator
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
}
