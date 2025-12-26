import SwiftUI

struct CardioTrackingView: View {
    @Binding var activityData: ChallengeActivityData

    @State private var distanceValue: Double = 0.0
    @State private var distanceUnit: DistanceUnit = .miles
    @State private var durationMinutes: Int = 30
    @State private var durationSeconds: Int = 0
    @State private var caloriesBurned: Int = 200
    @State private var averageHeartRate: Int = 140

    var calculatedPace: String {
        guard distanceValue > 0 else { return "--:--" }
        let totalSeconds = (durationMinutes * 60) + durationSeconds
        let paceSeconds = Int(Double(totalSeconds) / distanceValue)
        let paceMinutes = paceSeconds / 60
        let paceSecs = paceSeconds % 60
        return String(format: "%d:%02d /mi", paceMinutes, paceSecs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cardio Details")
                .font(.headline)

            VStack(spacing: 12) {
                // Distance
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "figure.run")
                        Text("Distance")
                        Spacer()
                        Picker("Unit", selection: $distanceUnit) {
                            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                Text(unit.abbreviation).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }

                    HStack {
                        TextField("0.0", value: $distanceValue, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text(distanceUnit.abbreviation)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Duration")
                        Spacer()
                    }

                    HStack {
                        Picker("Minutes", selection: $durationMinutes) {
                            ForEach(0..<180) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 80)
                        .clipped()

                        Text("min")
                            .foregroundStyle(.secondary)

                        Picker("Seconds", selection: $durationSeconds) {
                            ForEach(0..<60) { second in
                                Text(String(format: "%02d", second)).tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 80)
                        .clipped()

                        Text("sec")
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Pace (calculated)
                HStack {
                    Image(systemName: "speedometer")
                    Text("Average Pace")
                    Spacer()
                    Text(calculatedPace)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Calories
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Calories Burned")
                    Spacer()
                    Stepper("\(caloriesBurned) cal", value: $caloriesBurned, in: 0...2000, step: 25)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Heart Rate (optional)
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Avg Heart Rate")
                    Spacer()
                    Stepper("\(averageHeartRate) bpm", value: $averageHeartRate, in: 60...220, step: 5)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: distanceValue) { _, _ in updateActivityData() }
        .onChange(of: distanceUnit) { _, _ in updateActivityData() }
        .onChange(of: durationMinutes) { _, _ in updateActivityData() }
        .onChange(of: durationSeconds) { _, _ in updateActivityData() }
        .onChange(of: caloriesBurned) { _, _ in updateActivityData() }
        .onChange(of: averageHeartRate) { _, _ in updateActivityData() }
    }

    private func updateActivityData() {
        activityData.distanceValue = distanceValue
        activityData.distanceUnit = distanceUnit
        activityData.durationSeconds = (durationMinutes * 60) + durationSeconds
        activityData.caloriesBurned = caloriesBurned
        activityData.averageHeartRate = averageHeartRate

        // Calculate pace
        if distanceValue > 0 {
            let totalSeconds = (durationMinutes * 60) + durationSeconds
            activityData.averagePaceSecondsPerMile = Int(Double(totalSeconds) / distanceValue)
        }
    }
}
