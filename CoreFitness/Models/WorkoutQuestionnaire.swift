import Foundation

// MARK: - Workout Questionnaire

/// Captures user preferences for AI-generated workout plans
struct WorkoutQuestionnaire: Codable, Equatable {
    // MARK: - Goal
    var primaryGoal: QWorkoutGoal = .strength

    // MARK: - Schedule
    var daysPerWeek: Int = 4
    var programWeeks: Int = 8
    var sessionDuration: SessionDuration = .medium

    // MARK: - Location & Equipment
    var location: WorkoutLocation = .gym
    var availableEquipment: Set<QEquipment> = [.barbell, .dumbbell, .machines]

    // MARK: - Cardio Preferences
    var includeCardio: Bool = true
    var cardioTypes: Set<CardioType> = []
    var cardioFrequency: CardioFrequency = .moderate

    // MARK: - Experience
    var experienceLevel: ExperienceLevel = .intermediate

    // MARK: - Preferences
    var focusAreas: Set<QMuscleGroup> = []
    var avoidExercises: [String] = []
    var additionalNotes: String = ""
}

// MARK: - Questionnaire Workout Goal

enum QWorkoutGoal: String, Codable, CaseIterable, Identifiable {
    case strength = "Build Strength"
    case muscle = "Build Muscle"
    case fatLoss = "Lose Fat"
    case endurance = "Improve Endurance"
    case general = "General Fitness"
    case athletic = "Athletic Performance"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .strength: return "Focus on heavy compound lifts to maximize strength gains"
        case .muscle: return "Hypertrophy-focused training to build lean muscle mass"
        case .fatLoss: return "High-intensity workouts combined with strength training"
        case .endurance: return "Build stamina and cardiovascular fitness"
        case .general: return "Balanced approach to overall health and fitness"
        case .athletic: return "Improve speed, power, and athletic performance"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .muscle: return "figure.arms.open"
        case .fatLoss: return "flame.fill"
        case .endurance: return "figure.run"
        case .general: return "heart.fill"
        case .athletic: return "sportscourt.fill"
        }
    }
}

// MARK: - Session Duration

enum SessionDuration: Int, Codable, CaseIterable, Identifiable {
    case short = 30
    case medium = 45
    case long = 60
    case extended = 90

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue) min"
    }

    var description: String {
        switch self {
        case .short: return "Quick and efficient"
        case .medium: return "Balanced session"
        case .long: return "Full workout"
        case .extended: return "Comprehensive training"
        }
    }
}

// MARK: - Workout Location

enum WorkoutLocation: String, Codable, CaseIterable, Identifiable {
    case gym = "Gym"
    case home = "Home"
    case outdoor = "Outdoor"
    case mixed = "Mixed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gym: return "dumbbell.fill"
        case .home: return "house.fill"
        case .outdoor: return "sun.max.fill"
        case .mixed: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Questionnaire Equipment

enum QEquipment: String, Codable, CaseIterable, Identifiable, Hashable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbells"
    case kettlebell = "Kettlebells"
    case machines = "Machines"
    case cables = "Cables"
    case resistanceBands = "Resistance Bands"
    case pullUpBar = "Pull-up Bar"
    case bench = "Bench"
    case bodyweight = "Bodyweight Only"
    case trx = "TRX/Suspension"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .kettlebell: return "figure.cross.training"
        case .machines: return "gearshape.2.fill"
        case .cables: return "cable.connector"
        case .resistanceBands: return "figure.flexibility"
        case .pullUpBar: return "figure.climbing"
        case .bench: return "rectangle.split.3x1"
        case .bodyweight: return "figure.walk"
        case .trx: return "figure.gymnastics"
        }
    }
}

// MARK: - Cardio Type

enum CardioType: String, Codable, CaseIterable, Identifiable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case rowing = "Rowing"
    case elliptical = "Elliptical"
    case stairClimber = "Stair Climber"
    case jumpRope = "Jump Rope"
    case hiking = "Hiking"
    case hiit = "HIIT"
    case walking = "Walking"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .rowing: return "figure.rowing"
        case .elliptical: return "figure.elliptical"
        case .stairClimber: return "figure.stair.stepper"
        case .jumpRope: return "figure.jumprope"
        case .hiking: return "figure.hiking"
        case .hiit: return "flame.fill"
        case .walking: return "figure.walk"
        }
    }
}

// MARK: - Cardio Frequency

enum CardioFrequency: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case light = "1-2x/week"
    case moderate = "3-4x/week"
    case daily = "Daily"

    var id: String { rawValue }

    var sessionsPerWeek: Int {
        switch self {
        case .none: return 0
        case .light: return 2
        case .moderate: return 3
        case .daily: return 5
        }
    }
}

// MARK: - Experience Level

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .beginner: return "New to working out or returning after a long break"
        case .intermediate: return "1-3 years of consistent training"
        case .advanced: return "3+ years with structured programming"
        }
    }
}

// MARK: - Questionnaire Muscle Group

enum QMuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case glutes = "Glutes"
    case core = "Core"
    case calves = "Calves"
    case forearms = "Forearms"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.strengthtraining.traditional"
        case .shoulders: return "figure.boxing"
        case .biceps, .triceps: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .glutes: return "figure.run"
        case .core: return "figure.core.training"
        case .calves: return "figure.step.training"
        case .forearms: return "hand.raised.fill"
        }
    }
}

// MARK: - Generated Workout Plan

struct GeneratedWorkoutPlan: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var weeks: Int
    var workoutsPerWeek: Int
    var workouts: [GeneratedWorkout]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        weeks: Int,
        workoutsPerWeek: Int,
        workouts: [GeneratedWorkout],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.weeks = weeks
        self.workoutsPerWeek = workoutsPerWeek
        self.workouts = workouts
        self.createdAt = createdAt
    }
}

// MARK: - Generated Workout

struct GeneratedWorkout: Codable, Identifiable {
    let id: UUID
    var dayNumber: Int
    var name: String
    var exercises: [GeneratedExercise]
    var estimatedDuration: Int
    var notes: String?

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        name: String,
        exercises: [GeneratedExercise],
        estimatedDuration: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.name = name
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
        self.notes = notes
    }
}

// MARK: - Generated Exercise

struct GeneratedExercise: Codable, Identifiable {
    let id: UUID
    var exerciseName: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var notes: String?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        sets: Int,
        reps: String,
        restSeconds: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

// MARK: - Questionnaire Steps

enum QuestionnaireStep: Int, CaseIterable {
    case goal = 0
    case schedule
    case location
    case cardio
    case experience
    case preferences
    case review

    var title: String {
        switch self {
        case .goal: return "Your Goal"
        case .schedule: return "Schedule"
        case .location: return "Workout Location"
        case .cardio: return "Cardio"
        case .experience: return "Experience"
        case .preferences: return "Preferences"
        case .review: return "Review"
        }
    }

    var subtitle: String {
        switch self {
        case .goal: return "What do you want to achieve?"
        case .schedule: return "How often can you train?"
        case .location: return "Where will you work out?"
        case .cardio: return "Include cardio training?"
        case .experience: return "What's your fitness level?"
        case .preferences: return "Any specific focus areas?"
        case .review: return "Review your selections"
        }
    }

    var icon: String {
        switch self {
        case .goal: return "target"
        case .schedule: return "calendar"
        case .location: return "location.fill"
        case .cardio: return "heart.fill"
        case .experience: return "chart.bar.fill"
        case .preferences: return "slider.horizontal.3"
        case .review: return "checkmark.circle.fill"
        }
    }
}
