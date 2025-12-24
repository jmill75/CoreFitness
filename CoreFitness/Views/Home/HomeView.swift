import SwiftUI

struct HomeView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    // MARK: - Bindings
    @Binding var selectedTab: Tab

    // MARK: - State
    @State private var showDailyCheckIn = false
    @State private var showWaterIntake = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome Header
                        WelcomeHeader(
                            userName: authManager.currentUser?.displayName ?? "Champion",
                            onCheckIn: {
                                showDailyCheckIn = true
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            },
                            onWaterIntake: {
                                showWaterIntake = true
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        )
                        .id("top")

                        // Week Calendar (no card, at top)
                        WeekCalendarStrip()

                        // Today's Recovery - Improved Hero Card
                        TodayRecoveryCard(selectedTab: $selectedTab)

                        // Quick Stats Row
                        QuickStatsRow(selectedTab: $selectedTab)

                        // Today's Workout Card
                        TodayWorkoutCard()
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
            .sheet(isPresented: $showDailyCheckIn) {
                DailyCheckInView()
                    .presentationBackground(.regularMaterial)
            }
            .sheet(isPresented: $showWaterIntake) {
                QuickWaterIntakeView()
                    .presentationDetents([.large])
                    .presentationBackground(.regularMaterial)
            }
            .task {
                // Refresh health data when view appears
                await healthKitManager.refreshData()
            }
        }
    }
}

// MARK: - Welcome Header
struct WelcomeHeader: View {
    let userName: String
    let onCheckIn: () -> Void
    let onWaterIntake: () -> Void

    @State private var isPressed = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Hey there"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting + ",")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(userName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            Spacer()

            // Quick Add Menu Button
            Menu {
                Button {
                    onCheckIn()
                } label: {
                    Label("Daily Check-in", systemImage: "heart.text.square")
                }

                Button {
                    onWaterIntake()
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
    }
}

// MARK: - Quick Stats Row
struct QuickStatsRow: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 12) {
            QuickStatCard(emoji: "🔥", value: "12", label: "Streak", selectedTab: $selectedTab)
            QuickStatCard(emoji: "💪", value: "48", label: "Workouts", selectedTab: $selectedTab)
            QuickStatCard(emoji: "🏆", value: "15", label: "Badges", selectedTab: $selectedTab)
        }
    }
}

struct QuickStatCard: View {
    let emoji: String
    let value: String
    let label: String
    @Binding var selectedTab: Tab

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            selectedTab = .progress
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title3)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today's Recovery Card (Improved - Bigger)
struct TodayRecoveryCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var selectedTab: Tab

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

    var body: some View {
        Button {
            selectedTab = .health
        } label: {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Today's Recovery")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
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
                    RecoveryFactorPill(
                        icon: "moon.fill",
                        label: "Sleep",
                        value: sleepStatus
                    )
                    RecoveryFactorPill(
                        icon: "waveform.path.ecg",
                        label: "HRV",
                        value: hrvStatus
                    )
                    RecoveryFactorPill(
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
        .buttonStyle(.plain)
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
}

struct RecoveryFactorPill: View {
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

// MARK: - Week Calendar Strip (no card)
struct WeekCalendarStrip: View {
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        guard let sunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: sunday) }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekDates, id: \.self) { date in
                DayScoreCell(date: date)
            }
        }
    }
}

struct DayScoreCell: View {
    let date: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }

    var body: some View {
        VStack(spacing: 8) {
            // Day letter
            Text(dayFormatter.string(from: date).prefix(1))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(isToday ? Color.brandPrimary : .secondary)

            // Date number in pill
            Text(dateFormatter.string(from: date))
                .font(.callout)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 36, height: 48)
                .background(
                    Capsule().fill(isToday ? Color.brandPrimary : Color(.systemGray5))
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Today's Workout Card
struct TodayWorkoutCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    @State private var showWorkoutExecution = false
    @State private var sampleWorkout: Workout?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack {
                Text("Today's Workout")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Scheduled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Workout Card Content
            VStack(alignment: .leading, spacing: 20) {
                // Header Row
                HStack(spacing: 16) {
                    // Workout Icon
                    ZStack {
                        Circle()
                            .fill(Color.accentOrange.opacity(0.15))
                            .frame(width: 64, height: 64)

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentOrange)
                    }

                    // Workout Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Upper Body Strength")
                            .font(.title3)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("45 min")
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "list.bullet")
                                    .font(.caption)
                                Text("6 exercises")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Exercise Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ExercisePreviewPill(name: "Bench Press", sets: 4)
                        ExercisePreviewPill(name: "Rows", sets: 4)
                        ExercisePreviewPill(name: "Shoulder Press", sets: 3)
                        ExercisePreviewPill(name: "+3 more", sets: 0)
                    }
                }

                // Start Button
                Button {
                    startWorkout()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.headline)
                        Text("Start Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.accentOrange, .accentOrange.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .accentOrange.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            if let workout = sampleWorkout {
                WorkoutExecutionView(workout: workout)
                    .environmentObject(workoutManager)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            loadWorkout()
        }
    }

    private func loadWorkout() {
        if sampleWorkout == nil {
            sampleWorkout = SampleWorkoutData.loadOrCreateSampleWorkout(in: modelContext)
        }
    }

    private func startWorkout() {
        // Reset workout manager state first
        workoutManager.resetState()

        // Ensure workout exists
        if sampleWorkout == nil {
            sampleWorkout = SampleWorkoutData.createSampleWorkout(in: modelContext)
        }

        // Verify workout has exercises before starting
        guard let workout = sampleWorkout,
              workout.exerciseCount > 0 else {
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        showWorkoutExecution = true
    }
}

struct ExercisePreviewPill: View {
    let name: String
    let sets: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            if sets > 0 {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("\(sets) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Water Intake Chart View
struct QuickWaterIntakeView: View {
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

    private let hydrationTips: [(icon: String, tip: String)] = [
        ("sunrise.fill", "Drink a glass of water first thing in the morning"),
        ("clock.fill", "Set reminders every 2 hours to stay hydrated"),
        ("fork.knife", "Have a glass before each meal to aid digestion"),
        ("figure.run", "Drink extra water before and after exercise"),
        ("leaf.fill", "Add lemon or cucumber for natural flavor"),
        ("moon.stars.fill", "Keep water by your bed for nighttime hydration")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header stats
                    HStack(spacing: 16) {
                        WaterStatBox(
                            icon: "drop.fill",
                            value: String(format: "%.1f", average),
                            label: "Daily Avg",
                            color: .accentBlue
                        )
                        WaterStatBox(
                            icon: "checkmark.circle.fill",
                            value: "\(daysMetGoal)",
                            label: "Goals Met",
                            color: .accentGreen
                        )
                        WaterStatBox(
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
                                        ForEach(0..<4) { _ in
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

                    // Hydration tips
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Color.accentYellow)
                            Text("Hydration Tips")
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        VStack(spacing: 12) {
                            ForEach(hydrationTips, id: \.tip) { item in
                                HStack(spacing: 14) {
                                    Image(systemName: item.icon)
                                        .font(.body)
                                        .foregroundStyle(Color.accentBlue)
                                        .frame(width: 32, height: 32)
                                        .background(Color.accentBlue.opacity(0.1))
                                        .clipShape(Circle())

                                    Text(item.tip)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Spacer()
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

struct WaterStatBox: View {
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

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
