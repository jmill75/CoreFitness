import SwiftUI
import MessageUI

struct ShareAndStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager

    let workout: Workout
    let onComplete: () -> Void

    @StateObject private var invitationService = WorkoutInvitationService()

    @State private var step: ShareStep = .selectBuddy
    @State private var selectedBuddy: SelectedWorkoutBuddy?
    @State private var currentInvitation: WorkoutInvitation?
    @State private var showMessageComposer = false
    @State private var showBuddyPicker = false
    @State private var sendSuccess = false

    enum ShareStep {
        case selectBuddy
        case preparingMessage
        case composingMessage
        case sending
        case complete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressBar

                    // Content based on step
                    Group {
                        switch step {
                        case .selectBuddy:
                            selectBuddyContent
                        case .preparingMessage:
                            preparingContent
                        case .composingMessage, .sending:
                            sendingContent
                        case .complete:
                            completeContent
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Share & Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                invitationService.setModelContext(modelContext)
            }
            .sheet(isPresented: $showBuddyPicker) {
                WorkoutBuddyPickerView { buddy in
                    selectedBuddy = buddy
                    prepareMessage()
                }
            }
            .fullScreenCover(isPresented: $showMessageComposer) {
                if MessageComposerAvailability.canSendMessages {
                    if let buddy = selectedBuddy, let invitation = currentInvitation {
                        WorkoutMessageComposer(
                            recipient: buddy.phoneNumber,
                            messageBody: invitationService.generateMessageBody(invitation: invitation)
                        ) { success in
                            handleMessageResult(success: success)
                        }
                    }
                } else {
                    // Simulator fallback
                    if let buddy = selectedBuddy, let invitation = currentInvitation {
                        MessageComposerUnavailableView(
                            recipient: buddy.phoneNumber,
                            messageBody: invitationService.generateMessageBody(invitation: invitation)
                        ) {
                            handleMessageResult(success: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(stepIndex >= index ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var stepIndex: Int {
        switch step {
        case .selectBuddy: return 0
        case .preparingMessage: return 1
        case .composingMessage, .sending: return 2
        case .complete: return 3
        }
    }

    // MARK: - Select Buddy Content
    private var selectBuddyContent: some View {
        VStack(spacing: 32) {
            Spacer()

            // Workout preview card
            workoutPreviewCard

            // Instructions
            VStack(spacing: 12) {
                Text("Invite a Workout Buddy")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose someone to join you for this workout. They'll receive a text with all the exercise details.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Select buddy button
            Button {
                themeManager.mediumImpact()
                showBuddyPicker = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Choose Workout Buddy")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Workout Preview Card
    private var workoutPreviewCard: some View {
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

            Text(workout.name)
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 24) {
                Label("\(workout.exerciseCount) exercises", systemImage: "dumbbell.fill")
                Label("~\(workout.estimatedDuration) min", systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .padding(.horizontal, 24)
    }

    // MARK: - Preparing Content
    private var preparingContent: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Preparing invitation...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Sending Content
    private var sendingContent: some View {
        VStack(spacing: 24) {
            Spacer()

            if let buddy = selectedBuddy {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Text(buddy.initials)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }

                    Text("Sending to \(buddy.name)")
                        .font(.headline)

                    Text(buddy.phoneNumber)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView()
                .padding(.top, 16)

            Spacer()
        }
    }

    // MARK: - Complete Content
    private var completeContent: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: sendSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(sendSuccess ? .green : .red)
            }

            VStack(spacing: 12) {
                Text(sendSuccess ? "Invitation Sent!" : "Message Not Sent")
                    .font(.title2)
                    .fontWeight(.bold)

                if sendSuccess, let buddy = selectedBuddy {
                    Text("\(buddy.name) will receive your workout invite")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                themeManager.notifySuccess()
                onComplete()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text(sendSuccess ? "Start Workout" : "Start Anyway")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "2d6a4f"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Actions
    private func prepareMessage() {
        step = .preparingMessage

        guard let buddy = selectedBuddy else { return }

        // Create invitation record
        let invitation = invitationService.createInvitation(
            workout: workout,
            buddy: buddy,
            senderUserId: "current_user", // TODO: Use real auth
            senderDisplayName: "Workout Buddy" // TODO: Use real user name
        )

        currentInvitation = invitation

        // Small delay for UX, then show composer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            step = .composingMessage
            showMessageComposer = true
        }
    }

    private func handleMessageResult(success: Bool) {
        showMessageComposer = false
        sendSuccess = success

        if success {
            currentInvitation?.messageType = .sms
            try? modelContext.save()
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            step = .complete
        }
    }
}

#Preview {
    ShareAndStartView(
        workout: Workout(
            name: "Full Body Strength",
            estimatedDuration: 45,
            difficulty: .intermediate,
            creationType: .preset
        ),
        onComplete: {}
    )
    .environmentObject(WorkoutManager())
    .environmentObject(ThemeManager())
}
