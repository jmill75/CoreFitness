import Foundation
import SwiftData

// MARK: - Exercise Definition (Template)
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var equipment: Equipment
    var instructions: String?
    var videoURL: String?
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise]?

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment = .bodyweight,
        instructions: String? = nil,
        videoURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.instructions = instructions
        self.videoURL = videoURL
        self.createdAt = Date()
    }
}

// MARK: - Workout Template
@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var name: String
    var workoutDescription: String?
    var estimatedDuration: Int // minutes
    var difficulty: Difficulty
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.workout)
    var sessions: [WorkoutSession]?

    var sortedExercises: [WorkoutExercise] {
        exercises?.sorted(by: { $0.order < $1.order }) ?? []
    }

    var exerciseCount: Int {
        exercises?.count ?? 0
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        estimatedDuration: Int = 45,
        difficulty: Difficulty = .intermediate
    ) {
        self.id = id
        self.name = name
        self.workoutDescription = description
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Workout Exercise (Join table with exercise-specific config)
@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double? // in lbs, stored consistently
    var restDuration: Int // seconds
    var notes: String?

    // Relationships
    var workout: Workout?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \CompletedSet.workoutExercise)
    var completedSets: [CompletedSet]?

    init(
        id: UUID = UUID(),
        order: Int,
        targetSets: Int = 3,
        targetReps: Int = 10,
        targetWeight: Double? = nil,
        restDuration: Int = 90
    ) {
        self.id = id
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restDuration = restDuration
    }
}

// MARK: - Workout Session (Completed workout instance)
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var status: SessionStatus
    var totalDuration: Int? // seconds
    var caloriesBurned: Int?
    var notes: String?

    // Relationships
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \CompletedSet.session)
    var completedSets: [CompletedSet]?

    var isActive: Bool {
        status == .inProgress
    }

    var formattedDuration: String {
        guard let duration = totalDuration else { return "--:--" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        status: SessionStatus = .inProgress
    ) {
        self.id = id
        self.startedAt = startedAt
        self.status = status
    }
}

// MARK: - Completed Set (Actual logged set)
@Model
final class CompletedSet {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double // in lbs
    var completedAt: Date
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var notes: String?

    // Relationships
    var workoutExercise: WorkoutExercise?
    var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        reps: Int,
        weight: Double,
        rpe: Int? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.completedAt = Date()
        self.rpe = rpe
    }
}

// MARK: - Enums

enum MuscleGroup: String, Codable, CaseIterable {
    case chest, back, shoulders, biceps, triceps
    case quadriceps, hamstrings, glutes, calves
    case core, fullBody

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps: return "figure.strengthtraining.functional"
        case .quadriceps, .hamstrings, .calves: return "figure.walk"
        case .glutes: return "figure.step.training"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell, dumbbell, kettlebell, machine
    case cable, bodyweight, bands, other

    var displayName: String { rawValue.capitalized }
}

enum Difficulty: String, Codable, CaseIterable {
    case beginner, intermediate, advanced

    var displayName: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .beginner: return "accentGreen"
        case .intermediate: return "accentOrange"
        case .advanced: return "accentRed"
        }
    }
}

enum SessionStatus: String, Codable {
    case inProgress
    case completed
    case paused
    case cancelled
}
