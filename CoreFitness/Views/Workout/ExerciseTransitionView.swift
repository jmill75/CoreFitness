import SwiftUI

struct ExerciseTransitionView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    private var nextExercise: WorkoutExercise? {
        guard let exercises = workoutManager.currentWorkout?.sortedExercises,
              workoutManager.currentExerciseIndex + 1 < exercises.count else { return nil }
        return exercises[workoutManager.currentExerciseIndex + 1]
    }

    var body: some View {
        VStack(spacing: 32) {
            // Celebration header
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentGreen)

                Text("Exercise Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(workoutManager.currentExercise?.exercise?.name ?? "Exercise") finished")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress summary
            HStack(spacing: 24) {
                VStack {
                    Text("\(workoutManager.currentExerciseIndex + 1)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentGreen)
                    Text("Done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(workoutManager.totalExercises - workoutManager.currentExerciseIndex - 1)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Next exercise preview
            if let next = nextExercise {
                VStack(spacing: 16) {
                    Text("Up Next")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        IconBadge(
                            next.exercise?.muscleGroup.icon ?? "dumbbell.fill",
                            color: .accentOrange,
                            size: 56
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(next.exercise?.name ?? "Next Exercise")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("\(next.targetSets) sets x \(next.targetReps) reps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Spacer()

            // Continue button
            GradientButton(
                "Continue to Next Exercise",
                icon: "arrow.right",
                gradient: AppGradients.energetic
            ) {
                workoutManager.nextExercise()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ExerciseTransitionView()
        .environmentObject(WorkoutManager())
}
