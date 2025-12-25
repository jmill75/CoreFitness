import SwiftUI
import AudioToolbox

struct WorkoutCompleteView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showContent = false
    @State private var fireworks: [WorkoutFirework] = []
    @State private var confetti: [WorkoutConfetti] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // Fireworks layer
                ForEach(fireworks) { firework in
                    ForEach(firework.particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                            .opacity(particle.opacity)
                            .blur(radius: particle.size > 8 ? 1 : 0)
                    }
                }

                // Confetti layer
                ForEach(confetti) { confettiPiece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(confettiPiece.color)
                        .frame(width: confettiPiece.width, height: confettiPiece.height)
                        .rotationEffect(.degrees(confettiPiece.rotation))
                        .position(confettiPiece.position)
                        .opacity(confettiPiece.opacity)
                }

                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        // Celebration header
                        VStack(spacing: 16) {
                            ZStack {
                                // Animated glow rings
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                                        .scaleEffect(showContent ? 1 : 0.5)
                                        .opacity(showContent ? Double(3 - i) * 0.25 : 0)
                                        .animation(
                                            .spring(response: 0.6, dampingFraction: 0.6)
                                            .delay(Double(i) * 0.1),
                                            value: showContent
                                        )
                                }

                                // Glow effect
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.yellow.opacity(0.4), Color.clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .scaleEffect(showContent ? 1.2 : 0.8)

                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 72))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .scaleEffect(showContent ? 1 : 0)
                                    .rotationEffect(.degrees(showContent ? 0 : -20))
                            }
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

                            Text("WORKOUT COMPLETE!")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .scaleEffect(showContent ? 1 : 0.5)
                                .opacity(showContent ? 1 : 0)

                            Text(workoutManager.currentWorkout?.name ?? "Great work!")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                        }
                        .padding(.top, 32)

                        // Stats summary
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            SummaryStatCard(
                                icon: "clock.fill",
                                value: workoutManager.formattedElapsedTime,
                                label: "Duration",
                                color: .accentBlue
                            )
                            .scaleEffect(showContent ? 1 : 0.8)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: showContent)

                            SummaryStatCard(
                                icon: "dumbbell.fill",
                                value: "\(workoutManager.totalExercises)",
                                label: "Exercises",
                                color: .accentOrange
                            )
                            .scaleEffect(showContent ? 1 : 0.8)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: showContent)

                            SummaryStatCard(
                                icon: "checkmark.circle.fill",
                                value: "\(totalSetsCompleted)",
                                label: "Sets",
                                color: .accentGreen
                            )
                            .scaleEffect(showContent ? 1 : 0.8)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: showContent)

                            SummaryStatCard(
                                icon: "scalemass.fill",
                                value: formattedVolume,
                                label: "Volume",
                                color: .accentTeal
                            )
                            .scaleEffect(showContent ? 1 : 0.8)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: showContent)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 40)

                        // Done button
                        GradientButton(
                            "Done",
                            icon: "checkmark",
                            gradient: AppGradients.success
                        ) {
                            workoutManager.resetState()
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                        .scaleEffect(showContent ? 1 : 0.8)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: showContent)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            startCelebration()
        }
    }

    private func startCelebration() {
        // Haptic celebration pattern
        celebrationHaptics()

        // Animate content in
        withAnimation {
            showContent = true
        }

        // Launch fireworks continuously
        launchFireworksShow()

        // Launch confetti
        launchConfetti()
    }

    private func celebrationHaptics() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Create a celebration pattern
        for i in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                UIImpactFeedbackGenerator(style: i % 2 == 0 ? .heavy : .medium).impactOccurred()
            }
        }
    }

    private func launchFireworksShow() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Launch multiple waves of fireworks
        for wave in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(wave) * 0.4) {
                // Launch 2-3 fireworks per wave from different positions
                let fireworkCount = Int.random(in: 2...3)
                for _ in 0..<fireworkCount {
                    let startX = CGFloat.random(in: screenWidth * 0.15...screenWidth * 0.85)
                    let startY = screenHeight
                    let peakY = CGFloat.random(in: screenHeight * 0.15...screenHeight * 0.4)

                    launchSingleFirework(from: CGPoint(x: startX, y: startY), to: CGPoint(x: startX, y: peakY))
                }
            }
        }

        // Continue with more waves
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            for wave in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(wave) * 0.5) {
                    let startX = CGFloat.random(in: screenWidth * 0.1...screenWidth * 0.9)
                    let startY = screenHeight
                    let peakY = CGFloat.random(in: screenHeight * 0.1...screenHeight * 0.35)

                    launchSingleFirework(from: CGPoint(x: startX, y: startY), to: CGPoint(x: startX, y: peakY))
                }
            }
        }
    }

    private func launchSingleFirework(from start: CGPoint, to peak: CGPoint) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .white]
        let fireworkColor = colors.randomElement() ?? .yellow
        let secondaryColor = colors.randomElement() ?? .orange

        var firework = WorkoutFirework(id: UUID(), particles: [])

        // Create trail particles during ascent
        let trailCount = 8
        for i in 0..<trailCount {
            let progress = Double(i) / Double(trailCount)
            let x = start.x
            let y = start.y - (start.y - peak.y) * progress

            let trailParticle = WorkoutFireworkParticle(
                id: UUID(),
                position: CGPoint(x: x, y: y),
                color: .white.opacity(0.6),
                size: CGFloat.random(in: 2...4),
                opacity: 1.0 - progress * 0.5
            )
            firework.particles.append(trailParticle)
        }

        fireworks.append(firework)
        let fireworkIndex = fireworks.count - 1

        // Ascent animation
        let ascentDuration = 0.5

        // Explosion at peak
        DispatchQueue.main.asyncAfter(deadline: .now() + ascentDuration) {
            guard fireworkIndex < fireworks.count else { return }

            // Clear trail particles
            fireworks[fireworkIndex].particles.removeAll()

            // Play haptic for explosion
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            // Create explosion particles
            let particleCount = Int.random(in: 40...60)
            for _ in 0..<particleCount {
                let angle = Double.random(in: 0...2 * .pi)
                let distance = CGFloat.random(in: 30...120)
                let endX = peak.x + cos(angle) * distance
                let endY = peak.y + sin(angle) * distance

                let particle = WorkoutFireworkParticle(
                    id: UUID(),
                    position: peak,
                    color: Bool.random() ? fireworkColor : secondaryColor,
                    size: CGFloat.random(in: 3...10),
                    opacity: 1.0
                )

                fireworks[fireworkIndex].particles.append(particle)
                let particleIndex = fireworks[fireworkIndex].particles.count - 1

                // Animate particle outward
                withAnimation(.easeOut(duration: 0.8)) {
                    if fireworkIndex < fireworks.count && particleIndex < fireworks[fireworkIndex].particles.count {
                        fireworks[fireworkIndex].particles[particleIndex].position = CGPoint(x: endX, y: endY + 30)
                    }
                }

                // Fade out with gravity
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        if fireworkIndex < fireworks.count && particleIndex < fireworks[fireworkIndex].particles.count {
                            fireworks[fireworkIndex].particles[particleIndex].opacity = 0
                            fireworks[fireworkIndex].particles[particleIndex].position.y += 40
                        }
                    }
                }
            }

            // Cleanup firework
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if let idx = fireworks.firstIndex(where: { $0.id == firework.id }) {
                    fireworks.remove(at: idx)
                }
            }
        }
    }

    private func launchConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]

        // Create lots of confetti
        for i in 0..<100 {
            let delay = Double(i) * 0.03
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                let newPiece = WorkoutConfetti(
                    id: UUID(),
                    position: CGPoint(x: CGFloat.random(in: 0...screenWidth), y: -20),
                    color: colors.randomElement() ?? .yellow,
                    width: CGFloat.random(in: 6...12),
                    height: CGFloat.random(in: 12...20),
                    rotation: Double.random(in: 0...360),
                    opacity: 1.0
                )

                confetti.append(newPiece)
                let index = confetti.count - 1
                let pieceId = newPiece.id
                let startX = newPiece.position.x

                // Animate falling with rotation
                let fallDuration = Double.random(in: 2.5...4.0)
                let endY = screenHeight + 50
                let drift = CGFloat.random(in: -100...100)
                let rotationAdd = Double.random(in: 360...720)

                withAnimation(.easeIn(duration: fallDuration)) {
                    if index < confetti.count {
                        confetti[index].position = CGPoint(x: startX + drift, y: endY)
                        confetti[index].rotation += rotationAdd
                    }
                }

                // Fade out near bottom
                try? await Task.sleep(nanoseconds: UInt64(fallDuration * 0.7 * 1_000_000_000))
                withAnimation(.easeIn(duration: fallDuration * 0.3)) {
                    if index < confetti.count {
                        confetti[index].opacity = 0
                    }
                }

                // Remove
                try? await Task.sleep(nanoseconds: UInt64((fallDuration * 0.3 + 0.5) * 1_000_000_000))
                if let idx = confetti.firstIndex(where: { $0.id == pieceId }) {
                    confetti.remove(at: idx)
                }
            }
        }

        // Second wave of confetti
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            for i in 0..<60 {
                let delay = Double(i) * 0.04
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    let newPiece = WorkoutConfetti(
                        id: UUID(),
                        position: CGPoint(x: CGFloat.random(in: 0...screenWidth), y: -20),
                        color: colors.randomElement() ?? .yellow,
                        width: CGFloat.random(in: 6...12),
                        height: CGFloat.random(in: 12...20),
                        rotation: Double.random(in: 0...360),
                        opacity: 1.0
                    )

                    confetti.append(newPiece)
                    let index = confetti.count - 1
                    let pieceId = newPiece.id
                    let startX = newPiece.position.x

                    let fallDuration = Double.random(in: 2.5...4.0)
                    let endY = screenHeight + 50
                    let drift = CGFloat.random(in: -100...100)
                    let rotationAdd = Double.random(in: 360...720)

                    withAnimation(.easeIn(duration: fallDuration)) {
                        if index < confetti.count {
                            confetti[index].position = CGPoint(x: startX + drift, y: endY)
                            confetti[index].rotation += rotationAdd
                        }
                    }

                    try? await Task.sleep(nanoseconds: UInt64((fallDuration + 0.5) * 1_000_000_000))
                    if let idx = confetti.firstIndex(where: { $0.id == pieceId }) {
                        confetti.remove(at: idx)
                    }
                }
            }
        }
    }

    private var totalSetsCompleted: Int {
        workoutManager.currentSession?.completedSets?.count ?? 0
    }

    private var totalVolume: Double {
        workoutManager.currentSession?.completedSets?.reduce(0.0) { sum, set in
            sum + (set.weight * Double(set.reps))
        } ?? 0
    }

    private var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk", totalVolume / 1000)
        } else {
            return themeManager.formatWeight(totalVolume)
        }
    }
}

struct SummaryStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Firework Models

struct WorkoutFirework: Identifiable {
    let id: UUID
    var particles: [WorkoutFireworkParticle]
}

struct WorkoutFireworkParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
}

struct WorkoutConfetti: Identifiable {
    let id: UUID
    var position: CGPoint
    var color: Color
    var width: CGFloat
    var height: CGFloat
    var rotation: Double
    var opacity: Double
}

#Preview {
    WorkoutCompleteView()
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
