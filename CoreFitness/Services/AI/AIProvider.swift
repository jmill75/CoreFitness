import Foundation

// MARK: - AI Provider Type

enum AIProviderType: String, Codable, CaseIterable {
    case gemini
    case claude

    var displayName: String {
        switch self {
        case .gemini: return "Gemini"
        case .claude: return "Claude"
        }
    }

    var defaultModel: String {
        switch self {
        case .gemini: return "gemini-pro"
        case .claude: return "claude-3-haiku-20240307"
        }
    }
}

// MARK: - AI Response

struct AIResponse: Codable {
    let content: String
    let tokensUsed: Int?
    let model: String
    let provider: AIProviderType

    init(content: String, tokensUsed: Int? = nil, model: String, provider: AIProviderType) {
        self.content = content
        self.tokensUsed = tokensUsed
        self.model = model
        self.provider = provider
    }
}

// MARK: - AI Request Types

enum AIRequestType: String, Codable {
    case healthInsight
    case workoutGeneration
    case generalTip
}

struct AIRequest: Codable {
    let type: AIRequestType
    let prompt: String
    let systemPrompt: String?
    let provider: AIProviderType
    let model: String?

    init(type: AIRequestType, prompt: String, systemPrompt: String? = nil, provider: AIProviderType, model: String? = nil) {
        self.type = type
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.provider = provider
        self.model = model
    }
}

// MARK: - AI Provider Protocol

protocol AIProvider {
    var providerType: AIProviderType { get }
    var name: String { get }

    func generateResponse(request: AIRequest) async throws -> AIResponse
}

extension AIProvider {
    var name: String {
        providerType.displayName
    }
}

// MARK: - AI Error Types

enum AIError: LocalizedError {
    case networkError(underlying: Error)
    case invalidResponse
    case rateLimited
    case serverError(statusCode: Int, message: String?)
    case providerUnavailable
    case configurationError(String)
    case parsingError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .providerUnavailable:
            return "AI provider is currently unavailable"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .parsingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

// MARK: - System Prompts

struct AISystemPrompts {
    static let healthInsights = """
        You are a supportive fitness and wellness coach embedded in a fitness app.
        Provide brief, actionable insights based on the user's health trends.
        Be encouraging but honest. Focus on recovery, hydration, sleep, and activity.
        Keep responses under 100 words. Use a friendly, motivating tone.
        Do not provide medical advice - suggest consulting a doctor for health concerns.
        Format your response as a JSON array of insights with this structure:
        [{"title": "Brief title", "message": "The insight message", "priority": 1-3, "type": "recovery|hydration|sleep|activity|mood|general"}]
        """

    static let workoutGeneration = """
        You are a certified personal trainer creating workout programs.
        Generate structured workout plans in JSON format.
        Consider the user's goals, experience level, and available equipment.
        Include proper warm-up and cooldown recommendations.
        Ensure progressive overload across weeks.
        Balance muscle groups appropriately.
        Keep exercise names simple and recognizable.
        """

    static let generalTip = """
        You are a friendly fitness coach providing quick tips.
        Keep responses brief (1-2 sentences), practical, and encouraging.
        Focus on actionable advice the user can apply immediately.
        """

    static let workoutParsing = """
        You are an expert at parsing workout routines from text.
        Extract the workout name, description, estimated duration, difficulty level, and exercises.
        For each exercise, extract: name, sets, reps, weight (if mentioned), and rest time.
        Return the result as valid JSON with this structure:
        {
            "name": "Workout Name",
            "description": "Brief description",
            "estimatedDuration": 45,
            "difficulty": "Beginner|Intermediate|Advanced",
            "exercises": [
                {"name": "Exercise Name", "sets": 3, "reps": "10", "weight": "135 lbs", "restSeconds": 60}
            ]
        }
        Keep exercise names simple and standardized.
        """
}
