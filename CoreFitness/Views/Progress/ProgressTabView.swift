import SwiftUI
import SwiftData

struct ProgressTabView: View {

    @Binding var selectedTab: Tab

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with stats strip
                        ProgressHeader()
                            .id("top")

                        // Active Program Progress
                        ActiveProgramProgressSection()
                            .padding(.top, 24)
                            .padding(.horizontal)

                        // Featured Achievement - Next to Earn
                        FeaturedAchievementSection()
                            .padding(.top, 24)
                            .padding(.horizontal)

                        // Trophy Case - Earned Achievements
                        TrophyCaseSection()
                            .padding(.top, 28)
                            .padding(.horizontal)

                        // In Progress Achievements
                        InProgressSection()
                            .padding(.top, 28)
                            .padding(.horizontal)

                        // Weekly Activity & Recent Workouts
                        ActivitySection()
                            .padding(.top, 28)
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)
                .background(Color.black.ignoresSafeArea())
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .progress {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Progress Header
private struct ProgressHeader: View {
    @Query private var workoutSessions: [WorkoutSession]
    @Query private var userAchievements: [UserAchievement]
    @Query(sort: \Achievement.points, order: .reverse) private var achievements: [Achievement]
    @Query private var userPrograms: [UserProgram]

    @State private var selectedSummary: SummaryTab = .allTime

    private let cardBg = Color(hex: "161616")
    private let goldStart = Color(hex: "feca57")
    private let goldEnd = Color(hex: "ff9f43")

    private enum SummaryTab: String, CaseIterable {
        case allTime = "All Time"
        case currentProgram = "Current Program"
    }

    // MARK: - Cached Computed Properties (Performance Optimized)

    private var completedSessions: [WorkoutSession] {
        workoutSessions.filter { $0.status == .completed }
    }

    private var activeProgram: UserProgram? {
        userPrograms.first { $0.status == .active }
    }

    // Program-specific sessions
    private var programSessions: [WorkoutSession] {
        guard let program = activeProgram else { return [] }
        return completedSessions.filter { session in
            guard let completedAt = session.completedAt else { return false }
            return completedAt >= program.startDate
        }
    }

    // Optimized: Build Set of workout dates once, then check streak
    private var currentStreak: Int {
        let calendar = Calendar.current
        let sessions = selectedSummary == .allTime ? completedSessions : programSessions

        let workoutDates: Set<Date> = Set(
            sessions.compactMap { session in
                guard let completed = session.completedAt else { return nil }
                return calendar.startOfDay(for: completed)
            }
        )

        guard !workoutDates.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while workoutDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        return streak
    }

    private var earnedCount: Int {
        userAchievements.filter { $0.isComplete }.count
    }

    // Optimized: Build dictionary lookup once - O(n) instead of O(n²)
    private var totalPoints: Int {
        let pointsById = achievements.reduce(into: [String: Int]()) { dict, achievement in
            dict[achievement.id] = achievement.points
        }
        return userAchievements
            .filter { $0.isComplete }
            .compactMap { pointsById[$0.achievementId] }
            .reduce(0, +)
    }

    private var workoutCount: Int {
        selectedSummary == .allTime ? completedSessions.count : programSessions.count
    }

    var body: some View {
        VStack(spacing: 20) {
            // Title with gradient
            HStack {
                Text("PROGRESS")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, goldStart],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Summary Section
            VStack(spacing: 16) {
                // Section Header with Segmented Control
                HStack {
                    Text("SUMMARY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    // Segmented Picker
                    HStack(spacing: 0) {
                        ForEach(SummaryTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSummary = tab
                                }
                            } label: {
                                Text(tab.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(selectedSummary == tab ? .white : .white.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedSummary == tab ?
                                        Color.white.opacity(0.15) : Color.clear
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .padding(.horizontal)

                // Stats Grid - 2x2 with bigger cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ProgressStatCard(
                        value: "\(currentStreak)",
                        label: "Day Streak",
                        icon: "flame.fill",
                        color: Color(hex: "ff6b6b")
                    )

                    ProgressStatCard(
                        value: "\(earnedCount)",
                        label: "Trophies",
                        icon: "trophy.fill",
                        color: goldStart
                    )

                    ProgressStatCard(
                        value: "\(totalPoints)",
                        label: "Points",
                        icon: "star.fill",
                        color: Color(hex: "54a0ff")
                    )

                    ProgressStatCard(
                        value: "\(workoutCount)",
                        label: "Workouts",
                        icon: "figure.strengthtraining.traditional",
                        color: Color(hex: "1dd1a1")
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Progress Stat Card (Bigger)
private struct ProgressStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    private let cardBg = Color(hex: "161616")

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            // Value
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Label
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Active Program Progress Section
private struct ActiveProgramProgressSection: View {
    @Query private var userPrograms: [UserProgram]

    private let cyanColor = Color(hex: "54a0ff")

    private var activeProgram: UserProgram? {
        userPrograms.first { $0.status == .active }
    }

    var body: some View {
        if let program = activeProgram, let template = program.template {
            VStack(alignment: .leading, spacing: 16) {
                // Section header with colored icon
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [cyanColor, cyanColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                            Image(systemName: "figure.run.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text("ACTIVE PROGRAM")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.7))
                            .tracking(1.5)
                    }

                    Spacer()

                    NavigationLink {
                        ProgramDetailView(
                            program: template,
                            activeProgram: program
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Text("View")
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(cyanColor)
                    }
                }

                // Program card
                ActiveProgramCard(program: program, template: template)
            }
        }
    }
}

private struct ActiveProgramCard: View {
    let program: UserProgram
    let template: ProgramTemplate

    private let cardBg = Color(hex: "161616")

    private var overallProgress: Double {
        let totalWorkouts = template.durationWeeks * template.workoutsPerWeek
        guard totalWorkouts > 0 else { return 0 }
        return Double(program.completedWorkouts) / Double(totalWorkouts)
    }

    private var workoutsThisWeek: Int {
        let weekKey = "week\(program.currentWeek)"
        return program.completedDays[weekKey]?.count ?? 0
    }

    private var weekProgress: Double {
        guard template.workoutsPerWeek > 0 else { return 0 }
        return Double(workoutsThisWeek) / Double(template.workoutsPerWeek)
    }

    private var categoryColor: Color {
        switch template.category {
        case .strength: return Color(hex: "ff6b6b")
        case .cardio: return Color(hex: "ff6b6b")
        case .yoga: return Color(hex: "00d2d3")
        case .pilates: return Color(hex: "54a0ff")
        case .hiit: return Color(hex: "ff9f43")
        case .stretching: return Color(hex: "1dd1a1")
        case .running: return Color(hex: "00d2d3")
        case .cycling: return Color(hex: "54a0ff")
        case .swimming: return Color(hex: "54a0ff")
        case .calisthenics: return Color(hex: "00d2d3")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header row
            HStack(spacing: 14) {
                // Category icon with glow
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [categoryColor, categoryColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: template.category.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("Week \(program.currentWeek) of \(template.durationWeeks)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))

                        Text("•")
                            .foregroundStyle(.white.opacity(0.3))

                        Text("\(program.completedWorkouts) workouts done")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()
            }

            // Overall progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    Text("\(Int(overallProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(categoryColor)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [categoryColor, categoryColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * overallProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // This week progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("This Week")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    Text("\(workoutsThisWeek)/\(template.workoutsPerWeek)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Week workout dots
                HStack(spacing: 8) {
                    ForEach(0..<template.workoutsPerWeek, id: \.self) { index in
                        let completed = index < workoutsThisWeek
                        Circle()
                            .fill(completed ? categoryColor : Color.white.opacity(0.1))
                            .frame(width: 12, height: 12)
                            .overlay(
                                completed ?
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.white)
                                : nil
                            )
                    }

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            VStack {
                LinearGradient(
                    colors: [categoryColor.opacity(0.9), categoryColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Featured Achievement Section
private struct FeaturedAchievementSection: View {
    @Query(sort: \Achievement.points, order: .reverse) private var achievements: [Achievement]
    @Query private var userAchievements: [UserAchievement]

    private let goldColor = Color(hex: "feca57")
    private let cyanColor = Color(hex: "54a0ff")

    // Optimized: Build lookup dictionary once - O(n) instead of O(n²)
    private var nextAchievement: (achievement: Achievement, progress: Double)? {
        // Build lookup dictionaries O(n) once - use reduce to safely handle duplicates
        let userAchievementById = userAchievements.reduce(into: [String: UserAchievement]()) { dict, ua in
            dict[ua.achievementId] = ua
        }

        // Find the closest-to-complete unearned achievement
        let unearned = achievements.filter { achievement in
            !achievement.isSecret && !(userAchievementById[achievement.id]?.isComplete ?? false)
        }

        var closest: (Achievement, Double)? = nil
        var highestProgress: Double = -1

        for achievement in unearned {
            let userProgress = userAchievementById[achievement.id]?.progress ?? 0  // O(1) lookup
            let progress = achievement.requirement > 0 ? Double(userProgress) / Double(achievement.requirement) : 0

            if progress > highestProgress {
                highestProgress = progress
                closest = (achievement, progress)
            }
        }

        return closest
    }

    private func isEarned(_ id: String) -> Bool {
        userAchievements.first { $0.achievementId == id }?.isComplete ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with colored icon
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [goldColor, Color(hex: "ff9f43")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "star.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("NEXT TROPHY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1.5)
                }

                Spacer()

                NavigationLink {
                    AchievementWallView()
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(cyanColor)
                }
            }

            if let next = nextAchievement {
                FeaturedAchievementCard(
                    achievement: next.achievement,
                    progress: next.progress
                )
            } else {
                // All achievements earned state
                AllAchievementsEarnedCard()
            }
        }
    }
}

private struct FeaturedAchievementCard: View {
    let achievement: Achievement
    let progress: Double

    @State private var animatedProgress: Double = 0

    private let cardBg = Color(hex: "161616")

    private var categoryColor: Color {
        switch achievement.category {
        case .workout: return Color(hex: "54a0ff")
        case .streak: return Color(hex: "ff6b6b")
        case .strength: return Color(hex: "00d2d3")
        case .social: return Color(hex: "ff6b6b")
        case .milestone: return Color(hex: "1dd1a1")
        case .challenge: return Color(hex: "feca57")
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            // Large progress ring with emoji
            ZStack {
                // Outer glow
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 105, height: 105)
                    .blur(radius: 12)

                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 88, height: 88)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(-90))

                // Inner circle
                Circle()
                    .fill(cardBg)
                    .frame(width: 72, height: 72)

                // Emoji
                Text(achievement.emoji)
                    .font(.system(size: 34))
            }
            .onAppear {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.3)) {
                    animatedProgress = progress
                }
            }

            // Achievement info
            VStack(alignment: .leading, spacing: 8) {
                Text(achievement.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(achievement.achievementDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)

                HStack(spacing: 12) {
                    // Progress percentage
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.15))
                        .clipShape(Capsule())

                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: "feca57"))
                        Text("\(achievement.points) pts")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            VStack {
                LinearGradient(
                    colors: [categoryColor.opacity(0.9), categoryColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct AllAchievementsEarnedCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🏆")
                .font(.system(size: 48))

            Text("All Trophies Earned!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("You've unlocked every achievement. Legendary!")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(0.2),
                            Color(hex: "1C1C1E").opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Trophy Case Section
private struct TrophyCaseSection: View {
    @Query(sort: \Achievement.points, order: .reverse) private var achievements: [Achievement]
    @Query private var userAchievements: [UserAchievement]

    private let goldColor = Color(hex: "feca57")
    private let cardBg = Color(hex: "161616")

    private var earnedAchievements: [Achievement] {
        achievements.filter { achievement in
            userAchievements.first { $0.achievementId == achievement.id }?.isComplete ?? false
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with colored icon
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [goldColor, Color(hex: "ff9f43")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("TROPHY CASE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1.5)
                }

                Spacer()

                Text("\(earnedAchievements.count) earned")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            if earnedAchievements.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.2))
                    Text("Complete challenges to earn trophies")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
            } else {
                // Trophy grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(earnedAchievements.prefix(8), id: \.id) { achievement in
                        TrophyBadge(
                            achievement: achievement,
                            userAchievement: userAchievements.first { $0.achievementId == achievement.id }
                        )
                    }
                }
                .padding(16)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    VStack {
                        LinearGradient(
                            colors: [goldColor, Color(hex: "ff9f43")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 3)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )

                // View all if more than 8
                if earnedAchievements.count > 8 {
                    NavigationLink {
                        AchievementWallView()
                    } label: {
                        HStack {
                            Text("View all \(earnedAchievements.count) trophies")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                        }
                        .foregroundStyle(Color(hex: "54a0ff"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "54a0ff").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}

private struct TrophyBadge: View {
    let achievement: Achievement
    let userAchievement: UserAchievement?

    @State private var isPressed = false
    @State private var showDetail = false

    private var categoryColor: Color {
        switch achievement.category {
        case .workout: return Color(hex: "54a0ff")
        case .streak: return Color(hex: "ff6b6b")
        case .strength: return Color(hex: "00d2d3")
        case .social: return Color(hex: "ff6b6b")
        case .milestone: return Color(hex: "1dd1a1")
        case .challenge: return Color(hex: "feca57")
        }
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(categoryColor.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)

                    // Badge circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.4), categoryColor.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(categoryColor.opacity(0.5), lineWidth: 2)
                        )

                    // Emoji
                    Text(achievement.emoji)
                        .font(.title2)
                }

                Text(achievement.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .sheet(isPresented: $showDetail) {
            AchievementDetailSheet(
                achievement: achievement,
                userAchievement: userAchievement
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - In Progress Section
private struct InProgressSection: View {
    @Query(sort: \Achievement.points, order: .reverse) private var achievements: [Achievement]
    @Query private var userAchievements: [UserAchievement]

    private let cyanColor = Color(hex: "54a0ff")

    private var inProgressAchievements: [(achievement: Achievement, progress: Double)]  {
        achievements.compactMap { achievement in
            guard !achievement.isSecret else { return nil }
            guard let userAchievement = userAchievements.first(where: { $0.achievementId == achievement.id }),
                  !userAchievement.isComplete,
                  userAchievement.progress > 0 else { return nil }

            let progress = achievement.requirement > 0
                ? Double(userAchievement.progress) / Double(achievement.requirement)
                : 0

            return (achievement, progress)
        }
        .sorted { $0.progress > $1.progress }
    }

    var body: some View {
        if !inProgressAchievements.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Section header with colored icon
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [cyanColor, cyanColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("IN PROGRESS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1.5)
                }

                VStack(spacing: 10) {
                    ForEach(inProgressAchievements.prefix(3), id: \.achievement.id) { item in
                        InProgressRow(
                            achievement: item.achievement,
                            progress: item.progress
                        )
                    }
                }
            }
        }
    }
}

private struct InProgressRow: View {
    let achievement: Achievement
    let progress: Double

    private let cardBg = Color(hex: "161616")

    private var categoryColor: Color {
        switch achievement.category {
        case .workout: return Color(hex: "54a0ff")
        case .streak: return Color(hex: "ff6b6b")
        case .strength: return Color(hex: "00d2d3")
        case .social: return Color(hex: "ff6b6b")
        case .milestone: return Color(hex: "1dd1a1")
        case .challenge: return Color(hex: "feca57")
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Emoji badge
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(achievement.emoji)
                    .font(.title3)
            }

            // Info and progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(categoryColor)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [categoryColor, categoryColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Activity Section (Streaks + Recent Workouts)
private struct ActivitySection: View {
    var body: some View {
        VStack(spacing: 20) {
            WeeklyStreakSection()
            RecentWorkoutsSection()
        }
    }
}

private struct WeeklyStreakSection: View {
    @Query private var workoutSessions: [WorkoutSession]

    private let limeColor = Color(hex: "1dd1a1")
    private let cardBg = Color(hex: "161616")

    private var completedSessions: [WorkoutSession] {
        workoutSessions.filter { $0.status == .completed }
    }

    private var weekDays: [(label: String, date: Date, hasWorkout: Bool, isToday: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: today) ?? today
            let weekday = calendar.component(.weekday, from: date) - 1
            let hasWorkout = completedSessions.contains {
                guard let completed = $0.completedAt else { return false }
                return calendar.isDate(completed, inSameDayAs: date)
            }
            let isToday = calendar.isDateInToday(date)
            return (label: dayLabels[weekday], date: date, hasWorkout: hasWorkout, isToday: isToday)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with colored icon
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [limeColor, Color(hex: "10ac84")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("THIS WEEK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(1.5)
            }

            HStack(spacing: 8) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(day.hasWorkout ? limeColor : Color.white.opacity(0.06))
                                .frame(width: 38, height: 38)

                            if day.hasWorkout {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(day.isToday ? Color.white.opacity(0.4) : Color.clear, lineWidth: 2)
                                .frame(width: 42, height: 42)
                        )

                        Text(day.label)
                            .font(.caption2)
                            .fontWeight(day.isToday ? .bold : .regular)
                            .foregroundStyle(day.isToday ? .white : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                VStack {
                    LinearGradient(
                        colors: [limeColor, Color(hex: "10ac84")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct RecentWorkoutsSection: View {
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var workoutSessions: [WorkoutSession]

    private let cyanColor = Color(hex: "54a0ff")
    private let cardBg = Color(hex: "161616")

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
        VStack(alignment: .leading, spacing: 16) {
            // Section header with colored icon
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [cyanColor, Color(hex: "2e86de")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("RECENT WORKOUTS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(1.5)
            }

            if recentWorkouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No workouts yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(recentWorkouts) { session in
                        HStack(spacing: 14) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(cyanColor.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(cyanColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.workout?.name ?? "Workout")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                Text(formatDate(session.completedAt))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }

                            Spacer()

                            Text("\((session.totalDuration ?? 0) / 60) min")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(12)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    VStack {
                        LinearGradient(
                            colors: [cyanColor, Color(hex: "2e86de")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 3)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    ProgressTabView(selectedTab: .constant(.progress))
}
