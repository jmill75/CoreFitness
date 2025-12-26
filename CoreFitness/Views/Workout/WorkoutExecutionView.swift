import SwiftUI
import AudioToolbox

struct WorkoutExecutionView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    // Prevent countdown from showing when dismissing
    @State private var isDismissing = false

    var body: some View {
        ZStack {
            // Black background like Apple Fitness
            Color.black
                .ignoresSafeArea()

            // Main content based on phase
            Group {
                switch workoutManager.currentPhase {
                case .idle:
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                        Text("Starting workout...")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                case .countdown(let remaining):
                    // Don't show countdown when dismissing
                    if !isDismissing {
                        CountdownView(count: remaining)
                            .transition(.scale.combined(with: .opacity))
                    }

                case .exercising, .loggingSet, .betweenExercises:
                    UnifiedWorkoutView()
                        .transition(.opacity)

                case .resting(let remaining):
                    RestingView(remaining: remaining)
                        .transition(.opacity)

                case .paused:
                    FitnessStylePausedView()

                case .completed:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: workoutManager.currentPhase)
        }
        .onAppear {
            // Start workout when view appears
            if !isDismissing && workoutManager.currentPhase == .idle {
                workoutManager.startWorkout(workout)
            }
        }
        .task {
            // Safety timeout - if still idle after 3 seconds, try starting again
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !isDismissing && workoutManager.currentPhase == .idle {
                workoutManager.startWorkout(workout)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $workoutManager.showWorkoutComplete) {
            WorkoutCompleteView()
                .environmentObject(workoutManager)
                .environmentObject(themeManager)
                .interactiveDismissDisabled()
                .onDisappear {
                    isDismissing = true
                    dismiss()
                }
        }
        .overlay {
            if workoutManager.showExitConfirmation {
                ExitConfirmationView(
                    onSaveExit: {
                        isDismissing = true
                        workoutManager.showExitConfirmation = false
                        workoutManager.completeWorkout()
                    },
                    onDiscard: {
                        isDismissing = true
                        workoutManager.showExitConfirmation = false
                        workoutManager.cancelWorkout()
                        dismiss()
                    },
                    onContinue: {
                        workoutManager.showExitConfirmation = false
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: workoutManager.showExitConfirmation)
        .overlay {
            if workoutManager.showPRCelebration {
                PRCelebrationView(
                    exerciseName: workoutManager.prExerciseName,
                    weight: workoutManager.prWeight,
                    onDismiss: {
                        workoutManager.showPRCelebration = false
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: workoutManager.showPRCelebration)
        .overlay {
            if workoutManager.showSetCompleteFeedback {
                SetCompleteFeedbackView(setNumber: workoutManager.completedSetNumber)
                    .transition(.opacity.combined(with: .scale(scale: 1.2)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: workoutManager.showSetCompleteFeedback)
        .overlay {
            if workoutManager.showExerciseCompleteFeedback {
                ExerciseCompleteFeedbackView(exerciseName: workoutManager.completedExerciseName)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: workoutManager.showExerciseCompleteFeedback)
    }
}

// MARK: - Set Complete Feedback View
struct SetCompleteFeedbackView: View {
    let setNumber: Int
    @State private var showCheckmark = false
    @State private var ringScale: CGFloat = 0.5
    @State private var glowPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Extra tint for contrast
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Success ring
            ZStack {
                // Pulsing outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.5), Color.green.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(ringScale * glowPulse)

                // Ring
                Circle()
                    .stroke(Color.green, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .scaleEffect(ringScale)
                    .shadow(color: .green.opacity(0.6), radius: 10)

                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.green)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .shadow(color: .green.opacity(0.5), radius: 8)
            }

            // Set text
            VStack {
                Spacer()

                Text("SET \(setNumber) COMPLETE")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(showCheckmark ? 1 : 0)
                    .offset(y: showCheckmark ? 0 : 20)
                    .shadow(color: .black.opacity(0.3), radius: 4)

                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                ringScale = 1.0
                showCheckmark = true
            }

            // Start pulse animation
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                glowPulse = 1.1
            }
        }
    }
}

// MARK: - Exercise Complete Feedback View
struct ExerciseCompleteFeedbackView: View {
    let exerciseName: String
    @State private var showContent = false
    @State private var particles: [CelebrationParticle] = []
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Celebration particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            // Main content
            VStack(spacing: 20) {
                // Star burst with glow
                ZStack {
                    // Pulsing glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.5), Color.orange.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(pulseScale)

                    // Star icon
                    Image(systemName: "star.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(showContent ? 1 : 0)
                        .rotationEffect(.degrees(showContent ? 0 : -30))
                }

                // Exercise Complete text
                Text("EXERCISE COMPLETE!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)

                // Exercise name
                Text(exerciseName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            // Animate content in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showContent = true
            }

            // Start pulse animation
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }

            // Launch celebration particles
            launchCelebration()
        }
    }

    private func launchCelebration() {
        let colors: [Color] = [.yellow, .orange, .green, .cyan, .pink]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let center = CGPoint(x: screenWidth / 2, y: screenHeight / 2 - 50)

        // Create burst of particles
        for i in 0..<30 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                let angle = Double.random(in: 0...2 * .pi)
                let distance = CGFloat.random(in: 100...250)
                let endX = center.x + cos(angle) * distance
                let endY = center.y + sin(angle) * distance

                var particle = CelebrationParticle(
                    id: UUID(),
                    position: center,
                    color: colors.randomElement() ?? .yellow,
                    size: CGFloat.random(in: 6...14),
                    opacity: 1.0
                )

                particles.append(particle)
                let index = particles.count - 1

                // Animate outward
                withAnimation(.easeOut(duration: 0.6)) {
                    if index < particles.count {
                        particles[index].position = CGPoint(x: endX, y: endY)
                    }
                }

                // Fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        if index < particles.count {
                            particles[index].opacity = 0
                        }
                    }
                }

                // Remove
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    if let idx = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles.remove(at: idx)
                    }
                }
            }
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
}

// MARK: - PR Celebration View with Fireworks
struct PRCelebrationView: View {
    let exerciseName: String
    let weight: Double
    let onDismiss: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @State private var showContent = false
    @State private var particles: [FireworkParticle] = []

    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Extra dark tint for contrast
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Firework particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            // Main content
            VStack(spacing: 24) {
                // Trophy icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(showContent ? 1.2 : 0.8)
                        .opacity(showContent ? 1 : 0)

                    Text("🏆")
                        .font(.system(size: 80))
                        .scaleEffect(showContent ? 1 : 0)
                }

                // NEW PR text
                Text("NEW PR!")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)

                // Exercise and weight
                VStack(spacing: 8) {
                    Text(exerciseName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Text(themeManager.formatWeightValue(weight))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text(themeManager.weightUnitLabel)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green.opacity(0.8))
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("KEEP CRUSHING IT")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.5), radius: 10, y: 5)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .padding(.top, 16)
            }
        }
        .onAppear {
            // Play celebration sound
            playCelebrationSound()

            // Animate content in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }

            // Launch fireworks
            launchFireworks()

            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                onDismiss()
            }
        }
    }

    private func playCelebrationSound() {
        // Sound disabled - keeping haptics only
    }

    private func launchFireworks() {
        let colors: [Color] = [.yellow, .orange, .red, .green, .cyan, .pink, .purple]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Create multiple bursts
        for burst in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(burst) * 0.3) {
                let centerX = CGFloat.random(in: screenWidth * 0.2...screenWidth * 0.8)
                let centerY = CGFloat.random(in: screenHeight * 0.2...screenHeight * 0.5)

                // Create particles for this burst
                for _ in 0..<20 {
                    let angle = Double.random(in: 0...2 * .pi)
                    let distance = CGFloat.random(in: 50...150)
                    let endX = centerX + cos(angle) * distance
                    let endY = centerY + sin(angle) * distance

                    let particle = FireworkParticle(
                        id: UUID(),
                        position: CGPoint(x: centerX, y: centerY),
                        color: colors.randomElement() ?? .yellow,
                        size: CGFloat.random(in: 4...12),
                        opacity: 1.0
                    )

                    particles.append(particle)
                    let index = particles.count - 1

                    // Animate particle outward
                    withAnimation(.easeOut(duration: 0.8)) {
                        if index < particles.count {
                            particles[index].position = CGPoint(x: endX, y: endY)
                        }
                    }

                    // Fade out and fall
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            if index < particles.count {
                                particles[index].opacity = 0
                                particles[index].position.y += 50
                            }
                        }
                    }

                    // Remove particle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if let idx = particles.firstIndex(where: { $0.id == particle.id }) {
                            particles.remove(at: idx)
                        }
                    }
                }
            }
        }
    }
}

struct FireworkParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
}

// MARK: - Exit Confirmation View
struct ExitConfirmationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onSaveExit: () -> Void
    let onDiscard: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Blurred background overlay
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()

            // Dark tint for better contrast
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onContinue()
                }

            // Dialog content
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                }

                // Title
                Text("End Workout?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Buttons
                VStack(spacing: 16) {
                    // Save & Exit
                    Button {
                        themeManager.mediumImpact()
                        onSaveExit()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Save & Exit")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Discard
                    Button {
                        themeManager.mediumImpact()
                        onDiscard()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                            Text("Discard Workout")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Continue
                    Button {
                        themeManager.lightImpact()
                        onContinue()
                    } label: {
                        Text("Continue Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.systemGray6).opacity(0.95))
            )
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Unified Workout View (Glove-Friendly)
struct UnifiedWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager

    // Local state for editing
    @State private var reps: Int = 10
    @State private var weight: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer(minLength: 0)

            // Main content - large touch targets
            VStack(spacing: 20) {
                // Set indicator
                setIndicator

                // Large input controls
                inputControls
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 20)

            // Large save button
            saveButton
                .padding(.horizontal, 16)

            Spacer(minLength: 16)

            // Skip exercise at very bottom
            skipExerciseButton
                .padding(.bottom, 16)
        }
        .onAppear {
            loadCurrentValues()
        }
        .onChange(of: workoutManager.currentSetNumber) { _, _ in
            loadCurrentValues()
        }
        .onChange(of: workoutManager.currentExerciseIndex) { _, _ in
            loadCurrentValues()
        }
    }

    private func loadCurrentValues() {
        reps = workoutManager.currentExercise?.targetReps ?? 10
        weight = workoutManager.currentExercise?.targetWeight ?? 0
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            // Timer
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text(workoutManager.formattedElapsedTime)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Spacer()

            // Exercise name
            Text(workoutManager.currentExercise?.exercise?.name ?? "Exercise")
                .font(.headline)
                .foregroundStyle(.gray)
                .lineLimit(1)

            Spacer()

            // Control buttons
            HStack(spacing: 8) {
                Button {
                    workoutManager.pauseWorkout()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }

                Button {
                    workoutManager.showExitConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Set Indicator
    private var setIndicator: some View {
        VStack(spacing: 8) {
            // Large set number
            Text("SET \(workoutManager.currentSetNumber)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Progress dots
            HStack(spacing: 10) {
                ForEach(1...(workoutManager.currentExercise?.targetSets ?? 3), id: \.self) { setNum in
                    Circle()
                        .fill(setNum < workoutManager.currentSetNumber ? Color.green :
                              setNum == workoutManager.currentSetNumber ? Color.yellow :
                              Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .overlay {
                            if setNum < workoutManager.currentSetNumber {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Input Controls (Large for gloves)
    private var inputControls: some View {
        VStack(spacing: 16) {
            // Reps row
            HStack(spacing: 0) {
                // Minus button
                Button {
                    if reps > 1 { reps -= 1 }
                    themeManager.mediumImpact()
                } label: {
                    Image(systemName: "minus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()

                // Reps display
                VStack(spacing: 4) {
                    Text("\(reps)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("REPS")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Plus button
                Button {
                    reps += 1
                    themeManager.mediumImpact()
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)
                        .frame(width: 80, height: 80)
                        .background(Color.cyan.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            // Weight row
            HStack(spacing: 0) {
                // Minus button
                Button {
                    if weight >= 5 { weight -= 5 }
                    themeManager.mediumImpact()
                } label: {
                    Text("-5")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()

                // Weight display
                VStack(spacing: 4) {
                    Text(themeManager.formatWeightValue(weight))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text(themeManager.weightUnitLabel)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Plus button
                Button {
                    weight += 5
                    themeManager.mediumImpact()
                } label: {
                    Text("+5")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .frame(width: 80, height: 80)
                        .background(Color.green.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Save Button (Extra large)
    private var saveButton: some View {
        Button {
            workoutManager.logSet(reps: reps, weight: weight, rpe: nil)
            themeManager.heavyImpact()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                Text("SAVE SET")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
        }
    }

    // MARK: - Skip Exercise Button
    private var skipExerciseButton: some View {
        Group {
            if !workoutManager.isLastExercise {
                Button {
                    workoutManager.nextExercise()
                } label: {
                    Text("Skip Exercise →")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            } else {
                // Empty space to maintain layout
                Text("")
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Resting View
struct RestingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    let remaining: Int

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Rest icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "clock.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                }

                Text("REST")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .tracking(2)

                Text(formatTime(remaining))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // Next up info
                VStack(spacing: 8) {
                    Text("NEXT SET")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                        .tracking(1)

                    Text("Set \(workoutManager.currentSetNumber) of \(workoutManager.currentExercise?.targetSets ?? 0)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(workoutManager.currentExercise?.exercise?.name ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.top, 16)
            }

            Spacer()

            // Rest controls
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button {
                        workoutManager.skipRest()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.fill")
                            Text("Skip Rest")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        workoutManager.extendRest(by: 30)
                    } label: {
                        Text("+30s")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 56)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                // End workout
                Button {
                    workoutManager.showExitConfirmation = true
                } label: {
                    Text("End Workout")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Completed Set Card
struct CompletedSetCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let set: CompletedSet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Set \(set.setNumber)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                HStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("×")
                        .foregroundStyle(.gray)
                    Text(themeManager.formatWeight(set.weight))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .padding(12)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Fitness Style Paused View
struct FitnessStylePausedView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Paused icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "pause.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)
            }

            Text("Workout Paused")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text(workoutManager.formattedElapsedTime)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundStyle(.yellow)
                .monospacedDigit()

            Spacer()

            // Resume button
            Button {
                workoutManager.resumeWorkout()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Resume Workout")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            // End workout button
            Button {
                workoutManager.showExitConfirmation = true
            } label: {
                Text("End Workout")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    let workout = Workout(name: "Upper Body Strength", estimatedDuration: 45)
    return WorkoutExecutionView(workout: workout)
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
