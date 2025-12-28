import Foundation
import SwiftData

// MARK: - Entry Source Enum
enum EntrySource: String, Codable {
    case manual = "Manual Entry"
    case timer = "In-App Timer"
    case healthkit = "My Health Data"

    var icon: String {
        switch self {
        case .manual: return "square.and.pencil"
        case .timer: return "timer"
        case .healthkit: return "heart.fill"
        }
    }
}

// MARK: - Distance Unit Enum
enum DistanceUnit: String, Codable, CaseIterable {
    case miles = "Miles"
    case kilometers = "Kilometers"
    case meters = "Meters"

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        case .meters: return "m"
        }
    }
}

// MARK: - Challenge Model
@Model
final class Challenge {
    var id: UUID = UUID()
    var name: String = ""
    var challengeDescription: String = ""
    var durationDays: Int = 30
    var startDate: Date = Date()
    var endDate: Date = Date()
    var goalTypeRaw: String = ChallengeGoalType.fitness.rawValue  // Stored as raw string
    var locationRaw: String = ChallengeLocation.anywhere.rawValue  // Stored as raw string
    var creatorId: String = ""
    var inviteCode: String = ""
    var isActive: Bool = true
    var createdAt: Date = Date()

    // Shutdown/cancellation fields
    var isShutdown: Bool = false
    var shutdownDate: Date?
    var shutdownReason: String?
    var shutdownByUserId: String?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ChallengeParticipant.challenge)
    var participants: [ChallengeParticipant]?

    // Computed properties for enums
    var goalType: ChallengeGoalType {
        get { ChallengeGoalType(rawValue: goalTypeRaw) ?? .fitness }
        set { goalTypeRaw = newValue.rawValue }
    }

    var location: ChallengeLocation {
        get { ChallengeLocation(rawValue: locationRaw) ?? .anywhere }
        set { locationRaw = newValue.rawValue }
    }

    var sortedParticipants: [ChallengeParticipant] {
        participants?.sorted { $0.completedDays > $1.completedDays } ?? []
    }

    var currentDay: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(max(days + 1, 1), durationDays)
    }

    var daysRemaining: Int {
        max(0, durationDays - currentDay + 1)
    }

    var progress: Double {
        Double(currentDay - 1) / Double(durationDays)
    }

    var isCompleted: Bool {
        Date() > endDate
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        durationDays: Int = 30,
        startDate: Date = Date(),
        goalType: ChallengeGoalType = .fitness,
        location: ChallengeLocation = .anywhere,
        creatorId: String
    ) {
        self.id = id
        self.name = name
        self.challengeDescription = description
        self.durationDays = durationDays
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
        self.goalTypeRaw = goalType.rawValue
        self.locationRaw = location.rawValue
        self.creatorId = creatorId
        self.inviteCode = Challenge.generateInviteCode()
        self.isActive = true
        self.createdAt = Date()
    }

    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

// MARK: - Challenge Participant
@Model
final class ChallengeParticipant {
    var id: UUID = UUID()
    var ownerId: String = ""
    var displayName: String = ""
    var avatarEmoji: String = "😀"
    var joinedAt: Date = Date()
    var completedDays: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var isOwner: Bool = false

    // Aggregate stats (optional for migration compatibility)
    var totalDistanceMiles: Double?
    var totalDurationSeconds: Int?
    var totalWeightLifted: Double?
    var totalCaloriesBurned: Int?
    var averageHeartRate: Int?
    var prsAchieved: Int?
    var currentWeightLoss: Double?

    // Sync properties (optional for migration compatibility)
    var lastSyncedAt: Date?
    var cloudKitRecordID: String?
    var needsSync: Bool?

    // Relationships
    var challenge: Challenge?

    @Relationship(deleteRule: .cascade, inverse: \ChallengeDayLog.participant)
    var dayLogs: [ChallengeDayLog]?

    @Relationship(deleteRule: .cascade, inverse: \ChallengeWeeklySummary.participant)
    var weeklySummaries: [ChallengeWeeklySummary]?

    var completionPercentage: Double {
        guard let challenge = challenge else { return 0 }
        return Double(completedDays) / Double(challenge.durationDays)
    }

    var formattedTotalDistance: String {
        String(format: "%.1f mi", totalDistanceMiles ?? 0)
    }

    var formattedTotalDuration: String {
        let seconds = totalDurationSeconds ?? 0
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedTotalWeight: String {
        let weight = totalWeightLifted ?? 0
        if weight >= 1000 {
            return String(format: "%.1fK lbs", weight / 1000)
        }
        return String(format: "%.0f lbs", weight)
    }

    init(
        id: UUID = UUID(),
        ownerId: String,
        displayName: String,
        avatarEmoji: String = "😀",
        isOwner: Bool = false
    ) {
        self.id = id
        self.ownerId = ownerId
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.joinedAt = Date()
        self.completedDays = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.isOwner = isOwner
        self.totalDistanceMiles = 0
        self.totalDurationSeconds = 0
        self.totalWeightLifted = 0
        self.totalCaloriesBurned = 0
        self.prsAchieved = 0
        self.needsSync = false
    }

    func logDay(day: Int, completed: Bool, activityData: ChallengeActivityData? = nil) {
        if completed {
            completedDays += 1
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)

            // Update aggregates from activity data
            if let data = activityData {
                totalDistanceMiles = (totalDistanceMiles ?? 0) + data.distanceInMiles
                totalDurationSeconds = (totalDurationSeconds ?? 0) + (data.durationSeconds ?? 0)
                totalWeightLifted = (totalWeightLifted ?? 0) + (data.totalWeightLifted ?? 0)
                totalCaloriesBurned = (totalCaloriesBurned ?? 0) + (data.caloriesBurned ?? 0)
                if data.isPR == true {
                    prsAchieved = (prsAchieved ?? 0) + 1
                }
            }

            needsSync = true
        } else {
            currentStreak = 0
        }
    }

    func recalculateAggregates() {
        totalDistanceMiles = 0
        totalDurationSeconds = 0
        totalWeightLifted = 0
        totalCaloriesBurned = 0
        prsAchieved = 0

        guard let logs = dayLogs else { return }
        for log in logs where log.isCompleted {
            if let data = log.activityData {
                totalDistanceMiles = (totalDistanceMiles ?? 0) + data.distanceInMiles
                totalDurationSeconds = (totalDurationSeconds ?? 0) + (data.durationSeconds ?? 0)
                totalWeightLifted = (totalWeightLifted ?? 0) + (data.totalWeightLifted ?? 0)
                totalCaloriesBurned = (totalCaloriesBurned ?? 0) + (data.caloriesBurned ?? 0)
                if data.isPR == true {
                    prsAchieved = (prsAchieved ?? 0) + 1
                }
            }
        }
        needsSync = true
    }
}

// MARK: - Challenge Day Log
@Model
final class ChallengeDayLog {
    var id: UUID = UUID()
    var dayNumber: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?
    var notes: String?

    // Entry tracking (stored as raw string for compatibility)
    var entrySourceRaw: String?
    var entryTimestamp: Date?

    // Photo attachments (stored as Data for SwiftData compatibility)
    var photoData: [Data]?

    // Relationships
    var participant: ChallengeParticipant?

    @Relationship(deleteRule: .cascade, inverse: \ChallengeActivityData.dayLog)
    var activityData: ChallengeActivityData?

    // Computed property for EntrySource
    var entrySource: EntrySource? {
        get { entrySourceRaw.flatMap { EntrySource(rawValue: $0) } }
        set { entrySourceRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        isCompleted: Bool = false,
        entrySource: EntrySource? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.isCompleted = isCompleted
        self.completedAt = isCompleted ? Date() : nil
        self.entrySourceRaw = entrySource?.rawValue
        self.entryTimestamp = isCompleted ? Date() : nil
    }
}

// MARK: - Challenge Activity Data
@Model
final class ChallengeActivityData {
    var id: UUID = UUID()

    // Cardio stats
    var startTime: Date?
    var endTime: Date?
    var durationSeconds: Int?
    var distanceValue: Double?
    var distanceUnitRaw: String?  // Stored as raw string for SwiftData compatibility
    var averagePaceSecondsPerMile: Int?
    var caloriesBurned: Int?

    // Strength stats
    var totalWeightLifted: Double?
    var totalSets: Int?
    var totalReps: Int?
    var exercisesCompleted: Int?
    var isPR: Bool?

    // Endurance stats
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    // Heart rate zone minutes stored as individual properties for SwiftData compatibility
    var heartRateZone1Minutes: Int?
    var heartRateZone2Minutes: Int?
    var heartRateZone3Minutes: Int?
    var heartRateZone4Minutes: Int?
    var heartRateZone5Minutes: Int?

    // Wellness stats
    var meditationMinutes: Int?
    var sleepHours: Double?
    var stressLevel: Int? // 1-10
    var hydrationOz: Double?

    // Weight Loss stats
    var currentWeight: Double?
    var targetWeight: Double?
    var bodyFatPercentage: Double?

    // Relationships
    var dayLog: ChallengeDayLog?

    @Relationship(deleteRule: .cascade, inverse: \ChallengeStrengthSet.activityData)
    var strengthSets: [ChallengeStrengthSet]?

    // Computed property for DistanceUnit
    var distanceUnit: DistanceUnit? {
        get { distanceUnitRaw.flatMap { DistanceUnit(rawValue: $0) } }
        set { distanceUnitRaw = newValue?.rawValue }
    }

    // Computed property for heart rate zone minutes array
    var heartRateZoneMinutes: [Int] {
        get {
            [
                heartRateZone1Minutes ?? 0,
                heartRateZone2Minutes ?? 0,
                heartRateZone3Minutes ?? 0,
                heartRateZone4Minutes ?? 0,
                heartRateZone5Minutes ?? 0
            ]
        }
        set {
            if newValue.count >= 1 { heartRateZone1Minutes = newValue[0] }
            if newValue.count >= 2 { heartRateZone2Minutes = newValue[1] }
            if newValue.count >= 3 { heartRateZone3Minutes = newValue[2] }
            if newValue.count >= 4 { heartRateZone4Minutes = newValue[3] }
            if newValue.count >= 5 { heartRateZone5Minutes = newValue[4] }
        }
    }

    // Computed properties
    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "--:--" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    var formattedPace: String {
        guard let pace = averagePaceSecondsPerMile else { return "--:--" }
        let minutes = pace / 60
        let seconds = pace % 60
        return String(format: "%d:%02d /mi", minutes, seconds)
    }

    var distanceInMiles: Double {
        guard let value = distanceValue, let unit = distanceUnit else { return 0 }
        switch unit {
        case .miles: return value
        case .kilometers: return value * 0.621371
        case .meters: return value * 0.000621371
        }
    }

    init(id: UUID = UUID()) {
        self.id = id
    }
}

// MARK: - Challenge Strength Set
@Model
final class ChallengeStrengthSet {
    var id: UUID = UUID()
    var exerciseName: String = ""
    var setNumber: Int = 1
    var reps: Int = 0
    var weight: Double = 0
    var isPR: Bool = false
    var completedAt: Date = Date()

    // Relationships
    var activityData: ChallengeActivityData?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        setNumber: Int,
        reps: Int,
        weight: Double,
        isPR: Bool = false
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isPR = isPR
        self.completedAt = Date()
    }
}

// MARK: - Challenge Weekly Summary
@Model
final class ChallengeWeeklySummary {
    var id: UUID = UUID()
    var weekNumber: Int = 1
    var startDate: Date = Date()
    var endDate: Date = Date()
    var completedDays: Int = 0
    var totalDurationSeconds: Int = 0
    var totalDistanceMiles: Double = 0
    var totalWeightLifted: Double = 0
    var totalCaloriesBurned: Int = 0
    var averageHeartRate: Int?

    // Relationships
    var participant: ChallengeParticipant?

    var formattedTotalDuration: String {
        let hours = totalDurationSeconds / 3600
        let minutes = (totalDurationSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    init(
        id: UUID = UUID(),
        weekNumber: Int,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.completedDays = 0
        self.totalDurationSeconds = 0
        self.totalDistanceMiles = 0
        self.totalWeightLifted = 0
        self.totalCaloriesBurned = 0
    }
}

// MARK: - Enums

enum ChallengeGoalType: String, Codable, CaseIterable {
    case fitness = "Fitness"
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case weightLoss = "Weight Loss"
    case muscle = "Build Muscle"
    case endurance = "Endurance"
    case wellness = "Wellness"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .fitness: return "figure.run"
        case .strength: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.yoga"
        case .weightLoss: return "scalemass.fill"
        case .muscle: return "dumbbell.fill"
        case .endurance: return "timer"
        case .wellness: return "leaf.fill"
        }
    }

    var color: String {
        switch self {
        case .fitness: return "accentBlue"
        case .strength: return "accentOrange"
        case .cardio: return "accentRed"
        case .flexibility: return "purple"
        case .weightLoss: return "accentGreen"
        case .muscle: return "accentOrange"
        case .endurance: return "accentYellow"
        case .wellness: return "accentTeal"
        }
    }
}

enum ChallengeLocation: String, Codable, CaseIterable {
    case home = "Home"
    case gym = "Gym"
    case outdoor = "Outdoor"
    case anywhere = "Anywhere"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .gym: return "dumbbell.fill"
        case .outdoor: return "sun.max.fill"
        case .anywhere: return "mappin.and.ellipse"
        }
    }
}

// MARK: - Challenge Configuration
struct ChallengeConfiguration {
    let dailyRequirements: [String]
    let weeklyGoals: [String]
    let metricsToTrack: [ChallengeMetric]
    let checkInInstructions: String
    let successCriteria: String
    let tips: [String]
}

enum ChallengeMetric: String, Codable {
    case distance = "Distance"
    case duration = "Duration"
    case calories = "Calories"
    case heartRate = "Heart Rate"
    case weight = "Weight"
    case bodyWeight = "Body Weight"
    case reps = "Reps"
    case sets = "Sets"
    case sleepHours = "Sleep Hours"
    case waterIntake = "Water Intake"
    case meditation = "Meditation"
    case steps = "Steps"
    case photos = "Progress Photos"

    var icon: String {
        switch self {
        case .distance: return "figure.run"
        case .duration: return "clock.fill"
        case .calories: return "flame.fill"
        case .heartRate: return "heart.fill"
        case .weight: return "dumbbell.fill"
        case .bodyWeight: return "scalemass.fill"
        case .reps: return "repeat"
        case .sets: return "number"
        case .sleepHours: return "moon.fill"
        case .waterIntake: return "drop.fill"
        case .meditation: return "brain.head.profile"
        case .steps: return "figure.walk"
        case .photos: return "camera.fill"
        }
    }
}

// MARK: - Challenge Templates
struct ChallengeTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let durationDays: Int
    let goalType: ChallengeGoalType
    let location: ChallengeLocation
    let difficulty: Difficulty
    let icon: String
    let configuration: ChallengeConfiguration

    static let templates: [ChallengeTemplate] = [
        // MARK: - Cardio Challenges
        ChallengeTemplate(
            name: "7-Day Cardio Kickstart",
            description: "Jump-start your cardio fitness with daily 20-minute sessions. Perfect for building the exercise habit.",
            durationDays: 7,
            goalType: .cardio,
            location: .anywhere,
            difficulty: .beginner,
            icon: "heart.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete 20+ minutes of cardio activity",
                    "Log your distance or time",
                    "Check in before 8 PM"
                ],
                weeklyGoals: [
                    "Complete all 7 days",
                    "Total 2+ hours of cardio",
                    "Track heart rate in at least 3 sessions"
                ],
                metricsToTrack: [.duration, .distance, .heartRate, .calories],
                checkInInstructions: "After your cardio session, log your time, distance (if applicable), and how you felt. Use the timer feature for accurate tracking.",
                successCriteria: "Complete cardio activity and check in daily. Missing a day breaks your streak!",
                tips: [
                    "Start with walking if running is too intense",
                    "Morning workouts help build consistency",
                    "Stay hydrated before and after"
                ]
            )
        ),
        ChallengeTemplate(
            name: "14-Day HIIT Sprint",
            description: "Intense high-intensity intervals. Burn maximum calories and boost metabolism with short, powerful workouts.",
            durationDays: 14,
            goalType: .cardio,
            location: .anywhere,
            difficulty: .advanced,
            icon: "bolt.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete 15-30 minute HIIT session",
                    "Reach target heart rate zone (80%+ max)",
                    "Log calories burned"
                ],
                weeklyGoals: [
                    "Complete 6 out of 7 days minimum",
                    "Burn 2000+ calories total",
                    "Improve recovery time between intervals"
                ],
                metricsToTrack: [.duration, .heartRate, .calories],
                checkInInstructions: "Complete your HIIT workout and log the duration, peak heart rate, and estimated calories. Rate your effort level.",
                successCriteria: "Push yourself with high-intensity effort. Track your heart rate to ensure you're reaching training zones.",
                tips: [
                    "Rest days are important for recovery",
                    "Warm up properly before intense intervals",
                    "Listen to your body - scale back if needed"
                ]
            )
        ),
        ChallengeTemplate(
            name: "30-Day Running Challenge",
            description: "Build endurance and distance over 30 days. Start at your level and progressively increase weekly mileage.",
            durationDays: 30,
            goalType: .cardio,
            location: .outdoor,
            difficulty: .intermediate,
            icon: "figure.run",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Run or jog (distance varies by week)",
                    "Week 1: 1-2 miles, Week 4: 3-4 miles",
                    "Log distance, time, and pace"
                ],
                weeklyGoals: [
                    "Week 1: 8 miles total",
                    "Week 2: 12 miles total",
                    "Week 3: 15 miles total",
                    "Week 4: 18 miles total"
                ],
                metricsToTrack: [.distance, .duration, .heartRate, .steps],
                checkInInstructions: "After each run, log your distance, time, and average pace. Note how you felt and any observations about your progress.",
                successCriteria: "Complete the daily mileage and progressively increase your weekly totals. Rest days are built in.",
                tips: [
                    "Invest in good running shoes",
                    "Vary your routes to stay motivated",
                    "Include one long slow run per week"
                ]
            )
        ),

        // MARK: - Strength Challenges
        ChallengeTemplate(
            name: "21-Day Core Challenge",
            description: "Sculpt and strengthen your core with daily targeted exercises. Build a strong foundation for all movement.",
            durationDays: 21,
            goalType: .strength,
            location: .home,
            difficulty: .beginner,
            icon: "figure.core.training",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete 10-15 minute core workout",
                    "Perform at least 4 different exercises",
                    "Hold planks for cumulative 2+ minutes"
                ],
                weeklyGoals: [
                    "Complete all 7 days each week",
                    "Increase plank hold time weekly",
                    "Add exercise variations as you progress"
                ],
                metricsToTrack: [.duration, .reps, .sets],
                checkInInstructions: "Log each core exercise with reps completed. Track your longest plank hold. Note any exercises that felt challenging.",
                successCriteria: "Complete daily core workout focusing on form over speed. Aim for progressive improvement in hold times.",
                tips: [
                    "Focus on form, not speed",
                    "Breathe steadily during exercises",
                    "Engage your core throughout the day"
                ]
            )
        ),
        ChallengeTemplate(
            name: "21-Day Strength Builder",
            description: "Progressive resistance training to build muscle and increase strength. Perfect for gym-goers ready to level up.",
            durationDays: 21,
            goalType: .muscle,
            location: .gym,
            difficulty: .intermediate,
            icon: "dumbbell.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete scheduled workout (Push/Pull/Legs split)",
                    "Track all weights, sets, and reps",
                    "Rest 1-2 days per week as scheduled"
                ],
                weeklyGoals: [
                    "Complete 5 strength sessions",
                    "Increase weight on at least 2 exercises weekly",
                    "Track total volume lifted"
                ],
                metricsToTrack: [.weight, .reps, .sets, .duration],
                checkInInstructions: "Log every exercise with weight, sets, and reps. Mark any personal records. Rate workout intensity 1-10.",
                successCriteria: "Follow the training split, progressively overload weights, and maintain proper form. Track PRs!",
                tips: [
                    "Progressive overload is key",
                    "Prioritize compound movements",
                    "Get 7-8 hours of sleep for recovery"
                ]
            )
        ),
        ChallengeTemplate(
            name: "30-Day Full Body Transformation",
            description: "Comprehensive strength program hitting all muscle groups. Build balanced strength and muscle definition.",
            durationDays: 30,
            goalType: .muscle,
            location: .gym,
            difficulty: .advanced,
            icon: "figure.strengthtraining.traditional",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Follow daily workout program",
                    "5-6 training days per week",
                    "Log all exercises with full details"
                ],
                weeklyGoals: [
                    "Hit each muscle group 2x per week",
                    "Increase total weekly volume",
                    "Set at least 1 new PR per week"
                ],
                metricsToTrack: [.weight, .reps, .sets, .duration, .photos],
                checkInInstructions: "Complete workout logging with weights, reps, and sets. Take weekly progress photos on the same day each week.",
                successCriteria: "Consistent training with progressive overload. Complete 24+ workouts in 30 days.",
                tips: [
                    "Nutrition is 80% of results",
                    "Take rest days seriously",
                    "Document your transformation with photos"
                ]
            )
        ),

        // MARK: - Weight Loss Challenges
        ChallengeTemplate(
            name: "30-Day Weight Loss Kickoff",
            description: "Structured approach to healthy weight loss. Combine activity with daily check-ins and accountability.",
            durationDays: 30,
            goalType: .weightLoss,
            location: .anywhere,
            difficulty: .beginner,
            icon: "scalemass.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete 30+ minutes of activity",
                    "Log daily weight (morning, before eating)",
                    "Track water intake (8+ glasses)"
                ],
                weeklyGoals: [
                    "Lose 1-2 lbs per week (healthy rate)",
                    "Complete 5+ active days",
                    "Drink 56+ oz water daily average"
                ],
                metricsToTrack: [.bodyWeight, .steps, .waterIntake, .calories, .photos],
                checkInInstructions: "Weigh yourself each morning and log it. Record your activity for the day and water intake. Weekly progress photos recommended.",
                successCriteria: "Consistent daily check-ins with weight, activity, and hydration. Focus on trends over daily fluctuations.",
                tips: [
                    "Weight fluctuates daily - track weekly averages",
                    "Take progress photos in same lighting",
                    "Small sustainable changes beat crash diets"
                ]
            )
        ),
        ChallengeTemplate(
            name: "60-Day Body Transformation",
            description: "Comprehensive weight loss journey with structured phases. Sustainable approach for lasting results.",
            durationDays: 60,
            goalType: .weightLoss,
            location: .anywhere,
            difficulty: .intermediate,
            icon: "figure.walk.motion",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete daily activity (type varies by phase)",
                    "Log weight, measurements, and activity",
                    "Track meals and water intake"
                ],
                weeklyGoals: [
                    "Phase 1 (Days 1-20): Build habits, 10k steps daily",
                    "Phase 2 (Days 21-40): Add strength training",
                    "Phase 3 (Days 41-60): Optimize and maintain"
                ],
                metricsToTrack: [.bodyWeight, .steps, .duration, .calories, .waterIntake, .photos],
                checkInInstructions: "Daily check-in with weight, activity completed, and how you're feeling. Take measurements and photos every 2 weeks.",
                successCriteria: "Follow the phased approach. Aim for 8-15 lbs total loss (depends on starting point). Focus on building lasting habits.",
                tips: [
                    "This is a marathon, not a sprint",
                    "Celebrate non-scale victories",
                    "Build habits that last beyond 60 days"
                ]
            )
        ),

        // MARK: - Wellness Challenges
        ChallengeTemplate(
            name: "7-Day Wellness Reset",
            description: "Quick mental and physical reset. Focus on sleep, hydration, movement, and mindfulness.",
            durationDays: 7,
            goalType: .wellness,
            location: .anywhere,
            difficulty: .beginner,
            icon: "leaf.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "10 minutes of mindfulness/meditation",
                    "8+ glasses of water",
                    "7+ hours of sleep",
                    "20+ minutes of gentle movement"
                ],
                weeklyGoals: [
                    "Complete all 7 days",
                    "Improve sleep quality score",
                    "Reduce stress levels"
                ],
                metricsToTrack: [.meditation, .waterIntake, .sleepHours, .steps],
                checkInInstructions: "Log your meditation time, water intake, sleep hours, and movement. Rate your stress and energy levels 1-10.",
                successCriteria: "Complete all four daily wellness activities. Notice improvements in energy and mood by day 7.",
                tips: [
                    "Meditate at the same time each day",
                    "Keep a water bottle with you",
                    "Create a bedtime routine"
                ]
            )
        ),
        ChallengeTemplate(
            name: "21-Day Mindfulness Journey",
            description: "Develop a sustainable meditation practice. Build mental resilience and reduce stress through daily mindfulness.",
            durationDays: 21,
            goalType: .wellness,
            location: .home,
            difficulty: .beginner,
            icon: "brain.head.profile",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete daily guided meditation",
                    "Week 1: 5 min, Week 2: 10 min, Week 3: 15 min",
                    "Journal one gratitude or reflection"
                ],
                weeklyGoals: [
                    "Complete all 7 meditation sessions",
                    "Try different meditation styles",
                    "Notice and log stress reduction"
                ],
                metricsToTrack: [.meditation, .sleepHours],
                checkInInstructions: "Log your meditation session and duration. Write a brief reflection or gratitude note. Track your mood and stress levels.",
                successCriteria: "Build a daily meditation habit. Progress from 5 to 15 minute sessions. Notice improved focus and reduced stress.",
                tips: [
                    "Same time, same place builds habit",
                    "Start smaller if needed - even 2 min counts",
                    "Use guided meditations to start"
                ]
            )
        ),
        ChallengeTemplate(
            name: "30-Day Total Wellness",
            description: "Holistic approach combining exercise, nutrition awareness, sleep, and mindfulness for complete well-being.",
            durationDays: 30,
            goalType: .wellness,
            location: .anywhere,
            difficulty: .intermediate,
            icon: "heart.circle.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "30 min exercise (any type)",
                    "10 min meditation",
                    "Log sleep and rate quality",
                    "Track water and note one healthy meal choice"
                ],
                weeklyGoals: [
                    "5+ workout days",
                    "7 meditation sessions",
                    "Average 7+ hours sleep",
                    "Hit daily water goals 6/7 days"
                ],
                metricsToTrack: [.duration, .meditation, .sleepHours, .waterIntake, .steps],
                checkInInstructions: "Complete daily log of exercise, meditation, sleep, and hydration. Rate overall well-being 1-10. Weekly reflection on progress.",
                successCriteria: "Consistent engagement across all wellness pillars. Build sustainable habits that improve quality of life.",
                tips: [
                    "Balance is key - don't neglect any area",
                    "Progress over perfection",
                    "Connect with your challenge partners for support"
                ]
            )
        ),

        // MARK: - Fitness (General) Challenges
        ChallengeTemplate(
            name: "7-Day Kickstart",
            description: "Quick week to build momentum. Complete any workout daily and establish the exercise habit.",
            durationDays: 7,
            goalType: .fitness,
            location: .home,
            difficulty: .beginner,
            icon: "star.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete 20+ minute workout (any type)",
                    "Check in with workout details",
                    "Stay consistent all 7 days"
                ],
                weeklyGoals: [
                    "Complete all 7 days - no misses!",
                    "Try at least 3 different workout types",
                    "Build the daily exercise habit"
                ],
                metricsToTrack: [.duration, .calories],
                checkInInstructions: "Log your workout type, duration, and how you felt. Celebrate completing each day!",
                successCriteria: "Complete some form of exercise every single day for 7 days. Variety is encouraged!",
                tips: [
                    "Choose workouts you enjoy",
                    "Lay out workout clothes the night before",
                    "7 days is just the beginning!"
                ]
            )
        ),
        ChallengeTemplate(
            name: "30-Day Fitness Challenge",
            description: "Build lasting fitness habits over 30 days. Complete daily workouts and transform your routine.",
            durationDays: 30,
            goalType: .fitness,
            location: .anywhere,
            difficulty: .intermediate,
            icon: "flame.fill",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete scheduled workout (varies by day)",
                    "Mix of cardio, strength, and flexibility",
                    "Rest 1 day per week"
                ],
                weeklyGoals: [
                    "Complete 6 workout days",
                    "Include 2 cardio, 2 strength, 2 flex/recovery",
                    "Progressive intensity increase"
                ],
                metricsToTrack: [.duration, .calories, .heartRate],
                checkInInstructions: "Log each workout with type, duration, and intensity. Track how your fitness improves over the 30 days.",
                successCriteria: "Complete 26+ workouts in 30 days. Notice improvements in endurance, strength, and energy.",
                tips: [
                    "Follow a balanced approach",
                    "Recovery days are just as important",
                    "Track your progress to stay motivated"
                ]
            )
        ),

        // MARK: - Flexibility Challenges
        ChallengeTemplate(
            name: "30-Day Yoga Journey",
            description: "Daily yoga practice to improve flexibility, balance, and mindfulness. All levels welcome.",
            durationDays: 30,
            goalType: .flexibility,
            location: .home,
            difficulty: .beginner,
            icon: "figure.yoga",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete 15-30 minute yoga session",
                    "Follow along with guided practice",
                    "Focus on breath and form"
                ],
                weeklyGoals: [
                    "Complete all 7 days",
                    "Try different yoga styles",
                    "Notice flexibility improvements"
                ],
                metricsToTrack: [.duration, .meditation],
                checkInInstructions: "Log your yoga session duration and style (vinyasa, yin, power, etc.). Note any poses that felt easier than before.",
                successCriteria: "Consistent daily practice. Notice improved flexibility, balance, and mental clarity by day 30.",
                tips: [
                    "Listen to your body",
                    "Modifications are always okay",
                    "Breath is as important as poses"
                ]
            )
        ),

        // MARK: - Endurance Challenges
        ChallengeTemplate(
            name: "30-Day Endurance Builder",
            description: "Systematically increase your cardiovascular endurance through progressive training.",
            durationDays: 30,
            goalType: .endurance,
            location: .outdoor,
            difficulty: .intermediate,
            icon: "figure.run",
            configuration: ChallengeConfiguration(
                dailyRequirements: [
                    "Complete endurance session (running, cycling, swimming)",
                    "Duration increases weekly",
                    "Week 1: 20min, Week 4: 45min+"
                ],
                weeklyGoals: [
                    "5 endurance sessions per week",
                    "Increase weekly duration by 15%",
                    "Improve heart rate recovery"
                ],
                metricsToTrack: [.duration, .distance, .heartRate, .calories],
                checkInInstructions: "Log activity type, duration, distance, and average heart rate. Track your recovery heart rate improvement.",
                successCriteria: "Progressive improvement in endurance capacity. Complete longer sessions with better recovery by end of challenge.",
                tips: [
                    "Increase duration gradually",
                    "Zone 2 training builds base fitness",
                    "Recovery is when adaptation happens"
                ]
            )
        )
    ]
}
