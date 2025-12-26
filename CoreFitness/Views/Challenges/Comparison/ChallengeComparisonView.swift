import SwiftUI

enum ComparisonMode: String, CaseIterable {
    case leaderboard = "Leaderboard"
    case sideBySide = "Side by Side"
    case charts = "Charts"

    var icon: String {
        switch self {
        case .leaderboard: return "list.number"
        case .sideBySide: return "rectangle.split.2x1"
        case .charts: return "chart.line.uptrend.xyaxis"
        }
    }
}

enum ComparisonTimeframe: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
    case allTime = "All Time"
}

struct ChallengeComparisonView: View {
    let challenge: Challenge
    let participants: [ChallengeParticipant]

    @State private var selectedMode: ComparisonMode = .leaderboard
    @State private var selectedTimeframe: ComparisonTimeframe = .allTime

    var body: some View {
        VStack(spacing: 0) {
            // Mode Selector
            modeSelector

            // Timeframe Filter
            timeframeFilter

            // Content based on selected mode
            comparisonContent
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Compare Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        Picker("View Mode", selection: $selectedMode) {
            ForEach(ComparisonMode.allCases, id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Timeframe Filter

    private var timeframeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ComparisonTimeframe.allCases, id: \.self) { timeframe in
                    Button {
                        selectedTimeframe = timeframe
                    } label: {
                        Text(timeframe.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTimeframe == timeframe ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTimeframe == timeframe ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                            .foregroundStyle(selectedTimeframe == timeframe ? .white : .primary)
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

    // MARK: - Comparison Content

    @ViewBuilder
    private var comparisonContent: some View {
        switch selectedMode {
        case .leaderboard:
            LeaderboardComparisonView(
                challenge: challenge,
                participants: participants,
                timeframe: selectedTimeframe
            )
        case .sideBySide:
            SideBySideComparisonView(
                challenge: challenge,
                participants: participants,
                timeframe: selectedTimeframe
            )
        case .charts:
            ChartComparisonView(
                challenge: challenge,
                participants: participants,
                timeframe: selectedTimeframe
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChallengeComparisonView(
            challenge: Challenge(name: "30-Day Fitness", creatorId: "user123"),
            participants: []
        )
    }
}
