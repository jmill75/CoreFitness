import SwiftUI
import SwiftData

struct HomeView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Bindings
    @Binding var selectedTab: Tab

    // MARK: - Queries
    @Query(filter: #Predicate<Challenge> { $0.isActive }, sort: \Challenge.startDate, order: .reverse)
    private var activeChallenges: [Challenge]

    // MARK: - State
    @State private var showDailyCheckIn = false
    @State private var showWaterIntake = false
    @State private var showWorkoutPopup = false
    @State private var selectedWorkoutForPopup: Workout?
    @State private var showWorkoutExecution = false
    @State private var showShareAndStart = false

    // Get current user's participant for a challenge
    private func currentUserParticipant(for challenge: Challenge) -> ChallengeParticipant? {
        guard let userId = authManager.currentUser?.id else { return nil }
        return challenge.participants?.first { $0.ownerId == userId }
    }

    @State private var animationStage = 0

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            // Welcome Header
                            WelcomeHeader(userName: "Jeff")
                                .id("top")
                                .opacity(animationStage >= 1 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 1 ? 0 : 10))
                                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: animationStage)

                            // Week Calendar (no card, at top)
                            WeekCalendarStrip()
                                .padding(.bottom, 8)
                                .opacity(animationStage >= 2 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 2 ? 0 : 10))
                                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8).delay(0.05), value: animationStage)

                            // Today's Recovery - Improved Hero Card
                            TodayRecoveryCard(selectedTab: $selectedTab)
                                .opacity(animationStage >= 3 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 3 ? 0 : 15))
                                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: animationStage)

                            // Current Activity Section (Workout + Challenge)
                            CurrentActivitySection(
                                activeChallenges: activeChallenges,
                                currentUserParticipant: currentUserParticipant,
                                selectedTab: $selectedTab,
                                onShowWorkoutPopup: { workout in
                                    selectedWorkoutForPopup = workout
                                    showWorkoutPopup = true
                                }
                            )
                            .opacity(animationStage >= 4 ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (animationStage >= 4 ? 0 : 15))
                            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.15), value: animationStage)

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
                            .opacity(animationStage >= 5 ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (animationStage >= 5 ? 0 : 15))
                            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.2), value: animationStage)

                            // AI Insights Section
                            AIInsightsSection(
                                selectedTab: $selectedTab,
                                onCheckIn: { showDailyCheckIn = true },
                                onWaterIntake: { showWaterIntake = true }
                            )
                            .opacity(animationStage >= 5 ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (animationStage >= 5 ? 0 : 15))
                            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.25), value: animationStage)
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                    .scrollIndicators(.hidden)
                    .background(Color(.systemGroupedBackground))
                    .onAppear {
                        proxy.scrollTo("top", anchor: .top)
                        if reduceMotion {
                            animationStage = 5
                        } else {
                            for stage in 1...5 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(stage) * 0.06) {
                                    animationStage = stage
                                }
                            }
                        }
                    }
                    .onChange(of: selectedTab) { _, newTab in
                        if newTab == .home {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showDailyCheckIn) {
                    DailyCheckInView()
                        .background(.ultraThinMaterial)
                }
                .fullScreenCover(isPresented: $showWaterIntake) {
                    QuickWaterIntakeView()
                        .background(.ultraThinMaterial)
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

            // Workout popup overlay
            if showWorkoutPopup, let workout = selectedWorkoutForPopup {
                WorkoutStartPopup(
                    workout: workout,
                    onStart: {
                        showWorkoutPopup = false
                        // Small delay to let popup dismiss before presenting execution view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showWorkoutExecution = true
                        }
                    },
                    onShareAndStart: {
                        showWorkoutPopup = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showShareAndStart = true
                        }
                    },
                    onCancel: {
                        showWorkoutPopup = false
                    }
                )
                .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            if let workout = selectedWorkoutForPopup {
                WorkoutExecutionView(workout: workout)
                    .environmentObject(workoutManager)
                    .environmentObject(themeManager)
            }
        }
        .fullScreenCover(isPresented: $showShareAndStart) {
            if let workout = selectedWorkoutForPopup {
                ShareAndStartView(workout: workout) {
                    // After sending invite, start workout
                    showShareAndStart = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showWorkoutExecution = true
                    }
                }
                .environmentObject(workoutManager)
                .environmentObject(themeManager)
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

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(timeGreeting), ")
                .font(.title)
                .fontWeight(.bold)

            Text(firstName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentBlue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
        .padding(.bottom, 8)
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
        case .checkIn: return "checkmark.circle.fill"
        case .water: return "drop.fill"
        case .exercises: return "figure.highintensity.intervaltraining"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .health: return "heart.text.clipboard.fill"
        case .programs: return "rectangle.stack.fill"
        case .challenges: return "flag.checkered"
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

// MARK: - AI Insights Section
struct AIInsightsSection: View {
    @StateObject private var aiService = AIInsightsService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTab: Tab

    let onCheckIn: () -> Void
    let onWaterIntake: () -> Void

    var body: some View {
        if aiService.aiEnabled && !aiService.insights.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("AI Insights")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }

                ForEach(aiService.insights) { insight in
                    AIInsightCard(
                        insight: insight,
                        onAction: {
                            handleInsightAction(insight)
                        },
                        onDismiss: {
                            withAnimation {
                                aiService.insights.removeAll { $0.id == insight.id }
                            }
                        }
                    )
                }
            }
            .padding(.top, 8)
            .task {
                await aiService.generateInsights()
            }
        }
    }

    private func handleInsightAction(_ insight: AIInsight) {
        themeManager.mediumImpact()

        switch insight.type {
        case .checkInReminder:
            onCheckIn()
        case .hydrationReminder:
            onWaterIntake()
        case .healthAdvice:
            selectedTab = .health
        case .challengeMotivation:
            selectedTab = .programs // Challenges are accessible from Programs
        case .engagementNudge, .workoutSuggestion:
            selectedTab = .programs
        case .moodSupport:
            onCheckIn()
        case .celebratory:
            selectedTab = .progress
        }
    }
}

// MARK: - AI Insight Card
struct AIInsightCard: View {
    let insight: AIInsight
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: insight.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(insight.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            // Actions
            VStack(spacing: 8) {
                if let actionLabel = insight.actionLabel {
                    Button(action: onAction) {
                        Text(actionLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(insight.color)
                            .clipShape(Capsule())
                    }
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Options Grid (Customizable)
struct QuickOptionsGrid: View {
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var userProfileManager: UserProfileManager
    let onCheckIn: () -> Void
    let onWaterIntake: () -> Void
    @Binding var selectedTab: Tab

    @State private var showEditSheet = false

    static let defaultActions: [QuickActionType] = [.checkIn, .water, .exercises, .progress, .health, .programs, .challenges, .settings]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var selectedActions: [QuickActionType] {
        if let decoded = try? JSONDecoder().decode([QuickActionType].self, from: userProfileManager.quickActionsData),
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Edit quick actions")
                .accessibilityHint("Double tap to customize your shortcuts")
            }

            // Dynamic Grid (supports 1-8 items)
            if !selectedActions.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
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
                        userProfileManager.quickActionsData = encoded
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
        case .exercises:
            selectedTab = .programs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationState.showExercises = true
            }
        case .programs:
            selectedTab = .programs
        case .progress:
            selectedTab = .progress
        case .health:
            selectedTab = .health
        case .challenges:
            selectedTab = .programs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationState.showChallenges = true
            }
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
    @State private var editMode: EditMode = .active

    private var availableActions: [QuickActionType] {
        QuickActionType.allCases.filter { !currentActions.contains($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Current Shortcuts Section
                Section {
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
                            .padding(.vertical, 20)
                            Spacer()
                        }
                        .listRowBackground(Color(.tertiarySystemGroupedBackground))
                    } else {
                        ForEach(currentActions) { action in
                            ReorderableActionRow(action: action)
                        }
                        .onMove(perform: moveAction)
                        .onDelete(perform: deleteAction)
                    }
                } header: {
                    HStack {
                        Text("Your Shortcuts")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                        Spacer()
                        Text("\(currentActions.count) of 8")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                    .padding(.bottom, 4)
                } footer: {
                    Text("Drag to reorder. Swipe left to remove.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Available Shortcuts Section
                if !availableActions.isEmpty {
                    Section {
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
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Add Shortcuts")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                            .padding(.bottom, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, $editMode)
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

    private func moveAction(from source: IndexSet, to destination: Int) {
        currentActions.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteAction(at offsets: IndexSet) {
        currentActions.remove(atOffsets: offsets)
    }

    private func addAction(_ action: QuickActionType) {
        guard currentActions.count < 8 else { return }
        withAnimation(.spring(response: 0.3)) {
            currentActions.append(action)
        }
    }
}

// MARK: - Reorderable Action Row
struct ReorderableActionRow: View {
    let action: QuickActionType

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(action.color)
                    .frame(width: 40, height: 40)

                Image(systemName: action.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }

            // Title
            Text(action.title)
                .font(.body)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.vertical, 4)
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

                        Image(systemName: action.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.white)
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
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                // Clean icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: color.opacity(0.35), radius: 6, y: 3)

                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                }

                // Title
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.92 : 1.0))
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            if !reduceMotion {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(title)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Today's Recovery Card (Large Hero Card)
struct TodayRecoveryCard: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
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
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Recovery")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.85))
                        Text(scoreMessage)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer().frame(height: 4)

                        HStack(spacing: 4) {
                            Text("View Details")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()
                }

                // Recovery Stats - Single row
                HStack(spacing: 0) {
                    HealthStatItem(icon: "moon.zzz.fill", value: sleepValue, label: "Sleep", color: Color(hex: "a78bfa"))
                    HealthStatItem(icon: "waveform.path.ecg", value: hrvValue, label: "HRV", color: Color(hex: "34d399"))
                    HealthStatItem(icon: "heart.fill", value: hrValue, label: "Resting HR", color: Color.accentRed)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
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
            .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.98 : 1.0))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            if !reduceMotion {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's Recovery Score")
        .accessibilityValue(healthKitManager.isAuthorized ? "\(score) out of 100. \(scoreMessage)" : "Not connected. Connect Health app to see your score.")
        .accessibilityHint("Double tap to view detailed recovery metrics")
        .accessibilityAddTraits(.isButton)
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

    private var waterValue: String {
        guard let water = healthKitManager.healthData.waterIntake else { return "--" }
        let cups = water / 8.0 // Convert oz to cups (8oz per cup)
        return String(format: "%.1f", cups)
    }

    private var readinessValue: String {
        // Calculate readiness based on HRV and sleep
        guard healthKitManager.isAuthorized else { return "--" }
        let hrvScore = min(100, max(0, (healthKitManager.healthData.hrv ?? 40) / 80 * 100))
        let sleepScore = min(100, max(0, (healthKitManager.healthData.sleepHours ?? 6) / 8 * 100))
        let readiness = Int((hrvScore + sleepScore) / 2)
        return "\(readiness)%"
    }

    private var trendValue: String {
        // Show trend based on score comparison (simplified)
        guard healthKitManager.isAuthorized else { return "--" }
        if score >= 70 { return "↑" }
        if score >= 50 { return "→" }
        return "↓"
    }
}

// Compact health stat for grid layout
struct HealthStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value == "--" ? "No data available" : value)
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
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
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

    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month header
            HStack {
                Text(monthYearText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Week days
            HStack(spacing: 6) {
                ForEach(weekDates, id: \.self) { date in
                    DayScoreCell(date: date)
                }
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
    var onShowWorkoutPopup: ((Workout) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Today's Workout
            VStack(alignment: .leading, spacing: 10) {
                Text("Today's Workout")
                    .font(.headline)
                    .fontWeight(.bold)

                ActiveWorkoutCard(selectedTab: $selectedTab, onShowPopup: onShowWorkoutPopup)
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
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Active Workout Card (Rich Design)
struct ActiveWorkoutCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @Binding var selectedTab: Tab
    var onShowPopup: ((Workout) -> Void)?

    @State private var showWorkoutExecution = false
    @State private var selectedWorkout: Workout?
    @State private var isPressed = false

    // Pine green gradient
    private let gradientStart = Color(hex: "2d6a4f")
    private let gradientEnd = Color(hex: "1b4332")

    private var activeSession: WorkoutSession? {
        workoutManager.currentSession
    }

    // Current workout is only shown if there's an active session or an explicitly active workout
    private var currentWorkout: Workout? {
        activeSession?.workout ?? workouts.first { $0.isActive }
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
                themeManager.mediumImpact()
                if isInProgress {
                    showWorkoutExecution = true
                } else {
                    selectedWorkout = workout
                    onShowPopup?(workout)
                }
            } label: {
                HStack(spacing: 16) {
                    // Workout icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // Status badge
                        Text(isInProgress ? "IN PROGRESS" : "READY TO START")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(0.5)
                            .foregroundStyle(.white.opacity(0.7))

                        // Title
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        // Stats row
                        HStack(spacing: 14) {
                            Label("\(totalExercises)", systemImage: "dumbbell.fill")
                            Label("\(workout.estimatedDuration) min", systemImage: "clock")
                            if isInProgress {
                                Label(workoutManager.formattedElapsedTime, systemImage: "timer")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.25))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * (isInProgress ? exerciseProgress : 0), height: 6)
                            }
                        }
                        .frame(height: 6)

                    }

                    Spacer()

                    // Play/Go button
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: isInProgress ? "play.fill" : "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(minHeight: 140)
                .background(
                    LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .fullScreenCover(isPresented: $showWorkoutExecution) {
                if let workout = isInProgress ? currentWorkout : selectedWorkout {
                    WorkoutExecutionView(workout: workout)
                        .environmentObject(workoutManager)
                        .environmentObject(themeManager)
                }
            }
        } else {
            // Empty state - Professional design
            VStack(spacing: 0) {
                // Main content area
                VStack(spacing: 16) {
                    // Icon with subtle glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [gradientStart.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)

                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 72, height: 72)

                        Image(systemName: "figure.run")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [gradientStart, gradientEnd],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    // Text content
                    VStack(spacing: 6) {
                        Text("No Active Workout")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Start a program or create a custom workout to get moving")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)

                // Action button
                Button {
                    themeManager.mediumImpact()
                    selectedTab = .programs
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))

                        Text("Browse Programs")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(gradientStart)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
    @EnvironmentObject var navigationState: NavigationState
    let challenge: Challenge
    let currentUserParticipant: ChallengeParticipant?
    @Environment(\.accessibilityReduceMotion) var reduceMotion
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
            navigationState.showChallenges = true
        } label: {
            HStack(spacing: 16) {
                // Challenge icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Status badge with rank
                    HStack(spacing: 8) {
                        Text("ACTIVE CHALLENGE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(0.5)
                            .foregroundStyle(.white.opacity(0.7))

                        if userRank > 0 && totalParticipants > 0 {
                            Text("•")
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Rank #\(userRank) of \(totalParticipants)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    // Title
                    Text(challenge.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    // Stats row
                    HStack(spacing: 14) {
                        Label("Day \(challenge.currentDay)/\(challenge.durationDays)", systemImage: "calendar")
                        Label("\(Int(challenge.progress * 100))%", systemImage: "checkmark.circle")
                        if currentStreak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                Text("\(currentStreak)")
                            }
                            .foregroundStyle(Color(hex: "fcd34d"))
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: geo.size.width * challenge.progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                Spacer()

                // Go button
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .frame(minHeight: 140)
            .background(
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.98 : 1.0))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            if !reduceMotion {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(challenge.name) challenge")
        .accessibilityValue("Day \(challenge.currentDay) of \(challenge.durationDays). \(Int(challenge.progress * 100)) percent complete\(currentStreak > 0 ? ". \(currentStreak) day streak" : "")")
        .accessibilityHint("Double tap to view challenge details")
        .accessibilityAddTraits(.isButton)
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

    // Get current workout only if explicitly active
    private var currentWorkout: Workout? {
        workouts.first { $0.isActive }
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

                    // Trend Graph
                    WaterTrendGraphSection()

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

// MARK: - Water Trend Graph Section
struct WaterTrendGraphSection: View {
    @EnvironmentObject var waterManager: WaterIntakeManager
    @State private var selectedPeriod: WaterTrendPeriod = .week
    @State private var trendData: [Double] = []
    @State private var isLoading = true

    private let chartHeight: CGFloat = 160

    enum WaterTrendPeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var shortLabel: String {
            switch self {
            case .day: return "1D"
            case .week: return "1W"
            case .month: return "1M"
            case .year: return "1Y"
            }
        }

        var dataPoints: Int {
            switch self {
            case .day: return 24      // Hourly
            case .week: return 7      // Daily
            case .month: return 30    // Daily
            case .year: return 12     // Monthly
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
    }

    private var averageValue: Double {
        guard !trendData.isEmpty else { return 0 }
        let nonZero = trendData.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0, +) / Double(nonZero.count)
    }

    private var goalOz: Double {
        waterManager.goalOunces
    }

    private var daysMetGoal: Int {
        trendData.filter { $0 >= goalOz }.count
    }

    private var hasData: Bool {
        trendData.contains { $0 > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with period selector
            HStack {
                Text("Hydration Trend")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                // Time period picker - compact single row
                HStack(spacing: 2) {
                    ForEach(WaterTrendPeriod.allCases, id: \.self) { period in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPeriod = period
                            }
                            loadData()
                        } label: {
                            Text(period.shortLabel)
                                .font(.system(size: 11, weight: selectedPeriod == period ? .bold : .medium))
                                .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    selectedPeriod == period ?
                                    Color.accentBlue :
                                    Color.clear
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(2)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
            }

            // Summary stats
            if hasData {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundStyle(Color.accentBlue)
                        Text(String(format: "%.0f oz avg", averageValue))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    if selectedPeriod != .day {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.accentGreen)
                            Text("\(daysMetGoal) goals met")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    Spacer()
                }
                .foregroundStyle(.secondary)
            }

            // Chart
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: chartHeight)
            } else if hasData {
                // Bar chart
                HStack(alignment: .top, spacing: 8) {
                    // Y-axis labels
                    VStack(alignment: .trailing) {
                        Text("\(Int(goalOz * 1.2))oz")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(goalOz))oz")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(goalOz * 0.5))oz")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("0")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 32, height: chartHeight)

                    // Chart area
                    ZStack(alignment: .bottom) {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                Spacer()
                            }
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                        .frame(height: chartHeight)

                        // Goal line
                        Rectangle()
                            .fill(Color.accentGreen.opacity(0.6))
                            .frame(height: 2)
                            .offset(y: -chartHeight * (goalOz / (goalOz * 1.2)))

                        // Bars
                        HStack(alignment: .bottom, spacing: selectedPeriod == .year ? 4 : 2) {
                            ForEach(0..<trendData.count, id: \.self) { index in
                                let value = trendData[index]
                                let maxValue = goalOz * 1.2
                                let height = min((value / maxValue) * chartHeight, chartHeight)
                                let metGoal = value >= goalOz

                                RoundedRectangle(cornerRadius: selectedPeriod == .day ? 1 : 3)
                                    .fill(
                                        metGoal ?
                                        LinearGradient(colors: [Color.accentGreen, Color.accentGreen.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                                        (value > 0 ? LinearGradient(colors: [Color.accentBlue, Color.accentBlue.opacity(0.5)], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                                    )
                                    .frame(height: max(height, 4))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: chartHeight)
                    }
                }

                // X-axis labels
                HStack {
                    Spacer().frame(width: 40)
                    HStack {
                        Text(xAxisStartLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(xAxisEndLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.accentGreen.opacity(0.6))
                            .frame(width: 16, height: 2)
                        Text("Goal: \(Int(goalOz))oz")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.accentGreen)
                            .frame(width: 8, height: 8)
                        Text("Goal met")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.accentBlue)
                            .frame(width: 8, height: 8)
                        Text("Below goal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No data for this period")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(height: chartHeight)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .onAppear {
            loadData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadData()
        }
    }

    private var xAxisStartLabel: String {
        switch selectedPeriod {
        case .day: return "12am"
        case .week: return "7d ago"
        case .month: return "30d ago"
        case .year: return "12m ago"
        }
    }

    private var xAxisEndLabel: String {
        switch selectedPeriod {
        case .day: return "Now"
        case .week: return "Today"
        case .month: return "Today"
        case .year: return "Now"
        }
    }

    private func loadData() {
        isLoading = true

        Task {
            let data: [Double]
            switch selectedPeriod {
            case .day:
                data = await waterManager.getHourlyDataForTodayAsync()
            case .week:
                data = await waterManager.getLast7DaysDataAsync()
            case .month:
                data = await waterManager.getLast30DaysDataAsync()
            case .year:
                data = await waterManager.getLast12MonthsDataAsync()
            }

            await MainActor.run {
                trendData = data
                isLoading = false
            }
        }
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

// MARK: - Workout Start Popup
struct WorkoutStartPopup: View {
    let workout: Workout
    let onStart: () -> Void
    let onShareAndStart: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(animateIn ? 0.4 : 0)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(animateIn ? 1 : 0))
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Popup card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "2d6a4f"), Color(hex: "1b4332")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        Label("\(workout.exerciseCount) exercises", systemImage: "dumbbell.fill")
                        Label("~\(workout.estimatedDuration) min", systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 28)
                .padding(.bottom, 24)

                Divider()

                // Options
                VStack(spacing: 0) {
                    // Start button
                    Button {
                        onStart()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: "2d6a4f"))
                                .clipShape(Circle())

                            Text("Start Workout")
                                .font(.body)
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 76)

                    // Share and Start button
                    Button {
                        onShareAndStart()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.accentBlue)
                                .clipShape(Circle())

                            Text("Share & Start")
                                .font(.body)
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Cancel button
                Button {
                    dismissWithAnimation()
                } label: {
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(colorScheme == .dark ? Color(hex: "1C1C1E") : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            .padding(.horizontal, 24)
            .scaleEffect(animateIn ? 1 : 0.9)
            .opacity(animateIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onCancel()
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
