import Foundation
import SwiftData

/// Provides default achievement definitions for the app
struct AchievementDefinitions {

    /// All available achievements in the app
    static let all: [Achievement] = [
        // MARK: - Workout Achievements
        Achievement(
            id: "first_workout",
            name: "First Steps",
            description: "Complete your first workout",
            category: .workout,
            iconName: "figure.walk",
            emoji: "🎯",
            requirement: 1,
            points: 10
        ),
        Achievement(
            id: "10_workouts",
            name: "Getting Started",
            description: "Complete 10 workouts",
            category: .workout,
            iconName: "figure.strengthtraining.traditional",
            emoji: "💪",
            requirement: 10,
            points: 25
        ),
        Achievement(
            id: "50_workouts",
            name: "Dedicated",
            description: "Complete 50 workouts",
            category: .workout,
            iconName: "star.fill",
            emoji: "⭐",
            requirement: 50,
            points: 50
        ),
        Achievement(
            id: "100_workouts",
            name: "Century Club",
            description: "Complete 100 workouts",
            category: .workout,
            iconName: "trophy.fill",
            emoji: "🏆",
            requirement: 100,
            points: 100
        ),
        Achievement(
            id: "500_workouts",
            name: "Legendary",
            description: "Complete 500 workouts",
            category: .workout,
            iconName: "crown.fill",
            emoji: "👑",
            requirement: 500,
            points: 250,
            isSecret: true
        ),

        // MARK: - Streak Achievements
        Achievement(
            id: "3_day_streak",
            name: "Warming Up",
            description: "Maintain a 3-day workout streak",
            category: .streak,
            iconName: "flame.fill",
            emoji: "🔥",
            requirement: 3,
            points: 15
        ),
        Achievement(
            id: "7_day_streak",
            name: "Week Warrior",
            description: "Maintain a 7-day workout streak",
            category: .streak,
            iconName: "flame.fill",
            emoji: "🔥",
            requirement: 7,
            points: 35
        ),
        Achievement(
            id: "14_day_streak",
            name: "Fortnight Fighter",
            description: "Maintain a 14-day workout streak",
            category: .streak,
            iconName: "flame.fill",
            emoji: "🔥",
            requirement: 14,
            points: 50
        ),
        Achievement(
            id: "30_day_streak",
            name: "Monthly Master",
            description: "Maintain a 30-day workout streak",
            category: .streak,
            iconName: "flame.fill",
            emoji: "🔥",
            requirement: 30,
            points: 100
        ),
        Achievement(
            id: "100_day_streak",
            name: "Unstoppable",
            description: "Maintain a 100-day workout streak",
            category: .streak,
            iconName: "bolt.fill",
            emoji: "⚡",
            requirement: 100,
            points: 250,
            isSecret: true
        ),

        // MARK: - Strength Achievements
        Achievement(
            id: "first_pr",
            name: "Personal Best",
            description: "Set your first personal record",
            category: .strength,
            iconName: "medal.fill",
            emoji: "🥇",
            requirement: 1,
            points: 20
        ),
        Achievement(
            id: "10_prs",
            name: "Record Breaker",
            description: "Set 10 personal records",
            category: .strength,
            iconName: "trophy.fill",
            emoji: "🏅",
            requirement: 10,
            points: 50
        ),
        Achievement(
            id: "50_prs",
            name: "PR Machine",
            description: "Set 50 personal records",
            category: .strength,
            iconName: "crown.fill",
            emoji: "💎",
            requirement: 50,
            points: 100
        ),
        Achievement(
            id: "1000_lbs_session",
            name: "Thousand Pounder",
            description: "Lift over 1,000 lbs in a single session",
            category: .strength,
            iconName: "scalemass.fill",
            emoji: "🦍",
            requirement: 1000,
            points: 30
        ),
        Achievement(
            id: "10000_lbs_session",
            name: "Iron Beast",
            description: "Lift over 10,000 lbs in a single session",
            category: .strength,
            iconName: "scalemass.fill",
            emoji: "🦁",
            requirement: 10000,
            points: 75
        ),

        // MARK: - Milestone Achievements
        Achievement(
            id: "1_hour_workout",
            name: "Marathon Session",
            description: "Complete a 60+ minute workout",
            category: .milestone,
            iconName: "clock.fill",
            emoji: "⏱️",
            requirement: 60,
            points: 25
        ),
        Achievement(
            id: "early_bird",
            name: "Early Bird",
            description: "Complete a workout before 7 AM",
            category: .milestone,
            iconName: "sun.horizon.fill",
            emoji: "🌅",
            requirement: 1,
            points: 15
        ),
        Achievement(
            id: "night_owl",
            name: "Night Owl",
            description: "Complete a workout after 10 PM",
            category: .milestone,
            iconName: "moon.fill",
            emoji: "🦉",
            requirement: 1,
            points: 15
        ),
        Achievement(
            id: "weekend_warrior",
            name: "Weekend Warrior",
            description: "Complete 10 weekend workouts",
            category: .milestone,
            iconName: "calendar",
            emoji: "📅",
            requirement: 10,
            points: 30
        ),
        Achievement(
            id: "perfect_week",
            name: "Perfect Week",
            description: "Meet your weekly workout goal",
            category: .milestone,
            iconName: "checkmark.seal.fill",
            emoji: "💯",
            requirement: 1,
            points: 40
        ),

        // MARK: - Challenge Achievements
        Achievement(
            id: "30_day_challenge",
            name: "30-Day Challenge",
            description: "Complete 30 workouts in 30 days",
            category: .challenge,
            iconName: "flag.checkered",
            emoji: "🏁",
            requirement: 30,
            points: 150
        ),
        Achievement(
            id: "new_year_resolution",
            name: "Resolution Keeper",
            description: "Work out on January 1st",
            category: .challenge,
            iconName: "party.popper.fill",
            emoji: "🎉",
            requirement: 1,
            points: 25,
            isSecret: true
        ),
        Achievement(
            id: "halloween_workout",
            name: "Spooky Sweat",
            description: "Work out on Halloween",
            category: .challenge,
            iconName: "theatermasks.fill",
            emoji: "🎃",
            requirement: 1,
            points: 20,
            isSecret: true
        ),

        // MARK: - Social Achievements
        Achievement(
            id: "first_share",
            name: "Social Butterfly",
            description: "Share your first workout",
            category: .social,
            iconName: "square.and.arrow.up",
            emoji: "📤",
            requirement: 1,
            points: 15
        ),
        Achievement(
            id: "10_shares",
            name: "Influencer",
            description: "Share 10 workouts",
            category: .social,
            iconName: "person.2.wave.2",
            emoji: "🌟",
            requirement: 10,
            points: 40
        )
    ]

    /// Seeds achievements into the database if not already present
    static func seedAchievements(in context: ModelContext) {
        for achievement in all {
            // Check if achievement already exists
            let id = achievement.id
            let descriptor = FetchDescriptor<Achievement>(
                predicate: #Predicate { $0.id == id }
            )

            if let existing = try? context.fetch(descriptor), !existing.isEmpty {
                continue // Skip if already exists
            }

            // Create new achievement
            let newAchievement = Achievement(
                id: achievement.id,
                name: achievement.name,
                description: achievement.achievementDescription,
                category: achievement.category,
                iconName: achievement.iconName,
                emoji: achievement.emoji,
                requirement: achievement.requirement,
                points: achievement.points,
                isSecret: achievement.isSecret
            )
            context.insert(newAchievement)
        }

        try? context.save()
    }
}
