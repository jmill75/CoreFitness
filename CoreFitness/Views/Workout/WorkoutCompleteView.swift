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
        themeManager.notifySuccess()

        // Create a celebration pattern
        for i in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) { [themeManager] in
                if i % 2 == 0 {
                    themeManager.heavyImpact()
                } else {
                    themeManager.mediumImpact()
                }
            }
        }
    }

    private func launchFireworksShow() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Simplified firework approach - create all particles upfront with animation states
        Task { @MainActor in
            for wave in 0..<6 {
                try? await Task.sleep(nanoseconds: UInt64(wave) * 400_000_000)

                let fireworkCount = Int.random(in: 2...3)
                for _ in 0..<fireworkCount {
                    let peakX = CGFloat.random(in: screenWidth * 0.15...screenWidth * 0.85)
                    let peakY = CGFloat.random(in: screenHeight * 0.15...screenHeight * 0.4)
                    createExplosion(at: CGPoint(x: peakX, y: peakY))
                }

                themeManager.heavyImpact()
            }
        }
    }

    private func createExplosion(at center: CGPoint) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .white]
        let fireworkColor = colors.randomElement() ?? .yellow
        let secondaryColor = colors.randomElement() ?? .orange

        let fireworkId = UUID()
        var particles: [WorkoutFireworkParticle] = []

        // Create all explosion particles at center
        let particleCount = Int.random(in: 30...45)
        for _ in 0..<particleCount {
            let particle = WorkoutFireworkParticle(
                id: UUID(),
                position: center,
                color: Bool.random() ? fireworkColor : secondaryColor,
                size: CGFloat.random(in: 3...8),
                opacity: 1.0
            )
            particles.append(particle)
        }

        let newFirework = WorkoutFirework(id: fireworkId, particles: particles)
        fireworks.append(newFirework)

        // Find firework and animate particles outward
        guard let fireworkIndex = fireworks.firstIndex(where: { $0.id == fireworkId }) else { return }

        // Animate each particle to its final position
        for i in 0..<particles.count {
            let angle = Double.random(in: 0...2 * .pi)
            let distance = CGFloat.random(in: 40...100)
            let endX = center.x + cos(angle) * distance
            let endY = center.y + sin(angle) * distance + 30

            withAnimation(.easeOut(duration: 0.6)) {
                if fireworkIndex < fireworks.count && i < fireworks[fireworkIndex].particles.count {
                    fireworks[fireworkIndex].particles[i].position = CGPoint(x: endX, y: endY)
                }
            }
        }

        // Fade out all particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard let idx = fireworks.firstIndex(where: { $0.id == fireworkId }) else { return }

            withAnimation(.easeIn(duration: 0.4)) {
                for i in 0..<fireworks[idx].particles.count {
                    fireworks[idx].particles[i].opacity = 0
                }
            }
        }

        // Remove firework
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            fireworks.removeAll { $0.id == fireworkId }
        }
    }

    private func launchConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]

        // Create confetti in batches with stable IDs
        Task { @MainActor in
            // First wave
            for batch in 0..<5 {
                try? await Task.sleep(nanoseconds: UInt64(batch) * 100_000_000)
                await createConfettiBatch(count: 20, screenWidth: screenWidth, screenHeight: screenHeight, colors: colors)
            }

            // Second wave after delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            for batch in 0..<3 {
                try? await Task.sleep(nanoseconds: UInt64(batch) * 150_000_000)
                await createConfettiBatch(count: 15, screenWidth: screenWidth, screenHeight: screenHeight, colors: colors)
            }
        }
    }

    @MainActor
    private func createConfettiBatch(count: Int, screenWidth: CGFloat, screenHeight: CGFloat, colors: [Color]) async {
        var newPieces: [WorkoutConfetti] = []

        for _ in 0..<count {
            let piece = WorkoutConfetti(
                id: UUID(),
                position: CGPoint(x: CGFloat.random(in: 0...screenWidth), y: -20),
                color: colors.randomElement() ?? .yellow,
                width: CGFloat.random(in: 6...12),
                height: CGFloat.random(in: 12...20),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            newPieces.append(piece)
        }

        confetti.append(contentsOf: newPieces)

        // Animate all pieces in this batch
        for piece in newPieces {
            guard let index = confetti.firstIndex(where: { $0.id == piece.id }) else { continue }

            let fallDuration = Double.random(in: 2.0...3.5)
            let endY = screenHeight + 50
            let drift = CGFloat.random(in: -80...80)
            let rotationAdd = Double.random(in: 360...720)

            withAnimation(.easeIn(duration: fallDuration)) {
                if index < confetti.count {
                    confetti[index].position = CGPoint(x: piece.position.x + drift, y: endY)
                    confetti[index].rotation += rotationAdd
                    confetti[index].opacity = 0
                }
            }
        }

        // Cleanup after animation completes
        let pieceIds = Set(newPieces.map { $0.id })
        try? await Task.sleep(nanoseconds: 4_000_000_000)
        confetti.removeAll { pieceIds.contains($0.id) }
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
