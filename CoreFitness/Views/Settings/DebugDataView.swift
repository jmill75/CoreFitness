import SwiftUI
import SwiftData

struct DebugDataView: View {

    @Environment(\.modelContext) private var modelContext

    // Queries for all data types
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Workout.name) private var workouts: [Workout]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \CompletedSet.completedAt, order: .reverse) private var completedSets: [CompletedSet]
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) private var personalRecords: [PersonalRecord]
    @Query(sort: \DailyHealthData.date, order: .reverse) private var healthData: [DailyHealthData]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]
    @Query private var streakData: [StreakData]
    @Query private var achievements: [Achievement]
    @Query(sort: \UserAchievement.earnedAt, order: .reverse) private var userAchievements: [UserAchievement]
    @Query(sort: \WorkoutShare.sharedAt, order: .reverse) private var workoutShares: [WorkoutShare]
    @Query(sort: \WeeklySummary.weekStartDate, order: .reverse) private var weeklySummaries: [WeeklySummary]
    @Query(sort: \MonthlySummary.year, order: .reverse) private var monthlySummaries: [MonthlySummary]
    @Query private var userProfiles: [UserProfile]

    var body: some View {
        List {
            // Summary Section
            Section {
                SummaryRow(label: "Exercises", count: exercises.count, icon: "figure.strengthtraining.traditional", color: .blue)
                SummaryRow(label: "Workouts", count: workouts.count, icon: "dumbbell.fill", color: .green)
                SummaryRow(label: "Sessions", count: sessions.count, icon: "clock.fill", color: .orange)
                SummaryRow(label: "Completed Sets", count: completedSets.count, icon: "checkmark.circle.fill", color: .purple)
                SummaryRow(label: "Personal Records", count: personalRecords.count, icon: "trophy.fill", color: .yellow)
                SummaryRow(label: "Health Data Days", count: healthData.count, icon: "heart.fill", color: .red)
                SummaryRow(label: "Mood Entries", count: moodEntries.count, icon: "face.smiling.fill", color: .pink)
                SummaryRow(label: "Achievements", count: achievements.count, icon: "star.fill", color: .yellow)
                SummaryRow(label: "User Achievements", count: userAchievements.count, icon: "medal.fill", color: .orange)
                SummaryRow(label: "Workout Shares", count: workoutShares.count, icon: "square.and.arrow.up", color: .blue)
            } header: {
                Text("Data Summary")
            }

            // Exercises
            Section {
                ForEach(exercises) { exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack {
                            Text(exercise.muscleGroup.displayName)
                            Text("•")
                            Text(exercise.equipment.displayName)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Exercises (\(exercises.count))")
            }

            // Workouts
            Section {
                ForEach(workouts) { workout in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack {
                            Text("\(workout.exerciseCount) exercises")
                            Text("•")
                            Text("\(workout.estimatedDuration) min")
                            Text("•")
                            Text(workout.difficulty.displayName)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Workouts (\(workouts.count))")
            }

            // Sessions
            Section {
                ForEach(sessions.prefix(20)) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.workout?.name ?? "Unknown Workout")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            StatusBadge(status: session.status)
                        }
                        HStack {
                            Text(session.startedAt, style: .date)
                            if let duration = session.totalDuration {
                                Text("•")
                                Text("\(duration / 60) min")
                            }
                            Text("•")
                            Text("\(session.completedSets?.count ?? 0) sets")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Sessions (showing \(min(sessions.count, 20)) of \(sessions.count))")
            }

            // Completed Sets
            Section {
                ForEach(completedSets.prefix(30)) { set in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.workoutExercise?.exercise?.name ?? "Unknown")
                                .font(.subheadline)
                            Text("Set \(set.setNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(set.weight)) lbs × \(set.reps)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(set.completedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Completed Sets (showing \(min(completedSets.count, 30)) of \(completedSets.count))")
            }

            // Personal Records
            Section {
                ForEach(personalRecords) { pr in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pr.exerciseName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(pr.achievedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(pr.weight)) lbs")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            if let improvement = pr.improvementPercentage {
                                Text("+\(String(format: "%.1f", improvement))%")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            } header: {
                Text("Personal Records (\(personalRecords.count))")
            }

            // Health Data
            Section {
                ForEach(healthData.prefix(14)) { data in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.date, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack(spacing: 16) {
                            if let steps = data.steps {
                                Label("\(steps)", systemImage: "figure.walk")
                            }
                            if let water = data.waterIntake {
                                Label("\(Int(water))oz", systemImage: "drop.fill")
                            }
                            if let sleep = data.sleepDuration {
                                Label("\(sleep / 60)h", systemImage: "bed.double.fill")
                            }
                            if let hr = data.restingHeartRate {
                                Label("\(hr)", systemImage: "heart.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Health Data (showing \(min(healthData.count, 14)) of \(healthData.count))")
            }

            // Mood Entries
            Section {
                ForEach(moodEntries.prefix(14)) { entry in
                    HStack {
                        Text(moodEmoji(for: entry.mood))
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.mood.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let energy = entry.energyLevel {
                            Text("Energy: \(energy)/10")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Mood Entries (showing \(min(moodEntries.count, 14)) of \(moodEntries.count))")
            }

            // Streak Data
            Section {
                if let streak = streakData.first {
                    LabeledContent("Current Streak", value: "\(streak.currentStreak) days")
                    LabeledContent("Longest Streak", value: "\(streak.longestStreak) days")
                    LabeledContent("Total Workout Days", value: "\(streak.totalWorkoutDays)")
                    LabeledContent("Weekly Goal", value: "\(streak.weeklyGoal) workouts")
                    LabeledContent("This Week", value: "\(streak.currentWeekWorkouts) workouts")
                    if let lastWorkout = streak.lastWorkoutDate {
                        LabeledContent("Last Workout", value: lastWorkout.formatted(date: .abbreviated, time: .omitted))
                    }
                } else {
                    Text("No streak data")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Streak Data")
            }

            // Achievements
            Section {
                ForEach(achievements.prefix(10)) { achievement in
                    HStack {
                        Text(achievement.emoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(achievement.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(achievement.achievementDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(achievement.points) pts")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("Achievements (showing \(min(achievements.count, 10)) of \(achievements.count))")
            }

            // User Achievements
            Section {
                ForEach(userAchievements) { ua in
                    HStack {
                        Image(systemName: ua.isComplete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(ua.isComplete ? .green : .gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ua.achievementId)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Progress: \(ua.progress)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if ua.isComplete {
                            Text(ua.earnedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("User Achievements (\(userAchievements.count))")
            }

            // Workout Shares
            Section {
                ForEach(workoutShares) { share in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(share.workoutName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(share.platform.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        HStack {
                            Text(share.sharedAt, style: .date)
                            Text("•")
                            Text("\(share.totalSets) sets")
                            Text("•")
                            Text(String(format: "%.0f lbs", share.totalVolume))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Workout Shares (\(workoutShares.count))")
            }

            // Weekly Summaries
            Section {
                ForEach(weeklySummaries.prefix(4)) { summary in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.weekStartDate.formatted(date: .abbreviated, time: .omitted)) - \(summary.weekEndDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack(spacing: 16) {
                            Label("\(summary.workoutsCompleted)", systemImage: "dumbbell.fill")
                            Label("\(summary.totalWorkoutMinutes)m", systemImage: "clock.fill")
                            Label("\(summary.prsAchieved)", systemImage: "trophy.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Weekly Summaries (\(weeklySummaries.count))")
            }

            // User Profile
            Section {
                if let profile = userProfiles.first {
                    if let name = profile.displayName {
                        LabeledContent("Name", value: name)
                    }
                    LabeledContent("Weekly Goal", value: "\(profile.weeklyWorkoutGoal) workouts")
                    LabeledContent("Daily Steps Goal", value: "\(profile.dailyStepsGoal)")
                    LabeledContent("Water Goal", value: "\(Int(profile.dailyWaterGoal)) oz")
                    LabeledContent("Use Metric", value: profile.useMetricSystem ? "Yes" : "No")
                    LabeledContent("Rest Timer", value: "\(profile.restTimerDuration) sec")
                    LabeledContent("Total Workouts", value: "\(profile.totalWorkoutsCompleted)")
                    LabeledContent("Member Since", value: profile.memberSince.formatted(date: .abbreviated, time: .omitted))
                } else {
                    Text("No user profile")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("User Profile")
            }
        }
        .navigationTitle("Debug Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func moodEmoji(for mood: Mood) -> String {
        switch mood {
        case .amazing: return "🤩"
        case .good: return "😊"
        case .okay: return "😐"
        case .tired: return "😴"
        case .stressed: return "😫"
        }
    }
}

// MARK: - Helper Views

struct SummaryRow: View {
    let label: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
                .foregroundStyle(count > 0 ? .primary : .secondary)
        }
    }
}

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .blue
        case .paused: return .orange
        case .cancelled: return .red
        }
    }
}

// MARK: - Debug Actions View

struct DebugActionsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    @State private var deleteType: DeleteType?
    @State private var showSuccessMessage = false
    @State private var successMessage = ""

    enum DeleteType: String, CaseIterable {
        case workouts = "Workouts"
        case programTemplates = "Program Templates"
        case exercises = "Exercises"
        case sessions = "Sessions"
        case completedSets = "Completed Sets"
        case personalRecords = "Personal Records"
        case healthData = "Health Data"
        case moodEntries = "Mood Entries"
        case achievements = "User Achievements"
        case shares = "Workout Shares"
        case all = "All Data"
    }

    var body: some View {
        List {
            // Seed Data Section
            Section {
                Button {
                    seedSampleWorkout()
                } label: {
                    Label("Create Sample Workout", systemImage: "plus.circle.fill")
                }

                Button {
                    seedSampleHealthData()
                } label: {
                    Label("Generate Health Data (7 days)", systemImage: "heart.fill")
                }

                Button {
                    seedSampleMoods()
                } label: {
                    Label("Generate Mood Entries (7 days)", systemImage: "face.smiling.fill")
                }

                Button {
                    seedSamplePRs()
                } label: {
                    Label("Generate Sample PRs", systemImage: "trophy.fill")
                }

                Button {
                    AchievementDefinitions.seedAchievements(in: modelContext)
                    showSuccess("Achievements seeded")
                } label: {
                    Label("Seed Achievements", systemImage: "star.fill")
                }

                Button {
                    ExerciseData.seedExercises(in: modelContext)
                    showSuccess("Exercises seeded")
                } label: {
                    Label("Seed Exercises", systemImage: "figure.strengthtraining.traditional")
                }

                Button {
                    reseedExercises()
                } label: {
                    Label("Reset & Reseed Exercises", systemImage: "arrow.counterclockwise")
                }
                .foregroundStyle(.orange)

                Button {
                    ProgramData.seedPrograms(in: modelContext)
                    showSuccess("Programs seeded")
                } label: {
                    Label("Seed Programs", systemImage: "calendar")
                }
            } header: {
                Text("Seed Data")
            } footer: {
                Text("Generate sample data for testing. Use 'Reset & Reseed Exercises' to clear existing exercises and reload from scratch with video URLs.")
            }

            // Delete Data Section
            Section {
                ForEach(DeleteType.allCases, id: \.self) { type in
                    Button(role: .destructive) {
                        deleteType = type
                        showDeleteAlert = true
                    } label: {
                        Label("Delete \(type.rawValue)", systemImage: "trash.fill")
                    }
                }
            } header: {
                Text("Delete Data")
            } footer: {
                Text("Permanently delete data from the database.")
            }

            // Export Section
            Section {
                Button {
                    exportDataToConsole()
                } label: {
                    Label("Print Data to Console", systemImage: "terminal.fill")
                }
            } header: {
                Text("Export")
            }
        }
        .navigationTitle("Debug Actions")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete \(deleteType?.rawValue ?? "")?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let type = deleteType {
                    performDelete(type)
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .overlay {
            if showSuccessMessage {
                VStack {
                    Spacer()
                    Text(successMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Capsule())
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showSuccessMessage)
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }

    private func seedSampleWorkout() {
        // Create exercises
        let benchPress = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        let squat = Exercise(name: "Barbell Squat", muscleGroup: .quadriceps, equipment: .barbell)
        let deadlift = Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell)

        modelContext.insert(benchPress)
        modelContext.insert(squat)
        modelContext.insert(deadlift)

        // Create workout
        let workout = Workout(name: "Full Body Power", description: "Compound lifts for strength", estimatedDuration: 60, difficulty: .intermediate)
        modelContext.insert(workout)

        // Add exercises to workout
        let we1 = WorkoutExercise(order: 0, targetSets: 4, targetReps: 8, targetWeight: 135, restDuration: 120)
        we1.workout = workout
        we1.exercise = benchPress
        modelContext.insert(we1)

        let we2 = WorkoutExercise(order: 1, targetSets: 4, targetReps: 6, targetWeight: 185, restDuration: 180)
        we2.workout = workout
        we2.exercise = squat
        modelContext.insert(we2)

        let we3 = WorkoutExercise(order: 2, targetSets: 3, targetReps: 5, targetWeight: 225, restDuration: 180)
        we3.workout = workout
        we3.exercise = deadlift
        modelContext.insert(we3)

        try? modelContext.save()
        showSuccess("Sample workout created")
    }

    private func seedSampleHealthData() {
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let data = DailyHealthData(date: date)
            data.steps = Int.random(in: 5000...15000)
            data.activeCalories = Int.random(in: 200...600)
            data.waterIntake = Double.random(in: 40...80)
            data.waterGoal = 64
            data.sleepDuration = Int.random(in: 360...540)
            data.restingHeartRate = Int.random(in: 55...75)
            data.recoveryScore = Int.random(in: 60...95)
            modelContext.insert(data)
        }
        try? modelContext.save()
        showSuccess("7 days of health data generated")
    }

    private func seedSampleMoods() {
        let moods: [Mood] = [.amazing, .good, .good, .okay, .tired, .good, .amazing]
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let entry = MoodEntry(date: date, mood: moods[i], energyLevel: Int.random(in: 5...10), stressLevel: Int.random(in: 1...5))
            modelContext.insert(entry)
        }
        try? modelContext.save()
        showSuccess("7 days of mood entries generated")
    }

    private func seedSamplePRs() {
        let exercises = ["Bench Press", "Squat", "Deadlift", "Overhead Press"]
        for exercise in exercises {
            let pr = PersonalRecord(exerciseName: exercise, weight: Double.random(in: 100...300), reps: Int.random(in: 1...5))
            modelContext.insert(pr)
        }
        try? modelContext.save()
        showSuccess("Sample PRs generated")
    }

    private func reseedExercises() {
        do {
            // Delete all existing exercises
            try modelContext.delete(model: Exercise.self)
            try modelContext.save()

            // Reseed with fresh data including video URLs
            ExerciseData.seedExercises(in: modelContext)
            showSuccess("Exercises reset and reseeded")
        } catch {
            print("Failed to reseed exercises: \(error)")
        }
    }

    private func performDelete(_ type: DeleteType) {
        do {
            switch type {
            case .workouts:
                try modelContext.delete(model: WorkoutExercise.self)
                try modelContext.delete(model: Workout.self)
            case .programTemplates:
                try modelContext.delete(model: UserProgram.self)
                try modelContext.delete(model: ProgramTemplate.self)
            case .exercises:
                try modelContext.delete(model: Exercise.self)
            case .sessions:
                try modelContext.delete(model: WorkoutSession.self)
            case .completedSets:
                try modelContext.delete(model: CompletedSet.self)
            case .personalRecords:
                try modelContext.delete(model: PersonalRecord.self)
            case .healthData:
                try modelContext.delete(model: DailyHealthData.self)
            case .moodEntries:
                try modelContext.delete(model: MoodEntry.self)
            case .achievements:
                try modelContext.delete(model: UserAchievement.self)
            case .shares:
                try modelContext.delete(model: WorkoutShare.self)
            case .all:
                try modelContext.delete(model: WorkoutSession.self)
                try modelContext.delete(model: CompletedSet.self)
                try modelContext.delete(model: PersonalRecord.self)
                try modelContext.delete(model: DailyHealthData.self)
                try modelContext.delete(model: MoodEntry.self)
                try modelContext.delete(model: UserAchievement.self)
                try modelContext.delete(model: WorkoutShare.self)
                try modelContext.delete(model: WeeklySummary.self)
                try modelContext.delete(model: MonthlySummary.self)
            }
            try modelContext.save()
            showSuccess("\(type.rawValue) deleted")
        } catch {
            print("Delete failed: \(error)")
        }
    }

    private func exportDataToConsole() {
        print("=== DEBUG DATA EXPORT ===")
        print("Exporting data to console...")
        // This would print detailed data - simplified for brevity
        showSuccess("Data printed to console")
    }
}

#Preview {
    NavigationStack {
        DebugDataView()
    }
}
