import SwiftUI
import AudioToolbox

struct WorkoutExecutionView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    // Prevent countdown from showing when dismissing
    @State private var isDismissing = false

    // Check if any popup is active
    private var isAnyPopupActive: Bool {
        workoutManager.showExitConfirmation ||
        workoutManager.showPRCelebration ||
        workoutManager.showSetCompleteFeedback ||
        workoutManager.showExerciseCompleteFeedback ||
        workoutManager.showNextExerciseTransition
    }

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
            .blur(radius: isAnyPopupActive ? 10 : 0)
            .animation(.easeInOut(duration: 0.2), value: isAnyPopupActive)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: workoutManager.currentPhase)

            // All popups in a single overlay group
            if isAnyPopupActive {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Exit Confirmation
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
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // PR Celebration
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

            // Set Complete Feedback
            if workoutManager.showSetCompleteFeedback {
                SetCompleteFeedbackView(setNumber: workoutManager.completedSetNumber)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            // Exercise Complete Feedback
            if workoutManager.showExerciseCompleteFeedback {
                ExerciseCompleteFeedbackView(exerciseName: workoutManager.completedExerciseName)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            // Next Exercise Transition
            if workoutManager.showNextExerciseTransition {
                NextExerciseTransitionView(
                    exerciseName: workoutManager.nextExerciseName,
                    exerciseNumber: workoutManager.nextExerciseNumber,
                    totalExercises: workoutManager.totalExerciseCount
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAnyPopupActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: workoutManager.showExitConfirmation)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: workoutManager.showPRCelebration)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: workoutManager.showSetCompleteFeedback)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: workoutManager.showExerciseCompleteFeedback)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: workoutManager.showNextExerciseTransition)
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
    }
}

// MARK: - Set Complete Feedback View
struct SetCompleteFeedbackView: View {
    let setNumber: Int
    @State private var showCheckmark = false
    @State private var ringScale: CGFloat = 0.5
    @State private var glowPulse: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

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
            Text("SET \(setNumber) COMPLETE")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .opacity(showCheckmark ? 1 : 0)
                .offset(y: showCheckmark ? 0 : 20)
                .shadow(color: .black.opacity(0.3), radius: 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Next Exercise Transition View
struct NextExerciseTransitionView: View {
    let exerciseName: String
    let exerciseNumber: Int
    let totalExercises: Int

    @State private var showContent = false
    @State private var arrowOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // "Up Next" label
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .offset(x: arrowOffset)
                Text("UP NEXT")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .tracking(2)
            }
            .foregroundStyle(.cyan)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : -20)

            // Exercise name
            Text(exerciseName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)

            // Progress indicator
            HStack(spacing: 6) {
                    Text("Exercise")
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(exerciseNumber)")
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)
                    Text("of")
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(totalExercises)")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .font(.subheadline)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalExercises, id: \.self) { index in
                    Circle()
                        .fill(index < exerciseNumber ? Color.cyan : Color.white.opacity(0.3))
                        .frame(width: index == exerciseNumber - 1 ? 10 : 6,
                               height: index == exerciseNumber - 1 ? 10 : 6)
                        .scaleEffect(showContent ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.05), value: showContent)
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Animate content in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }

            // Arrow bounce animation
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                arrowOffset = 5
            }
        }
    }
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
            // Tap to dismiss area
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    @ObservedObject private var musicService = MusicService.shared

    // Local state for editing
    @State private var reps: Int = 10
    @State private var weight: Double = 0
    @State private var showMusicSheet = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Compact header
                headerBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Exercise name - prominent display
                exerciseNameDisplay
                    .padding(.top, 24)
                    .padding(.horizontal, 16)

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

                Spacer(minLength: 12)

                // Music control bar at bottom
                WorkoutMusicBar(showMusicSheet: $showMusicSheet)
                    .padding(.horizontal, 16)

                // Skip exercise button - under music widget
                skipExerciseButton
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
            .blur(radius: showMusicSheet ? 10 : 0)
            .animation(.easeInOut(duration: 0.2), value: showMusicSheet)
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
        .sheet(isPresented: $showMusicSheet) {
            MusicControlSheet()
                .presentationDetents([.height(580)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
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
                    .frame(width: 8, height: 8)
                Text(workoutManager.formattedElapsedTime)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Spacer()

            // Compact health metrics - centered (only show when there's data)
            if workoutManager.currentHeartRate > 0 || workoutManager.workoutCalories > 0 {
                HStack(spacing: 12) {
                    // Heart Rate - compact
                    if workoutManager.currentHeartRate > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.red)
                            Text("\(workoutManager.currentHeartRate)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                    // Calories - compact
                    if workoutManager.workoutCalories > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                            Text("\(workoutManager.workoutCalories)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }

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

    // MARK: - Exercise Name Display
    private var exerciseNameDisplay: some View {
        VStack(spacing: 4) {
            Text(workoutManager.currentExercise?.exercise?.name ?? "Exercise")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .id("exercise-name-\(workoutManager.currentExerciseIndex)")

            // Exercise progress indicator
            if workoutManager.totalExercises > 0 {
                Text("Exercise \(workoutManager.currentExerciseIndex + 1) of \(workoutManager.totalExercises)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .id("exercise-progress-\(workoutManager.currentExerciseIndex)")
            }
        }
        .frame(maxWidth: .infinity)
        .id("exercise-display-\(workoutManager.currentExerciseIndex)")
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
                RepeatableButton(
                    action: {
                        if reps > 1 { reps -= 1 }
                    },
                    label: {
                        Image(systemName: "minus")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    },
                    backgroundColor: Color.gray.opacity(0.3),
                    accentColor: .white
                )

                Spacer()

                // Reps display
                VStack(spacing: 4) {
                    Text("\(reps)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: reps)
                    Text("REPS")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Plus button
                RepeatableButton(
                    action: {
                        reps += 1
                    },
                    label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.cyan)
                    },
                    backgroundColor: Color.cyan.opacity(0.2),
                    accentColor: .cyan
                )
            }

            // Weight row
            HStack(spacing: 0) {
                // Minus button
                RepeatableButton(
                    action: {
                        if weight >= 5 { weight -= 5 }
                    },
                    label: {
                        Text("-5")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    },
                    backgroundColor: Color.gray.opacity(0.3),
                    accentColor: .white
                )

                Spacer()

                // Weight display
                VStack(spacing: 4) {
                    Text(themeManager.formatWeightValue(weight))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: weight)
                    Text(themeManager.weightUnitLabel)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Plus button
                RepeatableButton(
                    action: {
                        weight += 5
                    },
                    label: {
                        Text("+5")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    },
                    backgroundColor: Color.green.opacity(0.2),
                    accentColor: .green
                )
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

    @State private var showMusicSheet = false

    var body: some View {
        ZStack {
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
                .padding(.bottom, 16)

                // Music bar at bottom
                WorkoutMusicBar(showMusicSheet: $showMusicSheet)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
            .blur(radius: showMusicSheet ? 10 : 0)
            .animation(.easeInOut(duration: 0.2), value: showMusicSheet)
        }
        .sheet(isPresented: $showMusicSheet) {
            MusicControlSheet()
                .presentationDetents([.height(580)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
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
    @State private var showMusicSheet = false

    var body: some View {
        ZStack {
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
                .padding(.bottom, 16)

                // Music bar at bottom
                WorkoutMusicBar(showMusicSheet: $showMusicSheet)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .blur(radius: showMusicSheet ? 10 : 0)
            .animation(.easeInOut(duration: 0.2), value: showMusicSheet)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .sheet(isPresented: $showMusicSheet) {
            MusicControlSheet()
                .presentationDetents([.height(580)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
    }
}

// MARK: - Workout Music Bar
struct WorkoutMusicBar: View {
    @ObservedObject private var musicService = MusicService.shared
    @Binding var showMusicSheet: Bool

    // Animation state for play button
    @State private var playButtonScale: CGFloat = 1.0

    var body: some View {
        Button {
            showMusicSheet = true
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 14) {
                    // Artwork or icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(musicService.selectedProvider.color.opacity(0.3))
                            .frame(width: 56, height: 56)

                        if let track = musicService.currentTrack, let artwork = track.artwork {
                            artwork
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 22))
                                .foregroundStyle(musicService.selectedProvider.color)
                        }
                    }

                // Track info
                VStack(alignment: .leading, spacing: 3) {
                    Text(musicService.currentTrack?.title ?? "Not Playing")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Small equalizer next to artist when playing
                        if musicService.isPlaying {
                            HStack(spacing: 2) {
                                MiniEqualizerBar(delay: 0)
                                MiniEqualizerBar(delay: 0.15)
                                MiniEqualizerBar(delay: 0.3)
                            }
                        }

                        Text(musicService.currentTrack?.artist ?? "Tap to open music")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Playback controls
                HStack(spacing: 8) {
                    Button {
                        musicService.skipToPrevious()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if musicService.currentTrack != nil {
                            musicService.togglePlayPause()
                        } else {
                            musicService.openMusicApp()
                        }
                    } label: {
                        ZStack {
                            // Pulsing ring when playing
                            if musicService.isPlaying {
                                Circle()
                                    .stroke(musicService.selectedProvider.color.opacity(0.5), lineWidth: 2)
                                    .frame(width: 52, height: 52)
                                    .scaleEffect(playButtonScale)
                            }

                            Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(musicService.selectedProvider.color.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        musicService.skipToNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }

                // Open app button (smaller)
                Button {
                    musicService.openMusicApp()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(musicService.selectedProvider.color.opacity(0.7))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }

            // Progress/scrub bar
            if let track = musicService.currentTrack, track.duration > 0 {
                HStack(spacing: 8) {
                    Text(formatTime(musicService.currentPlaybackTime))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                        .frame(width: 36, alignment: .trailing)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)

                            // Progress fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [musicService.selectedProvider.color.opacity(0.8), musicService.selectedProvider.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(musicService.currentPlaybackTime / track.duration)), height: 4)

                            // Scrub handle (only show when playing)
                            if musicService.isPlaying {
                                Circle()
                                    .fill(musicService.selectedProvider.color)
                                    .frame(width: 8, height: 8)
                                    .offset(x: max(0, geo.size.width * CGFloat(musicService.currentPlaybackTime / track.duration) - 4))
                            }
                        }
                    }
                    .frame(height: 8)

                    Text(formatTime(track.duration))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                        .frame(width: 36, alignment: .leading)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .onAppear {
            startAnimations()
        }
        .onChange(of: musicService.isPlaying) { _, isPlaying in
            if isPlaying {
                startAnimations()
            }
        }
    }

    private func startAnimations() {
        guard musicService.isPlaying else { return }

        // Pulsing play button
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            playButtonScale = 1.3
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Mini Equalizer Bar (for artist text)
struct MiniEqualizerBar: View {
    let delay: Double
    @State private var height: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.green)
            .frame(width: 2, height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(delay)) {
                    height = CGFloat.random(in: 4...12)
                }
            }
    }
}

// MARK: - Repeatable Button (Hold to increment faster)
struct RepeatableButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    let backgroundColor: Color
    let accentColor: Color

    @State private var isPressed = false
    @State private var repeatTimer: Timer?
    @State private var repeatCount = 0

    // Start slow, get faster
    private var repeatInterval: TimeInterval {
        if repeatCount < 5 {
            return 0.3 // First 5: slow
        } else if repeatCount < 15 {
            return 0.15 // Next 10: medium
        } else {
            return 0.08 // After 15: fast
        }
    }

    var body: some View {
        label()
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(accentColor.opacity(isPressed ? 0.3 : 0))
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                if pressing {
                    // Start pressing
                    isPressed = true
                    repeatCount = 0
                    action()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    startRepeating()
                } else {
                    // Stop pressing
                    isPressed = false
                    stopRepeating()
                }
            }, perform: {})
    }

    private func startRepeating() {
        stopRepeating()
        scheduleNextRepeat()
    }

    private func scheduleNextRepeat() {
        repeatTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: false) { _ in
            guard isPressed else { return }
            repeatCount += 1
            action()

            // Haptic feedback - lighter for rapid repeats
            if repeatCount < 15 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if repeatCount % 3 == 0 {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }

            scheduleNextRepeat()
        }
    }

    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        repeatCount = 0
    }
}

#Preview {
    let workout = Workout(name: "Upper Body Strength", estimatedDuration: 45)
    return WorkoutExecutionView(workout: workout)
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
