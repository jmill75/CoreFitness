import Foundation
import SwiftData

// MARK: - Entry Source Enum
enum EntrySource: String, Codable {
    case manual = "Manual Entry"
    case timer = "In-App Timer"
    case healthkit = "Apple Health"

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
    var oderId: String = ""
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
        oderId: String,
        displayName: String,
        avatarEmoji: String = "😀",
        isOwner: Bool = false
    ) {
        self.id = id
        self.oderId = oderId
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

    static let templates: [ChallengeTemplate] = [
        ChallengeTemplate(
            name: "30-Day Fitness Challenge",
            description: "Complete a workout every day for 30 days. Build consistency and transform your habits.",
            durationDays: 30,
            goalType: .fitness,
            location: .anywhere,
            difficulty: .intermediate,
            icon: "flame.fill"
        ),
        ChallengeTemplate(
            name: "21-Day Core Challenge",
            description: "Strengthen your core with daily ab workouts. Perfect for beginners.",
            durationDays: 21,
            goalType: .strength,
            location: .home,
            difficulty: .beginner,
            icon: "figure.core.training"
        ),
        ChallengeTemplate(
            name: "30-Day Yoga Journey",
            description: "Daily yoga practice to improve flexibility, balance, and mindfulness.",
            durationDays: 30,
            goalType: .flexibility,
            location: .home,
            difficulty: .beginner,
            icon: "figure.yoga"
        ),
        ChallengeTemplate(
            name: "14-Day HIIT Sprint",
            description: "Intense high-intensity interval training for maximum calorie burn.",
            durationDays: 14,
            goalType: .cardio,
            location: .anywhere,
            difficulty: .advanced,
            icon: "bolt.fill"
        ),
        ChallengeTemplate(
            name: "30-Day Running Challenge",
            description: "Run or jog daily, gradually increasing distance and endurance.",
            durationDays: 30,
            goalType: .endurance,
            location: .outdoor,
            difficulty: .intermediate,
            icon: "figure.run"
        ),
        ChallengeTemplate(
            name: "21-Day Strength Builder",
            description: "Progressive strength training to build muscle and power.",
            durationDays: 21,
            goalType: .muscle,
            location: .gym,
            difficulty: .intermediate,
            icon: "dumbbell.fill"
        ),
        ChallengeTemplate(
            name: "7-Day Kickstart",
            description: "A quick week-long challenge to jumpstart your fitness journey.",
            durationDays: 7,
            goalType: .fitness,
            location: .home,
            difficulty: .beginner,
            icon: "star.fill"
        ),
        ChallengeTemplate(
            name: "30-Day Wellness Reset",
            description: "Holistic challenge combining exercise, mindfulness, and healthy habits.",
            durationDays: 30,
            goalType: .wellness,
            location: .anywhere,
            difficulty: .beginner,
            icon: "leaf.fill"
        )
    ]
}
