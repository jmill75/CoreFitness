import Foundation
import SwiftData

// MARK: - Invitation Status
enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case declined
    case expired
}

// MARK: - Message Type
enum MessageType: String, Codable {
    case iMessage
    case sms
    case unknown
}

// MARK: - Workout Invitation Model
@Model
final class WorkoutInvitation {
    var id: UUID = UUID()
    var workoutId: UUID = UUID()
    var workoutName: String = ""
    var senderUserId: String = ""
    var senderDisplayName: String = ""
    var recipientPhone: String = ""
    var recipientName: String = ""
    var statusRaw: String = InvitationStatus.pending.rawValue
    var messageTypeRaw: String = MessageType.unknown.rawValue
    var inviteCode: String = ""
    var exerciseList: String = ""
    var estimatedDuration: Int = 0
    var exerciseCount: Int = 0
    var createdAt: Date = Date()
    var respondedAt: Date?

    var status: InvitationStatus {
        get { InvitationStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var messageType: MessageType {
        get { MessageType(rawValue: messageTypeRaw) ?? .unknown }
        set { messageTypeRaw = newValue.rawValue }
    }

    init(
        workoutId: UUID,
        workoutName: String,
        senderUserId: String,
        senderDisplayName: String,
        recipientPhone: String,
        recipientName: String,
        inviteCode: String,
        exerciseList: String,
        estimatedDuration: Int,
        exerciseCount: Int
    ) {
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.senderUserId = senderUserId
        self.senderDisplayName = senderDisplayName
        self.recipientPhone = recipientPhone
        self.recipientName = recipientName
        self.inviteCode = inviteCode
        self.exerciseList = exerciseList
        self.estimatedDuration = estimatedDuration
        self.exerciseCount = exerciseCount
    }
}

// MARK: - Selected Workout Buddy
struct SelectedWorkoutBuddy: Identifiable, Equatable {
    let id: String
    let name: String
    let phoneNumber: String
    let initials: String

    static func == (lhs: SelectedWorkoutBuddy, rhs: SelectedWorkoutBuddy) -> Bool {
        lhs.id == rhs.id
    }
}
