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
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
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

        guard let data = response.content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return WorkoutParseResult(parsed: nil, parseError: "Failed to parse workout response")
        }

        let parsed = ParsedWorkout(
            name: json["name"] as? String ?? fileName.replacingOccurrences(of: ".\(fileType)", with: ""),
            description: json["description"] as? String ?? "",
            estimatedDuration: json["estimatedDuration"] as? Int ?? 45,
            difficulty: json["difficulty"] as? String ?? "Intermediate",
            exercises: parseExercisesFromJSON(json["exercises"] as? [[String: Any]] ?? [])
        )

        return WorkoutParseResult(parsed: parsed, parseError: nil)
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
                throw AIError.rateLimited

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
    let parseError: String?
}
