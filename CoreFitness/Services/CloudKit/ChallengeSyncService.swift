import Foundation
import CloudKit
import SwiftData
import Combine

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error(String)
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

    // MARK: - Model Context
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Initialization
    private init() {
        setupSubscriptions()
    }

    // MARK: - CloudKit Availability Check

    func checkCloudKitAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            print("CloudKit availability check failed: \(error)")
            return false
        }
    }

    // MARK: - Sync Operations

    /// Syncs all local participant data to CloudKit
    func syncParticipantData(_ participant: ChallengeParticipant) async {
        guard participant.needsSync == true else { return }

        isSyncing = true
        syncStatus = .syncing

        do {
            // Create or update participant record
            let record = createParticipantRecord(from: participant)
            try await privateDatabase.save(record)

            // Sync day logs
            if let dayLogs = participant.dayLogs {
                for dayLog in dayLogs {
                    let logRecord = createDayLogRecord(from: dayLog, participantRecordID: record.recordID)
                    try await privateDatabase.save(logRecord)

                    // Sync activity data if present
                    if let activityData = dayLog.activityData {
                        let activityRecord = createActivityDataRecord(from: activityData, dayLogRecordID: logRecord.recordID)
                        try await privateDatabase.save(activityRecord)
                    }
                }
            }

            // Update local state
            participant.needsSync = false
            participant.lastSyncedAt = Date()
            participant.cloudKitRecordID = record.recordID.recordName

            lastSyncedAt = Date()
            syncStatus = .success
        } catch {
            syncStatus = .error(error.localizedDescription)
            print("Sync failed: \(error)")
        }

        isSyncing = false
    }

    /// Fetches updates from other participants in a challenge
    func fetchChallengeUpdates(for challenge: Challenge) async -> [ChallengeParticipant] {
        isSyncing = true
        syncStatus = .syncing

        var fetchedParticipants: [ChallengeParticipant] = []

        do {
            // Query for participants in this challenge
            let predicate = NSPredicate(format: "challengeID == %@", challenge.id.uuidString)
            let query = CKQuery(recordType: RecordType.participant, predicate: predicate)

            let (matchResults, _) = try await sharedDatabase.records(matching: query)

            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let participant = createParticipant(from: record) {
                        // Fetch day logs for this participant
                        let logs = await fetchDayLogs(for: record.recordID)
                        // Note: Relationship would be set when adding to context
                        fetchedParticipants.append(participant)
                    }
                case .failure(let error):
                    print("Failed to fetch record: \(error)")
                }
            }

            lastSyncedAt = Date()
            syncStatus = .success
        } catch {
            syncStatus = .error(error.localizedDescription)
            print("Fetch failed: \(error)")
        }

        isSyncing = false
        return fetchedParticipants
    }

    /// Creates a shareable link for a challenge via invite code
    func createChallengeShare(for challenge: Challenge) async -> CKShare? {
        do {
            let challengeRecord = createChallengeRecord(from: challenge)
            try await privateDatabase.save(challengeRecord)

            let share = CKShare(rootRecord: challengeRecord)
            share[CKShare.SystemFieldKey.title] = challenge.name
            share.publicPermission = .readWrite

            let (_, savedShare) = try await privateDatabase.modifyRecords(
                saving: [challengeRecord, share],
                deleting: []
            )

            return savedShare.first as? CKShare
        } catch {
            print("Failed to create share: \(error)")
            return nil
        }
    }

    /// Joins a challenge using an invite code
    func joinChallenge(withInviteCode code: String) async -> Challenge? {
        do {
            // Query for challenge with this invite code
            let predicate = NSPredicate(format: "inviteCode == %@", code)
            let query = CKQuery(recordType: RecordType.challenge, predicate: predicate)

            let (matchResults, _) = try await sharedDatabase.records(matching: query)

            if let (_, result) = matchResults.first {
                switch result {
                case .success(let record):
                    return createChallenge(from: record)
                case .failure(let error):
                    print("Failed to fetch challenge: \(error)")
                    return nil
                }
            }
        } catch {
            print("Join challenge failed: \(error)")
        }

        return nil
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
        record["oderId"] = participant.oderId
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
              let oderId = record["oderId"] as? String,
              let displayName = record["displayName"] as? String else {
            return nil
        }

        let participant = ChallengeParticipant(
            id: id,
            oderId: oderId,
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

        // Fetch all participants that need syncing
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
}
