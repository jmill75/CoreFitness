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
                    VStack(spacing: 28) {
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

// MARK: - Water Intake Tracking View
struct QuickWaterIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var fitnessDataService: FitnessDataService

    // State
    @State private var todayIntake: Double = 0 // glasses
    @State private var dailyGoal: Double = 8 // glasses
    @State private var showCustomAmount = false
    @State private var customAmount: String = ""
    @State private var showAddAnimation = false
    @State private var lastAddedAmount: Int = 0

    private let glassSize: Double = 8 // oz per glass

    private var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, todayIntake / dailyGoal)
    }

    private var remainingGlasses: Int {
        max(0, Int(dailyGoal - todayIntake))
    }

    private let hydrationTips: [(icon: String, tip: String)] = [
        ("sunrise.fill", "Drink a glass of water first thing in the morning"),
        ("clock.fill", "Set reminders every 2 hours to stay hydrated"),
        ("fork.knife", "Have a glass before each meal to aid digestion"),
        ("figure.run", "Drink extra water before and after exercise")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Today's Progress Hero
                    ZStack {
                        // Background gradient
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentBlue, Color.accentBlue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 20) {
                            // Large progress ring
                            ZStack {
                                // Background ring
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 16)
                                    .frame(width: 160, height: 160)

                                // Progress ring
                                Circle()
                                    .trim(from: 0, to: progressPercentage)
                                    .stroke(
                                        Color.white,
                                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                    )
                                    .frame(width: 160, height: 160)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressPercentage)

                                // Center content
                                VStack(spacing: 4) {
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("\(Int(todayIntake))")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                        Text("/\(Int(dailyGoal))")
                                            .font(.title2)
                                            .fontWeight(.medium)
                                            .opacity(0.8)
                                    }
                                    Text("glasses")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .opacity(0.8)
                                }
                                .foregroundStyle(.white)

                                // Add animation overlay
                                if showAddAnimation {
                                    Text("+\(lastAddedAmount)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .offset(y: -80)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity.combined(with: .move(edge: .top))
                                        ))
                                }
                            }

                            // Status message
                            if todayIntake >= dailyGoal {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Daily goal reached!")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                            } else {
                                Text("\(remainingGlasses) more glass\(remainingGlasses == 1 ? "" : "es") to reach your goal")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .padding(32)
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                    .shadow(color: Color.accentBlue.opacity(0.3), radius: 16, y: 8)

                    // Quick Add Buttons
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Add")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            WaterAddButton(amount: 1, icon: "drop.fill") {
                                addWater(glasses: 1)
                            }
                            WaterAddButton(amount: 2, icon: "drop.fill") {
                                addWater(glasses: 2)
                            }
                            WaterAddButton(amount: 3, icon: "drop.fill") {
                                addWater(glasses: 3)
                            }

                            // Custom amount button
                            Button {
                                showCustomAmount = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(Color.accentBlue)

                                    Text("Custom")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }

                    // Today's Log
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Stats")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            if todayIntake > 0 {
                                Button {
                                    removeLastGlass()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "minus.circle")
                                        Text("Undo")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }

                        HStack(spacing: 16) {
                            TodayWaterStatBox(
                                icon: "drop.fill",
                                value: "\(Int(todayIntake * glassSize))",
                                unit: "oz",
                                label: "Total",
                                color: .accentBlue
                            )
                            TodayWaterStatBox(
                                icon: "percent",
                                value: "\(Int(progressPercentage * 100))",
                                unit: "%",
                                label: "Progress",
                                color: progressPercentage >= 1 ? .accentGreen : .accentOrange
                            )
                            TodayWaterStatBox(
                                icon: "target",
                                value: "\(Int(dailyGoal * glassSize))",
                                unit: "oz",
                                label: "Goal",
                                color: .accentTeal
                            )
                        }
                    }
                    .padding()
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
            .alert("Add Water", isPresented: $showCustomAmount) {
                TextField("Glasses", text: $customAmount)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    customAmount = ""
                }
                Button("Add") {
                    if let amount = Int(customAmount), amount > 0 {
                        addWater(glasses: amount)
                    }
                    customAmount = ""
                }
            } message: {
                Text("Enter the number of glasses to add")
            }
            .onAppear {
                loadTodayData()
            }
        }
    }

    // MARK: - Actions

    private func addWater(glasses: Int) {
        lastAddedAmount = glasses
        todayIntake += Double(glasses)

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Show animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showAddAnimation = true
        }

        // Hide animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                showAddAnimation = false
            }
        }

        // Save to database
        saveWaterIntake()

        // Extra haptic for goal completion
        if todayIntake >= dailyGoal && todayIntake - Double(glasses) < dailyGoal {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func removeLastGlass() {
        guard todayIntake > 0 else { return }
        todayIntake = max(0, todayIntake - 1)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        saveWaterIntake()
    }

    private func loadTodayData() {
        let todayData = fitnessDataService.getOrCreateHealthData(for: Date())
        if let intake = todayData.waterIntake {
            todayIntake = intake / glassSize // Convert oz to glasses
        }
        if let goal = todayData.waterGoal {
            dailyGoal = goal / glassSize // Convert oz to glasses
        }
    }

    private func saveWaterIntake() {
        let todayData = fitnessDataService.getOrCreateHealthData(for: Date())
        todayData.waterIntake = todayIntake * glassSize // Store in oz
        todayData.waterGoal = dailyGoal * glassSize // Store in oz
        try? modelContext.save()
    }
}

// MARK: - Water Add Button
struct WaterAddButton: View {
    let amount: Int
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(0..<min(amount, 3), id: \.self) { _ in
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(Color.accentBlue)
                    }
                }

                Text("+\(amount)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("glass\(amount == 1 ? "" : "es")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Today Water Stat Box
struct TodayWaterStatBox: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
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
