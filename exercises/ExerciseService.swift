import Foundation

// MARK: - Exercise Service
/// Service for loading and managing exercises from ExerciseDB API or local JSON
@MainActor
class ExerciseService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Computed Properties
    
    /// Exercises grouped by category
    var exercisesByCategory: [ExerciseCategory: [Exercise]] {
        Dictionary(grouping: exercises) { $0.category }
    }
    
    /// Exercises grouped by body part
    var exercisesByBodyPart: [BodyPart: [Exercise]] {
        Dictionary(grouping: exercises) { $0.bodyPart }
    }
    
    /// Get count for a specific category
    func count(for category: ExerciseCategory) -> Int {
        exercisesByCategory[category]?.count ?? 0
    }
    
    /// Get exercises for a specific category
    func exercises(for category: ExerciseCategory) -> [Exercise] {
        exercisesByCategory[category] ?? []
    }
    
    // MARK: - API Configuration
    
    /// ExerciseDB API base URL (V1 - Open Source)
    /// Deploy your own: https://github.com/ExerciseDB/exercisedb-api
    private let baseURL = "https://exercisedb.p.rapidapi.com"
    
    /// Alternative: Self-hosted V1 API URL
    /// private let baseURL = "https://your-exercisedb.vercel.app/api/v1"
    
    // MARK: - Loading Methods
    
    /// Load exercises from bundled JSON file
    func loadFromBundle() async {
        isLoading = true
        error = nil
        
        do {
            guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
                throw ExerciseError.fileNotFound
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            exercises = try decoder.decode([Exercise].self, from: data)
            
        } catch {
            self.error = error
            print("Error loading exercises from bundle: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load exercises from a URL (API or remote JSON)
    func loadFromURL(_ urlString: String) async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: urlString) else {
                throw ExerciseError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ExerciseError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            exercises = try decoder.decode([Exercise].self, from: data)
            
        } catch {
            self.error = error
            print("Error loading exercises from URL: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load exercises from ExerciseDB API with API key
    func loadFromExerciseDB(apiKey: String, limit: Int = 1300) async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: "\(baseURL)/exercises?limit=\(limit)") else {
                throw ExerciseError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
            request.setValue("exercisedb.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ExerciseError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            exercises = try decoder.decode([Exercise].self, from: data)
            
        } catch {
            self.error = error
            print("Error loading from ExerciseDB API: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Search & Filter
    
    /// Search exercises by name
    func search(query: String) -> [Exercise] {
        guard !query.isEmpty else { return exercises }
        
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.target.localizedCaseInsensitiveContains(query) ||
            exercise.bodyPart.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Filter exercises by multiple criteria
    func filter(
        category: ExerciseCategory? = nil,
        bodyPart: BodyPart? = nil,
        equipment: Equipment? = nil,
        difficulty: Difficulty? = nil
    ) -> [Exercise] {
        exercises.filter { exercise in
            if let category = category, exercise.category != category {
                return false
            }
            if let bodyPart = bodyPart, exercise.bodyPart != bodyPart {
                return false
            }
            if let equipment = equipment, exercise.equipment != equipment {
                return false
            }
            if let difficulty = difficulty, exercise.difficulty != difficulty {
                return false
            }
            return true
        }
    }
    
    /// Get exercises targeting a specific muscle
    func exercises(targetingMuscle muscle: String) -> [Exercise] {
        exercises.filter { exercise in
            exercise.target.localizedCaseInsensitiveContains(muscle) ||
            exercise.secondaryMuscles.contains { $0.localizedCaseInsensitiveContains(muscle) }
        }
    }
}

// MARK: - Exercise Errors
enum ExerciseError: LocalizedError {
    case fileNotFound
    case invalidURL
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Exercise data file not found in bundle"
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode exercise data"
        }
    }
}

// MARK: - Preview Helper
extension ExerciseService {
    /// Sample exercises for SwiftUI previews
    static var preview: ExerciseService {
        let service = ExerciseService()
        service.exercises = Exercise.sampleExercises
        return service
    }
}

// MARK: - Sample Data Extension
extension Exercise {
    static var sampleExercises: [Exercise] {
        [
            Exercise(
                id: "0025",
                name: "Barbell Bench Press",
                bodyPart: .chest,
                equipment: .barbell,
                target: "pectorals",
                secondaryMuscles: ["triceps", "shoulders"],
                instructions: [
                    "Lie flat on a bench with your feet flat on the ground.",
                    "Grip the barbell with hands slightly wider than shoulder-width.",
                    "Lower the bar to your chest, then press back up."
                ],
                gifUrl: "https://v2.exercisedb.io/image/GiQSHxYRwL-Vex",
                imageUrl: nil
            ),
            Exercise(
                id: "0700",
                name: "Push-Up",
                bodyPart: .chest,
                equipment: .bodyWeight,
                target: "pectorals",
                secondaryMuscles: ["triceps", "shoulders", "core"],
                instructions: [
                    "Start in a high plank position.",
                    "Lower your body until your chest nearly touches the floor.",
                    "Push back up to the starting position."
                ],
                gifUrl: "https://v2.exercisedb.io/image/5N0dZIPoPnTjhY",
                imageUrl: nil
            ),
            Exercise(
                id: "0652",
                name: "Jumping Jack",
                bodyPart: .cardio,
                equipment: .bodyWeight,
                target: "cardiovascular system",
                secondaryMuscles: ["calves", "shoulders"],
                instructions: [
                    "Stand with feet together, arms at sides.",
                    "Jump while spreading legs and raising arms overhead.",
                    "Jump back to starting position."
                ],
                gifUrl: "https://v2.exercisedb.io/image/2L7dPGKlMnChfV",
                imageUrl: nil
            )
        ]
    }
}
