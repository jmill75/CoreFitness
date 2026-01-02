import SwiftUI
import UserNotifications

// MARK: - Check-In Time
enum CheckInTime: String, CaseIterable, Codable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var hour: Int {
        switch self {
        case .morning: return 8      // 8:00 AM
        case .afternoon: return 13   // 1:00 PM
        case .evening: return 19     // 7:00 PM
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        }
    }

    var description: String {
        switch self {
        case .morning: return "8:00 AM"
        case .afternoon: return "1:00 PM"
        case .evening: return "7:00 PM"
        }
    }
}

// MARK: - Notification Manager
@MainActor
class NotificationManager: ObservableObject {

    // MARK: - Singleton
    static let shared = NotificationManager()

    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - User Profile Manager Reference
    /// Weak reference to avoid retain cycle - set by app initialization
    weak var userProfileManager: UserProfileManager?

    // MARK: - Notification Identifiers
    private let dailyCheckInIdentifier = "com.corefitness.dailyCheckIn"

    // MARK: - Init
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    /// Configure with UserProfileManager for settings sync
    func configure(with profileManager: UserProfileManager) {
        self.userProfileManager = profileManager
    }

    /// Get check-in time from UserProfileManager or default
    var dailyCheckInTime: CheckInTime {
        guard let raw = userProfileManager?.dailyCheckInTimeRaw else { return .morning }
        return CheckInTime(rawValue: raw) ?? .morning
    }

    /// Get reminder enabled state from UserProfileManager
    var dailyCheckInReminderEnabled: Bool {
        userProfileManager?.dailyCheckInReminderEnabled ?? false
    }

    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Request Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Update Daily Check-In Notification
    func updateDailyCheckInNotification() async {
        // Remove existing notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [dailyCheckInIdentifier]
        )

        // If disabled, just return after removing
        guard dailyCheckInReminderEnabled else { return }

        // Check if authorized
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Mood Tracker"
        content.body = "How are you feeling today? Take a moment to log your mood."
        content.sound = .default
        content.badge = 1

        // Create trigger for the selected time
        var dateComponents = DateComponents()
        dateComponents.hour = dailyCheckInTime.hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: dailyCheckInIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Daily check-in notification scheduled for \(dailyCheckInTime.description)")
        } catch {
            print("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear Badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Get Pending Notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}
