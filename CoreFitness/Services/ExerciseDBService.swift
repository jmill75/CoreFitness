import Foundation
import SwiftData

// MARK: - ExerciseDB Entry (External API Format)
/// Represents an exercise from ExerciseDB API or JSON
struct ExerciseDBEntry: Codable, Identifiable {
    let id: String
    let name: String
    let bodyPart: String
    let equipment: String
    let target: String
    let secondaryMuscles: [String]
    let instructions: [String]
    let gifUrl: String

    /// Formatted instructions as a single string
    var formattedInstructions: String {
        instructions.enumerated().map { index, instruction in
            "\(index + 1). \(instruction)"
        }.joined(separator: " ")
    }
}

// MARK: - ExerciseDB Service
/// Service for loading and syncing exercises from ExerciseDB API or bundled JSON
@MainActor
class ExerciseDBService: ObservableObject {

    // MARK: - Published Properties
    @Published var entries: [ExerciseDBEntry] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - API Configuration
    /// ExerciseDB API base URL (RapidAPI)
    private let baseURL = "https://exercisedb.p.rapidapi.com"

    // MARK: - Loading Methods

    /// Load exercises from bundled JSON file
    func loadFromBundle() async {
        isLoading = true
        error = nil

        do {
            guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
                throw ExerciseDBError.fileNotFound
            }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            entries = try decoder.decode([ExerciseDBEntry].self, from: data)

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
                throw ExerciseDBError.invalidURL
            }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ExerciseDBError.invalidResponse
            }

            let decoder = JSONDecoder()
            entries = try decoder.decode([ExerciseDBEntry].self, from: data)

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
                throw ExerciseDBError.invalidURL
            }

            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
            request.setValue("exercisedb.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ExerciseDBError.invalidResponse
            }

            let decoder = JSONDecoder()
            entries = try decoder.decode([ExerciseDBEntry].self, from: data)

        } catch {
            self.error = error
            print("Error loading from ExerciseDB API: \(error)")
        }

        isLoading = false
    }

    // MARK: - SwiftData Integration

    /// Update existing exercises in the database with video URLs from ExerciseDB entries
    func updateExercisesWithVideos(in context: ModelContext) async {
        // First load the bundled exercises if not already loaded
        if entries.isEmpty {
            await loadFromBundle()
        }

        // Fetch all exercises from the database
        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? context.fetch(descriptor) else { return }

        var updatedCount = 0

        // Match by normalized name and update video URL
        for exercise in exercises {
            if let matchingEntry = findMatchingEntry(for: exercise.name) {
                if exercise.videoURL == nil || exercise.videoURL?.isEmpty == true {
                    exercise.videoURL = matchingEntry.gifUrl
                    updatedCount += 1
                }
                // Also update instructions if missing
                if exercise.instructions == nil || exercise.instructions?.isEmpty == true {
                    exercise.instructions = matchingEntry.formattedInstructions
                }
            }
        }

        if updatedCount > 0 {
            try? context.save()
            print("Updated \(updatedCount) exercises with video URLs")
        }
    }

    /// Find a matching ExerciseDB entry for an exercise name
    private func findMatchingEntry(for exerciseName: String) -> ExerciseDBEntry? {
        let normalizedName = normalizeExerciseName(exerciseName)

        return entries.first { entry in
            let entryNormalized = normalizeExerciseName(entry.name)
            return entryNormalized == normalizedName ||
                   entryNormalized.contains(normalizedName) ||
                   normalizedName.contains(entryNormalized)
        }
    }

    /// Normalize exercise name for matching (lowercase, remove common suffixes)
    private func normalizeExerciseName(_ name: String) -> String {
        var normalized = name.lowercased()

        // Remove common variations
        let variations = [
            " - medium grip", " - wide grip", " - close grip",
            " (barbell)", " (dumbbell)", " (cable)",
            "s" // Remove trailing 's' for singular/plural matching
        ]

        for variation in variations {
            normalized = normalized.replacingOccurrences(of: variation, with: "")
        }

        return normalized.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Search & Filter

    /// Search entries by name
    func search(query: String) -> [ExerciseDBEntry] {
        guard !query.isEmpty else { return entries }

        return entries.filter { entry in
            entry.name.localizedCaseInsensitiveContains(query) ||
            entry.target.localizedCaseInsensitiveContains(query) ||
            entry.bodyPart.localizedCaseInsensitiveContains(query)
        }
    }

    /// Get entries for a specific body part
    func entries(forBodyPart bodyPart: String) -> [ExerciseDBEntry] {
        entries.filter { $0.bodyPart.lowercased() == bodyPart.lowercased() }
    }

    /// Get entries for a specific equipment type
    func entries(forEquipment equipment: String) -> [ExerciseDBEntry] {
        entries.filter { $0.equipment.lowercased() == equipment.lowercased() }
    }

    /// Get video URL for an exercise name (for quick lookup)
    func videoURL(for exerciseName: String) -> String? {
        findMatchingEntry(for: exerciseName)?.gifUrl
    }
}

// MARK: - Exercise DB Errors
enum ExerciseDBError: LocalizedError {
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
extension ExerciseDBService {
    /// Sample service for SwiftUI previews
    static var preview: ExerciseDBService {
        let service = ExerciseDBService()
        service.entries = [
            ExerciseDBEntry(
                id: "0025",
                name: "Barbell Bench Press",
                bodyPart: "chest",
                equipment: "barbell",
                target: "pectorals",
                secondaryMuscles: ["triceps", "shoulders"],
                instructions: [
                    "Lie flat on a bench with your feet flat on the ground.",
                    "Grip the barbell with hands slightly wider than shoulder-width.",
                    "Lower the bar to your chest, then press back up."
                ],
                gifUrl: "https://v2.exercisedb.io/image/GiQSHxYRwL-Vex"
            ),
            ExerciseDBEntry(
                id: "0700",
                name: "Push-Up",
                bodyPart: "chest",
                equipment: "body weight",
                target: "pectorals",
                secondaryMuscles: ["triceps", "shoulders", "core"],
                instructions: [
                    "Start in a high plank position.",
                    "Lower your body until your chest nearly touches the floor.",
                    "Push back up to the starting position."
                ],
                gifUrl: "https://v2.exercisedb.io/image/5N0dZIPoPnTjhY"
            )
        ]
        return service
    }
}
