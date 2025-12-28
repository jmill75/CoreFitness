import SwiftUI
import Charts

struct ChallengeStatsView: View {
    let challenge: Challenge
    let participant: ChallengeParticipant

    @State private var selectedPeriod: StatsPeriod = .daily

    enum StatsPeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview Card
                overviewCard

                // Period Selector
                periodSelector

                // Progress Chart
                progressChart

                // Type-specific highlights
                highlightsSection

                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Your Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(spacing: 16) {
            // Progress Ring
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: participant.completionPercentage)
                        .stroke(
                            AngularGradient(
                                colors: [.accentColor, .accentColor.opacity(0.5)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(participant.completionPercentage * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 12) {
                    StatRow(icon: "checkmark.circle.fill", label: "Days", value: "\(participant.completedDays)/\(challenge.durationDays)", color: .green)
                    StatRow(icon: "flame.fill", label: "Current Streak", value: "\(participant.currentStreak) days", color: .orange)
                    StatRow(icon: "trophy.fill", label: "Best Streak", value: "\(participant.longestStreak) days", color: .yellow)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Over Time")
                .font(.headline)

            // Chart using actual day logs from participant
            Chart {
                ForEach(chartData, id: \.day) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Completed", data.completed ? 1 : 0)
                    )
                    .foregroundStyle(data.completed ? Color.accentColor : Color(.tertiarySystemFill))
                    .cornerRadius(4)
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Get chart data from actual day logs
    private var chartData: [(day: String, completed: Bool)] {
        // Get the days of the week starting from challenge start
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()

        // Create a set of completed day numbers for quick lookup
        let completedDayNumbers = Set(
            (participant.dayLogs ?? [])
                .filter { $0.isCompleted }
                .map { $0.dayNumber }
        )

        // Generate last 7 days data based on challenge timeline
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        var result: [(day: String, completed: Bool)] = []

        // Map current week to challenge days
        for dayIndex in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayIndex, to: startOfWeek) else { continue }
            let weekday = calendar.component(.weekday, from: date) - 1 // 0 = Sunday
            let dayLabel = dayLabels[weekday]

            // Calculate which challenge day this corresponds to
            let daysSinceStart = calendar.dateComponents([.day], from: challenge.startDate, to: date).day ?? 0
            let challengeDay = daysSinceStart + 1

            // Check if this challenge day was completed
            let isCompleted = challengeDay > 0 && challengeDay <= challenge.durationDays && completedDayNumbers.contains(challengeDay)

            result.append((day: dayLabel, completed: isCompleted))
        }

        return result
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Highlights")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                highlightCard(
                    icon: "clock.fill",
                    title: "Total Time",
                    value: participant.formattedTotalDuration,
                    color: .blue
                )

                highlightCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(participant.totalCaloriesBurned)",
                    color: .orange
                )

                typeSpecificHighlights
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var typeSpecificHighlights: some View {
        switch challenge.goalType {
        case .cardio, .endurance:
            highlightCard(
                icon: "figure.run",
                title: "Distance",
                value: participant.formattedTotalDistance,
                color: .green
            )

            if let avgHR = participant.averageHeartRate {
                highlightCard(
                    icon: "heart.fill",
                    title: "Avg HR",
                    value: "\(avgHR) bpm",
                    color: .red
                )
            } else {
                highlightCard(
                    icon: "heart.fill",
                    title: "Avg HR",
                    value: "--",
                    color: .red
                )
            }

        case .strength, .muscle:
            highlightCard(
                icon: "dumbbell.fill",
                title: "Weight Lifted",
                value: participant.formattedTotalWeight,
                color: .purple
            )

            highlightCard(
                icon: "star.fill",
                title: "PRs",
                value: "\(participant.prsAchieved)",
                color: .yellow
            )

        default:
            highlightCard(
                icon: "bolt.fill",
                title: "Streak",
                value: "\(participant.longestStreak) days",
                color: .yellow
            )

            highlightCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Consistency",
                value: "\(Int(participant.completionPercentage * 100))%",
                color: .green
            )
        }
    }

    private func highlightCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    WeeklySummaryView(participant: participant, challenge: challenge)
                } label: {
                    Text("See All")
                        .font(.subheadline)
                }
            }

            if let dayLogs = participant.dayLogs?.sorted(by: { $0.dayNumber > $1.dayNumber }).prefix(5) {
                ForEach(Array(dayLogs), id: \.id) { log in
                    RecentActivityRow(dayLog: log, challenge: challenge)
                }
            } else {
                Text("No activity logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Recent Activity Row

struct RecentActivityRow: View {
    let dayLog: ChallengeDayLog
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 12) {
            // Day indicator
            ZStack {
                Circle()
                    .fill(dayLog.isCompleted ? Color.green.opacity(0.15) : Color(.tertiarySystemFill))
                    .frame(width: 40, height: 40)

                if dayLog.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                } else {
                    Text("\(dayLog.dayNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(dayLog.dayNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let completedAt = dayLog.completedAt {
                    Text(completedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Entry source
            if let source = dayLog.entrySource {
                Image(systemName: source.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Stats preview
            if let activityData = dayLog.activityData {
                statsPreview(activityData)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func statsPreview(_ data: ChallengeActivityData) -> some View {
        switch challenge.goalType {
        case .cardio, .endurance:
            if let distance = data.distanceValue {
                Text(String(format: "%.1f mi", distance))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .strength, .muscle:
            if let weight = data.totalWeightLifted {
                Text(String(format: "%.0f lbs", weight))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            if let duration = data.durationSeconds {
                Text("\(duration / 60) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChallengeStatsView(
            challenge: Challenge(name: "30-Day Fitness", creatorId: "user123"),
            participant: ChallengeParticipant(ownerId: "user123", displayName: "You", isOwner: true)
        )
    }
}
