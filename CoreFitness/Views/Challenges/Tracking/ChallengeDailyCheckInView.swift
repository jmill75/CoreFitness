import SwiftUI
import SwiftData

struct ChallengeDailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let challenge: Challenge
    let participant: ChallengeParticipant
    let dayNumber: Int

    @State private var entrySource: EntrySource = .manual
    @State private var notes: String = ""
    @State private var showingTimer = false
    @State private var showingHealthKitImport = false
    @State private var showingPhotosPicker = false
    @State private var activityData = ChallengeActivityData()
    @State private var isSaving = false

    @StateObject private var timerService = ChallengeTimerService()
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Day Header
                    dayHeader

                    // Entry Source Picker
                    entrySourcePicker

                    // Type-specific tracking based on challenge goal type
                    trackingContent

                    // Notes Section
                    notesSection

                    // Photo Attachment (placeholder)
                    photoSection

                    // Save Button
                    saveButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Day \(dayNumber) Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTimer) {
                ActivityTimerView(
                    timerService: timerService,
                    onComplete: { result in
                        activityData.startTime = result.startTime
                        activityData.endTime = result.endTime
                        activityData.durationSeconds = result.durationSeconds
                        showingTimer = false
                    }
                )
            }
            .sheet(isPresented: $showingHealthKitImport) {
                HealthKitImportView(
                    challenge: challenge,
                    onImport: { importedData in
                        activityData = importedData
                        showingHealthKitImport = false
                    }
                )
            }
        }
    }

    // MARK: - Day Header

    private var dayHeader: some View {
        VStack(spacing: 8) {
            Text("Day \(dayNumber) of \(challenge.durationDays)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(challenge.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 4) {
                Image(systemName: challenge.goalType.icon)
                Text(challenge.goalType.displayName)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Entry Source Picker

    private var entrySourcePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How did you track this?")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach([EntrySource.manual, .timer, .healthkit], id: \.self) { source in
                    Button {
                        entrySource = source
                        handleEntrySourceChange(source)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: source.icon)
                                .font(.title2)
                            Text(source.rawValue)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(entrySource == source ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(entrySource == source ? .primary : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(entrySource == source ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tracking Content

    @ViewBuilder
    private var trackingContent: some View {
        switch challenge.goalType {
        case .cardio, .endurance:
            CardioTrackingView(activityData: $activityData)
        case .strength, .muscle:
            StrengthTrackingView(activityData: $activityData)
        case .flexibility:
            FlexibilityTrackingView(activityData: $activityData)
        case .wellness:
            WellnessTrackingView(activityData: $activityData)
        case .weightLoss:
            WeightLossTrackingView(activityData: $activityData)
        case .fitness:
            GeneralFitnessTrackingView(activityData: $activityData)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.headline)

            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress Photo (Optional)")
                .font(.headline)

            Button {
                showingPhotosPicker = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Add Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveCheckIn()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Day \(dayNumber)")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isSaving)
    }

    // MARK: - Actions

    private func handleEntrySourceChange(_ source: EntrySource) {
        switch source {
        case .timer:
            showingTimer = true
        case .healthkit:
            showingHealthKitImport = true
        case .manual:
            break
        }
    }

    private func saveCheckIn() {
        isSaving = true

        // Create day log
        let dayLog = ChallengeDayLog(
            dayNumber: dayNumber,
            isCompleted: true,
            entrySource: entrySource
        )
        dayLog.notes = notes.isEmpty ? nil : notes
        dayLog.participant = participant

        // Save activity data
        modelContext.insert(activityData)
        dayLog.activityData = activityData

        // Update participant stats
        participant.logDay(day: dayNumber, completed: true, activityData: activityData)

        // Insert day log
        modelContext.insert(dayLog)

        do {
            try modelContext.save()

            // Sync to CloudKit
            Task {
                await ChallengeSyncService.shared.syncParticipantData(participant)
            }

            dismiss()
        } catch {
            print("Failed to save check-in: \(error)")
            isSaving = false
        }
    }
}

// MARK: - Flexibility Tracking View

struct FlexibilityTrackingView: View {
    @Binding var activityData: ChallengeActivityData

    @State private var durationMinutes: Int = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Details")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Stepper("\(durationMinutes) min", value: $durationMinutes, in: 5...180, step: 5)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: durationMinutes) { _, newValue in
                activityData.durationSeconds = newValue * 60
            }
        }
    }
}

// MARK: - Wellness Tracking View

struct WellnessTrackingView: View {
    @Binding var activityData: ChallengeActivityData

    @State private var meditationMinutes: Int = 10
    @State private var sleepHours: Double = 7.0
    @State private var stressLevel: Int = 5
    @State private var hydrationOz: Double = 64

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wellness Metrics")
                .font(.headline)

            VStack(spacing: 12) {
                // Meditation
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Meditation")
                    Spacer()
                    Stepper("\(meditationMinutes) min", value: $meditationMinutes, in: 0...120, step: 5)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Sleep
                HStack {
                    Image(systemName: "moon.fill")
                    Text("Sleep")
                    Spacer()
                    Text(String(format: "%.1f hrs", sleepHours))
                    Stepper("", value: $sleepHours, in: 0...14, step: 0.5)
                        .labelsHidden()
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Stress Level
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Stress Level")
                        Spacer()
                        Text("\(stressLevel)/10")
                    }
                    Slider(value: Binding(
                        get: { Double(stressLevel) },
                        set: { stressLevel = Int($0) }
                    ), in: 1...10, step: 1)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Hydration
                HStack {
                    Image(systemName: "drop.fill")
                    Text("Water Intake")
                    Spacer()
                    Text(String(format: "%.0f oz", hydrationOz))
                    Stepper("", value: $hydrationOz, in: 0...200, step: 8)
                        .labelsHidden()
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: meditationMinutes) { _, newValue in
                activityData.meditationMinutes = newValue
            }
            .onChange(of: sleepHours) { _, newValue in
                activityData.sleepHours = newValue
            }
            .onChange(of: stressLevel) { _, newValue in
                activityData.stressLevel = newValue
            }
            .onChange(of: hydrationOz) { _, newValue in
                activityData.hydrationOz = newValue
            }
        }
    }
}

// MARK: - Weight Loss Tracking View

struct WeightLossTrackingView: View {
    @Binding var activityData: ChallengeActivityData

    @State private var currentWeight: Double = 150.0
    @State private var targetWeight: Double = 140.0
    @State private var bodyFatPercentage: Double = 20.0
    @State private var caloriesBurned: Int = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight & Body Composition")
                .font(.headline)

            VStack(spacing: 12) {
                // Current Weight
                HStack {
                    Image(systemName: "scalemass.fill")
                    Text("Current Weight")
                    Spacer()
                    Text(String(format: "%.1f lbs", currentWeight))
                    Stepper("", value: $currentWeight, in: 50...500, step: 0.5)
                        .labelsHidden()
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Body Fat %
                HStack {
                    Image(systemName: "percent")
                    Text("Body Fat")
                    Spacer()
                    Text(String(format: "%.1f%%", bodyFatPercentage))
                    Stepper("", value: $bodyFatPercentage, in: 5...50, step: 0.5)
                        .labelsHidden()
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Calories Burned
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Calories Burned")
                    Spacer()
                    Stepper("\(caloriesBurned) cal", value: $caloriesBurned, in: 0...2000, step: 50)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: currentWeight) { _, newValue in
                activityData.currentWeight = newValue
            }
            .onChange(of: bodyFatPercentage) { _, newValue in
                activityData.bodyFatPercentage = newValue
            }
            .onChange(of: caloriesBurned) { _, newValue in
                activityData.caloriesBurned = newValue
            }
        }
        .onAppear {
            activityData.targetWeight = targetWeight
        }
    }
}

// MARK: - General Fitness Tracking View

struct GeneralFitnessTrackingView: View {
    @Binding var activityData: ChallengeActivityData

    @State private var durationMinutes: Int = 30
    @State private var caloriesBurned: Int = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Details")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Duration")
                    Spacer()
                    Stepper("\(durationMinutes) min", value: $durationMinutes, in: 5...180, step: 5)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Image(systemName: "flame.fill")
                    Text("Calories Burned")
                    Spacer()
                    Stepper("\(caloriesBurned) cal", value: $caloriesBurned, in: 0...2000, step: 25)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: durationMinutes) { _, newValue in
                activityData.durationSeconds = newValue * 60
            }
            .onChange(of: caloriesBurned) { _, newValue in
                activityData.caloriesBurned = newValue
            }
        }
    }
}
