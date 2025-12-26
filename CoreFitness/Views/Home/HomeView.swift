import SwiftUI
import SwiftData

struct HomeView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Bindings
    @Binding var selectedTab: Tab

    // MARK: - Queries
    @Query(filter: #Predicate<Challenge> { $0.isActive }, sort: \Challenge.startDate, order: .reverse)
    private var activeChallenges: [Challenge]

    // MARK: - State
    @State private var showDailyCheckIn = false
    @State private var showWaterIntake = false

    // Get current user's participant for a challenge
    private func currentUserParticipant(for challenge: Challenge) -> ChallengeParticipant? {
        guard let userId = authManager.currentUser?.id else { return nil }
        return challenge.participants?.first { $0.oderId == userId }
    }

    @State private var animateContent = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome Header
                        WelcomeHeader(userName: authManager.currentUser?.displayName ?? "Champion")
                            .id("top")
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 10)

                        // Week Calendar (no card, at top)
                        WeekCalendarStrip()
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 10)

                        // Today's Recovery - Improved Hero Card
                        TodayRecoveryCard(selectedTab: $selectedTab)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 15)

                        // Current Activity Section (Workout + Challenge)
                        CurrentActivitySection(
                            activeChallenges: activeChallenges,
                            currentUserParticipant: currentUserParticipant,
                            selectedTab: $selectedTab
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 15)

                        // Quick Options Grid
                        QuickOptionsGrid(
                            onCheckIn: {
                                showDailyCheckIn = true
                                themeManager.mediumImpact()
                            },
                            onWaterIntake: {
                                showWaterIntake = true
                                themeManager.mediumImpact()
                            },
                            selectedTab: $selectedTab
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 15)
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    proxy.scrollTo("top", anchor: .top)
                    withAnimation(.easeOut(duration: 0.5)) {
                        animateContent = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showDailyCheckIn) {
                DailyCheckInView()
            }
            .fullScreenCover(isPresented: $showWaterIntake) {
                QuickWaterIntakeView()
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

    private var firstName: String {
        userName.components(separatedBy: " ").first ?? userName
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("Hi, ")
                .font(.title)
                .fontWeight(.bold)

            Text(firstName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentBlue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        case .checkIn: return "heart.fill"
        case .water: return "drop.fill"
        case .exercises: return "figure.run"
        case .progress: return "chart.bar.fill"
        case .health: return "heart.fill"
        case .programs: return "list.clipboard.fill"
        case .challenges: return "trophy.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var emoji: String {
        switch self {
        case .checkIn: return "❤️"
        case .water: return "💧"
        case .exercises: return "🏃"
        case .progress: return "📊"
        case .health: return "💗"
        case .programs: return "📋"
        case .challenges: return "🏆"
        case .settings: return "⚙️"
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
        case .checkIn: return Color(hex: "e74c3c") // Red
        case .water: return Color(hex: "3498db") // Blue
        case .exercises: return Color(hex: "e67e22") // Orange
        case .progress: return Color(hex: "27ae60") // Green
        case .health: return Color(hex: "e91e8c") // Pink
        case .programs: return Color(hex: "1abc9c") // Teal
        case .challenges: return Color(hex: "f1c40f") // Yellow/Gold
        case .settings: return Color(hex: "5a6068") // Gray
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
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(selectedActions) { action in
                        QuickActionButton(
                            emoji: action.emoji,
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
        // Note: Haptic feedback handled by parent view through callbacks
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
    }

    private func addAction(_ action: QuickActionType) {
        guard currentActions.count < 8 else { return }
        withAnimation(.spring(response: 0.3)) {
            currentActions.append(action)
        }
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
                    RoundedRectangle(cornerRadius: 14)
                        .fill(action.color)
                        .frame(width: 54, height: 54)

                    Text(action.emoji)
                        .font(.system(size: 24))
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, .red)
                        .frame(width: 44, height: 44)
                }
                .offset(x: 6, y: -6)
                .accessibilityLabel("Remove \(action.title)")
            }

            Text(action.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .contain)
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
                        RoundedRectangle(cornerRadius: 14)
                            .fill(action.color.opacity(disabled ? 0.2 : 0.4))
                            .frame(width: 54, height: 54)

                        Text(action.emoji)
                            .font(.system(size: 24))
                            .opacity(disabled ? 0.4 : 0.7)
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
        .accessibilityLabel("Add \(action.title)")
        .accessibilityHint(disabled ? "Maximum shortcuts reached" : "Double tap to add this shortcut")
    }
}

struct QuickActionButton: View {
    let emoji: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                // Large rounded square icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color)
                        .frame(width: 64, height: 64)
                        .shadow(color: color.opacity(0.3), radius: 4, y: 2)

                    Text(emoji)
                        .font(.system(size: 28))
                }

                // Title
                Text(title)
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(title)")
    }
}

// MARK: - Today's Recovery Card (Large Hero Card)
struct TodayRecoveryCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var selectedTab: Tab
    @State private var isPressed = false

    // Original blue palette
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
                        Text("Today's Health")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(scoreMessage)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer().frame(height: 4)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()
                }

                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    HealthStatItem(icon: "figure.walk", value: stepsValue, label: "Steps", color: Color.accentGreen)
                    HealthStatItem(icon: "flame.fill", value: caloriesValue, label: "Calories", color: Color.accentOrange)
                    HealthStatItem(icon: "moon.fill", value: sleepValue, label: "Sleep", color: Color(hex: "fcd34d"))
                    HealthStatItem(icon: "heart.fill", value: hrValue, label: "HR", color: Color.accentRed)
                    HealthStatItem(icon: "waveform.path.ecg", value: hrvValue, label: "HRV", color: Color(hex: "a78bfa"))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
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
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's Health. Score \(healthKitManager.isAuthorized ? "\(score)" : "not available"). \(scoreMessage)")
        .accessibilityHint("Double tap to view health details")
    }

    private var stepsValue: String {
        guard let steps = healthKitManager.healthData.steps else { return "--" }
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }

    private var caloriesValue: String {
        guard let cals = healthKitManager.healthData.activeCalories else { return "--" }
        return "\(Int(cals))"
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1fh", hours)
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

// Compact health stat for grid layout
struct HealthStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecoveryStat: View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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

    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fullDateFormatter.string(from: date))\(isToday ? ", Today" : "")")
    }
}

// MARK: - Current Activity Section (Workout + Challenge)
struct CurrentActivitySection: View {
    let activeChallenges: [Challenge]
    let currentUserParticipant: (Challenge) -> ChallengeParticipant?
    @Binding var selectedTab: Tab

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Today's Workout
            VStack(alignment: .leading, spacing: 10) {
                Text("Today's Workout")
                    .font(.headline)
                    .fontWeight(.bold)

                ActiveWorkoutCard(selectedTab: $selectedTab)
            }

            // Active Challenge (if exists)
            if let challenge = activeChallenges.first {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Challenge")
                        .font(.headline)
                        .fontWeight(.bold)

                    HomeChallengeCard(
                        challenge: challenge,
                        currentUserParticipant: currentUserParticipant(challenge),
                        selectedTab: $selectedTab
                    )
                }
            }
        }
    }
}

// MARK: - Active Workout Card (Rich Design)
struct ActiveWorkoutCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @Binding var selectedTab: Tab

    @State private var showWorkoutExecution = false
    @State private var showStartConfirmation = false
    @State private var selectedWorkout: Workout?
    @State private var isPressed = false

    // Original blue gradient
    private let gradientStart = Color(hex: "3b82f6")
    private let gradientEnd = Color(hex: "1e40af")

    private var activeSession: WorkoutSession? {
        workoutManager.currentSession
    }

    private var currentWorkout: Workout? {
        activeSession?.workout ?? workouts.first
    }

    private var isInProgress: Bool {
        activeSession != nil && workoutManager.currentPhase != .idle && workoutManager.currentPhase != .completed
    }

    private var exerciseProgress: Double {
        guard let workout = currentWorkout, workout.exerciseCount > 0 else { return 0 }
        if isInProgress {
            return Double(workoutManager.currentExerciseIndex + 1) / Double(workout.exerciseCount)
        }
        return 0
    }

    private var totalExercises: Int {
        currentWorkout?.exerciseCount ?? 0
    }

    var body: some View {
        if let workout = currentWorkout {
            Button {
                if isInProgress {
                    showWorkoutExecution = true
                } else {
                    selectedWorkout = workout
                    showStartConfirmation = true
                }
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    // Title and chevron
                    HStack {
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    // Stats row
                    HStack(spacing: 16) {
                        Label("\(totalExercises) exercises", systemImage: "dumbbell.fill")
                        Label("\(workout.estimatedDuration) min", systemImage: "clock")
                        if isInProgress {
                            Label(workoutManager.formattedElapsedTime, systemImage: "timer")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 5)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: geo.size.width * (isInProgress ? exerciseProgress : 0), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .alert("Start Workout?", isPresented: $showStartConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Start") {
                    startWorkout()
                }
            } message: {
                if let selected = selectedWorkout {
                    Text("Begin \(selected.name)? (~\(selected.estimatedDuration) min)")
                } else {
                    Text("Start this workout?")
                }
            }
            .fullScreenCover(isPresented: $showWorkoutExecution) {
                if let workout = isInProgress ? currentWorkout : selectedWorkout {
                    WorkoutExecutionView(workout: workout)
                        .environmentObject(workoutManager)
                        .environmentObject(themeManager)
                }
            }
        } else {
            // Empty state
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Text("💪")
                        .font(.system(size: 24))
                        .opacity(0.5)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("No Workout")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.6))

                    Text("Tap to create one")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button {
                    selectedTab = .programs
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [gradientStart.opacity(0.4), gradientEnd.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func startWorkout() {
        workoutManager.resetState()
        guard let workout = selectedWorkout, workout.exerciseCount > 0 else { return }
        showWorkoutExecution = true
    }
}

// MARK: - Home Challenge Card (Rich Design)
struct HomeChallengeCard: View {
    let challenge: Challenge
    let currentUserParticipant: ChallengeParticipant?
    @Binding var selectedTab: Tab
    @State private var isPressed = false

    // Original orange gradient
    private let gradientStart = Color(hex: "f97316")
    private let gradientEnd = Color(hex: "ea580c")

    private var userRank: Int {
        guard let participant = currentUserParticipant,
              let participants = challenge.participants else { return 0 }
        let sorted = participants.sorted { $0.completedDays > $1.completedDays }
        return (sorted.firstIndex(where: { $0.id == participant.id }) ?? -1) + 1
    }

    private var totalParticipants: Int {
        challenge.participants?.count ?? 0
    }

    private var currentStreak: Int {
        currentUserParticipant?.currentStreak ?? 0
    }

    var body: some View {
        Button {
            selectedTab = .programs
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Title and chevron
                HStack {
                    Text(challenge.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Stats row
                HStack(spacing: 16) {
                    Label("Day \(challenge.currentDay)/\(challenge.durationDays)", systemImage: "calendar")
                    Label("\(Int(challenge.progress * 100))%", systemImage: "checkmark.circle")
                    if currentStreak > 0 {
                        Label("\(currentStreak) 🔥", systemImage: "flame")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 5)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: geo.size.width * challenge.progress, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Today's Workout Card (Compact - Legacy)
struct TodayWorkoutCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @Binding var selectedTab: Tab

    @State private var showWorkoutExecution = false
    @State private var showStartConfirmation = false
    @State private var selectedWorkout: Workout?

    // Get most recent workout
    private var currentWorkout: Workout? {
        workouts.first
    }

    var body: some View {
        if let workout = currentWorkout {
            HStack(spacing: 12) {
                // Workout Icon
                ZStack {
                    Circle()
                        .fill(Color.accentOrange.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentOrange)
                }

                // Workout Info (tappable to go to Programs)
                Button {
                    selectedTab = .programs
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Today's Workout")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        HStack(spacing: 8) {
                            Label("\(workout.estimatedDuration) min", systemImage: "clock")
                            Label("\(workout.exerciseCount) exercises", systemImage: "list.bullet")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                        Text("View Details")
                            .font(.caption2)
                            .foregroundStyle(Color.accentOrange)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                // Start Button
                Button {
                    selectedWorkout = workout
                    showStartConfirmation = true
                } label: {
                    Text("Start")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentOrange)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start workout")
                .accessibilityHint("Double tap to start \(workout.name) workout")
            }
            .accessibilityElement(children: .contain)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .alert("Start Workout?", isPresented: $showStartConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Start") {
                    startWorkout()
                }
            } message: {
                if let selected = selectedWorkout {
                    Text("Are you sure you want to begin \(selected.name)? This workout is approximately \(selected.estimatedDuration) minutes.")
                } else {
                    Text("Are you sure you want to start this workout?")
                }
            }
            .fullScreenCover(isPresented: $showWorkoutExecution) {
                if let selected = selectedWorkout {
                    WorkoutExecutionView(workout: selected)
                        .environmentObject(workoutManager)
                        .environmentObject(themeManager)
                }
            }
        } else {
            // Empty state - no workouts available
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 48, height: 48)

                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("No Workout Planned")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text("Create a workout in Programs")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    selectedTab = .programs
                } label: {
                    Text("Create")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentOrange)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func startWorkout() {
        workoutManager.resetState()
        guard let workout = selectedWorkout, workout.exerciseCount > 0 else { return }
        showWorkoutExecution = true
    }
}

// MARK: - Water Intake Tracking View
struct QuickWaterIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var waterManager: WaterIntakeManager
    @EnvironmentObject var themeManager: ThemeManager

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
        themeManager.mediumImpact()

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
            themeManager.notifySuccess()
            waterManager.markGoalCelebrated()

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
        .accessibilityLabel("Add \(size.displaySize) of water")
        .accessibilityHint("Double tap to log \(size.label) \(size.displaySize)")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit)")
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
