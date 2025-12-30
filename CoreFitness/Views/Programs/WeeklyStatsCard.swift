import SwiftUI
import SwiftData

// MARK: - Weekly Stats Card (Refined Dark Theme)
struct WeeklyStatsCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var allSessions: [WorkoutSession]

    private let calendar = Calendar.current

    // Colors
    private let cardBg = Color(hex: "161616")
    private let statsBg = Color(hex: "111111")
    private let cyanColor = Color(hex: "54a0ff")
    private let limeColor = Color(hex: "1dd1a1")
    private let goldColor = Color(hex: "feca57")

    // MARK: - Computed Properties

    private var thisWeekSessions: [WorkoutSession] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return allSessions.filter { session in
            guard session.status == .completed,
                  let completedAt = session.completedAt else { return false }
            return completedAt >= startOfWeek
        }
    }

    private var lastWeekSessions: [WorkoutSession] {
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? Date()

        return allSessions.filter { session in
            guard session.status == .completed,
                  let completedAt = session.completedAt else { return false }
            return completedAt >= startOfLastWeek && completedAt < startOfThisWeek
        }
    }

    private var workoutCount: Int { thisWeekSessions.count }

    private var totalDuration: String {
        let minutes = thisWeekSessions.compactMap { $0.totalDuration }.reduce(0, +) / 60
        if minutes >= 60 {
            let hours = Double(minutes) / 60.0
            return String(format: "%.1fh", hours)
        }
        return "\(minutes)m"
    }

    private var currentStreak: Int {
        // Calculate consecutive days with workouts
        var streak = 0
        var currentDate = Date()
        let calendar = Calendar.current

        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let hasWorkout = allSessions.contains { session in
                guard session.status == .completed,
                      let completedAt = session.completedAt else { return false }
                return completedAt >= dayStart && completedAt < dayEnd
            }

            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }

        return streak
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header with badge
            HStack {
                // "This Week" badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(cyanColor)
                        .frame(width: 6, height: 6)

                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(cyanColor)
                        .tracking(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(cyanColor.opacity(0.15))
                .clipShape(Capsule())

                Spacer()
            }

            // Stats Grid
            HStack(spacing: 12) {
                DashboardStatItem(
                    value: "\(workoutCount)",
                    label: "Workouts",
                    accentColor: cyanColor
                )

                DashboardStatItem(
                    value: totalDuration,
                    label: "Duration",
                    accentColor: limeColor
                )

                DashboardStatItem(
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    accentColor: goldColor
                )
            }
        }
        .padding(24)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            // Cyan accent bar at top
            VStack {
                LinearGradient(
                    colors: [Color(hex: "2e86de"), cyanColor, Color(hex: "00d2d3")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        // Radial glow effect
        .overlay(
            Circle()
                .fill(
                    RadialGradient(
                        colors: [cyanColor.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 150, height: 150)
                .offset(x: 60, y: -60)
                .clipped()
            , alignment: .topTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Dashboard Stat Item (with colored bottom accent)
struct DashboardStatItem: View {
    let value: String
    let label: String
    let accentColor: Color

    private let statsBg = Color(hex: "111111")

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)

            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(statsBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            // Colored bottom accent bar
            VStack {
                Spacer()
                accentColor
                    .frame(height: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Trend Direction (kept for compatibility)
enum TrendDirection {
    case up, down, neutral

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .accentGreen
        case .down: return .accentOrange
        case .neutral: return .secondary
        }
    }
}

// MARK: - Legacy Stat Item (kept for compatibility)
struct WeeklyStatItem: View {
    let value: String
    let label: String
    let icon: String
    let trend: TrendDirection
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Image(systemName: trend.icon)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(trend.color)
            }

            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WeeklyStatsCard()
            .environmentObject(ThemeManager())
            .padding()
    }
}
