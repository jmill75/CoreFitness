import SwiftUI

struct SideBySideComparisonView: View {
    let challenge: Challenge
    let participants: [ChallengeParticipant]
    let timeframe: ComparisonTimeframe

    @State private var selectedParticipants: Set<UUID> = []

    var selectedList: [ChallengeParticipant] {
        participants.filter { selectedParticipants.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Participant Selector
            participantSelector

            // Comparison Cards
            if selectedList.isEmpty {
                emptyState
            } else {
                comparisonCards
            }
        }
    }

    // MARK: - Participant Selector

    private var participantSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(participants) { participant in
                    let isSelected = selectedParticipants.contains(participant.id)

                    Button {
                        if isSelected {
                            selectedParticipants.remove(participant.id)
                        } else if selectedParticipants.count < 3 {
                            selectedParticipants.insert(participant.id)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(participant.avatarEmoji)
                            Text(participant.displayName)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? .clear : Color(.separator), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Select Participants")
                .font(.headline)
            Text("Tap up to 3 participants above to compare their progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Comparison Cards

    private var comparisonCards: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 12) {
                ForEach(selectedList) { participant in
                    ParticipantComparisonCard(
                        participant: participant,
                        challenge: challenge
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Participant Comparison Card

struct ParticipantComparisonCard: View {
    let participant: ChallengeParticipant
    let challenge: Challenge

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text(participant.avatarEmoji)
                    .font(.largeTitle)

                Text(participant.displayName)
                    .font(.headline)
                    .lineLimit(1)

                if participant.isOwner {
                    Label("Owner", systemImage: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }

            Divider()

            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: participant.completionPercentage)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(participant.completionPercentage * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("complete")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)

            Divider()

            // Stats
            VStack(spacing: 12) {
                ComparisonStatRow(icon: "checkmark.circle.fill", label: "Days", value: "\(participant.completedDays)")
                ComparisonStatRow(icon: "flame.fill", label: "Streak", value: "\(participant.currentStreak)")
                ComparisonStatRow(icon: "trophy.fill", label: "Best", value: "\(participant.longestStreak)")

                // Type-specific stats
                typeSpecificStats
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var typeSpecificStats: some View {
        switch challenge.goalType {
        case .cardio, .endurance:
            VStack(spacing: 12) {
                ComparisonStatRow(icon: "figure.run", label: "Distance", value: participant.formattedTotalDistance)
                ComparisonStatRow(icon: "clock.fill", label: "Time", value: participant.formattedTotalDuration)
            }
        case .strength, .muscle:
            VStack(spacing: 12) {
                ComparisonStatRow(icon: "dumbbell.fill", label: "Weight", value: participant.formattedTotalWeight)
                ComparisonStatRow(icon: "star.fill", label: "PRs", value: "\(participant.prsAchieved)")
            }
        default:
            VStack(spacing: 12) {
                ComparisonStatRow(icon: "clock.fill", label: "Time", value: participant.formattedTotalDuration)
                ComparisonStatRow(icon: "bolt.fill", label: "Calories", value: "\(participant.totalCaloriesBurned)")
            }
        }
    }
}

// MARK: - Comparison Stat Row

struct ComparisonStatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    SideBySideComparisonView(
        challenge: Challenge(name: "30-Day Fitness", creatorId: "user123"),
        participants: [],
        timeframe: .allTime
    )
}
