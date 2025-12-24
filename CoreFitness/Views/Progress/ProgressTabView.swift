import SwiftUI

struct ProgressTabView: View {

    @Binding var selectedTab: Tab

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        // Stats Overview
                        StatsOverviewSection()
                            .id("top")

                        // Achievements/Badges
                        AchievementsSection()

                        // Streaks
                        StreaksSection()

                        // Workout History
                        WorkoutHistorySection()
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentYellow)
                        Text("Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Stats Overview Section
struct StatsOverviewSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatOverviewCard(emoji: "🔥", value: "12", label: "Day Streak", subtitle: "Best: 30 days")
                StatOverviewCard(emoji: "💪", value: "48", label: "Workouts", subtitle: "This month: 12")
            }

            HStack(spacing: 12) {
                StatOverviewCard(emoji: "⏱️", value: "32h", label: "Total Time", subtitle: "Avg: 45 min")
                StatOverviewCard(emoji: "🏆", value: "15", label: "Badges", subtitle: "3 new this week")
            }
        }
    }
}

struct StatOverviewCard: View {
    let emoji: String
    let value: String
    let label: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Achievements Section
struct AchievementsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text("See All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.brandPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(emoji: "🏆", title: "First Workout", earned: true)
                    AchievementBadge(emoji: "🔥", title: "7 Day Streak", earned: true)
                    AchievementBadge(emoji: "💯", title: "Perfect Week", earned: true)
                    AchievementBadge(emoji: "🦁", title: "Beast Mode", earned: false)
                    AchievementBadge(emoji: "⚡", title: "Speed Demon", earned: false)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct AchievementBadge: View {
    let emoji: String
    let title: String
    let earned: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? Color.accentYellow.opacity(0.2) : Color(.systemGray5))
                    .frame(width: 60, height: 60)

                Text(emoji)
                    .font(.title)
                    .opacity(earned ? 1 : 0.3)
            }

            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(earned ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
    }
}

// MARK: - Streaks Section
struct StreaksSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Streak")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(index < 5 ? Color.accentGreen : Color(.systemGray5))
                                .frame(width: 36, height: 36)

                            if index < 5 {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(["M", "T", "W", "T", "F", "S", "S"][index])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Workout History Section
struct WorkoutHistorySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text("See All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.brandPrimary)
            }

            VStack(spacing: 10) {
                WorkoutHistoryRow(name: "Upper Body Push", date: "Today", duration: "45 min", icon: "figure.arms.open")
                WorkoutHistoryRow(name: "Lower Body", date: "Yesterday", duration: "52 min", icon: "figure.walk")
                WorkoutHistoryRow(name: "Core & Cardio", date: "Dec 20", duration: "30 min", icon: "figure.core.training")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct WorkoutHistoryRow: View {
    let name: String
    let date: String
    let duration: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(duration)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProgressTabView(selectedTab: .constant(.progress))
}
