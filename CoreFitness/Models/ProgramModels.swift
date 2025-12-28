import Foundation
import SwiftData

// MARK: - Program Template (Blueprint for Workout Programs)
@Model
final class ProgramTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var programDescription: String = ""
    var categoryRaw: String = ExerciseCategory.strength.rawValue
    var difficultyRaw: String = Difficulty.intermediate.rawValue
    var durationWeeks: Int = 4
    var workoutsPerWeek: Int = 3
    var estimatedMinutesPerSession: Int = 45
    var goalRaw: String = ProgramGoal.general.rawValue
    var equipmentRequired: [String] = []
    var imageURL: String?
    var isFeatured: Bool = false
    var isPremium: Bool = false
    var createdAt: Date = Date()

    // Schedule JSON - stores the weekly workout pattern
    // Format: [{"day": 1, "workoutName": "Push Day", "isRest": false}, ...]
    var scheduleJSON: String = "[]"

    // Workouts JSON - stores all workout definitions for the program
    // Format: [{"name": "Push Day", "exercises": [{"exerciseName": "Bench Press", "sets": 3, "reps": 10, "rest": 90}, ...]}]
    var workoutsJSON: String = "[]"

    // Statistics
    var totalDownloads: Int = 0
    var averageRating: Double = 0.0
    var ratingsCount: Int = 0

    // Computed properties
    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .strength }
        set { categoryRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .intermediate }
        set { difficultyRaw = newValue.rawValue }
    }

    var goal: ProgramGoal {
        get { ProgramGoal(rawValue: goalRaw) ?? .general }
        set { goalRaw = newValue.rawValue }
    }

    var schedule: [ProgramDaySchedule] {
        get {
            guard let data = scheduleJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([ProgramDaySchedule].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue),
               let string = String(data: encoded, encoding: .utf8) {
                scheduleJSON = string
            }
        }
    }

    var workoutDefinitions: [ProgramWorkoutDefinition] {
        get {
            guard let data = workoutsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([ProgramWorkoutDefinition].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue),
               let string = String(data: encoded, encoding: .utf8) {
                workoutsJSON = string
            }
        }
    }

    var totalWorkouts: Int {
        durationWeeks * workoutsPerWeek
    }

    var formattedDuration: String {
        if durationWeeks == 1 {
            return "1 Week"
        } else if durationWeeks < 4 {
            return "\(durationWeeks) Weeks"
        } else {
            let months = durationWeeks / 4
            let remainingWeeks = durationWeeks % 4
            if remainingWeeks == 0 {
                return months == 1 ? "1 Month" : "\(months) Months"
            } else {
                return "\(durationWeeks) Weeks"
            }
        }
    }

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \UserProgram.template)
    var userPrograms: [UserProgram]?

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: ExerciseCategory,
        difficulty: Difficulty,
        durationWeeks: Int,
        workoutsPerWeek: Int,
        estimatedMinutesPerSession: Int = 45,
        goal: ProgramGoal = .general,
        equipmentRequired: [String] = [],
        isFeatured: Bool = false,
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.programDescription = description
        self.categoryRaw = category.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.durationWeeks = durationWeeks
        self.workoutsPerWeek = workoutsPerWeek
        self.estimatedMinutesPerSession = estimatedMinutesPerSession
        self.goalRaw = goal.rawValue
        self.equipmentRequired = equipmentRequired
        self.isFeatured = isFeatured
        self.isPremium = isPremium
        self.createdAt = Date()
    }
}

// MARK: - User Program (Active instance of a program template)
@Model
final class UserProgram {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var targetEndDate: Date = Date()
    var actualEndDate: Date?
    var currentWeek: Int = 1
    var currentDay: Int = 1
    var statusRaw: String = ProgramStatus.active.rawValue
    var isFavorite: Bool = false
    var notes: String?

    // Progress tracking
    var completedWorkouts: Int = 0
    var missedWorkouts: Int = 0
    var totalMinutesLogged: Int = 0
    var totalWeightLifted: Double = 0
    var totalCaloriesBurned: Int = 0
    var personalRecordsSet: Int = 0

    // Completion tracking JSON - tracks which days are completed
    // Format: {"week1": [1, 2, 4], "week2": [1, 3, 5], ...}
    var completionJSON: String = "{}"

    // Relationships
    var template: ProgramTemplate?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.userProgram)
    var sessions: [WorkoutSession]?

    // Computed properties
    var status: ProgramStatus {
        get { ProgramStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var completedDays: [String: [Int]] {
        get {
            guard let data = completionJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue),
               let string = String(data: encoded, encoding: .utf8) {
                completionJSON = string
            }
        }
    }

    var progressPercentage: Double {
        guard let template = template else { return 0 }
        let totalDays = template.durationWeeks * 7
        let completedCount = completedDays.values.reduce(0) { $0 + $1.count }
        return Double(completedCount) / Double(totalDays) * 100
    }

    var isActive: Bool {
        status == .active
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: targetEndDate)
        return max(0, calendar.dateComponents([.day], from: today, to: end).day ?? 0)
    }

    var weekProgress: Double {
        guard let template = template else { return 0 }
        let daysInWeek = template.schedule.count
        let completedThisWeek = completedDays["week\(currentWeek)"]?.count ?? 0
        return Double(completedThisWeek) / Double(daysInWeek) * 100
    }

    init(
        id: UUID = UUID(),
        template: ProgramTemplate,
        startDate: Date = Date()
    ) {
        self.id = id
        self.template = template
        self.startDate = startDate
        self.currentWeek = 1
        self.currentDay = 1
        self.statusRaw = ProgramStatus.active.rawValue

        // Calculate target end date
        let calendar = Calendar.current
        self.targetEndDate = calendar.date(
            byAdding: .day,
            value: template.durationWeeks * 7,
            to: startDate
        ) ?? startDate
    }

    func markDayCompleted(week: Int, day: Int) {
        var days = completedDays
        let key = "week\(week)"
        if days[key] == nil {
            days[key] = []
        }
        if !days[key]!.contains(day) {
            days[key]!.append(day)
        }
        completedDays = days
    }

    func isDayCompleted(week: Int, day: Int) -> Bool {
        completedDays["week\(week)"]?.contains(day) ?? false
    }
}

// MARK: - Supporting Types

struct ProgramDaySchedule: Codable, Identifiable {
    var id: UUID = UUID()
    var dayOfWeek: Int // 1 = Monday, 7 = Sunday
    var workoutName: String? // nil means rest day
    var isRest: Bool
    var notes: String?

    var dayName: String {
        switch dayOfWeek {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Day \(dayOfWeek)"
        }
    }

    var shortDayName: String {
        switch dayOfWeek {
        case 1: return "Mon"
        case 2: return "Tue"
        case 3: return "Wed"
        case 4: return "Thu"
        case 5: return "Fri"
        case 6: return "Sat"
        case 7: return "Sun"
        default: return "D\(dayOfWeek)"
        }
    }
}

struct ProgramWorkoutDefinition: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var estimatedMinutes: Int
    var exercises: [ProgramExerciseDefinition]
    var warmup: [String]?
    var cooldown: [String]?
}

struct ProgramExerciseDefinition: Codable, Identifiable {
    var id: UUID = UUID()
    var exerciseName: String
    var sets: Int
    var reps: String // Can be "10" or "8-12" or "AMRAP"
    var weight: String? // Can be "135 lbs" or "RPE 7" or "Bodyweight"
    var restSeconds: Int
    var notes: String?
    var superset: Bool = false
    var supersetWith: String? // Name of exercise to superset with
}

// MARK: - Enums

enum ProgramGoal: String, Codable, CaseIterable {
    case general = "General Fitness"
    case muscleBuilding = "Muscle Building"
    case fatloss = "Fat Loss"
    case strength = "Strength"
    case endurance = "Endurance"
    case flexibility = "Flexibility"
    case athleticPerformance = "Athletic Performance"
    case rehabilitation = "Rehabilitation"
    case competition = "Competition Prep"
    case maintenance = "Maintenance"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "figure.mixed.cardio"
        case .muscleBuilding: return "figure.strengthtraining.traditional"
        case .fatloss: return "flame.fill"
        case .strength: return "bolt.fill"
        case .endurance: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .athleticPerformance: return "sportscourt.fill"
        case .rehabilitation: return "cross.case.fill"
        case .competition: return "trophy.fill"
        case .maintenance: return "checkmark.shield.fill"
        }
    }
}

enum ProgramStatus: String, Codable, CaseIterable {
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case abandoned = "Abandoned"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .active: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .abandoned: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .active: return "accentGreen"
        case .paused: return "accentOrange"
        case .completed: return "accentBlue"
        case .abandoned: return "gray"
        }
    }
}

// MARK: - Extension for WorkoutSession to link to UserProgram
extension WorkoutSession {
    // Add relationship to UserProgram (will need to add to WorkoutModels.swift)
    // var userProgram: UserProgram?
}
