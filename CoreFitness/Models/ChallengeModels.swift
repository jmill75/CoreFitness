import Foundation
import SwiftData

// MARK: - Challenge Model
@Model
final class Challenge {
    @Attribute(.unique) var id: UUID
    var name: String
    var challengeDescription: String
    var durationDays: Int
    var startDate: Date
    var endDate: Date
    var goalType: ChallengeGoalType
    var location: ChallengeLocation
    var creatorId: String
    var inviteCode: String
    var isActive: Bool
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ChallengeParticipant.challenge)
    var participants: [ChallengeParticipant]?

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
        self.goalType = goalType
        self.location = location
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
    @Attribute(.unique) var id: UUID
    var oderId: String
    var displayName: String
    var avatarEmoji: String
    var joinedAt: Date
    var completedDays: Int
    var currentStreak: Int
    var longestStreak: Int
    var isOwner: Bool

    // Relationships
    var challenge: Challenge?

    @Relationship(deleteRule: .cascade, inverse: \ChallengeDayLog.participant)
    var dayLogs: [ChallengeDayLog]?

    var completionPercentage: Double {
        guard let challenge = challenge else { return 0 }
        return Double(completedDays) / Double(challenge.durationDays)
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
    }

    func logDay(day: Int, completed: Bool) {
        if completed {
            completedDays += 1
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
    }
}

// MARK: - Challenge Day Log
@Model
final class ChallengeDayLog {
    @Attribute(.unique) var id: UUID
    var dayNumber: Int
    var isCompleted: Bool
    var completedAt: Date?
    var notes: String?

    // Relationships
    var participant: ChallengeParticipant?

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.isCompleted = isCompleted
        self.completedAt = isCompleted ? Date() : nil
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
