import SwiftUI

struct HealthView: View {

    // MARK: - Environment
    @EnvironmentObject var healthKitManager: HealthKitManager

    // MARK: - State
    @State private var showWaterIntake = false
    @State private var showMoodDetail = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        // Recovery Status - Hero Card
                        RecoveryStatusCard()
                            .id("top")

                        // Score Trend - Compact
                        ScoreTrendCard()

                        // Health Metrics Grid
                        HealthMetricsSection()

                        // Water Intake
                        WaterIntakeCard(showDetail: $showWaterIntake)

                        // Mood Tracker
                        MoodTrackerCard(showDetail: $showMoodDetail)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentRed)
                        Text("Health")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showWaterIntake) {
                WaterIntakeDetailView()
                    .presentationBackground(.regularMaterial)
            }
            .sheet(isPresented: $showMoodDetail) {
                MoodDetailView()
                    .presentationBackground(.regularMaterial)
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

// MARK: - Water Intake Card (Improved)
struct WaterIntakeCard: View {

    @Binding var showDetail: Bool
    @State private var glasses: Int = 5
    private let goal: Int = 8

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

                Spacer()

                Text("\(Int(Double(glasses) / Double(goal) * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(glasses >= goal ? Color.accentGreen : Color.accentBlue)
                    .clipShape(Capsule())
            }

            // Large counter with +/- buttons
            HStack(spacing: 24) {
                // Minus button
                Button {
                    if glasses > 0 {
                        glasses -= 1
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(glasses > 0 ? Color.accentBlue : .gray)
                        .frame(width: 60, height: 60)
                        .background(Color.accentBlue.opacity(0.15))
                        .clipShape(Circle())
                }
                .disabled(glasses <= 0)

                // Glass count display
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(glasses)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accentBlue)
                        Text("/ \(goal)")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    Text("glasses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Plus button
                Button {
                    if glasses < goal {
                        glasses += 1
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(glasses < goal ? Color.accentBlue : Color.accentGreen)
                        .clipShape(Circle())
                }
            }

            // Visual progress drops
            HStack(spacing: 6) {
                ForEach(0..<goal, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            glasses = index + 1
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: index < glasses ? "drop.fill" : "drop")
                            .font(.title2)
                            .foregroundStyle(index < glasses ? Color.accentBlue : .gray.opacity(0.3))
                            .frame(width: 36, height: 44)
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentBlue.opacity(0.15))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBlue, glasses >= goal ? Color.accentGreen : Color.accentBlue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(glasses) / CGFloat(goal), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Mood Tracker Card
struct MoodTrackerCard: View {

    @Binding var showDetail: Bool

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

                // Mood grid
                HStack(spacing: 0) {
                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                        VStack(spacing: 8) {
                            Text(moodEmoji(for: day))
                                .font(.title2)
                            Text(day.prefix(1))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(day == "Sun" ? Color.accentYellow.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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

// MARK: - Mood Detail View (30 Days)
struct MoodDetailView: View {
    @Environment(\.dismiss) private var dismiss

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
                    // Summary header
                    VStack(spacing: 12) {
                        Text(moodTypes[dominantMood].emoji)
                            .font(.system(size: 60))

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
                            // Day labels
                            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                                Text(day)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .frame(height: 20)
                            }

                            // Empty cells for alignment (assuming we start mid-week)
                            ForEach(0..<2, id: \.self) { _ in
                                Color.clear
                                    .frame(height: 44)
                            }

                            // Mood cells
                            ForEach(0..<dailyMoods.count, id: \.self) { index in
                                VStack(spacing: 2) {
                                    Text(moodTypes[dailyMoods[index]].emoji)
                                        .font(.title3)
                                    Text("\(index + 1)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(moodTypes[dailyMoods[index]].color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Weekly pattern
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weekly Pattern")
                            .font(.headline)
                            .fontWeight(.bold)

                        HStack(spacing: 0) {
                            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                                VStack(spacing: 8) {
                                    Text(averageMoodEmoji(for: day))
                                        .font(.title2)
                                    Text(day.prefix(1))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mood Tracker")
            .navigationBarTitleDisplayMode(.inline)
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

    private func averageMoodEmoji(for day: String) -> String {
        // Return typical mood for each day based on sample data
        switch day {
        case "Sun": return "😴"
        case "Mon": return "😊"
        case "Tue": return "😄"
        case "Wed": return "😐"
        case "Thu": return "😊"
        case "Fri": return "😄"
        case "Sat": return "😄"
        default: return "😐"
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
                // Large Score Ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 12)
                        .frame(width: 110, height: 110)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: healthKitManager.isAuthorized ? CGFloat(score) / 100.0 : 0)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))

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

            // Recovery factors row
            HStack(spacing: 12) {
                RecoveryFactorPillHealth(
                    icon: "moon.fill",
                    label: "Sleep",
                    value: sleepStatus
                )
                RecoveryFactorPillHealth(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: hrvStatus
                )
                RecoveryFactorPillHealth(
                    icon: "heart.fill",
                    label: "HR",
                    value: hrStatus
                )
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppGradients.scoreGradient(for: score))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: scoreColor.opacity(0.3), radius: 12, y: 6)
    }
}

struct RecoveryFactorPillHealth: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Water Intake Detail View
struct WaterIntakeDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let chartHeight: CGFloat = 180
    private let goal: Int = 8

    // Sample 30-day water intake data (glasses per day)
    private let dailyData: [Int] = [
        6, 7, 5, 8, 7, 6, 8, 5, 7, 6,
        8, 7, 6, 5, 7, 8, 6, 7, 5, 8,
        7, 6, 8, 7, 5, 6, 8, 7, 6, 5
    ]

    private var average: Double {
        Double(dailyData.reduce(0, +)) / Double(dailyData.count)
    }

    private var daysMetGoal: Int {
        dailyData.filter { $0 >= goal }.count
    }

    private var maxValue: Int {
        dailyData.max() ?? 10
    }

    private var minValue: Int {
        dailyData.min() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header stats
                    HStack(spacing: 12) {
                        WaterDetailStatBox(
                            icon: "drop.fill",
                            value: String(format: "%.1f", average),
                            label: "Daily Avg",
                            color: .accentBlue
                        )
                        WaterDetailStatBox(
                            icon: "checkmark.circle.fill",
                            value: "\(daysMetGoal)",
                            label: "Goals Met",
                            color: .accentGreen
                        )
                        WaterDetailStatBox(
                            icon: "target",
                            value: "\(goal)",
                            label: "Daily Goal",
                            color: .accentOrange
                        )
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
                                Text("10")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("8")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("5")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("0")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 24, height: chartHeight)

                            // Chart
                            GeometryReader { geometry in
                                let width = geometry.size.width
                                let stepX = width / CGFloat(dailyData.count - 1)

                                ZStack {
                                    // Goal line
                                    Path { path in
                                        let goalY = chartHeight - (CGFloat(goal) / 10.0) * chartHeight
                                        path.move(to: CGPoint(x: 0, y: goalY))
                                        path.addLine(to: CGPoint(x: width, y: goalY))
                                    }
                                    .stroke(Color.accentGreen.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))

                                    // Grid lines
                                    VStack(spacing: 0) {
                                        ForEach(0..<4, id: \.self) { _ in
                                            Divider()
                                                .background(Color.gray.opacity(0.2))
                                            Spacer()
                                        }
                                    }

                                    // Gradient fill
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: chartHeight))
                                        for (index, value) in dailyData.enumerated() {
                                            let x = CGFloat(index) * stepX
                                            let y = chartHeight - (CGFloat(value) / 10.0) * chartHeight
                                            path.addLine(to: CGPoint(x: x, y: y))
                                        }
                                        path.addLine(to: CGPoint(x: width, y: chartHeight))
                                        path.closeSubpath()
                                    }
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentBlue.opacity(0.4), Color.accentBlue.opacity(0.05)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                    // Line
                                    Path { path in
                                        for (index, value) in dailyData.enumerated() {
                                            let x = CGFloat(index) * stepX
                                            let y = chartHeight - (CGFloat(value) / 10.0) * chartHeight
                                            if index == 0 {
                                                path.move(to: CGPoint(x: x, y: y))
                                            } else {
                                                path.addLine(to: CGPoint(x: x, y: y))
                                            }
                                        }
                                    }
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.accentBlue, Color.accentBlue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                    )

                                    // Data points
                                    ForEach(0..<dailyData.count, id: \.self) { index in
                                        let x = CGFloat(index) * stepX
                                        let y = chartHeight - (CGFloat(dailyData[index]) / 10.0) * chartHeight

                                        Circle()
                                            .fill(dailyData[index] >= goal ? Color.accentGreen : Color.accentBlue)
                                            .frame(width: 6, height: 6)
                                            .position(x: x, y: y)
                                    }
                                }
                            }
                            .frame(height: chartHeight)
                            .padding(.trailing, 8)
                        }
                        .padding(.horizontal)

                        // Legend
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.accentGreen)
                                    .frame(width: 8, height: 8)
                                Text("Goal met")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(Color.accentGreen.opacity(0.5))
                                    .frame(width: 16, height: 2)
                                Text("Goal line (8 glasses)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Stats summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Summary")
                            .font(.headline)
                            .fontWeight(.bold)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Best Day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(maxValue) glasses")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Divider()
                                .frame(height: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lowest Day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(minValue) glasses")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Divider()
                                .frame(height: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Success Rate")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(Double(daysMetGoal) / Double(dailyData.count) * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.accentGreen)
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
            .navigationTitle("Water Intake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentBlue)
                }
            }
        }
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
            .navigationTitle(metricType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
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
