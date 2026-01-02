import SwiftUI
import SwiftData

// MARK: - AI Insight Types
enum InsightType: String, Codable, CaseIterable {
    case healthAdvice       // When health data shows concerning trends
    case moodSupport        // Multiple days of low mood
    case challengeMotivation // Falling behind in challenge
    case engagementNudge    // User hasn't been active
    case hydrationReminder  // Water intake below goal
    case checkInReminder    // Haven't checked in today
    case celebratory        // Achievement or milestone
    case workoutSuggestion  // AI workout recommendations
}

enum InsightPriority: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3

    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct AIInsight: Identifiable, Equatable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let icon: String
    let color: Color
    let priority: InsightPriority
    let actionLabel: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        message: String,
        icon: String,
        color: Color,
        priority: InsightPriority = .medium,
        actionLabel: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
        self.priority = priority
        self.actionLabel = actionLabel
        self.createdAt = Date()
    }

    static func == (lhs: AIInsight, rhs: AIInsight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AI Insights Service
@MainActor
class AIInsightsService: ObservableObject {
    static let shared = AIInsightsService()

    @Published var insights: [AIInsight] = []
    @Published var aiEnabled: Bool = true

    private var modelContext: ModelContext?
    private weak var healthKitManager: HealthKitManager?

    private init() {
        // Load AI preference from UserDefaults
        aiEnabled = UserDefaults.standard.bool(forKey: "aiInsightsEnabled")
        if !UserDefaults.standard.contains(key: "aiInsightsEnabled") {
            aiEnabled = true // Default to enabled
            UserDefaults.standard.set(true, forKey: "aiInsightsEnabled")
        }
    }

    func configure(modelContext: ModelContext, healthKitManager: HealthKitManager) {
        self.modelContext = modelContext
        self.healthKitManager = healthKitManager
    }

    func setAIEnabled(_ enabled: Bool) {
        aiEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "aiInsightsEnabled")
        if !enabled {
            insights.removeAll()
        }
    }

    // MARK: - Generate Insights

    func generateInsights() async {
        guard aiEnabled else { return }

        var newInsights: [AIInsight] = []

        // Health insights
        if let healthInsight = await generateHealthInsight() {
            newInsights.append(healthInsight)
        }

        // Mood insights
        if let moodInsight = generateMoodInsight() {
            newInsights.append(moodInsight)
        }

        // Challenge insights
        if let challengeInsight = generateChallengeInsight() {
            newInsights.append(challengeInsight)
        }

        // Engagement insights
        if let engagementInsight = generateEngagementInsight() {
            newInsights.append(engagementInsight)
        }

        // Hydration reminder
        if let hydrationInsight = generateHydrationInsight() {
            newInsights.append(hydrationInsight)
        }

        // Check-in reminder
        if let checkInInsight = generateCheckInInsight() {
            newInsights.append(checkInInsight)
        }

        // Sort by priority (highest first)
        newInsights.sort { $0.priority > $1.priority }

        // Limit to top 3 insights
        insights = Array(newInsights.prefix(3))
    }

    // MARK: - Health Insights

    private func generateHealthInsight() async -> AIInsight? {
        guard let hkManager = healthKitManager else { return nil }

        // Check HRV
        let currentHRV = hkManager.healthData.hrv ?? 0

        if currentHRV > 0 && currentHRV < 30 {
            // Low HRV indicates poor recovery
            return AIInsight(
                type: .healthAdvice,
                title: "Recovery Alert",
                message: "Your HRV is lower than optimal. Consider prioritizing rest today or doing a lighter workout.",
                icon: "heart.text.square",
                color: .orange,
                priority: .high,
                actionLabel: "View Recovery"
            )
        }

        // Check sleep quality
        let sleepHours = hkManager.healthData.sleepHours ?? 0
        if sleepHours > 0 && sleepHours < 6 {
            return AIInsight(
                type: .healthAdvice,
                title: "Sleep Check-In",
                message: "You logged \(String(format: "%.1f", sleepHours)) hours of sleep. Adequate rest is crucial for muscle recovery and performance. Try to aim for 7-9 hours tonight.",
                icon: "moon.zzz",
                color: .purple,
                priority: .medium
            )
        }

        // Check resting heart rate
        let restingHR = hkManager.healthData.restingHeartRate ?? 0

        if restingHR > 0 && restingHR > 80 {
            return AIInsight(
                type: .healthAdvice,
                title: "Elevated Heart Rate",
                message: "Your resting heart rate is higher than usual today. This could indicate stress, dehydration, or inadequate recovery. Listen to your body.",
                icon: "heart.fill",
                color: .red,
                priority: .high
            )
        }

        return nil
    }

    // MARK: - Mood Insights

    private func generateMoodInsight() -> AIInsight? {
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
              recentMoods.count >= 3 else { return nil }

        // Check for consistently low mood (tired or stressed)
        let lowMoods = Set(["tired", "stressed"])
        let lowMoodCount = recentMoods.prefix(3).filter { lowMoods.contains($0.moodRaw) }.count

        if lowMoodCount >= 3 {
            return AIInsight(
                type: .moodSupport,
                title: "We're Here for You",
                message: "I noticed you've been feeling low lately. Remember that movement can boost your mood - even a short walk helps. You've got this!",
                icon: "heart.circle",
                color: .pink,
                priority: .high,
                actionLabel: "Start Quick Workout"
            )
        }

        if lowMoodCount == 2 {
            return AIInsight(
                type: .moodSupport,
                title: "Check In With Yourself",
                message: "It seems like the past few days have been challenging. Consider trying a mindfulness exercise or a gentle workout to lift your spirits.",
                icon: "sparkles",
                color: .purple,
                priority: .medium
            )
        }

        return nil
    }

    // MARK: - Challenge Insights

    private func generateChallengeInsight() -> AIInsight? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { challenge in
                challenge.isActive
            }
        )

        guard let challenges = try? context.fetch(descriptor),
              let activeChallenge = challenges.first else { return nil }

        // Check if user is behind in challenge
        let calendar = Calendar.current
        let startOfChallenge = calendar.startOfDay(for: activeChallenge.startDate)
        let today = calendar.startOfDay(for: Date())
        let daysPassed = calendar.dateComponents([.day], from: startOfChallenge, to: today).day ?? 0

        // Get user's progress (simplified check)
        if let participants = activeChallenge.participants,
           let currentUser = participants.first(where: { $0.ownerId == UserDefaults.standard.string(forKey: "currentUserId") }),
           let logs = currentUser.dayLogs {

            let daysCompleted = logs.filter { $0.isCompleted }.count

            // If behind by 2+ days
            if daysPassed - daysCompleted >= 2 && daysPassed > 0 {
                let wittyComments = [
                    "Hey champion, your challenge buddies are wondering where you are! Time to catch up?",
                    "The couch is comfy, but victory is sweeter. Let's get back on track!",
                    "Missing a day happens. Missing two? Now it's a pattern we can break together.",
                    "Your future self will thank you for getting back in the game today!"
                ]

                return AIInsight(
                    type: .challengeMotivation,
                    title: "Challenge Check-In",
                    message: wittyComments.randomElement() ?? wittyComments[0],
                    icon: "flag.fill",
                    color: .orange,
                    priority: .high,
                    actionLabel: "Log Progress"
                )
            }
        }

        return nil
    }

    // MARK: - Engagement Insights

    private func generateEngagementInsight() -> AIInsight? {
        guard let context = modelContext else { return nil }

        // Check last workout date
        let sessionsDescriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        if let sessions = try? context.fetch(sessionsDescriptor) {
            let completedSessions = sessions.filter { $0.status == .completed }

            if completedSessions.isEmpty {
                // Never completed a workout
                return AIInsight(
                    type: .engagementNudge,
                    title: "Ready to Start?",
                    message: "Your fitness journey begins with a single rep. Let's create your first workout together!",
                    icon: "figure.run",
                    color: .green,
                    priority: .medium,
                    actionLabel: "Create Workout"
                )
            }

            if let lastWorkout = completedSessions.first?.completedAt {
                let daysSinceWorkout = Calendar.current.dateComponents([.day], from: lastWorkout, to: Date()).day ?? 0

                if daysSinceWorkout >= 5 {
                    return AIInsight(
                        type: .engagementNudge,
                        title: "We Miss You!",
                        message: "It's been \(daysSinceWorkout) days since your last workout. Even a quick 10-minute session keeps the momentum going!",
                        icon: "figure.walk",
                        color: .blue,
                        priority: .medium,
                        actionLabel: "Start Quick Workout"
                    )
                }
            }
        }

        // Check if user has never used AI Create
        let workoutsDescriptor = FetchDescriptor<Workout>()
        if let workouts = try? context.fetch(workoutsDescriptor) {
            let aiWorkouts = workouts.filter { $0.creationType == .aiGenerated }
            if aiWorkouts.isEmpty && workouts.count > 2 {
                return AIInsight(
                    type: .engagementNudge,
                    title: "Try AI Create",
                    message: "Did you know I can generate personalized workouts based on your goals? Give AI Create a try!",
                    icon: "wand.and.stars",
                    color: .purple,
                    priority: .low,
                    actionLabel: "Create with AI"
                )
            }
        }

        return nil
    }

    // MARK: - Hydration Insights

    private func generateHydrationInsight() -> AIInsight? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        // Only show after noon
        guard hour >= 12 else { return nil }

        // Get today's water intake (in oz)
        let todayIntake = UserDefaults.standard.double(forKey: "todayWaterIntake")
        let dailyGoal = UserDefaults.standard.double(forKey: "dailyWaterGoal")

        guard dailyGoal > 0 else { return nil }

        let percentComplete = todayIntake / dailyGoal

        if percentComplete < 0.3 && hour >= 14 {
            return AIInsight(
                type: .hydrationReminder,
                title: "Hydration Check",
                message: "You're at \(Int(percentComplete * 100))% of your water goal. Staying hydrated improves focus and workout performance!",
                icon: "drop.fill",
                color: .cyan,
                priority: .medium,
                actionLabel: "Log Water"
            )
        }

        return nil
    }

    // MARK: - Check-In Insights

    private func generateCheckInInsight() -> AIInsight? {
        let lastCheckInDateString = UserDefaults.standard.string(forKey: "lastCheckInDateString") ?? ""
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        if lastCheckInDateString != todayString {
            let hour = Calendar.current.component(.hour, from: Date())

            // Only remind after 9am
            guard hour >= 9 else { return nil }

            return AIInsight(
                type: .checkInReminder,
                title: "Mood Tracker",
                message: "How are you feeling today? Tracking your mood helps understand your wellness trends!",
                icon: "face.smiling",
                color: .yellow,
                priority: .low,
                actionLabel: "Track Mood"
            )
        }

        return nil
    }

    // MARK: - Celebratory Insights

    func generateCelebratoryInsight(for event: String) -> AIInsight {
        switch event {
        case "first_workout":
            return AIInsight(
                type: .celebratory,
                title: "First Workout Complete!",
                message: "You did it! Your first workout is in the books. This is the beginning of something amazing.",
                icon: "star.fill",
                color: .yellow,
                priority: .high
            )
        case "streak_7":
            return AIInsight(
                type: .celebratory,
                title: "7-Day Streak!",
                message: "A whole week of consistency! You're building habits that will transform your life.",
                icon: "flame.fill",
                color: .orange,
                priority: .high
            )
        case "new_pr":
            return AIInsight(
                type: .celebratory,
                title: "New Personal Record!",
                message: "You're stronger than yesterday! Keep pushing those limits.",
                icon: "trophy.fill",
                color: .yellow,
                priority: .high
            )
        default:
            return AIInsight(
                type: .celebratory,
                title: "Great Job!",
                message: "You're making progress every day. Keep it up!",
                icon: "hands.clap.fill",
                color: .green,
                priority: .medium
            )
        }
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
