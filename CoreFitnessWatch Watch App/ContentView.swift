import SwiftUI
import Combine

struct WatchContentView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @EnvironmentObject var workoutState: WatchWorkoutState

    var body: some View {
        NavigationStack {
            if workoutState.isWorkoutActive || workoutState.isCountingDown {
                WatchWorkoutView()
            } else {
                WatchHomeView()
            }
        }
        .onAppear {
            setupCallbacks()
            // Start extended session to keep app alive
            workoutState.startExtendedSession()
        }
    }

    private func setupCallbacks() {
        // Countdown started
        connectivityManager.onCountdownStarted = {
            workoutState.isWorkoutActive = true
            workoutState.startCountdown()
        }

        // Workout started
        connectivityManager.onWorkoutStarted = { name, exercise, totalSets in
            workoutState.isWorkoutActive = true
            workoutState.workoutName = name
            workoutState.currentExercise = exercise
            workoutState.totalSets = totalSets
            workoutState.currentSet = 1
            // Don't start local timer - iPhone syncs elapsed time every second
        }

        // Workout ended
        connectivityManager.onWorkoutEnded = { _, _ in
            workoutState.reset()
        }

        // Exercise changed
        connectivityManager.onExerciseChanged = { exercise, setNumber, totalSets, weight, reps in
            workoutState.currentExercise = exercise
            workoutState.currentSet = setNumber
            workoutState.totalSets = totalSets
            workoutState.targetWeight = weight
            workoutState.targetReps = reps
            workoutState.isResting = false
        }

        // Rest timer started
        connectivityManager.onRestTimerStarted = { duration in
            workoutState.isResting = true
            workoutState.restTimeRemaining = duration
        }

        // Rest timer ended
        connectivityManager.onRestTimerEnded = {
            workoutState.isResting = false
            workoutState.restTimeRemaining = 0
        }

        // Health data update (heart rate, calories, SpO2)
        connectivityManager.onHealthDataUpdate = { heartRate, calories, bloodOxygen in
            if let hr = heartRate {
                workoutState.heartRate = hr
            }
            if let cal = calories {
                workoutState.caloriesBurned = cal
            }
            if let spo2 = bloodOxygen {
                workoutState.bloodOxygen = spo2
            }

            // Send health data to iPhone
            if workoutState.isWorkoutActive {
                connectivityManager.sendHealthDataToPhone(
                    heartRate: heartRate,
                    calories: calories
                )
            }
        }

        // Elapsed time sync
        connectivityManager.onElapsedTimeUpdate = { time in
            workoutState.elapsedTime = time
        }

        // Mirrored workout received from iPhone (auto-launches Watch app)
        connectivityManager.onMirroredWorkoutReceived = {
            // The mirrored session was received - activate the workout UI
            // The actual workout data will come via the regular workout_started message
            if !workoutState.isWorkoutActive {
                workoutState.isWorkoutActive = true
                workoutState.startExtendedSession()
            }
        }
    }
}

// MARK: - Watch Home View
struct WatchHomeView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header with time
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("CoreFitness")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                    }
                    Spacer()
                    // Connection indicator
                    Circle()
                        .fill(connectivityManager.isPhoneReachable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                }
                .padding(.horizontal, 4)

                // Weekly Progress Card
                VStack(spacing: 8) {
                    HStack {
                        Text("This Week")
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Week day indicators
                    HStack(spacing: 4) {
                        ForEach(0..<7) { day in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(day < 3 ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        if day < 3 {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                Text(dayLabel(day))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Quick Stats
                HStack(spacing: 8) {
                    QuickStatCard(
                        icon: "flame.fill",
                        value: "3",
                        label: "workouts",
                        color: .orange
                    )
                    QuickStatCard(
                        icon: "clock.fill",
                        value: "2:15",
                        label: "hours",
                        color: .blue
                    )
                }

                // Ready to workout message
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }

                    Text("Ready to train?")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        Image(systemName: "iphone")
                            .font(.caption2)
                        Text("Start on iPhone")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 8)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func dayLabel(_ day: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        let today = Calendar.current.component(.weekday, from: Date()) - 1
        let index = (today - (6 - day) + 7) % 7
        return days[index]
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchPhoneConnectivityManager())
        .environmentObject(WatchWorkoutState())
}
