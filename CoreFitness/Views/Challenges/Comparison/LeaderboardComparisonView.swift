import SwiftUI

struct LeaderboardComparisonView: View {
    let challenge: Challenge
    let participants: [ChallengeParticipant]
    let timeframe: ComparisonTimeframe

    @State private var expandedParticipantId: UUID?

    var sortedParticipants: [ChallengeParticipant] {
        participants.sorted { $0.completedDays > $1.completedDays }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    ChallengeLeaderboardRow(
                        rank: index + 1,
                        participant: participant,
                        challenge: challenge,
                        isExpanded: expandedParticipantId == participant.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                if expandedParticipantId == participant.id {
                                    expandedParticipantId = nil
                                } else {
                                    expandedParticipantId = participant.id
                                }
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Challenge Leaderboard Row

struct ChallengeLeaderboardRow: View {
    let rank: Int
    let participant: ChallengeParticipant
    let challenge: Challenge
    let isExpanded: Bool
    let onTap: () -> Void

    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return .orange
        default: return .accentColor
        }
    }

    var rankIcon: String {
        switch rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "\(rank).circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Row
            HStack(spacing: 16) {
                // Rank Badge
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    if rank <= 3 {
                        Image(systemName: rankIcon)
                            .font(.title3)
                            .foregroundStyle(rankColor)
                    } else {
                        Text("\(rank)")
                            .font(.headline)
                            .foregroundStyle(rankColor)
                    }
                }

                // Avatar
                Text(participant.avatarEmoji)
                    .font(.title2)

                // Name and Stats
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(participant.displayName)
                            .font(.headline)
                        if participant.isOwner {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }

                    HStack(spacing: 12) {
                        Label("\(participant.completedDays) days", systemImage: "checkmark.circle.fill")
                        Label("\(participant.currentStreak) streak", systemImage: "flame.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(participant.completionPercentage * 100))%")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // Expanded Details
            if isExpanded {
                expandedContent
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal)

            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(participant.completedDays)/\(challenge.durationDays) days")
                        .font(.subheadline)
                }

                ProgressView(value: participant.completionPercentage)
                    .tint(.accentColor)
            }
            .padding(.horizontal)

            // Type-specific stats
            typeSpecificStats
                .padding(.horizontal)
                .padding(.bottom)
        }
    }

    @ViewBuilder
    private var typeSpecificStats: some View {
        switch challenge.goalType {
        case .cardio, .endurance:
            cardioStats
        case .strength, .muscle:
            strengthStats
        default:
            generalStats
        }
    }

    private var cardioStats: some View {
        HStack(spacing: 16) {
            ChallengeStatPill(icon: "figure.run", label: "Distance", value: participant.formattedTotalDistance)
            ChallengeStatPill(icon: "clock.fill", label: "Time", value: participant.formattedTotalDuration)
            ChallengeStatPill(icon: "flame.fill", label: "Calories", value: "\(participant.totalCaloriesBurned)")
        }
    }

    private var strengthStats: some View {
        HStack(spacing: 16) {
            ChallengeStatPill(icon: "dumbbell.fill", label: "Weight", value: participant.formattedTotalWeight)
            ChallengeStatPill(icon: "star.fill", label: "PRs", value: "\(participant.prsAchieved)")
            ChallengeStatPill(icon: "clock.fill", label: "Time", value: participant.formattedTotalDuration)
        }
    }

    private var generalStats: some View {
        HStack(spacing: 16) {
            ChallengeStatPill(icon: "clock.fill", label: "Time", value: participant.formattedTotalDuration)
            ChallengeStatPill(icon: "flame.fill", label: "Calories", value: "\(participant.totalCaloriesBurned)")
            ChallengeStatPill(icon: "bolt.fill", label: "Streak", value: "\(participant.longestStreak)")
        }
    }
}

// MARK: - Challenge Stat Pill

struct ChallengeStatPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    LeaderboardComparisonView(
        challenge: Challenge(name: "30-Day Fitness", creatorId: "user123"),
        participants: [],
        timeframe: .allTime
    )
}
