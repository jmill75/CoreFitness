import SwiftUI
import SwiftData
import UIKit
import Combine

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

    // MARK: - User Profile Manager Reference
    private weak var userProfileManager: UserProfileManager?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties (synced with UserProfileManager)
    @Published var selectedTheme: AppTheme = .standard
    @Published var colorSchemePreference: ColorSchemePreference = .system
    @Published var useMetric: Bool = false
    @Published var hapticsEnabled: Bool = true
    @Published var soundsEnabled: Bool = true
    @Published var restTimerDuration: Double = 90

    // MARK: - Computed Properties
    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: - Setup

    /// Connect to UserProfileManager for synced settings
    func setUserProfileManager(_ manager: UserProfileManager) {
        self.userProfileManager = manager

        // Load initial values
        loadFromUserProfileManager()

        // Subscribe to changes from UserProfileManager
        manager.$selectedThemeRaw
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rawValue in
                if let theme = AppTheme(rawValue: rawValue) {
                    self?.selectedTheme = theme
                }
            }
            .store(in: &cancellables)

        manager.$colorSchemePreferenceRaw
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rawValue in
                if let pref = ColorSchemePreference(rawValue: rawValue) {
                    self?.colorSchemePreference = pref
                }
            }
            .store(in: &cancellables)

        manager.$useMetricSystem
            .receive(on: DispatchQueue.main)
            .assign(to: &$useMetric)

        manager.$hapticsEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$hapticsEnabled)

        manager.$soundsEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$soundsEnabled)

        manager.$restTimerDuration
            .receive(on: DispatchQueue.main)
            .map { Double($0) }
            .assign(to: &$restTimerDuration)

        // Subscribe to local changes and push to UserProfileManager
        $selectedTheme
            .dropFirst()
            .sink { [weak self] theme in
                self?.userProfileManager?.selectedThemeRaw = theme.rawValue
            }
            .store(in: &cancellables)

        $colorSchemePreference
            .dropFirst()
            .sink { [weak self] pref in
                self?.userProfileManager?.colorSchemePreferenceRaw = pref.rawValue
            }
            .store(in: &cancellables)

        $useMetric
            .dropFirst()
            .sink { [weak self] value in
                self?.userProfileManager?.useMetricSystem = value
            }
            .store(in: &cancellables)

        $hapticsEnabled
            .dropFirst()
            .sink { [weak self] value in
                self?.userProfileManager?.hapticsEnabled = value
            }
            .store(in: &cancellables)

        $soundsEnabled
            .dropFirst()
            .sink { [weak self] value in
                self?.userProfileManager?.soundsEnabled = value
            }
            .store(in: &cancellables)

        $restTimerDuration
            .dropFirst()
            .sink { [weak self] value in
                self?.userProfileManager?.restTimerDuration = Int(value)
            }
            .store(in: &cancellables)
    }

    /// Load initial values from UserProfileManager
    private func loadFromUserProfileManager() {
        guard let manager = userProfileManager else { return }

        if let theme = AppTheme(rawValue: manager.selectedThemeRaw) {
            selectedTheme = theme
        }
        if let pref = ColorSchemePreference(rawValue: manager.colorSchemePreferenceRaw) {
            colorSchemePreference = pref
        }
        useMetric = manager.useMetricSystem
        hapticsEnabled = manager.hapticsEnabled
        soundsEnabled = manager.soundsEnabled
        restTimerDuration = Double(manager.restTimerDuration)
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

    /// Returns just the numeric value formatted (without unit)
    func formatWeightValue(_ pounds: Double) -> String {
        if useMetric {
            let kg = pounds * 0.453592
            return String(format: "%.1f", kg)
        } else {
            return String(format: "%.0f", pounds)
        }
    }

    /// Returns the weight unit label
    var weightUnitLabel: String {
        useMetric ? "KG" : "LBS"
    }

    func convertWeight(_ value: Double, toMetric: Bool) -> Double {
        if toMetric {
            return value * 0.453592
        } else {
            return value / 0.453592
        }
    }

    // MARK: - Haptic Feedback

    /// Trigger light impact haptic feedback (respects hapticsEnabled setting)
    func lightImpact() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Trigger medium impact haptic feedback (respects hapticsEnabled setting)
    func mediumImpact() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Trigger heavy impact haptic feedback (respects hapticsEnabled setting)
    func heavyImpact() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Trigger soft impact haptic feedback (respects hapticsEnabled setting)
    func softImpact() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Trigger rigid impact haptic feedback (respects hapticsEnabled setting)
    func rigidImpact() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    /// Trigger selection changed haptic feedback (respects hapticsEnabled setting)
    func selectionChanged() {
        guard hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Trigger success notification haptic feedback (respects hapticsEnabled setting)
    func notifySuccess() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Trigger warning notification haptic feedback (respects hapticsEnabled setting)
    func notifyWarning() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Trigger error notification haptic feedback (respects hapticsEnabled setting)
    func notifyError() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // Legacy haptic methods (for compatibility)
    func lightHaptic() { lightImpact() }
    func mediumHaptic() { mediumImpact() }
    func heavyHaptic() { heavyImpact() }
    func successHaptic() { notifySuccess() }
    func errorHaptic() { notifyError() }
    func selectionHaptic() { selectionChanged() }
}
