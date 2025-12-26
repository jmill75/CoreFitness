import SwiftUI

struct StrengthTrackingView: View {
    @Binding var activityData: ChallengeActivityData

    @State private var exercises: [StrengthExerciseEntry] = []
    @State private var showingAddExercise = false
    @State private var durationMinutes: Int = 45

    var totalWeight: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var totalReps: Int {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + $1.reps }
        }
    }

    var hasPR: Bool {
        exercises.contains { exercise in
            exercise.sets.contains { $0.isPR }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strength Details")
                .font(.headline)

            VStack(spacing: 12) {
                // Duration
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Duration")
                    Spacer()
                    Stepper("\(durationMinutes) min", value: $durationMinutes, in: 5...180, step: 5)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Summary Stats
                HStack(spacing: 16) {
                    StrengthStatBox(title: "Total Weight", value: formatWeight(totalWeight))
                    StrengthStatBox(title: "Sets", value: "\(totalSets)")
                    StrengthStatBox(title: "Reps", value: "\(totalReps)")
                }

                // Exercises List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Exercises")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            showingAddExercise = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }

                    if exercises.isEmpty {
                        Text("Tap + to add exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach($exercises) { $exercise in
                            ExerciseCard(exercise: $exercise, onDelete: {
                                exercises.removeAll { $0.id == exercise.id }
                            })
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet { newExercise in
                exercises.append(newExercise)
                updateActivityData()
            }
        }
        .onChange(of: durationMinutes) { _, _ in updateActivityData() }
        .onChange(of: exercises) { _, _ in updateActivityData() }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight >= 1000 {
            return String(format: "%.1fK", weight / 1000)
        }
        return String(format: "%.0f", weight)
    }

    private func updateActivityData() {
        activityData.durationSeconds = durationMinutes * 60
        activityData.totalWeightLifted = totalWeight
        activityData.totalSets = totalSets
        activityData.totalReps = totalReps
        activityData.exercisesCompleted = exercises.count
        activityData.isPR = hasPR
    }
}

// MARK: - Supporting Types

struct StrengthExerciseEntry: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var sets: [StrengthSetEntry]

    static func == (lhs: StrengthExerciseEntry, rhs: StrengthExerciseEntry) -> Bool {
        lhs.id == rhs.id
    }
}

struct StrengthSetEntry: Identifiable, Equatable {
    let id = UUID()
    var reps: Int
    var weight: Double
    var isPR: Bool

    static func == (lhs: StrengthSetEntry, rhs: StrengthSetEntry) -> Bool {
        lhs.id == rhs.id && lhs.reps == rhs.reps && lhs.weight == rhs.weight && lhs.isPR == rhs.isPR
    }
}

// MARK: - Strength Stat Box

struct StrengthStatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    @Binding var exercise: StrengthExerciseEntry
    let onDelete: () -> Void

    @State private var showingAddSet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button {
                    showingAddSet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.body)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                HStack {
                    Text("Set \(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(set.reps) x \(Int(set.weight)) lbs")
                        .font(.caption)
                    if set.isPR {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $showingAddSet) {
            AddSetSheet { newSet in
                exercise.sets.append(newSet)
            }
        }
    }
}

// MARK: - Add Exercise Sheet

struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (StrengthExerciseEntry) -> Void

    @State private var exerciseName = ""
    @State private var sets: [StrengthSetEntry] = []
    @State private var reps: Int = 10
    @State private var weight: Double = 45
    @State private var isPR = false

    let commonExercises = [
        "Bench Press", "Squat", "Deadlift", "Overhead Press",
        "Barbell Row", "Pull-ups", "Dumbbell Curl", "Tricep Extension",
        "Leg Press", "Lat Pulldown", "Shoulder Press", "Romanian Deadlift"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise name", text: $exerciseName)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonExercises, id: \.self) { name in
                                Button(name) {
                                    exerciseName = name
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }

                Section("Add Set") {
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                    Stepper("Weight: \(Int(weight)) lbs", value: $weight, in: 0...1000, step: 5)
                    Toggle("Personal Record", isOn: $isPR)

                    Button("Add Set") {
                        sets.append(StrengthSetEntry(reps: reps, weight: weight, isPR: isPR))
                        isPR = false
                    }
                }

                if !sets.isEmpty {
                    Section("Sets Added (\(sets.count))") {
                        ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                Spacer()
                                Text("\(set.reps) x \(Int(set.weight)) lbs")
                                if set.isPR {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            sets.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let exercise = StrengthExerciseEntry(name: exerciseName, sets: sets)
                        onAdd(exercise)
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty || sets.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Set Sheet

struct AddSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (StrengthSetEntry) -> Void

    @State private var reps: Int = 10
    @State private var weight: Double = 45
    @State private var isPR = false

    var body: some View {
        NavigationStack {
            Form {
                Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                Stepper("Weight: \(Int(weight)) lbs", value: $weight, in: 0...1000, step: 5)
                Toggle("Personal Record", isOn: $isPR)
            }
            .navigationTitle("Add Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(StrengthSetEntry(reps: reps, weight: weight, isPR: isPR))
                        dismiss()
                    }
                }
            }
        }
    }
}
