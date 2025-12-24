import Foundation
import SwiftData

// ============================================
// MARK: - Personal Record (PR) Tracking
// ============================================

/// Tracks personal records for each exercise
@Model
final class PersonalRecord {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var weight: Double // in lbs
    var reps: Int
    var achievedAt: Date
    var previousWeight: Double? // for tracking progression
    var sessionId: UUID? // link to the session where PR was achieved

    init(
        id: UUID = UUID(),
        exerciseName: String,
        weight: Double,
        reps: Int,
        previousWeight: Double? = nil,
        sessionId: UUID? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.achievedAt = Date()
        self.previousWeight = previousWeight
        self.sessionId = sessionId
    }

    /// Calculate improvement percentage
    var improvementPercentage: Double? {
        guard let previous = previousWeight, previous > 0 else { return nil }
        return ((weight - previous) / previous) * 100
    }
}

// ============================================
// MARK: - Daily Health Metrics
// ============================================

/// Stores daily health and wellness data from HealthKit and manual entries
@Model
final class DailyHealthData {
    @Attribute(.unique) var id: UUID
    var date: Date // Date component only, time stripped

    // Activity
    var steps: Int?
    var activeCalories: Int?
    var totalCalories: Int?
    var exerciseMinutes: Int?
    var standHours: Int?
    var distanceWalked: Double? // in miles

    // Heart
    var restingHeartRate: Int?
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var heartRateVariability: Double? // HRV in ms

    // Sleep
    var sleepDuration: Int? // minutes
    var sleepQuality: SleepQuality?
    var bedtime: Date?
    var wakeTime: Date?
    var deepSleepMinutes: Int?
    var remSleepMinutes: Int?

    // Recovery & Wellness
    var recoveryScore: Int? // 0-100
    var stressLevel: Int? // 1-10
    var energyLevel: Int? // 1-10
    var bloodOxygen: Double? // SpO2 percentage

    // Hydration
    var waterIntake: Double? // in oz
    var waterGoal: Double? // in oz

    // Body Measurements
    var weight: Double? // in lbs
    var bodyFatPercentage: Double?

    // Workout Summary
    var workoutsCompleted: Int?
    var totalWorkoutMinutes: Int?
    var totalVolumeLifted: Double? // total lbs lifted

    // Computed overall score
    var overallScore: Int? // 0-100, computed from multiple factors

    init(
        id: UUID = UUID(),
        date: Date
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
    }

    /// Calculate overall score based on available metrics
    func calculateOverallScore() -> Int {
        var score = 0
        var factors = 0

        // Sleep score (0-25 points)
        if let sleep = sleepDuration {
            let sleepHours = Double(sleep) / 60.0
            let sleepScore = min(25, Int((sleepHours / 8.0) * 25))
            score += sleepScore
            factors += 1
        }

        // Activity score (0-25 points)
        if let steps = steps {
            let stepsScore = min(25, Int((Double(steps) / 10000.0) * 25))
            score += stepsScore
            factors += 1
        }

        // Recovery score (0-25 points)
        if let recovery = recoveryScore {
            score += min(25, recovery / 4)
            factors += 1
        }

        // Hydration score (0-25 points)
        if let water = waterIntake, let goal = waterGoal, goal > 0 {
            let hydrationScore = min(25, Int((water / goal) * 25))
            score += hydrationScore
            factors += 1
        }

        return factors > 0 ? score : 0
    }
}

enum SleepQuality: String, Codable, CaseIterable {
    case poor, fair, good, excellent

    var displayName: String { rawValue.capitalized }

    var score: Int {
        switch self {
        case .poor: return 25
        case .fair: return 50
        case .good: return 75
        case .excellent: return 100
        }
    }
}

// ============================================
// MARK: - Mood Tracking
// ============================================

/// Tracks daily mood entries
@Model
final class MoodEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mood: Mood
    var energyLevel: Int? // 1-10
    var stressLevel: Int? // 1-10
    var notes: String?
    var tags: [String]? // e.g., ["tired", "motivated", "stressed"]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Mood,
        energyLevel: Int? = nil,
        stressLevel: Int? = nil,
        notes: String? = nil,
        tags: [String]? = nil
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.energyLevel = energyLevel
        self.stressLevel = stressLevel
        self.notes = notes
        self.tags = tags
    }
}

enum Mood: String, Codable, CaseIterable {
    case amazing, good, okay, tired, stressed

    var emoji: String {
        switch self {
        case .amazing: return "amazing"
        case .good: return "good"
        case .okay: return "okay"
        case .tired: return "tired"
        case .stressed: return "stressed"
        }
    }

    var displayName: String { rawValue.capitalized }

    var score: Int {
        switch self {
        case .amazing: return 100
        case .good: return 75
        case .okay: return 50
        case .tired: return 35
        case .stressed: return 25
        }
    }

    var color: String {
        switch self {
        case .amazing: return "accentGreen"
        case .good: return "accentBlue"
        case .okay: return "accentYellow"
        case .tired: return "accentOrange"
        case .stressed: return "accentRed"
        }
    }
}

// ============================================
// MARK: - Streak Tracking
// ============================================

/// Tracks workout streaks and consistency
@Model
final class StreakData {
    @Attribute(.unique) var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastWorkoutDate: Date?
    var totalWorkoutDays: Int
    var weeklyGoal: Int // workouts per week target
    var currentWeekWorkouts: Int

    // Streak history
    var streakStartDate: Date?
    var streakBrokenDates: [Date]?

    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalWorkoutDays: Int = 0,
        weeklyGoal: Int = 4,
        currentWeekWorkouts: Int = 0
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalWorkoutDays = totalWorkoutDays
        self.weeklyGoal = weeklyGoal
        self.currentWeekWorkouts = currentWeekWorkouts
    }

    /// Update streak after completing a workout
    func recordWorkout(on date: Date = Date()) {
        let today = Calendar.current.startOfDay(for: date)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        if let lastWorkout = lastWorkoutDate {
            let lastWorkoutDay = Calendar.current.startOfDay(for: lastWorkout)

            if lastWorkoutDay == today {
                // Already worked out today, no change to streak
                return
            } else if lastWorkoutDay == yesterday {
                // Consecutive day, increment streak
                currentStreak += 1
            } else {
                // Streak broken
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
                if streakBrokenDates == nil {
                    streakBrokenDates = []
                }
                streakBrokenDates?.append(lastWorkoutDay)
                currentStreak = 1
                streakStartDate = today
            }
        } else {
            // First workout
            currentStreak = 1
            streakStartDate = today
        }

        lastWorkoutDate = today
        totalWorkoutDays += 1

        // Update weekly count
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        if let lastWorkout = lastWorkoutDate,
           Calendar.current.isDate(lastWorkout, equalTo: weekStart, toGranularity: .weekOfYear) == false {
            currentWeekWorkouts = 1
        } else {
            currentWeekWorkouts += 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }
}

// ============================================
// MARK: - Achievements System
// ============================================

/// Defines available achievements/badges
@Model
final class Achievement {
    @Attribute(.unique) var id: String // e.g., "first_workout", "7_day_streak"
    var name: String
    var achievementDescription: String
    var category: AchievementCategory
    var iconName: String // SF Symbol or custom
    var emoji: String
    var requirement: Int // The number needed to unlock
    var points: Int // Gamification points
    var isSecret: Bool // Hidden until unlocked

    init(
        id: String,
        name: String,
        description: String,
        category: AchievementCategory,
        iconName: String,
        emoji: String,
        requirement: Int,
        points: Int = 10,
        isSecret: Bool = false
    ) {
        self.id = id
        self.name = name
        self.achievementDescription = description
        self.category = category
        self.iconName = iconName
        self.emoji = emoji
        self.requirement = requirement
        self.points = points
        self.isSecret = isSecret
    }
}

/// Tracks user's earned achievements
@Model
final class UserAchievement {
    @Attribute(.unique) var id: UUID
    var achievementId: String
    var earnedAt: Date
    var progress: Int // Current progress toward achievement
    var isComplete: Bool
    var notified: Bool // Whether user was shown notification

    init(
        id: UUID = UUID(),
        achievementId: String,
        progress: Int = 0,
        isComplete: Bool = false
    ) {
        self.id = id
        self.achievementId = achievementId
        self.earnedAt = Date()
        self.progress = progress
        self.isComplete = isComplete
        self.notified = false
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case workout // Workout-related achievements
    case streak // Consistency achievements
    case strength // PR and weight achievements
    case social // Sharing and community
    case milestone // Total workouts, days, etc.
    case challenge // Special challenges

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .workout: return "figure.strengthtraining.traditional"
        case .streak: return "flame.fill"
        case .strength: return "trophy.fill"
        case .social: return "person.2.fill"
        case .milestone: return "flag.checkered"
        case .challenge: return "star.fill"
        }
    }
}

// ============================================
// MARK: - Social Sharing
// ============================================

/// Represents a shared workout post
@Model
final class WorkoutShare {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var sharedAt: Date
    var platform: SharePlatform
    var caption: String?
    var imageData: Data? // Workout summary image

    // Workout summary data (denormalized for historical record)
    var workoutName: String
    var duration: Int // seconds
    var exerciseCount: Int
    var totalSets: Int
    var totalVolume: Double // total weight lifted

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        platform: SharePlatform,
        workoutName: String,
        duration: Int,
        exerciseCount: Int,
        totalSets: Int,
        totalVolume: Double,
        caption: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.sharedAt = Date()
        self.platform = platform
        self.workoutName = workoutName
        self.duration = duration
        self.exerciseCount = exerciseCount
        self.totalSets = totalSets
        self.totalVolume = totalVolume
        self.caption = caption
    }
}

enum SharePlatform: String, Codable, CaseIterable {
    case instagram, twitter, facebook, messages, copy, other

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .twitter: return "X (Twitter)"
        case .facebook: return "Facebook"
        case .messages: return "Messages"
        case .copy: return "Copy Link"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .twitter: return "bubble.left.fill"
        case .facebook: return "person.2.fill"
        case .messages: return "message.fill"
        case .copy: return "doc.on.doc.fill"
        case .other: return "square.and.arrow.up"
        }
    }
}

// ============================================
// MARK: - Weekly/Monthly Summaries
// ============================================

/// Stores aggregated weekly fitness data
@Model
final class WeeklySummary {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date

    // Workout Stats
    var workoutsCompleted: Int
    var totalWorkoutMinutes: Int
    var totalExercises: Int
    var totalSets: Int
    var totalReps: Int
    var totalVolumeLifted: Double

    // PRs achieved this week
    var prsAchieved: Int

    // Activity
    var totalSteps: Int
    var averageDailySteps: Int
    var totalActiveCalories: Int

    // Wellness
    var averageSleepMinutes: Int
    var averageMoodScore: Int
    var averageRecoveryScore: Int

    // Streak info
    var workoutDays: Int // Days with at least one workout

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.workoutsCompleted = 0
        self.totalWorkoutMinutes = 0
        self.totalExercises = 0
        self.totalSets = 0
        self.totalReps = 0
        self.totalVolumeLifted = 0
        self.prsAchieved = 0
        self.totalSteps = 0
        self.averageDailySteps = 0
        self.totalActiveCalories = 0
        self.averageSleepMinutes = 0
        self.averageMoodScore = 0
        self.averageRecoveryScore = 0
        self.workoutDays = 0
    }
}

/// Stores aggregated monthly fitness data
@Model
final class MonthlySummary {
    @Attribute(.unique) var id: UUID
    var month: Int // 1-12
    var year: Int

    // Workout Stats
    var workoutsCompleted: Int
    var totalWorkoutMinutes: Int
    var totalVolumeLifted: Double
    var prsAchieved: Int

    // Best week
    var bestWeekWorkouts: Int
    var bestWeekVolume: Double

    // Activity
    var totalSteps: Int
    var totalActiveCalories: Int

    // Wellness averages
    var averageSleepMinutes: Int
    var averageMoodScore: Int
    var averageRecoveryScore: Int

    // Streaks
    var longestStreakThisMonth: Int
    var totalWorkoutDays: Int

    init(
        id: UUID = UUID(),
        month: Int,
        year: Int
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.workoutsCompleted = 0
        self.totalWorkoutMinutes = 0
        self.totalVolumeLifted = 0
        self.prsAchieved = 0
        self.bestWeekWorkouts = 0
        self.bestWeekVolume = 0
        self.totalSteps = 0
        self.totalActiveCalories = 0
        self.averageSleepMinutes = 0
        self.averageMoodScore = 0
        self.averageRecoveryScore = 0
        self.longestStreakThisMonth = 0
        self.totalWorkoutDays = 0
    }
}

// ============================================
// MARK: - User Settings & Profile
// ============================================

/// User profile and settings
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String?
    var email: String?
    var avatarData: Data?
    var createdAt: Date

    // Goals
    var weeklyWorkoutGoal: Int
    var dailyStepsGoal: Int
    var dailyWaterGoal: Double // oz
    var targetWeight: Double? // lbs
    var targetBodyFat: Double?

    // Preferences
    var useMetricSystem: Bool
    var notificationsEnabled: Bool
    var workoutReminderTime: Date?
    var restTimerDuration: Int // default rest between sets
    var showHeartRateZones: Bool

    // Stats
    var totalWorkoutsCompleted: Int
    var totalMinutesWorkedOut: Int
    var memberSince: Date

    init(
        id: UUID = UUID(),
        displayName: String? = nil,
        weeklyWorkoutGoal: Int = 4,
        dailyStepsGoal: Int = 10000,
        dailyWaterGoal: Double = 64,
        useMetricSystem: Bool = false,
        notificationsEnabled: Bool = true,
        restTimerDuration: Int = 90
    ) {
        self.id = id
        self.displayName = displayName
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.dailyStepsGoal = dailyStepsGoal
        self.dailyWaterGoal = dailyWaterGoal
        self.useMetricSystem = useMetricSystem
        self.notificationsEnabled = notificationsEnabled
        self.restTimerDuration = restTimerDuration
        self.showHeartRateZones = true
        self.totalWorkoutsCompleted = 0
        self.totalMinutesWorkedOut = 0
        self.createdAt = Date()
        self.memberSince = Date()
    }
}
