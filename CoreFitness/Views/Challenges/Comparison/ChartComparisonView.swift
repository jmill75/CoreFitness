import SwiftUI
import Charts

enum ChartMetric: String, CaseIterable {
    case completedDays = "Days Completed"
    case streak = "Current Streak"
    case distance = "Total Distance"
    case weight = "Weight Lifted"
    case calories = "Calories Burned"

    var icon: String {
        switch self {
        case .completedDays: return "checkmark.circle.fill"
        case .streak: return "flame.fill"
        case .distance: return "figure.run"
        case .weight: return "dumbbell.fill"
        case .calories: return "flame.fill"
        }
    }
}

struct ChartComparisonView: View {
    let challenge: Challenge
    let participants: [ChallengeParticipant]
    let timeframe: ComparisonTimeframe

    @State private var selectedMetric: ChartMetric = .completedDays

    var chartData: [ParticipantChartData] {
        participants.map { participant in
            ParticipantChartData(
                participant: participant,
                value: getValue(for: participant, metric: selectedMetric)
            )
        }
        .sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Metric Selector
            metricSelector

            // Chart
            ScrollView {
                VStack(spacing: 24) {
                    // Bar Chart
                    barChart
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Legend / Current Values
                    legendSection
                }
                .padding()
            }
        }
    }

    // MARK: - Metric Selector

    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableMetrics, id: \.self) { metric in
                    Button {
                        selectedMetric = metric
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: metric.icon)
                            Text(metric.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedMetric == metric ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(selectedMetric == metric ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var availableMetrics: [ChartMetric] {
        switch challenge.goalType {
        case .cardio, .endurance:
            return [.completedDays, .streak, .distance, .calories]
        case .strength, .muscle:
            return [.completedDays, .streak, .weight, .calories]
        default:
            return [.completedDays, .streak, .calories]
        }
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedMetric.rawValue)
                .font(.headline)

            Chart(chartData) { data in
                BarMark(
                    x: .value("Participant", data.participant.displayName),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(by: .value("Participant", data.participant.displayName))
                .cornerRadius(8)
                .annotation(position: .top) {
                    Text(formatValue(data.value, for: selectedMetric))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            VStack {
                                if let participant = participants.first(where: { $0.displayName == name }) {
                                    Text(participant.avatarEmoji)
                                }
                                Text(name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .frame(height: 250)
        }
    }

    // MARK: - Legend Section

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Values")
                .font(.headline)

            ForEach(chartData, id: \.id) { data in
                HStack(spacing: 12) {
                    Text(data.participant.avatarEmoji)
                        .font(.title3)

                    Text(data.participant.displayName)
                        .font(.subheadline)

                    Spacer()

                    Text(formatValue(data.value, for: selectedMetric))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func getValue(for participant: ChallengeParticipant, metric: ChartMetric) -> Double {
        switch metric {
        case .completedDays:
            return Double(participant.completedDays)
        case .streak:
            return Double(participant.currentStreak)
        case .distance:
            return participant.totalDistanceMiles ?? 0
        case .weight:
            return participant.totalWeightLifted ?? 0
        case .calories:
            return Double(participant.totalCaloriesBurned ?? 0)
        }
    }

    private func formatValue(_ value: Double, for metric: ChartMetric) -> String {
        switch metric {
        case .completedDays, .streak:
            return "\(Int(value))"
        case .distance:
            return String(format: "%.1f mi", value)
        case .weight:
            if value >= 1000 {
                return String(format: "%.1fK lbs", value / 1000)
            }
            return String(format: "%.0f lbs", value)
        case .calories:
            return String(format: "%.0f cal", value)
        }
    }
}

// MARK: - Chart Data

struct ParticipantChartData: Identifiable {
    let id = UUID()
    let participant: ChallengeParticipant
    let value: Double
}

// MARK: - Preview

#Preview {
    ChartComparisonView(
        challenge: Challenge(name: "30-Day Fitness", creatorId: "user123"),
        participants: [],
        timeframe: .allTime
    )
}
