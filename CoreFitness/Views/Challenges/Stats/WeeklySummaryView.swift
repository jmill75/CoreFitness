import SwiftUI
import Charts

struct WeeklySummaryView: View {
    let participant: ChallengeParticipant
    let challenge: Challenge

    var weeklySummaries: [ChallengeWeeklySummary] {
        participant.weeklySummaries?.sorted { $0.weekNumber < $1.weekNumber } ?? []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Progress
                overallProgressCard

                // Weekly Breakdown
                if weeklySummaries.isEmpty {
                    emptyState
                } else {
                    ForEach(weeklySummaries) { summary in
                        WeekCard(summary: summary, challenge: challenge)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weekly Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overall Progress Card

    private var overallProgressCard: some View {
        VStack(spacing: 16) {
            Text("Challenge Overview")
                .font(.headline)

            HStack(spacing: 20) {
                overallStat(
                    value: "\(participant.completedDays)",
                    label: "Days",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                overallStat(
                    value: participant.formattedTotalDuration,
                    label: "Total Time",
                    icon: "clock.fill",
                    color: .blue
                )

                overallStat(
                    value: "\(participant.totalCaloriesBurned)",
                    label: "Calories",
                    icon: "flame.fill",
                    color: .orange
                )
            }

            // Progress comparison chart
            if !weeklySummaries.isEmpty {
                weeklyComparisonChart
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func overallStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weekly Comparison Chart

    private var weeklyComparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Days Completed Per Week")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(weeklySummaries) { summary in
                BarMark(
                    x: .value("Week", "W\(summary.weekNumber)"),
                    y: .value("Days", summary.completedDays)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...7)
            .frame(height: 120)
        }
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Weekly Data Yet")
                .font(.headline)

            Text("Complete more days to see your weekly summaries")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Week Card

struct WeekCard: View {
    let summary: ChallengeWeeklySummary
    let challenge: Challenge

    @State private var isExpanded = false

    var completionRate: Double {
        Double(summary.completedDays) / 7.0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    // Week Badge
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 50, height: 50)

                        VStack(spacing: 0) {
                            Text("W\(summary.weekNumber)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }

                    // Week Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week \(summary.weekNumber)")
                            .font(.headline)

                        Text(dateRangeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Completion
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(summary.completedDays)/7")
                            .font(.headline)
                            .foregroundStyle(summary.completedDays >= 5 ? .green : .primary)

                        Text("days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Expanded Content
            if isExpanded {
                expandedContent
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: summary.startDate)
        let end = formatter.string(from: summary.endDate)
        return "\(start) - \(end)"
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal)

            // Day Dots
            dayDots

            // Stats Grid
            statsGrid

            // Comparison to previous week
            comparisonSection
        }
        .padding(.bottom)
    }

    private var dayDots: some View {
        HStack(spacing: 8) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 24, height: 24)
                        .opacity(0.7) // Would check actual completion

                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            weekStat(icon: "clock.fill", label: "Time", value: summary.formattedTotalDuration, color: .blue)
            weekStat(icon: "flame.fill", label: "Calories", value: "\(summary.totalCaloriesBurned)", color: .orange)

            // Type-specific stats
            typeSpecificStats
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var typeSpecificStats: some View {
        switch challenge.goalType {
        case .cardio, .endurance:
            weekStat(
                icon: "figure.run",
                label: "Distance",
                value: String(format: "%.1f mi", summary.totalDistanceMiles),
                color: .green
            )
            if let avgHR = summary.averageHeartRate {
                weekStat(icon: "heart.fill", label: "Avg HR", value: "\(avgHR) bpm", color: .red)
            }
        case .strength, .muscle:
            weekStat(
                icon: "dumbbell.fill",
                label: "Weight",
                value: formatWeight(summary.totalWeightLifted),
                color: .purple
            )
        default:
            EmptyView()
        }
    }

    private func weekStat(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var comparisonSection: some View {
        HStack {
            Image(systemName: summary.completedDays >= 5 ? "arrow.up.right" : "arrow.down.right")
                .foregroundStyle(summary.completedDays >= 5 ? .green : .red)

            Text(summary.completedDays >= 5 ? "Great week! You hit your goals." : "Keep pushing! You can do better next week.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight >= 1000 {
            return String(format: "%.1fK lbs", weight / 1000)
        }
        return String(format: "%.0f lbs", weight)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeeklySummaryView(
            participant: ChallengeParticipant(oderId: "user123", displayName: "You", isOwner: true),
            challenge: Challenge(name: "30-Day Fitness", creatorId: "user123")
        )
    }
}
