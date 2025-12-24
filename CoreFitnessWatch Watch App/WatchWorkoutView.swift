import SwiftUI
import WatchKit
import HealthKit

struct WatchWorkoutView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @EnvironmentObject var workoutState: WatchWorkoutState

    @State private var showingSetLogger = false

    var body: some View {
        Group {
            if workoutState.isCountingDown {
                // Countdown Animation
                CountdownView()
                    .environmentObject(workoutState)
            } else {
                TabView {
                    // Main Workout View
                    WorkoutMainView(showingSetLogger: $showingSetLogger)
                        .environmentObject(workoutState)
                        .environmentObject(connectivityManager)

                    // Heart Rate & Metrics View
                    MetricsView()
                        .environmentObject(workoutState)

                    // Controls View
                    WorkoutControlsView()
                        .environmentObject(connectivityManager)
                        .environmentObject(workoutState)
                }
                .tabViewStyle(.verticalPage)
            }
        }
        .sheet(isPresented: $showingSetLogger) {
            WatchSetLoggerView()
                .environmentObject(workoutState)
                .environmentObject(connectivityManager)
        }
    }
}

// MARK: - Countdown View
struct CountdownView: View {

    @EnvironmentObject var workoutState: WatchWorkoutState
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Background pulse
            Circle()
                .fill(Color.green.opacity(0.3))
                .scaleEffect(scale * 1.5)
                .opacity(opacity * 0.5)

            // Main countdown circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.green, .green.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 140, height: 140)
                .scaleEffect(scale)
                .opacity(opacity)

            // Countdown number or GO!
            if workoutState.countdownValue > 0 {
                Text("\(workoutState.countdownValue)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(scale)
            } else {
                Text("GO!")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(scale)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onChange(of: workoutState.countdownValue) { _, _ in
            animateCountdown()
        }
        .onAppear {
            animateCountdown()
        }
    }

    private func animateCountdown() {
        // Reset
        scale = 0.5
        opacity = 0

        // Animate in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
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
                    .environmentObject(connectivityManager)
            } else {
                // Elapsed Time Header
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(formattedElapsedTime)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    Spacer()
                    // Set Progress
                    Text("Set \(workoutState.currentSet)/\(workoutState.totalSets)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 8)

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * setProgress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: setProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 8)

                // Exercise Name - LARGE
                Text(workoutState.currentExercise)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)

                // Target Weight/Reps - BIG & CLEAR
                if let weight = workoutState.targetWeight, let reps = workoutState.targetReps {
                    HStack(spacing: 16) {
                        VStack(spacing: 0) {
                            Text("\(Int(weight))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("lbs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("×")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            Text("\(reps)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Spacer()

                // Log Set Button - BIG & PROMINENT
                Button {
                    WKInterfaceDevice.current().play(.click)
                    showingSetLogger = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("LOG SET")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private var formattedElapsedTime: String {
        let time = workoutState.elapsedTime
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var setProgress: CGFloat {
        guard workoutState.totalSets > 0 else { return 0 }
        return CGFloat(workoutState.currentSet - 1) / CGFloat(workoutState.totalSets)
    }
}

// MARK: - Rest Timer Display
struct RestTimerDisplay: View {

    @EnvironmentObject var workoutState: WatchWorkoutState
    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @State private var timeRemaining: Int = 0
    @State private var initialDuration: Int = 0
    @State private var timer: Timer?
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 6) {
            // REST Label with pulse
            Text("REST")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.black)
                .foregroundStyle(timeRemaining <= 10 ? .red : .orange)
                .scaleEffect(pulseAnimation && timeRemaining <= 5 ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: pulseAnimation)

            // Timer Ring - LARGE
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timeRemaining <= 10 ? Color.red : Color.orange,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                // Time display - BIG
                VStack(spacing: 0) {
                    Text(timeString)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(timeRemaining <= 10 ? .red : .primary)
                    Text("seconds")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // Control Buttons - BIG
            HStack(spacing: 12) {
                // Skip Button
                Button {
                    WKInterfaceDevice.current().play(.click)
                    connectivityManager.sendWorkoutAction("skip_rest")
                    workoutState.isResting = false
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                        Text("Skip")
                            .font(.caption2)
                    }
                    .frame(width: 60, height: 50)
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                // +30s Button
                Button {
                    WKInterfaceDevice.current().play(.click)
                    timeRemaining += 30
                    initialDuration += 30
                    connectivityManager.sendWorkoutAction("extend_rest_30")
                } label: {
                    VStack(spacing: 2) {
                        Text("+30")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("sec")
                            .font(.caption2)
                    }
                    .frame(width: 60, height: 50)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .onAppear {
            timeRemaining = workoutState.restTimeRemaining
            initialDuration = max(workoutState.restTimeRemaining, 1)
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: workoutState.restTimeRemaining) { _, newValue in
            timeRemaining = newValue
            if newValue > initialDuration {
                initialDuration = newValue
            }
        }
    }

    private var progress: CGFloat {
        guard initialDuration > 0 else { return 0 }
        return CGFloat(timeRemaining) / CGFloat(initialDuration)
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

                // Pulse animation and haptics for last 5 seconds
                if timeRemaining <= 5 && timeRemaining > 0 {
                    pulseAnimation.toggle()
                    WKInterfaceDevice.current().play(.click)
                } else if timeRemaining == 0 {
                    WKInterfaceDevice.current().play(.notification)
                }
            }
        }
    }
}

// MARK: - Metrics View (Heart Rate, Calories, SpO2)
struct MetricsView: View {

    @EnvironmentObject var workoutState: WatchWorkoutState
    @State private var heartPulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Heart Rate - PROMINENT
                VStack(spacing: 4) {
                    ZStack {
                        // Pulse ring
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 4)
                            .frame(width: 80, height: 80)
                            .scaleEffect(heartPulse ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: heartPulse)

                        // Heart icon
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.red)
                            .scaleEffect(heartPulse ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: heartPulse)
                    }

                    if let hr = workoutState.heartRate {
                        Text("\(Int(hr))")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        Text("BPM")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Heart Rate Zone
                        HeartRateZoneBadge(heartRate: hr)
                    } else {
                        Text("--")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("Measuring...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear { heartPulse = true }

                Divider()
                    .padding(.horizontal)

                // Stats Row
                HStack(spacing: 20) {
                    // Calories
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        Text("\(workoutState.caloriesBurned)")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                        Text("cal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // SpO2
                    VStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                        if let spo2 = workoutState.bloodOxygen {
                            Text("\(Int(spo2))%")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                        } else {
                            Text("--%")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }
                        Text("SpO2")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Time
                    VStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                        Text(formattedTime)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                        Text("time")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var formattedTime: String {
        let time = Int(workoutState.elapsedTime)
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%d:%02d", minutes, seconds)
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
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(zone.color)
            .clipShape(Capsule())
    }
}

// MARK: - Workout Controls View
struct WorkoutControlsView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @EnvironmentObject var workoutState: WatchWorkoutState
    @State private var showEndConfirmation = false
    @State private var isPaused = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Workout info header
                VStack(spacing: 4) {
                    Text(workoutState.workoutName)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .lineLimit(1)

                    Text("Exercise \(workoutState.currentSet) of \(workoutState.totalSets)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                // Pause/Resume Button - BIG
                Button {
                    WKInterfaceDevice.current().play(.click)
                    isPaused.toggle()
                    connectivityManager.sendWorkoutAction(isPaused ? "pause" : "resume")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                        Text(isPaused ? "Resume" : "Pause")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(isPaused ? .green : .yellow)

                // Skip Exercise Button
                Button {
                    WKInterfaceDevice.current().play(.click)
                    connectivityManager.sendWorkoutAction("skip_exercise")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                        Text("Skip Exercise")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                // End Workout Button
                Button(role: .destructive) {
                    WKInterfaceDevice.current().play(.click)
                    showEndConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("End Workout")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 8)
        }
        .confirmationDialog("End Workout?", isPresented: $showEndConfirmation) {
            Button("End Workout", role: .destructive) {
                WKInterfaceDevice.current().play(.notification)
                connectivityManager.sendWorkoutAction("end_workout")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your progress will be saved.")
        }
    }
}

// MARK: - Watch Set Logger View
struct WatchSetLoggerView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutState: WatchWorkoutState
    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager

    @State private var weight: Double = 0
    @State private var reps: Double = 0
    @State private var editingWeight: Bool = true
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Weight Input - BIG
                    VStack(spacing: 4) {
                        Text("WEIGHT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(editingWeight ? .blue : .secondary)

                        HStack(spacing: 12) {
                            Button {
                                WKInterfaceDevice.current().play(.click)
                                if weight >= 5 { weight -= 5 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(editingWeight ? .blue : .gray)
                            }
                            .buttonStyle(.plain)

                            Text("\(Int(weight))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .frame(width: 80)
                                .foregroundStyle(editingWeight ? .primary : .secondary)

                            Button {
                                WKInterfaceDevice.current().play(.click)
                                weight += 5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(editingWeight ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingWeight = true
                            WKInterfaceDevice.current().play(.click)
                        }

                        Text("lbs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(editingWeight ? Color.blue.opacity(0.15) : Color.clear)
                    .cornerRadius(12)

                    // Reps Input - BIG
                    VStack(spacing: 4) {
                        Text("REPS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(!editingWeight ? .green : .secondary)

                        HStack(spacing: 12) {
                            Button {
                                WKInterfaceDevice.current().play(.click)
                                if reps > 0 { reps -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(!editingWeight ? .green : .gray)
                            }
                            .buttonStyle(.plain)

                            Text("\(Int(reps))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .frame(width: 80)
                                .foregroundStyle(!editingWeight ? .primary : .secondary)

                            Button {
                                WKInterfaceDevice.current().play(.click)
                                reps += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(!editingWeight ? .green : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingWeight = false
                            WKInterfaceDevice.current().play(.click)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(!editingWeight ? Color.green.opacity(0.15) : Color.clear)
                    .cornerRadius(12)

                    // Crown hint
                    Text("Turn crown to adjust")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    // Save Button - BIG GREEN
                    Button {
                        WKInterfaceDevice.current().play(.success)
                        connectivityManager.sendSetCompleted(
                            exerciseId: workoutState.currentExercise,
                            weight: weight,
                            reps: Int(reps)
                        )
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("SAVE SET")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.horizontal, 8)
            }
            .focusable(true)
            .focused($isFocused)
            .digitalCrownRotation(
                editingWeight ? $weight : $reps,
                from: 0,
                through: editingWeight ? 500 : 100,
                by: editingWeight ? 2.5 : 1,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
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
                reps = Double(workoutState.targetReps ?? 10)
                isFocused = true
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
