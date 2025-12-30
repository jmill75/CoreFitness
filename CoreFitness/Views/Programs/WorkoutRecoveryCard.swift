import SwiftUI
import SwiftData

// MARK: - Workout Recovery Card
struct WorkoutRecoveryCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @Query(sort: \WorkoutSession.completedAt, order: .reverse)
    private var completedSessions: [WorkoutSession]

    private var lastCompletedSession: WorkoutSession? {
        completedSessions.first { $0.status == .completed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentRed)

                Text("Last Workout Recovery")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if let session = lastCompletedSession, let completedAt = session.completedAt {
                    Text(timeAgo(from: completedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let session = lastCompletedSession {
                // Workout name
                Text(session.workout?.name ?? "Workout")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Workout duration
                    RecoveryStatCell(
                        icon: "clock.fill",
                        value: formatDuration(session.totalDuration),
                        label: "Duration",
                        color: .accentBlue
                    )

                    // Calories burned
                    RecoveryStatCell(
                        icon: "flame.fill",
                        value: "\(session.caloriesBurned ?? 0)",
                        label: "Calories",
                        color: .accentOrange
                    )

                    // Sets completed
                    RecoveryStatCell(
                        icon: "checkmark.circle.fill",
                        value: "\(session.completedSets?.count ?? 0)",
                        label: "Sets",
                        color: .accentRed
                    )

                    // Recovery score
                    RecoveryStatCell(
                        icon: "bolt.heart.fill",
                        value: formatRecoveryScore(),
                        label: "Recovery",
                        color: recoveryScoreColor
                    )
                }

                // Post-workout recovery indicators
                if healthKitManager.isAuthorized {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.vertical, 4)

                        HStack(spacing: 16) {
                            // Sleep
                            MiniRecoveryStat(
                                icon: "moon.zzz.fill",
                                value: formatSleep(healthKitManager.healthData.sleepHours ?? 0),
                                label: "Sleep",
                                trend: sleepTrend
                            )

                            Divider()
                                .frame(height: 30)

                            // HRV
                            MiniRecoveryStat(
                                icon: "waveform.path.ecg",
                                value: formatHRV(healthKitManager.healthData.hrv ?? 0),
                                label: "HRV",
                                trend: hrvTrend
                            )

                            Divider()
                                .frame(height: 30)

                            // Resting HR
                            MiniRecoveryStat(
                                icon: "heart.fill",
                                value: formatRestingHR(Int(healthKitManager.healthData.restingHeartRate ?? 0)),
                                label: "Rest HR",
                                trend: restingHRTrend
                            )
                        }
                    }
                }
            } else {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.title)
                            .foregroundStyle(.secondary)

                        Text("Complete a workout to see recovery stats")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helper Methods

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(_ seconds: Int?) -> String {
        guard let seconds = seconds, seconds > 0 else { return "--" }
        let minutes = seconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }

    private func formatHeartRate(_ hr: Int?) -> String {
        guard let hr = hr, hr > 0 else { return "--" }
        return "\(hr)"
    }

    private func formatRecoveryScore() -> String {
        let score = calculateRecoveryScore()
        guard score > 0 else { return "--" }
        return "\(score)"
    }

    /// Calculate recovery score based on available health data
    private func calculateRecoveryScore() -> Int {
        var score = 70 // Base score

        // Adjust based on sleep (target 7-9 hours)
        let sleep = healthKitManager.healthData.sleepHours ?? 0
        if sleep >= 7 && sleep <= 9 {
            score += 15
        } else if sleep >= 6 {
            score += 5
        } else if sleep > 0 {
            score -= 10
        }

        // Adjust based on HRV (higher is better)
        let hrv = healthKitManager.healthData.hrv ?? 0
        if hrv >= 50 {
            score += 10
        } else if hrv >= 30 {
            score += 5
        }

        // Adjust based on resting HR (lower is better)
        let restingHR = healthKitManager.healthData.restingHeartRate ?? 0
        if restingHR > 0 && restingHR < 60 {
            score += 5
        } else if restingHR > 80 {
            score -= 5
        }

        return max(0, min(100, score))
    }

    private var recoveryScoreColor: Color {
        let score = calculateRecoveryScore()
        if score >= 80 { return .accentGreen }
        if score >= 60 { return .accentOrange }
        return .accentRed
    }

    private func formatSleep(_ hours: Double) -> String {
        guard hours > 0 else { return "--" }
        return String(format: "%.1fh", hours)
    }

    private func formatHRV(_ hrv: Double) -> String {
        guard hrv > 0 else { return "--" }
        return String(format: "%.0f", hrv)
    }

    private func formatRestingHR(_ hr: Int) -> String {
        guard hr > 0 else { return "--" }
        return "\(hr)"
    }

    private var sleepTrend: TrendDirection {
        // Compare to recommended sleep (7-9 hours)
        let sleep = healthKitManager.healthData.sleepHours ?? 0
        if sleep >= 7 { return .up }
        if sleep >= 6 { return .neutral }
        return .down
    }

    private var hrvTrend: TrendDirection {
        // HRV trend based on average (higher is generally better)
        let hrv = healthKitManager.healthData.hrv ?? 0
        if hrv >= 50 { return .up }
        if hrv >= 30 { return .neutral }
        return .down
    }

    private var restingHRTrend: TrendDirection {
        // Lower resting HR is generally better
        let hr = healthKitManager.healthData.restingHeartRate ?? 0
        if hr > 0 && hr < 60 { return .up }
        if hr < 75 { return .neutral }
        return .down
    }
}

// MARK: - Recovery Stat Cell
struct RecoveryStatCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Mini Recovery Stat
struct MiniRecoveryStat: View {
    let icon: String
    let value: String
    let label: String
    let trend: TrendDirection

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Image(systemName: trend.icon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(trend.color)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WorkoutRecoveryCard()
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .padding()
        .background(Color(.systemGroupedBackground))
}
