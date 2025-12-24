import SwiftUI

struct WorkoutCompleteView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Celebration header
                    VStack(spacing: 16) {
                        ZStack {
                            // Glow effect
                            Circle()
                                .fill(Color.accentGreen.opacity(0.2))
                                .frame(width: 140, height: 140)
                                .blur(radius: 30)

                            Image(systemName: "trophy.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.accentYellow)
                        }
                        .bounceOnAppear()

                        Text("Workout Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(workoutManager.currentWorkout?.name ?? "Great work!")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    // Stats summary
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        SummaryStatCard(
                            icon: "clock.fill",
                            value: workoutManager.formattedElapsedTime,
                            label: "Duration",
                            color: .accentBlue
                        )

                        SummaryStatCard(
                            icon: "dumbbell.fill",
                            value: "\(workoutManager.totalExercises)",
                            label: "Exercises",
                            color: .accentOrange
                        )

                        SummaryStatCard(
                            icon: "checkmark.circle.fill",
                            value: "\(totalSetsCompleted)",
                            label: "Sets",
                            color: .accentGreen
                        )

                        SummaryStatCard(
                            icon: "scalemass.fill",
                            value: formattedVolume,
                            label: "Volume",
                            color: .accentTeal
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)

                    // Done button
                    GradientButton(
                        "Done",
                        icon: "checkmark",
                        gradient: AppGradients.success
                    ) {
                        workoutManager.resetState()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private var totalSetsCompleted: Int {
        workoutManager.currentSession?.completedSets?.count ?? 0
    }

    private var totalVolume: Double {
        workoutManager.currentSession?.completedSets?.reduce(0.0) { sum, set in
            sum + (set.weight * Double(set.reps))
        } ?? 0
    }

    private var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk", totalVolume / 1000)
        } else {
            return themeManager.formatWeight(totalVolume)
        }
    }
}

struct SummaryStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    WorkoutCompleteView()
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
