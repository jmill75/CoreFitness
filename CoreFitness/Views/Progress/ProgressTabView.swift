import SwiftUI
import SwiftData

struct ProgressTabView: View {

    @Binding var selectedTab: Tab

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        HStack {
                            Text("Progress")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .id("top")

                        // Stats Overview
                        StatsOverviewSection()

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
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Stats Overview Section
struct StatsOverviewSection: View {
    @Query private var workoutSessions: [WorkoutSession]
    @Query private var userAchievements: [UserAchievement]

    // Only completed sessions
    private var completedSessions: [WorkoutSession] {
        workoutSessions.filter { $0.status == .completed }
    }

    private var currentStreak: Int {
        // Calculate consecutive days with workouts
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let hasWorkout = completedSessions.contains {
                guard let completed = $0.completedAt else { return false }
                return calendar.isDate(completed, inSameDayAs: checkDate)
            }
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    private var bestStreak: Int {
        // For now, return current streak as best (would need to track this separately)
        max(currentStreak, 0)
    }

    private var totalWorkouts: Int {
        completedSessions.count
    }

    private var workoutsThisMonth: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        return completedSessions.filter {
            guard let completed = $0.completedAt else { return false }
            return completed >= startOfMonth
        }.count
    }

    private var totalTimeMinutes: Int {
        completedSessions.reduce(0) { $0 + (($1.totalDuration ?? 0) / 60) }
    }

    private var avgWorkoutMinutes: Int {
        guard totalWorkouts > 0 else { return 0 }
        return totalTimeMinutes / totalWorkouts
    }

    private var badgesEarned: Int {
        userAchievements.filter { $0.isComplete }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatOverviewCard(
                    emoji: "🔥",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    subtitle: bestStreak > 0 ? "Best: \(bestStreak) days" : "Start your streak!"
                )
                StatOverviewCard(
                    emoji: "💪",
                    value: "\(totalWorkouts)",
                    label: "Workouts",
                    subtitle: workoutsThisMonth > 0 ? "This month: \(workoutsThisMonth)" : "No workouts yet"
                )
            }

            HStack(spacing: 12) {
                StatOverviewCard(
                    emoji: "⏱️",
                    value: totalTimeMinutes >= 60 ? "\(totalTimeMinutes / 60)h" : "\(totalTimeMinutes)m",
                    label: "Total Time",
                    subtitle: avgWorkoutMinutes > 0 ? "Avg: \(avgWorkoutMinutes) min" : "Start training!"
                )
                StatOverviewCard(
                    emoji: "🏆",
                    value: "\(badgesEarned)",
                    label: "Badges",
                    subtitle: badgesEarned > 0 ? "Keep earning!" : "Complete goals to earn"
                )
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
    @Query(sort: \Achievement.points, order: .reverse) private var achievements: [Achievement]
    @Query private var userAchievements: [UserAchievement]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink {
                    AchievementWallView()
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.brandPrimary)
                }
            }

            // Score summary
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Color.accentYellow)
                    Text("\(earnedCount)/\(totalCount)")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.accentYellow)
                        .font(.caption)
                    Text("\(earnedPoints) pts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(displayAchievements, id: \.id) { achievement in
                        AchievementBadge(
                            emoji: achievement.emoji,
                            title: achievement.name,
                            earned: isAchievementEarned(achievement.id)
                        )
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var earnedCount: Int {
        userAchievements.filter { $0.isComplete }.count
    }

    private var totalCount: Int {
        achievements.filter { !$0.isSecret || isAchievementEarned($0.id) }.count
    }

    private var earnedPoints: Int {
        userAchievements
            .filter { $0.isComplete }
            .compactMap { userAchievement in
                achievements.first { $0.id == userAchievement.achievementId }?.points
            }
            .reduce(0, +)
    }

    private var displayAchievements: [Achievement] {
        // Show mix of earned and next to earn
        let earned = achievements.filter { isAchievementEarned($0.id) }
        let unearned = achievements.filter { !isAchievementEarned($0.id) && !$0.isSecret }

        var display: [Achievement] = []
        display.append(contentsOf: earned.prefix(3))
        display.append(contentsOf: unearned.prefix(2))
        return display
    }

    private func isAchievementEarned(_ id: String) -> Bool {
        userAchievements.first { $0.achievementId == id }?.isComplete ?? false
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
    @Query private var workoutSessions: [WorkoutSession]

    // Only completed sessions
    private var completedSessions: [WorkoutSession] {
        workoutSessions.filter { $0.status == .completed }
    }

    // Get the last 7 days and check which have workouts
    private var weekDays: [(label: String, date: Date, hasWorkout: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: today) ?? today
            let weekday = calendar.component(.weekday, from: date) - 1 // 0 = Sunday
            let hasWorkout = completedSessions.contains {
                guard let completed = $0.completedAt else { return false }
                return calendar.isDate(completed, inSameDayAs: date)
            }
            return (label: dayLabels[weekday], date: date, hasWorkout: hasWorkout)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 6) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(day.hasWorkout ? Color.accentGreen : Color(.systemGray5))
                                .frame(width: 36, height: 36)

                            if day.hasWorkout {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(day.label)
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
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var workoutSessions: [WorkoutSession]

    // Only completed sessions
    private var completedSessions: [WorkoutSession] {
        workoutSessions.filter { $0.status == .completed }
    }

    private var recentWorkouts: [WorkoutSession] {
        Array(completedSessions.prefix(3))
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if completedSessions.count > 3 {
                    Text("See All")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.brandPrimary)
                }
            }

            if recentWorkouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No workouts yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Complete your first workout to see it here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(recentWorkouts) { session in
                        WorkoutHistoryRow(
                            name: session.workout?.name ?? "Workout",
                            date: formatDate(session.completedAt),
                            duration: "\((session.totalDuration ?? 0) / 60) min",
                            icon: "figure.strengthtraining.traditional"
                        )
                    }
                }
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
