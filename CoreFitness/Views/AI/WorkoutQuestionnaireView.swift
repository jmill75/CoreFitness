import SwiftUI

// MARK: - Workout Questionnaire View

struct WorkoutQuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var generator = WorkoutGeneratorEngine.shared

    @State private var showGeneratedPlan = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Content
                    TabView(selection: $generator.currentStep) {
                        ForEach(QuestionnaireStep.allCases, id: \.self) { step in
                            stepContent(for: step)
                                .tag(step)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: generator.currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding()
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        generator.reset()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showGeneratedPlan) {
                if generator.generatedPlan != nil {
                    GeneratedWorkoutPreviewView()
                        .environmentObject(generator)
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(QuestionnaireStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(stepColor(for: step))
                    .frame(height: 4)
            }
        }
    }

    private func stepColor(for step: QuestionnaireStep) -> Color {
        if step.rawValue < generator.currentStep.rawValue {
            return .accentGreen
        } else if step == generator.currentStep {
            return .brandPrimary
        } else {
            return Color(.tertiarySystemFill)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private func stepContent(for step: QuestionnaireStep) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                stepHeader(step)
                    .padding(.top, 24)

                // Content
                switch step {
                case .goal:
                    goalStep
                case .schedule:
                    scheduleStep
                case .location:
                    locationStep
                case .cardio:
                    cardioStep
                case .experience:
                    experienceStep
                case .preferences:
                    preferencesStep
                case .review:
                    reviewStep
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal)
        }
    }

    private func stepHeader(_ step: QuestionnaireStep) -> some View {
        VStack(spacing: 8) {
            Image(systemName: step.icon)
                .font(.system(size: 32))
                .foregroundStyle(.brandPrimary)

            Text(step.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(step.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Goal Step

    private var goalStep: some View {
        VStack(spacing: 12) {
            ForEach(WorkoutGoal.allCases) { goal in
                GoalOptionCard(
                    goal: goal,
                    isSelected: generator.questionnaire.primaryGoal == goal,
                    onTap: {
                        generator.questionnaire.primaryGoal = goal
                        themeManager.lightImpact()
                    }
                )
            }
        }
    }

    // MARK: - Schedule Step

    private var scheduleStep: some View {
        VStack(spacing: 24) {
            // Days per week
            VStack(alignment: .leading, spacing: 12) {
                Text("Training Days")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(2...7, id: \.self) { days in
                        Button {
                            generator.questionnaire.daysPerWeek = days
                            themeManager.lightImpact()
                        } label: {
                            Text("\(days)")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(
                                    generator.questionnaire.daysPerWeek == days
                                        ? Color.brandPrimary
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                                .foregroundStyle(
                                    generator.questionnaire.daysPerWeek == days
                                        ? .white
                                        : .primary
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("days per week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Program length
            VStack(alignment: .leading, spacing: 12) {
                Text("Program Length")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach([4, 8, 12, 16], id: \.self) { weeks in
                        Button {
                            generator.questionnaire.programWeeks = weeks
                            themeManager.lightImpact()
                        } label: {
                            Text("\(weeks)")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    generator.questionnaire.programWeeks == weeks
                                        ? Color.brandPrimary
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                                .foregroundStyle(
                                    generator.questionnaire.programWeeks == weeks
                                        ? .white
                                        : .primary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Session duration
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Duration")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(SessionDuration.allCases) { duration in
                        Button {
                            generator.questionnaire.sessionDuration = duration
                            themeManager.lightImpact()
                        } label: {
                            VStack(spacing: 4) {
                                Text(duration.displayName)
                                    .font(.headline)
                                Text(duration.description)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                generator.questionnaire.sessionDuration == duration
                                    ? Color.brandPrimary
                                    : Color(.tertiarySystemGroupedBackground)
                            )
                            .foregroundStyle(
                                generator.questionnaire.sessionDuration == duration
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Location Step

    private var locationStep: some View {
        VStack(spacing: 24) {
            // Location selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Where will you train?")
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(WorkoutLocation.allCases) { location in
                        Button {
                            generator.questionnaire.location = location
                            themeManager.lightImpact()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: location.icon)
                                    .font(.title2)
                                Text(location.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                generator.questionnaire.location == location
                                    ? Color.brandPrimary
                                    : Color(.tertiarySystemGroupedBackground)
                            )
                            .foregroundStyle(
                                generator.questionnaire.location == location
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Equipment selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Equipment")
                    .font(.headline)

                FlowLayout(spacing: 8) {
                    ForEach(Equipment.allCases) { equipment in
                        EquipmentChip(
                            equipment: equipment,
                            isSelected: generator.questionnaire.availableEquipment.contains(equipment),
                            onTap: {
                                if generator.questionnaire.availableEquipment.contains(equipment) {
                                    generator.questionnaire.availableEquipment.remove(equipment)
                                } else {
                                    generator.questionnaire.availableEquipment.insert(equipment)
                                }
                                themeManager.lightImpact()
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Cardio Step

    private var cardioStep: some View {
        VStack(spacing: 24) {
            // Include cardio toggle
            Toggle(isOn: $generator.questionnaire.includeCardio) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Include Cardio")
                        .font(.headline)
                }
            }
            .tint(.brandPrimary)

            if generator.questionnaire.includeCardio {
                Divider()

                // Cardio frequency
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cardio Frequency")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(CardioFrequency.allCases.filter { $0 != .none }) { frequency in
                            Button {
                                generator.questionnaire.cardioFrequency = frequency
                                themeManager.lightImpact()
                            } label: {
                                Text(frequency.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        generator.questionnaire.cardioFrequency == frequency
                                            ? Color.brandPrimary
                                            : Color(.tertiarySystemGroupedBackground)
                                    )
                                    .foregroundStyle(
                                        generator.questionnaire.cardioFrequency == frequency
                                            ? .white
                                            : .primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Cardio types
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred Cardio Types")
                        .font(.headline)

                    FlowLayout(spacing: 8) {
                        ForEach(CardioType.allCases) { cardioType in
                            CardioChip(
                                cardioType: cardioType,
                                isSelected: generator.questionnaire.cardioTypes.contains(cardioType),
                                onTap: {
                                    if generator.questionnaire.cardioTypes.contains(cardioType) {
                                        generator.questionnaire.cardioTypes.remove(cardioType)
                                    } else {
                                        generator.questionnaire.cardioTypes.insert(cardioType)
                                    }
                                    themeManager.lightImpact()
                                }
                            )
                        }
                    }

                    Text("Select your preferred activities (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Experience Step

    private var experienceStep: some View {
        VStack(spacing: 12) {
            ForEach(ExperienceLevel.allCases) { level in
                ExperienceLevelCard(
                    level: level,
                    isSelected: generator.questionnaire.experienceLevel == level,
                    onTap: {
                        generator.questionnaire.experienceLevel = level
                        themeManager.lightImpact()
                    }
                )
            }
        }
    }

    // MARK: - Preferences Step

    private var preferencesStep: some View {
        VStack(spacing: 24) {
            // Focus areas
            VStack(alignment: .leading, spacing: 12) {
                Text("Focus Areas (Optional)")
                    .font(.headline)

                Text("Select muscle groups you want to emphasize")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(MuscleGroup.allCases) { muscle in
                        MuscleChip(
                            muscle: muscle,
                            isSelected: generator.questionnaire.focusAreas.contains(muscle),
                            onTap: {
                                if generator.questionnaire.focusAreas.contains(muscle) {
                                    generator.questionnaire.focusAreas.remove(muscle)
                                } else {
                                    generator.questionnaire.focusAreas.insert(muscle)
                                }
                                themeManager.lightImpact()
                            }
                        )
                    }
                }
            }

            Divider()

            // Additional notes
            VStack(alignment: .leading, spacing: 12) {
                Text("Additional Notes (Optional)")
                    .font(.headline)

                TextField("Any injuries, preferences, or special requests...", text: $generator.questionnaire.additionalNotes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .lineLimit(3...6)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Review Step

    private var reviewStep: some View {
        VStack(spacing: 16) {
            ReviewRow(title: "Goal", value: generator.questionnaire.primaryGoal.rawValue)
            ReviewRow(title: "Training Days", value: "\(generator.questionnaire.daysPerWeek) days/week")
            ReviewRow(title: "Program Length", value: "\(generator.questionnaire.programWeeks) weeks")
            ReviewRow(title: "Session Duration", value: generator.questionnaire.sessionDuration.displayName)
            ReviewRow(title: "Location", value: generator.questionnaire.location.rawValue)
            ReviewRow(title: "Experience", value: generator.questionnaire.experienceLevel.rawValue)

            if generator.questionnaire.includeCardio {
                ReviewRow(title: "Cardio", value: generator.questionnaire.cardioFrequency.rawValue)
            }

            if !generator.questionnaire.focusAreas.isEmpty {
                ReviewRow(
                    title: "Focus Areas",
                    value: generator.questionnaire.focusAreas.map { $0.rawValue }.joined(separator: ", ")
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if generator.currentStep != .goal {
                Button {
                    generator.previousStep()
                    themeManager.lightImpact()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if generator.currentStep == .review {
                Button {
                    generateWorkout()
                } label: {
                    HStack {
                        if generator.isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("Generate")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(generator.isGenerating)
            } else {
                Button {
                    generator.nextStep()
                    themeManager.lightImpact()
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(generator.canProceed ? Color.brandPrimary : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!generator.canProceed)
            }
        }
    }

    // MARK: - Actions

    private func generateWorkout() {
        Task {
            do {
                _ = try await generator.generateWorkoutPlan()
                showGeneratedPlan = true
                themeManager.mediumImpact()
            } catch {
                // Error is stored in generator.generationError
                themeManager.errorNotification()
            }
        }
    }
}

// MARK: - Supporting Views

struct GoalOptionCard: View {
    let goal: WorkoutGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .brandPrimary)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.brandPrimary : Color.brandPrimary.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.brandPrimary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct ExperienceLevelCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.brandPrimary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct EquipmentChip: View {
    let equipment: Equipment
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: equipment.icon)
                    .font(.caption)
                Text(equipment.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandPrimary : Color(.tertiarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CardioChip: View {
    let cardioType: CardioType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: cardioType.icon)
                    .font(.caption)
                Text(cardioType.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.red : Color(.tertiarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct MuscleChip: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(muscle.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentGreen : Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ReviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + maxHeight)
        }
    }
}

#Preview {
    WorkoutQuestionnaireView()
        .environmentObject(ThemeManager())
}
