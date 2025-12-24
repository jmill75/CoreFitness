import SwiftUI

struct DailyCheckInView: View {

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var mood: Double = 3
    @State private var soreness: Double = 2
    @State private var stress: Double = 2
    @State private var sleepQuality: Double = 3
    @State private var selectedPlan: TodayPlanType = .workout
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showConfetti = false
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
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
                        TodaysPlanCard(selectedPlan: $selectedPlan)

                        // Notes Section
                        NotesCard(notes: $notes)

                        // Save Button
                        GradientButton(isSaving ? "Saving..." : "Save Check-In", icon: isSaving ? nil : "checkmark.circle.fill", gradient: AppGradients.primary) {
                            saveCheckIn()
                        }
                        .disabled(isSaving)
                        .padding(.top, 8)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemGroupedBackground))

                // Confetti overlay
                if showConfetti {
                    GeometryReader { geometry in
                        ForEach(confettiPieces) { piece in
                            ConfettiView(piece: piece, screenHeight: geometry.size.height)
                        }
                    }
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
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

    private func saveCheckIn() {
        isSaving = true
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // TODO: Save to Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSaving = false
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            triggerConfetti()
        }
    }

    private func triggerConfetti() {
        showConfetti = true
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                color: [Color.accentRed, Color.accentOrange, Color.accentYellow, Color.accentGreen, Color.accentBlue, Color.accentTeal].randomElement()!,
                size: CGFloat.random(in: 8...14),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.3)
            )
        }

        // Dismiss after confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
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
    @State private var handHeight: CGFloat = 60
    @State private var textOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            // Animated Waving Hand
            Text("👋")
                .font(.system(size: 50))
                .rotationEffect(.degrees(waveRotation), anchor: .bottomTrailing)
                .scaleEffect(popScale)
                .opacity(handOpacity)
                .frame(height: handHeight)
                .onAppear {
                    startWaveAnimation()
                }

            VStack(spacing: 8) {
                Text("How are you feeling?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your daily check-in helps personalize your experience and track your wellness journey.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .offset(y: textOffset)

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
            .background(.white.opacity(0.2))
            .clipShape(Capsule())
            .offset(y: textOffset)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppGradients.sunset)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.accentOrange.opacity(0.3), radius: 15, y: 8)
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

        // Fade out hand and move text up
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.6)) {
                handOpacity = 0
                popScale = 0.5
            }
            withAnimation(.easeInOut(duration: 0.8)) {
                handHeight = 0
                textOffset = -20
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

    @Binding var selectedPlan: TodayPlanType

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                IconBadge("calendar", color: .accentGreen, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Plan")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("What's on the schedule?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Plan Type Selector
            HStack(spacing: 10) {
                ForEach(TodayPlanType.allCases, id: \.self) { plan in
                    PlanTypeButton(
                        plan: plan,
                        isSelected: selectedPlan == plan
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Today Plan Type
enum TodayPlanType: String, CaseIterable {
    case restDay = "Rest Day"
    case workout = "Workout"
    case cardio = "Cardio"

    var icon: String {
        switch self {
        case .restDay: return "moon.zzz.fill"
        case .workout: return "figure.strengthtraining.traditional"
        case .cardio: return "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .restDay: return .accentBlue
        case .workout: return .accentOrange
        case .cardio: return .accentGreen
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

// MARK: - Check-In Slider Content (Apple Glass Style)
struct CheckInSliderContent: View {

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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                // Icon with glass background
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
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

                // Value badge with glass effect
                Text(labels[Int(value)])
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(sliderColor.gradient)
                            .shadow(color: sliderColor.opacity(0.4), radius: 4, y: 2)
                    )
            }

            // Slider with glass track
            VStack(spacing: 8) {
                GlassSlider(
                    value: $value,
                    in: 0...Double(labels.count - 1),
                    step: 1,
                    tint: sliderColor
                )
                .frame(height: 32)

                // Step indicators
                HStack {
                    ForEach(0..<labels.count, id: \.self) { index in
                        if index > 0 { Spacer() }
                        Circle()
                            .fill(Int(value) == index ? sliderColor : Color.primary.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Labels
            HStack {
                Text(labels.first ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(labels.last ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {

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
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
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
