import SwiftUI
import SwiftData

struct SetLoggerSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var reps: Int = 10
    @State private var weight: Double = 0
    @State private var selectedRPE: Int? = nil
    @State private var lastWorkoutSets: [CompletedSet] = []
    @State private var lastWorkoutDate: Date?
    @State private var showSetLoggedFeedback = false


    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Set number header with exercise name and category
                    VStack(spacing: 8) {
                        Text("Set \(workoutManager.currentSetNumber)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        // Exercise category badge
                        if let category = workoutManager.currentExercise?.exercise?.safeCategory {
                            Text(category.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.5)
                                .foregroundStyle(categoryColor(category))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(categoryColor(category).opacity(0.2))
                                .clipShape(Capsule())
                        }

                        Text(workoutManager.currentExercise?.exercise?.name ?? "Exercise")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.top, 8)

                        // Last workout reference
                        if !lastWorkoutSets.isEmpty {
                            lastWorkoutView
                        }
                    }
                    .padding(.top, 8)

                    // Main input area
                    HStack(spacing: 40) {
                        // Reps input
                        VStack(spacing: 16) {
                            Text("REPS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.gray)
                                .tracking(1)

                            HStack(spacing: 20) {
                                RepeatingButton(
                                    action: {
                                        if reps > 1 { reps -= 1 }
                                    },
                                    label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "minus")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                )

                                Text("\(reps)")
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundStyle(.cyan)
                                    .frame(width: 80)

                                RepeatingButton(
                                    action: {
                                        reps += 1
                                    },
                                    label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.cyan.opacity(0.3))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "plus")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.cyan)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Weight input
                    VStack(spacing: 16) {
                        Text("WEIGHT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                            .tracking(1)

                        HStack(spacing: 16) {
                            // -5 button with press-and-hold
                            RepeatingButton(
                                action: {
                                    if weight >= 5 { weight -= 5 }
                                },
                                label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        Text("-5")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                            )

                            Text(themeManager.formatWeight(weight))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                                .frame(width: 150)

                            // +5 button with press-and-hold
                            RepeatingButton(
                                action: {
                                    weight += 5
                                },
                                label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        Text("+5")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.green)
                                    }
                                }
                            )
                        }

                        // Quick weight adjustments
                        HStack(spacing: 10) {
                            ForEach([-10.0, -2.5, 2.5, 10.0], id: \.self) { adjustment in
                                Button {
                                    weight = max(0, weight + adjustment)
                                    themeManager.lightImpact()
                                } label: {
                                    Text(adjustment > 0 ? "+\(adjustment.formatted())" : "\(adjustment.formatted())")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(adjustment > 0 ? .green : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // RPE Selection (optional)
                    VStack(spacing: 12) {
                        Text("RPE (optional)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                            .tracking(1)

                        HStack(spacing: 8) {
                            ForEach([6, 7, 8, 9, 10], id: \.self) { rpe in
                                Button {
                                    selectedRPE = selectedRPE == rpe ? nil : rpe
                                    themeManager.lightImpact()
                                } label: {
                                    Text("\(rpe)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(selectedRPE == rpe ? .black : .white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            selectedRPE == rpe ?
                                                rpeColor(rpe) :
                                                Color.gray.opacity(0.2)
                                        )
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }

                    Spacer()

                    // Save button
                    Button {
                        showSetLoggedFeedback = true
                        themeManager.mediumImpact()

                        // Delay the actual save to show feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            workoutManager.logSet(reps: reps, weight: weight, rpe: selectedRPE)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Save Set")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }
                .padding()

                // Set Logged Feedback Overlay
                if showSetLoggedFeedback {
                    SetLoggedFeedbackView(
                        setNumber: workoutManager.currentSetNumber,
                        reps: reps,
                        weight: weight
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showSetLoggedFeedback)
            .preferredColorScheme(.dark)
            .onAppear {
                reps = workoutManager.loggedReps
                weight = workoutManager.loggedWeight
                fetchLastWorkout()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        workoutManager.showSetLogger = false
                        workoutManager.currentPhase = .exercising
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 6...7: return .green
        case 8: return .yellow
        case 9: return .orange
        case 10: return .red
        default: return .gray
        }
    }

    private func categoryColor(_ category: ExerciseCategory) -> Color {
        switch category {
        case .strength: return .orange
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .pink
        case .hiit: return .yellow
        case .stretching: return .mint
        case .running: return .blue
        case .cycling: return .green
        case .swimming: return .cyan
        case .calisthenics: return .indigo
        }
    }

    // MARK: - Last Workout View
    private var lastWorkoutView: some View {
        VStack(spacing: 6) {
            // Header with date
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                Text("Last: \(lastWorkoutDateText)")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.5))

            // Sets display
            HStack(spacing: 8) {
                ForEach(lastWorkoutSets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                    Text("\(Int(set.weight))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 12)
    }

    private var lastWorkoutDateText: String {
        guard let date = lastWorkoutDate else { return "" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 14 {
            return "1 week ago"
        } else {
            return "\(days / 7) weeks ago"
        }
    }

    private func fetchLastWorkout() {
        guard let exerciseId = workoutManager.currentExercise?.exercise?.id,
              let currentSessionId = workoutManager.currentSession?.id else { return }

        // Fetch all completed sets
        let descriptor = FetchDescriptor<CompletedSet>()

        do {
            let allSets = try modelContext.fetch(descriptor)

            // Filter to this exercise from previous sessions
            let relevantSets = allSets.filter { set in
                set.workoutExercise?.exercise?.id == exerciseId &&
                set.session?.id != currentSessionId
            }

            // Group by session and get the most recent session's sets
            let sessionGroups = Dictionary(grouping: relevantSets) { $0.session?.id }

            // Find the most recent session
            if let mostRecentEntry = sessionGroups.compactMap({ (sessionId, sets) -> (Date, [CompletedSet])? in
                guard let date = sets.first?.session?.startedAt else { return nil }
                return (date, sets)
            }).sorted(by: { $0.0 > $1.0 }).first {
                lastWorkoutSets = mostRecentEntry.1
                lastWorkoutDate = mostRecentEntry.0
            }
        } catch {
            print("Failed to fetch last workout: \(error)")
        }
    }
}

// MARK: - Repeating Button (Press-and-Hold with Acceleration)
struct RepeatingButton<Label: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var timer: Timer?
    @State private var isPressed = false
    @State private var pressStartTime: Date?
    @State private var currentInterval: TimeInterval = 0.15

    // Acceleration settings
    private let initialInterval: TimeInterval = 0.15
    private let acceleratedInterval: TimeInterval = 0.05
    private let accelerationDelay: TimeInterval = 2.0

    var body: some View {
        label()
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            pressStartTime = Date()
                            currentInterval = initialInterval

                            // Immediate action on press
                            action()
                            themeManager.lightImpact()

                            // Start repeating after delay
                            startTimer()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        pressStartTime = nil
                        currentInterval = initialInterval
                        timer?.invalidate()
                        timer = nil
                    }
            )
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: false) { _ in
            guard isPressed else { return }

            action()
            themeManager.lightImpact()

            // Check if we should accelerate
            if let startTime = pressStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed >= accelerationDelay && currentInterval != acceleratedInterval {
                    currentInterval = acceleratedInterval
                    themeManager.mediumImpact() // Indicate acceleration
                }
            }

            // Schedule next iteration
            startTimer()
        }
    }
}

// MARK: - Set Logged Feedback View
struct SetLoggedFeedbackView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let setNumber: Int
    let reps: Int
    let weight: Double

    @State private var showContent = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 1.0
    @State private var particles: [SetLoggedParticle] = []
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Extra dark tint
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Particles layer
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            // Content
            VStack(spacing: 20) {
                // Checkmark circle with animated rings
                ZStack {
                    // Expanding rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            .frame(width: 100 + CGFloat(i * 30), height: 100 + CGFloat(i * 30))
                            .scaleEffect(ringScale + CGFloat(i) * 0.1)
                            .opacity(ringOpacity - Double(i) * 0.2)
                    }

                    // Pulsing glow
                    Circle()
                        .fill(Color.green.opacity(glowPulse ? 0.4 : 0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)
                        .scaleEffect(glowPulse ? 1.2 : 1.0)

                    // Circle background with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "10ac84"), Color.green, Color(hex: "1dd1a1")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.green.opacity(0.6), radius: 20, y: 5)
                        .scaleEffect(checkmarkScale)

                    // Checkmark with bounce
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkScale)
                }

                // Text with staggered animation
                VStack(spacing: 8) {
                    Text("SET LOGGED")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(showContent ? 1 : 0.8)

                    Text("Set \(setNumber) • \(reps) reps • \(themeManager.formatWeight(weight))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
            }
        }
        .onAppear {
            // Create particles
            createParticles()

            // Animate checkmark with overshoot
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)) {
                checkmarkScale = 1.0
            }

            // Animate rings
            withAnimation(.easeOut(duration: 0.8)) {
                ringScale = 1.5
                ringOpacity = 0
            }

            // Animate text
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15)) {
                showContent = true
            }

            // Pulse glow
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                glowPulse = true
            }

            // Haptic celebration
            themeManager.notifySuccess()
        }
    }

    private func createParticles() {
        let colors: [Color] = [.green, .cyan, .yellow, .white, Color(hex: "1dd1a1")]
        let center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 50)

        for _ in 0..<20 {
            let angle = Double.random(in: 0...2 * .pi)
            let distance = CGFloat.random(in: 80...200)
            let endX = center.x + cos(angle) * distance
            let endY = center.y + sin(angle) * distance

            var particle = SetLoggedParticle(
                id: UUID(),
                position: center,
                color: colors.randomElement() ?? .green,
                size: CGFloat.random(in: 4...10),
                opacity: 1.0
            )

            particles.append(particle)

            // Animate particle outward
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                withAnimation(.easeOut(duration: Double.random(in: 0.4...0.8))) {
                    particles[index].position = CGPoint(x: endX, y: endY)
                }

                // Fade out
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
                    particles[index].opacity = 0
                }
            }
        }
    }
}

struct SetLoggedParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
}

#Preview {
    SetLoggerSheet()
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
