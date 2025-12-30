import SwiftUI
import SwiftData

// MARK: - Saved Workouts Section
struct SavedWorkoutsSection: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var allSessions: [WorkoutSession]

    @State private var selectedSession: WorkoutSession?
    @State private var showDetailSheet = false
    @State private var showDeleteConfirmation = false
    @State private var sessionToDelete: WorkoutSession?

    // Filter for paused or cancelled sessions only
    private var savedSessions: [WorkoutSession] {
        allSessions.filter { $0.status == .paused || $0.status == .cancelled }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "pause.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentOrange)

                Text("Saved Workouts")
                    .font(.headline)
                    .fontWeight(.semibold)

                if !savedSessions.isEmpty {
                    Text("(\(savedSessions.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if savedSessions.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.title)
                            .foregroundStyle(.secondary)

                        Text("No saved workouts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                // Saved workout cards
                ForEach(savedSessions.prefix(3), id: \.id) { session in
                    DashboardSavedWorkoutCard(
                        session: session,
                        onTap: {
                            selectedSession = session
                            showDetailSheet = true
                        },
                        onDelete: {
                            sessionToDelete = session
                            showDeleteConfirmation = true
                        }
                    )
                }

                // Show more if there are additional sessions
                if savedSessions.count > 3 {
                    Button {
                        // Could navigate to a full list view
                    } label: {
                        HStack {
                            Text("View all \(savedSessions.count) saved workouts")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.accentBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showDetailSheet) {
            if let session = selectedSession {
                SavedWorkoutDetailSheet(session: session)
            }
        }
        .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
        } message: {
            Text("This will permanently delete this saved workout and all its progress.")
        }
    }

    private func deleteSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        try? modelContext.save()
        themeManager.mediumImpact()
    }
}

// MARK: - Saved Workout Card
struct DashboardSavedWorkoutCard: View {
    let session: WorkoutSession
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(session.status == .paused ? Color.accentOrange : Color.secondary)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workout?.name ?? "Workout")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        if let notes = session.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(timeAgo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: session.startedAt, relativeTo: Date())
    }
}

// MARK: - Saved Workout Detail Sheet
struct SavedWorkoutDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager

    let session: WorkoutSession

    @State private var showResumeWarning = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Workout Info
                    VStack(spacing: 8) {
                        Text(session.workout?.name ?? "Workout")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            Label(statusText, systemImage: statusIcon)
                                .font(.subheadline)
                                .foregroundStyle(statusColor)

                            if let duration = session.totalDuration, duration > 0 {
                                Label("\(duration / 60) min", systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top)

                    // Progress summary
                    if let completedSets = session.completedSets, !completedSets.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress Saved")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Completed Sets")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(completedSets.count)")
                                        .fontWeight(.semibold)
                                }

                                if let calories = session.caloriesBurned, calories > 0 {
                                    HStack {
                                        Text("Calories Burned")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(calories)")
                                            .fontWeight(.semibold)
                                    }
                                }

                                if let notes = session.notes {
                                    HStack {
                                        Text("Status")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(notes)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }

                    // Notes
                    if let notes = session.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)

                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Time info
                    VStack(spacing: 8) {
                        HStack {
                            Text("Started")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatDate(session.startedAt))
                        }

                        if let completedAt = session.completedAt {
                            HStack {
                                Text("Saved")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatDate(completedAt))
                            }
                        }
                    }
                    .font(.subheadline)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    Spacer(minLength: 40)

                    // Action Buttons
                    VStack(spacing: 12) {
                        // Resume button - only for paused workouts
                        if session.status == .paused {
                            Button {
                                if workoutManager.hasActiveWorkout {
                                    showResumeWarning = true
                                } else {
                                    resumeWorkout()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Resume Workout")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        // Start Over button
                        if let workout = session.workout {
                            Button {
                                if workoutManager.hasActiveWorkout {
                                    showResumeWarning = true
                                } else {
                                    startOver(workout: workout)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Start Over")
                                }
                                .font(.headline)
                                .foregroundStyle(Color.accentBlue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentBlue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        // Delete button
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Saved Workout")
                            }
                            .font(.headline)
                            .foregroundStyle(Color.accentRed)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentRed.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Saved Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Workout In Progress", isPresented: $showResumeWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Save & Continue") {
                workoutManager.saveAndCancelWorkout()
                if session.status == .paused {
                    resumeWorkout()
                } else if let workout = session.workout {
                    startOver(workout: workout)
                }
            }
        } message: {
            Text("You have \"\(workoutManager.activeWorkoutName ?? "a workout")\" in progress. Starting this workout will save your current progress.")
        }
        .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("This will permanently delete this saved workout and all its progress.")
        }
    }

    // MARK: - Helper Methods

    private var statusText: String {
        session.status == .paused ? "Paused" : "Saved"
    }

    private var statusIcon: String {
        session.status == .paused ? "pause.circle.fill" : "arrow.uturn.backward.circle"
    }

    private var statusColor: Color {
        session.status == .paused ? .accentOrange : .secondary
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func resumeWorkout() {
        // TODO: Implement resume functionality in WorkoutManager
        dismiss()
        themeManager.mediumImpact()
    }

    private func startOver(workout: Workout) {
        // Delete the saved session and start fresh
        modelContext.delete(session)
        try? modelContext.save()
        workoutManager.startWorkout(workout)
        dismiss()
        themeManager.mediumImpact()
    }

    private func deleteWorkout() {
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
        themeManager.mediumImpact()
    }
}

#Preview {
    SavedWorkoutsSection()
        .environmentObject(ThemeManager())
        .environmentObject(WorkoutManager())
        .padding()
        .background(Color(.systemGroupedBackground))
}
