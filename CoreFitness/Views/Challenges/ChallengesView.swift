import SwiftUI
import SwiftData
import Contacts
import ContactsUI

struct ChallengesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]

    @State private var showCreateChallenge = false
    @State private var showJoinChallenge = false
    @State private var selectedChallenge: Challenge?
    @State private var selectedTab = 0

    // Only one active challenge at a time
    private var activeChallenge: Challenge? {
        challenges.first { $0.isActive && !$0.isCompleted }
    }

    private var completedChallenges: [Challenge] {
        challenges.filter { $0.isCompleted }
    }

    // Stats
    private var completedCount: Int {
        completedChallenges.count
    }

    private var bestFinish: String {
        guard completedCount > 0 else { return "--" }
        var bestRank = Int.max
        for challenge in completedChallenges {
            if let rank = challenge.sortedParticipants.firstIndex(where: { $0.oderId == "current_user" }) {
                bestRank = min(bestRank, rank + 1)
            }
        }
        if bestRank == Int.max { return "--" }
        switch bestRank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(bestRank)th"
        }
    }

    private var daysLeft: Int {
        activeChallenge?.daysRemaining ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Active Challenge Hero Section
                    if let challenge = activeChallenge {
                        ActiveChallengeHero(challenge: challenge) {
                            selectedChallenge = challenge
                        }
                    } else {
                        // No Active Challenge - Prompt to start
                        NoActiveChallengeCard {
                            showCreateChallenge = true
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    // Stats Row
                    HStack(spacing: 0) {
                        StatItem(value: "\(completedCount)", label: "Completed", icon: "checkmark.circle.fill", color: .accentGreen)
                        Divider().frame(height: 40)
                        StatItem(value: bestFinish, label: "Best Finish", icon: "trophy.fill", color: .accentOrange)
                        Divider().frame(height: 40)
                        StatItem(value: "\(daysLeft)", label: "Days Left", icon: "calendar", color: .accentBlue)
                    }
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Create",
                            icon: "plus",
                            color: Color(hex: "22c55e")
                        ) {
                            showCreateChallenge = true
                        }

                        ActionButton(
                            title: "Join",
                            icon: "person.badge.plus",
                            color: Color(hex: "3b82f6")
                        ) {
                            showJoinChallenge = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Challenge Details Section (when active challenge exists)
                    if let challenge = activeChallenge {
                        // Leaderboard Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Leaderboard", action: nil) {}

                            VStack(spacing: 8) {
                                ForEach(Array(challenge.sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                                    LeaderboardRowCompact(
                                        rank: index + 1,
                                        participant: participant,
                                        totalDays: challenge.durationDays,
                                        isCurrentUser: participant.oderId == "current_user"
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 24)

                        // Your Stats Section
                        if let userParticipant = challenge.participants?.first(where: { $0.oderId == "current_user" }) {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Your Progress", action: nil) {}

                                YourProgressCard(participant: userParticipant, challenge: challenge)
                                    .padding(.horizontal, 16)
                            }
                            .padding(.top, 24)
                        }

                        // Challenge Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Challenge Info", action: nil) {}

                            ChallengeInfoCard(challenge: challenge)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 24)
                    }

                    // Completed Challenges Section
                    if !completedChallenges.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "History", action: nil) {}

                            VStack(spacing: 12) {
                                ForEach(completedChallenges.prefix(5)) { challenge in
                                    CompletedChallengeRow(challenge: challenge)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 24)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .fullScreenCover(isPresented: $showCreateChallenge) {
            CreateChallengeView()
                .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showJoinChallenge) {
            JoinChallengeView()
                .background(.ultraThinMaterial)
        }
        .fullScreenCover(item: $selectedChallenge) { challenge in
            ChallengeDetailView(challenge: challenge)
                .background(.ultraThinMaterial)
        }
    }

    private func createChallengeFromTemplate(_ template: ChallengeTemplate) {
        if activeChallenge != nil { return }

        let challenge = Challenge(
            name: template.name,
            description: template.description,
            durationDays: template.durationDays,
            goalType: template.goalType,
            location: template.location,
            creatorId: "current_user"
        )

        let participant = ChallengeParticipant(
            oderId: "current_user",
            displayName: "You",
            avatarEmoji: "💪",
            isOwner: true
        )
        participant.challenge = challenge

        modelContext.insert(challenge)
        modelContext.insert(participant)
        try? modelContext.save()

        selectedChallenge = challenge
    }
}

// MARK: - Section Header
private struct SectionHeader: View {
    let title: String
    let action: String?
    let onAction: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Spacer()

            if let action = action {
                Button(action: onAction) {
                    Text(action)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentBlue)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Action Button
private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - No Active Challenge Card
private struct NoActiveChallengeCard: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentOrange.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentOrange)
            }

            Text("No Active Challenge")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Start a challenge to compete with friends and stay motivated")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onCreate) {
                Text("Start Challenge")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentOrange)
                    .clipShape(Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Active Challenge Hero
private struct ActiveChallengeHero: View {
    let challenge: Challenge
    let onTap: () -> Void

    private var progress: Double {
        let elapsed = Date().timeIntervalSince(challenge.startDate)
        let total = Double(challenge.durationDays) * 86400
        return min(max(elapsed / total, 0), 1)
    }

    private var daysRemaining: Int {
        let endDate = challenge.startDate.addingTimeInterval(Double(challenge.durationDays) * 86400)
        let remaining = endDate.timeIntervalSince(Date())
        return max(0, Int(remaining / 86400))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTIVE CHALLENGE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.7))

                        Text(challenge.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(daysRemaining)")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundStyle(.white)
                        Text("days left")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                // Participants
                HStack {
                    HStack(spacing: -8) {
                        ForEach(challenge.sortedParticipants.prefix(4)) { participant in
                            Text(participant.avatarEmoji)
                                .font(.caption)
                                .frame(width: 28, height: 28)
                                .background(.white.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                        }
                    }

                    Text("\(challenge.sortedParticipants.count) participants")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(hex: "f97316"), Color(hex: "ea580c")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Template Card
private struct TemplateCard: View {
    let template: ChallengeTemplate
    let onSelect: () -> Void

    private var iconColor: Color {
        switch template.goalType {
        case .fitness: return Color(hex: "3b82f6")
        case .strength, .muscle: return Color(hex: "f97316")
        case .cardio: return Color(hex: "ef4444")
        case .flexibility: return Color(hex: "06b6d4") // Teal instead of purple
        case .weightLoss, .wellness: return Color(hex: "22c55e")
        case .endurance: return Color(hex: "eab308")
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: template.goalType.icon)
                            .font(.subheadline)
                            .foregroundStyle(iconColor)
                    }

                    Spacer()

                    Text("\(template.durationDays)d")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Capsule())
                }

                Text(template.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 32, alignment: .topLeading)

                Text(template.difficulty.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completed Challenge Row
private struct CompletedChallengeRow: View {
    let challenge: Challenge

    private var resultColor: Color {
        // Check if user won (finished first)
        if challenge.sortedParticipants.first?.oderId == "current_user" {
            return Color(hex: "22c55e")
        }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(resultColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: challenge.sortedParticipants.first?.oderId == "current_user" ? "trophy.fill" : "flag.checkered")
                    .font(.headline)
                    .foregroundStyle(resultColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(challenge.durationDays) days • \(challenge.sortedParticipants.count) participants")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(challenge.startDate.formatted(.dateTime.month().day()))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Challenge Stat Card
struct ChallengeStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.heavy)

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [color.opacity(0.2), color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Active Challenge Card Redesigned
struct ActiveChallengeCardRedesigned: View {
    let challenge: Challenge
    let onTap: () -> Void

    private var goalColor: Color {
        switch challenge.goalType {
        case .fitness: return Color(hex: "3b82f6")
        case .strength, .muscle: return Color(hex: "f97316")
        case .cardio: return Color(hex: "ef4444")
        case .flexibility: return .purple
        case .weightLoss, .wellness: return Color(hex: "22c55e")
        case .endurance: return Color(hex: "eab308")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [goalColor, goalColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: challenge.goalType.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Started \(challenge.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    // Day counter
                    VStack(spacing: 2) {
                        Text("\(challenge.currentDay)")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundStyle(goalColor)

                        Text("of \(challenge.durationDays)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [goalColor, goalColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * challenge.progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(Int(challenge.progress * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer()

                        Text("\(challenge.daysRemaining) days left")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                // Participants
                HStack(spacing: 8) {
                    HStack(spacing: -8) {
                        ForEach(Array(challenge.sortedParticipants.prefix(4).enumerated()), id: \.offset) { _, participant in
                            Text(participant.avatarEmoji)
                                .font(.headline)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: "2a2a3e"))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(hex: "1a1a2e"), lineWidth: 2))
                        }
                    }

                    Text("\(challenge.participants?.count ?? 0) participants")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(20)
            .background(
                ZStack {
                    Color(hex: "1a1a2e")

                    // Glow effect
                    Circle()
                        .fill(goalColor.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: 100, y: -50)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Template Card Redesigned
struct ChallengeTemplateCardRedesigned: View {
    let template: ChallengeTemplate
    let onSelect: () -> Void

    private var goalColor: Color {
        switch template.goalType {
        case .fitness: return Color(hex: "3b82f6")
        case .strength, .muscle: return Color(hex: "f97316")
        case .cardio: return Color(hex: "ef4444")
        case .flexibility: return .purple
        case .weightLoss, .wellness: return Color(hex: "22c55e")
        case .endurance: return Color(hex: "eab308")
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [goalColor, goalColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: template.icon)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text("\(template.durationDays) days")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "22c55e"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "22c55e").opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(template.difficulty.displayName) • \(template.location.displayName)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "1a1a2e"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Leaderboard Preview Card
struct LeaderboardPreviewCard: View {
    let challenge: Challenge

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Leaderboard")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text("View All")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "22c55e"))
            }

            VStack(spacing: 0) {
                ForEach(Array(challenge.sortedParticipants.prefix(3).enumerated()), id: \.element.id) { index, participant in
                    LeaderboardRow(
                        rank: index + 1,
                        participant: participant,
                        totalDays: challenge.durationDays
                    )

                    if index < min(2, challenge.sortedParticipants.count - 1) {
                        Divider()
                            .background(.white.opacity(0.05))
                    }
                }
            }
        }
        .padding(20)
        .background(Color(hex: "1a1a2e"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let rank: Int
    let participant: ChallengeParticipant
    let totalDays: Int

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "eab308")
        case 2: return Color(hex: "9ca3af")
        case 3: return Color(hex: "f97316")
        default: return .clear
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                }

                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(rank <= 3 ? rankColor : .white.opacity(0.5))
            }
            .frame(width: 24)

            // Avatar
            Text(participant.avatarEmoji)
                .font(.title2)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if participant.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(participant.currentStreak) day streak")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            // Percentage
            Text("\(Int(participant.completionPercentage * 100))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: "22c55e"))
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Completed Challenge Card Redesigned
struct CompletedChallengeCardRedesigned: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color(hex: "22c55e"))

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("\(challenge.durationDays) days • \(challenge.participants?.count ?? 0) participants")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "1a1a2e"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Active Challenge Card
struct ActiveChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void

    private var goalColor: Color {
        switch challenge.goalType {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    // Goal icon
                    Image(systemName: challenge.goalType.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(goalColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("Day \(challenge.currentDay) of \(challenge.durationDays)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Participants count
                    HStack(spacing: -8) {
                        ForEach(Array(challenge.sortedParticipants.prefix(3).enumerated()), id: \.offset) { index, participant in
                            Text(participant.avatarEmoji)
                                .font(.title3)
                                .frame(width: 28, height: 28)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        }

                        if (challenge.participants?.count ?? 0) > 3 {
                            Text("+\((challenge.participants?.count ?? 0) - 3)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.gray)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        }
                    }
                }

                // Progress bar
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(goalColor.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(goalColor)
                                .frame(width: geometry.size.width * challenge.progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(Int(challenge.progress * 100))% complete")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(challenge.daysRemaining) days left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Action Button
struct ChallengeActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Template Card
struct ChallengeTemplateCard: View {
    let template: ChallengeTemplate
    let onSelect: () -> Void

    private var goalColor: Color {
        switch template.goalType {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    private var difficultyColor: Color {
        switch template.difficulty {
        case .beginner: return .accentGreen
        case .intermediate: return .accentOrange
        case .advanced: return .accentRed
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                // Icon and duration
                HStack {
                    Image(systemName: template.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(goalColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Text("\(template.durationDays)d")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(goalColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(goalColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Title - fixed height area
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 40, alignment: .topLeading)

                Spacer(minLength: 0)

                // Badges at bottom
                HStack(spacing: 4) {
                    Text(template.difficulty.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(difficultyColor)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Image(systemName: template.location.icon)
                        .font(.caption2)
                    Text(template.location.displayName)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completed Challenge Card
struct CompletedChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("Completed • \(challenge.participants?.count ?? 0) participants")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Create Challenge View
struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedGoal: ChallengeGoalType?
    @State private var selectedTemplate: ChallengeTemplate?
    @State private var startDate = Date()
    @State private var selectedContacts: [SelectedContact] = []
    @State private var showContactPicker = false
    @State private var showConfirmationPopup = false

    // Button animation states
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonGlow: CGFloat = 0.0

    private var filteredTemplates: [ChallengeTemplate] {
        guard let goal = selectedGoal else { return [] }
        return ChallengeTemplate.templates.filter { $0.goalType == goal }
    }

    private func goalColor(_ goal: ChallengeGoalType) -> Color {
        switch goal {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Step 1: Choose Goal
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.accentBlue)
                                    .clipShape(Circle())

                                Text("Choose Your Goal")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(ChallengeGoalType.allCases, id: \.self) { goal in
                                    GoalSelectionCard(
                                        goal: goal,
                                        color: goalColor(goal),
                                        isSelected: selectedGoal == goal
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedGoal == goal {
                                                selectedGoal = nil
                                                selectedTemplate = nil
                                            } else {
                                                selectedGoal = goal
                                                selectedTemplate = nil
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Step 2: Choose Challenge (shown after goal selection)
                        if selectedGoal != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("2")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.accentOrange)
                                        .clipShape(Circle())

                                    Text("Select a Challenge")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }

                                if filteredTemplates.isEmpty {
                                    Text("No challenges available for this goal yet.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(filteredTemplates) { template in
                                            ChallengeOptionCard(
                                                template: template,
                                                color: goalColor(selectedGoal!),
                                                isSelected: selectedTemplate?.id == template.id
                                            ) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedTemplate = template
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Step 3: Start Date (shown after template selection)
                        if selectedTemplate != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("3")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.accentGreen)
                                        .clipShape(Circle())

                                    Text("When to Start?")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }

                                DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(goalColor(selectedGoal!))
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Step 4: Invite Friends (shown after template selection)
                        if selectedTemplate != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("4")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.purple)
                                        .clipShape(Circle())

                                    Text("Invite Friends & Family")
                                        .font(.headline)
                                        .fontWeight(.bold)

                                    Text("(Optional)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                // Selected contacts display
                                if !selectedContacts.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(selectedContacts) { contact in
                                                SelectedContactChip(contact: contact) {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedContacts.removeAll { $0.id == contact.id }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Add friends button
                                Button {
                                    showContactPicker = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.title2)
                                            .foregroundStyle(Color.purple)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Add from Contacts")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)

                                            Text(selectedContacts.isEmpty ? "Challenge your friends and family" : "\(selectedContacts.count) selected • Tap to add more")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top)
                }
                .background(.ultraThinMaterial)

                // Blur overlay and confirmation popup
                if showConfirmationPopup {
                    Color.black.opacity(0.4)
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showConfirmationPopup = false
                            }
                        }

                    ChallengeConfirmationPopup(
                        template: selectedTemplate,
                        startDate: startDate,
                        selectedContacts: selectedContacts,
                        goalColor: selectedGoal != nil ? goalColor(selectedGoal!) : .accentBlue,
                        onConfirm: {
                            createChallenge()
                        },
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showConfirmationPopup = false
                            }
                        }
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if selectedTemplate != nil {
                    Button {
                        // Animate button press
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                            buttonScale = 0.95
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                buttonScale = 1.05
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                buttonScale = 1.0
                            }
                            // Show confirmation popup
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showConfirmationPopup = true
                            }
                        }

                        themeManager.mediumImpact()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.headline)
                            Text("Create Challenge")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ZStack {
                                goalColor(selectedGoal!)

                                // Glow effect
                                goalColor(selectedGoal!)
                                    .blur(radius: 20)
                                    .opacity(buttonGlow)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: goalColor(selectedGoal!).opacity(0.4), radius: 8, y: 4)
                    }
                    .scaleEffect(buttonScale)
                    .padding()
                    .background(.ultraThinMaterial)
                    .onAppear {
                        startButtonGlowAnimation()
                    }
                }
            }
            .fullScreenCover(isPresented: $showContactPicker) {
                ContactPickerView(selectedContacts: $selectedContacts)
            }
        }
    }

    private func startButtonGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatCount(3, autoreverses: true)) {
            buttonGlow = 0.3
        }
        // Settle to subtle glow after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                buttonGlow = 0.15
            }
        }
    }

    private func createChallenge() {
        guard let template = selectedTemplate else { return }

        let challenge = Challenge(
            name: template.name,
            description: template.description,
            durationDays: template.durationDays,
            startDate: startDate,
            goalType: template.goalType,
            location: .anywhere,
            creatorId: "current_user"
        )

        // Add current user as owner
        let ownerParticipant = ChallengeParticipant(
            oderId: "current_user",
            displayName: "You",
            avatarEmoji: "💪",
            isOwner: true
        )
        ownerParticipant.challenge = challenge
        modelContext.insert(ownerParticipant)

        // Add selected contacts as participants
        let emojis = ["😀", "🎯", "🔥", "⭐️", "🚀", "💫", "🌟", "✨"]
        for (index, contact) in selectedContacts.prefix(5).enumerated() {
            let participant = ChallengeParticipant(
                oderId: contact.id,
                displayName: contact.name,
                avatarEmoji: emojis[index % emojis.count],
                isOwner: false
            )
            participant.challenge = challenge
            modelContext.insert(participant)
        }

        modelContext.insert(challenge)
        try? modelContext.save()

        themeManager.notifySuccess()

        dismiss()
    }
}

// MARK: - Selected Contact Model
struct SelectedContact: Identifiable, Equatable {
    let id: String
    let name: String
    let initials: String
}

// MARK: - Selected Contact Chip
struct SelectedContactChip: View {
    let contact: SelectedContact
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(contact.initials)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.purple)
                .clipShape(Circle())

            Text(contact.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Contact Picker View
struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedContacts: [SelectedContact]

    @State private var contacts: [CNContact] = []
    @State private var searchText = ""
    @State private var hasPermission = false
    @State private var showPermissionDenied = false

    private let maxFriends = 5

    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
            return fullName.contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selection counter header
                HStack {
                    Text("Selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(selectedContacts.count)/\(maxFriends)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(selectedContacts.count == maxFriends ? .orange : .accentColor)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Group {
                    if showPermissionDenied {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text("Contacts Access Required")
                                .font(.headline)

                            Text("Please enable contacts access in Settings to invite friends to your challenge.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredContacts, id: \.identifier) { contact in
                                ContactRow(
                                    contact: contact,
                                    isSelected: selectedContacts.contains { $0.id == contact.identifier },
                                    isDisabled: !selectedContacts.contains { $0.id == contact.identifier } && selectedContacts.count >= maxFriends
                                ) {
                                    toggleContact(contact)
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search contacts")
                    }
                }
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Select Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            requestContactsPermission()
        }
    }

    private func requestContactsPermission() {
        let store = CNContactStore()

        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    hasPermission = true
                    loadContacts()
                } else {
                    showPermissionDenied = true
                }
            }
        }
    }

    private func loadContacts() {
        let store = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName

        var fetchedContacts: [CNContact] = []

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                if !contact.givenName.isEmpty || !contact.familyName.isEmpty {
                    fetchedContacts.append(contact)
                }
            }
            contacts = fetchedContacts
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }

    private func toggleContact(_ contact: CNContact) {
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let initials = "\(contact.givenName.prefix(1))\(contact.familyName.prefix(1))".uppercased()

        if let index = selectedContacts.firstIndex(where: { $0.id == contact.identifier }) {
            selectedContacts.remove(at: index)
        } else if selectedContacts.count < 5 {
            let selectedContact = SelectedContact(
                id: contact.identifier,
                name: fullName,
                initials: initials.isEmpty ? "?" : initials
            )
            selectedContacts.append(selectedContact)
        }

        themeManager.lightImpact()
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    var isDisabled: Bool = false
    let onTap: () -> Void

    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }

    private var initials: String {
        let first = contact.givenName.prefix(1)
        let last = contact.familyName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(initials)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(isDisabled ? Color.gray.opacity(0.5) : Color.purple.opacity(0.8))
                    .clipShape(Circle())

                Text(fullName)
                    .font(.body)
                    .foregroundStyle(isDisabled ? .secondary : .primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.purple : (isDisabled ? Color.gray.opacity(0.2) : Color.gray.opacity(0.3)))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Challenge Confirmation Popup
struct ChallengeConfirmationPopup: View {
    let template: ChallengeTemplate?
    let startDate: Date
    let selectedContacts: [SelectedContact]
    let goalColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 20) {
            // Header icon
            ZStack {
                Circle()
                    .fill(goalColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: template?.icon ?? "star.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(goalColor)
            }
            .scaleEffect(animateIn ? 1 : 0.5)
            .opacity(animateIn ? 1 : 0)

            // Challenge name
            Text(template?.name ?? "Challenge")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Details
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(goalColor)
                    Text("Starts \(startDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                    Spacer()
                }

                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(goalColor)
                    Text("\(template?.durationDays ?? 0) days")
                        .font(.subheadline)
                    Spacer()
                }

                HStack {
                    Image(systemName: "person.2")
                        .foregroundStyle(goalColor)
                    Text(selectedContacts.isEmpty ? "Just you" : "You + \(selectedContacts.count) friend\(selectedContacts.count == 1 ? "" : "s")")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Participants preview
            if !selectedContacts.isEmpty {
                HStack(spacing: -8) {
                    Text("💪")
                        .font(.title2)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))

                    ForEach(Array(selectedContacts.prefix(4).enumerated()), id: \.element.id) { index, contact in
                        Text(contact.initials)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.purple)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    }
                }
            }

            // Buttons
            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    HStack {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                        Text("Let's Go!")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(goalColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onCancel) {
                    Text("Go Back")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Goal Selection Card
struct GoalSelectionCard: View {
    let goal: ChallengeGoalType
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)

                Text(goal.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? color : color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Option Card
struct ChallengeOptionCard: View {
    let template: ChallengeTemplate
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? color : color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label("\(template.durationDays) days", systemImage: "calendar")
                        Label(template.difficulty.displayName, systemImage: "chart.bar.fill")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : Color.gray.opacity(0.3))
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Join Challenge View
struct JoinChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var inviteCode = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentGreen)
                }
                .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Join a Challenge")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter the 6-character invite code shared by your friend.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Code input
                TextField("INVITE CODE", text: $inviteCode)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                    .onChange(of: inviteCode) { _, newValue in
                        inviteCode = String(newValue.prefix(6)).uppercased()
                    }

                Spacer()

                Button {
                    joinChallenge()
                } label: {
                    Text("Join Challenge")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(inviteCode.count == 6 ? Color.accentGreen : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(inviteCode.count != 6)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(.ultraThinMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func joinChallenge() {
        // Query iCloud for shared challenges, fallback to local
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { $0.inviteCode == inviteCode }
        )

        if let challenges = try? modelContext.fetch(descriptor),
           let challenge = challenges.first {
            // Check if already a participant
            let currentUserId = "current_user"
            if challenge.participants?.contains(where: { $0.oderId == currentUserId }) == true {
                errorMessage = "You're already in this challenge!"
                showError = true
                return
            }

            // Check participant limit (5 + owner = 6 max)
            if (challenge.participants?.count ?? 0) >= 6 {
                errorMessage = "This challenge is full (max 6 participants)."
                showError = true
                return
            }

            // Add participant
            let participant = ChallengeParticipant(
                oderId: currentUserId,
                displayName: "You",
                avatarEmoji: ["😀", "🎯", "🔥", "⭐️", "🚀"].randomElement()!,
                isOwner: false
            )
            participant.challenge = challenge

            modelContext.insert(participant)
            try? modelContext.save()

            dismiss()
        } else {
            errorMessage = "Challenge not found. Please check the code and try again."
            showError = true
        }
    }
}

// MARK: - Challenge Detail View
struct ChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    let challenge: Challenge

    @State private var showShareSheet = false
    @State private var showLeaveConfirmation = false

    private var currentUserParticipant: ChallengeParticipant? {
        challenge.participants?.first { $0.oderId == "current_user" }
    }

    private var goalColor: Color {
        switch challenge.goalType {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero card
                    VStack(spacing: 16) {
                        // Icon and progress
                        ZStack {
                            Circle()
                                .stroke(goalColor.opacity(0.2), lineWidth: 8)
                                .frame(width: 100, height: 100)

                            Circle()
                                .trim(from: 0, to: challenge.progress)
                                .stroke(goalColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                Text("Day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(challenge.currentDay)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }

                        Text(challenge.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        // Stats row
                        HStack(spacing: 24) {
                            VStack {
                                Text("\(challenge.durationDays)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Total Days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack {
                                Text("\(challenge.daysRemaining)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack {
                                Text("\(challenge.participants?.count ?? 0)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Participants")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Today's check-in
                    if !challenge.isCompleted {
                        TodayCheckInCard(
                            challenge: challenge,
                            participant: currentUserParticipant,
                            goalColor: goalColor
                        )
                        .padding(.horizontal)
                    }

                    // Leaderboard
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Leaderboard")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(Array(challenge.sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                                ParticipantRow(
                                    rank: index + 1,
                                    participant: participant,
                                    totalDays: challenge.durationDays,
                                    isCurrentUser: participant.oderId == "current_user"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Invite section
                    VStack(spacing: 12) {
                        Text("Invite Friends")
                            .font(.headline)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            Text(challenge.inviteCode)
                                .font(.title2)
                                .fontWeight(.bold)
                                .tracking(4)

                            Button {
                                UIPasteboard.general.string = challenge.inviteCode
                                themeManager.mediumImpact()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.title3)
                                    .foregroundStyle(Color.accentBlue)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("Share this code with up to 5 friends")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(.ultraThinMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
        }
    }
}

// MARK: - Today Check-In Card
struct TodayCheckInCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    let challenge: Challenge
    let participant: ChallengeParticipant?
    let goalColor: Color

    @State private var hasCheckedInToday = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(challenge.currentDay) Check-In")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(hasCheckedInToday ? "Completed!" : "Mark today as complete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    checkInToday()
                } label: {
                    Image(systemName: hasCheckedInToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 44))
                        .foregroundStyle(hasCheckedInToday ? Color.accentGreen : goalColor.opacity(0.3))
                }
                .disabled(hasCheckedInToday)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            checkTodayStatus()
        }
    }

    private func checkTodayStatus() {
        guard let participant = participant else { return }
        hasCheckedInToday = participant.dayLogs?.contains { $0.dayNumber == challenge.currentDay && $0.isCompleted } ?? false
    }

    private func checkInToday() {
        guard let participant = participant else { return }

        let dayLog = ChallengeDayLog(dayNumber: challenge.currentDay, isCompleted: true)
        dayLog.participant = participant

        participant.logDay(day: challenge.currentDay, completed: true)

        modelContext.insert(dayLog)
        try? modelContext.save()

        hasCheckedInToday = true

        themeManager.notifySuccess()
    }
}

// MARK: - Participant Row
struct ParticipantRow: View {
    let rank: Int
    let participant: ChallengeParticipant
    let totalDays: Int
    let isCurrentUser: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                }

                Text("\(rank)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(rank <= 3 ? rankColor : .secondary)
            }
            .frame(width: 28)

            // Avatar
            Text(participant.avatarEmoji)
                .font(.title2)

            // Name and stats
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(participant.displayName)
                        .font(.subheadline)
                        .fontWeight(isCurrentUser ? .bold : .medium)

                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(participant.completedDays)/\(totalDays) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Streak
            if participant.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("\(participant.currentStreak)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            // Progress
            Text("\(Int(participant.completionPercentage * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.accentGreen)
        }
        .padding()
        .background(isCurrentUser ? Color.accentBlue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Leaderboard Row Compact
private struct LeaderboardRowCompact: View {
    let rank: Int
    let participant: ChallengeParticipant
    let totalDays: Int
    let isCurrentUser: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "eab308") // Gold
        case 2: return Color(hex: "9ca3af") // Silver
        case 3: return Color(hex: "f97316") // Bronze
        default: return .secondary
        }
    }

    private var rankIcon: String? {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    if let icon = rankIcon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(rankColor)
                    }
                } else {
                    Text("\(rank)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                }
            }

            // Avatar
            Text(participant.avatarEmoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Circle())

            // Name and streak
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(participant.displayName)
                        .font(.subheadline)
                        .fontWeight(isCurrentUser ? .bold : .medium)

                    if isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentBlue)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 4) {
                    if participant.currentStreak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(participant.currentStreak) day streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(participant.completedDays) days completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Progress
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(participant.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(rank == 1 ? rankColor : Color.accentGreen)

                Text("\(participant.completedDays)/\(totalDays)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(isCurrentUser ? Color.accentBlue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrentUser ? Color.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Your Progress Card
private struct YourProgressCard: View {
    let participant: ChallengeParticipant
    let challenge: Challenge

    var body: some View {
        VStack(spacing: 16) {
            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProgressStatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(participant.completedDays)",
                    label: "Days Done",
                    color: .accentGreen
                )

                ProgressStatItem(
                    icon: "flame.fill",
                    value: "\(participant.currentStreak)",
                    label: "Streak",
                    color: .orange
                )

                ProgressStatItem(
                    icon: "trophy.fill",
                    value: "\(participant.longestStreak)",
                    label: "Best Streak",
                    color: .yellow
                )
            }

            Divider()

            // Type-specific stats
            switch challenge.goalType {
            case .cardio, .endurance:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProgressStatItem(
                        icon: "figure.run",
                        value: participant.formattedTotalDistance,
                        label: "Distance",
                        color: .accentBlue
                    )
                    ProgressStatItem(
                        icon: "clock.fill",
                        value: participant.formattedTotalDuration,
                        label: "Total Time",
                        color: .purple
                    )
                }
            case .strength, .muscle:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProgressStatItem(
                        icon: "dumbbell.fill",
                        value: participant.formattedTotalWeight,
                        label: "Lifted",
                        color: .accentOrange
                    )
                    ProgressStatItem(
                        icon: "star.fill",
                        value: "\(participant.prsAchieved ?? 0)",
                        label: "PRs",
                        color: .yellow
                    )
                }
            default:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProgressStatItem(
                        icon: "clock.fill",
                        value: participant.formattedTotalDuration,
                        label: "Total Time",
                        color: .purple
                    )
                    ProgressStatItem(
                        icon: "flame.fill",
                        value: "\(participant.totalCaloriesBurned ?? 0)",
                        label: "Calories",
                        color: .accentRed
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Progress Stat Item
private struct ProgressStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Challenge Info Card
private struct ChallengeInfoCard: View {
    let challenge: Challenge

    private var goalColor: Color {
        switch challenge.goalType {
        case .fitness: return .accentBlue
        case .strength, .muscle: return .accentOrange
        case .cardio: return .accentRed
        case .flexibility: return .purple
        case .weightLoss, .wellness: return .accentGreen
        case .endurance: return .accentYellow
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Goal type and location
            HStack(spacing: 16) {
                // Goal type
                HStack(spacing: 8) {
                    Image(systemName: challenge.goalType.icon)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(goalColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(challenge.goalType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                // Location
                HStack(spacing: 8) {
                    Image(systemName: challenge.location.icon)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.accentTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(challenge.location.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }

            Divider()

            // Dates
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(challenge.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(challenge.endDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Description if available
            if !challenge.challengeDescription.isEmpty {
                Divider()

                Text(challenge.challengeDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Invite code
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite Code")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(challenge.inviteCode)
                        .font(.headline)
                        .fontWeight(.bold)
                        .tracking(2)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = challenge.inviteCode
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ChallengesView()
}
