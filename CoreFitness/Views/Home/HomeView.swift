import SwiftUI

struct HomeView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var navigationState: NavigationState

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

                        // Today's Workout Card
                        TodayWorkoutCard(selectedTab: $selectedTab)

                        // Quick Options Grid
                        QuickOptionsGrid(
                            onCheckIn: {
                                showDailyCheckIn = true
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            },
                            onWaterIntake: {
                                showWaterIntake = true
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            },
                            selectedTab: $selectedTab
                        )
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
            .fullScreenCover(isPresented: $showDailyCheckIn) {
                DailyCheckInView()
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
            .onChange(of: navigationState.showWaterIntake) { _, newValue in
                if newValue {
                    showWaterIntake = true
                    // Reset navigation state
                    navigationState.showWaterIntake = false
                }
            }
            .onChange(of: navigationState.showDailyCheckIn) { _, newValue in
                if newValue {
                    showDailyCheckIn = true
                    // Reset navigation state
                    navigationState.showDailyCheckIn = false
                }
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

// MARK: - Quick Action Types
enum QuickActionType: String, CaseIterable, Codable, Identifiable {
    case checkIn = "check_in"
    case water = "water"
    case exercises = "exercises"
    case progress = "progress"
    case health = "health"
    case programs = "programs"
    case challenges = "challenges"
    case settings = "settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .checkIn: return "heart.text.square.fill"
        case .water: return "drop.fill"
        case .exercises: return "figure.run"
        case .progress: return "chart.bar.fill"
        case .health: return "heart.fill"
        case .programs: return "list.clipboard.fill"
        case .challenges: return "trophy.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .checkIn: return "Check-In"
        case .water: return "Water"
        case .exercises: return "Exercises"
        case .progress: return "Progress"
        case .health: return "Health"
        case .programs: return "Programs"
        case .challenges: return "Challenges"
        case .settings: return "Settings"
        }
    }

    var color: Color {
        switch self {
        case .checkIn: return .accentRed
        case .water: return .accentBlue
        case .exercises: return .accentOrange
        case .progress: return .accentGreen
        case .health: return Color(hex: "FF2D55") // Pink
        case .programs: return Color(hex: "0891b2") // Teal
        case .challenges: return .accentYellow
        case .settings: return .gray
        }
    }
}

// MARK: - Quick Options Grid (Customizable)
struct QuickOptionsGrid: View {
    let onCheckIn: () -> Void
    let onWaterIntake: () -> Void
    @Binding var selectedTab: Tab

    @AppStorage("quickActions") private var quickActionsData: Data = Data()
    @State private var showEditSheet = false

    static let defaultActions: [QuickActionType] = [.checkIn, .water, .exercises, .progress, .health, .programs, .challenges, .settings]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var selectedActions: [QuickActionType] {
        if let decoded = try? JSONDecoder().decode([QuickActionType].self, from: quickActionsData),
           !decoded.isEmpty {
            return decoded
        }
        return Self.defaultActions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Edit button
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentBlue)
                }
            }

            // Dynamic Grid (supports 1-8 items)
            if !selectedActions.isEmpty {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(selectedActions) { action in
                        QuickActionButton(
                            icon: action.icon,
                            title: action.title,
                            color: action.color
                        ) {
                            handleAction(action)
                        }
                    }
                }
            } else {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                        Text("No shortcuts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showEditSheet) {
            EditQuickActionsSheet(
                selectedActions: selectedActions,
                onSave: { newActions in
                    if let encoded = try? JSONEncoder().encode(newActions) {
                        quickActionsData = encoded
                    }
                }
            )
            .presentationDetents([.large])
        }
    }

    private func handleAction(_ action: QuickActionType) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch action {
        case .checkIn:
            onCheckIn()
        case .water:
            onWaterIntake()
        case .exercises, .programs:
            selectedTab = .programs
        case .progress:
            selectedTab = .progress
        case .health:
            selectedTab = .health
        case .challenges:
            selectedTab = .programs
        case .settings:
            selectedTab = .settings
        }
    }
}

// MARK: - Edit Quick Actions Sheet
struct EditQuickActionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selectedActions: [QuickActionType]
    let onSave: ([QuickActionType]) -> Void

    @State private var currentActions: [QuickActionType] = []

    private var availableActions: [QuickActionType] {
        QuickActionType.allCases.filter { !currentActions.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Shortcuts Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Shortcuts")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(currentActions.count) of 8")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if currentActions.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.title)
                                        .foregroundStyle(.tertiary)
                                    Text("No shortcuts added")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 30)
                                Spacer()
                            }
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(currentActions) { action in
                                    EditableActionItem(action: action) {
                                        removeAction(action)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Available Shortcuts Section
                    if !availableActions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add Shortcuts")
                                .font(.headline)
                                .fontWeight(.bold)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(availableActions) { action in
                                    AddableActionItem(action: action, disabled: currentActions.count >= 8) {
                                        addAction(action)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Info text
                    Text("Tap the minus to remove a shortcut. Tap an available shortcut to add it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(currentActions)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                currentActions = selectedActions
            }
        }
    }

    private func removeAction(_ action: QuickActionType) {
        withAnimation(.spring(response: 0.3)) {
            currentActions.removeAll { $0 == action }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func addAction(_ action: QuickActionType) {
        guard currentActions.count < 8 else { return }
        withAnimation(.spring(response: 0.3)) {
            currentActions.append(action)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Editable Action Item (with delete button)
struct EditableActionItem: View {
    let action: QuickActionType
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: action.icon)
                        .font(.title3)
                        .foregroundStyle(action.color)
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, .red)
                }
                .offset(x: 6, y: -6)
            }

            Text(action.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Addable Action Item (with add button)
struct AddableActionItem: View {
    let action: QuickActionType
    let disabled: Bool
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(action.color.opacity(disabled ? 0.05 : 0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: action.icon)
                            .font(.title3)
                            .foregroundStyle(action.color.opacity(disabled ? 0.3 : 0.5))
                    }

                    // Add button
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, disabled ? .gray : .accentGreen)
                        .offset(x: 6, y: -6)
                }

                Text(action.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(disabled ? .tertiary : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 6) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }

                // Title
                Text(title)
                    .font(.system(size: 10))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Today's Recovery Card (Compact with Sleep, HRV, HR)
struct TodayRecoveryCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var selectedTab: Tab

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
        Button {
            selectedTab = .health
        } label: {
            HStack(spacing: 12) {
                // Compact Score Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 6)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: healthKitManager.isAuthorized ? CGFloat(score) / 100.0 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [ringStart, ringEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Text(healthKitManager.isAuthorized ? "\(score)" : "--")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recovery")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(scoreMessage)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }

                Spacer()

                // Quick stats - Sleep, HRV, HR
                HStack(spacing: 8) {
                    CompactRecoveryStat(icon: "moon.fill", label: "Sleep", value: sleepValue, color: Color(hex: "fcd34d"))
                    CompactRecoveryStat(icon: "waveform.path.ecg", label: "HRV", value: hrvValue, color: Color(hex: "a78bfa"))
                    CompactRecoveryStat(icon: "heart.fill", label: "HR", value: hrValue, color: Color(hex: "ef4444"))
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [bgStart, bgEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.0fh", hours)
    }

    private var hrvValue: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        return "\(Int(hrv))"
    }

    private var hrValue: String {
        guard let hr = healthKitManager.healthData.restingHeartRate else { return "--" }
        return "\(Int(hr))"
    }
}

struct CompactRecoveryStat: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(width: 32)
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

// MARK: - Today's Workout Card (Compact)
struct TodayWorkoutCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Tab

    @State private var showWorkoutExecution = false
    @State private var showStartConfirmation = false
    @State private var sampleWorkout: Workout?

    var body: some View {
        Button {
            // Navigate to Programs tab
            selectedTab = .programs
        } label: {
            HStack(spacing: 14) {
                // Workout Icon
                ZStack {
                    Circle()
                        .fill(Color.accentOrange.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentOrange)
                }

                // Workout Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upper Body Strength")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("45 min")
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 10))
                            Text("6 exercises")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Start Button
                Button {
                    showStartConfirmation = true
                } label: {
                    Text("Start")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentOrange)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .alert("Start Workout?", isPresented: $showStartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                startWorkout()
            }
        } message: {
            Text("Are you sure you want to begin Upper Body Strength? This workout is approximately 45 minutes.")
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
        workoutManager.resetState()
        if sampleWorkout == nil {
            sampleWorkout = SampleWorkoutData.createSampleWorkout(in: modelContext)
        }
        guard let workout = sampleWorkout, workout.exerciseCount > 0 else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showWorkoutExecution = true
    }
}

// MARK: - Water Intake Tracking View
struct QuickWaterIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var waterManager: WaterIntakeManager

    // Local animation state
    @State private var showAddAnimation = false
    @State private var animateProgress = false
    @State private var showCelebration = false

    private let hydrationTips: [(icon: String, tip: String)] = [
        ("sunrise.fill", "Drink water first thing in the morning"),
        ("clock.fill", "Set reminders every 2 hours to stay hydrated"),
        ("fork.knife", "Have water before each meal to aid digestion"),
        ("figure.run", "Drink extra water before and after exercise")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Progress Hero
                    ZStack {
                        // Background gradient
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentBlue, Color.accentTeal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Celebration water droplets
                        if showCelebration {
                            WaterDropletCelebration()
                        }

                        VStack(spacing: 20) {
                            // Large progress ring
                            ZStack {
                                // Background ring with segments
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 14)
                                    .frame(width: 150, height: 150)

                                // Segmented progress ring (red to green)
                                Circle()
                                    .trim(from: 0, to: animateProgress ? waterManager.ringProgress : 0)
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                Color.red,
                                                Color.orange,
                                                Color.yellow,
                                                Color.accentGreen
                                            ]),
                                            center: .center,
                                            startAngle: .degrees(-90),
                                            endAngle: .degrees(270)
                                        ),
                                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                    )
                                    .frame(width: 150, height: 150)
                                    .rotationEffect(.degrees(-90))

                                // Center content
                                VStack(spacing: 2) {
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("\(Int(waterManager.totalOunces))")
                                            .font(.system(size: 42, weight: .bold, design: .rounded))
                                        Text("oz")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .opacity(0.8)
                                    }
                                    Text("of \(Int(waterManager.goalOunces)) oz")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .opacity(0.8)
                                }
                                .foregroundStyle(.white)

                                // Add animation overlay
                                if showAddAnimation {
                                    Text("+\(Int(waterManager.lastAddedAmount)) oz")
                                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: .orange.opacity(0.8), radius: 8, x: 0, y: 0)
                                        .shadow(color: .yellow.opacity(0.5), radius: 15, x: 0, y: 0)
                                        .scaleEffect(1.1)
                                        .offset(y: -90)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.5).combined(with: .opacity),
                                            removal: .scale(scale: 1.5).combined(with: .opacity).combined(with: .move(edge: .top))
                                        ))
                                }
                            }

                            // Status message
                            if waterManager.hasReachedGoal {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Daily goal reached!")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .scaleEffect(showCelebration ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showCelebration)
                            } else {
                                Text("\(waterManager.remainingOunces) oz more to reach your goal")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .padding(28)
                    }
                    .frame(height: 280)
                    .padding(.horizontal)
                    .shadow(color: Color.accentBlue.opacity(0.3), radius: 16, y: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 28))

                    // Quick Add Buttons - Bottle sizes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Add")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        HStack(spacing: 8) {
                            ForEach(HomeWaterSize.allCases) { size in
                                HomeWaterAddButton(size: size) {
                                    addWater(ounces: size.ounces)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Today's Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Stats")
                            .font(.headline)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            TodayWaterStatBox(
                                icon: "drop.fill",
                                value: "\(Int(waterManager.totalOunces))",
                                unit: "oz",
                                label: "Total",
                                color: .accentBlue
                            )
                            TodayWaterStatBox(
                                icon: "percent",
                                value: "\(Int(waterManager.progressPercentage * 100))",
                                unit: "%",
                                label: "Progress",
                                color: waterManager.progressPercentage >= 1 ? .accentGreen : .accentOrange
                            )
                            TodayWaterStatBox(
                                icon: "target",
                                value: "\(Int(waterManager.goalOunces))",
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
            .onAppear {
                waterManager.loadTodayData()
                withAnimation(.easeOut(duration: 0.8)) {
                    animateProgress = true
                }
            }
        }
    }

    // MARK: - Actions

    private func addWater(ounces: Double) {
        let previousTotal = waterManager.totalOunces
        waterManager.addWater(ounces: ounces)

        // Reset and re-animate progress
        animateProgress = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateProgress = true
            }
        }

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

        // Celebration and extra haptic for goal completion
        if waterManager.hasReachedGoal && previousTotal < waterManager.goalOunces {
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // Trigger celebration animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCelebration = true
            }

            // Hide celebration after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showCelebration = false
                }
            }
        }
    }
}

// MARK: - Home Water Size (Bottle sizes)
enum HomeWaterSize: CaseIterable, Identifiable {
    case glass      // 8oz
    case small      // 16oz
    case medium     // 24oz
    case large      // 32oz
    case extraLarge // 64oz

    var id: String { displaySize }

    var ounces: Double {
        switch self {
        case .glass: return 8
        case .small: return 16
        case .medium: return 24
        case .large: return 32
        case .extraLarge: return 64
        }
    }

    var displaySize: String {
        switch self {
        case .glass: return "8oz"
        case .small: return "16oz"
        case .medium: return "24oz"
        case .large: return "32oz"
        case .extraLarge: return "64oz"
        }
    }

    var icon: String {
        switch self {
        case .glass: return "drop.fill"
        case .small: return "waterbottle.fill"
        case .medium: return "waterbottle.fill"
        case .large: return "waterbottle.fill"
        case .extraLarge: return "waterbottle.fill"
        }
    }

    var label: String {
        switch self {
        case .glass: return "Glass"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "XL"
        }
    }
}

// MARK: - Home Water Add Button
struct HomeWaterAddButton: View {
    let size: HomeWaterSize
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: size.icon)
                    .font(.system(size: size == .glass ? 16 : 20))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentBlue)

                Text(size.displaySize)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(size.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 75)
            .background(Color.accentBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(isPressed ? 0.92 : 1.0)
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

// MARK: - Water Droplet Celebration
struct WaterDropletCelebration: View {
    @State private var droplets: [WaterDroplet] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(droplets) { droplet in
                    WaterDropletView(droplet: droplet)
                }
            }
            .onAppear {
                createDroplets(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createDroplets(in size: CGSize) {
        droplets = (0..<25).map { index in
            WaterDroplet(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -50...(-20)),
                endY: size.height + 50,
                size: CGFloat.random(in: 8...18),
                delay: Double(index) * 0.08,
                duration: Double.random(in: 1.5...2.5),
                opacity: Double.random(in: 0.5...0.9)
            )
        }
    }
}

struct WaterDroplet: Identifiable {
    let id: Int
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let delay: Double
    let duration: Double
    let opacity: Double
}

struct WaterDropletView: View {
    let droplet: WaterDroplet
    @State private var yPosition: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: droplet.size))
            .foregroundStyle(.white.opacity(droplet.opacity))
            .position(x: droplet.x, y: isAnimating ? droplet.endY : droplet.startY)
            .onAppear {
                withAnimation(
                    .easeIn(duration: droplet.duration)
                    .delay(droplet.delay)
                ) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
