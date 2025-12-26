import Foundation
import SwiftData

// MARK: - Exercise Definition (Template)
@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscleGroupRaw: String = MuscleGroup.fullBody.rawValue
    var equipmentRaw: String = Equipment.bodyweight.rawValue
    var instructions: String?
    var videoURL: String?
    var createdAt: Date = Date()

    // Computed properties for enums
    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .bodyweight }
        set { equipmentRaw = newValue.rawValue }
    }

    // Extended properties - optional to support migration from existing data
    var category: ExerciseCategory?
    var difficulty: Difficulty?
    var location: ExerciseLocation?

    // Safe accessors with defaults
    var safeCategory: ExerciseCategory {
        category ?? .strength
    }

    var safeDifficulty: Difficulty {
        difficulty ?? .intermediate
    }

    var safeLocation: ExerciseLocation {
        location ?? .both
    }
    var estimatedCaloriesPerMinute: Int?
    var isFavorite: Bool = false
    var imageURL: String?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise]?

    // Computed property to provide a safe default
    var caloriesPerMinute: Int {
        estimatedCaloriesPerMinute ?? 8
    }

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment = .bodyweight,
        category: ExerciseCategory = .strength,
        difficulty: Difficulty = .intermediate,
        location: ExerciseLocation = .both,
        estimatedCaloriesPerMinute: Int? = 8,
        instructions: String? = nil,
        videoURL: String? = nil,
        imageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentRaw = equipment.rawValue
        self.category = category
        self.difficulty = difficulty
        self.location = location
        self.estimatedCaloriesPerMinute = estimatedCaloriesPerMinute
        self.instructions = instructions
        self.videoURL = videoURL
        self.imageURL = imageURL
        self.isFavorite = false
        self.createdAt = Date()
    }
}

// MARK: - Workout Template
@Model
final class Workout {
    var id: UUID = UUID()
    var name: String = ""
    var workoutDescription: String?
    var estimatedDuration: Int = 45 // minutes
    var difficultyRaw: String = Difficulty.intermediate.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Program management properties - defaults support migration
    var creationType: CreationType?
    var isActive: Bool = false
    var isQuickWorkout: Bool = false
    var personalRecordsCount: Int = 0

    // Computed property for difficulty enum
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .intermediate }
        set { difficultyRaw = newValue.rawValue }
    }

    // Safe accessor for creationType with default
    var safeCreationType: CreationType {
        creationType ?? .userCreated
    }

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

    var hasBeenStarted: Bool {
        (sessions?.count ?? 0) > 0
    }

    var completedSessionsCount: Int {
        sessions?.filter { $0.status == .completed }.count ?? 0
    }

    var lastSessionDate: Date? {
        sessions?.filter { $0.status == .completed }
            .sorted { $0.completedAt ?? Date.distantPast > $1.completedAt ?? Date.distantPast }
            .first?.completedAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        estimatedDuration: Int = 45,
        difficulty: Difficulty = .intermediate,
        creationType: CreationType = .userCreated,
        isQuickWorkout: Bool = false
    ) {
        self.id = id
        self.name = name
        self.workoutDescription = description
        self.estimatedDuration = estimatedDuration
        self.difficultyRaw = difficulty.rawValue
        self.creationType = creationType
        self.isQuickWorkout = isQuickWorkout
        self.isActive = false
        self.personalRecordsCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Workout Exercise (Join table with exercise-specific config)
@Model
final class WorkoutExercise {
    var id: UUID = UUID()
    var order: Int = 0
    var targetSets: Int = 3
    var targetReps: Int = 10
    var targetWeight: Double? // in lbs, stored consistently
    var restDuration: Int = 90 // seconds
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
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var completedAt: Date?
    var statusRaw: String = SessionStatus.inProgress.rawValue
    var totalDuration: Int? // seconds
    var caloriesBurned: Int?
    var notes: String?

    // Relationships
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \CompletedSet.session)
    var completedSets: [CompletedSet]?

    // Computed property for status enum
    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

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
        self.statusRaw = status.rawValue
    }
}

// MARK: - Completed Set (Actual logged set)
@Model
final class CompletedSet {
    var id: UUID = UUID()
    var setNumber: Int = 1
    var reps: Int = 0
    var weight: Double = 0 // in lbs
    var completedAt: Date = Date()
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

enum CreationType: String, Codable, CaseIterable {
    case userCreated = "User Created"
    case aiGenerated = "AI Generated"
    case imported = "Imported"
    case preset = "Preset"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .userCreated: return "person.fill"
        case .aiGenerated: return "sparkles"
        case .imported: return "square.and.arrow.down.fill"
        case .preset: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .userCreated: return "accentBlue"
        case .aiGenerated: return "purple"
        case .imported: return "accentOrange"
        case .preset: return "accentGreen"
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case strength = "Strength"
    case cardio = "Cardio"
    case yoga = "Yoga"
    case pilates = "Pilates"
    case hiit = "HIIT"
    case stretching = "Stretching"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case calisthenics = "Calisthenics"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .hiit: return "flame.fill"
        case .stretching: return "figure.flexibility"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .calisthenics: return "figure.strengthtraining.functional"
        }
    }

    var color: String {
        switch self {
        case .strength: return "accentBlue"
        case .cardio: return "accentRed"
        case .yoga: return "purple"
        case .pilates: return "accentTeal"
        case .hiit: return "accentOrange"
        case .stretching: return "accentGreen"
        case .running: return "accentYellow"
        case .cycling: return "accentBlue"
        case .swimming: return "accentTeal"
        case .calisthenics: return "accentOrange"
        }
    }
}

enum ExerciseLocation: String, Codable, CaseIterable {
    case home = "Home"
    case gym = "Gym"
    case outdoor = "Outdoor"
    case both = "Anywhere"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .gym: return "dumbbell.fill"
        case .outdoor: return "sun.max.fill"
        case .both: return "mappin.and.ellipse"
        }
    }
}
