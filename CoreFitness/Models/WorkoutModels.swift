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
    var imageId: String?  // Base name for exercise images (e.g., "Barbell_Bench_Press_-_Medium_Grip")

    // Computed properties for exercise images
    var startImageName: String? {
        guard let imageId = imageId, !imageId.isEmpty else { return nil }
        return "\(imageId)_0"
    }

    var endImageName: String? {
        guard let imageId = imageId, !imageId.isEmpty else { return nil }
        return "\(imageId)_1"
    }

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
        imageURL: String? = nil,
        imageId: String? = nil
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
        self.imageId = imageId
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
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Status & Type
    var statusRaw: String = WorkoutStatus.created.rawValue
    var workoutTypeRaw: String = WorkoutType.regular.rawValue
    var difficultyRaw: String = Difficulty.intermediate.rawValue

    // MARK: - Source/Creation Info
    var creationTypeRaw: String = CreationType.userCreated.rawValue
    var sourceProgramId: UUID?
    var sourceProgramName: String?
    var linkedChallengeId: UUID?  // If this workout is part of a challenge

    // MARK: - Program Schedule Position
    var programWeekNumber: Int = 0            // Which week of the program (1-12 for 12-week program)
    var programDayNumber: Int = 0             // Which day within the week (1-7, where 1=Monday)
    var programSessionNumber: Int = 0         // Session number within entire program (1-36 for 12 weeks x 3/week)
    var scheduledDate: Date?                  // The actual date this workout is scheduled for

    // MARK: - Goal & Category
    var goalRaw: String = WorkoutGoal.general.rawValue
    var categoryRaw: String = ExerciseCategory.strength.rawValue

    // MARK: - Duration & Schedule
    var estimatedDuration: Int = 45          // minutes per session
    var totalWeeks: Int = 1                   // Total program duration in weeks
    var totalDays: Int = 1                    // Days per week
    var totalSessions: Int = 1                // Total number of sessions
    var sessionLength: Int = 45               // Target minutes per session
    var restDaysBetweenSessions: Int = 1      // Rest days between workouts

    // MARK: - Timing
    var firstStartedAt: Date?                 // When workout was first started
    var lastCompletedAt: Date?                // When last session completed
    var scheduledStartDate: Date?             // When workout is scheduled to begin
    var scheduledEndDate: Date?               // Target completion date

    // MARK: - State Flags
    var isActive: Bool = false                // Currently selected/in-use
    var isQuickWorkout: Bool = false          // Quick workout flag
    var isFavorite: Bool = false              // User favorited
    var isArchived: Bool = false              // Archived/hidden from main list

    // MARK: - Progress Tracking
    var personalRecordsCount: Int = 0
    var totalCaloriesBurned: Int = 0
    var totalMinutesCompleted: Int = 0
    var totalWeightLifted: Double = 0

    // MARK: - Trophy/Achievement
    var isTrophyEligible: Bool = false
    var trophyCategoryRaw: String?            // "strength_pr", "consistency", etc.
    var trophyRequirement: String?            // Description of what's needed
    var trophyAchievedAt: Date?               // When trophy was earned

    // MARK: - Calendar/Schedule Data (JSON encoded)
    var scheduledDaysJSON: String?            // JSON: [1,3,5] for Mon/Wed/Fri
    var restDaysJSON: String?                 // JSON: list of rest day dates
    var completedDatesJSON: String?           // JSON: list of completed session dates

    // MARK: - Notes & Tags
    var notes: String?
    var tagsJSON: String?                     // JSON: ["upper body", "strength"]

    // MARK: - Computed Properties for Enums
    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: statusRaw) ?? .created }
        set { statusRaw = newValue.rawValue }
    }

    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .regular }
        set { workoutTypeRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .intermediate }
        set { difficultyRaw = newValue.rawValue }
    }

    var creationType: CreationType {
        get { CreationType(rawValue: creationTypeRaw) ?? .userCreated }
        set { creationTypeRaw = newValue.rawValue }
    }

    var goal: WorkoutGoal {
        get { WorkoutGoal(rawValue: goalRaw) ?? .general }
        set { goalRaw = newValue.rawValue }
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .strength }
        set { categoryRaw = newValue.rawValue }
    }

    var trophyCategory: String? {
        get { trophyCategoryRaw }
        set { trophyCategoryRaw = newValue }
    }

    // MARK: - Scheduled Days Helpers
    var scheduledDays: [Int] {
        get {
            guard let json = scheduledDaysJSON,
                  let data = json.data(using: .utf8),
                  let days = try? JSONDecoder().decode([Int].self, from: data) else {
                return []
            }
            return days
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                scheduledDaysJSON = json
            }
        }
    }

    var restDays: [Date] {
        get {
            guard let json = restDaysJSON,
                  let data = json.data(using: .utf8),
                  let dates = try? JSONDecoder().decode([Date].self, from: data) else {
                return []
            }
            return dates
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                restDaysJSON = json
            }
        }
    }

    var completedDates: [Date] {
        get {
            guard let json = completedDatesJSON,
                  let data = json.data(using: .utf8),
                  let dates = try? JSONDecoder().decode([Date].self, from: data) else {
                return []
            }
            return dates
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                completedDatesJSON = json
            }
        }
    }

    var tags: [String] {
        get {
            guard let json = tagsJSON,
                  let data = json.data(using: .utf8),
                  let t = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return t
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                tagsJSON = json
            }
        }
    }

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.workout)
    var sessions: [WorkoutSession]?

    // MARK: - Computed Helpers
    var sortedExercises: [WorkoutExercise] {
        exercises?.sorted(by: { $0.order < $1.order }) ?? []
    }

    var exerciseCount: Int {
        exercises?.count ?? 0
    }

    var hasBeenStarted: Bool {
        firstStartedAt != nil || (sessions?.count ?? 0) > 0
    }

    var completedSessionsCount: Int {
        sessions?.filter { $0.status == .completed }.count ?? 0
    }

    var pausedSessionsCount: Int {
        sessions?.filter { $0.status == .paused || $0.status == .cancelled }.count ?? 0
    }

    var lastSessionDate: Date? {
        sessions?.filter { $0.status == .completed }
            .sorted { $0.completedAt ?? Date.distantPast > $1.completedAt ?? Date.distantPast }
            .first?.completedAt
    }

    var progressPercentage: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessionsCount) / Double(totalSessions) * 100
    }

    var isCompleted: Bool {
        status == .completed || (totalSessions > 0 && completedSessionsCount >= totalSessions)
    }

    var nextScheduledDate: Date? {
        // Return next scheduled workout date based on scheduledDays
        guard !scheduledDays.isEmpty else { return nil }
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())

        // Find next scheduled day
        for i in 0..<7 {
            let checkDay = ((today - 1 + i) % 7) + 1
            if scheduledDays.contains(checkDay) {
                return calendar.date(byAdding: .day, value: i, to: Date())
            }
        }
        return nil
    }

    var previousSession: WorkoutSession? {
        sessions?.filter { $0.status == .completed }
            .sorted { $0.completedAt ?? Date.distantPast > $1.completedAt ?? Date.distantPast }
            .first
    }

    var formattedDuration: String {
        if totalWeeks > 1 {
            return "\(totalWeeks) weeks"
        } else if totalDays > 1 {
            return "\(totalDays) days"
        } else {
            return "\(estimatedDuration) min"
        }
    }

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        estimatedDuration: Int = 45,
        difficulty: Difficulty = .intermediate,
        creationType: CreationType = .userCreated,
        workoutType: WorkoutType = .regular,
        goal: WorkoutGoal = .general,
        isQuickWorkout: Bool = false
    ) {
        self.id = id
        self.name = name
        self.workoutDescription = description
        self.estimatedDuration = estimatedDuration
        self.sessionLength = estimatedDuration
        self.difficultyRaw = difficulty.rawValue
        self.creationTypeRaw = creationType.rawValue
        self.workoutTypeRaw = workoutType.rawValue
        self.goalRaw = goal.rawValue
        self.isQuickWorkout = isQuickWorkout
        self.isActive = false
        self.personalRecordsCount = 0
        self.statusRaw = WorkoutStatus.created.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Helper Methods
    func markAsStarted() {
        if firstStartedAt == nil {
            firstStartedAt = Date()
        }
        status = .inProgress
        isActive = true
        updatedAt = Date()
    }

    func markAsCompleted() {
        status = .completed
        lastCompletedAt = Date()
        isActive = false
        updatedAt = Date()
    }

    func markAsSaved() {
        status = .savedInMiddle
        updatedAt = Date()
    }

    func markAsAbandoned() {
        status = .abandoned
        isActive = false
        updatedAt = Date()
    }

    func addCompletedDate(_ date: Date) {
        var dates = completedDates
        dates.append(date)
        completedDates = dates
    }

    func addRestDay(_ date: Date) {
        var days = restDays
        days.append(date)
        restDays = days
    }

    func updateStats(calories: Int, minutes: Int, weight: Double) {
        totalCaloriesBurned += calories
        totalMinutesCompleted += minutes
        totalWeightLifted += weight
        updatedAt = Date()
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
    var userProgram: UserProgram?

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

    var shortName: String {
        switch self {
        case .beginner: return "Easy"
        case .intermediate: return "Medium"
        case .advanced: return "Hard"
        }
    }

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

// MARK: - Workout Status (Lifecycle)
enum WorkoutStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case created = "Created"           // Created but never started
    case active = "Active"             // Currently being used
    case inProgress = "In Progress"    // Mid-workout
    case completed = "Completed"       // Finished all sessions
    case savedInMiddle = "Saved"       // Paused/saved for later
    case abandoned = "Abandoned"       // Started but gave up
    case deleted = "Deleted"           // Soft deleted

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .draft: return "doc.badge.ellipsis"
        case .created: return "plus.circle"
        case .active: return "play.circle.fill"
        case .inProgress: return "clock.fill"
        case .completed: return "checkmark.circle.fill"
        case .savedInMiddle: return "bookmark.fill"
        case .abandoned: return "xmark.circle"
        case .deleted: return "trash"
        }
    }

    var color: String {
        switch self {
        case .draft: return "gray"
        case .created: return "accentBlue"
        case .active: return "accentGreen"
        case .inProgress: return "accentOrange"
        case .completed: return "accentGreen"
        case .savedInMiddle: return "accentYellow"
        case .abandoned: return "gray"
        case .deleted: return "accentRed"
        }
    }
}

// MARK: - Workout Type
enum WorkoutType: String, Codable, CaseIterable {
    case regular = "Regular"
    case challenge = "Challenge"
    case quickWorkout = "Quick Workout"
    case programSession = "Program Session"
    case custom = "Custom"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .regular: return "dumbbell.fill"
        case .challenge: return "trophy.fill"
        case .quickWorkout: return "bolt.fill"
        case .programSession: return "calendar.badge.clock"
        case .custom: return "slider.horizontal.3"
        }
    }

    var color: String {
        switch self {
        case .regular: return "accentBlue"
        case .challenge: return "accentOrange"
        case .quickWorkout: return "accentYellow"
        case .programSession: return "accentTeal"
        case .custom: return "purple"
        }
    }
}

// MARK: - Workout Goal
enum WorkoutGoal: String, Codable, CaseIterable {
    case strength = "Strength"
    case cardio = "Cardio"
    case muscleBuilding = "Muscle Building"
    case fatLoss = "Fat Loss"
    case endurance = "Endurance"
    case flexibility = "Flexibility"
    case general = "General Fitness"
    case athleticPerformance = "Athletic Performance"
    case rehabilitation = "Rehabilitation"
    case maintenance = "Maintenance"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        case .muscleBuilding: return "figure.arms.open"
        case .fatLoss: return "flame.fill"
        case .endurance: return "figure.run"
        case .flexibility: return "figure.flexibility"
        case .general: return "figure.mixed.cardio"
        case .athleticPerformance: return "sportscourt.fill"
        case .rehabilitation: return "cross.fill"
        case .maintenance: return "arrow.triangle.2.circlepath"
        }
    }

    var color: String {
        switch self {
        case .strength: return "accentBlue"
        case .cardio: return "accentRed"
        case .muscleBuilding: return "accentOrange"
        case .fatLoss: return "accentYellow"
        case .endurance: return "accentGreen"
        case .flexibility: return "purple"
        case .general: return "accentTeal"
        case .athleticPerformance: return "accentOrange"
        case .rehabilitation: return "accentGreen"
        case .maintenance: return "gray"
        }
    }
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
