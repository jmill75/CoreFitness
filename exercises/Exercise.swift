import Foundation

// MARK: - Exercise Model
/// Core exercise model matching ExerciseDB v1 structure with video/GIF support
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let bodyPart: BodyPart
    let equipment: Equipment
    let target: String
    let secondaryMuscles: [String]
    let instructions: [String]
    let gifUrl: String        // Animated GIF showing exercise movement
    let imageUrl: String?     // Optional static image
    
    // Computed property for category mapping to your app's UI
    var category: ExerciseCategory {
        ExerciseCategory.from(bodyPart: bodyPart, equipment: equipment)
    }
    
    // Difficulty level (can be computed or stored)
    var difficulty: Difficulty {
        // Simple heuristic based on equipment
        switch equipment {
        case .bodyWeight, .assistedBodyweight:
            return .beginner
        case .dumbbell, .cable, .band, .stabilityBall, .medicineBall:
            return .intermediate
        case .barbell, .leverageMachine, .olympicBarbell, .kettlebell, .trapBar:
            return .intermediate
        case .smith_machine, .ezBarbell, .weightedMachine:
            return .advanced
        default:
            return .intermediate
        }
    }
}

// MARK: - Exercise Category (Matching Your App UI)
enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
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
    
    var id: String { rawValue }
    
    var iconName: String {
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
        case .strength: return "#007AFF"      // Blue
        case .cardio: return "#FF3B30"        // Red
        case .yoga: return "#AF52DE"          // Purple
        case .pilates: return "#32AFA9"       // Teal
        case .hiit: return "#FF9500"          // Orange
        case .stretching: return "#34C759"    // Green
        case .running: return "#FFCC00"       // Yellow
        case .cycling: return "#007AFF"       // Blue
        case .swimming: return "#5AC8FA"      // Light Blue
        case .calisthenics: return "#FF9500"  // Orange
        }
    }
    
    /// Maps body part and equipment to app category
    static func from(bodyPart: BodyPart, equipment: Equipment) -> ExerciseCategory {
        // Cardio-specific body parts
        if bodyPart == .cardio {
            return .cardio
        }
        
        // Equipment-based mapping
        switch equipment {
        case .bodyWeight, .assistedBodyweight:
            return .calisthenics
        case .stabilityBall, .bosuBall:
            return .pilates
        case .rope:
            return .hiit
        default:
            break
        }
        
        // Default to strength for most exercises
        return .strength
    }
}

// MARK: - Body Part
enum BodyPart: String, Codable, CaseIterable {
    case back = "back"
    case cardio = "cardio"
    case chest = "chest"
    case lowerArms = "lower arms"
    case lowerLegs = "lower legs"
    case neck = "neck"
    case shoulders = "shoulders"
    case upperArms = "upper arms"
    case upperLegs = "upper legs"
    case waist = "waist"
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Equipment
enum Equipment: String, Codable, CaseIterable {
    case assisted = "assisted"
    case assistedBodyweight = "assisted bodyweight"
    case band = "band"
    case barbell = "barbell"
    case bodyWeight = "body weight"
    case bosuBall = "bosu ball"
    case cable = "cable"
    case dumbbell = "dumbbell"
    case elliptical = "elliptical machine"
    case ezBarbell = "ez barbell"
    case hammer = "hammer"
    case kettlebell = "kettlebell"
    case leverageMachine = "leverage machine"
    case medicineBall = "medicine ball"
    case olympicBarbell = "olympic barbell"
    case resistanceBand = "resistance band"
    case roller = "roller"
    case rope = "rope"
    case skiergMachine = "skierg machine"
    case sledMachine = "sled machine"
    case smith_machine = "smith machine"
    case stabilityBall = "stability ball"
    case stationary_bike = "stationary bike"
    case stepmill = "stepmill machine"
    case tire = "tire"
    case trapBar = "trap bar"
    case upperBodyErgometer = "upper body ergometer"
    case weightedMachine = "weighted"
    case wheelRoller = "wheel roller"
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Difficulty
enum Difficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: String {
        switch self {
        case .beginner: return "#34C759"      // Green
        case .intermediate: return "#FF9500"   // Orange
        case .advanced: return "#FF3B30"       // Red
        }
    }
}

// MARK: - Exercise Extensions
extension Exercise {
    /// Full URL for the GIF (ExerciseDB CDN)
    var fullGifUrl: URL? {
        URL(string: gifUrl)
    }
    
    /// Formatted instructions as a single string
    var formattedInstructions: String {
        instructions.enumerated().map { index, instruction in
            "\(index + 1). \(instruction)"
        }.joined(separator: "\n\n")
    }
    
    /// Target muscles formatted for display
    var targetMuscles: String {
        ([target] + secondaryMuscles).joined(separator: ", ")
    }
}
