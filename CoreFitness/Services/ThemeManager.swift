import SwiftUI

// MARK: - App Theme
enum AppTheme: String, CaseIterable {
    case standard = "Standard"
    case masculine = "Bold"
    case feminine = "Soft"
    case midnight = "Midnight"

    var primaryColor: Color {
        switch self {
        case .standard: return .blue
        case .masculine: return Color(red: 0.2, green: 0.4, blue: 0.6)
        case .feminine: return Color(red: 0.9, green: 0.5, blue: 0.6)
        case .midnight: return Color(red: 0.4, green: 0.3, blue: 0.8)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .standard: return .indigo
        case .masculine: return Color(red: 0.3, green: 0.5, blue: 0.4)
        case .feminine: return Color(red: 0.7, green: 0.4, blue: 0.7)
        case .midnight: return Color(red: 0.3, green: 0.4, blue: 0.6)
        }
    }

    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Scheme Preference
enum ColorSchemePreference: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {

    // MARK: - Published Properties
    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .standard
    @AppStorage("colorSchemePreference") var colorSchemePreference: ColorSchemePreference = .system
    @AppStorage("useMetric") var useMetric: Bool = false
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("soundsEnabled") var soundsEnabled: Bool = true
    @AppStorage("restTimerDuration") var restTimerDuration: Double = 90

    // MARK: - Computed Properties
    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: - Haptic Feedback
    func lightHaptic() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func mediumHaptic() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func heavyHaptic() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func successHaptic() {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func errorHaptic() {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func selectionHaptic() {
        guard hapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Weight Formatting
    func formatWeight(_ pounds: Double) -> String {
        if useMetric {
            let kg = pounds * 0.453592
            return String(format: "%.1f kg", kg)
        } else {
            return String(format: "%.1f lbs", pounds)
        }
    }

    func convertWeight(_ value: Double, toMetric: Bool) -> Double {
        if toMetric {
            return value * 0.453592
        } else {
            return value / 0.453592
        }
    }
}
