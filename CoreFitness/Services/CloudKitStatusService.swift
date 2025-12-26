import SwiftUI
import CloudKit
import Combine

// MARK: - iCloud Sync Status
enum iCloudSyncStatus: Equatable {
    case available
    case unavailable(reason: String)
    case checking

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .available:
            return "Syncing"
        case .unavailable(let reason):
            return reason
        case .checking:
            return "Checking..."
        }
    }

    var icon: String {
        switch self {
        case .available:
            return "checkmark.icloud.fill"
        case .unavailable:
            return "xmark.icloud.fill"
        case .checking:
            return "icloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .available:
            return .green
        case .unavailable:
            return .orange
        case .checking:
            return .secondary
        }
    }
}

// MARK: - CloudKit Status Service
@MainActor
class CloudKitStatusService: ObservableObject {
    static let shared = CloudKitStatusService()

    @Published private(set) var syncStatus: iCloudSyncStatus = .checking
    @Published private(set) var lastChecked: Date?

    private var notificationObserver: NSObjectProtocol?

    init() {
        setupNotificationObserver()
        Task {
            await checkStatus()
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Status Check

    /// Check current iCloud account status
    func checkStatus() async {
        syncStatus = .checking

        do {
            let status = try await CKContainer.default().accountStatus()

            switch status {
            case .available:
                syncStatus = .available
            case .noAccount:
                syncStatus = .unavailable(reason: "Not signed in")
            case .restricted:
                syncStatus = .unavailable(reason: "Restricted")
            case .couldNotDetermine:
                syncStatus = .unavailable(reason: "Unknown")
            case .temporarilyUnavailable:
                syncStatus = .unavailable(reason: "Temporarily unavailable")
            @unknown default:
                syncStatus = .unavailable(reason: "Unknown")
            }

            lastChecked = Date()
        } catch {
            syncStatus = .unavailable(reason: "Error checking")
            lastChecked = Date()
        }
    }

    // MARK: - Notification Observer

    private func setupNotificationObserver() {
        // Listen for iCloud account changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkStatus()
            }
        }
    }
}
