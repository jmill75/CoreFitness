import SwiftUI
import SwiftData

// MARK: - Notification Extension
extension Notification.Name {
    static let activeProgramChanged = Notification.Name("activeProgramChanged")
}

struct ProgramDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    let program: ProgramTemplate
    let activeProgram: UserProgram?

    @Query private var exercises: [Exercise]
    @Query private var workouts: [Workout]

    @State private var selectedTab = 0
    @State private var showStartConfirmation = false
    @State private var showShareSheet = false
    @State private var showSwitchProgramAlert = false

    private var hasActiveProgram: Bool {
        activeProgram != nil && activeProgram?.template?.id != program.id
    }

    // Get today's day of week (1 = Monday, 7 = Sunday)
    private var todayDayOfWeek: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Convert from Sunday=1 to Monday=1 format
        return weekday == 1 ? 7 : weekday - 1
    }

    // Find today's schedule from the program
    private var todaysSchedule: ProgramDaySchedule? {
        program.schedule.first { $0.dayOfWeek == todayDayOfWeek }
    }

    // Find today's workout definition
    private var todaysWorkoutDefinition: ProgramWorkoutDefinition? {
        guard let schedule = todaysSchedule,
              !schedule.isRest,
              let workoutName = schedule.workoutName else {
            return nil
        }
        return program.workoutDefinitions.first { $0.name == workoutName }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        ProgramHeader(program: program)

                        // Stats Bar
                        ProgramStatsBar(program: program)

                        // Tab Selector
                        Picker("View", selection: $selectedTab) {
                            Text("Overview").tag(0)
                            Text("Schedule").tag(1)
                            Text("Workouts").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // Tab Content
                        switch selectedTab {
                        case 0:
                            OverviewTab(program: program)
                        case 1:
                            ScheduleTab(program: program)
                        case 2:
                            WorkoutsTab(program: program)
                        default:
                            EmptyView()
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }

                // Bottom Action Button
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        // Share Button
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }

                        // Add Program Button
                        Button {
                            if hasActiveProgram {
                                showSwitchProgramAlert = true
                            } else {
                                showStartConfirmation = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Program")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareProgramSheet(program: program)
            }
            .alert("Add Program?", isPresented: $showStartConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    startProgram()
                }
            } message: {
                Text("Add \(program.name) to your workouts? This \(program.durationWeeks)-week program will be queued and ready to start.")
            }
            .alert("End Current Program?", isPresented: $showSwitchProgramAlert) {
                Button("Keep Current", role: .cancel) { }
                Button("End & Replace", role: .destructive) {
                    switchToProgram()
                }
            } message: {
                if let currentProgram = activeProgram?.template {
                    Text("⚠️ This will permanently end your current program.\n\n\"\(currentProgram.name)\" (Week \(activeProgram?.currentWeek ?? 1) of \(currentProgram.durationWeeks))\n\n• All remaining scheduled workouts will be cancelled\n• Your completed progress will be saved to history\n• You cannot resume this program later\n\nAre you sure you want to end it and start \"\(program.name)\"?")
                } else {
                    Text("⚠️ This will end your current program.\n\nYour completed progress will be saved to history, but remaining workouts will be cancelled. You cannot resume the current program later.\n\nAre you sure you want to start \"\(program.name)\"?")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func startProgram() {
        let userProgram = UserProgram(template: program)
        modelContext.insert(userProgram)

        // Create ALL workouts for the entire program
        createAllProgramWorkouts(userProgram: userProgram)

        try? modelContext.save()

        // Notify views of program change
        NotificationCenter.default.post(name: .activeProgramChanged, object: nil)

        themeManager.mediumImpact()
        dismiss()
    }

    private func switchToProgram() {
        // Close out current program (save progress)
        if let active = activeProgram {
            active.status = .completed
            active.actualEndDate = Date()
        }

        // Start new program
        let userProgram = UserProgram(template: program)
        modelContext.insert(userProgram)

        // Create ALL workouts for the entire program
        createAllProgramWorkouts(userProgram: userProgram)

        try? modelContext.save()

        // Notify views of program change
        NotificationCenter.default.post(name: .activeProgramChanged, object: nil)

        themeManager.mediumImpact()
        dismiss()
    }

    // MARK: - Create All Program Workouts

    /// Creates all workouts for the entire program duration (e.g., 12 weeks = 36 workouts)
    private func createAllProgramWorkouts(userProgram: UserProgram) {
        let calendar = Calendar.current
        let startDate = userProgram.startDate

        // Clear any existing active workout - no workout should be active until user explicitly starts one
        for workout in workouts where workout.isActive {
            workout.isActive = false
        }

        var sessionNumber = 0

        // Loop through each week of the program
        for week in 1...program.durationWeeks {
            // Calculate the start of this week
            let weekStartDate = calendar.date(byAdding: .weekOfYear, value: week - 1, to: startDate) ?? startDate

            // Loop through each day of the week schedule
            for daySchedule in program.schedule {
                // Skip rest days
                guard !daySchedule.isRest,
                      let workoutName = daySchedule.workoutName,
                      let workoutDef = program.workoutDefinitions.first(where: { $0.name == workoutName }) else {
                    continue
                }

                sessionNumber += 1

                // Calculate the actual date for this workout
                // daySchedule.dayOfWeek: 1 = Monday, 7 = Sunday
                // We need to adjust based on the week start
                let daysToAdd = daySchedule.dayOfWeek - 1 // 0 for Monday, 6 for Sunday
                let workoutDate = calendar.date(byAdding: .day, value: daysToAdd, to: weekStartDate)

                // Create the workout - NOT active until user explicitly starts it
                let workout = createWorkoutFromDefinition(
                    workoutDef,
                    weekNumber: week,
                    dayNumber: daySchedule.dayOfWeek,
                    sessionNumber: sessionNumber,
                    scheduledDate: workoutDate,
                    isActive: false
                )

                modelContext.insert(workout)
            }
        }
    }

    // MARK: - Legacy: Set Current Workout from Program (kept for compatibility)

    private func setCurrentWorkoutFromProgram() {
        // Clear any existing active workout
        for workout in workouts where workout.isActive {
            workout.isActive = false
        }

        // If today is a rest day, find the next workout day
        guard let workoutDef = todaysWorkoutDefinition ?? getNextWorkoutDefinition() else {
            return
        }

        // Check if we already have a workout from this program with the same name
        if let existingWorkout = workouts.first(where: {
            $0.sourceProgramId == program.id && $0.name == workoutDef.name
        }) {
            // Reuse existing workout
            existingWorkout.isActive = true
            existingWorkout.updatedAt = Date()
        } else {
            // Create new workout from program definition
            let workout = createWorkoutFromDefinition(workoutDef)
            modelContext.insert(workout)
        }
    }

    private func getNextWorkoutDefinition() -> ProgramWorkoutDefinition? {
        // Find the next workout day in the schedule
        for dayOffset in 1...7 {
            let futureDay = ((todayDayOfWeek - 1 + dayOffset) % 7) + 1
            if let schedule = program.schedule.first(where: { $0.dayOfWeek == futureDay }),
               !schedule.isRest,
               let workoutName = schedule.workoutName,
               let workoutDef = program.workoutDefinitions.first(where: { $0.name == workoutName }) {
                return workoutDef
            }
        }
        // Fallback to first workout definition
        return program.workoutDefinitions.first
    }

    /// Creates a workout from a program definition with full program position tracking
    private func createWorkoutFromDefinition(
        _ definition: ProgramWorkoutDefinition,
        weekNumber: Int = 0,
        dayNumber: Int = 0,
        sessionNumber: Int = 0,
        scheduledDate: Date? = nil,
        isActive: Bool = true
    ) -> Workout {
        let workout = Workout(
            name: definition.name,
            description: definition.description,
            estimatedDuration: definition.estimatedMinutes,
            difficulty: program.difficulty,
            creationType: .preset,
            workoutType: .programSession,
            goal: mapCategoryToGoal(program.category)
        )

        // Set program tracking info
        workout.isActive = isActive
        workout.sourceProgramId = program.id
        workout.sourceProgramName = program.name
        workout.programWeekNumber = weekNumber
        workout.programDayNumber = dayNumber
        workout.programSessionNumber = sessionNumber
        workout.scheduledDate = scheduledDate

        // Set program duration info on the workout
        workout.totalWeeks = program.durationWeeks
        workout.totalDays = program.workoutsPerWeek
        workout.totalSessions = program.durationWeeks * program.workoutsPerWeek

        // Create workout exercises
        for (index, exerciseDef) in definition.exercises.enumerated() {
            let workoutExercise = WorkoutExercise(
                order: index,
                targetSets: exerciseDef.sets,
                targetReps: parseReps(exerciseDef.reps),
                targetWeight: parseWeight(exerciseDef.weight),
                restDuration: exerciseDef.restSeconds
            )
            workoutExercise.notes = exerciseDef.notes

            // Try to find matching exercise in database
            if let exercise = exercises.first(where: {
                $0.name.lowercased() == exerciseDef.exerciseName.lowercased()
            }) {
                workoutExercise.exercise = exercise
            } else {
                // Create a new exercise if not found
                let newExercise = Exercise(
                    name: exerciseDef.exerciseName,
                    muscleGroup: .fullBody,
                    category: program.category,
                    difficulty: program.difficulty
                )
                modelContext.insert(newExercise)
                workoutExercise.exercise = newExercise
            }

            workoutExercise.workout = workout
            modelContext.insert(workoutExercise)
        }

        return workout
    }

    /// Maps exercise category to workout goal
    private func mapCategoryToGoal(_ category: ExerciseCategory) -> WorkoutGoal {
        switch category {
        case .strength, .calisthenics: return .strength
        case .cardio, .running, .cycling, .swimming: return .cardio
        case .yoga, .pilates, .stretching: return .flexibility
        case .hiit: return .fatLoss
        }
    }

    private func parseReps(_ reps: String) -> Int {
        // Handle formats like "10", "8-12", "AMRAP"
        if let intReps = Int(reps) {
            return intReps
        }
        // For ranges like "8-12", take the lower value
        if let first = reps.split(separator: "-").first, let intReps = Int(first) {
            return intReps
        }
        return 10 // Default
    }

    private func parseWeight(_ weight: String?) -> Double? {
        guard let weight = weight else { return nil }
        // Handle formats like "135 lbs", "50 kg", "Bodyweight", "RPE 7"
        let numericValue = weight.filter { $0.isNumber || $0 == "." }
        return Double(numericValue)
    }
}

// MARK: - Program Header
struct ProgramHeader: View {
    let program: ProgramTemplate

    var body: some View {
        VStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: program.category.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(categoryColor)
            }

            VStack(spacing: 8) {
                // Category badge
                Text(program.category.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundStyle(categoryColor)

                Text(program.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Difficulty and Goal badges
                HStack(spacing: 8) {
                    Text(program.difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.2))
                        .clipShape(Capsule())

                    Text(program.goal.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            Text(program.programDescription)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var categoryColor: Color {
        switch program.category {
        case .strength: return .blue
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .teal
        case .hiit: return .orange
        case .stretching: return .green
        case .running: return .yellow
        case .cycling: return .blue
        case .swimming: return .cyan
        case .calisthenics: return .orange
        }
    }

    private var difficultyColor: Color {
        switch program.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Program Stats Bar
struct ProgramStatsBar: View {
    let program: ProgramTemplate

    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(program.durationWeeks)", label: "Weeks", icon: "calendar")
            Divider().background(Color.white.opacity(0.2)).frame(height: 40)
            StatItem(value: "\(program.workoutsPerWeek)", label: "Per Week", icon: "figure.run")
            Divider().background(Color.white.opacity(0.2)).frame(height: 40)
            StatItem(value: "\(program.estimatedMinutesPerSession)", label: "Min/Session", icon: "clock")
            Divider().background(Color.white.opacity(0.2)).frame(height: 40)
            StatItem(value: "\(program.totalWorkouts)", label: "Total", icon: "checkmark.circle")
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.cyan)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    let program: ProgramTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Equipment Required
            if !program.equipmentRequired.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Equipment Required")
                        .font(.headline)
                        .foregroundStyle(.white)

                    FlowLayout(spacing: 8) {
                        ForEach(Array(program.equipmentRequired.enumerated()), id: \.offset) { _, equipment in
                            Text(equipment)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }

            // What You'll Achieve
            VStack(alignment: .leading, spacing: 12) {
                Text("What You'll Achieve")
                    .font(.headline)
                    .foregroundStyle(.white)

                VStack(spacing: 10) {
                    AchievementRow(icon: "flame.fill", text: "Burn \(program.totalWorkouts * 300)+ calories over the program", color: .orange)
                    AchievementRow(icon: "calendar.badge.checkmark", text: "Complete \(program.totalWorkouts) structured workouts", color: .green)
                    AchievementRow(icon: "chart.line.uptrend.xyaxis", text: "Track progressive improvement", color: .cyan)
                    AchievementRow(icon: "trophy.fill", text: "Achieve your \(program.goal.displayName.lowercased()) goal", color: .yellow)
                }
            }
            .padding(.horizontal)

            // Schedule Preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Schedule Preview")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    ForEach(program.schedule) { day in
                        VStack(spacing: 6) {
                            Text(day.shortDayName)
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            Circle()
                                .fill(day.isRest ? Color.gray.opacity(0.3) : Color.green)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if day.isRest {
                                        Image(systemName: "bed.double.fill")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    } else {
                                        Image(systemName: "figure.run")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    }
                                }
                            Text(day.isRest ? "Rest" : "Train")
                                .font(.caption2)
                                .foregroundStyle(day.isRest ? .gray : .white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }
}

struct AchievementRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Schedule Tab (Calendar View)
struct ScheduleTab: View {
    let program: ProgramTemplate
    @State private var selectedWeek = 1

    var body: some View {
        VStack(spacing: 20) {
            // Week Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...program.durationWeeks, id: \.self) { week in
                        Button {
                            selectedWeek = week
                        } label: {
                            Text("Week \(week)")
                                .font(.subheadline)
                                .fontWeight(selectedWeek == week ? .semibold : .regular)
                                .foregroundStyle(selectedWeek == week ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedWeek == week ? Color.cyan : Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Calendar Grid
            VStack(spacing: 12) {
                // Days Header
                HStack(spacing: 8) {
                    ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Schedule Days
                HStack(spacing: 8) {
                    ForEach(program.schedule) { day in
                        ScheduleDayCell(day: day)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .green, label: "Workout Day")
                LegendItem(color: .gray.opacity(0.5), label: "Rest Day")
            }
            .padding(.horizontal)

            // Week Summary
            if let workoutDays = program.schedule.filter({ !$0.isRest }).count as Int? {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Week \(selectedWeek) Summary")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 16) {
                        SummaryCard(value: "\(workoutDays)", label: "Workouts", color: .green)
                        SummaryCard(value: "\(7 - workoutDays)", label: "Rest Days", color: .gray)
                        SummaryCard(value: "~\(workoutDays * program.estimatedMinutesPerSession)", label: "Minutes", color: .cyan)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ScheduleDayCell: View {
    let day: ProgramDaySchedule

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(day.isRest ? Color.gray.opacity(0.2) : Color.green.opacity(0.3))
                    .frame(width: 44, height: 44)

                if day.isRest {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray)
                } else {
                    Image(systemName: "figure.run")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                }
            }

            if let workoutName = day.workoutName {
                Text(workoutName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Rest")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

struct SummaryCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Workouts Tab
struct WorkoutsTab: View {
    let program: ProgramTemplate

    var body: some View {
        VStack(spacing: 16) {
            ForEach(program.workoutDefinitions) { workout in
                WorkoutDefinitionCard(workout: workout)
            }
        }
        .padding(.horizontal)
    }
}

struct WorkoutDefinitionCard: View {
    let workout: ProgramWorkoutDefinition
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        HStack(spacing: 12) {
                            Label("\(workout.exercises.count) exercises", systemImage: "dumbbell.fill")
                            Label("\(workout.estimatedMinutes) min", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.gray)
                }
                .padding()
            }

            // Expanded Content
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))

                VStack(spacing: 0) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.exerciseName)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                HStack(spacing: 8) {
                                    Text("\(exercise.sets) × \(exercise.reps)")
                                        .font(.caption)
                                        .foregroundStyle(.cyan)
                                    if let weight = exercise.weight {
                                        Text("• \(weight)")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    Text("• \(exercise.restSeconds)s rest")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)

                        if index < workout.exercises.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 44)
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Share Sheet
struct ShareProgramSheet: View {
    @Environment(\.dismiss) private var dismiss
    let program: ProgramTemplate
    @State private var shareText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Preview Card
                    VStack(spacing: 12) {
                        Image(systemName: program.category.icon)
                            .font(.largeTitle)
                            .foregroundStyle(.cyan)

                        Text(program.name)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("\(program.durationWeeks) weeks • \(program.workoutsPerWeek)x per week")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Share Options
                    VStack(spacing: 12) {
                        ShareOptionButton(icon: "message.fill", label: "Share via Messages", color: .green) {
                            shareViaMessages()
                        }
                        ShareOptionButton(icon: "link", label: "Copy Link", color: .blue) {
                            copyLink()
                        }
                        ShareOptionButton(icon: "square.and.arrow.up", label: "More Options", color: .gray) {
                            shareMore()
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Share Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.cyan)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private func shareViaMessages() {
        // Implementation for Messages sharing
    }

    private func copyLink() {
        UIPasteboard.general.string = "Check out \(program.name) on CoreFitness!"
    }

    private func shareMore() {
        // Implementation for system share sheet
    }
}

struct ShareOptionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Flow Layout for Equipment Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)

                if x + viewSize.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, viewSize.height)
                x += viewSize.width + spacing
            }

            size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    let template = ProgramTemplate(
        name: "Push Pull Legs Classic",
        description: "The gold standard bodybuilding split.",
        category: .strength,
        difficulty: .intermediate,
        durationWeeks: 12,
        workoutsPerWeek: 6
    )
    template.schedule = [
        ProgramDaySchedule(dayOfWeek: 1, workoutName: "Push", isRest: false),
        ProgramDaySchedule(dayOfWeek: 2, workoutName: "Pull", isRest: false),
        ProgramDaySchedule(dayOfWeek: 3, workoutName: "Legs", isRest: false),
        ProgramDaySchedule(dayOfWeek: 4, workoutName: "Push", isRest: false),
        ProgramDaySchedule(dayOfWeek: 5, workoutName: "Pull", isRest: false),
        ProgramDaySchedule(dayOfWeek: 6, workoutName: "Legs", isRest: false),
        ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
    ]

    return ProgramDetailView(program: template, activeProgram: nil)
        .environmentObject(ThemeManager())
}
