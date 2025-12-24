import SwiftUI

struct WorkoutHeaderBar: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        HStack {
            // Exit button
            Button {
                workoutManager.showExitConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Progress indicator
            VStack(spacing: 2) {
                Text(workoutManager.currentWorkout?.name ?? "Workout")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                        Capsule()
                            .fill(AppGradients.success)
                            .frame(width: geo.size.width * workoutManager.exerciseProgress)
                    }
                }
                .frame(width: 100, height: 4)
            }

            Spacer()

            // Timer
            Text(workoutManager.formattedElapsedTime)
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .padding()
        .background(.regularMaterial)
    }
}

#Preview {
    WorkoutHeaderBar()
        .environmentObject(WorkoutManager())
}
