import SwiftUI

// MARK: - Shared Recovery Card Component
// Used in both HomeView and HealthView for consistent recovery score display

struct RecoveryCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var onTap: (() -> Void)? = nil
    @State private var isPressed = false

    // Vibrant coral accent colors
    private let coralStart = Color(hex: "e85555")
    private let coralEnd = Color(hex: "ff6b6b")
    private let cardBg = Color(hex: "161616")

    private var score: Int {
        healthKitManager.calculateOverallScore()
    }

    private var scoreMessage: String {
        if !healthKitManager.isAuthorized { return "Connect Health" }
        switch score {
        case 80...100: return "Crushing it!"
        case 60..<80: return "Good recovery"
        case 40..<60: return "Take it easy"
        default: return "Rest day"
        }
    }

    var body: some View {
        Group {
            if let action = onTap {
                Button {
                    action()
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                    if !reduceMotion {
                        isPressed = pressing
                    }
                }, perform: {})
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's Recovery Score")
        .accessibilityValue(healthKitManager.isAuthorized ? "\(score) out of 100. \(scoreMessage)" : "Not connected. Connect Health app to see your score.")
        .accessibilityHint(onTap != nil ? "Double tap to view detailed recovery metrics" : "")
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }

    private var cardContent: some View {
        VStack(spacing: 20) {
            // Top row: Score Ring + Info
            HStack(spacing: 16) {
                // Large Score Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 10)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: healthKitManager.isAuthorized ? CGFloat(score) / 100.0 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [coralStart, coralEnd, Color(hex: "ff9f43")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(healthKitManager.isAuthorized ? "\(score)" : "--")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "ff6b6b"))
                        Text("score")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(scoreMessage)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer().frame(height: 4)

                    if onTap != nil {
                        HStack(spacing: 4) {
                            Text("View Details")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()
            }

            // Recovery Stats - Individual cards with colored bottom accents
            HStack(spacing: 12) {
                RecoveryMetricCard(value: hrvValue, label: "HRV", accentColor: Color(hex: "ff6b6b"))
                RecoveryMetricCard(value: sleepValue, label: "Sleep", accentColor: Color(hex: "00d2d3"))
                RecoveryMetricCard(value: hrValue, label: "Rest HR", accentColor: Color(hex: "54a0ff"))
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            // Coral accent bar at top
            VStack {
                LinearGradient(
                    colors: [coralStart, coralEnd, Color(hex: "ff9f43")],
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
        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 6)
        .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.98 : 1.0))
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1fh", hours)
    }

    private var hrvValue: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        return "\(Int(hrv))"
    }

    private var hrValue: String {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return "--" }
        return "\(Int(hr))"
    }
}

// Individual metric card with colored bottom accent
struct RecoveryMetricCard: View {
    let value: String
    let label: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(hex: "111111"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value == "--" ? "No data available" : value)
    }
}

#Preview {
    RecoveryCard()
        .environmentObject(HealthKitManager())
        .padding()
        .background(Color.black)
}
