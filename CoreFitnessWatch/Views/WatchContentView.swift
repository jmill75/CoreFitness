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
        connectivityManager.onWorkoutStarted = { name, exercise, totalSets in
            workoutState.isWorkoutActive = true
            workoutState.workoutName = name
            workoutState.currentExercise = exercise
            workoutState.totalSets = totalSets
            workoutState.currentSet = 1
        }

        connectivityManager.onWorkoutEnded = { _, _ in
            workoutState.reset()
        }

        connectivityManager.onExerciseChanged = { exercise, setNumber, totalSets, weight, reps in
            workoutState.currentExercise = exercise
            workoutState.currentSet = setNumber
            workoutState.totalSets = totalSets
            workoutState.targetWeight = weight
            workoutState.targetReps = reps
            workoutState.isResting = false
        }

        connectivityManager.onRestTimerStarted = { duration in
            workoutState.isResting = true
            workoutState.restTimeRemaining = duration
        }

        connectivityManager.onRestTimerEnded = {
            workoutState.isResting = false
            workoutState.restTimeRemaining = 0
        }

        connectivityManager.onHealthDataUpdate = { heartRate in
            workoutState.heartRate = heartRate
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
