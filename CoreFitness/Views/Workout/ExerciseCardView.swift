import SwiftUI

struct ExerciseCardView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header - Progress & Timer
            WorkoutHeaderBar()

            ScrollView {
                VStack(spacing: 24) {
                    // Exercise Info Card
                    exerciseInfoCard

                    // Set Indicators
                    setIndicators

                    // Current Set Target
                    currentSetCard

                    // Previous Sets (if any)
                    if !workoutManager.completedSetsForCurrentExercise.isEmpty {
                        completedSetsSection
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)

            // Bottom Action Area
            VStack(spacing: 12) {
                // Log Set Button
                GradientButton(
                    "Log Set \(workoutManager.currentSetNumber)",
                    icon: "checkmark.circle.fill",
                    gradient: AppGradients.success
                ) {
                    workoutManager.openSetLogger()
                }
                .frame(maxWidth: .infinity)

                // Navigation hints
                HStack {
                    if workoutManager.currentExerciseIndex > 0 {
                        Button {
                            workoutManager.previousExercise()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if !workoutManager.isLastExercise {
                        Button {
                            workoutManager.nextExercise()
                        } label: {
                            HStack {
                                Text("Skip Exercise")
                                Image(systemName: "chevron.right")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
        }
    }

    // MARK: - Subviews

    private var exerciseInfoCard: some View {
        VStack(spacing: 16) {
            // Exercise icon and name
            HStack(spacing: 16) {
                IconBadge(
                    workoutManager.currentExercise?.exercise?.muscleGroup.icon ?? "dumbbell.fill",
                    color: .accentOrange,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutManager.currentExercise?.exercise?.name ?? "Exercise")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Exercise \(workoutManager.currentExerciseIndex + 1) of \(workoutManager.totalExercises)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Equipment & muscle group tags
            HStack(spacing: 8) {
                if let equipment = workoutManager.currentExercise?.exercise?.equipment {
                    TagPill(equipment.displayName, color: .accentBlue)
                }
                if let muscle = workoutManager.currentExercise?.exercise?.muscleGroup {
                    TagPill(muscle.displayName, color: .accentTeal)
                }
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var setIndicators: some View {
        HStack(spacing: 8) {
            ForEach(1...(workoutManager.currentExercise?.targetSets ?? 3), id: \.self) { setNum in
                SetIndicator(
                    setNumber: setNum,
                    status: setStatus(for: setNum)
                )
            }
        }
    }

    private var currentSetCard: some View {
        VStack(spacing: 16) {
            Text("Set \(workoutManager.currentSetNumber)")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(workoutManager.currentExercise?.targetReps ?? 0)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("@")
                    .font(.title)
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    Text(themeManager.formatWeight(workoutManager.currentExercise?.targetWeight ?? 0))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("target")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.brandPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var completedSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Sets")
                .font(.headline)

            ForEach(workoutManager.completedSetsForCurrentExercise, id: \.id) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(set.reps) reps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("@")
                        .foregroundStyle(.secondary)
                    Text(themeManager.formatWeight(set.weight))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentGreen)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func setStatus(for setNumber: Int) -> SetIndicator.Status {
        if setNumber < workoutManager.currentSetNumber {
            return .completed
        } else if setNumber == workoutManager.currentSetNumber {
            return .current
        } else {
            return .pending
        }
    }
}

// MARK: - Supporting Views

struct TagPill: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct SetIndicator: View {
    let setNumber: Int
    let status: Status

    enum Status {
        case pending, current, completed
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 40, height: 40)

            if status == .completed {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } else {
                Text("\(setNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor)
            }
        }
        .overlay {
            if status == .current {
                Circle()
                    .stroke(Color.brandPrimary, lineWidth: 3)
                    .frame(width: 44, height: 44)
            }
        }
        .animation(.spring(response: 0.3), value: status)
    }

    private var backgroundColor: Color {
        switch status {
        case .pending: return Color(.systemGray5)
        case .current: return Color.brandPrimary.opacity(0.2)
        case .completed: return Color.accentGreen
        }
    }

    private var textColor: Color {
        switch status {
        case .pending: return .secondary
        case .current: return .brandPrimary
        case .completed: return .white
        }
    }
}

#Preview {
    ExerciseCardView()
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
