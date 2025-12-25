import SwiftUI

struct HealthView: View {

    // MARK: - Environment
    @EnvironmentObject var healthKitManager: HealthKitManager

    // MARK: - State
    @State private var showWaterIntake = false
    @State private var showMoodDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with + button
                    HStack {
                        Text("Health")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        // Quick Add Menu Button (same as Home/Programs)
                        Menu {
                            Button {
                                showMoodDetail = true
                            } label: {
                                Label("Daily Check-in", systemImage: "heart.text.square")
                            }

                            Button {
                                showWaterIntake = true
                            } label: {
                                Label("Log Water", systemImage: "drop.fill")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(Color.accentBlue)
                                .clipShape(Circle())
                                .shadow(color: Color.accentBlue.opacity(0.4), radius: 10, y: 5)
                        }
                    }

                    // Recovery Status - Hero Card
                    RecoveryStatusCard()

                    // Score Trend - Compact
                    ScoreTrendCard()

                    // Health Metrics Grid
                    HealthMetricsSection()

                    // Water Intake
                    WaterIntakeCard(showDetail: $showWaterIntake)

                    // Mood Tracker
                    MoodTrackerCard(showDetail: $showMoodDetail)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showWaterIntake) {
                WaterIntakeDetailView()
                    .background(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $showMoodDetail) {
                MoodDetailView()
                    .background(.ultraThinMaterial)
            }
            .task {
                // Refresh health data when view appears
                if healthKitManager.isAuthorized {
                    await healthKitManager.fetchTodayData()
                }
            }
        }
    }
}

// MARK: - Score Trend Card (Line Graph)
struct ScoreTrendCard: View {

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let values: [Double] = [60, 75, 65, 82, 78, 88, 85]
    private let chartHeight: CGFloat = 120

    private var maxValue: Double { values.max() ?? 100 }
    private var minValue: Double { max(0, (values.min() ?? 0) - 10) }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Trend")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Recovery score over 7 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("+5%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentGreen)
                .clipShape(Capsule())
            }

            // Line Graph with Y-axis labels
            HStack(alignment: .top, spacing: 8) {
                // Y-axis labels
                VStack {
                    Text("100")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("75")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("50")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("25")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 28, height: chartHeight)

                // Chart area
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let stepX = width / CGFloat(values.count - 1)

                    ZStack {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<4) { _ in
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                Spacer()
                            }
                        }

                        // Gradient fill under line
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: chartHeight))
                            for (index, value) in values.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = chartHeight - (CGFloat(value) / 100.0) * chartHeight
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: width, y: chartHeight))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary.opacity(0.3), Color.brandPrimary.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        Path { path in
                            for (index, value) in values.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = chartHeight - (CGFloat(value) / 100.0) * chartHeight
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.accentGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )

                        // Data points with value labels
                        ForEach(0..<values.count, id: \.self) { index in
                            let x = CGFloat(index) * stepX
                            let y = chartHeight - (CGFloat(values[index]) / 100.0) * chartHeight

                            VStack(spacing: 4) {
                                Text("\(Int(values[index]))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.brandPrimary)

                                Circle()
                                    .fill(Color.brandPrimary)
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 5, height: 5)
                                    )
                            }
                            .position(x: x, y: y - 12)
                        }
                    }
                }
                .frame(height: chartHeight)
            }

            // Day labels (offset to align with chart)
            HStack(spacing: 8) {
                Spacer()
                    .frame(width: 28)

                HStack {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Health Metric Type
enum HealthMetricType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case hrv = "HRV"
    case restingHR = "Resting HR"
    case sleep = "Sleep"
    case steps = "Steps"

    var icon: String {
        switch self {
        case .hrv: return "waveform.path.ecg"
        case .restingHR: return "heart.fill"
        case .sleep: return "moon.fill"
        case .steps: return "figure.walk"
        }
    }

    var unit: String {
        switch self {
        case .hrv: return "ms"
        case .restingHR: return "bpm"
        case .sleep: return "hrs"
        case .steps: return ""
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .hrv: return AppGradients.primary
        case .restingHR: return AppGradients.health
        case .sleep: return AppGradients.ocean
        case .steps: return AppGradients.energetic
        }
    }

    var color: Color {
        switch self {
        case .hrv: return .brandPrimary
        case .restingHR: return .accentRed
        case .sleep: return .accentBlue
        case .steps: return .accentOrange
        }
    }

    var description: String {
        switch self {
        case .hrv: return "Heart Rate Variability measures the variation in time between heartbeats. Higher values generally indicate better recovery."
        case .restingHR: return "Your resting heart rate when you're calm and relaxed. Lower values typically indicate better cardiovascular fitness."
        case .sleep: return "Total hours of sleep recorded. Adults typically need 7-9 hours for optimal recovery."
        case .steps: return "Total steps taken throughout the day. 10,000 steps is a common daily goal."
        }
    }

    // Sample 30-day data for demo
    var sampleData: [Double] {
        switch self {
        case .hrv:
            return [42, 45, 38, 52, 48, 55, 50, 47, 44, 51, 53, 49, 46, 58, 54, 52, 48, 45, 50, 56, 53, 49, 47, 52, 55, 51, 48, 54, 57, 52]
        case .restingHR:
            return [62, 60, 64, 58, 61, 59, 63, 60, 58, 62, 59, 61, 57, 60, 62, 58, 61, 59, 63, 57, 60, 58, 62, 59, 61, 58, 60, 57, 59, 58]
        case .sleep:
            return [7.2, 6.8, 7.5, 8.1, 6.5, 7.8, 7.0, 6.9, 7.4, 8.0, 7.2, 6.7, 7.6, 7.3, 6.8, 7.9, 7.1, 6.6, 7.5, 8.2, 7.0, 6.9, 7.4, 7.8, 7.2, 6.8, 7.5, 7.1, 7.6, 7.3]
        case .steps:
            return [8500, 10200, 6800, 12400, 9100, 7600, 11300, 8900, 10500, 7200, 9800, 11000, 8400, 10100, 6900, 12000, 9500, 8100, 10800, 7400, 9200, 11500, 8700, 10300, 7000, 9600, 11200, 8300, 10000, 9400]
        }
    }

    var yAxisRange: (min: Double, max: Double) {
        switch self {
        case .hrv: return (20, 80)
        case .restingHR: return (50, 80)
        case .sleep: return (4, 10)
        case .steps: return (0, 15000)
        }
    }
}

// MARK: - Health Metrics Section
struct HealthMetricsSection: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedMetric: HealthMetricType?

    private var hrvValue: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        return "\(Int(hrv))"
    }

    private var restingHRValue: String {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return "--" }
        return "\(Int(hr))"
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1f", hours)
    }

    private var stepsValue: String {
        guard let steps = healthKitManager.healthData.steps else { return "--" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "--"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apple Health Data")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HealthMetricCard(
                    title: "HRV",
                    value: hrvValue,
                    unit: "ms",
                    trend: .neutral,
                    icon: "waveform.path.ecg",
                    gradient: AppGradients.primary
                ) {
                    selectedMetric = .hrv
                }

                HealthMetricCard(
                    title: "Resting HR",
                    value: restingHRValue,
                    unit: "bpm",
                    trend: .neutral,
                    icon: "heart.fill",
                    gradient: AppGradients.health
                ) {
                    selectedMetric = .restingHR
                }

                HealthMetricCard(
                    title: "Sleep",
                    value: sleepValue,
                    unit: "hrs",
                    trend: .neutral,
                    icon: "moon.fill",
                    gradient: AppGradients.ocean
                ) {
                    selectedMetric = .sleep
                }

                HealthMetricCard(
                    title: "Steps",
                    value: stepsValue,
                    unit: "",
                    trend: .neutral,
                    icon: "figure.walk",
                    gradient: AppGradients.energetic
                ) {
                    selectedMetric = .steps
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(item: $selectedMetric) { metric in
            HealthMetricDetailView(metricType: metric)
        }
    }
}

enum Trend {
    case up, down, neutral

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .white
        case .down: return .white
        case .neutral: return .white.opacity(0.7)
        }
    }
}

struct HealthMetricCard: View {

    let title: String
    let value: String
    let unit: String
    let trend: Trend
    let icon: String
    let gradient: LinearGradient
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(value)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .foregroundStyle(.white)
            .padding()
            .frame(height: 120)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Water Intake Size
enum WaterIntakeSize: CaseIterable, Identifiable {
    case glass      // 8oz
    case small      // 16oz
    case medium     // 24oz
    case large      // 32oz
    case extraLarge // 64oz

    var id: String { name }

    var name: String {
        switch self {
        case .glass: return "Glass"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "XL"
        }
    }

    var ounces: Double {
        switch self {
        case .glass: return 8
        case .small: return 16
        case .medium: return 24
        case .large: return 32
        case .extraLarge: return 64
        }
    }

    var icon: String {
        switch self {
        case .glass: return "cup.and.saucer.fill"
        case .small: return "waterbottle.fill"
        case .medium: return "waterbottle.fill"
        case .large: return "waterbottle.fill"
        case .extraLarge: return "waterbottle.fill"
        }
    }

    var displaySize: String {
        "\(Int(ounces))oz"
    }
}

// MARK: - Water Intake Card (Enhanced)
struct WaterIntakeCard: View {

    @Binding var showDetail: Bool
    @EnvironmentObject var waterManager: WaterIntakeManager
    @State private var showAddSheet = false
    @State private var animateProgress = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkRotation: Double = 0
    @State private var showCheckmark = false
    @State private var checkmarkBounce: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentBlue)

                Text("Water Intake")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(Int(waterManager.ringProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(waterManager.hasReachedGoal ? Color.accentGreen : Color.accentBlue)
                .clipShape(Capsule())
            }

            // Current intake display with animated ring
            HStack(spacing: 24) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.accentBlue.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: animateProgress ? waterManager.ringProgress : 0)
                        .stroke(
                            LinearGradient(
                                colors: [Color.accentBlue, waterManager.hasReachedGoal ? Color.accentGreen : Color.accentTeal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(waterManager.totalOunces))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accentBlue)
                        Text("oz")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animateProgress = true
                    }
                }

                // Intake info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(waterManager.totalOunces))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accentBlue)
                        Text("/ \(Int(waterManager.goalOunces)) oz")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(Int(waterManager.totalOunces / 8)) glasses equivalent")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if waterManager.hasReachedGoal {
                        HStack(spacing: 6) {
                            ZStack {
                                // Glow effect behind checkmark
                                Circle()
                                    .fill(Color.accentGreen.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                    .blur(radius: 4)
                                    .scaleEffect(showCheckmark ? 1.3 * checkmarkBounce : 0)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.accentGreen)
                                    .scaleEffect(checkmarkScale * checkmarkBounce)
                                    .rotationEffect(.degrees(checkmarkRotation))
                            }

                            Text("Goal reached!")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentGreen)
                                .opacity(showCheckmark ? 1 : 0)
                                .offset(x: showCheckmark ? 0 : -10)
                        }
                        .onAppear {
                            startCheckmarkAnimation()
                            startContinuousBounce()
                        }
                        .onChange(of: waterManager.hasReachedGoal) { _, newValue in
                            if newValue {
                                startCheckmarkAnimation()
                                startContinuousBounce()
                            }
                        }
                    }
                }

                Spacer()
            }

            // Quick add buttons
            VStack(spacing: 12) {
                Text("Quick Add")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    ForEach(WaterIntakeSize.allCases) { size in
                        WaterQuickAddButton(size: size) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                waterManager.addWater(ounces: size.ounces)
                                animateProgress = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    animateProgress = true
                                }
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentBlue.opacity(0.15))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBlue, waterManager.hasReachedGoal ? Color.accentGreen : Color.accentTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * waterManager.ringProgress, height: 10)
                        .animation(.spring(response: 0.4), value: waterManager.totalOunces)
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    // MARK: - Checkmark Animation
    private func startCheckmarkAnimation() {
        // Reset
        checkmarkScale = 0
        checkmarkRotation = -45
        showCheckmark = false

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Animate checkmark bouncing in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)) {
            checkmarkScale = 1.3
            checkmarkRotation = 10
            showCheckmark = true
        }

        // Bounce back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                checkmarkScale = 0.85
                checkmarkRotation = -5
            }
        }

        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkRotation = 0
            }
        }
    }

    // MARK: - Continuous Bounce
    private func startContinuousBounce() {
        // Start subtle continuous bounce after initial animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                checkmarkBounce = 1.12
            }
        }
    }
}

// MARK: - Water Quick Add Button
struct WaterQuickAddButton: View {
    let size: WaterIntakeSize
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: size.icon)
                    .font(.system(size: size == .glass ? 14 : 16))
                    .fontWeight(.medium)
                Text(size.displaySize)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color.accentBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentBlue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Mood Tracker Card
struct MoodTrackerCard: View {

    @Binding var showDetail: Bool
    @State private var bounceValues: [Int: Bool] = [:]
    @State private var hasStartedAnimation = false

    var body: some View {
        Button {
            showDetail = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    IconBadge("face.smiling.fill", color: .accentYellow, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mood This Week")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Your emotional patterns")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Mood grid with animated emojis
                HStack(spacing: 0) {
                    ForEach(Array(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 8) {
                            Text(moodEmoji(for: day))
                                .font(.title2)
                                .scaleEffect(bounceValues[index] == true ? 1.2 : 1.0)
                                .rotationEffect(.degrees(bounceValues[index] == true ? -5 : 0))
                            Text(dayAbbreviation(for: day))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(moodColor(for: day).opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onAppear {
                            // Start animation for each day with staggered delay
                            if index == 0 && !hasStartedAnimation {
                                hasStartedAnimation = true
                                for i in 0..<7 {
                                    startBounceAnimation(for: i)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Mood summary
                HStack(spacing: 16) {
                    MoodSummaryPill(emoji: "😄", label: "Great", count: 3, color: .accentGreen)
                    MoodSummaryPill(emoji: "😊", label: "Good", count: 2, color: .accentBlue)
                    MoodSummaryPill(emoji: "😐", label: "Okay", count: 1, color: .accentOrange)
                    MoodSummaryPill(emoji: "😴", label: "Tired", count: 1, color: .accentTeal)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func moodEmoji(for day: String) -> String {
        switch day {
        case "Mon": return "😊"
        case "Tue": return "😄"
        case "Wed": return "😐"
        case "Thu": return "😊"
        case "Fri": return "😄"
        case "Sat": return "🤩"
        case "Sun": return "😴"
        default: return "😐"
        }
    }

    private func dayAbbreviation(for day: String) -> String {
        switch day {
        case "Mon": return "M"
        case "Tue": return "Tu"
        case "Wed": return "W"
        case "Thu": return "Th"
        case "Fri": return "F"
        case "Sat": return "Sa"
        case "Sun": return "Su"
        default: return ""
        }
    }

    private func moodColor(for day: String) -> Color {
        let emoji = moodEmoji(for: day)
        switch emoji {
        case "😄", "🤩": return .accentGreen
        case "😊": return .accentBlue
        case "😐": return .accentOrange
        case "😔": return .accentRed
        case "😴": return .accentTeal
        default: return .gray
        }
    }

    private func startBounceAnimation(for index: Int) {
        // Stagger the animation start for each emoji
        let delay = Double(index) * 0.15

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounceValues[index] = true
            }

            // Return to normal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounceValues[index] = false
                }
            }
        }

        // Repeat animation periodically
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0 + delay) {
            startBounceAnimation(for: index)
        }
    }
}

struct MoodSummaryPill: View {
    let emoji: String
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title3)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// MARK: - Mood Detail View (30 Days)
struct MoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var emojiScale: CGFloat = 0.3
    @State private var emojiRotation: Double = 0
    @State private var emojiOffset: CGFloat = -30
    @State private var emojiOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    // Shimmer animation for 30-day grid
    @State private var shimmerValues: [Int: Bool] = [:]
    @State private var hasStartedGridAnimation = false

    // Mood types with their properties
    private let moodTypes: [(emoji: String, label: String, color: Color)] = [
        ("😄", "Great", .accentGreen),
        ("😊", "Good", .accentBlue),
        ("😐", "Okay", .accentOrange),
        ("😔", "Low", .accentRed),
        ("😴", "Tired", .accentTeal)
    ]

    // Sample 30-day mood data (index into moodTypes)
    private let dailyMoods: [Int] = [
        0, 1, 2, 1, 0, 0, 4,  // Week 1
        1, 0, 1, 2, 1, 0, 1,  // Week 2
        2, 1, 0, 0, 1, 0, 4,  // Week 3
        1, 1, 0, 2, 3, 1, 0   // Week 4 + 2 days
    ]

    private var moodCounts: [Int] {
        var counts = Array(repeating: 0, count: moodTypes.count)
        for mood in dailyMoods {
            counts[mood] += 1
        }
        return counts
    }

    private var dominantMood: Int {
        moodCounts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary header with animated emoji
                    VStack(spacing: 12) {
                        ZStack {
                            // Glow effect behind emoji
                            Circle()
                                .fill(moodTypes[dominantMood].color.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)
                                .scaleEffect(emojiScale * 1.2)
                                .opacity(glowOpacity)

                            Text(moodTypes[dominantMood].emoji)
                                .font(.system(size: 80))
                                .scaleEffect(emojiScale)
                                .rotationEffect(.degrees(emojiRotation))
                                .offset(y: emojiOffset)
                                .opacity(emojiOpacity)
                        }
                        .onAppear {
                            startEmojiAnimation()
                        }

                        Text("Mostly \(moodTypes[dominantMood].label)")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Based on your last 30 days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Mood breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mood Breakdown")
                            .font(.headline)
                            .fontWeight(.bold)

                        ForEach(0..<moodTypes.count, id: \.self) { index in
                            MoodBreakdownRow(
                                emoji: moodTypes[index].emoji,
                                label: moodTypes[index].label,
                                count: moodCounts[index],
                                total: dailyMoods.count,
                                color: moodTypes[index].color
                            )
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // 30-day calendar grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last 30 Days")
                            .font(.headline)
                            .fontWeight(.bold)

                        // Calendar grid (5 rows x 7 columns, showing last 30 days)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                            // Day labels - use unique string IDs
                            ForEach(Array(["Su", "M", "Tu", "W", "Th", "F", "Sa"].enumerated()), id: \.offset) { index, day in
                                Text(day)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .frame(height: 20)
                                    .id("day-\(index)")
                            }

                            // Empty cells for alignment (assuming we start mid-week)
                            ForEach(0..<2, id: \.self) { index in
                                Color.clear
                                    .frame(height: 44)
                                    .id("empty-\(index)")
                            }

                            // Mood cells with shimmer animation
                            ForEach(0..<dailyMoods.count, id: \.self) { index in
                                VStack(spacing: 2) {
                                    Text(moodTypes[dailyMoods[index]].emoji)
                                        .font(.title3)
                                        .scaleEffect(shimmerValues[index] == true ? 1.3 : 1.0)
                                        .rotationEffect(.degrees(shimmerValues[index] == true ? -8 : 0))
                                    Text("\(index + 1)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(moodTypes[dailyMoods[index]].color.opacity(shimmerValues[index] == true ? 0.3 : 0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .id("mood-\(index)")
                                .onAppear {
                                    if index == 0 && !hasStartedGridAnimation {
                                        hasStartedGridAnimation = true
                                        startRandomShimmer()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentYellow)
                }
            }
        }
    }

    private func startEmojiAnimation() {
        // Dramatic entrance - drop in and bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            emojiScale = 1.4
            emojiOffset = 0
            emojiOpacity = 1.0
            glowOpacity = 0.8
        }

        // First bounce back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                emojiScale = 0.9
                emojiRotation = -15
            }
        }

        // Second bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                emojiScale = 1.15
                emojiRotation = 10
            }
        }

        // Settle to normal size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                emojiScale = 1.0
                emojiRotation = 0
                glowOpacity = 0.5
            }
        }

        // Start continuous pulsing animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                emojiScale = 1.15
                glowOpacity = 0.8
            }

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                emojiRotation = 8
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    emojiRotation = -8
                }
            }
        }
    }

    // MARK: - Random Shimmer Animation for 30-Day Grid
    private func startRandomShimmer() {
        // Pick 2-3 random emojis to shimmer
        let count = Int.random(in: 2...3)
        let indices = (0..<dailyMoods.count).shuffled().prefix(count)

        for (delay, index) in indices.enumerated() {
            let staggerDelay = Double(delay) * 0.15

            DispatchQueue.main.asyncAfter(deadline: .now() + staggerDelay) {
                // Animate in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    shimmerValues[index] = true
                }

                // Animate out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        shimmerValues[index] = false
                    }
                }
            }
        }

        // Repeat with random interval (2-4 seconds)
        let nextInterval = Double.random(in: 2.0...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + nextInterval) {
            startRandomShimmer()
        }
    }
}

struct MoodBreakdownRow: View {
    let emoji: String
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var percentage: Double {
        Double(count) / Double(total)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(count) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("(\(Int(percentage * 100))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * percentage, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}

// MARK: - Recovery Status Card (Same as Home)
struct RecoveryStatusCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    // Blue Ocean Theme
    // Ring gradient: #60a5fa to #3b82f6
    // Background: #1e40af to #1e3a8a
    // Pill backgrounds: #60a5fa
    // Icon colors: emoji colors (yellow moon, pink heart, red heart)
    private let ringStart = Color(hex: "60a5fa")
    private let ringEnd = Color(hex: "3b82f6")
    private let bgStart = Color(hex: "1e40af")
    private let bgEnd = Color(hex: "1e3a8a")
    private let pillBgColor = Color(hex: "60a5fa")
    private let sleepColor = Color(hex: "fcd34d")    // Yellow moon
    private let hrvColor = Color(hex: "ec4899")      // Pink heart
    private let hrColor = Color(hex: "ef4444")       // Red heart

    private var score: Int {
        healthKitManager.calculateOverallScore()
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return .scoreExcellent
        case 60..<80: return .scoreGood
        case 40..<60: return .scoreFair
        default: return .scorePoor
        }
    }

    private var scoreMessage: String {
        if !healthKitManager.isAuthorized {
            return "No health data"
        }
        switch score {
        case 80...100: return "You're crushing it today!"
        case 60..<80: return "Good recovery, keep it up!"
        case 40..<60: return "Take it easy today"
        default: return "Consider a rest day"
        }
    }

    private var recommendation: String {
        if !healthKitManager.isAuthorized {
            return "Connect Apple Health to see your score"
        }
        switch score {
        case 80...100: return "High intensity workout recommended"
        case 60..<80: return "Moderate workout recommended"
        case 40..<60: return "Light activity recommended"
        default: return "Rest and recovery day"
        }
    }

    private var sleepStatus: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        if hours >= 7 { return "Good" }
        else if hours >= 6 { return "Fair" }
        else { return "Low" }
    }

    private var hrvStatus: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        if hrv >= 50 { return "High" }
        else if hrv >= 30 { return "Normal" }
        else { return "Low" }
    }

    private var hrStatus: String {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return "--" }
        if hr <= 60 { return "Low" }
        else if hr <= 75 { return "Normal" }
        else { return "High" }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Today's Recovery")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            HStack(spacing: 24) {
                // Large Score Ring with gradient
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 14)
                        .frame(width: 110, height: 110)

                    // Green gradient progress ring
                    Circle()
                        .trim(from: 0, to: healthKitManager.isAuthorized ? CGFloat(score) / 100.0 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [ringStart, ringEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: ringStart.opacity(0.5), radius: 6)

                    // Score text
                    VStack(spacing: 2) {
                        Text(healthKitManager.isAuthorized ? "\(score)" : "--")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("SCORE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Message and recommendation
                VStack(alignment: .leading, spacing: 10) {
                    Text(scoreMessage)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    Text(recommendation)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            // Recovery factors row with colored icons
            HStack(spacing: 10) {
                RecoveryFactorPillHealth(
                    icon: "moon.fill",
                    label: "Sleep",
                    value: sleepStatus,
                    iconColor: sleepColor,
                    bgColor: pillBgColor
                )
                RecoveryFactorPillHealth(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: hrvStatus,
                    iconColor: hrvColor,
                    bgColor: pillBgColor
                )
                RecoveryFactorPillHealth(
                    icon: "heart.fill",
                    label: "HR",
                    value: hrStatus,
                    iconColor: hrColor,
                    bgColor: pillBgColor
                )
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [bgStart, bgEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: ringStart.opacity(0.3), radius: 12, y: 6)
    }
}

struct RecoveryFactorPillHealth: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color
    var bgColor: Color? = nil  // Optional separate bg color

    var body: some View {
        HStack(spacing: 8) {
            // Colored icon circle
            ZStack {
                Circle()
                    .fill((bgColor ?? iconColor).opacity(0.3))
                    .frame(width: 26, height: 26)

                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Water Intake Detail View
struct WaterIntakeDetailView: View {
    @Environment(\.dismiss) private var dismiss

    // Water droplet animation state - 25 droplets for full screen rain
    private let dropletCount = 25
    @State private var dropletYPositions: [CGFloat] = Array(repeating: -100, count: 25)
    @State private var dropletOpacities: [Double] = Array(repeating: 0, count: 25)
    @State private var hasAnimated = false

    // Pre-computed random values for each droplet
    private let dropletXPositions: [CGFloat] = (0..<25).map { _ in CGFloat.random(in: -180...180) }
    private let dropletSizes: [CGFloat] = (0..<25).map { _ in CGFloat.random(in: 16...32) }
    private let dropletDelays: [Double] = (0..<25).map { _ in Double.random(in: 0...0.8) }

    private let chartHeight: CGFloat = 200
    private let goalOz: Double = 64  // 64oz daily goal

    // Sample 30-day water intake data (in ounces)
    private let dailyData: [Double] = [
        48, 56, 40, 64, 56, 48, 64, 40, 56, 48,
        64, 56, 48, 40, 56, 64, 48, 56, 40, 64,
        56, 48, 64, 56, 40, 48, 64, 56, 48, 40
    ]

    private var averageOz: Double {
        dailyData.reduce(0, +) / Double(dailyData.count)
    }

    private var daysMetGoal: Int {
        dailyData.filter { $0 >= goalOz }.count
    }

    private var maxValue: Double {
        dailyData.max() ?? 80
    }

    private var minValue: Double {
        dailyData.min() ?? 0
    }

    private var currentStreak: Int {
        var streak = 0
        for value in dailyData.reversed() {
            if value >= goalOz {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var totalOz: Double {
        dailyData.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header summary card
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            // Progress circle
                            ZStack {
                                Circle()
                                    .stroke(Color.accentBlue.opacity(0.2), lineWidth: 10)
                                    .frame(width: 100, height: 100)

                                Circle()
                                    .trim(from: 0, to: CGFloat(daysMetGoal) / 30.0)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.accentBlue, Color.accentTeal],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 0) {
                                    Text("\(Int(Double(daysMetGoal) / 30.0 * 100))%")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.accentBlue)
                                    Text("Success")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.0f oz", averageOz))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Daily Average")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(daysMetGoal)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(Color.accentGreen)
                                        Text("Goals Met")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(currentStreak)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(Color.accentOrange)
                                        Text("Day Streak")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color.accentBlue.opacity(0.15), Color.accentTeal.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // 30-day bar chart
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Last 30 Days")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                Text(String(format: "%.0f oz total", totalOz))
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        // Bar chart with Y-axis labels
                        HStack(alignment: .top, spacing: 8) {
                            // Y-axis labels
                            VStack(alignment: .trailing) {
                                Text("80oz")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("60oz")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("40oz")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("20oz")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("0")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 28, height: chartHeight)

                            // Chart area with grid and bars
                            ZStack(alignment: .bottom) {
                                // Grid lines
                                VStack(spacing: 0) {
                                    ForEach(0..<4, id: \.self) { _ in
                                        Divider()
                                            .background(Color.gray.opacity(0.2))
                                        Spacer()
                                    }
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                }
                                .frame(height: chartHeight)

                                // Goal line at 64oz
                                Rectangle()
                                    .fill(Color.accentGreen.opacity(0.6))
                                    .frame(height: 2)
                                    .offset(y: -chartHeight * (goalOz / 80.0))

                                // Bars
                                HStack(alignment: .bottom, spacing: 2) {
                                    ForEach(0..<dailyData.count, id: \.self) { index in
                                        let value = dailyData[index]
                                        let height = (value / 80.0) * chartHeight
                                        let metGoal = value >= goalOz

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(
                                                metGoal ?
                                                LinearGradient(colors: [Color.accentGreen, Color.accentGreen.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                                                LinearGradient(colors: [Color.accentBlue, Color.accentBlue.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                            )
                                            .frame(height: max(height, 4))
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(height: chartHeight)
                            }
                        }
                        .padding(.horizontal)

                        // X-axis week labels
                        HStack(spacing: 0) {
                            Spacer().frame(width: 36)
                            ForEach(0..<4, id: \.self) { week in
                                Text("Week \(week + 1)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                            Text("W5")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                        }
                        .padding(.horizontal)

                        // Legend
                        HStack {
                            Rectangle()
                                .fill(Color.accentGreen.opacity(0.6))
                                .frame(width: 20, height: 2)
                            Text("Goal: \(Int(goalOz))oz")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.accentGreen)
                                    .frame(width: 8, height: 8)
                                Text("Goal met")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.accentBlue)
                                    .frame(width: 8, height: 8)
                                Text("Below goal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        WaterStatCard(
                            icon: "arrow.up.circle.fill",
                            title: "Best Day",
                            value: "\(Int(maxValue))oz",
                            subtitle: "\(Int(maxValue / 8)) glasses",
                            color: .accentGreen
                        )

                        WaterStatCard(
                            icon: "arrow.down.circle.fill",
                            title: "Lowest Day",
                            value: "\(Int(minValue))oz",
                            subtitle: "\(Int(minValue / 8)) glasses",
                            color: .accentOrange
                        )

                        WaterStatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "This Week",
                            value: "\(Int(dailyData.suffix(7).reduce(0, +)))oz",
                            subtitle: "vs last: +12%",
                            color: .accentBlue
                        )

                        WaterStatCard(
                            icon: "flame.fill",
                            title: "Current Streak",
                            value: "\(currentStreak) days",
                            subtitle: currentStreak > 0 ? "Keep it up!" : "Start today!",
                            color: .accentRed
                        )
                    }
                    .padding(.horizontal)

                    // Quick tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hydration Tips")
                            .font(.headline)
                            .fontWeight(.bold)

                        VStack(spacing: 8) {
                            HydrationTipRow(icon: "sunrise.fill", tip: "Start your day with a glass of water", color: .accentYellow)
                            HydrationTipRow(icon: "fork.knife", tip: "Drink water before each meal", color: .accentGreen)
                            HydrationTipRow(icon: "figure.run", tip: "Extra hydration during workouts", color: .accentOrange)
                            HydrationTipRow(icon: "bell.fill", tip: "Set hourly reminders", color: .accentBlue)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentBlue)
                }
            }
            .overlay {
                // Water droplet rain animation overlay - full screen
                if !hasAnimated {
                    GeometryReader { geometry in
                        ZStack {
                            ForEach(0..<dropletCount, id: \.self) { index in
                                Image(systemName: "drop.fill")
                                    .font(.system(size: dropletSizes[index]))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color.accentBlue.opacity(0.9),
                                                Color.accentTeal.opacity(0.7)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.accentBlue.opacity(0.3), radius: 2, y: 2)
                                    .position(
                                        x: geometry.size.width / 2 + dropletXPositions[index],
                                        y: dropletYPositions[index]
                                    )
                                    .opacity(dropletOpacities[index])
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                if !hasAnimated {
                    startRainAnimation()
                }
            }
        }
    }

    // MARK: - Rain Animation
    private func startRainAnimation() {
        // Animate each droplet falling from top to bottom with staggered timing
        for index in 0..<dropletCount {
            let delay = dropletDelays[index]
            let fallDuration = Double.random(in: 1.2...1.8)
            let startY: CGFloat = -50
            let endY: CGFloat = UIScreen.main.bounds.height + 100

            // Start falling
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Fade in
                withAnimation(.easeOut(duration: 0.2)) {
                    dropletOpacities[index] = Double.random(in: 0.6...1.0)
                }

                // Fall down
                withAnimation(.easeIn(duration: fallDuration)) {
                    dropletYPositions[index] = endY
                }
            }

            // Fade out near bottom
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + fallDuration - 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    dropletOpacities[index] = 0
                }
            }
        }

        // Mark as animated after all droplets finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            hasAnimated = true
        }
    }
}

struct WaterStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct HydrationTipRow: View {
    let icon: String
    let tip: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(tip)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct WaterDetailStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
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
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Health Metric Detail View (30-Day Chart)
struct HealthMetricDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let metricType: HealthMetricType

    private let chartHeight: CGFloat = 200
    private var data: [Double] { metricType.sampleData }
    private var yRange: (min: Double, max: Double) { metricType.yAxisRange }

    private var average: Double {
        data.reduce(0, +) / Double(data.count)
    }

    private var maxVal: Double { data.max() ?? 0 }
    private var minVal: Double { data.min() ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current value hero
                    VStack(spacing: 8) {
                        Image(systemName: metricType.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(metricType.color)

                        Text(metricType.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(metricType.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // Stats row
                    HStack(spacing: 16) {
                        StatBox(label: "Average", value: formatValue(average), color: metricType.color)
                        StatBox(label: "High", value: formatValue(maxVal), color: .accentGreen)
                        StatBox(label: "Low", value: formatValue(minVal), color: .accentOrange)
                    }
                    .padding(.horizontal)

                    // 30-day chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last 30 Days")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        // Chart with Y-axis
                        HStack(alignment: .top, spacing: 8) {
                            // Y-axis labels
                            VStack {
                                Text(formatAxisValue(yRange.max))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatAxisValue((yRange.max + yRange.min) / 2))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatAxisValue(yRange.min))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 40, height: chartHeight)

                            // Chart
                            GeometryReader { geometry in
                                let width = geometry.size.width
                                let stepX = width / CGFloat(data.count - 1)

                                ZStack {
                                    // Grid lines
                                    VStack(spacing: 0) {
                                        ForEach(0..<5) { _ in
                                            Divider()
                                                .background(Color.gray.opacity(0.2))
                                            Spacer()
                                        }
                                    }

                                    // Gradient fill
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: chartHeight))
                                        for (index, value) in data.enumerated() {
                                            let x = CGFloat(index) * stepX
                                            let normalizedY = (value - yRange.min) / (yRange.max - yRange.min)
                                            let y = chartHeight - CGFloat(normalizedY) * chartHeight
                                            path.addLine(to: CGPoint(x: x, y: y))
                                        }
                                        path.addLine(to: CGPoint(x: width, y: chartHeight))
                                        path.closeSubpath()
                                    }
                                    .fill(
                                        LinearGradient(
                                            colors: [metricType.color.opacity(0.4), metricType.color.opacity(0.05)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                    // Line
                                    Path { path in
                                        for (index, value) in data.enumerated() {
                                            let x = CGFloat(index) * stepX
                                            let normalizedY = (value - yRange.min) / (yRange.max - yRange.min)
                                            let y = chartHeight - CGFloat(normalizedY) * chartHeight
                                            if index == 0 {
                                                path.move(to: CGPoint(x: x, y: y))
                                            } else {
                                                path.addLine(to: CGPoint(x: x, y: y))
                                            }
                                        }
                                    }
                                    .stroke(
                                        metricType.color,
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                                    )

                                    // Data points (every 5th day)
                                    ForEach(Array(stride(from: 0, to: data.count, by: 5)), id: \.self) { index in
                                        let x = CGFloat(index) * stepX
                                        let normalizedY = (data[index] - yRange.min) / (yRange.max - yRange.min)
                                        let y = chartHeight - CGFloat(normalizedY) * chartHeight

                                        Circle()
                                            .fill(metricType.color)
                                            .frame(width: 8, height: 8)
                                            .overlay(
                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 4, height: 4)
                                            )
                                            .position(x: x, y: y)
                                    }
                                }
                            }
                            .frame(height: chartHeight)
                        }
                        .padding(.horizontal)

                        // X-axis labels
                        HStack {
                            Spacer().frame(width: 48)
                            HStack {
                                Text("30d ago")
                                Spacer()
                                Text("15d ago")
                                Spacer()
                                Text("Today")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatValue(_ value: Double) -> String {
        switch metricType {
        case .steps:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: Int(value))) ?? "--"
        case .sleep:
            return String(format: "%.1f", value)
        default:
            return "\(Int(value))"
        }
    }

    private func formatAxisValue(_ value: Double) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value / 1000))k"
        case .sleep:
            return String(format: "%.0f", value)
        default:
            return "\(Int(value))"
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HealthView()
}
