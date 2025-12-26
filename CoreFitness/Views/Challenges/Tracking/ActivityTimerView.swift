import SwiftUI

struct ActivityTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var timerService: ChallengeTimerService
    let onComplete: (TimerResult) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // Timer Display
                Text(timerService.formattedTime)
                    .font(.system(size: 72, weight: .thin, design: .monospaced))
                    .monospacedDigit()

                // Status
                Text(statusText)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Controls
                HStack(spacing: 40) {
                    if timerService.isIdle {
                        // Start Button
                        Button {
                            timerService.start()
                        } label: {
                            Circle()
                                .fill(.green)
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "play.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                        }
                    } else if timerService.isRunning {
                        // Pause Button
                        Button {
                            timerService.pause()
                        } label: {
                            Circle()
                                .fill(.orange)
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "pause.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                        }

                        // Stop Button
                        Button {
                            let result = timerService.stop()
                            onComplete(result)
                        } label: {
                            Circle()
                                .fill(.red)
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "stop.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                        }
                    } else if timerService.isPaused {
                        // Resume Button
                        Button {
                            timerService.resume()
                        } label: {
                            Circle()
                                .fill(.green)
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "play.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                        }

                        // Stop Button
                        Button {
                            let result = timerService.stop()
                            onComplete(result)
                        } label: {
                            Circle()
                                .fill(.red)
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "stop.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Activity Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        timerService.reset()
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusText: String {
        switch timerService.state {
        case .idle:
            return "Tap play to start"
        case .running:
            return "Recording..."
        case .paused:
            return "Paused"
        }
    }
}

// MARK: - Preview

#Preview {
    ActivityTimerView(
        timerService: ChallengeTimerService(),
        onComplete: { _ in }
    )
}
