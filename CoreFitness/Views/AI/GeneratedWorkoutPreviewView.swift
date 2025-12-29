import SwiftUI
import SwiftData

// MARK: - Generated Workout Preview View

struct GeneratedWorkoutPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var generator: WorkoutGeneratorEngine

    @State private var selectedWorkoutIndex = 0
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    @State private var saveError: Error?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if let plan = generator.generatedPlan {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Program header
                            programHeader(plan)

                            // Program overview
                            programOverview(plan)

                            // Workouts list
                            workoutsList(plan)

                            // Save button
                            saveButton

                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                } else {
                    // Loading or error state
                    VStack(spacing: 16) {
                        if generator.isGenerating {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Generating your workout plan...")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        } else if let error = generator.generationError {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)

                            Text("Generation Failed")
                                .font(.headline)

                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Try Again") {
                                Task {
                                    try? await generator.generateWorkoutPlan()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Your Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            try? await generator.generateWorkoutPlan()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(generator.isGenerating)
                }
            }
            .alert("Saved!", isPresented: $showSaveSuccess) {
                Button("Done") {
                    generator.reset()
                    dismiss()
                }
            } message: {
                Text("Your workout program has been saved. You can find it in your Programs.")
            }
            .alert("Save Failed", isPresented: .init(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError?.localizedDescription ?? "An error occurred")
            }
        }
    }

    // MARK: - Program Header

    private func programHeader(_ plan: GeneratedWorkoutPlan) -> some View {
        VStack(spacing: 12) {
            // AI badge
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.caption)
                Text("AI Generated")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.brandPrimary.opacity(0.15))
            .foregroundStyle(Color.brandPrimary)
            .clipShape(Capsule())

            Text(plan.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(plan.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Program Overview

    private func programOverview(_ plan: GeneratedWorkoutPlan) -> some View {
        HStack(spacing: 16) {
            OverviewStat(
                icon: "calendar",
                value: "\(plan.weeks)",
                label: "Weeks"
            )

            Divider()
                .frame(height: 40)

            OverviewStat(
                icon: "figure.strengthtraining.traditional",
                value: "\(plan.workoutsPerWeek)",
                label: "Days/Week"
            )

            Divider()
                .frame(height: 40)

            OverviewStat(
                icon: "list.bullet",
                value: "\(plan.workouts.count)",
                label: "Workouts"
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Workouts List

    private func workoutsList(_ plan: GeneratedWorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Workouts")
                .font(.headline)

            ForEach(Array(plan.workouts.enumerated()), id: \.element.id) { index, workout in
                WorkoutPreviewCard(
                    workout: workout,
                    isExpanded: selectedWorkoutIndex == index,
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedWorkoutIndex == index {
                                selectedWorkoutIndex = -1
                            } else {
                                selectedWorkoutIndex = index
                            }
                        }
                        themeManager.lightImpact()
                    }
                )
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveProgram()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Program")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSaving)
    }

    // MARK: - Actions

    private func saveProgram() {
        isSaving = true
        generator.configure(modelContext: modelContext)

        Task {
            do {
                try await generator.saveGeneratedPlan()
                isSaving = false
                showSaveSuccess = true
                themeManager.notifySuccess()
            } catch {
                isSaving = false
                saveError = error
                themeManager.notifyError()
            }
        }
    }
}

// MARK: - Overview Stat

struct OverviewStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brandPrimary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workout Preview Card

struct WorkoutPreviewCard: View {
    let workout: GeneratedWorkout
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Day \(workout.dayNumber)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.brandPrimary)
                                .clipShape(Capsule())

                            Text(workout.name)
                                .font(.headline)
                        }

                        HStack(spacing: 12) {
                            Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                            Label("~\(workout.estimatedDuration) min", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(workout.exercises) { exercise in
                        ExercisePreviewRow(exercise: exercise)
                    }

                    if let notes = workout.notes, !notes.isEmpty {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Exercise Preview Row

struct ExercisePreviewRow: View {
    let exercise: GeneratedExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(exercise.sets) × \(exercise.reps)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())

                Text("\(exercise.restSeconds)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let generator = WorkoutGeneratorEngine.shared
    generator.generatedPlan = GeneratedWorkoutPlan(
        name: "Strength Builder Pro",
        description: "A comprehensive 8-week strength program designed to build muscle and increase power.",
        weeks: 8,
        workoutsPerWeek: 4,
        workouts: [
            GeneratedWorkout(
                dayNumber: 1,
                name: "Push Day",
                exercises: [
                    GeneratedExercise(exerciseName: "Bench Press", sets: 4, reps: "6-8", restSeconds: 120),
                    GeneratedExercise(exerciseName: "Overhead Press", sets: 3, reps: "8-10", restSeconds: 90),
                    GeneratedExercise(exerciseName: "Incline Dumbbell Press", sets: 3, reps: "10-12", restSeconds: 60),
                    GeneratedExercise(exerciseName: "Tricep Dips", sets: 3, reps: "8-12", restSeconds: 60),
                    GeneratedExercise(exerciseName: "Lateral Raises", sets: 3, reps: "12-15", restSeconds: 45)
                ],
                estimatedDuration: 55
            ),
            GeneratedWorkout(
                dayNumber: 2,
                name: "Pull Day",
                exercises: [
                    GeneratedExercise(exerciseName: "Deadlift", sets: 4, reps: "5", restSeconds: 180),
                    GeneratedExercise(exerciseName: "Pull-ups", sets: 4, reps: "6-10", restSeconds: 90),
                    GeneratedExercise(exerciseName: "Barbell Rows", sets: 3, reps: "8-10", restSeconds: 90),
                    GeneratedExercise(exerciseName: "Face Pulls", sets: 3, reps: "15-20", restSeconds: 45),
                    GeneratedExercise(exerciseName: "Bicep Curls", sets: 3, reps: "10-12", restSeconds: 45)
                ],
                estimatedDuration: 60
            )
        ]
    )

    return GeneratedWorkoutPreviewView()
        .environmentObject(ThemeManager())
        .environmentObject(generator)
}
