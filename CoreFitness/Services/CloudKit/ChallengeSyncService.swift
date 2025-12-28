import Foundation
import CloudKit
import SwiftData
import Combine

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case retrying(attempt: Int, maxAttempts: Int)
    case error(String)

    var displayText: String {
        switch self {
        case .idle: return "Idle"
        case .syncing: return "Syncing..."
        case .success: return "Synced"
        case .retrying(let attempt, let max): return "Retrying (\(attempt)/\(max))..."
        case .error(let message): return message
        }
    }
}

// MARK: - Sync Error
enum SyncError: Error, LocalizedError {
    case networkUnavailable
    case cloudKitUnavailable
    case quotaExceeded
    case serverError(String)
    case recordNotFound
    case permissionDenied
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "No network connection"
        case .cloudKitUnavailable: return "iCloud unavailable"
        case .quotaExceeded: return "iCloud storage full"
        case .serverError(let msg): return "Server error: \(msg)"
        case .recordNotFound: return "Record not found"
        case .permissionDenied: return "Permission denied"
        case .unknown(let error): return error.localizedDescription
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .serverError, .unknown: return true
        case .cloudKitUnavailable, .quotaExceeded, .recordNotFound, .permissionDenied: return false
        }
    }

    static func from(_ error: Error) -> SyncError {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return .networkUnavailable
            case .notAuthenticated, .managedAccountRestricted:
                return .cloudKitUnavailable
            case .quotaExceeded:
                return .quotaExceeded
            case .unknownItem:
                return .recordNotFound
            case .permissionFailure:
                return .permissionDenied
            case .serverRejectedRequest, .serviceUnavailable, .requestRateLimited:
                return .serverError(ckError.localizedDescription)
            default:
                return .unknown(error)
            }
        }
        return .unknown(error)
    }
}

// MARK: - Pending Sync Operation
struct PendingSyncOperation: Codable, Identifiable {
    let id: UUID
    let participantID: UUID
    let operationType: OperationType
    let createdAt: Date
    var attemptCount: Int
    var lastAttemptAt: Date?
    var lastError: String?

    enum OperationType: String, Codable {
        case syncParticipant
        case syncDayLog
        case syncActivityData
    }

    init(participantID: UUID, operationType: OperationType) {
        self.id = UUID()
        self.participantID = participantID
        self.operationType = operationType
        self.createdAt = Date()
        self.attemptCount = 0
    }
}

// MARK: - Retry Configuration
struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let jitterFactor: Double

    static let `default` = RetryConfiguration(
        maxAttempts: 5,
        baseDelay: 1.0,
        maxDelay: 60.0,
        jitterFactor: 0.2
    )

    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        let clampedDelay = min(exponentialDelay, maxDelay)
        let jitter = clampedDelay * jitterFactor * Double.random(in: -1...1)
        return max(0, clampedDelay + jitter)
    }
}

// MARK: - Challenge Sync Service
@MainActor
class ChallengeSyncService: ObservableObject {

    // MARK: - Singleton
    static let shared = ChallengeSyncService()

    // MARK: - Published Properties
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var isSyncing = false
    @Published private(set) var pendingOperationsCount: Int = 0
    @Published private(set) var isOnline: Bool = true

    // MARK: - CloudKit Configuration
    private let containerIdentifier = "iCloud.com.jmillergroup.CoreFitness"
    private lazy var container = CKContainer(identifier: containerIdentifier)
    private lazy var privateDatabase = container.privateCloudDatabase
    private lazy var sharedDatabase = container.sharedCloudDatabase

    // Record Types
    private enum RecordType {
        static let challenge = "Challenge"
        static let participant = "ChallengeParticipant"
        static let dayLog = "ChallengeDayLog"
        static let activityData = "ChallengeActivityData"
    }

    // MARK: - Retry Configuration
    private let retryConfig = RetryConfiguration.default

    // MARK: - Pending Operations Queue
    private var pendingOperations: [PendingSyncOperation] = []
    private let pendingOperationsKey = "ChallengeSyncPendingOperations"
    private var retryTask: Task<Void, Never>?

    // MARK: - Model Context
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Initialization
    private init() {
        loadPendingOperations()
        setupSubscriptions()
        startRetryLoop()
    }

    // MARK: - CloudKit Availability Check

    func checkCloudKitAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            isOnline = status == .available
            return status == .available
        } catch {
            print("CloudKit availability check failed: \(error)")
            isOnline = false
            return false
        }
    }

    // MARK: - Retry Logic with Exponential Backoff

    /// Executes an async operation with retry logic and exponential backoff
    private func withRetry<T>(
        operation: String,
        config: RetryConfiguration = .default,
        block: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...config.maxAttempts {
            do {
                // Update status for UI
                if attempt > 1 {
                    syncStatus = .retrying(attempt: attempt, maxAttempts: config.maxAttempts)
                }

                let result = try await block()

                // Success - reset status
                syncStatus = .success
                return result

            } catch {
                lastError = error
                let syncError = SyncError.from(error)

                print("[\(operation)] Attempt \(attempt)/\(config.maxAttempts) failed: \(syncError.localizedDescription ?? "Unknown error")")

                // Don't retry non-retryable errors
                guard syncError.isRetryable else {
                    print("[\(operation)] Error is not retryable, failing immediately")
                    throw syncError
                }

                // Don't wait after last attempt
                guard attempt < config.maxAttempts else {
                    break
                }

                // Calculate delay with exponential backoff + jitter
                let delay = config.delay(for: attempt)
                print("[\(operation)] Waiting \(String(format: "%.1f", delay))s before retry...")

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // All retries exhausted
        let finalError = lastError ?? SyncError.unknown(NSError(domain: "ChallengeSyncService", code: -1))
        syncStatus = .error(SyncError.from(finalError).localizedDescription ?? "Sync failed")
        throw finalError
    }

    // MARK: - Pending Operations Queue

    private func loadPendingOperations() {
        if let data = UserDefaults.standard.data(forKey: pendingOperationsKey),
           let operations = try? JSONDecoder().decode([PendingSyncOperation].self, from: data) {
            pendingOperations = operations
            pendingOperationsCount = operations.count
        }
    }

    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: pendingOperationsKey)
        }
        pendingOperationsCount = pendingOperations.count
    }

    private func addPendingOperation(_ operation: PendingSyncOperation) {
        // Avoid duplicates
        if !pendingOperations.contains(where: { $0.participantID == operation.participantID && $0.operationType == operation.operationType }) {
            pendingOperations.append(operation)
            savePendingOperations()
            print("[SyncQueue] Added pending operation: \(operation.operationType.rawValue) for \(operation.participantID)")
        }
    }

    private func removePendingOperation(_ operation: PendingSyncOperation) {
        pendingOperations.removeAll { $0.id == operation.id }
        savePendingOperations()
    }

    private func updatePendingOperation(_ operation: PendingSyncOperation, error: String?) {
        if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
            pendingOperations[index].attemptCount += 1
            pendingOperations[index].lastAttemptAt = Date()
            pendingOperations[index].lastError = error
            savePendingOperations()
        }
    }

    // MARK: - Retry Loop for Pending Operations

    private func startRetryLoop() {
        retryTask = Task {
            while !Task.isCancelled {
                // Wait 30 seconds between retry attempts
                try? await Task.sleep(nanoseconds: 30_000_000_000)

                // Check if we're online
                guard await checkCloudKitAvailability() else {
                    continue
                }

                // Process pending operations
                await processPendingOperations()
            }
        }
    }

    private func processPendingOperations() async {
        guard !pendingOperations.isEmpty else { return }
        guard let context = modelContext else { return }

        print("[SyncQueue] Processing \(pendingOperations.count) pending operations...")

        for operation in pendingOperations {
            // Skip if too many attempts
            guard operation.attemptCount < retryConfig.maxAttempts else {
                print("[SyncQueue] Operation exceeded max attempts, removing: \(operation.id)")
                removePendingOperation(operation)
                continue
            }

            // Skip if attempted too recently (wait at least baseDelay * 2^attempts)
            if let lastAttempt = operation.lastAttemptAt {
                let minWait = retryConfig.delay(for: operation.attemptCount)
                if Date().timeIntervalSince(lastAttempt) < minWait {
                    continue
                }
            }

            // Try to execute the operation
            do {
                switch operation.operationType {
                case .syncParticipant:
                    // Fetch participant and retry sync
                    let descriptor = FetchDescriptor<ChallengeParticipant>(
                        predicate: #Predicate { $0.id == operation.participantID }
                    )
                    if let participant = try? context.fetch(descriptor).first {
                        try await syncParticipantDataInternal(participant)
                        removePendingOperation(operation)
                        print("[SyncQueue] Successfully synced participant: \(operation.participantID)")
                    }
                case .syncDayLog, .syncActivityData:
                    // Handle other operation types
                    removePendingOperation(operation)
                }
            } catch {
                updatePendingOperation(operation, error: error.localizedDescription)
                print("[SyncQueue] Failed to process operation: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sync Operations

    /// Syncs all local participant data to CloudKit with retry logic
    func syncParticipantData(_ participant: ChallengeParticipant) async {
        guard participant.needsSync == true else { return }

        isSyncing = true
        syncStatus = .syncing

        do {
            try await syncParticipantDataInternal(participant)
        } catch {
            // Add to pending queue for later retry
            let operation = PendingSyncOperation(
                participantID: participant.id,
                operationType: .syncParticipant
            )
            addPendingOperation(operation)
            print("[Sync] Added to pending queue for retry: \(participant.id)")
        }

        isSyncing = false
    }

    /// Internal sync implementation with retry
    private func syncParticipantDataInternal(_ participant: ChallengeParticipant) async throws {
        try await withRetry(operation: "syncParticipant") {
            // Create or update participant record
            let record = self.createParticipantRecord(from: participant)
            try await self.privateDatabase.save(record)

            // Sync day logs
            if let dayLogs = participant.dayLogs {
                for dayLog in dayLogs {
                    let logRecord = self.createDayLogRecord(from: dayLog, participantRecordID: record.recordID)
                    try await self.privateDatabase.save(logRecord)

                    // Sync activity data if present
                    if let activityData = dayLog.activityData {
                        let activityRecord = self.createActivityDataRecord(from: activityData, dayLogRecordID: logRecord.recordID)
                        try await self.privateDatabase.save(activityRecord)
                    }
                }
            }

            // Update local state on success
            await MainActor.run {
                participant.needsSync = false
                participant.lastSyncedAt = Date()
                participant.cloudKitRecordID = record.recordID.recordName
                self.lastSyncedAt = Date()
            }

            return ()
        }
    }

    /// Fetches updates from other participants in a challenge with retry logic
    func fetchChallengeUpdates(for challenge: Challenge) async -> [ChallengeParticipant] {
        isSyncing = true
        syncStatus = .syncing

        var fetchedParticipants: [ChallengeParticipant] = []

        do {
            fetchedParticipants = try await withRetry(operation: "fetchChallengeUpdates") {
                var participants: [ChallengeParticipant] = []

                // Query for participants in this challenge
                let predicate = NSPredicate(format: "challengeID == %@", challenge.id.uuidString)
                let query = CKQuery(recordType: RecordType.participant, predicate: predicate)

                let (matchResults, _) = try await self.sharedDatabase.records(matching: query)

                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        if let participant = self.createParticipant(from: record) {
                            // Fetch day logs for this participant
                            let _ = await self.fetchDayLogs(for: record.recordID)
                            participants.append(participant)
                        }
                    case .failure(let error):
                        print("Failed to fetch record: \(error)")
                    }
                }

                await MainActor.run {
                    self.lastSyncedAt = Date()
                }

                return participants
            }
        } catch {
            print("Fetch failed after retries: \(error)")
        }

        isSyncing = false
        return fetchedParticipants
    }

    /// Creates a shareable link for a challenge via invite code with retry logic
    func createChallengeShare(for challenge: Challenge) async -> CKShare? {
        do {
            return try await withRetry(operation: "createChallengeShare") {
                let challengeRecord = self.createChallengeRecord(from: challenge)
                try await self.privateDatabase.save(challengeRecord)

                let share = CKShare(rootRecord: challengeRecord)
                share[CKShare.SystemFieldKey.title] = challenge.name
                share.publicPermission = .readWrite

                let (_, savedShare) = try await self.privateDatabase.modifyRecords(
                    saving: [challengeRecord, share],
                    deleting: []
                )

                return savedShare.first as? CKShare
            }
        } catch {
            print("Failed to create share after retries: \(error)")
            return nil
        }
    }

    /// Joins a challenge using an invite code with retry logic
    func joinChallenge(withInviteCode code: String) async -> Challenge? {
        do {
            return try await withRetry(operation: "joinChallenge") {
                // Query for challenge with this invite code
                let predicate = NSPredicate(format: "inviteCode == %@", code)
                let query = CKQuery(recordType: RecordType.challenge, predicate: predicate)

                let (matchResults, _) = try await self.sharedDatabase.records(matching: query)

                if let (_, result) = matchResults.first {
                    switch result {
                    case .success(let record):
                        return self.createChallenge(from: record)
                    case .failure(let error):
                        throw error
                    }
                }
                return nil
            }
        } catch {
            print("Join challenge failed after retries: \(error)")
            return nil
        }
    }

    // MARK: - Record Creation

    private func createChallengeRecord(from challenge: Challenge) -> CKRecord {
        let recordID = CKRecord.ID(recordName: challenge.id.uuidString)
        let record = CKRecord(recordType: RecordType.challenge, recordID: recordID)

        record["id"] = challenge.id.uuidString
        record["name"] = challenge.name
        record["challengeDescription"] = challenge.challengeDescription
        record["durationDays"] = challenge.durationDays
        record["startDate"] = challenge.startDate
        record["endDate"] = challenge.endDate
        record["goalType"] = challenge.goalTypeRaw
        record["location"] = challenge.locationRaw
        record["creatorId"] = challenge.creatorId
        record["inviteCode"] = challenge.inviteCode
        record["isActive"] = challenge.isActive

        return record
    }

    private func createParticipantRecord(from participant: ChallengeParticipant) -> CKRecord {
        let recordID: CKRecord.ID
        if let existingID = participant.cloudKitRecordID {
            recordID = CKRecord.ID(recordName: existingID)
        } else {
            recordID = CKRecord.ID(recordName: participant.id.uuidString)
        }

        let record = CKRecord(recordType: RecordType.participant, recordID: recordID)

        record["id"] = participant.id.uuidString
        record["ownerId"] = participant.ownerId
        record["displayName"] = participant.displayName
        record["avatarEmoji"] = participant.avatarEmoji
        record["joinedAt"] = participant.joinedAt
        record["completedDays"] = participant.completedDays
        record["currentStreak"] = participant.currentStreak
        record["longestStreak"] = participant.longestStreak
        record["isOwner"] = participant.isOwner

        // Aggregate stats
        record["totalDistanceMiles"] = participant.totalDistanceMiles
        record["totalDurationSeconds"] = participant.totalDurationSeconds
        record["totalWeightLifted"] = participant.totalWeightLifted
        record["totalCaloriesBurned"] = participant.totalCaloriesBurned
        record["prsAchieved"] = participant.prsAchieved

        if let challengeID = participant.challenge?.id.uuidString {
            record["challengeID"] = challengeID
        }

        return record
    }

    private func createDayLogRecord(from dayLog: ChallengeDayLog, participantRecordID: CKRecord.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: dayLog.id.uuidString)
        let record = CKRecord(recordType: RecordType.dayLog, recordID: recordID)

        record["id"] = dayLog.id.uuidString
        record["dayNumber"] = dayLog.dayNumber
        record["isCompleted"] = dayLog.isCompleted
        record["completedAt"] = dayLog.completedAt
        record["notes"] = dayLog.notes
        record["entrySource"] = dayLog.entrySourceRaw
        record["entryTimestamp"] = dayLog.entryTimestamp

        // Reference to participant
        let reference = CKRecord.Reference(recordID: participantRecordID, action: .deleteSelf)
        record["participant"] = reference

        return record
    }

    private func createActivityDataRecord(from data: ChallengeActivityData, dayLogRecordID: CKRecord.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: data.id.uuidString)
        let record = CKRecord(recordType: RecordType.activityData, recordID: recordID)

        record["id"] = data.id.uuidString

        // Cardio stats
        record["startTime"] = data.startTime
        record["endTime"] = data.endTime
        record["durationSeconds"] = data.durationSeconds
        record["distanceValue"] = data.distanceValue
        record["distanceUnit"] = data.distanceUnitRaw
        record["averagePaceSecondsPerMile"] = data.averagePaceSecondsPerMile
        record["caloriesBurned"] = data.caloriesBurned

        // Strength stats
        record["totalWeightLifted"] = data.totalWeightLifted
        record["totalSets"] = data.totalSets
        record["totalReps"] = data.totalReps
        record["exercisesCompleted"] = data.exercisesCompleted
        record["isPR"] = data.isPR

        // Endurance stats
        record["averageHeartRate"] = data.averageHeartRate
        record["maxHeartRate"] = data.maxHeartRate

        // Reference to day log
        let reference = CKRecord.Reference(recordID: dayLogRecordID, action: .deleteSelf)
        record["dayLog"] = reference

        return record
    }

    // MARK: - Record Parsing

    private func createChallenge(from record: CKRecord) -> Challenge? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let creatorId = record["creatorId"] as? String else {
            return nil
        }

        let challenge = Challenge(
            id: id,
            name: name,
            description: record["challengeDescription"] as? String ?? "",
            durationDays: record["durationDays"] as? Int ?? 30,
            startDate: record["startDate"] as? Date ?? Date(),
            goalType: ChallengeGoalType(rawValue: record["goalType"] as? String ?? "") ?? .fitness,
            location: ChallengeLocation(rawValue: record["location"] as? String ?? "") ?? .anywhere,
            creatorId: creatorId
        )

        return challenge
    }

    private func createParticipant(from record: CKRecord) -> ChallengeParticipant? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let ownerId = record["ownerId"] as? String,
              let displayName = record["displayName"] as? String else {
            return nil
        }

        let participant = ChallengeParticipant(
            id: id,
            ownerId: ownerId,
            displayName: displayName,
            avatarEmoji: record["avatarEmoji"] as? String ?? "😀",
            isOwner: record["isOwner"] as? Bool ?? false
        )

        // Set aggregate stats
        participant.completedDays = record["completedDays"] as? Int ?? 0
        participant.currentStreak = record["currentStreak"] as? Int ?? 0
        participant.longestStreak = record["longestStreak"] as? Int ?? 0
        participant.totalDistanceMiles = record["totalDistanceMiles"] as? Double ?? 0
        participant.totalDurationSeconds = record["totalDurationSeconds"] as? Int ?? 0
        participant.totalWeightLifted = record["totalWeightLifted"] as? Double ?? 0
        participant.totalCaloriesBurned = record["totalCaloriesBurned"] as? Int ?? 0
        participant.prsAchieved = record["prsAchieved"] as? Int ?? 0
        participant.cloudKitRecordID = record.recordID.recordName
        participant.lastSyncedAt = Date()
        participant.needsSync = false

        return participant
    }

    private func fetchDayLogs(for participantRecordID: CKRecord.ID) async -> [ChallengeDayLog] {
        var logs: [ChallengeDayLog] = []

        do {
            let reference = CKRecord.Reference(recordID: participantRecordID, action: .none)
            let predicate = NSPredicate(format: "participant == %@", reference)
            let query = CKQuery(recordType: RecordType.dayLog, predicate: predicate)

            let (matchResults, _) = try await sharedDatabase.records(matching: query)

            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let log = createDayLog(from: record) {
                        logs.append(log)
                    }
                case .failure(let error):
                    print("Failed to fetch day log: \(error)")
                }
            }
        } catch {
            print("Failed to fetch day logs: \(error)")
        }

        return logs
    }

    private func createDayLog(from record: CKRecord) -> ChallengeDayLog? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let dayNumber = record["dayNumber"] as? Int else {
            return nil
        }

        let isCompleted = record["isCompleted"] as? Bool ?? false
        let entrySourceRaw = record["entrySource"] as? String

        let log = ChallengeDayLog(
            id: id,
            dayNumber: dayNumber,
            isCompleted: isCompleted,
            entrySource: entrySourceRaw != nil ? EntrySource(rawValue: entrySourceRaw!) : nil
        )

        log.completedAt = record["completedAt"] as? Date
        log.notes = record["notes"] as? String
        log.entryTimestamp = record["entryTimestamp"] as? Date

        return log
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        // Subscribe to changes in challenge participants
        Task {
            do {
                let subscription = CKQuerySubscription(
                    recordType: RecordType.participant,
                    predicate: NSPredicate(value: true),
                    options: [.firesOnRecordCreation, .firesOnRecordUpdate]
                )

                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo

                try await privateDatabase.save(subscription)
            } catch {
                print("Failed to setup subscription: \(error)")
            }
        }
    }

    // MARK: - Background Sync

    func performBackgroundSync() async {
        guard let context = modelContext else { return }

        // First, process any pending operations
        await processPendingOperations()

        // Then sync any new changes
        let descriptor = FetchDescriptor<ChallengeParticipant>(
            predicate: #Predicate { $0.needsSync == true }
        )

        do {
            let participantsToSync = try context.fetch(descriptor)
            for participant in participantsToSync {
                await syncParticipantData(participant)
            }
        } catch {
            print("Background sync failed: \(error)")
        }
    }

    // MARK: - Manual Retry

    /// Manually retry all pending operations
    func retryPendingOperations() async {
        guard await checkCloudKitAvailability() else {
            syncStatus = .error("iCloud unavailable")
            return
        }

        await processPendingOperations()
    }

    /// Clear all pending operations (use with caution)
    func clearPendingOperations() {
        pendingOperations.removeAll()
        savePendingOperations()
    }
}
