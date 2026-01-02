import SwiftUI

// MARK: - Water Tracker View (Animated Glass Design)
struct WaterTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var waterManager: WaterIntakeManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedAmount: Int = 8 // Default 8oz
    @State private var showAddAnimation = false
    @State private var addedAmount: Int = 0
    @State private var waveOffset: CGFloat = 0
    @State private var showCelebration = false
    @State private var celebrationDroplets: [CelebrationDroplet] = []
    @State private var celebrationSparkles: [CelebrationSparkle] = []
    @State private var glowPulse = false
    @State private var glassBounce = false

    private let amounts = [4, 8, 12, 16, 24, 32]

    private var fillPercentage: CGFloat {
        min(waterManager.totalOunces / waterManager.goalOunces, 1.0)
    }

    private var waterColor: Color {
        if fillPercentage >= 1.0 {
            return Color(hex: "00d2d3") // Teal when complete
        } else if fillPercentage >= 0.5 {
            return Color(hex: "54a0ff") // Blue
        } else {
            return Color(hex: "74b9ff") // Light blue
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0a0a0a")
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Button("Skip") {
                        dismiss()
                    }
                    .font(.custom("Helvetica Neue", size: 14).weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("Stay Hydrated")
                        .font(.custom("Helvetica Neue", size: 32).weight(.bold))
                        .foregroundStyle(.white)

                    Text("\(Int(waterManager.totalOunces)) of \(Int(waterManager.goalOunces)) oz today")
                        .font(.custom("Helvetica Neue", size: 16).weight(.light))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Water Glass with Celebration
                ZStack {
                    // Pulsing glow when goal reached
                    if showCelebration {
                        Circle()
                            .fill(waterColor.opacity(0.3))
                            .frame(width: glowPulse ? 320 : 240, height: glowPulse ? 320 : 240)
                            .blur(radius: 40)

                        Circle()
                            .fill(waterColor.opacity(0.2))
                            .frame(width: glowPulse ? 280 : 220, height: glowPulse ? 280 : 220)
                            .blur(radius: 30)
                    }

                    // Water droplets splashing out
                    ForEach(celebrationDroplets) { droplet in
                        CelebrationDropletView(droplet: droplet, waterColor: waterColor)
                    }

                    // Sparkles
                    ForEach(celebrationSparkles) { sparkle in
                        SparkleView(sparkle: sparkle)
                    }

                    // The glass
                    WaterGlass(
                        fillPercentage: fillPercentage,
                        waterColor: waterColor,
                        showAddAnimation: showAddAnimation,
                        addedAmount: addedAmount,
                        isCelebrating: showCelebration
                    )
                    .frame(width: 200, height: 280)
                    .scaleEffect(glassBounce ? 1.05 : 1.0)
                    .rotationEffect(.degrees(glassBounce ? 2 : 0))
                }
                .frame(height: 320)

                Spacer()

                // Status
                if waterManager.hasReachedGoal {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "00d2d3"))
                        Text("Goal reached!")
                            .font(.custom("Helvetica Neue", size: 18).weight(.semibold))
                            .foregroundStyle(Color(hex: "00d2d3"))
                    }
                } else {
                    Text("\(waterManager.remainingOunces) oz to go")
                        .font(.custom("Helvetica Neue", size: 18).weight(.medium))
                        .foregroundStyle(waterColor)
                }

                Spacer()

                // Amount Selector
                VStack(spacing: 16) {
                    Text("Add Water")
                        .font(.custom("Helvetica Neue", size: 14).weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))

                    HStack(spacing: 12) {
                        ForEach(amounts, id: \.self) { amount in
                            WaterAmountButton(
                                amount: amount,
                                isSelected: selectedAmount == amount,
                                color: waterColor
                            ) {
                                themeManager.lightImpact()
                                selectedAmount = amount
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Add Button
                Button {
                    addWater()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                        Text("Add \(selectedAmount) oz")
                            .font(.custom("Helvetica Neue", size: 16).weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: "0a0a0a"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(waterColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addWater() {
        themeManager.mediumImpact()
        addedAmount = selectedAmount

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showAddAnimation = true
        }

        let wasGoalReached = waterManager.hasReachedGoal
        waterManager.addWater(ounces: Double(selectedAmount))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showAddAnimation = false
            }
        }

        // Trigger celebration if goal just reached
        if waterManager.hasReachedGoal && !wasGoalReached {
            triggerCelebration()
        }
    }

    private func triggerCelebration() {
        themeManager.notifySuccess()

        // Start celebration
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            showCelebration = true
        }

        // Generate water droplets splashing out
        celebrationDroplets = (0..<20).map { i in
            let angle = Double.random(in: -Double.pi...0) // Upper half
            let distance = CGFloat.random(in: 80...160)
            return CelebrationDroplet(
                id: UUID(),
                startX: 0,
                startY: -20,
                endX: cos(angle) * distance,
                endY: sin(angle) * distance - 40,
                size: CGFloat.random(in: 8...16),
                delay: Double(i) * 0.02,
                duration: Double.random(in: 0.6...1.0)
            )
        }

        // Generate sparkles
        celebrationSparkles = (0..<15).map { i in
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 100...180)
            return CelebrationSparkle(
                id: UUID(),
                x: cos(angle) * distance,
                y: sin(angle) * distance - 40,
                size: CGFloat.random(in: 4...12),
                rotation: Double.random(in: 0...360),
                delay: Double(i) * 0.03
            )
        }

        // Pulsing glow animation
        withAnimation(.easeInOut(duration: 0.6).repeatCount(5, autoreverses: true)) {
            glowPulse = true
        }

        // Glass bounce animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4).repeatCount(3, autoreverses: true)) {
            glassBounce = true
        }

        // Reset after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                celebrationDroplets = []
                celebrationSparkles = []
                glowPulse = false
                glassBounce = false
            }
        }
    }
}

// MARK: - Celebration Droplet
struct CelebrationDroplet: Identifiable {
    let id: UUID
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let delay: Double
    let duration: Double
}

struct CelebrationDropletView: View {
    let droplet: CelebrationDroplet
    let waterColor: Color

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [waterColor, waterColor.opacity(0.6)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: droplet.size
                )
            )
            .frame(width: droplet.size, height: droplet.size)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: droplet.size * 0.3, height: droplet.size * 0.3)
                    .offset(x: -droplet.size * 0.2, y: -droplet.size * 0.2)
            )
            .offset(
                x: animate ? droplet.endX : droplet.startX,
                y: animate ? droplet.endY : droplet.startY
            )
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 0.3 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: droplet.duration)
                    .delay(droplet.delay)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Celebration Sparkle
struct CelebrationSparkle: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

struct SparkleView: View {
    let sparkle: CelebrationSparkle

    @State private var animate = false
    @State private var twinkle = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: sparkle.size, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, Color(hex: "00d2d3"), .white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .rotationEffect(.degrees(sparkle.rotation + (twinkle ? 30 : 0)))
            .scaleEffect(animate ? 1 : 0)
            .scaleEffect(twinkle ? 1.2 : 0.8)
            .opacity(animate ? (twinkle ? 1 : 0.7) : 0)
            .offset(x: sparkle.x, y: sparkle.y)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(sparkle.delay)) {
                    animate = true
                }
                withAnimation(.easeInOut(duration: 0.3).repeatCount(6, autoreverses: true).delay(sparkle.delay + 0.2)) {
                    twinkle = true
                }
            }
    }
}

// MARK: - Water Glass
struct WaterGlass: View {
    let fillPercentage: CGFloat
    let waterColor: Color
    let showAddAnimation: Bool
    let addedAmount: Int
    var isCelebrating: Bool = false

    @State private var wavePhase: CGFloat = 0
    @State private var bubbles: [WaterBubble] = []
    @State private var risingBubbles: [RisingBubble] = []

    var body: some View {
        ZStack {
            // Glass outline with glow when celebrating
            GlassShape()
                .stroke(
                    isCelebrating ? waterColor : Color.white.opacity(0.2),
                    lineWidth: isCelebrating ? 4 : 3
                )
                .shadow(color: isCelebrating ? waterColor.opacity(0.5) : .clear, radius: 10)

            // Water fill with wave
            GlassShape()
                .fill(Color.clear)
                .overlay(
                    GeometryReader { geo in
                        ZStack {
                            // Water with enhanced gradient when celebrating
                            WaterWaveShape(phase: wavePhase, amplitude: isCelebrating ? 12 : 8)
                                .fill(
                                    LinearGradient(
                                        colors: isCelebrating
                                            ? [waterColor, waterColor.opacity(0.8), Color(hex: "00d2d3")]
                                            : [waterColor, waterColor.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: geo.size.height * fillPercentage + 20)
                                .offset(y: geo.size.height * (1 - fillPercentage) - 10)

                            // Static bubbles
                            ForEach(bubbles) { bubble in
                                Circle()
                                    .fill(Color.white.opacity(bubble.opacity))
                                    .frame(width: bubble.size, height: bubble.size)
                                    .position(x: bubble.x * geo.size.width, y: bubble.y * geo.size.height)
                            }

                            // Rising celebration bubbles
                            ForEach(risingBubbles) { bubble in
                                RisingBubbleView(bubble: bubble, containerHeight: geo.size.height)
                            }
                        }
                    }
                )
                .clipShape(GlassShape())

            // Glass highlight
            GlassShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .mask(
                    Rectangle()
                        .frame(width: 30)
                        .offset(x: -60)
                )

            // Add animation
            if showAddAnimation {
                Text("+\(addedAmount) oz")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: waterColor, radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            // Start wave animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
            // Generate bubbles
            generateBubbles()
        }
        .onChange(of: fillPercentage) { _, _ in
            generateBubbles()
        }
        .onChange(of: isCelebrating) { _, celebrating in
            if celebrating {
                generateRisingBubbles()
            }
        }
    }

    private func generateBubbles() {
        bubbles = (0..<8).map { _ in
            WaterBubble(
                id: UUID(),
                x: CGFloat.random(in: 0.2...0.8),
                y: CGFloat.random(in: (1 - fillPercentage)...1.0),
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.2...0.5)
            )
        }
    }

    private func generateRisingBubbles() {
        risingBubbles = (0..<12).map { i in
            RisingBubble(
                id: UUID(),
                x: CGFloat.random(in: 0.2...0.8),
                size: CGFloat.random(in: 6...14),
                delay: Double(i) * 0.15,
                duration: Double.random(in: 1.5...2.5)
            )
        }

        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            risingBubbles = []
        }
    }
}

// MARK: - Rising Bubble
struct RisingBubble: Identifiable {
    let id: UUID
    let x: CGFloat
    let size: CGFloat
    let delay: Double
    let duration: Double
}

struct RisingBubbleView: View {
    let bubble: RisingBubble
    let containerHeight: CGFloat

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.5))
            .frame(width: bubble.size, height: bubble.size)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: bubble.size * 0.3, height: bubble.size * 0.3)
                    .offset(x: -bubble.size * 0.15, y: -bubble.size * 0.15)
            )
            .position(
                x: bubble.x * 160 + 20, // Adjusted for glass width
                y: animate ? -20 : containerHeight + 20
            )
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 1.3 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: bubble.duration)
                    .delay(bubble.delay)
                ) {
                    animate = true
                }
            }
    }
}

struct WaterBubble: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

// MARK: - Glass Shape
struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topWidth = rect.width * 0.9
        let bottomWidth = rect.width * 0.7
        let topInset = (rect.width - topWidth) / 2
        let bottomInset = (rect.width - bottomWidth) / 2

        // Start top left
        path.move(to: CGPoint(x: topInset, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: rect.width - topInset, y: 0))

        // Right edge (tapered)
        path.addLine(to: CGPoint(x: rect.width - bottomInset, y: rect.height - 20))

        // Bottom right curve
        path.addQuadCurve(
            to: CGPoint(x: rect.width - bottomInset - 20, y: rect.height),
            control: CGPoint(x: rect.width - bottomInset, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: bottomInset + 20, y: rect.height))

        // Bottom left curve
        path.addQuadCurve(
            to: CGPoint(x: bottomInset, y: rect.height - 20),
            control: CGPoint(x: bottomInset, y: rect.height)
        )

        // Left edge (tapered)
        path.addLine(to: CGPoint(x: topInset, y: 0))

        path.closeSubpath()

        return path
    }
}

// MARK: - Water Wave Shape
struct WaterWaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let wavelength = rect.width / 2

        path.move(to: CGPoint(x: 0, y: rect.height))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / wavelength
            let y = amplitude * sin(relativeX * .pi * 2 + phase)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Water Amount Button
struct WaterAmountButton: View {
    let amount: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(amount)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color(hex: "0a0a0a") : .white)
                .frame(width: 44, height: 44)
                .background(isSelected ? color : Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

#Preview {
    WaterTrackerView()
        .environmentObject(WaterIntakeManager())
        .environmentObject(ThemeManager())
}
