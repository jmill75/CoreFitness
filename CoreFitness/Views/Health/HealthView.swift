import SwiftUI
import SwiftData

struct HealthView: View {

    // MARK: - Environment
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - State
    @State private var showWaterIntake = false
    @State private var showMoodDetail = false
    @State private var showDailyCheckIn = false
    @State private var isInitialLoad = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with + button
                    ViewHeader("Health", isLoading: healthKitManager.isLoading) {
                        Button {
                            showDailyCheckIn = true
                        } label: {
                            Label("Daily Check-in", systemImage: "heart.text.square")
                        }

                        Button {
                            showWaterIntake = true
                        } label: {
                            Label("Log Water", systemImage: "drop.fill")
                        }
                    }

                    if isInitialLoad && healthKitManager.isLoading {
                        // Show skeleton loading state
                        HealthViewSkeleton()
                    } else {
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
            .fullScreenCover(isPresented: $showDailyCheckIn) {
                DailyCheckInView()
                    .background(.ultraThinMaterial)
            }
            .task {
                // Refresh health data when view appears
                if healthKitManager.isAuthorized {
                    await healthKitManager.fetchTodayData()
                }
                isInitialLoad = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .dailyCheckInSaved)) { _ in
                // Refresh health data when check-in is saved
                Task {
                    if healthKitManager.isAuthorized {
                        await healthKitManager.fetchTodayData()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .healthDataUpdated)) { _ in
                // Refresh health data when health data is updated
                Task {
                    if healthKitManager.isAuthorized {
                        await healthKitManager.fetchTodayData()
                    }
                }
            }
        }
    }
}

// MARK: - Health View Skeleton Loading
struct HealthViewSkeleton: View {
    var body: some View {
        VStack(spacing: 20) {
            // Recovery Status Skeleton
            VStack(spacing: 16) {
                HStack {
                    SkeletonView(width: 100, height: 100)
                        .clipShape(Circle())
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        SkeletonView(width: 120, height: 24)
                        SkeletonView(width: 80, height: 16)
                    }
                }
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonView(height: 60)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Score Trend Skeleton
            VStack(alignment: .leading, spacing: 12) {
                SkeletonView(width: 140, height: 20)
                SkeletonView(height: 120)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Health Metrics Grid Skeleton
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonView(width: 44, height: 44)
                            .clipShape(Circle())
                        SkeletonView(width: 60, height: 24)
                        SkeletonView(width: 80, height: 14)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            // Water Intake Skeleton
            HStack {
                SkeletonView(width: 60, height: 60)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView(width: 100, height: 20)
                    SkeletonView(width: 140, height: 16)
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Score Trend Card (Line Graph)
struct ScoreTrendCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyHealthData: [DailyHealthData]

    private let chartHeight: CGFloat = 120

    // Calculate the dates for the past 7 days
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    // Get recovery scores for the past 7 days from real data
    private var values: [Double] {
        weekDates.map { date in
            let startOfDay = Calendar.current.startOfDay(for: date)

            // For today, always use HealthKitManager's live score
            if Calendar.current.isDateInToday(date) {
                return Double(healthKitManager.calculateOverallScore())
            }

            // For past days, check stored DailyHealthData
            if let data = dailyHealthData.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: startOfDay)
            }) {
                let score = data.recoveryScore ?? data.calculateOverallScore()
                // Only return if we have actual data (score > 0)
                if score > 0 {
                    return Double(score)
                }
            }

            return 0
        }
    }

    private var hasData: Bool {
        values.contains { $0 > 0 }
    }

    private var trendPercentage: Int {
        guard values.count >= 2 else { return 0 }
        let recent = values.suffix(3).reduce(0, +) / 3.0
        let earlier = values.prefix(3).reduce(0, +) / 3.0
        guard earlier > 0 else { return 0 }
        return Int(((recent - earlier) / earlier) * 100)
    }

    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Recovery Trend")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(dateRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if hasData {
                    HStack(spacing: 6) {
                        Image(systemName: trendPercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(trendPercentage >= 0 ? "+" : "")\(trendPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(trendPercentage >= 0 ? Color.accentGreen : Color.accentOrange)
                    .clipShape(Capsule())
                }
            }

            if hasData {
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
                        let validValues = values.filter { $0 > 0 }

                        ZStack {
                            // Grid lines
                            VStack(spacing: 0) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                    Spacer()
                                }
                            }

                            if !validValues.isEmpty {
                                let maxValue = validValues.max() ?? 0
                                let minValue = validValues.filter { $0 > 0 }.min() ?? 0
                                let maxIndex = values.firstIndex(of: maxValue)
                                let minIndex = values.lastIndex(where: { $0 == minValue && $0 > 0 })

                                // Gradient fill under line
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: chartHeight))
                                    for (index, value) in values.enumerated() {
                                        let x = CGFloat(index) * stepX
                                        let y = chartHeight - (CGFloat(max(value, 0)) / 100.0) * chartHeight
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
                                        let y = chartHeight - (CGFloat(max(value, 0)) / 100.0) * chartHeight
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

                                // Data points - only show dots, highlight min/max
                                ForEach(0..<values.count, id: \.self) { index in
                                    let x = CGFloat(index) * stepX
                                    let value = values[index]
                                    let y = chartHeight - (CGFloat(max(value, 0)) / 100.0) * chartHeight
                                    let isMax = index == maxIndex
                                    let isMin = index == minIndex && minIndex != maxIndex

                                    if value > 0 {
                                        // Show label only for max and min
                                        if isMax || isMin {
                                            VStack(spacing: 2) {
                                                HStack(spacing: 2) {
                                                    Image(systemName: isMax ? "arrow.up" : "arrow.down")
                                                        .font(.system(size: 8, weight: .bold))
                                                    Text("\(Int(value))")
                                                        .font(.system(size: 10, weight: .bold))
                                                }
                                                .foregroundStyle(isMax ? Color.accentGreen : Color.accentOrange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background((isMax ? Color.accentGreen : Color.accentOrange).opacity(0.15))
                                                .clipShape(Capsule())

                                                Circle()
                                                    .fill(isMax ? Color.accentGreen : Color.accentOrange)
                                                    .frame(width: 12, height: 12)
                                                    .overlay(
                                                        Circle()
                                                            .fill(.white)
                                                            .frame(width: 6, height: 6)
                                                    )
                                            }
                                            .position(x: x, y: y - 16)
                                        } else {
                                            // Regular data point (just dot, no label)
                                            Circle()
                                                .fill(Color.brandPrimary)
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
                            }
                        }
                    }
                    .frame(height: chartHeight)
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No recovery data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Complete daily check-ins to see your trends")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(height: chartHeight)
                .frame(maxWidth: .infinity)
            }

            // Day labels with dates (offset to align with chart)
            HStack(spacing: 8) {
                Spacer()
                    .frame(width: 28)

                HStack {
                    ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                        VStack(spacing: 2) {
                            Text(dayName(for: date))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(isToday(date) ? Color.brandPrimary : .secondary)
                            Text(dayNumber(for: date))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(isToday(date) ? .white : .primary)
                                .frame(width: 22, height: 22)
                                .background(isToday(date) ? Color.brandPrimary : Color.clear)
                                .clipShape(Circle())
                        }
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
    case calories = "Active Calories"
    case water = "Water"

    var icon: String {
        switch self {
        case .hrv: return "waveform.path.ecg"
        case .restingHR: return "heart.fill"
        case .sleep: return "moon.fill"
        case .steps: return "figure.walk"
        case .calories: return "flame.fill"
        case .water: return "drop.fill"
        }
    }

    var unit: String {
        switch self {
        case .hrv: return "ms"
        case .restingHR: return "bpm"
        case .sleep: return "hrs"
        case .steps: return ""
        case .calories: return "kcal"
        case .water: return "cups"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .hrv: return AppGradients.primary
        case .restingHR: return AppGradients.health
        case .sleep: return AppGradients.ocean
        case .steps: return AppGradients.energetic
        case .calories: return LinearGradient(colors: [Color(hex: "f97316"), Color(hex: "ea580c")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .water: return LinearGradient(colors: [Color(hex: "0ea5e9"), Color(hex: "0284c7")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var color: Color {
        switch self {
        case .hrv: return .brandPrimary
        case .restingHR: return .accentRed
        case .sleep: return .accentBlue
        case .steps: return .accentOrange
        case .calories: return Color(hex: "f97316")
        case .water: return Color(hex: "0ea5e9")
        }
    }

    var description: String {
        switch self {
        case .hrv: return "Heart Rate Variability measures the variation in time between heartbeats. Higher values generally indicate better recovery."
        case .restingHR: return "Your resting heart rate when you're calm and relaxed. Lower values typically indicate better cardiovascular fitness."
        case .sleep: return "Total hours of sleep recorded. Adults typically need 7-9 hours for optimal recovery."
        case .steps: return "Total steps taken throughout the day. 10,000 steps is a common daily goal."
        case .calories: return "Active calories burned through physical activity. This excludes your basal metabolic rate."
        case .water: return "Water intake tracked throughout the day. Aim for 8 cups (64 oz) daily for optimal hydration."
        }
    }

    var yAxisRange: (min: Double, max: Double) {
        switch self {
        case .hrv: return (20, 80)
        case .restingHR: return (50, 80)
        case .sleep: return (4, 10)
        case .steps: return (0, 15000)
        case .calories: return (0, 1000)
        case .water: return (0, 12)
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

    private var caloriesValue: String {
        guard let cals = healthKitManager.healthData.activeCalories else { return "--" }
        return "\(Int(cals))"
    }

    private var waterValue: String {
        guard let water = healthKitManager.healthData.waterIntake else { return "--" }
        return String(format: "%.1f", water / 8.0) // Convert oz to cups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentRed)

                Text("My Health Data")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 4)

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

                HealthMetricCard(
                    title: "Active Cal",
                    value: caloriesValue,
                    unit: "kcal",
                    trend: .neutral,
                    icon: "flame.fill",
                    gradient: LinearGradient(
                        colors: [Color(hex: "f97316"), Color(hex: "ea580c")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ) {
                    selectedMetric = .calories
                }

                HealthMetricCard(
                    title: "Water",
                    value: waterValue,
                    unit: "cups",
                    trend: .neutral,
                    icon: "drop.fill",
                    gradient: LinearGradient(
                        colors: [Color(hex: "0ea5e9"), Color(hex: "0284c7")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ) {
                    selectedMetric = .water
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

// MARK: - Water Drop Model
struct WaterDrop: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

// MARK: - Water Intake Card (Enhanced)
struct WaterIntakeCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showDetail: Bool
    @EnvironmentObject var waterManager: WaterIntakeManager
    @State private var showAddSheet = false
    @State private var animateProgress = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkRotation: Double = 0
    @State private var showCheckmark = false
    @State private var checkmarkBounce: CGFloat = 1.0
    @State private var waterDrops: [WaterDrop] = []

    var body: some View {
        ZStack {
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

                    Text("\(Int(waterManager.ringProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
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
                    // Delay animation to prevent navigation stutter
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.8)) {
                            animateProgress = true
                        }
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
                            // Show checkmark visually if goal already reached (no haptic on navigation)
                            if waterManager.hasReachedGoal {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    startCheckmarkAnimation(withHaptic: false)
                                    startContinuousBounce()
                                }
                            }
                        }
                        .onChange(of: waterManager.hasReachedGoal) { _, newValue in
                            if newValue {
                                // Play haptic only when goal is first reached today
                                let shouldCelebrate = waterManager.shouldCelebrateGoal
                                startCheckmarkAnimation(withHaptic: shouldCelebrate)
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
                            themeManager.mediumImpact()
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
                // View Details hint
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                        Text("View Details")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Water drops falling animation when goal reached
            if waterManager.hasReachedGoal {
                ForEach(waterDrops) { drop in
                    Image(systemName: "drop.fill")
                        .font(.system(size: drop.size))
                        .foregroundStyle(Color.accentBlue.opacity(drop.opacity))
                        .position(x: drop.x, y: drop.y)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
            themeManager.lightImpact()
        }
        .onChange(of: waterManager.hasReachedGoal) { _, reached in
            if reached {
                startWaterDropAnimation()
            }
        }
        .onAppear {
            // Delay water drop animation to prevent navigation stutter
            if waterManager.hasReachedGoal {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    startWaterDropAnimation()
                }
            }
        }
    }

    // MARK: - Water Drop Animation
    private func startWaterDropAnimation() {
        waterDrops = []

        // Create multiple water drops
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                let drop = WaterDrop(
                    x: CGFloat.random(in: 40...320),
                    y: -20,
                    size: CGFloat.random(in: 10...18),
                    opacity: Double.random(in: 0.4...0.8)
                )
                waterDrops.append(drop)

                // Animate the drop falling
                withAnimation(.easeIn(duration: Double.random(in: 0.8...1.2))) {
                    if let index = waterDrops.firstIndex(where: { $0.id == drop.id }) {
                        waterDrops[index].y = 250
                        waterDrops[index].opacity = 0
                    }
                }

                // Remove after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    waterDrops.removeAll { $0.id == drop.id }
                }
            }
        }
    }

    // MARK: - Checkmark Animation
    private func startCheckmarkAnimation(withHaptic: Bool = false) {
        // Reset
        checkmarkScale = 0
        checkmarkRotation = -45
        showCheckmark = false

        // Haptic feedback - only plays when goal is first reached, not on navigation
        if withHaptic {
            themeManager.notifySuccess()
            waterManager.markGoalCelebrated()
        }

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

    // MARK: - Continuous Bounce (Limited duration for performance)
    private func startContinuousBounce() {
        // Run subtle bounce animation for 3 seconds only, then stop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                checkmarkBounce = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    checkmarkBounce = 1.0
                }
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
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showDetail: Bool
    @Query private var moodEntries: [MoodEntry]
    @State private var bounceValues: [Int: Bool] = [:]
    @State private var hasStartedAnimation = false

    // Calculate the dates for the current week (Sun-Sat)
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1 = Sunday
        let daysFromSunday = weekday - 1
        guard let sunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: sunday) }
    }

    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }

    // Get mood entries for this week
    private func moodEntry(for date: Date) -> MoodEntry? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return moodEntries.first { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }
    }

    // Calculate mood summary counts from real data
    private var moodCounts: [Mood: Int] {
        var counts: [Mood: Int] = [:]
        for date in weekDates where !isFutureDate(date) {
            if let entry = moodEntry(for: date) {
                counts[entry.mood, default: 0] += 1
            }
        }
        return counts
    }

    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let day = formatter.string(from: date)
        switch day {
        case "Mon": return "M"
        case "Tue": return "Tu"
        case "Wed": return "W"
        case "Thu": return "Th"
        case "Fri": return "F"
        case "Sat": return "Sa"
        case "Sun": return "Su"
        default: return String(day.prefix(2))
        }
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func isFutureDate(_ date: Date) -> Bool {
        date > Date()
    }

    var body: some View {
        Button {
            showDetail = true
            themeManager.lightImpact()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "face.smiling.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentYellow)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mood This Week")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(dateRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Mood grid with animated emojis and dates
                HStack(spacing: 6) {
                    ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                        VStack(spacing: 4) {
                            Text(moodEmoji(for: date))
                                .font(.title3)
                                .scaleEffect(bounceValues[index] == true ? 1.2 : 1.0)
                                .rotationEffect(.degrees(bounceValues[index] == true ? -5 : 0))
                                .opacity(isFutureDate(date) ? 0.3 : 1.0)
                            Text(dayAbbreviation(for: date))
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .foregroundStyle(isToday(date) ? Color.accentYellow : .secondary)
                            Text(dayNumber(for: date))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(isToday(date) ? .white : .primary)
                                .frame(width: 20, height: 20)
                                .background(isToday(date) ? Color.accentYellow : Color.clear)
                                .clipShape(Circle())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(moodColor(for: date).opacity(isFutureDate(date) ? 0.1 : 0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onAppear {
                            // Delay staggered animations to prevent navigation stutter
                            if index == 0 && !hasStartedAnimation {
                                hasStartedAnimation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    for i in 0..<7 {
                                        if !isFutureDate(weekDates[safe: i] ?? Date()) {
                                            startBounceAnimation(for: i)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Mood summary from real data
                HStack(spacing: 12) {
                    MoodSummaryPill(emoji: "🤩", label: "Amazing", count: moodCounts[.amazing] ?? 0, color: .accentGreen)
                    MoodSummaryPill(emoji: "😊", label: "Good", count: moodCounts[.good] ?? 0, color: .accentBlue)
                    MoodSummaryPill(emoji: "😐", label: "Okay", count: moodCounts[.okay] ?? 0, color: .accentOrange)
                    MoodSummaryPill(emoji: "😴", label: "Tired", count: moodCounts[.tired] ?? 0, color: .accentTeal)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // Get mood emoji from real data
    private func moodEmoji(for date: Date) -> String {
        if isFutureDate(date) { return "○" }
        guard let entry = moodEntry(for: date) else { return "○" } // No data logged
        switch entry.mood {
        case .amazing: return "🤩"
        case .good: return "😊"
        case .okay: return "😐"
        case .tired: return "😴"
        case .stressed: return "😔"
        }
    }

    private func moodColor(for date: Date) -> Color {
        if isFutureDate(date) { return .gray }
        guard let entry = moodEntry(for: date) else { return .gray }
        switch entry.mood {
        case .amazing: return .accentGreen
        case .good: return .accentBlue
        case .okay: return .accentOrange
        case .tired: return .accentTeal
        case .stressed: return .accentRed
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
    @Query(sort: \MoodEntry.date, order: .reverse) private var allMoodEntries: [MoodEntry]
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

    // Calendar day data structure
    struct CalendarDay: Identifiable {
        let id: String
        let date: Date
        let dayOfMonth: Int
        let moodIndex: Int?  // nil if no mood entry
        let isToday: Bool
    }

    // Get calendar data with proper date alignment
    private var calendarData: (days: [CalendarDay], leadingEmptyCells: Int, monthLabel: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get date 29 days ago (30 days including today)
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else {
            return ([], 0, "")
        }

        // Create a dictionary of date -> mood entry for quick lookup
        var moodByDate: [Date: MoodEntry] = [:]
        for entry in allMoodEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            moodByDate[dayStart] = entry
        }

        // Calculate leading empty cells based on weekday of start date
        // weekday: 1 = Sunday, 2 = Monday, etc.
        let startWeekday = calendar.component(.weekday, from: startDate)
        let leadingEmptyCells = startWeekday - 1  // Sunday = 0 empty cells

        // Build array for last 30 days
        var days: [CalendarDay] = []
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let dayOfMonth = calendar.component(.day, from: date)
            let isToday = calendar.isDateInToday(date)

            var moodIndex: Int? = nil
            if let entry = moodByDate[calendar.startOfDay(for: date)] {
                moodIndex = moodToIndex(entry.mood)
            }

            days.append(CalendarDay(
                id: "day-\(dayOffset)",
                date: date,
                dayOfMonth: dayOfMonth,
                moodIndex: moodIndex,
                isToday: isToday
            ))
        }

        // Create month label (e.g., "Nov 26 - Dec 25")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let monthLabel = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: today))"

        return (days, leadingEmptyCells, monthLabel)
    }

    // For mood breakdown stats - only count days WITH actual mood entries
    private var moodCounts: [Int] {
        var counts = Array(repeating: 0, count: moodTypes.count)
        for day in calendarData.days {
            if let moodIndex = day.moodIndex {
                counts[moodIndex] += 1
            }
        }
        return counts
    }

    private var totalMoodEntries: Int {
        calendarData.days.compactMap { $0.moodIndex }.count
    }

    private var dominantMood: Int {
        moodCounts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 2
    }

    // Convert Mood enum to display index
    private func moodToIndex(_ mood: Mood) -> Int {
        switch mood {
        case .amazing: return 0  // Great
        case .good: return 1     // Good
        case .okay: return 2     // Okay
        case .tired: return 4    // Tired
        case .stressed: return 3 // Low
        }
    }

    // Check if we have any actual mood entries in the last 30 days
    private var hasActualMoodData: Bool {
        totalMoodEntries > 0
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
                                total: max(totalMoodEntries, 1),  // Avoid division by zero
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
                        HStack {
                            Text("Last 30 Days")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            // Date range label
                            Text(calendarData.monthLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Calendar grid with proper date alignment
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                            // Day labels
                            ForEach(Array(["Su", "M", "Tu", "W", "Th", "F", "Sa"].enumerated()), id: \.offset) { index, day in
                                Text(day)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .frame(height: 20)
                                    .id("header-\(index)")
                            }

                            // Leading empty cells based on weekday of first day
                            ForEach(0..<calendarData.leadingEmptyCells, id: \.self) { index in
                                Color.clear
                                    .frame(height: 44)
                                    .id("empty-\(index)")
                            }

                            // Mood cells with actual dates
                            ForEach(Array(calendarData.days.enumerated()), id: \.element.id) { index, day in
                                VStack(spacing: 2) {
                                    if let moodIndex = day.moodIndex {
                                        // Has mood entry - show emoji
                                        Text(moodTypes[moodIndex].emoji)
                                            .font(.title3)
                                            .scaleEffect(shimmerValues[index] == true ? 1.3 : 1.0)
                                            .rotationEffect(.degrees(shimmerValues[index] == true ? -8 : 0))
                                    } else {
                                        // No mood entry - show dash
                                        Text("—")
                                            .font(.title3)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Text("\(day.dayOfMonth)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(day.isToday ? .primary : .secondary)
                                        .fontWeight(day.isToday ? .bold : .regular)
                                }
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Group {
                                        if let moodIndex = day.moodIndex {
                                            moodTypes[moodIndex].color.opacity(shimmerValues[index] == true ? 0.3 : 0.15)
                                        } else {
                                            Color(.tertiarySystemFill)
                                        }
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(day.isToday ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
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

                        // Legend
                        if !hasActualMoodData {
                            Text("Log your mood daily to see your patterns")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
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

        // Start pulsing animation (limited to ~3 cycles then settle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.5).repeatCount(3, autoreverses: true)) {
                emojiScale = 1.15
                glowOpacity = 0.8
            }

            withAnimation(.easeInOut(duration: 2.0).repeatCount(3, autoreverses: true)) {
                emojiRotation = 8
            }

            // Settle back to normal after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    emojiScale = 1.0
                    emojiRotation = 0
                    glowOpacity = 0.5
                }
            }
        }
    }

    // MARK: - Random Shimmer Animation for 30-Day Grid
    private func startRandomShimmer() {
        // Pick 2-3 random emojis to shimmer
        let count = Int.random(in: 2...3)
        let daysCount = calendarData.days.count
        guard daysCount > 0 else { return }
        let indices = (0..<daysCount).shuffled().prefix(count)

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

// MARK: - Recovery Status Card (Large Hero Card - Same as Home)
struct RecoveryStatusCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    private let ringStart = Color(hex: "60a5fa")
    private let ringEnd = Color(hex: "3b82f6")
    private let bgStart = Color(hex: "1e40af")
    private let bgEnd = Color(hex: "1e3a8a")

    private var score: Int {
        healthKitManager.calculateOverallScore()
    }

    private var scoreMessage: String {
        if !healthKitManager.isAuthorized { return "Connect Health" }
        switch score {
        case 80...100: return "Crushing it!"
        case 60..<80: return "Good recovery"
        case 40..<60: return "Take it easy"
        default: return "Rest day"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Top row: Score Ring + Info
            HStack(spacing: 16) {
                // Large Score Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 10)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: healthKitManager.isAuthorized ? CGFloat(score) / 100.0 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [ringStart, ringEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(healthKitManager.isAuthorized ? "\(score)" : "--")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("score")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Recovery")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(scoreMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()
            }

            // Bottom row: Stats
            HStack(spacing: 0) {
                HealthRecoveryStat(icon: "moon.fill", label: "Sleep", value: sleepValue, color: Color(hex: "fcd34d"))

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.2))

                HealthRecoveryStat(icon: "waveform.path.ecg", label: "HRV", value: hrvValue, color: Color(hex: "a78bfa"))

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.2))

                HealthRecoveryStat(icon: "heart.fill", label: "Resting HR", value: hrValue, color: Color(hex: "ef4444"))
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
        .shadow(color: bgStart.opacity(0.3), radius: 12, y: 6)
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1fh", hours)
    }

    private var hrvValue: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        return "\(Int(hrv)) ms"
    }

    private var hrValue: String {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return "--" }
        return "\(Int(hr)) bpm"
    }
}

struct HealthRecoveryStat: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Water Intake Detail View
struct WaterIntakeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var waterManager: WaterIntakeManager

    // Water droplet animation state - 25 droplets for full screen rain
    private let dropletCount = 25
    @State private var dropletYPositions: [CGFloat] = Array(repeating: -100, count: 25)
    @State private var dropletOpacities: [Double] = Array(repeating: 0, count: 25)
    @State private var hasAnimated = false
    @State private var dailyData: [Double] = []
    @State private var isLoadingData = true

    // Pre-computed random values for each droplet
    private let dropletXPositions: [CGFloat] = (0..<25).map { _ in CGFloat.random(in: -180...180) }
    private let dropletSizes: [CGFloat] = (0..<25).map { _ in CGFloat.random(in: 16...32) }
    private let dropletDelays: [Double] = (0..<25).map { _ in Double.random(in: 0...0.8) }

    private let chartHeight: CGFloat = 200

    // Use goal from water manager
    private var goalOz: Double {
        waterManager.goalOunces
    }

    private var averageOz: Double {
        guard !dailyData.isEmpty else { return 0 }
        return dailyData.reduce(0, +) / Double(dailyData.count)
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

    // Check if we have any actual water data
    private var hasWaterData: Bool {
        dailyData.contains { $0 > 0 }
    }

    // Calculate week-over-week change
    private var weekOverWeekChange: Int? {
        guard dailyData.count >= 14 else { return nil }
        let thisWeek = dailyData.suffix(7).reduce(0, +)
        let lastWeek = dailyData.dropLast(7).suffix(7).reduce(0, +)
        guard lastWeek > 0 else { return nil }
        return Int(((thisWeek - lastWeek) / lastWeek) * 100)
    }

    private var weekOverWeekChangeLabel: String {
        guard let change = weekOverWeekChange else {
            return "vs last week"
        }
        let sign = change >= 0 ? "+" : ""
        return "vs last: \(sign)\(change)%"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if hasWaterData {
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
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.accentBlue.opacity(0.5))

                            Text("No Water Data Yet")
                                .font(.headline)
                                .fontWeight(.bold)

                            Text("Start logging your water intake to see your hydration trends and statistics here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    }

                    // 30-day bar chart - only show if we have data
                    if hasWaterData {
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
                                subtitle: weekOverWeekChangeLabel,
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
                    } // End of hasWaterData check

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
            .task {
                // Load actual water intake history from WaterIntakeManager
                isLoadingData = true
                dailyData = await waterManager.getLast30DaysDataAsync()
                isLoadingData = false
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

// MARK: - Time Period for Charts
enum TimePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }

    var dataPoints: Int {
        switch self {
        case .day: return 24      // Hourly for day
        case .week: return 7      // Daily for week
        case .month: return 30    // Daily for month
        case .year: return 12     // Monthly for year
        }
    }

    var chartTitle: String {
        switch self {
        case .day: return "Today"
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .year: return "Last 12 Months"
        }
    }

    var xAxisLabels: (start: String, middle: String, end: String) {
        switch self {
        case .day: return ("12am", "12pm", "Now")
        case .week: return ("7d ago", "3d ago", "Today")
        case .month: return ("30d ago", "15d ago", "Today")
        case .year: return ("12m ago", "6m ago", "Now")
        }
    }
}

// MARK: - Health Metric Detail View
struct HealthMetricDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    let metricType: HealthMetricType

    @State private var historicalData: [Double] = []
    @State private var isLoading = true
    @State private var selectedPeriod: TimePeriod = .month

    private let chartHeight: CGFloat = 200
    private var data: [Double] {
        historicalData.isEmpty ? Array(repeating: 0, count: selectedPeriod.dataPoints) : historicalData
    }
    private var yRange: (min: Double, max: Double) { metricType.yAxisRange }
    private var hasData: Bool { historicalData.contains { $0 > 0 } }

    private var average: Double {
        let validData = data.filter { $0 > 0 }
        guard !validData.isEmpty else { return 0 }
        return validData.reduce(0, +) / Double(validData.count)
    }

    private var maxVal: Double { data.filter { $0 > 0 }.max() ?? 0 }
    private var minVal: Double { data.filter { $0 > 0 }.min() ?? 0 }

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

                    // Time period picker
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _, _ in
                        Task {
                            await loadHistoricalData()
                        }
                    }

                    // Chart section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(selectedPeriod.chartTitle)
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

                                    // Min/Max indicators
                                    let validValues = data.filter { $0 > 0 }
                                    let maxValue = validValues.max() ?? 0
                                    let minValue = validValues.min() ?? maxValue
                                    let maxIndex = data.firstIndex(of: maxValue)
                                    let minIndex = data.lastIndex(where: { $0 == minValue && $0 > 0 })

                                    // Max point indicator
                                    if let maxIdx = maxIndex, maxValue > 0 {
                                        let x = CGFloat(maxIdx) * stepX
                                        let normalizedY = (data[maxIdx] - yRange.min) / (yRange.max - yRange.min)
                                        let y = chartHeight - CGFloat(normalizedY) * chartHeight

                                        VStack(spacing: 4) {
                                            HStack(spacing: 2) {
                                                Image(systemName: "arrow.up")
                                                    .font(.system(size: 9, weight: .bold))
                                                Text(formatValue(maxValue))
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.accentGreen)
                                            .clipShape(Capsule())

                                            Circle()
                                                .fill(Color.accentGreen)
                                                .frame(width: 10, height: 10)
                                                .overlay(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 5, height: 5)
                                                )
                                        }
                                        .position(x: x, y: max(35, y - 10))
                                    }

                                    // Min point indicator (only if different from max)
                                    if let minIdx = minIndex, minIdx != maxIndex, minValue > 0 {
                                        let x = CGFloat(minIdx) * stepX
                                        let normalizedY = (data[minIdx] - yRange.min) / (yRange.max - yRange.min)
                                        let y = chartHeight - CGFloat(normalizedY) * chartHeight

                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(Color.accentOrange)
                                                .frame(width: 10, height: 10)
                                                .overlay(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 5, height: 5)
                                                )

                                            HStack(spacing: 2) {
                                                Image(systemName: "arrow.down")
                                                    .font(.system(size: 9, weight: .bold))
                                                Text(formatValue(minValue))
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.accentOrange)
                                            .clipShape(Capsule())
                                        }
                                        .position(x: x, y: min(chartHeight - 35, y + 10))
                                    }

                                    // Latest point indicator (today)
                                    if data.count > 0, let lastValue = data.last, lastValue > 0 {
                                        let lastIdx = data.count - 1
                                        if lastIdx != maxIndex && lastIdx != minIndex {
                                            let x = CGFloat(lastIdx) * stepX
                                            let normalizedY = (lastValue - yRange.min) / (yRange.max - yRange.min)
                                            let y = chartHeight - CGFloat(normalizedY) * chartHeight

                                            Circle()
                                                .fill(metricType.color)
                                                .frame(width: 10, height: 10)
                                                .overlay(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 5, height: 5)
                                                )
                                                .position(x: x, y: y)
                                        }
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
                                Text(selectedPeriod.xAxisLabels.start)
                                Spacer()
                                Text(selectedPeriod.xAxisLabels.middle)
                                Spacer()
                                Text(selectedPeriod.xAxisLabels.end)
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
            .overlay {
                if isLoading {
                    ProgressView("Loading data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .task {
                await loadHistoricalData()
            }
        }
    }

    private func loadHistoricalData() async {
        isLoading = true
        let days = selectedPeriod.days
        switch metricType {
        case .hrv:
            historicalData = await healthKitManager.getHRVHistory(days: days)
        case .restingHR:
            historicalData = await healthKitManager.getRestingHRHistory(days: days)
        case .sleep:
            historicalData = await healthKitManager.getSleepHistory(days: days)
        case .steps:
            historicalData = await healthKitManager.getStepsHistory(days: days)
        case .calories:
            historicalData = await healthKitManager.getCaloriesHistory(days: days)
        case .water:
            historicalData = await healthKitManager.getWaterHistory(days: days)
        }
        isLoading = false
    }

    private func formatValue(_ value: Double) -> String {
        switch metricType {
        case .steps, .calories:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: Int(value))) ?? "--"
        case .sleep, .water:
            return String(format: "%.1f", value)
        default:
            return "\(Int(value))"
        }
    }

    private func formatAxisValue(_ value: Double) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value / 1000))k"
        case .calories:
            return "\(Int(value))"
        case .sleep, .water:
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

// MARK: - Safe Array Subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    HealthView()
}
