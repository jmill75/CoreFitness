import SwiftUI

// MARK: - Animated Counter
struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var animatedValue: Int = 0

    var body: some View {
        Text("\(animatedValue)")
            .font(font)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(animatedValue)))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animatedValue = newValue
                }
            }
    }
}

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let gradient: LinearGradient
    let backgroundColor: Color
    var accessibilityLabelText: String?

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedProgress = min(newValue, 1.0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText ?? "Progress: \(Int(progress * 100)) percent")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}

// MARK: - Pulsing Button Style
struct PulsingButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Bouncy Button Style
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Animated Stat Card
struct AnimatedStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    let delay: Double

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(subtitle != nil ? ", \(subtitle!)" : "")")
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Fade In Modifier
struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
}

// MARK: - Scale In Modifier
struct ScaleInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func scaleIn(delay: Double = 0) -> some View {
        modifier(ScaleInModifier(delay: delay))
    }
}

// MARK: - Animated Checkmark
struct AnimatedCheckmark: View {
    let isComplete: Bool
    let size: CGFloat
    let color: Color
    var accessibilityLabelText: String?

    @State private var trimEnd: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(isComplete ? color : Color(.systemGray5))
                .frame(width: size, height: size)

            if isComplete {
                Path { path in
                    let startPoint = CGPoint(x: size * 0.25, y: size * 0.5)
                    let midPoint = CGPoint(x: size * 0.42, y: size * 0.65)
                    let endPoint = CGPoint(x: size * 0.75, y: size * 0.35)

                    path.move(to: startPoint)
                    path.addLine(to: midPoint)
                    path.addLine(to: endPoint)
                }
                .trim(from: 0, to: trimEnd)
                .stroke(.white, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round, lineJoin: .round))
            }
        }
        .onChange(of: isComplete) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.3)) {
                    trimEnd = 1
                }
            } else {
                trimEnd = 0
            }
        }
        .onAppear {
            if isComplete {
                withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                    trimEnd = 1
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText ?? (isComplete ? "Completed" : "Not completed"))
    }
}

// MARK: - Animated Progress Bar
struct AnimatedProgressBar: View {
    let progress: Double
    let height: CGFloat
    let backgroundColor: Color
    let foregroundGradient: LinearGradient
    var accessibilityLabelText: String?

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor.opacity(0.2))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundGradient)
                    .frame(width: max(geometry.size.width * animatedProgress, height), height: height)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animatedProgress = min(newValue, 1.0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText ?? "Progress bar")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// Note: ConfettiView and ConfettiPiece are defined in DailyCheckInView.swift

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    var accessibilityLabelText: String = "Action button"

    @State private var isPressed = false
    @State private var showRipple = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                showRipple = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showRipple = false
            }
        }) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.4), radius: 8, y: 4)

                if showRipple {
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 2)
                        .frame(width: 70, height: 70)
                        .scaleEffect(showRipple ? 1.3 : 1)
                        .opacity(showRipple ? 0 : 1)
                }

                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(accessibilityLabelText)
    }
}

// MARK: - Animated Tab Indicator
struct AnimatedTabIndicator: View {
    let selectedIndex: Int
    let tabCount: Int
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let tabWidth = geometry.size.width / CGFloat(tabCount)

            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: tabWidth * 0.6, height: 4)
                .offset(x: tabWidth * CGFloat(selectedIndex) + tabWidth * 0.2)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
        }
        .frame(height: 4)
    }
}

// MARK: - Loading Dots
struct LoadingDots: View {
    @State private var dotIndex = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotIndex == index ? 1.3 : 1.0)
                    .opacity(dotIndex == index ? 1.0 : 0.4)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    dotIndex = (dotIndex + 1) % 3
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

// Note: SkeletonView is defined in SectionCard.swift
