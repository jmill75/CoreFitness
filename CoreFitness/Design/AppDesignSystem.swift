import SwiftUI

// MARK: - App Design System
/// Centralized design system for consistent AAA-quality UI

// MARK: - Brand Colors
extension Color {
    // Primary Brand
    static let brandPrimary = Color(hex: "007AFF")      // iOS Blue
    static let brandSecondary = Color(hex: "5AC8FA")    // Light Blue

    // Accent Colors
    static let accentGreen = Color(hex: "34C759")       // Apple Green
    static let accentOrange = Color(hex: "FF9500")      // Bright Orange
    static let accentBlue = Color(hex: "007AFF")        // iOS Blue
    static let accentRed = Color(hex: "FF3B30")         // Vibrant Red
    static let accentYellow = Color(hex: "FFCC00")      // Bright Yellow
    static let accentTeal = Color(hex: "5AC8FA")        // Teal/Light Blue

    // Score Colors
    static let scoreExcellent = Color(hex: "34C759")    // 80-100 - Apple Green
    static let scoreGood = Color(hex: "FFD60A")         // 60-79 - Bright Yellow
    static let scoreFair = Color(hex: "FF9F0A")         // 40-59 - Orange
    static let scorePoor = Color(hex: "FF3B30")         // 0-39 - Red

    // Background Colors (adaptive for dark mode)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let elevatedBackground = Color(.tertiarySystemGroupedBackground)

    // Dark mode specific
    static let darkCardBackground = Color(hex: "1C1C1E")
    static let darkElevatedBackground = Color(hex: "2C2C2E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
struct AppGradients {
    // Primary Gradients
    static let primary = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5AC8FA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let energetic = LinearGradient(
        colors: [Color(hex: "FF9500"), Color(hex: "FF3B30")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let health = LinearGradient(
        colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let success = LinearGradient(
        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let ocean = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5AC8FA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sunset = LinearGradient(
        colors: [Color(hex: "FF9500"), Color(hex: "FF3B30")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let night = LinearGradient(
        colors: [Color(hex: "1C1C1E"), Color(hex: "3A3A3C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let electric = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "32ADE6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Score Gradients
    static func scoreGradient(for score: Int) -> LinearGradient {
        switch score {
        case 80...100:
            // Vibrant green
            return LinearGradient(colors: [Color(hex: "22C55E"), Color(hex: "16A34A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 60..<80:
            // Clean blue
            return LinearGradient(colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 40..<60:
            // Warm orange
            return LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "EA580C")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            // Soft red
            return LinearGradient(colors: [Color(hex: "EF4444"), Color(hex: "DC2626")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Card Styles
enum CardStyle {
    case standard
    case gradient(LinearGradient)
    case accent(Color)
    case elevated
}

// MARK: - Styled Card Component
struct StyledCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    let icon: String?
    let style: CardStyle
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        icon: String? = nil,
        style: CardStyle = .standard,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.content = content
    }

    private var accentColor: Color {
        switch style {
        case .accent(let color): return color
        case .gradient: return .white
        default: return .brandPrimary
        }
    }

    private var textColor: Color {
        switch style {
        case .gradient: return .white
        default: return .primary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            if title != nil || subtitle != nil {
                HStack(spacing: 12) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(accentColor)
                            .frame(width: 32, height: 32)
                            .background(accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let title = title {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(textColor)
                        }
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(textColor.opacity(0.7))
                        }
                    }

                    Spacer()
                }
            }

            // Content
            content()
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .standard:
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        case .gradient(let gradient):
            RoundedRectangle(cornerRadius: 20)
                .fill(gradient)
        case .accent(let color):
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        case .elevated:
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
    }
}

// MARK: - Gradient Button
struct GradientButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        gradient: LinearGradient = AppGradients.primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(gradient)
            .clipShape(Capsule())
            .shadow(color: Color.brandPrimary.opacity(0.3), radius: isPressed ? 4 : 8, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(title)
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Icon Badge
struct IconBadge: View {
    let icon: String
    let color: Color
    let size: CGFloat

    init(_ icon: String, color: Color, size: CGFloat = 44) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.45))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    var accessibilityLabelText: String?

    init(progress: Double, color: Color = .brandPrimary, lineWidth: CGFloat = 10, size: CGFloat = 100, accessibilityLabelText: String? = nil) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.accessibilityLabelText = accessibilityLabelText
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText ?? "Progress: \(Int(progress * 100)) percent")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}

// MARK: - Dismiss Button (X)
struct DismissButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let action: () -> Void

    var body: some View {
        Button {
            themeManager.lightImpact()
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .frame(width: 44, height: 44) // Minimum touch target size for accessibility
        .accessibilityLabel("Close")
        .accessibilityHint("Double tap to dismiss")
    }
}

// MARK: - Glass Slider
struct GlassSlider: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tintColor: Color
    let onEditingChanged: ((Bool) -> Void)?

    @State private var isDragging = false

    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        tint: Color = .brandPrimary,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tintColor = tint
        self.onEditingChanged = onEditingChanged
    }

    private var progress: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let thumbSize: CGFloat = 32
            let trackHeight: CGFloat = 12
            let thumbPosition = width * progress

            ZStack(alignment: .leading) {
                // Track background (liquid glass)
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(height: trackHeight)
                    .overlay(
                        // Inner shadow effect
                        Capsule()
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                            .blur(radius: 1)
                            .offset(y: 1)
                            .mask(Capsule())
                    )
                    .overlay(
                        // Top highlight
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: trackHeight / 2)
                            .offset(y: -trackHeight / 4)
                    )
                    .overlay(
                        // Border
                        Capsule()
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )

                // Filled track (liquid glass with color)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tintColor.opacity(0.9), tintColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(0, thumbPosition + trackHeight / 2), height: trackHeight)
                    .overlay(
                        // Glossy shine on filled track
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: trackHeight * 0.4)
                            .offset(y: -trackHeight * 0.2)
                            .mask(
                                Capsule()
                                    .frame(width: max(0, thumbPosition + trackHeight / 2), height: trackHeight)
                            )
                    )
                    .shadow(color: tintColor.opacity(0.4), radius: 4, y: 2)

                // Thumb (liquid glass bubble)
                ZStack {
                    // Soft glow behind thumb
                    Circle()
                        .fill(tintColor.opacity(isDragging ? 0.3 : 0.15))
                        .frame(width: thumbSize * (isDragging ? 1.5 : 1.15), height: thumbSize * (isDragging ? 1.5 : 1.15))
                        .blur(radius: isDragging ? 6 : 3)

                    // Main glass bubble
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            // Inner gradient for depth
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(0.8), .white.opacity(0.2), .clear],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: thumbSize * 0.8
                                    )
                                )
                        )
                        .overlay(
                            // Secondary highlight
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(0.6), .clear],
                                        center: UnitPoint(x: 0.3, y: 0.2),
                                        startRadius: 0,
                                        endRadius: thumbSize * 0.4
                                    )
                                )
                        )
                        .overlay(
                            // Glass border
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.8), .white.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isDragging ? 2.5 : 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
                }
                .shadow(color: tintColor.opacity(isDragging ? 0.6 : 0.3), radius: isDragging ? 16 : 6, y: isDragging ? 6 : 3)
                .scaleEffect(isDragging ? 1.35 : 1.0)
                .offset(x: max(0, min(thumbPosition - thumbSize / 2, width - thumbSize)))
                .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isDragging)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { gesture in
                        // Only activate if drag is more horizontal than vertical
                        let horizontalDrag = abs(gesture.translation.width)
                        let verticalDrag = abs(gesture.translation.height)

                        if !isDragging {
                            // Require horizontal intent to start dragging
                            if horizontalDrag > verticalDrag {
                                isDragging = true
                                onEditingChanged?(true)
                                themeManager.lightImpact()
                            } else {
                                return
                            }
                        }

                        let newProgress = gesture.location.x / width
                        let clampedProgress = max(0, min(1, newProgress))
                        let rawValue = range.lowerBound + clampedProgress * (range.upperBound - range.lowerBound)
                        let steppedValue = (rawValue / step).rounded() * step
                        let newValue = max(range.lowerBound, min(range.upperBound, steppedValue))

                        // Haptic feedback when value changes
                        if newValue != value {
                            themeManager.lightImpact()
                        }
                        value = newValue
                    }
                    .onEnded { _ in
                        if isDragging {
                            isDragging = false
                            onEditingChanged?(false)
                            themeManager.lightImpact()
                        }
                    }
            )
        }
        .frame(height: 32)
    }
}

// MARK: - Previews
#Preview("Design System") {
    ScrollView {
        VStack(spacing: 20) {
            // Glass Sliders
            VStack(spacing: 16) {
                Text("Glass Sliders")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GlassSlider(value: .constant(0.7), in: 0...1, tint: .brandPrimary)
                GlassSlider(value: .constant(0.5), in: 0...1, tint: .accentGreen)
                GlassSlider(value: .constant(0.3), in: 0...1, tint: .accentOrange)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Gradient Buttons
            HStack {
                GradientButton("Start", icon: "play.fill", gradient: AppGradients.success) {}
                GradientButton("Create", icon: "sparkles", gradient: AppGradients.primary) {}
            }

            // Stat Pills
            HStack {
                StatPill(value: "85", label: "Score", color: .accentGreen)
                StatPill(value: "7.5h", label: "Sleep", color: .accentBlue)
                StatPill(value: "62", label: "HR", color: .accentRed)
            }

            // Icon Badges
            HStack(spacing: 16) {
                IconBadge("figure.run", color: .accentOrange)
                IconBadge("heart.fill", color: .accentRed)
                IconBadge("moon.fill", color: .accentBlue)
                IconBadge("flame.fill", color: .accentRed)
            }

            // Progress Ring
            ProgressRing(progress: 0.75, color: .accentGreen, size: 120)

            // Styled Cards
            StyledCard(title: "Standard Card", subtitle: "Default styling", icon: "star.fill") {
                Text("Content here")
            }

            StyledCard(title: "Accent Card", subtitle: "With color accent", icon: "bolt.fill", style: .accent(.accentOrange)) {
                Text("Content here")
            }

            StyledCard(title: "Gradient Card", subtitle: "Vibrant background", icon: "sparkles", style: .gradient(AppGradients.primary)) {
                Text("Content here")
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Animation Utilities

/// Standard app animations
struct AppAnimations {
    /// Quick spring for button presses
    static let buttonPress = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Smooth entrance animation
    static let entrance = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Subtle bounce
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Smooth transition
    static let smooth = Animation.easeInOut(duration: 0.3)

    /// Fast transition
    static let fast = Animation.easeOut(duration: 0.2)
}

/// Staggered animation modifier for lists
struct StaggeredAnimation: ViewModifier {
    let index: Int
    let animation: Animation

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(animation.delay(Double(index) * 0.05)) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Apply staggered entrance animation based on index
    func staggeredAnimation(index: Int, animation: Animation = AppAnimations.entrance) -> some View {
        modifier(StaggeredAnimation(index: index, animation: animation))
    }
}

/// Pressable button style with scale effect
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
    }
}

/// Bounce animation modifier
struct BounceOnAppear: ViewModifier {
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(AppAnimations.bounce) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Apply bounce animation on appear
    func bounceOnAppear() -> some View {
        modifier(BounceOnAppear())
    }
}
