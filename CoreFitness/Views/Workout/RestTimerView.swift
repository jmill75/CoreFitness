import SwiftUI

struct RestTimerView: View {
    let remaining: Int

    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager

    private var progress: Double {
        guard let restDuration = workoutManager.currentExercise?.restDuration,
              restDuration > 0 else { return 0 }
        return Double(remaining) / Double(restDuration)
    }

    private var formattedTime: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 32) {
            // Header
            Text("Rest Time")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            // Timer ring
            ZStack {
                // Background glow
                Circle()
                    .fill(Color.accentBlue.opacity(0.1))
                    .frame(width: 260, height: 260)
                    .blur(radius: 40)

                // Progress ring
                ProgressRing(
                    progress: progress,
                    color: .accentBlue,
                    lineWidth: 16,
                    size: 220
                )

                // Time display
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text("until next set")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Next set preview
            VStack(spacing: 8) {
                Text("Next: Set \(workoutManager.currentSetNumber + 1)")
                    .font(.headline)

                if let exercise = workoutManager.currentExercise {
                    Text("\(exercise.targetReps) reps @ \(themeManager.formatWeight(exercise.targetWeight ?? 0))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                // Extend button
                Button {
                    workoutManager.extendRest(by: 30)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("30s")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                }

                // Skip button
                GradientButton(
                    "Skip Rest",
                    icon: "forward.fill",
                    gradient: AppGradients.energetic
                ) {
                    workoutManager.skipRest()
                }
            }
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    RestTimerView(remaining: 45)
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
