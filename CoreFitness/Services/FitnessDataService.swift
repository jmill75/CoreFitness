import Foundation
import SwiftData

/// Service for querying and aggregating fitness data for charts and recommendations
@MainActor
class FitnessDataService: ObservableObject {

    private var modelContext: ModelContext?

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Workout Queries

    /// Get workouts completed in a date range
    func getWorkouts(from startDate: Date, to endDate: Date) -> [WorkoutSession] {
        guard let context = modelContext else { return [] }

        let completedStatus = SessionStatus.completed.rawValue
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.startedAt >= startDate && session.startedAt <= endDate && session.status.rawValue == completedStatus
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get workout count by day for the last N days
    func getWorkoutsByDay(days: Int) -> [(date: Date, count: Int)] {
        guard let context = modelContext else { return [] }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let completedStatus = SessionStatus.completed.rawValue

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.startedAt >= startDate && session.status.rawValue == completedStatus
            }
        )

        guard let sessions = try? context.fetch(descriptor) else { return [] }

        // Group by day
        var dayCount: [Date: Int] = [:]
        for session in sessions {
            let day = Calendar.current.startOfDay(for: session.startedAt)
            dayCount[day, default: 0] += 1
        }

        return dayCount.map { ($0.key, $0.value) }.sorted { $0.date < $1.date }
    }

    // MARK: - PR Queries

    /// Get all PRs for an exercise
    func getPRHistory(for exerciseName: String) -> [PersonalRecord] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { pr in
                pr.exerciseName == exerciseName
            },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get recent PRs (last N days)
    func getRecentPRs(days: Int) -> [PersonalRecord] {
        guard let context = modelContext else { return [] }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { pr in
                pr.achievedAt >= startDate
            },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get current PR for an exercise
    func getCurrentPR(for exerciseName: String) -> PersonalRecord? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { pr in
                pr.exerciseName == exerciseName
            },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )

        return try? context.fetch(descriptor).first
    }

    // MARK: - Health Data Queries

    /// Get health data for a date range
    func getHealthData(from startDate: Date, to endDate: Date) -> [DailyHealthData] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= startDate && data.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get health data for today
    func getTodayHealthData() -> DailyHealthData? {
        let today = Calendar.current.startOfDay(for: Date())
        return getHealthData(for: today)
    }

    /// Get or create health data for a specific date
    func getOrCreateHealthData(for date: Date) -> DailyHealthData {
        let dayStart = Calendar.current.startOfDay(for: date)

        if let existing = getHealthData(for: dayStart) {
            return existing
        }

        let newData = DailyHealthData(date: dayStart)
        modelContext?.insert(newData)
        try? modelContext?.save()
        return newData
    }

    private func getHealthData(for date: Date) -> DailyHealthData? {
        guard let context = modelContext else { return nil }

        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!

        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= dayStart && data.date < dayEnd
            }
        )

        return try? context.fetch(descriptor).first
    }

    // MARK: - Mood Queries

    /// Get mood entries for a date range
    func getMoodEntries(from startDate: Date, to endDate: Date) -> [MoodEntry] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { entry in
                entry.date >= startDate && entry.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get mood breakdown (counts by mood type) for a date range
    func getMoodBreakdown(from startDate: Date, to endDate: Date) -> [Mood: Int] {
        let entries = getMoodEntries(from: startDate, to: endDate)
        var breakdown: [Mood: Int] = [:]
        for entry in entries {
            breakdown[entry.mood, default: 0] += 1
        }
        return breakdown
    }

    /// Get average mood score for a date range
    func getAverageMoodScore(from startDate: Date, to endDate: Date) -> Int {
        let entries = getMoodEntries(from: startDate, to: endDate)
        guard !entries.isEmpty else { return 0 }
        let totalScore = entries.reduce(0) { $0 + $1.mood.score }
        return totalScore / entries.count
    }

    // MARK: - Streak Queries

    /// Get or create the user's streak data
    func getOrCreateStreakData() -> StreakData {
        guard let context = modelContext else {
            return StreakData()
        }

        let descriptor = FetchDescriptor<StreakData>()

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let newStreak = StreakData()
        context.insert(newStreak)
        try? context.save()
        return newStreak
    }

    // MARK: - Achievement Queries

    /// Get all earned achievements
    func getEarnedAchievements() -> [UserAchievement] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<UserAchievement>(
            predicate: #Predicate { achievement in
                achievement.isComplete
            },
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get achievement progress for a specific achievement
    func getAchievementProgress(for achievementId: String) -> UserAchievement? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<UserAchievement>(
            predicate: #Predicate { achievement in
                achievement.achievementId == achievementId
            }
        )

        return try? context.fetch(descriptor).first
    }

    /// Update achievement progress
    func updateAchievementProgress(achievementId: String, progress: Int, requirement: Int) {
        guard let context = modelContext else { return }

        let existing = getAchievementProgress(for: achievementId)

        if let existing = existing {
            existing.progress = progress
            if progress >= requirement && !existing.isComplete {
                existing.isComplete = true
                existing.earnedAt = Date()
            }
        } else {
            let userAchievement = UserAchievement(
                achievementId: achievementId,
                progress: progress,
                isComplete: progress >= requirement
            )
            context.insert(userAchievement)
        }

        try? context.save()
    }

    // MARK: - Weekly/Monthly Summaries

    /// Get or create weekly summary
    func getOrCreateWeeklySummary(for date: Date) -> WeeklySummary {
        guard let context = modelContext else {
            return WeeklySummary(weekStartDate: date, weekEndDate: date)
        }

        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        let descriptor = FetchDescriptor<WeeklySummary>(
            predicate: #Predicate { summary in
                summary.weekStartDate == weekStart
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let newSummary = WeeklySummary(weekStartDate: weekStart, weekEndDate: weekEnd)
        context.insert(newSummary)
        try? context.save()
        return newSummary
    }

    /// Calculate and update weekly summary
    func updateWeeklySummary(for date: Date) {
        let summary = getOrCreateWeeklySummary(for: date)
        let workouts = getWorkouts(from: summary.weekStartDate, to: summary.weekEndDate)

        summary.workoutsCompleted = workouts.count
        summary.totalWorkoutMinutes = workouts.compactMap { $0.totalDuration }.reduce(0, +) / 60

        // Count unique workout days
        let workoutDays = Set(workouts.map { Calendar.current.startOfDay(for: $0.startedAt) })
        summary.workoutDays = workoutDays.count

        // Count PRs
        let prs = getRecentPRs(days: 7).filter {
            $0.achievedAt >= summary.weekStartDate && $0.achievedAt <= summary.weekEndDate
        }
        summary.prsAchieved = prs.count

        // Health data aggregation
        let healthData = getHealthData(from: summary.weekStartDate, to: summary.weekEndDate)
        summary.totalSteps = healthData.compactMap { $0.steps }.reduce(0, +)
        summary.averageDailySteps = healthData.isEmpty ? 0 : summary.totalSteps / healthData.count
        summary.totalActiveCalories = healthData.compactMap { $0.activeCalories }.reduce(0, +)

        let sleepData = healthData.compactMap { $0.sleepDuration }
        summary.averageSleepMinutes = sleepData.isEmpty ? 0 : sleepData.reduce(0, +) / sleepData.count

        let moodScore = getAverageMoodScore(from: summary.weekStartDate, to: summary.weekEndDate)
        summary.averageMoodScore = moodScore

        let recoveryScores = healthData.compactMap { $0.recoveryScore }
        summary.averageRecoveryScore = recoveryScores.isEmpty ? 0 : recoveryScores.reduce(0, +) / recoveryScores.count

        try? modelContext?.save()
    }

    // MARK: - Chart Data Helpers

    /// Get steps data for charting (last N days)
    func getStepsChartData(days: Int) -> [(date: Date, steps: Int)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let healthData = getHealthData(from: startDate, to: Date())

        return healthData.compactMap { data in
            guard let steps = data.steps else { return nil }
            return (data.date, steps)
        }
    }

    /// Get water intake data for charting (last N days)
    func getWaterChartData(days: Int) -> [(date: Date, intake: Double, goal: Double)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let healthData = getHealthData(from: startDate, to: Date())

        return healthData.compactMap { data in
            guard let intake = data.waterIntake else { return nil }
            return (data.date, intake, data.waterGoal ?? 64)
        }
    }

    /// Get sleep data for charting (last N days)
    func getSleepChartData(days: Int) -> [(date: Date, minutes: Int)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let healthData = getHealthData(from: startDate, to: Date())

        return healthData.compactMap { data in
            guard let sleep = data.sleepDuration else { return nil }
            return (data.date, sleep)
        }
    }

    /// Get weight progression for an exercise (for PR chart)
    func getExerciseProgressionData(exerciseName: String) -> [(date: Date, weight: Double)] {
        let prs = getPRHistory(for: exerciseName)
        return prs.map { ($0.achievedAt, $0.weight) }.reversed()
    }

    // MARK: - Recommendations

    /// Generate workout recommendations based on history
    func getWorkoutRecommendations() -> [WorkoutRecommendation] {
        var recommendations: [WorkoutRecommendation] = []

        // Check streak
        let streak = getOrCreateStreakData()
        if let lastWorkout = streak.lastWorkoutDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastWorkout, to: Date()).day ?? 0
            if daysSince >= 2 {
                recommendations.append(WorkoutRecommendation(
                    type: .streak,
                    title: "Keep Your Streak Alive!",
                    message: "It's been \(daysSince) days since your last workout. Don't let your \(streak.currentStreak)-day streak end!",
                    priority: .high
                ))
            }
        }

        // Check weekly goal progress
        let weeklySummary = getOrCreateWeeklySummary(for: Date())
        if weeklySummary.workoutsCompleted < streak.weeklyGoal {
            let remaining = streak.weeklyGoal - weeklySummary.workoutsCompleted
            recommendations.append(WorkoutRecommendation(
                type: .goal,
                title: "Weekly Goal Check",
                message: "You need \(remaining) more workout\(remaining == 1 ? "" : "s") to hit your weekly goal!",
                priority: .medium
            ))
        }

        // Check if ready for PR attempt
        let recentPRs = getRecentPRs(days: 30)
        if recentPRs.isEmpty {
            recommendations.append(WorkoutRecommendation(
                type: .pr,
                title: "Time for a PR?",
                message: "You haven't set a personal record in 30 days. Challenge yourself today!",
                priority: .low
            ))
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - Recommendation Model

struct WorkoutRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let message: String
    let priority: RecommendationPriority

    enum RecommendationType {
        case streak, goal, pr, recovery, rest
    }

    enum RecommendationPriority: Int {
        case low = 1, medium = 2, high = 3
    }
}
