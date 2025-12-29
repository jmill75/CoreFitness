import SwiftUI
import SwiftData

// MARK: - Workout Dashboard View
struct WorkoutDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @Query(sort: \Workout.createdAt, order: .reverse)
    private var workouts: [Workout]

    @Query(sort: \UserProgram.startDate, order: .reverse)
    private var userPrograms: [UserProgram]

    @State private var showRestDaySheet = false
    @State private var showWorkoutWarning = false
    @State private var pendingWorkout: Workout?
    @State private var showCalendar = false

    // Get next scheduled workout - only if there's an active program
    private var nextWorkout: Workout? {
        // Only show next workout if there's an active user program
        guard hasActiveProgram else {
            return nil
        }

        // Find the next uncompleted workout from the program, sorted by scheduled date
        let programWorkouts = workouts.filter { workout in
            workout.programWeekNumber > 0 &&
            workout.status != .completed &&
            workout.status != .deleted
        }
        .sorted { w1, w2 in
            // Sort by session number or scheduled date
            if let d1 = w1.scheduledDate, let d2 = w2.scheduledDate {
                return d1 < d2
            }
            return w1.programSessionNumber < w2.programSessionNumber
        }

        return programWorkouts.first
    }

    // Check if there's an active program
    private var hasActiveProgram: Bool {
        userPrograms.contains { $0.isActive }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Collapsible Calendar Toggle
            CalendarToggleButton(isExpanded: $showCalendar)

            // Calendar View (collapsible)
            if showCalendar {
                WorkoutCalendarView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Weekly Stats
            WeeklyStatsCard()

            // Next Workout Card
            if let workout = nextWorkout {
                NextWorkoutCard(
                    workout: workout,
                    onStart: {
                        if workoutManager.hasActiveWorkout {
                            pendingWorkout = workout
                            showWorkoutWarning = true
                        } else {
                            startWorkout(workout)
                        }
                    },
                    onRestDay: {
                        showRestDaySheet = true
                    }
                )
            }

            // Active Workout Card (if in progress)
            if workoutManager.hasActiveWorkout {
                ActiveWorkoutDashboardCard()
            }

            // Saved Workouts Section
            SavedWorkoutsSection()

            // Recovery Card
            WorkoutRecoveryCard()
        }
        .sheet(isPresented: $showRestDaySheet) {
            RestDaySheet()
        }
        .alert("Workout In Progress", isPresented: $showWorkoutWarning) {
            Button("Cancel", role: .cancel) {
                pendingWorkout = nil
            }
            Button("Save & Start New") {
                if let workout = pendingWorkout {
                    workoutManager.saveAndCancelWorkout()
                    startWorkout(workout)
                }
                pendingWorkout = nil
            }
        } message: {
            Text("You have \"\(workoutManager.activeWorkoutName ?? "a workout")\" in progress. Starting a new workout will save your current progress.")
        }
    }

    private func startWorkout(_ workout: Workout) {
        workoutManager.startWorkout(workout)
        themeManager.mediumImpact()
    }
}

// MARK: - Next Workout Card
struct NextWorkoutCard: View {
    let workout: Workout
    let onStart: () -> Void
    let onRestDay: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentGreen)

                Text("Next Workout")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Workout Info
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.name)
                    .font(.title3)
                    .fontWeight(.bold)

                HStack(spacing: 16) {
                    Label("\(workout.exercises?.count ?? 0) exercises", systemImage: "figure.strengthtraining.traditional")

                    Label("\(workout.estimatedDuration) min", systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onRestDay) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                        Text("Rest Day")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentBlue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Active Workout Dashboard Card
struct ActiveWorkoutDashboardCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with pulsing indicator
            HStack {
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.accentGreen.opacity(0.5), lineWidth: 2)
                            .scaleEffect(1.5)
                    )

                Text("Workout In Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentGreen)

                Spacer()

                // Timer
                Text(formatTime(workoutManager.elapsedTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            // Workout name
            if let workout = workoutManager.currentWorkout {
                Text(workout.name)
                    .font(.title3)
                    .fontWeight(.bold)
            }

            // Progress
            HStack(spacing: 16) {
                // Exercise progress
                Label(
                    "\(workoutManager.currentExerciseIndex + 1)/\(workoutManager.totalExercises) exercises",
                    systemImage: "figure.strengthtraining.traditional"
                )

                // Sets completed
                if workoutManager.totalSets > 0 {
                    Label(
                        "\(workoutManager.completedSetsCount)/\(workoutManager.totalSets) sets",
                        systemImage: "checkmark.circle"
                    )
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentGreen)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                }
            }
            .frame(height: 8)

            // Action buttons
            HStack(spacing: 12) {
                if workoutManager.isPaused {
                    Button {
                        workoutManager.resumeWorkout()
                        themeManager.mediumImpact()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                } else {
                    Button {
                        workoutManager.pauseWorkout()
                        themeManager.mediumImpact()
                    } label: {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .font(.headline)
                        .foregroundStyle(Color.accentOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentOrange.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Button {
                    workoutManager.showExitConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("End")
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentGreen.opacity(0.3), lineWidth: 2)
                )
        )
    }

    private var progressPercentage: CGFloat {
        guard workoutManager.totalExercises > 0 else { return 0 }
        return CGFloat(workoutManager.currentExerciseIndex) / CGFloat(workoutManager.totalExercises)
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Calendar Toggle Button
struct CalendarToggleButton: View {
    @Binding var isExpanded: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            themeManager.lightImpact()
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentBlue)

                Text("Workout Calendar")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        WorkoutDashboardView()
            .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environmentObject(ThemeManager())
    .environmentObject(WorkoutManager())
    .environmentObject(HealthKitManager())
}
