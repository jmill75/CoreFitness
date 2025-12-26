import SwiftUI
import SwiftData

struct DailyCheckInView: View {

    // MARK: - Environment
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var mood: Double = 3
    @State private var soreness: Double = 2
    @State private var stress: Double = 2
    @State private var sleepQuality: Double = 3
    @State private var selectedPlans: Set<TodayPlanType> = [.workout]
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showSuccessOverlay = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var ringProgress: CGFloat = 0
    @State private var hasCheckedInToday = false

    // Check-in data storage
    @AppStorage("lastCheckInDate") private var lastCheckInDateString: String = ""
    @AppStorage("lastCheckInMood") private var savedMood: Double = 3
    @AppStorage("lastCheckInSoreness") private var savedSoreness: Double = 2
    @AppStorage("lastCheckInStress") private var savedStress: Double = 2
    @AppStorage("lastCheckInSleep") private var savedSleepQuality: Double = 3

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if hasCheckedInToday {
                            // Already checked in view
                            AlreadyCheckedInView(
                                mood: savedMood,
                                sleepQuality: savedSleepQuality,
                                stress: savedStress,
                                soreness: savedSoreness
                            )
                        } else {
                            // Hero Header Card
                            CheckInHeaderCard()

                            // Wellness Metrics Section
                            WellnessMetricsCard(
                                mood: $mood,
                                sleepQuality: $sleepQuality,
                                stress: $stress
                            )

                            // Physical Status Section
                            PhysicalStatusCard(soreness: $soreness)

                            // Today's Plan Section
                            TodaysPlanCard(selectedPlans: $selectedPlans)

                            // Notes Section
                            NotesCard(notes: $notes)

                            // Save Button
                            GradientButton(isSaving ? "Saving..." : "Save Check-In", icon: isSaving ? nil : "checkmark.circle.fill", gradient: AppGradients.primary) {
                                saveCheckIn()
                            }
                            .disabled(isSaving)
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    checkIfAlreadyCheckedIn()
                }

                // Success overlay
                if showSuccessOverlay {
                    ZStack {
                        // Blurred background
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 24) {
                            // Animated checkmark circle
                            ZStack {
                                // Background ring
                                Circle()
                                    .stroke(Color.accentGreen.opacity(0.2), lineWidth: 8)
                                    .frame(width: 120, height: 120)

                                // Animated progress ring
                                Circle()
                                    .trim(from: 0, to: ringProgress)
                                    .stroke(
                                        Color.accentGreen,
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))

                                // Checkmark
                                Image(systemName: "checkmark")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundStyle(Color.accentGreen)
                                    .scaleEffect(checkmarkScale)
                                    .opacity(checkmarkOpacity)
                            }

                            VStack(spacing: 8) {
                                Text("Check-In Saved!")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Great job tracking your wellness!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .opacity(checkmarkOpacity)
                        }
                        .padding(40)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
        }
    }

    private func checkIfAlreadyCheckedIn() {
        hasCheckedInToday = lastCheckInDateString == todayString
    }

    private func saveCheckIn() {
        isSaving = true
        themeManager.mediumImpact()

        // Save check-in data to AppStorage (for quick access)
        lastCheckInDateString = todayString
        savedMood = mood
        savedSoreness = soreness
        savedStress = stress
        savedSleepQuality = sleepQuality

        // Save MoodEntry to SwiftData for persistence and sync
        let moodEntry = MoodEntry(
            date: Date(),
            mood: moodFromValue(mood),
            energyLevel: Int(sleepQuality * 2), // Convert 1-5 to 2-10
            stressLevel: Int(stress * 2),
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(moodEntry)

        // Also save/update DailyHealthData for today
        saveDailyHealthData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            showSuccessAnimation()

            // Post notification for data refresh
            NotificationCenter.default.post(name: .dailyCheckInSaved, object: nil)
        }
    }

    private func moodFromValue(_ value: Double) -> Mood {
        switch Int(value) {
        case 5: return .amazing
        case 4: return .good
        case 3: return .okay
        case 2: return .tired
        default: return .stressed
        }
    }

    private func saveDailyHealthData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if we already have data for today
        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= today
            }
        )

        do {
            let existingData = try modelContext.fetch(descriptor)

            if let todayData = existingData.first {
                // Update existing entry
                todayData.energyLevel = Int(sleepQuality * 2) // Convert 1-5 to 2-10
                todayData.stressLevel = Int(stress * 2)
            } else {
                // Create new entry
                let healthData = DailyHealthData(date: today)
                healthData.energyLevel = Int(sleepQuality * 2)
                healthData.stressLevel = Int(stress * 2)
                modelContext.insert(healthData)
            }
        } catch {
            print("Error saving daily health data: \(error)")
        }
    }

    private func showSuccessAnimation() {
        // Show overlay
        withAnimation(.easeOut(duration: 0.2)) {
            showSuccessOverlay = true
        }

        // Animate ring
        withAnimation(.easeOut(duration: 0.6)) {
            ringProgress = 1.0
        }

        // Pop in checkmark after ring completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            themeManager.notifySuccess()

            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }

        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSuccessOverlay = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

// MARK: - Already Checked In View
struct AlreadyCheckedInView: View {
    let mood: Double
    let sleepQuality: Double
    let stress: Double
    let soreness: Double

    private func moodLabel(_ value: Double) -> String {
        switch Int(value) {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Moderate"
        }
    }

    private func moodEmoji(_ value: Double) -> String {
        switch Int(value) {
        case 1: return "😔"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "😄"
        default: return "🙂"
        }
    }

    private func moodColor(_ value: Double) -> Color {
        switch Int(value) {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .accentGreen
        case 5: return .accentGreen
        default: return .yellow
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Success Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentGreen)
                }

                Text("Already Checked In Today")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You've completed your daily check-in. Come back tomorrow!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // Today's Summary Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Summary")
                    .font(.headline)
                    .fontWeight(.bold)

                // Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    CheckInSummaryItem(
                        label: "Mood",
                        value: moodLabel(mood),
                        emoji: moodEmoji(mood),
                        color: moodColor(mood)
                    )

                    CheckInSummaryItem(
                        label: "Sleep Quality",
                        value: moodLabel(sleepQuality),
                        emoji: sleepQuality >= 4 ? "😴" : "🥱",
                        color: moodColor(sleepQuality)
                    )

                    CheckInSummaryItem(
                        label: "Stress Level",
                        value: moodLabel(stress),
                        emoji: stress <= 2 ? "😌" : stress >= 4 ? "😰" : "😐",
                        color: stress <= 2 ? .accentGreen : stress >= 4 ? .red : .orange
                    )

                    CheckInSummaryItem(
                        label: "Soreness",
                        value: moodLabel(soreness),
                        emoji: soreness <= 2 ? "💪" : soreness >= 4 ? "🤕" : "😐",
                        color: soreness <= 2 ? .accentGreen : soreness >= 4 ? .red : .orange
                    )
                }
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Spacer()
        }
    }
}

// MARK: - Check-In Summary Item
struct CheckInSummaryItem: View {
    let label: String
    let value: String
    let emoji: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Confetti Piece Model
struct ConfettiPiece: Identifiable {
    let id: UUID
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

// MARK: - Confetti View
struct ConfettiView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat

    @State private var yPosition: CGFloat = -20
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1
    @State private var xOffset: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(currentRotation))
            .position(x: piece.x + xOffset, y: yPosition)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeIn(duration: 2.5)
                    .delay(piece.delay)
                ) {
                    yPosition = screenHeight + 50
                    opacity = 0
                }
                withAnimation(
                    .linear(duration: 2.5)
                    .repeatForever(autoreverses: false)
                    .delay(piece.delay)
                ) {
                    currentRotation = piece.rotation + 720
                }
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(piece.delay)
                ) {
                    xOffset = CGFloat.random(in: -30...30)
                }
            }
    }
}

// MARK: - Check-In Header Card (Hero)
struct CheckInHeaderCard: View {

    @State private var waveRotation: Double = 0
    @State private var popScale: CGFloat = 1.0
    @State private var handOpacity: Double = 1.0
    @State private var showHand: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            // Animated Waving Hand
            if showHand {
                Text("👋")
                    .font(.system(size: 50))
                    .rotationEffect(.degrees(waveRotation), anchor: .bottomTrailing)
                    .scaleEffect(popScale)
                    .opacity(handOpacity)
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        startWaveAnimation()
                    }
            }

            VStack(spacing: 8) {
                Text("How are you feeling?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your daily check-in helps personalize your experience and track your wellness journey.")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            // Date badge
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(Date(), style: .date)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentTeal.opacity(0.2))
            .clipShape(Capsule())
        }
        .foregroundStyle(.primary)
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.tertiarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.accentTeal.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func startWaveAnimation() {
        // Pop up
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            popScale = 1.2
        }

        // Wave 4 times
        let waveDuration: Double = 0.15
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * waveDuration + 0.2) {
                withAnimation(.easeInOut(duration: waveDuration)) {
                    waveRotation = i % 2 == 0 ? 25 : -5
                }
            }
        }

        // Return to rest and pop back down
        DispatchQueue.main.asyncAfter(deadline: .now() + 8 * waveDuration + 0.3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                waveRotation = 0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                popScale = 1.0
            }
        }

        // Fade out hand - content stays centered
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                handOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showHand = false
                }
            }
        }
    }
}

// MARK: - Wellness Metrics Card
struct WellnessMetricsCard: View {

    @Binding var mood: Double
    @Binding var sleepQuality: Double
    @Binding var stress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                IconBadge("chart.bar.fill", color: .brandPrimary, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wellness Metrics")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Rate how you're feeling today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 16) {
                // Mood Slider
                CheckInSliderContent(
                    title: "Mood",
                    value: $mood,
                    icon: "face.smiling",
                    color: .accentYellow,
                    labels: ["Terrible", "Poor", "Okay", "Good", "Great"]
                )

                // Sleep Quality Slider
                CheckInSliderContent(
                    title: "Sleep Quality",
                    value: $sleepQuality,
                    icon: "moon.zzz",
                    color: .accentBlue,
                    labels: ["Terrible", "Poor", "Fair", "Good", "Excellent"]
                )

                // Stress Slider (inverted: low stress = green, high stress = red)
                CheckInSliderContent(
                    title: "Stress Level",
                    value: $stress,
                    icon: "brain.head.profile",
                    color: .accentOrange,
                    labels: ["Calm", "Low", "Moderate", "High", "Overwhelmed"],
                    invertColors: true
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Physical Status Card
struct PhysicalStatusCard: View {

    @Binding var soreness: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                IconBadge("figure.stand", color: .accentBlue, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Physical Status")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("How does your body feel?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Soreness Slider (inverted: no soreness = green, very sore = red)
            CheckInSliderContent(
                title: "Soreness",
                value: $soreness,
                icon: "figure.walk",
                color: .accentRed,
                labels: ["None", "Mild", "Moderate", "Sore", "Very Sore"],
                invertColors: true
            )
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Today's Plan Card
struct TodaysPlanCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedPlans: Set<TodayPlanType>

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                IconBadge("calendar", color: .accentGreen, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Plan")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(selectedPlans.contains(.restDay) ? "Rest day selected" : "Select all that apply")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection count badge
                if selectedPlans.count > 1 {
                    Text("\(selectedPlans.count) selected")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentGreen)
                        .clipShape(Capsule())
                }
            }

            // Plan Type Selector (Multi-select) - 2 rows of 3
            VStack(spacing: 10) {
                // First row
                HStack(spacing: 10) {
                    ForEach(Array(TodayPlanType.allCases.prefix(3)), id: \.self) { plan in
                        PlanTypeButton(
                            plan: plan,
                            isSelected: selectedPlans.contains(plan)
                        ) {
                            togglePlan(plan)
                        }
                    }
                }

                // Second row
                HStack(spacing: 10) {
                    ForEach(Array(TodayPlanType.allCases.suffix(3)), id: \.self) { plan in
                        PlanTypeButton(
                            plan: plan,
                            isSelected: selectedPlans.contains(plan)
                        ) {
                            togglePlan(plan)
                        }
                    }
                }
            }

            // Show combined plan summary
            if selectedPlans.count > 1 {
                HStack(spacing: 8) {
                    ForEach(Array(selectedPlans).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { plan in
                        HStack(spacing: 4) {
                            Image(systemName: plan.icon)
                                .font(.caption2)
                            Text(plan.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(plan.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(plan.color.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func togglePlan(_ plan: TodayPlanType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if plan == .restDay {
                // Rest is exclusive - if selecting rest, clear everything else
                if selectedPlans.contains(.restDay) {
                    // Already selected, don't allow deselecting if only one
                    if selectedPlans.count > 1 {
                        selectedPlans.remove(.restDay)
                    }
                } else {
                    // Selecting rest clears all other selections
                    selectedPlans.removeAll()
                    selectedPlans.insert(.restDay)
                }
            } else {
                // Non-rest option selected
                if selectedPlans.contains(plan) {
                    // Don't allow deselecting if it's the only one selected
                    if selectedPlans.count > 1 {
                        selectedPlans.remove(plan)
                    }
                } else {
                    // If rest is currently selected, remove it first
                    selectedPlans.remove(.restDay)
                    selectedPlans.insert(plan)
                }
            }
        }
        themeManager.lightImpact()
    }
}

// MARK: - Today Plan Type
enum TodayPlanType: String, CaseIterable {
    case restDay = "Rest"
    case workout = "Workout"
    case cardio = "Cardio"
    case walking = "Walking"
    case cycling = "Cycling"
    case yoga = "Yoga"

    var icon: String {
        switch self {
        case .restDay: return "moon.zzz.fill"
        case .workout: return "figure.strengthtraining.traditional"
        case .cardio: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .yoga: return "figure.yoga"
        }
    }

    var color: Color {
        switch self {
        case .restDay: return .accentBlue
        case .workout: return .accentOrange
        case .cardio: return .accentGreen
        case .walking: return .accentTeal
        case .cycling: return .accentYellow
        case .yoga: return .purple
        }
    }
}

// MARK: - Plan Type Button
struct PlanTypeButton: View {
    let plan: TodayPlanType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: plan.icon)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(plan.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? plan.color : Color(.systemGray5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isSelected ? plan.color : Color.clear, lineWidth: 2)
                )

                // Checkmark badge for selected items
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, plan.color)
                        .background(Circle().fill(plan.color))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notes Card
struct NotesCard: View {

    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                IconBadge("note.text", color: .secondary, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notes")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Anything else to share?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            TextField("How's your day going?", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Check-In Slider Content (Apple Native Style)
struct CheckInSliderContent: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    @Binding var value: Double
    let icon: String
    let color: Color
    let labels: [String]
    var invertColors: Bool = false  // When true, low = good (green), high = bad (red)

    private var normalizedValue: Double {
        value / Double(labels.count - 1)
    }

    private var sliderColor: Color {
        let effectiveValue = invertColors ? (1.0 - normalizedValue) : normalizedValue
        switch effectiveValue {
        case 0..<0.25: return .accentRed
        case 0.25..<0.5: return .accentOrange
        case 0.5..<0.75: return .accentYellow
        default: return .accentGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Value badge
                Text(labels[Int(value)])
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(sliderColor.gradient)
                    )
            }

            // Native Apple Slider
            Slider(
                value: $value,
                in: 0...Double(labels.count - 1),
                step: 1
            ) {
                Text(title)
            } minimumValueLabel: {
                Text(labels.first ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text(labels.last ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .tint(sliderColor)
            .onChange(of: value) { _, _ in
                themeManager.lightImpact()
            }

            // Step indicators
            HStack(spacing: 0) {
                ForEach(0..<labels.count, id: \.self) { index in
                    Circle()
                        .fill(Int(value) == index ? sliderColor : Color.primary.opacity(0.2))
                        .frame(width: 8, height: 8)
                    if index < labels.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
                .onChange(of: isOn) { _, _ in
                    themeManager.lightImpact()
                }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DailyCheckInView()
}
