import SwiftUI
import SwiftData

// MARK: - Mood Tracker View (Wave Design)
struct MoodTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedMood: Int = 2 // 0-4: Awful, Bad, Okay, Good, Great
    @State private var isSaving = false
    @State private var showSuccess = false

    private let moods = ["Awful", "Bad", "Okay", "Good", "Great"]

    private let moodColors: [MoodColorScheme] = [
        MoodColorScheme(wave: Color(hex: "6c5ce7"), face: Color(hex: "a29bfe"), accent: Color(hex: "6c5ce7")),  // Awful - Purple
        MoodColorScheme(wave: Color(hex: "0984e3"), face: Color(hex: "74b9ff"), accent: Color(hex: "0984e3")),  // Bad - Blue
        MoodColorScheme(wave: Color(hex: "fdcb6e"), face: Color(hex: "ffeaa7"), accent: Color(hex: "fdcb6e")),  // Okay - Yellow
        MoodColorScheme(wave: Color(hex: "00b894"), face: Color(hex: "55efc4"), accent: Color(hex: "00b894")),  // Good - Green
        MoodColorScheme(wave: Color(hex: "ff7675"), face: Color(hex: "fab1a0"), accent: Color(hex: "ff7675"))   // Great - Coral
    ]

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0a0a0a")
                .ignoresSafeArea()

            // Animated waves
            WaveBackground(moodIndex: selectedMood, colors: moodColors)

            // Confetti for Great mood
            if selectedMood == 4 {
                MoodConfettiView()
            }

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
                    Text("How are you")
                        .font(.custom("Helvetica Neue", size: 32).weight(.bold))
                        .foregroundStyle(.white)
                    Text("feeling?")
                        .font(.custom("Helvetica Neue", size: 32).weight(.bold))
                        .foregroundStyle(.white)
                }

                Text("Slide to express your mood")
                    .font(.custom("Helvetica Neue", size: 16).weight(.light))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)

                Spacer()

                // Animated Face
                MoodFace(
                    moodIndex: selectedMood,
                    faceColor: moodColors[selectedMood].face
                )
                .frame(width: 180, height: 180)

                Spacer()

                // Mood Label
                Text(moods[selectedMood])
                    .font(.custom("Helvetica Neue", size: 24).weight(.bold))
                    .foregroundStyle(moodColors[selectedMood].accent)
                    .animation(.easeInOut(duration: 0.3), value: selectedMood)

                Spacer()

                // Slider Section
                VStack(spacing: 16) {
                    // Custom Slider
                    MoodSlider(value: $selectedMood, accentColor: moodColors[selectedMood].accent)
                        .frame(height: 40)

                    // Labels
                    HStack {
                        ForEach(moods, id: \.self) { mood in
                            Text(mood)
                                .font(.custom("Helvetica Neue", size: 12).weight(.medium))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.03))
                .background(.ultraThinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                // Save Button
                Button {
                    saveMood()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(Color(hex: "0a0a0a"))
                        } else {
                            Text("Continue")
                                .font(.custom("Helvetica Neue", size: 16).weight(.semibold))
                        }
                    }
                    .foregroundStyle(Color(hex: "0a0a0a"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(moodColors[selectedMood].accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isSaving)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveMood() {
        isSaving = true
        themeManager.mediumImpact()

        // Convert to Mood enum
        let mood: Mood = {
            switch selectedMood {
            case 0: return .stressed
            case 1: return .tired
            case 2: return .okay
            case 3: return .good
            case 4: return .amazing
            default: return .okay
            }
        }()

        // Save MoodEntry
        let moodEntry = MoodEntry(
            date: Date(),
            mood: mood,
            energyLevel: (selectedMood + 1) * 2,
            stressLevel: (4 - selectedMood) * 2,
            notes: nil
        )
        modelContext.insert(moodEntry)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            themeManager.notifySuccess()
            NotificationCenter.default.post(name: .dailyCheckInSaved, object: nil)
            dismiss()
        }
    }
}

// MARK: - Mood Color Scheme
struct MoodColorScheme {
    let wave: Color
    let face: Color
    let accent: Color
}

// MARK: - Wave Background
struct WaveBackground: View {
    let moodIndex: Int
    let colors: [MoodColorScheme]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Wave 3 (back)
                WaveShape(offset: 0.3, amplitude: 20)
                    .fill(colors[moodIndex].wave.opacity(0.3))
                    .frame(height: geometry.size.height * 0.5)
                    .offset(y: geometry.size.height * 0.5)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: moodIndex)

                // Wave 2 (middle)
                WaveShape(offset: 0.5, amplitude: 25)
                    .fill(colors[moodIndex].wave.opacity(0.6))
                    .frame(height: geometry.size.height * 0.45)
                    .offset(y: geometry.size.height * 0.55)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: moodIndex)

                // Wave 1 (front)
                WaveShape(offset: 0, amplitude: 30)
                    .fill(colors[moodIndex].wave)
                    .frame(height: geometry.size.height * 0.4)
                    .offset(y: geometry.size.height * 0.6)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: moodIndex)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset) * .pi * 2)
            let y = amplitude * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Mood Face
struct MoodFace: View {
    let moodIndex: Int
    let faceColor: Color

    @State private var floatOffset: CGFloat = 0

    private var eyeHeight: CGFloat {
        switch moodIndex {
        case 0: return 8   // Awful - squinted
        case 1: return 16  // Bad
        case 2: return 20  // Okay
        case 3: return 20  // Good
        case 4: return 14  // Great - happy squint
        default: return 20
        }
    }

    private var eyeScaleY: CGFloat {
        moodIndex == 4 ? 0.5 : 1.0
    }

    private var mouthStyle: MouthStyle {
        switch moodIndex {
        case 0: return .frown
        case 1: return .neutral
        case 2: return .neutral
        case 3: return .smile
        case 4: return .bigSmile
        default: return .neutral
        }
    }

    var body: some View {
        ZStack {
            // Face circle
            Circle()
                .fill(faceColor)
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 20)

            // Face features
            VStack(spacing: 20) {
                // Eyes
                HStack(spacing: 35) {
                    // Left eye
                    ZStack {
                        Capsule()
                            .fill(Color(hex: "1a1a1a").opacity(0.8))
                            .frame(width: 16, height: eyeHeight)
                            .scaleEffect(y: eyeScaleY)

                        // Tear for Awful mood
                        if moodIndex == 0 {
                            TearDrop()
                                .offset(x: -2, y: eyeHeight / 2 + 8)
                        }
                    }

                    // Right eye
                    Capsule()
                        .fill(Color(hex: "1a1a1a").opacity(0.8))
                        .frame(width: 16, height: eyeHeight)
                        .scaleEffect(y: eyeScaleY)
                }

                // Mouth
                MouthShape(style: mouthStyle)
            }
        }
        .offset(y: floatOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: moodIndex == 4 ? 2 : 3).repeatForever(autoreverses: true)) {
                floatOffset = -15
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: moodIndex)
    }
}

// MARK: - Mouth Style
enum MouthStyle {
    case frown, neutral, smile, bigSmile
}

// MARK: - Mouth Shape
struct MouthShape: View {
    let style: MouthStyle

    var body: some View {
        switch style {
        case .frown:
            // Upside down smile
            Capsule()
                .fill(Color(hex: "1a1a1a").opacity(0.8))
                .frame(width: 40, height: 15)
                .mask(
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: 10)
                    }
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )

        case .neutral:
            Capsule()
                .fill(Color(hex: "1a1a1a").opacity(0.8))
                .frame(width: 25, height: 6)

        case .smile:
            // Simple smile arc
            SmileArc(curvature: 0.4)
                .fill(Color(hex: "1a1a1a").opacity(0.8))
                .frame(width: 35, height: 18)

        case .bigSmile:
            // Big open smile
            SmileArc(curvature: 0.5)
                .fill(Color(hex: "1a1a1a").opacity(0.8))
                .frame(width: 45, height: 25)
        }
    }
}

// MARK: - Smile Arc Shape
struct SmileArc: Shape {
    let curvature: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: 0),
            control: CGPoint(x: rect.width / 2, y: rect.height * (1 + curvature))
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height * 0.3),
            control: CGPoint(x: rect.width / 2, y: rect.height * curvature)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Tear Drop
struct TearDrop: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Ellipse()
            .fill(Color(hex: "74b9ff"))
            .frame(width: 8, height: 12)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 2).repeatForever(autoreverses: false)) {
                    offset = 30
                    opacity = 0
                }
            }
    }
}

// MARK: - Mood Slider
struct MoodSlider: View {
    @Binding var value: Int
    let accentColor: Color

    var body: some View {
        GeometryReader { geometry in
            let thumbSize: CGFloat = 32
            let trackWidth = geometry.size.width - thumbSize
            let stepWidth = trackWidth / 4

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
                    .offset(x: CGFloat(value) * stepWidth)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = Int((gesture.location.x / stepWidth).rounded())
                                let clampedValue = max(0, min(4, newValue))
                                if clampedValue != value {
                                    value = clampedValue
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Mood Confetti View
struct MoodConfettiView: View {
    @State private var confettiPieces: [MoodConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece, screenHeight: geometry.size.height)
                }
            }
            .onAppear {
                confettiPieces = (0..<15).map { _ in
                    MoodConfettiPiece(
                        id: UUID(),
                        x: CGFloat.random(in: 0...geometry.size.width),
                        color: [
                            Color(hex: "ff6b6b"),
                            Color(hex: "feca57"),
                            Color(hex: "48dbfb"),
                            Color(hex: "ff9ff3"),
                            Color(hex: "54a0ff"),
                            Color(hex: "5f27cd"),
                            Color(hex: "00d2d3")
                        ].randomElement()!,
                        size: CGFloat.random(in: 8...14),
                        delay: Double.random(in: 0...2)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct MoodConfettiPiece: Identifiable {
    let id: UUID
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: MoodConfettiPiece
    let screenHeight: CGFloat

    @State private var yPosition: CGFloat = -20
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(rotation))
            .position(x: piece.x, y: yPosition)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false).delay(piece.delay)) {
                    yPosition = screenHeight + 50
                    rotation = 720
                    opacity = 0.5
                }
            }
    }
}

#Preview {
    MoodTrackerView()
        .environmentObject(ThemeManager())
}
