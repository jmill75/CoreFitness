import Foundation
import CloudKit

// MARK: - AI Config Manager

/// Manages AI configuration fetched from CloudKit
/// Allows server-side switching of AI providers without app update
@MainActor
class AIConfigManager: ObservableObject {
    static let shared = AIConfigManager()

    // MARK: - Published Properties

    @Published var currentProvider: AIProviderType = .gemini
    @Published var isAIEnabled: Bool = true
    @Published var geminiModel: String = "gemini-1.5-flash"
    @Published var claudeModel: String = "claude-3-haiku-20240307"
    @Published var lastUpdated: Date?
    @Published var isLoading: Bool = false
    @Published var configError: Error?

    // MARK: - Private Properties

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let configRecordType = "AIConfig"
    private let userDefaults = UserDefaults.standard

    // Cache keys
    private enum CacheKeys {
        static let provider = "ai_config_provider"
        static let isEnabled = "ai_config_enabled"
        static let geminiModel = "ai_config_gemini_model"
        static let claudeModel = "ai_config_claude_model"
        static let lastUpdated = "ai_config_last_updated"
    }

    // MARK: - Initialization

    private init() {
        self.container = CKContainer.default()
        self.publicDatabase = container.publicCloudDatabase

        // Load cached config first for immediate use
        loadCachedConfig()
    }

    // MARK: - Public Methods

    /// Fetch the latest AI configuration from CloudKit
    func fetchConfig() async {
        isLoading = true
        configError = nil

        defer { isLoading = false }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: configRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]

        do {
            let (matchResults, _) = try await publicDatabase.records(matching: query, resultsLimit: 1)

            guard let result = matchResults.first else {
                // No config found, use defaults
                print("[AIConfigManager] No config record found, using defaults")
                return
            }

            let record = try result.1.get()
            parseConfig(from: record)
            cacheConfig()

            print("[AIConfigManager] Config fetched successfully - Provider: \(currentProvider.rawValue)")

        } catch let error as CKError where error.code == .unknownItem {
            // Record type doesn't exist in CloudKit yet - this is expected
            // Just use defaults silently until AIConfig is set up in CloudKit Dashboard
            print("[AIConfigManager] Using default config (AIConfig record type not configured)")
        } catch {
            configError = error
            print("[AIConfigManager] Failed to fetch config: \(error.localizedDescription)")
            // Continue using cached/default config
        }
    }

    /// Subscribe to config changes for real-time updates
    func subscribeToConfigChanges() async {
        let subscriptionID = "ai-config-changes"

        // Check if subscription already exists
        do {
            _ = try await publicDatabase.subscription(for: subscriptionID)
            print("[AIConfigManager] Subscription already exists")
            return
        } catch {
            // Subscription doesn't exist, create it
        }

        let subscription = CKQuerySubscription(
            recordType: configRecordType,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            try await publicDatabase.save(subscription)
            print("[AIConfigManager] Subscribed to config changes")
        } catch {
            print("[AIConfigManager] Failed to subscribe: \(error.localizedDescription)")
        }
    }

    /// Handle remote notification for config update
    func handleConfigNotification() async {
        await fetchConfig()
    }

    // MARK: - Admin Methods (for development/testing)

    #if DEBUG
    /// Update the AI provider (for testing)
    func setProvider(_ provider: AIProviderType) {
        currentProvider = provider
        cacheConfig()
    }

    /// Toggle AI features (for testing)
    func setAIEnabled(_ enabled: Bool) {
        isAIEnabled = enabled
        cacheConfig()
    }
    #endif

    // MARK: - Private Methods

    private func parseConfig(from record: CKRecord) {
        if let providerString = record["activeProvider"] as? String,
           let provider = AIProviderType(rawValue: providerString) {
            currentProvider = provider
        }

        if let enabled = record["isEnabled"] as? Bool {
            isAIEnabled = enabled
        }

        if let model = record["geminiModel"] as? String {
            geminiModel = model
        }

        if let model = record["claudeModel"] as? String {
            claudeModel = model
        }

        lastUpdated = record.modificationDate
    }

    private func cacheConfig() {
        userDefaults.set(currentProvider.rawValue, forKey: CacheKeys.provider)
        userDefaults.set(isAIEnabled, forKey: CacheKeys.isEnabled)
        userDefaults.set(geminiModel, forKey: CacheKeys.geminiModel)
        userDefaults.set(claudeModel, forKey: CacheKeys.claudeModel)
        userDefaults.set(lastUpdated, forKey: CacheKeys.lastUpdated)
    }

    private func loadCachedConfig() {
        if let providerString = userDefaults.string(forKey: CacheKeys.provider),
           let provider = AIProviderType(rawValue: providerString) {
            currentProvider = provider
        }

        if userDefaults.object(forKey: CacheKeys.isEnabled) != nil {
            isAIEnabled = userDefaults.bool(forKey: CacheKeys.isEnabled)
        }

        if let model = userDefaults.string(forKey: CacheKeys.geminiModel) {
            geminiModel = model
        }

        if let model = userDefaults.string(forKey: CacheKeys.claudeModel) {
            claudeModel = model
        }

        if let date = userDefaults.object(forKey: CacheKeys.lastUpdated) as? Date {
            lastUpdated = date
        }
    }
}

// MARK: - CloudKit Record Extension

extension AIConfigManager {
    /// Create the AIConfig record type in CloudKit Dashboard
    /// Fields needed:
    /// - activeProvider: String ("gemini" or "claude")
    /// - isEnabled: Int64 (0 or 1, CloudKit doesn't have Bool)
    /// - geminiModel: String
    /// - claudeModel: String

    static var recordTypeSchema: String {
        """
        CloudKit Record Type: AIConfig

        Fields:
        ┌──────────────────┬──────────┬─────────────────────────────┐
        │ Field Name       │ Type     │ Description                 │
        ├──────────────────┼──────────┼─────────────────────────────┤
        │ activeProvider   │ String   │ "gemini" or "claude"        │
        │ isEnabled        │ Int(64)  │ 1 = enabled, 0 = disabled   │
        │ geminiModel      │ String   │ e.g., "gemini-pro"          │
        │ claudeModel      │ String   │ e.g., "claude-3-haiku-..."  │
        └──────────────────┴──────────┴─────────────────────────────┘

        Note: Create this record type in CloudKit Dashboard under
        your app's container > Schema > Record Types
        """
    }
}
