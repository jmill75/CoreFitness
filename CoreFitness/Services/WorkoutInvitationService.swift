import Foundation
import SwiftData
import Contacts

@MainActor
class WorkoutInvitationService: ObservableObject {
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Generate Invite Code
    /// Generates a 6-character alphanumeric code (excluding confusing characters)
    func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKMNPQRSTUVWXYZ23456789" // Excludes I, L, O, 0, 1
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    // MARK: - Format Exercise List
    /// Creates a formatted exercise list for SMS body
    func formatExerciseList(workout: Workout) -> String {
        guard let exercises = workout.exercises, !exercises.isEmpty else {
            return "No exercises added yet"
        }

        let sortedExercises = exercises.sorted { $0.order < $1.order }
        var lines: [String] = []

        for (index, workoutExercise) in sortedExercises.prefix(8).enumerated() {
            let exercise = workoutExercise.exercise
            let sets = workoutExercise.targetSets
            let reps = workoutExercise.targetReps
            let rest = workoutExercise.restDuration

            let restText = rest >= 60 ? "\(rest / 60)m rest" : "\(rest)s rest"
            lines.append("\(index + 1). \(exercise?.name ?? "Exercise") - \(sets)x\(reps) (\(restText))")
        }

        if sortedExercises.count > 8 {
            lines.append("   ... and \(sortedExercises.count - 8) more exercises")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Create Invitation
    func createInvitation(
        workout: Workout,
        buddy: SelectedWorkoutBuddy,
        senderUserId: String,
        senderDisplayName: String
    ) -> WorkoutInvitation {
        let invitation = WorkoutInvitation(
            workoutId: workout.id,
            workoutName: workout.name,
            senderUserId: senderUserId,
            senderDisplayName: senderDisplayName,
            recipientPhone: buddy.phoneNumber,
            recipientName: buddy.name,
            inviteCode: generateInviteCode(),
            exerciseList: formatExerciseList(workout: workout),
            estimatedDuration: workout.estimatedDuration,
            exerciseCount: workout.exerciseCount
        )

        modelContext?.insert(invitation)
        try? modelContext?.save()

        return invitation
    }

    // MARK: - Generate Message Body
    func generateMessageBody(invitation: WorkoutInvitation) -> String {
        let header = """
        Hey! Join me for \(invitation.workoutName)!
        \(invitation.estimatedDuration) min | \(invitation.exerciseCount) exercises

        """

        let exercises = invitation.exerciseList

        let footer = """

        Accept or Decline:
        https://corefitness.app/invite/\(invitation.inviteCode)

        — Sent via CoreFitness
        """

        return header + exercises + footer
    }

    // MARK: - Update Status
    func updateStatus(_ invitation: WorkoutInvitation, status: InvitationStatus) {
        invitation.status = status
        invitation.respondedAt = Date()
        try? modelContext?.save()
    }

    // MARK: - Get Pending Invitations
    func getPendingInvitations() -> [WorkoutInvitation] {
        let descriptor = FetchDescriptor<WorkoutInvitation>(
            predicate: #Predicate { $0.statusRaw == "pending" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return (try? modelContext?.fetch(descriptor)) ?? []
    }

    // MARK: - Find Invitation by Code
    func findInvitation(byCode code: String) -> WorkoutInvitation? {
        let descriptor = FetchDescriptor<WorkoutInvitation>(
            predicate: #Predicate { $0.inviteCode == code }
        )

        return try? modelContext?.fetch(descriptor).first
    }

    // MARK: - Get Recent Invitations
    func getRecentInvitations(limit: Int = 10) -> [WorkoutInvitation] {
        var descriptor = FetchDescriptor<WorkoutInvitation>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext?.fetch(descriptor)) ?? []
    }
}
