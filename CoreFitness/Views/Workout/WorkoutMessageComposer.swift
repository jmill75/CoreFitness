import SwiftUI
import MessageUI

struct WorkoutMessageComposer: UIViewControllerRepresentable {
    let recipient: String
    let messageBody: String
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [recipient]
        controller.body = messageBody
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onComplete: (Bool) -> Void

        init(onComplete: @escaping (Bool) -> Void) {
            self.onComplete = onComplete
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            let success = result == .sent
            controller.dismiss(animated: true) {
                self.onComplete(success)
            }
        }
    }
}

// MARK: - Message Availability Check
struct MessageComposerAvailability {
    static var canSendMessages: Bool {
        MFMessageComposeViewController.canSendText()
    }
}

// MARK: - Fallback View for Simulator
struct MessageComposerUnavailableView: View {
    let recipient: String
    let messageBody: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "message.badge.waveform")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Messages Unavailable")
                    .font(.headline)

                Text("This device cannot send text messages. In a real device, the message would be sent to:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("To:")
                            .fontWeight(.medium)
                        Text(recipient)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Text("Message Preview:")
                        .fontWeight(.medium)

                    ScrollView {
                        Text(messageBody)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8)
                .padding(.horizontal)

                Button("Continue (Simulated Send)") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Message Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview("Unavailable View") {
    MessageComposerUnavailableView(
        recipient: "+1 (555) 123-4567",
        messageBody: """
        Hey! Join me for Full Body Strength!
        45 min | 8 exercises

        1. Bench Press - 3x10 (90s rest)
        2. Incline Press - 3x12 (60s rest)
        3. Dumbbell Rows - 3x10 (90s rest)
        4. Lat Pulldowns - 3x12 (60s rest)
        5. Shoulder Press - 3x10 (90s rest)

        Accept or Decline:
        https://corefitness.app/invite/ABC123

        — Sent via CoreFitness
        """,
        onDismiss: {}
    )
}
