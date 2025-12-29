import SwiftUI
import SwiftData

struct HealthView: View {

    // MARK: - Environment
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var waterManager: WaterIntakeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Bindings
    @Binding var selectedTab: Tab

    // MARK: - State
    @State private var showWaterIntake = false
    @State private var showMoodDetail = false
    @State private var showDailyCheckIn = false
    @State private var isInitialLoad = true
    @State private var animationStage = 0
    @State private var selectedMetric: HealthMetricType?
    @State private var healthAlerts: [HealthAlert] = []

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HealthPageHeader(
                            onCheckIn: { showDailyCheckIn = true },
                            onLogWater: { showWaterIntake = true }
                        )
                        .id("top")
                        .padding(.horizontal)
                        .opacity(animationStage >= 1 ? 1 : 0)
                        .offset(y: reduceMotion ? 0 : (animationStage >= 1 ? 0 : 10))

                        if isInitialLoad && healthKitManager.isLoading {
                            HealthViewSkeleton()
                                .padding(.horizontal)
                        } else {
                            // Recovery Hero Card
                            RecoveryHeroCard()
                                .padding(.horizontal)
                                .padding(.top, 20)
                                .opacity(animationStage >= 2 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 2 ? 0 : 15))

                            // Health Alerts (if any)
                            if !healthAlerts.isEmpty {
                                HealthAlertsSection(alerts: healthAlerts)
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                    .opacity(animationStage >= 3 ? 1 : 0)
                                    .offset(y: reduceMotion ? 0 : (animationStage >= 3 ? 0 : 15))
                            }

                            // My Health Metrics Grid
                            MyHealthMetricsSection(selectedMetric: $selectedMetric)
                                .padding(.horizontal)
                                .padding(.top, 24)
                                .opacity(animationStage >= 4 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 4 ? 0 : 15))

                            // Lifestyle Section (Water + Mood)
                            LifestyleCardsSection(
                                showWaterDetail: $showWaterIntake,
                                showMoodDetail: $showMoodDetail
                            )
                            .padding(.horizontal)
                            .padding(.top, 24)
                            .opacity(animationStage >= 5 ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (animationStage >= 5 ? 0 : 15))

                            // Weekly Recovery Trend
                            WeeklyRecoveryTrendSection()
                                .padding(.horizontal)
                                .padding(.top, 24)
                                .padding(.bottom, 100)
                                .opacity(animationStage >= 6 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 6 ? 0 : 15))
                        }
                    }
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
                .background(Color.black.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .onAppear {
                    if reduceMotion {
                        animationStage = 6
                    } else {
                        for stage in 1...6 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stage) * 0.05) {
                                animationStage = stage
                            }
                        }
                    }
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .health {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showWaterIntake) {
                QuickWaterIntakeView()
            }
            .fullScreenCover(isPresented: $showMoodDetail) {
                MoodDetailView()
                    .background(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $showDailyCheckIn) {
                DailyCheckInView()
                    .background(.ultraThinMaterial)
            }
            .sheet(item: $selectedMetric) { metric in
                HealthMetricDetailView(metricType: metric)
            }
            .task {
                if healthKitManager.isAuthorized {
                    await healthKitManager.fetchTodayData()
                    await generateHealthAlerts()
                }
                isInitialLoad = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .dailyCheckInSaved)) { _ in
                Task {
                    if healthKitManager.isAuthorized {
                        await healthKitManager.fetchTodayData()
                        await generateHealthAlerts()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .healthDataUpdated)) { _ in
                Task {
                    if healthKitManager.isAuthorized {
                        await healthKitManager.fetchTodayData()
                        await generateHealthAlerts()
                    }
                }
            }
        }
    }

    // MARK: - Generate Health Alerts
    private func generateHealthAlerts() async {
        var alerts: [HealthAlert] = []

        // Check HRV trend
        let hrvHistory = await healthKitManager.getHRVHistory(days: 7)
        if hrvHistory.count >= 3 {
            let recent = hrvHistory.suffix(3).filter { $0 > 0 }
            let earlier = hrvHistory.prefix(3).filter { $0 > 0 }
            if !recent.isEmpty && !earlier.isEmpty {
                let recentAvg = recent.reduce(0, +) / Double(recent.count)
                let earlierAvg = earlier.reduce(0, +) / Double(earlier.count)
                let change = ((recentAvg - earlierAvg) / earlierAvg) * 100
                if change < -15 {
                    alerts.append(HealthAlert(
                        type: .warning,
                        title: "HRV Declining",
                        message: "Your HRV is down \(Int(abs(change)))% this week. Consider extra rest.",
                        metric: .hrv
                    ))
                } else if change > 15 {
                    alerts.append(HealthAlert(
                        type: .positive,
                        title: "HRV Improving",
                        message: "Your HRV is up \(Int(change))% this week. Great recovery!",
                        metric: .hrv
                    ))
                }
            }
        }

        // Check resting HR
        if let hr = healthKitManager.healthData.restingHeartRate {
            if hr > 80 {
                alerts.append(HealthAlert(
                    type: .warning,
                    title: "Elevated Resting HR",
                    message: "Your resting heart rate is \(Int(hr)) bpm. Consider rest or stress reduction.",
                    metric: .restingHR
                ))
            }
        }

        // Check sleep
        if let sleep = healthKitManager.healthData.sleepHours {
            if sleep < 6 {
                alerts.append(HealthAlert(
                    type: .warning,
                    title: "Low Sleep",
                    message: "You only got \(String(format: "%.1f", sleep)) hours of sleep. Aim for 7-9 hours.",
                    metric: .sleep
                ))
            } else if sleep >= 8 {
                alerts.append(HealthAlert(
                    type: .positive,
                    title: "Great Sleep",
                    message: "You got \(String(format: "%.1f", sleep)) hours of quality sleep!",
                    metric: .sleep
                ))
            }
        }

        healthAlerts = alerts
    }
}

// MARK: - Health Alert Model
struct HealthAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let title: String
    let message: String
    let metric: HealthMetricType

    enum AlertType {
        case positive, warning, info

        var color: Color {
            switch self {
            case .positive: return Color(hex: "22c55e")
            case .warning: return Color(hex: "f59e0b")
            case .info: return Color(hex: "5AC8FA")
            }
        }

        var icon: String {
            switch self {
            case .positive: return "arrow.up.right.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}

// MARK: - Health Page Header
private struct HealthPageHeader: View {
    let onCheckIn: () -> Void
    let onLogWater: () -> Void

    private let tealColor = Color(hex: "00d2d3")
    private let cyanColor = Color(hex: "54a0ff")

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HEALTH")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, tealColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Your wellness dashboard")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onLogWater) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: [cyanColor, Color(hex: "2e86de")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }

                Button(action: onCheckIn) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1dd1a1"), Color(hex: "10ac84")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Recovery Hero Card
private struct RecoveryHeroCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var animateRing = false

    private let cardBg = Color(hex: "161616")
    private let tealStart = Color(hex: "00d2d3")
    private let tealEnd = Color(hex: "0097a7")

    private var score: Int {
        healthKitManager.calculateOverallScore()
    }

    private var scoreColor: Color {
        tealStart
    }

    private var scoreMessage: String {
        if !healthKitManager.isAuthorized { return "Connect Health" }
        switch score {
        case 85...100: return "Peak Performance"
        case 70..<85: return "Well Recovered"
        case 55..<70: return "Moderate Recovery"
        case 40..<55: return "Light Activity Day"
        default: return "Rest & Recover"
        }
    }

    private var scoreSubtext: String {
        if !healthKitManager.isAuthorized { return "Tap to connect Apple Health" }
        switch score {
        case 80...100: return "You're ready for intense training"
        case 60..<80: return "Good for moderate exercise"
        case 40..<60: return "Consider lighter activities"
        default: return "Focus on rest and recovery"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                // Score Ring
                ZStack {
                    // Glow
                    Circle()
                        .fill(tealStart.opacity(0.25))
                        .frame(width: 115, height: 115)
                        .blur(radius: 15)

                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: animateRing ? CGFloat(score) / 100.0 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [tealStart, tealEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(healthKitManager.isAuthorized ? "\(score)" : "--")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("SCORE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(1.5)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Recovery")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(tealStart)

                    Text(scoreMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(scoreSubtext)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                }

                Spacer()
            }

            // Recovery Factors
            HStack(spacing: 0) {
                RecoveryFactorPill(
                    icon: "moon.fill",
                    value: sleepValue,
                    label: "Sleep",
                    color: Color(hex: "54a0ff"),
                    status: sleepStatus
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.1))

                RecoveryFactorPill(
                    icon: "waveform.path.ecg",
                    value: hrvValue,
                    label: "HRV",
                    color: Color(hex: "1dd1a1"),
                    status: hrvStatus
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.1))

                RecoveryFactorPill(
                    icon: "heart.fill",
                    value: hrValue,
                    label: "Rest HR",
                    color: Color(hex: "ff6b6b"),
                    status: hrStatus
                )
            }
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            VStack {
                LinearGradient(
                    colors: [tealStart, tealEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateRing = true
                }
            }
        }
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1fh", hours)
    }

    private var hrvValue: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        return "\(Int(hrv))ms"
    }

    private var hrValue: String {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return "--" }
        return "\(Int(hr))"
    }

    private var sleepStatus: MetricStatus {
        guard let hours = healthKitManager.healthData.sleepHours else { return .unknown }
        if hours >= 7 { return .good }
        if hours >= 5 { return .moderate }
        return .low
    }

    private var hrvStatus: MetricStatus {
        guard let hrv = healthKitManager.healthData.hrv else { return .unknown }
        if hrv >= 50 { return .good }
        if hrv >= 30 { return .moderate }
        return .low
    }

    private var hrStatus: MetricStatus {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return .unknown }
        if hr <= 60 { return .good }
        if hr <= 75 { return .moderate }
        return .low
    }
}

private enum MetricStatus {
    case good, moderate, low, unknown

    var color: Color {
        switch self {
        case .good: return Color(hex: "1dd1a1")
        case .moderate: return Color(hex: "feca57")
        case .low: return Color(hex: "ff6b6b")
        case .unknown: return Color.gray
        }
    }
}

private struct RecoveryFactorPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let status: MetricStatus

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Health Alerts Section
private struct HealthAlertsSection: View {
    let alerts: [HealthAlert]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(alerts) { alert in
                HStack(spacing: 12) {
                    Image(systemName: alert.type.icon)
                        .font(.title3)
                        .foregroundStyle(alert.type.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text(alert.message)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(alert.type.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(alert.type.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - My Health Metrics Section
private struct MyHealthMetricsSection: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var selectedMetric: HealthMetricType?

    @State private var metricTrends: [HealthMetricType: TrendData] = [:]

    private let coralColor = Color(hex: "ff6b6b")

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [coralColor, Color(hex: "ee5a5a")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "heart.text.clipboard.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("MY HEALTH")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1.5)
                }

                Spacer()

                Text("Tap for details")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }

            LazyVGrid(columns: columns, spacing: 12) {
                HealthMetricCard(
                    type: .steps,
                    value: stepsValue,
                    trend: metricTrends[.steps],
                    onTap: { selectedMetric = .steps }
                )

                HealthMetricCard(
                    type: .calories,
                    value: caloriesValue,
                    trend: metricTrends[.calories],
                    onTap: { selectedMetric = .calories }
                )

                HealthMetricCard(
                    type: .hrv,
                    value: hrvValue,
                    trend: metricTrends[.hrv],
                    onTap: { selectedMetric = .hrv }
                )

                HealthMetricCard(
                    type: .restingHR,
                    value: hrValue,
                    trend: metricTrends[.restingHR],
                    onTap: { selectedMetric = .restingHR }
                )

                HealthMetricCard(
                    type: .sleep,
                    value: sleepValue,
                    trend: metricTrends[.sleep],
                    onTap: { selectedMetric = .sleep }
                )

                HealthMetricCard(
                    type: .water,
                    value: waterValue,
                    trend: nil,
                    onTap: { selectedMetric = .water }
                )
            }
        }
        .task {
            await loadTrends()
        }
    }

    private func loadTrends() async {
        // Load 7-day trends for each metric
        let hrvHistory = await healthKitManager.getHRVHistory(days: 7)
        metricTrends[.hrv] = calculateTrend(from: hrvHistory, isLowerBetter: false)

        let hrHistory = await healthKitManager.getRestingHRHistory(days: 7)
        metricTrends[.restingHR] = calculateTrend(from: hrHistory, isLowerBetter: true)

        let sleepHistory = await healthKitManager.getSleepHistory(days: 7)
        metricTrends[.sleep] = calculateTrend(from: sleepHistory, isLowerBetter: false)

        let stepsHistory = await healthKitManager.getStepsHistory(days: 7)
        metricTrends[.steps] = calculateTrend(from: stepsHistory, isLowerBetter: false)

        let caloriesHistory = await healthKitManager.getCaloriesHistory(days: 7)
        metricTrends[.calories] = calculateTrend(from: caloriesHistory, isLowerBetter: false)
    }

    private func calculateTrend(from history: [Double], isLowerBetter: Bool) -> TrendData? {
        let validData = history.filter { $0 > 0 }
        guard validData.count >= 3 else { return nil }

        let recent = Array(validData.suffix(3))
        let earlier = Array(validData.prefix(min(3, validData.count)))

        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let earlierAvg = earlier.reduce(0, +) / Double(earlier.count)

        guard earlierAvg > 0 else { return nil }

        let percentChange = ((recentAvg - earlierAvg) / earlierAvg) * 100
        let isPositive = isLowerBetter ? percentChange < 0 : percentChange > 0

        return TrendData(
            percentChange: abs(percentChange),
            isUp: percentChange > 0,
            isPositive: isPositive
        )
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

    private var hrvValue: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        return "\(Int(hrv))"
    }

    private var hrValue: String {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return "--" }
        return "\(Int(hr))"
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1f", hours)
    }

    private var waterValue: String {
        guard let water = healthKitManager.healthData.waterIntake else { return "--" }
        return "\(Int(water))"
    }
}

struct TrendData {
    let percentChange: Double
    let isUp: Bool
    let isPositive: Bool

    var color: Color {
        if percentChange < 5 { return Color.white.opacity(0.5) }
        return isPositive ? Color(hex: "1dd1a1") : Color(hex: "feca57")
    }

    var icon: String {
        isUp ? "arrow.up.right" : "arrow.down.right"
    }

    var displayText: String {
        guard percentChange >= 5 else { return "Stable" }
        return "\(isUp ? "+" : "-")\(Int(percentChange))%"
    }
}

private struct HealthMetricCard: View {
    let type: HealthMetricType
    let value: String
    let trend: TrendData?
    let onTap: () -> Void

    @State private var isPressed = false

    private let cardBg = Color(hex: "161616")

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and trend
                HStack {
                    ZStack {
                        Circle()
                            .fill(type.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: type.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(type.color)
                    }

                    Spacer()

                    if let trend = trend, trend.percentChange >= 5 {
                        HStack(spacing: 3) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 9, weight: .bold))
                            Text(trend.displayText)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(trend.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(trend.color.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                // Value and label
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(type.unit)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Text(type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
            .padding(16)
            .frame(height: 140)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                VStack {
                    LinearGradient(
                        colors: [type.color.opacity(0.8), type.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Lifestyle Cards Section
private struct LifestyleCardsSection: View {
    @Binding var showWaterDetail: Bool
    @Binding var showMoodDetail: Bool

    private let limeColor = Color(hex: "1dd1a1")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [limeColor, Color(hex: "10ac84")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("LIFESTYLE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(1.5)
            }

            HStack(spacing: 12) {
                WaterCard(showDetail: $showWaterDetail)
                MoodCard(showDetail: $showMoodDetail)
            }
        }
    }
}

private struct WaterCard: View {
    @Binding var showDetail: Bool
    @EnvironmentObject var waterManager: WaterIntakeManager

    private let cardBg = Color(hex: "161616")
    private let cyanColor = Color(hex: "54a0ff")

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.title2)
                        .foregroundStyle(cyanColor)
                    Spacer()
                    Text("\(Int(waterManager.ringProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(waterManager.hasReachedGoal ? Color(hex: "1dd1a1") : cyanColor)
                        .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(waterManager.totalOunces))oz")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("of \(Int(waterManager.goalOunces))oz")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(16)
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                VStack {
                    LinearGradient(
                        colors: [cyanColor, Color(hex: "2e86de")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MoodCard: View {
    @Binding var showDetail: Bool
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    private let cardBg = Color(hex: "161616")
    private let tealColor = Color(hex: "00d2d3")

    private var todayMood: Mood? {
        let today = Calendar.current.startOfDay(for: Date())
        return moodEntries.first { Calendar.current.isDate($0.date, inSameDayAs: today) }?.mood
    }

    private var moodEmoji: String {
        guard let mood = todayMood else { return "+" }
        switch mood {
        case .stressed: return "😰"
        case .tired: return "😴"
        case .okay: return "😐"
        case .good: return "🙂"
        case .amazing: return "😄"
        }
    }

    private var moodLabel: String {
        guard let mood = todayMood else { return "Log mood" }
        return mood.rawValue.capitalized
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "face.smiling.fill")
                        .font(.title2)
                        .foregroundStyle(tealColor)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(moodEmoji)
                        .font(.title)
                    Text(moodLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(16)
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                VStack {
                    LinearGradient(
                        colors: [tealColor, Color(hex: "0097a7")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekly Recovery Trend Section
private struct WeeklyRecoveryTrendSection: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Query private var dailyHealthData: [DailyHealthData]

    private let chartHeight: CGFloat = 120

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    private var values: [Double] {
        weekDates.map { date in
            let startOfDay = Calendar.current.startOfDay(for: date)

            if Calendar.current.isDateInToday(date) {
                return Double(healthKitManager.calculateOverallScore())
            }

            if let data = dailyHealthData.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: startOfDay)
            }) {
                let score = data.recoveryScore ?? data.calculateOverallScore()
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
        return String(formatter.string(from: date).prefix(1))
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private let cyanColor = Color(hex: "54a0ff")
    private let cardBg = Color(hex: "161616")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with colored icon
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [cyanColor, Color(hex: "2e86de")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("RECOVERY TREND")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1.5)
                }

                Spacer()

                if hasData {
                    HStack(spacing: 4) {
                        Image(systemName: trendPercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(trendPercentage >= 0 ? "+" : "")\(trendPercentage)%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(trendPercentage >= 0 ? Color(hex: "1dd1a1") : Color(hex: "feca57"))
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: 16) {
                if hasData {
                    // Chart
                    HStack(alignment: .top, spacing: 8) {
                        // Y-axis
                        VStack {
                            Text("100")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                            Spacer()
                            Text("50")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                            Spacer()
                            Text("0")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(width: 24, height: chartHeight)

                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let stepX = width / CGFloat(values.count - 1)

                            ZStack {
                                // Grid
                                VStack(spacing: 0) {
                                    ForEach(0..<4, id: \.self) { _ in
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                        Spacer()
                                    }
                                }

                                // Gradient fill
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
                                        colors: [cyanColor.opacity(0.3), cyanColor.opacity(0.05)],
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
                                        colors: [cyanColor, Color(hex: "1dd1a1")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )

                                // Data points
                                ForEach(0..<values.count, id: \.self) { index in
                                    let x = CGFloat(index) * stepX
                                    let value = values[index]
                                    let y = chartHeight - (CGFloat(max(value, 0)) / 100.0) * chartHeight

                                    if value > 0 {
                                        Circle()
                                            .fill(Color(hex: "1dd1a1"))
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
                        .frame(height: chartHeight)
                    }

                    // Day labels
                    HStack(spacing: 8) {
                        Spacer().frame(width: 24)
                        HStack {
                            ForEach(Array(weekDates.enumerated()), id: \.offset) { _, date in
                                VStack(spacing: 4) {
                                    Text(dayName(for: date))
                                        .font(.system(size: 10))
                                        .fontWeight(.medium)
                                        .foregroundStyle(isToday(date) ? Color(hex: "1dd1a1") : .white.opacity(0.4))
                                    Text(dayNumber(for: date))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(isToday(date) ? .white : .white.opacity(0.6))
                                        .frame(width: 22, height: 22)
                                        .background(isToday(date) ? Color(hex: "1dd1a1") : Color.clear)
                                        .clipShape(Circle())
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.2))
                        Text("No recovery data yet")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                        Text("Complete daily check-ins to see trends")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                VStack {
                    LinearGradient(
                        colors: [cyanColor, Color(hex: "2e86de")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
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
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Health Metrics Grid Skeleton
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonView(width: 44, height: 44)
                            .clipShape(Circle())
                        SkeletonView(width: 60, height: 24)
                        SkeletonView(width: 80, height: 14)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(.top, 20)
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
        case .water: return "oz"
        }
    }

    var color: Color {
        switch self {
        case .hrv: return Color(hex: "22c55e")
        case .restingHR: return Color(hex: "ef4444")
        case .sleep: return Color(hex: "a78bfa")
        case .steps: return Color(hex: "f97316")
        case .calories: return Color(hex: "FF6B35")
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
        case .water: return "Water intake tracked throughout the day. Aim for 64+ oz daily for optimal hydration."
        }
    }

    var yAxisRange: (min: Double, max: Double) {
        switch self {
        case .hrv: return (20, 80)
        case .restingHR: return (50, 80)
        case .sleep: return (4, 10)
        case .steps: return (0, 15000)
        case .calories: return (0, 1000)
        case .water: return (0, 100)
        }
    }
}

// MARK: - Time Period for Charts
enum TimePeriod: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case year = "1Y"

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
        case .day: return 24
        case .week: return 7
        case .month: return 30
        case .year: return 12
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
    @State private var selectedPeriod: TimePeriod = .week

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
                    // Hero section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(metricType.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: metricType.icon)
                                .font(.system(size: 32))
                                .foregroundStyle(metricType.color)
                        }

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
                    HStack(spacing: 12) {
                        MetricStatBox(label: "Average", value: formatValue(average), color: metricType.color)
                        MetricStatBox(label: "High", value: formatValue(maxVal), color: .accentGreen)
                        MetricStatBox(label: "Low", value: formatValue(minVal), color: .accentOrange)
                    }
                    .padding(.horizontal)

                    // Time period picker
                    HStack(spacing: 8) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Button {
                                selectedPeriod = period
                            } label: {
                                Text(period.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedPeriod == period ? metricType.color : Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _, _ in
                        Task {
                            await loadHistoricalData()
                        }
                    }

                    // Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text(selectedPeriod.chartTitle)
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        HStack(alignment: .top, spacing: 8) {
                            // Y-axis
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
                                let stepX = data.count > 1 ? width / CGFloat(data.count - 1) : width

                                ZStack {
                                    // Grid
                                    VStack(spacing: 0) {
                                        ForEach(0..<5, id: \.self) { _ in
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
                    ProgressView("Loading...")
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

private struct MetricStatBox: View {
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

// MARK: - Mood Detail View
struct MoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MoodEntry.date, order: .reverse) private var allMoodEntries: [MoodEntry]

    private let moodTypes: [(emoji: String, label: String, color: Color)] = [
        ("😄", "Great", .accentGreen),
        ("😊", "Good", .accentBlue),
        ("😐", "Okay", .accentOrange),
        ("😔", "Low", .accentRed),
        ("😴", "Tired", .accentTeal)
    ]

    private var calendarData: [CalendarDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else {
            return []
        }

        var moodByDate: [Date: MoodEntry] = [:]
        for entry in allMoodEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            moodByDate[dayStart] = entry
        }

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

        return days
    }

    private func moodToIndex(_ mood: Mood) -> Int {
        switch mood {
        case .amazing: return 0
        case .good: return 1
        case .okay: return 2
        case .tired: return 4
        case .stressed: return 3
        }
    }

    private var moodCounts: [Int] {
        var counts = Array(repeating: 0, count: moodTypes.count)
        for day in calendarData {
            if let moodIndex = day.moodIndex {
                counts[moodIndex] += 1
            }
        }
        return counts
    }

    private var dominantMood: Int {
        moodCounts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 2
    }

    private var totalMoodEntries: Int {
        calendarData.compactMap { $0.moodIndex }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary header
                    VStack(spacing: 12) {
                        Text(moodTypes[dominantMood].emoji)
                            .font(.system(size: 64))

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
                                total: max(totalMoodEntries, 1),
                                color: moodTypes[index].color
                            )
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // 30-day grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last 30 Days")
                            .font(.headline)
                            .fontWeight(.bold)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                            ForEach(["Su", "M", "Tu", "W", "Th", "F", "Sa"], id: \.self) { day in
                                Text(day)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .frame(height: 20)
                            }

                            ForEach(calendarData) { day in
                                VStack(spacing: 2) {
                                    if let moodIndex = day.moodIndex {
                                        Text(moodTypes[moodIndex].emoji)
                                            .font(.title3)
                                    } else {
                                        Text("—")
                                            .font(.title3)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Text("\(day.dayOfMonth)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(day.isToday ? .primary : .secondary)
                                }
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Group {
                                        if let moodIndex = day.moodIndex {
                                            moodTypes[moodIndex].color.opacity(0.15)
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
}

struct CalendarDay: Identifiable {
    let id: String
    let date: Date
    let dayOfMonth: Int
    let moodIndex: Int?
    let isToday: Bool
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

// MARK: - Safe Array Subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    HealthView(selectedTab: .constant(.health))
}
