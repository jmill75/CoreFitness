import Foundation
import UIKit

// MARK: - AI Proxy Service

/// Handles all AI requests through the backend proxy server
/// API keys are stored server-side for security
@MainActor
class AIProxyService: ObservableObject {
    static let shared = AIProxyService()

    // MARK: - Configuration

    /// Base URL for the AI proxy backend
    private var baseURL: String {
        return "https://corefitness-ai-proxy.jmill75.workers.dev/api/ai"
    }

    @Published var isLoading = false
    @Published var lastError: AIError?

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120  // 2 minutes for large AI responses
        config.timeoutIntervalForResource = 180 // 3 minutes total
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Public Methods

    /// Generate health insights based on user's health analysis
    func generateHealthInsight(prompt: String, provider: AIProviderType? = nil) async throws -> AIResponse {
        let activeProvider = provider ?? AIConfigManager.shared.currentProvider
        let request = AIRequest(
            type: .healthInsight,
            prompt: prompt,
            systemPrompt: AISystemPrompts.healthInsights,
            provider: activeProvider
        )
        return try await sendRequest(request, endpoint: "/insights")
    }

    /// Generate a personalized workout plan
    func generateWorkout(prompt: String, provider: AIProviderType? = nil) async throws -> AIResponse {
        let activeProvider = provider ?? AIConfigManager.shared.currentProvider
        let request = AIRequest(
            type: .workoutGeneration,
            prompt: prompt,
            systemPrompt: AISystemPrompts.workoutGeneration,
            provider: activeProvider
        )
        return try await sendRequest(request, endpoint: "/workout")
    }

    /// Generate a general fitness tip
    func generateTip(prompt: String, provider: AIProviderType? = nil) async throws -> AIResponse {
        let activeProvider = provider ?? AIConfigManager.shared.currentProvider
        let request = AIRequest(
            type: .generalTip,
            prompt: prompt,
            systemPrompt: AISystemPrompts.generalTip,
            provider: activeProvider
        )
        return try await sendRequest(request, endpoint: "/tip")
    }

    /// Parse a workout from file content (PDF, CSV, text, etc.)
    func parseWorkout(fileContent: String, fileName: String, fileType: String, provider: AIProviderType? = nil) async throws -> WorkoutParseResult {
        let activeProvider = provider ?? AIConfigManager.shared.currentProvider

        let prompt = """
            Parse the following \(fileType) workout file named "\(fileName)":

            \(fileContent)
            """

        let request = AIRequest(
            type: .workoutGeneration,
            prompt: prompt,
            systemPrompt: AISystemPrompts.workoutParsing,
            provider: activeProvider
        )
        let response = try await sendRequest(request, endpoint: "/parse")

        // Clean the response - remove markdown code fences if present
        let cleanContent = response.content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleanContent.data(using: .utf8) else {
            return WorkoutParseResult(parsed: nil, parsedProgram: nil, parseError: "Failed to parse workout response")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return WorkoutParseResult(parsed: nil, parsedProgram: nil, parseError: "Failed to parse workout response")
        }

        // Check if it's a program with multiple workouts
        if let workoutsArray = json["workouts"] as? [[String: Any]], !workoutsArray.isEmpty {
            let programName = json["programName"] as? String ?? fileName.replacingOccurrences(of: ".\(fileType)", with: "")
            let programDesc = json["programDescription"] as? String ?? ""
            let difficulty = json["difficulty"] as? String ?? "Intermediate"

            // Parse daysPerWeek - check JSON fields first, then extract from description
            var daysPerWeek = json["daysPerWeek"] as? Int
                ?? json["days_per_week"] as? Int

            // If not in JSON, try to extract from description (e.g., "6 days", "6-day", "6x per week")
            if daysPerWeek == nil {
                daysPerWeek = extractDaysPerWeek(from: programDesc) ?? extractDaysPerWeek(from: programName)
            }

            // Final fallback: use workout count but cap at 6 (most programs max out at 6 days/week)
            if daysPerWeek == nil {
                daysPerWeek = min(6, workoutsArray.count)
            }

            // Parse durationWeeks - check JSON fields first, then extract from description
            var durationWeeks = json["durationWeeks"] as? Int
                ?? json["duration_weeks"] as? Int
                ?? json["weeks"] as? Int

            // If not in JSON, try to extract from description (e.g., "6-week program", "8 weeks")
            if durationWeeks == nil {
                durationWeeks = extractWeeks(from: programDesc) ?? extractWeeks(from: programName) ?? 8
            }

            let workouts = workoutsArray.map { workoutJson in
                ParsedWorkout(
                    name: workoutJson["name"] as? String ?? "Workout",
                    description: workoutJson["description"] as? String ?? "",
                    estimatedDuration: workoutJson["estimatedDuration"] as? Int ?? 45,
                    difficulty: difficulty,
                    exercises: parseExercisesFromJSON(workoutJson["exercises"] as? [[String: Any]] ?? [])
                )
            }

            let program = ParsedProgram(
                programName: programName,
                programDescription: programDesc,
                difficulty: difficulty,
                daysPerWeek: daysPerWeek ?? 3,
                durationWeeks: durationWeeks ?? 8,
                workouts: workouts
            )

            return WorkoutParseResult(parsed: nil, parsedProgram: program, parseError: nil)
        }

        // Single workout format
        let parsed = ParsedWorkout(
            name: json["name"] as? String ?? fileName.replacingOccurrences(of: ".\(fileType)", with: ""),
            description: json["description"] as? String ?? "",
            estimatedDuration: json["estimatedDuration"] as? Int ?? 45,
            difficulty: json["difficulty"] as? String ?? "Intermediate",
            exercises: parseExercisesFromJSON(json["exercises"] as? [[String: Any]] ?? [])
        )

        return WorkoutParseResult(parsed: parsed, parsedProgram: nil, parseError: nil)
    }

    private func parseExercisesFromJSON(_ jsonArray: [[String: Any]]) -> [ParsedExercise] {
        return jsonArray.map { dict in
            ParsedExercise(
                name: dict["name"] as? String ?? "Unknown Exercise",
                sets: dict["sets"] as? Int ?? 3,
                reps: dict["reps"] as? String ?? "10",
                weight: dict["weight"] as? String,
                restSeconds: dict["restSeconds"] as? Int
            )
        }
    }

    /// Extracts weeks from text like "6-week program", "8 weeks", "12 week"
    private func extractWeeks(from text: String) -> Int? {
        let patterns = [
            #"(\d+)[- ]?week"#,  // "6-week", "6 week", "6week"
            #"(\d+)\s*weeks"#    // "6 weeks"
        ]

        let lowercased = text.lowercased()
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)),
               let range = Range(match.range(at: 1), in: lowercased) {
                return Int(lowercased[range])
            }
        }
        return nil
    }

    /// Extracts days per week from text like "6 days", "6-day", "6x per week"
    private func extractDaysPerWeek(from text: String) -> Int? {
        let patterns = [
            #"(\d)[- ]?day"#,           // "6-day", "6 day"
            #"(\d)\s*days"#,            // "6 days"
            #"(\d)x\s*(?:per|a)\s*week"#, // "6x per week", "6x a week"
            #"(\d)\s*times?\s*(?:per|a)\s*week"# // "6 times per week"
        ]

        let lowercased = text.lowercased()
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)),
               let range = Range(match.range(at: 1), in: lowercased),
               let days = Int(lowercased[range]),
               days >= 1 && days <= 7 {
                return days
            }
        }
        return nil
    }

    // MARK: - Private Methods

    private func sendRequest(_ aiRequest: AIRequest, endpoint: String) async throws -> AIResponse {
        guard AIConfigManager.shared.isAIEnabled else {
            throw AIError.providerUnavailable
        }

        isLoading = true
        lastError = nil

        defer { isLoading = false }

        guard let url = URL(string: baseURL + endpoint) else {
            throw AIError.configurationError("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add device identifier for rate limiting (anonymized)
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            urlRequest.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        }

        do {
            urlRequest.httpBody = try encoder.encode(aiRequest)
        } catch {
            throw AIError.configurationError("Failed to encode request")
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let aiResponse = try decoder.decode(AIResponse.self, from: data)
                    return aiResponse
                } catch {
                    throw AIError.parsingError(error.localizedDescription)
                }

            case 429:
                // Parse error message from server
                if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorResponse["error"] as? [String: Any],
                   let code = error["code"] as? String,
                   let message = error["message"] as? String {
                    if code == "QUOTA_EXCEEDED" {
                        throw AIError.quotaExceeded(message: message)
                    }
                    throw AIError.rateLimited(message: message)
                }
                throw AIError.rateLimited(message: nil)

            case 503:
                throw AIError.providerUnavailable

            default:
                let message = String(data: data, encoding: .utf8)
                throw AIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }

        } catch let error as AIError {
            lastError = error
            throw error
        } catch {
            let aiError = AIError.networkError(underlying: error)
            lastError = aiError
            throw aiError
        }
    }
}

// MARK: - Backend Response Types

/// Response structure from the backend proxy
struct ProxyResponse: Codable {
    let success: Bool
    let data: AIResponse?
    let error: ProxyError?
}

struct ProxyError: Codable {
    let code: String
    let message: String
}

// MARK: - Workout Parse Response Types

struct WorkoutParseResult {
    let parsed: ParsedWorkout?
    let parsedProgram: ParsedProgram?
    let parseError: String?

    var isProgram: Bool {
        parsedProgram != nil && (parsedProgram?.workouts.count ?? 0) > 1
    }
}
