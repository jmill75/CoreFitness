import SwiftUI

struct WatchContentView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager
    @EnvironmentObject var workoutState: WatchWorkoutState

    var body: some View {
        NavigationStack {
            if workoutState.isWorkoutActive {
                WatchWorkoutView()
            } else {
                WatchHomeView()
            }
        }
        .onAppear {
            setupCallbacks()
        }
    }

    private func setupCallbacks() {
        // Workout started from iPhone
        connectivityManager.onWorkoutStarted = { name, exercise, totalSets in
            workoutState.isWorkoutActive = true
            workoutState.workoutName = name
            workoutState.currentExercise = exercise
            workoutState.totalSets = totalSets
            workoutState.currentSet = 1
            // Start extended session to keep Watch app alive
            workoutState.startExtendedSession()
            // Start elapsed time tracking
            workoutState.startElapsedTimer()
        }

        // Countdown started (show 3-2-1-GO)
        connectivityManager.onCountdownStarted = {
            workoutState.startCountdown()
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

        // Health data update
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
        }

        // Elapsed time sync from iPhone
        connectivityManager.onElapsedTimeUpdate = { time in
            workoutState.elapsedTime = time
        }

        // Mirrored workout received from HealthKit (auto-launch scenario)
        connectivityManager.onMirroredWorkoutReceived = {
            // Request sync from iPhone to get workout details
            connectivityManager.requestSync()
        }
    }
}

// MARK: - Watch Home View
struct WatchHomeView: View {

    @EnvironmentObject var connectivityManager: WatchPhoneConnectivityManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)

                    Text("CoreFitness")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.top, 8)

                // Connection Status
                HStack(spacing: 6) {
                    Circle()
                        .fill(connectivityManager.isPhoneReachable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(connectivityManager.connectionStatus)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .padding(.horizontal)

                // Quick Stats Card
                VStack(spacing: 8) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        StatItem(icon: "flame.fill", value: "0", label: "cal", color: .orange)
                        StatItem(icon: "figure.walk", value: "0", label: "steps", color: .green)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Start Workout Prompt
                VStack(spacing: 8) {
                    Image(systemName: "iphone")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    Text("Start a workout on your iPhone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .padding(.horizontal)
        }
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
