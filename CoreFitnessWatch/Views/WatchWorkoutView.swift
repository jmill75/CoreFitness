import SwiftUI

struct WatchWorkoutView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @EnvironmentObject var workoutState: WatchWorkoutState

    @State private var showingSetLogger = false

    var body: some View {
        TabView {
            // Main Workout View
            WorkoutMainView(showingSetLogger: $showingSetLogger)
                .environmentObject(workoutState)
                .environmentObject(connectivityManager)

            // Heart Rate View
            HeartRateView()
                .environmentObject(workoutState)

            // Controls View
            WorkoutControlsView()
                .environmentObject(connectivityManager)
                .environmentObject(workoutState)
        }
        .tabViewStyle(.verticalPage)
        .sheet(isPresented: $showingSetLogger) {
            WatchSetLoggerView()
                .environmentObject(workoutState)
                .environmentObject(connectivityManager)
        }
    }
}

// MARK: - Workout Main View
struct WorkoutMainView: View {

    @EnvironmentObject var workoutState: WatchWorkoutState
    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @Binding var showingSetLogger: Bool

    var body: some View {
        VStack(spacing: 8) {
            if workoutState.isResting {
                // Rest Timer Display
                RestTimerDisplay()
                    .environmentObject(workoutState)
            } else {
                // Active Exercise Display
                VStack(spacing: 6) {
                    // Exercise Name
                    Text(workoutState.currentExercise)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    // Set Counter
                    HStack(spacing: 4) {
                        Text("Set")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("\(workoutState.currentSet)")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)

                        Text("of \(workoutState.totalSets)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Target Weight/Reps
                    if let weight = workoutState.targetWeight, let reps = workoutState.targetReps {
                        HStack(spacing: 8) {
                            Label("\(Int(weight)) lbs", systemImage: "scalemass")
                                .font(.caption2)

                            Label("\(reps) reps", systemImage: "arrow.counterclockwise")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Log Set Button
                Button {
                    showingSetLogger = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Log Set")
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
    }
}

// MARK: - Rest Timer Display
struct RestTimerDisplay: View {

    @EnvironmentObject var workoutState: WatchWorkoutState
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            Text("REST")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time display
                VStack(spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            Text("Next: \(workoutState.currentExercise)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .onAppear {
            timeRemaining = workoutState.restTimeRemaining
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: workoutState.restTimeRemaining) { _, newValue in
            timeRemaining = newValue
        }
    }

    private var progress: CGFloat {
        guard workoutState.restTimeRemaining > 0 else { return 0 }
        return CGFloat(timeRemaining) / CGFloat(workoutState.restTimeRemaining)
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)"
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
}

// MARK: - Heart Rate View
struct HeartRateView: View {

    @EnvironmentObject var workoutState: WatchWorkoutState
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // Heart Icon with animation
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }

            // Heart Rate Value
            if let heartRate = workoutState.heartRate {
                VStack(spacing: 4) {
                    Text("\(Int(heartRate))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("BPM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 4) {
                    Text("--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text("Measuring...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Heart Rate Zone
            if let heartRate = workoutState.heartRate {
                HeartRateZoneBadge(heartRate: heartRate)
            }
        }
        .padding()
    }
}

// MARK: - Heart Rate Zone Badge
struct HeartRateZoneBadge: View {
    let heartRate: Double

    private var zone: (name: String, color: Color) {
        switch heartRate {
        case ..<100: return ("Rest", .gray)
        case 100..<120: return ("Warm Up", .blue)
        case 120..<140: return ("Fat Burn", .green)
        case 140..<160: return ("Cardio", .orange)
        case 160..<180: return ("Peak", .red)
        default: return ("Max", .purple)
        }
    }

    var body: some View {
        Text(zone.name)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(zone.color)
            .clipShape(Capsule())
    }
}

// MARK: - Workout Controls View
struct WorkoutControlsView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @EnvironmentObject var workoutState: WatchWorkoutState
    @State private var showEndConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Controls")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Skip Exercise Button
            Button {
                connectivityManager.sendWorkoutAction("skip_exercise")
            } label: {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Skip")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // End Workout Button
            Button(role: .destructive) {
                showEndConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("End")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // Workout Name
            Text(workoutState.workoutName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
        .confirmationDialog("End Workout?", isPresented: $showEndConfirmation) {
            Button("End Workout", role: .destructive) {
                connectivityManager.sendWorkoutAction("end_workout")
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Watch Set Logger View
struct WatchSetLoggerView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutState: WatchWorkoutState
    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager

    @State private var weight: Double = 0
    @State private var reps: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Weight Input
                VStack(spacing: 4) {
                    Text("Weight")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if weight >= 5 { weight -= 5 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        Text("\(Int(weight))")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .frame(width: 60)

                        Button {
                            weight += 5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("lbs")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Reps Input
                VStack(spacing: 4) {
                    Text("Reps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            if reps > 0 { reps -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        Text("\(reps)")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .frame(width: 60)

                        Button {
                            reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Save Button
                Button {
                    connectivityManager.sendSetCompleted(
                        exerciseId: workoutState.currentExercise,
                        weight: weight,
                        reps: reps
                    )
                    dismiss()
                } label: {
                    Text("Save Set")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
            .navigationTitle("Log Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                weight = workoutState.targetWeight ?? 0
                reps = workoutState.targetReps ?? 10
            }
        }
    }
}

#Preview {
    let state = WatchWorkoutState()
    state.isWorkoutActive = true
    state.workoutName = "Push Day"
    state.currentExercise = "Bench Press"
    state.currentSet = 2
    state.totalSets = 4
    state.targetWeight = 135
    state.targetReps = 10

    return WatchWorkoutView()
        .environmentObject(WatchPhoneConnectivityManager())
        .environmentObject(state)
}
