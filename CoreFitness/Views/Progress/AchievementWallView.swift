import SwiftUI
import SwiftData

struct AchievementWallView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Achievement.points, order: .reverse) private var achievements: [Achievement]
    @Query private var userAchievements: [UserAchievement]

    @State private var selectedCategory: AchievementCategory?
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score Header
                ScoreHeaderView(
                    earnedCount: earnedCount,
                    totalCount: totalCount,
                    totalPoints: totalPoints,
                    earnedPoints: earnedPoints
                )

                // Category Filter
                CategoryFilterView(selectedCategory: $selectedCategory)

                // Achievement Grid
                AchievementGridView(
                    achievements: filteredAchievements,
                    userAchievements: userAchievements
                )
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Achievement Wall")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    generateShareImage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [
                    image,
                    "Check out my achievements on CoreFitness! 💪"
                ])
            } else {
                ShareSheet(items: [
                    "I've unlocked \(earnedCount) achievements and earned \(earnedPoints) points on CoreFitness! 🏆"
                ])
            }
        }
    }

    // MARK: - Computed Properties

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

    private var totalPoints: Int {
        achievements.reduce(0) { $0 + $1.points }
    }

    private var filteredAchievements: [Achievement] {
        let visibleAchievements = achievements.filter { !$0.isSecret || isAchievementEarned($0.id) }

        if let category = selectedCategory {
            return visibleAchievements.filter { $0.category == category }
        }
        return visibleAchievements
    }

    private func isAchievementEarned(_ id: String) -> Bool {
        userAchievements.first { $0.achievementId == id }?.isComplete ?? false
    }

    // MARK: - Share Image Generation

    @MainActor
    private func generateShareImage() {
        let earnedAchievements = achievements.filter { isAchievementEarned($0.id) }

        let shareCard = AchievementShareCardView(
            earnedCount: earnedCount,
            totalCount: achievements.count,
            earnedPoints: earnedPoints,
            totalPoints: totalPoints,
            topAchievements: Array(earnedAchievements.prefix(6))
        )
        .frame(width: 320)
        .background(Color.white)

        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            shareImage = image
            DispatchQueue.main.async {
                self.showShareSheet = true
            }
        } else {
            // Fallback: Share text if image generation fails
            let text = "I've unlocked \(earnedCount) achievements and earned \(earnedPoints) points on CoreFitness!"
            shareImage = nil
            // Create a simple fallback
            let fallbackView = Text(text)
                .padding()
                .background(Color.white)
            let fallbackRenderer = ImageRenderer(content: fallbackView)
            fallbackRenderer.scale = UIScreen.main.scale
            if let fallbackImage = fallbackRenderer.uiImage {
                shareImage = fallbackImage
                DispatchQueue.main.async {
                    self.showShareSheet = true
                }
            }
        }
    }
}

// MARK: - Score Header View

struct ScoreHeaderView: View {
    let earnedCount: Int
    let totalCount: Int
    let totalPoints: Int
    let earnedPoints: Int

    var body: some View {
        VStack(spacing: 20) {
            // Trophy and Score
            HStack(spacing: 16) {
                // Trophy Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentYellow, Color.accentOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.accentYellow.opacity(0.4), radius: 12, y: 4)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(earnedCount) / \(totalCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    Text("Achievements Unlocked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentYellow, Color.accentOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progressPercentage, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(Int(progressPercentage * 100))% Complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accentYellow)
                        Text("\(earnedPoints) / \(totalPoints) pts")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(earnedCount) / Double(totalCount)
    }
}

// MARK: - Category Filter View

struct CategoryFilterView: View {
    @Binding var selectedCategory: AchievementCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.brandPrimary : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Grid View

struct AchievementGridView: View {
    let achievements: [Achievement]
    let userAchievements: [UserAchievement]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Sort with earned achievements first
    private var sortedAchievements: [Achievement] {
        achievements.sorted { a, b in
            let aEarned = userAchievements.first { $0.achievementId == a.id }?.isComplete ?? false
            let bEarned = userAchievements.first { $0.achievementId == b.id }?.isComplete ?? false

            if aEarned != bEarned {
                return aEarned // Earned first
            }
            // Then by points (higher first)
            return a.points > b.points
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(sortedAchievements, id: \.id) { achievement in
                AchievementTileView(
                    achievement: achievement,
                    userAchievement: userAchievements.first { $0.achievementId == achievement.id }
                )
            }
        }
    }
}

struct AchievementTileView: View {
    let achievement: Achievement
    let userAchievement: UserAchievement?

    @State private var showDetail = false

    private var isEarned: Bool {
        userAchievement?.isComplete ?? false
    }

    private var progress: Double {
        guard let ua = userAchievement, achievement.requirement > 0 else { return 0 }
        return min(1.0, Double(ua.progress) / Double(achievement.requirement))
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 10) {
                // Badge Circle
                ZStack {
                    // Background circle with glow for earned
                    Circle()
                        .fill(isEarned ? badgeGradient : lockedGradient)
                        .frame(width: 70, height: 70)
                        .shadow(color: isEarned ? shadowColor.opacity(0.5) : .clear, radius: 8, y: 2)

                    // Progress ring for unearned
                    if !isEarned && progress > 0 {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 3)
                            .frame(width: 70, height: 70)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.brandPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                    }

                    // Emoji
                    Text(achievement.emoji)
                        .font(.system(size: 30))
                        .opacity(isEarned ? 1 : 0.4)
                        .grayscale(isEarned ? 0 : 0.8)

                    // Lock overlay for locked
                    if !isEarned && progress == 0 {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 70, height: 70)

                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Title
                Text(achievement.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isEarned ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 30)

                // Points
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                    Text("\(achievement.points)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(isEarned ? Color.accentYellow : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            AchievementDetailSheet(
                achievement: achievement,
                userAchievement: userAchievement
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(
            colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var lockedGradient: LinearGradient {
        LinearGradient(
            colors: [Color(.systemGray5), Color(.systemGray6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .workout: return .blue
        case .streak: return .orange
        case .strength: return .purple
        case .social: return .pink
        case .milestone: return .green
        case .challenge: return .yellow
        }
    }

    private var shadowColor: Color {
        categoryColor
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    let userAchievement: UserAchievement?

    @Environment(\.dismiss) private var dismiss

    private var isEarned: Bool {
        userAchievement?.isComplete ?? false
    }

    private var progress: Int {
        userAchievement?.progress ?? 0
    }

    var body: some View {
        VStack(spacing: 24) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)

            // Large Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isEarned
                                ? [Color.accentYellow, Color.accentOrange]
                                : [Color(.systemGray4), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: isEarned ? Color.accentYellow.opacity(0.4) : .clear, radius: 20, y: 8)

                Text(achievement.emoji)
                    .font(.system(size: 56))
                    .opacity(isEarned ? 1 : 0.5)
                    .grayscale(isEarned ? 0 : 0.8)
            }

            // Title and Description
            VStack(spacing: 8) {
                Text(achievement.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(achievement.achievementDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Progress or Earned Date
            if isEarned {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Unlocked")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    if let earnedAt = userAchievement?.earnedAt {
                        Text(earnedAt.formatted(date: .long, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brandPrimary)
                                .frame(width: geo.size.width * progressPercentage, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(progress) / \(achievement.requirement)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Points
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.accentYellow)
                Text("\(achievement.points) points")
                    .fontWeight(.semibold)
            }
            .font(.headline)

            Spacer()
        }
        .padding()
    }

    private var progressPercentage: Double {
        guard achievement.requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(achievement.requirement))
    }
}

// MARK: - Share Card View (for image generation)

struct AchievementShareCardView: View {
    let earnedCount: Int
    let totalCount: Int
    let earnedPoints: Int
    let totalPoints: Int
    let topAchievements: [Achievement]

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(spacing: 16) {
                // App branding
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3)
                    Text("CoreFitness")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white.opacity(0.9))

                // Trophy and Score
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }

                    Text("Achievement Wall")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                // Stats
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(earnedCount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Unlocked")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("\(earnedPoints)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Points")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .foregroundStyle(.white)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.3),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Achievement badges
            VStack(spacing: 16) {
                if topAchievements.isEmpty {
                    Text("Start earning achievements!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 24)
                } else {
                    Text("Top Achievements")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 4)

                    // Grid of achievements
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(topAchievements.prefix(6), id: \.id) { achievement in
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)

                                    Text(achievement.emoji)
                                        .font(.title2)
                                }

                                Text(achievement.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(width: 70)
                            }
                        }
                    }
                }

                // Progress
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progressPercentage, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(progressPercentage * 100))% Complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color.white)

            // Footer
            HStack {
                Text("corefitness.app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
        }
        .frame(width: 320)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }

    private var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(earnedCount) / Double(totalCount)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        AchievementWallView()
    }
}
