import Foundation
import SwiftUI
import SwiftData

// MARK: - Health Analysis

/// Represents analyzed health trends without raw values (for privacy)
struct HealthAnalysis: Codable {
    let hrvStatus: TrendStatus
    let sleepStatus: SleepStatus
    let restingHRStatus: TrendStatus
    let hydrationStatus: HydrationStatus
    let activityStatus: ActivityStatus
    let moodTrend: MoodTrend?
    let recoveryScore: RecoveryLevel
    let daysSinceLastWorkout: Int?
    let timeOfDay: TimeOfDay

    enum TrendStatus: String, Codable {
        case low, normal, elevated, unknown
    }

    enum SleepStatus: String, Codable {
        case poor       // < 5 hours
        case insufficient  // 5-6 hours
        case adequate   // 6-7 hours
        case optimal    // 7-9 hours
        case excessive  // > 9 hours
        case unknown
    }

    enum HydrationStatus: String, Codable {
        case veryLow    // < 20%
        case low        // 20-40%
        case moderate   // 40-60%
        case good       // 60-80%
        case excellent  // > 80%
        case unknown
    }

    enum ActivityStatus: String, Codable {
        case sedentary  // < 2000 steps
        case light      // 2000-5000 steps
        case moderate   // 5000-8000 steps
        case active     // 8000-12000 steps
        case veryActive // > 12000 steps
        case unknown
    }

    enum MoodTrend: String, Codable {
        case declining
        case stable
        case improving
        case stressed
        case tired
        case energized
        case unknown
    }

    enum RecoveryLevel: String, Codable {
        case poor, fair, good, excellent, unknown
    }

    enum TimeOfDay: String, Codable {
        case morning, afternoon, evening, night
    }
}

// MARK: - AI Generated Insight

struct AIGeneratedInsight: Codable {
    let title: String
    let message: String
    let priority: Int
    let type: String

    func toAIInsight() -> AIInsight {
        let insightType: InsightType
        switch type.lowercased() {
        case "recovery": insightType = .healthAdvice
        case "hydration": insightType = .hydrationReminder
        case "sleep": insightType = .healthAdvice
        case "activity": insightType = .engagementNudge
        case "mood": insightType = .moodSupport
        default: insightType = .healthAdvice
        }

        let color: Color
        let icon: String
        switch type.lowercased() {
        case "recovery":
            color = .orange
            icon = "heart.text.square"
        case "hydration":
            color = .cyan
            icon = "drop.fill"
        case "sleep":
            color = .purple
            icon = "moon.zzz"
        case "activity":
            color = .green
            icon = "figure.run"
        case "mood":
            color = .pink
            icon = "face.smiling"
        default:
            color = .blue
            icon = "lightbulb.fill"
        }

        let insightPriority: InsightPriority
        switch priority {
        case 1: insightPriority = .low
        case 2: insightPriority = .medium
        case 3: insightPriority = .high
        default: insightPriority = .medium
        }

        return AIInsight(
            type: insightType,
            title: title,
            message: message,
            icon: icon,
            color: color,
            priority: insightPriority
        )
    }
}

// MARK: - Health Insights Engine

@MainActor
class HealthInsightsEngine: ObservableObject {
    static let shared = HealthInsightsEngine()

    @Published var isGenerating = false
    @Published var lastGeneratedInsights: [AIInsight] = []
    @Published var lastAnalysis: HealthAnalysis?
    @Published var lastGenerationTime: Date?
    @Published var generationError: Error?

    private var modelContext: ModelContext?
    private weak var healthKitManager: HealthKitManager?
    private weak var waterIntakeManager: WaterIntakeManager?

    // Minimum interval between AI generations (4 hours)
    private let minimumGenerationInterval: TimeInterval = 4 * 60 * 60

    private init() {}

    // MARK: - Configuration

    func configure(
        modelContext: ModelContext,
        healthKitManager: HealthKitManager,
        waterIntakeManager: WaterIntakeManager?
    ) {
        self.modelContext = modelContext
        self.healthKitManager = healthKitManager
        self.waterIntakeManager = waterIntakeManager
    }

    // MARK: - Public Methods

    /// Check if we should generate new insights
    var shouldGenerateNewInsights: Bool {
        guard AIConfigManager.shared.isAIEnabled else { return false }

        guard let lastTime = lastGenerationTime else { return true }
        return Date().timeIntervalSince(lastTime) >= minimumGenerationInterval
    }

    /// Generate AI-powered health insights
    func generateInsights(force: Bool = false) async -> [AIInsight] {
        guard AIConfigManager.shared.isAIEnabled else {
            return []
        }

        // Check if we should regenerate
        guard force || shouldGenerateNewInsights else {
            return lastGeneratedInsights
        }

        isGenerating = true
        generationError = nil

        defer { isGenerating = false }

        do {
            // 1. Analyze health data
            let analysis = await analyzeHealthData()
            lastAnalysis = analysis

            // 2. Build prompt from analysis
            let prompt = buildInsightPrompt(from: analysis)

            // 3. Call AI service
            let response = try await AIProxyService.shared.generateHealthInsight(prompt: prompt)

            // 4. Parse response into insights
            let insights = parseInsights(from: response.content)

            lastGeneratedInsights = insights
            lastGenerationTime = Date()

            return insights

        } catch {
            generationError = error
            print("[HealthInsightsEngine] Generation failed: \(error.localizedDescription)")

            // Fall back to rule-based insights
            return []
        }
    }

    // MARK: - Health Analysis

    /// Analyze current health data and convert to trend indicators
    func analyzeHealthData() async -> HealthAnalysis {
        let hkManager = healthKitManager

        // HRV Analysis
        let hrvStatus: HealthAnalysis.TrendStatus
        if let hrv = hkManager?.healthData.hrv {
            if hrv < 30 {
                hrvStatus = .low
            } else if hrv > 70 {
                hrvStatus = .elevated
            } else {
                hrvStatus = .normal
            }
        } else {
            hrvStatus = .unknown
        }

        // Sleep Analysis
        let sleepStatus: HealthAnalysis.SleepStatus
        if let hours = hkManager?.healthData.sleepHours {
            switch hours {
            case ..<5: sleepStatus = .poor
            case 5..<6: sleepStatus = .insufficient
            case 6..<7: sleepStatus = .adequate
            case 7..<9: sleepStatus = .optimal
            default: sleepStatus = .excessive
            }
        } else {
            sleepStatus = .unknown
        }

        // Resting Heart Rate Analysis
        let restingHRStatus: HealthAnalysis.TrendStatus
        if let rhr = hkManager?.healthData.restingHeartRate {
            if rhr > 80 {
                restingHRStatus = .elevated
            } else if rhr < 50 {
                restingHRStatus = .low
            } else {
                restingHRStatus = .normal
            }
        } else {
            restingHRStatus = .unknown
        }

        // Hydration Analysis
        let hydrationStatus = await analyzeHydration()

        // Activity Analysis
        let activityStatus: HealthAnalysis.ActivityStatus
        if let steps = hkManager?.healthData.steps {
            switch steps {
            case ..<2000: activityStatus = .sedentary
            case 2000..<5000: activityStatus = .light
            case 5000..<8000: activityStatus = .moderate
            case 8000..<12000: activityStatus = .active
            default: activityStatus = .veryActive
            }
        } else {
            activityStatus = .unknown
        }

        // Mood Trend Analysis
        let moodTrend = analyzeMoodTrend()

        // Recovery Score
        let recoveryScore = calculateRecoveryScore(
            hrvStatus: hrvStatus,
            sleepStatus: sleepStatus,
            restingHRStatus: restingHRStatus
        )

        // Days since last workout
        let daysSinceWorkout = fetchDaysSinceLastWorkout()

        // Time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: HealthAnalysis.TimeOfDay
        switch hour {
        case 5..<12: timeOfDay = .morning
        case 12..<17: timeOfDay = .afternoon
        case 17..<21: timeOfDay = .evening
        default: timeOfDay = .night
        }

        return HealthAnalysis(
            hrvStatus: hrvStatus,
            sleepStatus: sleepStatus,
            restingHRStatus: restingHRStatus,
            hydrationStatus: hydrationStatus,
            activityStatus: activityStatus,
            moodTrend: moodTrend,
            recoveryScore: recoveryScore,
            daysSinceLastWorkout: daysSinceWorkout,
            timeOfDay: timeOfDay
        )
    }

    // MARK: - Private Methods

    private func analyzeHydration() async -> HealthAnalysis.HydrationStatus {
        guard let waterManager = waterIntakeManager else {
            // Try to get from HealthKit
            if let waterOz = healthKitManager?.healthData.waterIntake {
                let goalOz = UserDefaults.standard.double(forKey: "dailyWaterGoal")
                guard goalOz > 0 else { return .unknown }
                let percentage = waterOz / goalOz
                return hydrationStatusFromPercentage(percentage)
            }
            return .unknown
        }

        let percentage = waterManager.percentComplete
        return hydrationStatusFromPercentage(percentage)
    }

    private func hydrationStatusFromPercentage(_ percentage: Double) -> HealthAnalysis.HydrationStatus {
        switch percentage {
        case ..<0.2: return .veryLow
        case 0.2..<0.4: return .low
        case 0.4..<0.6: return .moderate
        case 0.6..<0.8: return .good
        default: return .excellent
        }
    }

    private func analyzeMoodTrend() -> HealthAnalysis.MoodTrend? {
        guard let context = modelContext else { return nil }

        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!

        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate<MoodEntry> { entry in
                entry.date >= threeDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let recentMoods = try? context.fetch(descriptor),
              recentMoods.count >= 2 else { return nil }

        let moods = recentMoods.prefix(3).map { $0.moodRaw }

        // Check for stress/tired patterns
        if moods.allSatisfy({ $0 == "stressed" }) { return .stressed }
        if moods.allSatisfy({ $0 == "tired" }) { return .tired }
        if moods.allSatisfy({ $0 == "energized" || $0 == "happy" }) { return .energized }

        // Check trend
        let moodScores = moods.map { moodScore(for: $0) }
        if moodScores.count >= 2 {
            let trend = moodScores[0] - moodScores[moodScores.count - 1]
            if trend > 1 { return .improving }
            if trend < -1 { return .declining }
        }

        return .stable
    }

    private func moodScore(for mood: String) -> Int {
        switch mood {
        case "energized": return 5
        case "happy": return 4
        case "calm": return 3
        case "tired": return 2
        case "stressed": return 1
        default: return 3
        }
    }

    private func calculateRecoveryScore(
        hrvStatus: HealthAnalysis.TrendStatus,
        sleepStatus: HealthAnalysis.SleepStatus,
        restingHRStatus: HealthAnalysis.TrendStatus
    ) -> HealthAnalysis.RecoveryLevel {
        var score = 0

        // HRV contributes 0-3 points
        switch hrvStatus {
        case .normal: score += 3
        case .elevated: score += 2
        case .low: score += 0
        case .unknown: score += 1
        }

        // Sleep contributes 0-3 points
        switch sleepStatus {
        case .optimal: score += 3
        case .adequate: score += 2
        case .excessive: score += 2
        case .insufficient: score += 1
        case .poor: score += 0
        case .unknown: score += 1
        }

        // Resting HR contributes 0-3 points
        switch restingHRStatus {
        case .normal: score += 3
        case .low: score += 2
        case .elevated: score += 0
        case .unknown: score += 1
        }

        // Total: 0-9 points
        switch score {
        case 0...2: return .poor
        case 3...4: return .fair
        case 5...6: return .good
        case 7...9: return .excellent
        default: return .unknown
        }
    }

    private func fetchDaysSinceLastWorkout() -> Int? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.status == .completed },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        guard let sessions = try? context.fetch(descriptor),
              let lastSession = sessions.first,
              let completedAt = lastSession.completedAt else { return nil }

        return Calendar.current.dateComponents([.day], from: completedAt, to: Date()).day
    }

    // MARK: - Prompt Building

    private func buildInsightPrompt(from analysis: HealthAnalysis) -> String {
        var contextParts: [String] = []

        // Recovery context
        contextParts.append("Recovery score: \(analysis.recoveryScore.rawValue)")

        // HRV context
        if analysis.hrvStatus != .unknown {
            contextParts.append("HRV: \(analysis.hrvStatus.rawValue)")
        }

        // Sleep context
        if analysis.sleepStatus != .unknown {
            contextParts.append("Sleep quality: \(analysis.sleepStatus.rawValue)")
        }

        // Resting HR context
        if analysis.restingHRStatus != .unknown {
            contextParts.append("Resting heart rate: \(analysis.restingHRStatus.rawValue)")
        }

        // Hydration context
        if analysis.hydrationStatus != .unknown {
            contextParts.append("Hydration level: \(analysis.hydrationStatus.rawValue)")
        }

        // Activity context
        if analysis.activityStatus != .unknown {
            contextParts.append("Activity level today: \(analysis.activityStatus.rawValue)")
        }

        // Mood context
        if let mood = analysis.moodTrend {
            contextParts.append("Recent mood trend: \(mood.rawValue)")
        }

        // Workout context
        if let days = analysis.daysSinceLastWorkout {
            if days == 0 {
                contextParts.append("Worked out today")
            } else if days == 1 {
                contextParts.append("Last workout: yesterday")
            } else {
                contextParts.append("Days since last workout: \(days)")
            }
        }

        // Time context
        contextParts.append("Time of day: \(analysis.timeOfDay.rawValue)")

        let context = contextParts.joined(separator: ", ")

        return """
            User health context: \(context).

            Generate 1-2 brief, personalized health insights based on this data.
            Focus on the most important observation and actionable advice.
            Be encouraging but honest about areas needing attention.
            """
    }

    // MARK: - Response Parsing

    private func parseInsights(from content: String) -> [AIInsight] {
        // Try to parse as JSON array
        guard let data = content.data(using: .utf8) else {
            return [createFallbackInsight(from: content)]
        }

        do {
            let generatedInsights = try JSONDecoder().decode([AIGeneratedInsight].self, from: data)
            return generatedInsights.map { $0.toAIInsight() }
        } catch {
            // If JSON parsing fails, try to extract from text
            print("[HealthInsightsEngine] JSON parsing failed, using text: \(error)")
            return [createFallbackInsight(from: content)]
        }
    }

    private func createFallbackInsight(from content: String) -> AIInsight {
        // Create a single insight from the raw text
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return AIInsight(
            type: .healthAdvice,
            title: "Health Insight",
            message: String(cleanContent.prefix(200)),
            icon: "lightbulb.fill",
            color: .blue,
            priority: .medium
        )
    }
}
