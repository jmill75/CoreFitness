import SwiftUI
import SwiftData

struct InvitationResponseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navigationState: NavigationState

    let inviteCode: String

    @State private var invitation: WorkoutInvitation?
    @State private var isLoading = true
    @State private var hasResponded = false
    @State private var responseStatus: InvitationStatus?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading invitation...")
                } else if let invitation = invitation {
                    invitationContent(invitation)
                } else {
                    notFoundContent
                }
            }
            .navigationTitle("Workout Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadInvitation()
            }
        }
    }

    // MARK: - Invitation Content
    private func invitationContent(_ invitation: WorkoutInvitation) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Sender info
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "2d6a4f"), Color(hex: "1b4332")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(invitation.senderDisplayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("invited you to workout together!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Workout info card
            VStack(spacing: 16) {
                Text(invitation.workoutName)
                    .font(.title3)
                    .fontWeight(.bold)

                HStack(spacing: 24) {
                    Label("\(invitation.exerciseCount) exercises", systemImage: "dumbbell.fill")
                    Label("~\(invitation.estimatedDuration) min", systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                // Exercise list preview
                Text(invitation.exerciseList)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(6)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

            // Response buttons
            if !hasResponded {
                VStack(spacing: 12) {
                    Button {
                        respondToInvitation(.accepted)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept & Join")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "2d6a4f"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        respondToInvitation(.declined)
                    } label: {
                        Text("Maybe Next Time")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            } else {
                responseConfirmation
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Response Confirmation
    private var responseConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: responseStatus == .accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(responseStatus == .accepted ? .green : .orange)

            Text(responseStatus == .accepted ? "You're in!" : "Response sent")
                .font(.headline)

            if responseStatus == .accepted {
                Text("Your buddy will be notified")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Not Found Content
    private var notFoundContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Invitation Not Found")
                .font(.title2)
                .fontWeight(.bold)

            Text("This invitation may have expired or doesn't exist.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Actions
    private func loadInvitation() {
        let invitationService = WorkoutInvitationService()
        invitationService.setModelContext(modelContext)

        invitation = invitationService.findInvitation(byCode: inviteCode)
        isLoading = false
    }

    private func respondToInvitation(_ status: InvitationStatus) {
        guard let invitation = invitation else { return }

        themeManager.mediumImpact()

        let invitationService = WorkoutInvitationService()
        invitationService.setModelContext(modelContext)
        invitationService.updateStatus(invitation, status: status)

        responseStatus = status
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            hasResponded = true
        }

        if status == .accepted {
            themeManager.notifySuccess()
        }
    }
}

#Preview {
    InvitationResponseView(inviteCode: "ABC123")
        .environmentObject(ThemeManager())
        .environmentObject(NavigationState())
}
