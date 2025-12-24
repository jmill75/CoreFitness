import SwiftUI

struct WorkoutExecutionView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    // Prevent countdown from showing when dismissing
    @State private var isDismissing = false

    var body: some View {
        ZStack {
            // Black background like Apple Fitness
            Color.black
                .ignoresSafeArea()

            // Main content based on phase
            Group {
                switch workoutManager.currentPhase {
                case .idle:
                    ProgressView()
                        .tint(.white)
                        .onAppear {
                            // Only start workout if not dismissing
                            if !isDismissing {
                                workoutManager.startWorkout(workout)
                            }
                        }

                case .countdown(let remaining):
                    // Don't show countdown when dismissing
                    if !isDismissing {
                        CountdownView(count: remaining)
                            .transition(.scale.combined(with: .opacity))
                    }

                case .exercising, .loggingSet, .betweenExercises:
                    UnifiedWorkoutView()
                        .transition(.opacity)

                case .resting(let remaining):
                    RestingView(remaining: remaining)
                        .transition(.opacity)

                case .paused:
                    FitnessStylePausedView()

                case .completed:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: workoutManager.currentPhase)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $workoutManager.showWorkoutComplete) {
            WorkoutCompleteView()
                .interactiveDismissDisabled()
                .onDisappear {
                    isDismissing = true
                    dismiss()
                }
        }
        .confirmationDialog(
            "End Workout?",
            isPresented: $workoutManager.showExitConfirmation
        ) {
            Button("Save & Exit", role: .destructive) {
                isDismissing = true
                workoutManager.completeWorkout()
            }
            Button("Discard Workout", role: .destructive) {
                isDismissing = true
                workoutManager.cancelWorkout()
                dismiss()
            }
            Button("Continue Workout", role: .cancel) {}
        }
    }
}

// MARK: - Unified Workout View (Glove-Friendly)
struct UnifiedWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager

    // Local state for editing
    @State private var reps: Int = 10
    @State private var weight: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer(minLength: 0)

            // Main content - large touch targets
            VStack(spacing: 20) {
                // Set indicator
                setIndicator

                // Large input controls
                inputControls
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)

            // Large save button
            saveButton
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
        .onAppear {
            loadCurrentValues()
        }
        .onChange(of: workoutManager.currentSetNumber) { _, _ in
            loadCurrentValues()
        }
        .onChange(of: workoutManager.currentExerciseIndex) { _, _ in
            loadCurrentValues()
        }
    }

    private func loadCurrentValues() {
        reps = workoutManager.currentExercise?.targetReps ?? 10
        weight = workoutManager.currentExercise?.targetWeight ?? 0
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            // Timer
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text(workoutManager.formattedElapsedTime)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Spacer()

            // Exercise name
            Text(workoutManager.currentExercise?.exercise?.name ?? "Exercise")
                .font(.headline)
                .foregroundStyle(.gray)
                .lineLimit(1)

            Spacer()

            // Control buttons
            HStack(spacing: 8) {
                Button {
                    workoutManager.pauseWorkout()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }

                Button {
                    workoutManager.showExitConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Set Indicator
    private var setIndicator: some View {
        VStack(spacing: 8) {
            // Large set number
            Text("SET \(workoutManager.currentSetNumber)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Progress dots
            HStack(spacing: 10) {
                ForEach(1...(workoutManager.currentExercise?.targetSets ?? 3), id: \.self) { setNum in
                    Circle()
                        .fill(setNum < workoutManager.currentSetNumber ? Color.green :
                              setNum == workoutManager.currentSetNumber ? Color.yellow :
                              Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .overlay {
                            if setNum < workoutManager.currentSetNumber {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Input Controls (Large for gloves)
    private var inputControls: some View {
        VStack(spacing: 16) {
            // Reps row
            HStack(spacing: 0) {
                // Minus button
                Button {
                    if reps > 1 { reps -= 1 }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()

                // Reps display
                VStack(spacing: 4) {
                    Text("\(reps)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("REPS")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Plus button
                Button {
                    reps += 1
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)
                        .frame(width: 80, height: 80)
                        .background(Color.cyan.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            // Weight row
            HStack(spacing: 0) {
                // Minus button
                Button {
                    if weight >= 5 { weight -= 5 }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Text("-5")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()

                // Weight display
                VStack(spacing: 4) {
                    Text(themeManager.formatWeight(weight))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("WEIGHT")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Plus button
                Button {
                    weight += 5
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Text("+5")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .frame(width: 80, height: 80)
                        .background(Color.green.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Save Button (Extra large)
    private var saveButton: some View {
        VStack(spacing: 12) {
            Button {
                workoutManager.logSet(reps: reps, weight: weight, rpe: nil)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                    Text("SAVE SET")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
            }

            // Skip exercise link
            if !workoutManager.isLastExercise {
                Button {
                    workoutManager.nextExercise()
                } label: {
                    Text("Skip Exercise →")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}

// MARK: - Resting View
struct RestingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    let remaining: Int

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Rest icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "clock.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                }

                Text("REST")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .tracking(2)

                Text(formatTime(remaining))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // Next up info
                VStack(spacing: 8) {
                    Text("NEXT SET")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                        .tracking(1)

                    Text("Set \(workoutManager.currentSetNumber) of \(workoutManager.currentExercise?.targetSets ?? 0)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(workoutManager.currentExercise?.exercise?.name ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.top, 16)
            }

            Spacer()

            // Rest controls
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button {
                        workoutManager.skipRest()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.fill")
                            Text("Skip Rest")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        workoutManager.extendRest(by: 30)
                    } label: {
                        Text("+30s")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 56)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                // End workout
                Button {
                    workoutManager.showExitConfirmation = true
                } label: {
                    Text("End Workout")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Completed Set Card
struct CompletedSetCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let set: CompletedSet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Set \(set.setNumber)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                HStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("×")
                        .foregroundStyle(.gray)
                    Text(themeManager.formatWeight(set.weight))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .padding(12)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Fitness Style Paused View
struct FitnessStylePausedView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Paused icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "pause.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)
            }

            Text("Workout Paused")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text(workoutManager.formattedElapsedTime)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundStyle(.yellow)
                .monospacedDigit()

            Spacer()

            // Resume button
            Button {
                workoutManager.resumeWorkout()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Resume Workout")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            // End workout button
            Button {
                workoutManager.showExitConfirmation = true
            } label: {
                Text("End Workout")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    let workout = Workout(name: "Upper Body Strength", estimatedDuration: 45)
    return WorkoutExecutionView(workout: workout)
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
