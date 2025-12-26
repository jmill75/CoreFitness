import SwiftUI
import HealthKit

struct HealthKitImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager

    let challenge: Challenge
    let onImport: (ChallengeActivityData) -> Void

    @State private var workouts: [HKWorkout] = []
    @State private var isLoading = true
    @State private var selectedWorkout: HKWorkout?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if workouts.isEmpty {
                    emptyView
                } else {
                    workoutList
                }
            }
            .navigationTitle("Import from Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await loadWorkouts()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading workouts from Apple Health...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Unable to Load Workouts")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await loadWorkouts() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Recent Workouts")
                .font(.headline)
            Text("Complete a workout using Apple Watch or the Fitness app, then come back to import it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Workout List

    private var workoutList: some View {
        List(workouts, id: \.uuid) { workout in
            WorkoutRow(workout: workout, isSelected: selectedWorkout == workout)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedWorkout = workout
                }
        }
        .safeAreaInset(edge: .bottom) {
            if selectedWorkout != nil {
                Button {
                    importSelectedWorkout()
                } label: {
                    Text("Import Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Actions

    private func loadWorkouts() async {
        isLoading = true
        errorMessage = nil

        // Fetch workouts from the last 7 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!

        workouts = await healthKitManager.fetchWorkouts(from: startDate, to: endDate)
        isLoading = false
    }

    private func importSelectedWorkout() {
        guard let workout = selectedWorkout else { return }

        let activityData = healthKitManager.createActivityData(from: workout)

        // Enrich with heart rate data
        Task {
            await healthKitManager.enrichActivityDataWithHeartRate(activityData)
            await MainActor.run {
                onImport(activityData)
            }
        }
    }
}

// MARK: - Workout Row

struct WorkoutRow: View {
    let workout: HKWorkout
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            Image(systemName: workoutIcon)
                .font(.title2)
                .foregroundStyle(isSelected ? .white : .accentColor)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(workoutName)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(formattedDuration, systemImage: "clock")
                    if let distance = formattedDistance {
                        Label(distance, systemImage: "figure.run")
                    }
                    if let calories = formattedCalories {
                        Label(calories, systemImage: "flame.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "dumbbell.fill"
        case .highIntensityIntervalTraining: return "bolt.fill"
        case .hiking: return "figure.hiking"
        default: return "figure.mixed.cardio"
        }
    }

    private var workoutName: String {
        switch workout.workoutActivityType {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stair Climbing"
        case .rowing: return "Rowing"
        default: return "Workout"
        }
    }

    private var formattedDuration: String {
        let minutes = Int(workout.duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }

    private var formattedDistance: String? {
        guard let distance = workout.totalDistance?.doubleValue(for: .mile()) else {
            return nil
        }
        return String(format: "%.2f mi", distance)
    }

    private var formattedCalories: String? {
        guard let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) else {
            return nil
        }
        return String(format: "%.0f cal", calories)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.startDate)
    }
}

// MARK: - Preview

#Preview {
    HealthKitImportView(
        challenge: Challenge(name: "30-Day Fitness", creatorId: "user123"),
        onImport: { _ in }
    )
    .environmentObject(HealthKitManager())
}
