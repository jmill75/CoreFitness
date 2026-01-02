import SwiftUI
import SwiftData

struct HomeView: View {

    // MARK: - Environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var activeProgramManager: ActiveProgramManager
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
                            WelcomeHeader(
                                userName: "Jeff",
                                selectedTab: $selectedTab,
                                onCheckIn: { showDailyCheckIn = true },
                                onWaterIntake: { showWaterIntake = true }
                            )
                            .id("top")
                                .opacity(animationStage >= 1 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 1 ? 0 : 10))
                                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: animationStage)

                            // Stats Grid (Recovery, HRV, Sleep)
                            StatsGridSection(selectedTab: $selectedTab)
                                .opacity(animationStage >= 2 ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (animationStage >= 2 ? 0 : 15))
                                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: animationStage)

                            // Weekly Activity Section
                            WeeklyActivitySection(selectedTab: $selectedTab)
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
                        .padding(.bottom, 140)
                    }
                    .scrollIndicators(.hidden)
                    .background(Color(hex: "000000"))
                    .onAppear {
                        proxy.scrollTo("top", anchor: .top)
                        if reduceMotion {
                            animationStage = 5
                        } else {
                            // Single animation instead of 5 separate dispatches
                            withAnimation(.easeOut(duration: 0.3)) {
                                animationStage = 5
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
    @Binding var selectedTab: Tab
    var onCheckIn: () -> Void
    var onWaterIntake: () -> Void

    @State private var showQuickActions = false

    private var firstName: String {
        userName.components(separatedBy: " ").first ?? userName
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<21: return "GOOD EVENING"
        default: return "GOOD NIGHT"
        }
    }

    private var dateString: String {
        CachedFormatters.dateString.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .top) {
            // Greeting with gradient and date
            VStack(alignment: .leading, spacing: 4) {
                Text("\(timeGreeting), \(firstName.uppercased())")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "feca57"), Color(hex: "ff9f43")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(dateString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Quick Actions Button
            Button {
                showQuickActions = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "00d2d3"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "141414"))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Quick Actions")
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .sheet(isPresented: $showQuickActions) {
            QuickActionsSheet(
                selectedTab: $selectedTab,
                onCheckIn: onCheckIn,
                onWaterIntake: onWaterIntake
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Quick Actions Sheet
struct QuickActionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeProgramManager: ActiveProgramManager
    @EnvironmentObject var navigationState: NavigationState
    @Binding var selectedTab: Tab
    var onCheckIn: () -> Void
    var onWaterIntake: () -> Void

    @State private var showNoProgramToast = false

    private let teal = Color(hex: "00d2d3")
    private let coral = Color(hex: "ff6b6b")
    private let purple = Color(hex: "a55eea")
    private let gold = Color(hex: "feca57")

    private var hasActiveProgram: Bool {
        activeProgramManager.hasCurrentWorkout || activeProgramManager.hasActiveProgram
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        SheetQuickActionButton(
                            icon: "figure.run",
                            label: "Start Workout",
                            color: teal
                        ) {
                            if hasActiveProgram {
                                dismiss()
                                selectedTab = .programs
                            } else {
                                showNoProgramToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showNoProgramToast = false
                                    dismiss()
                                    selectedTab = .programs
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        navigationState.showProgramBrowser = true
                                    }
                                }
                            }
                        }

                        SheetQuickActionButton(
                            icon: "drop.fill",
                            label: "Log Water",
                            color: Color(hex: "54a0ff")
                        ) {
                            dismiss()
                            onWaterIntake()
                        }

                        SheetQuickActionButton(
                            icon: "heart.text.square.fill",
                            label: "Check In",
                            color: coral
                        ) {
                            dismiss()
                            onCheckIn()
                        }

                        SheetQuickActionButton(
                            icon: "trophy.fill",
                            label: "Challenges",
                            color: gold
                        ) {
                            dismiss()
                            selectedTab = .programs
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 20)

                // No Program Toast
                if showNoProgramToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("No program selected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color(hex: "1a1a1a"))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: showNoProgramToast)
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(teal)
                }
            }
        }
    }
}

private struct SheetQuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(hex: "141414"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notifications Sheet
struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Tab
    var onCheckIn: () -> Void
    var onWaterIntake: () -> Void

    // Sample notifications - replace with actual data
    @State private var notifications: [AppNotification] = [
        AppNotification(icon: "trophy.fill", iconColor: .yellow, title: "Achievement Unlocked!", message: "You completed your 7-day workout streak", time: "2h ago", destination: .progress),
        AppNotification(icon: "drop.fill", iconColor: .accentBlue, title: "Water Reminder", message: "You're at 40% of your daily water goal. Stay hydrated!", time: "3h ago", destination: .water),
        AppNotification(icon: "figure.run", iconColor: .accentGreen, title: "Workout Reminder", message: "Don't forget your scheduled leg day workout", time: "4h ago", destination: .workout),
        AppNotification(icon: "checkmark.circle.fill", iconColor: Color.brandPrimary, title: "Check-in Reminder", message: "How are you feeling today? Log your daily check-in", time: "5h ago", destination: .checkIn),
        AppNotification(icon: "flag.checkered", iconColor: .accentOrange, title: "Challenge Update", message: "You're in 2nd place! Keep pushing to take the lead", time: "Yesterday", destination: .challenges),
        AppNotification(icon: "heart.fill", iconColor: .accentRed, title: "Recovery Alert", message: "Your HRV is low today. Consider a rest day", time: "Yesterday", destination: .health),
    ]

    var body: some View {
        NavigationStack {
            List {
                if notifications.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No Notifications")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("You're all caught up!")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(notifications) { notification in
                        NotificationRow(notification: notification)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleNotificationTap(notification)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteNotification)
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !notifications.isEmpty {
                        Button("Clear All") {
                            withAnimation {
                                notifications.removeAll()
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch notification.destination {
            case .progress:
                selectedTab = .progress
            case .health:
                selectedTab = .health
            case .programs, .workout:
                selectedTab = .programs
            case .challenges:
                selectedTab = .programs
            case .checkIn:
                onCheckIn()
            case .water:
                onWaterIntake()
            }
        }
    }

    private func deleteNotification(at offsets: IndexSet) {
        withAnimation {
            notifications.remove(atOffsets: offsets)
        }
    }
}

// MARK: - Notification Destination
enum NotificationDestination {
    case progress
    case health
    case programs
    case challenges
    case checkIn
    case water
    case workout
}

// MARK: - App Notification Model
struct AppNotification: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let time: String
    let destination: NotificationDestination
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            Image(systemName: notification.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(notification.iconColor)
                .frame(width: 40, height: 40)
                .background(notification.iconColor.opacity(0.15))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(notification.time)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        case .checkIn: return Color(hex: "ff6b6b") // Coral
        case .water: return Color(hex: "54a0ff") // Cyan
        case .exercises: return Color(hex: "ff9f43") // Orange
        case .progress: return Color(hex: "1dd1a1") // Lime
        case .health: return Color(hex: "ee5253") // Red
        case .programs: return Color(hex: "00d2d3") // Teal
        case .challenges: return Color(hex: "feca57") // Gold
        case .settings: return Color(hex: "576574") // Gray
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

    private let tealAccent = Color(hex: "00d2d3")
    private let tealDeep = Color(hex: "01a3a4")
    private let cardBg = Color(hex: "161616")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(tealAccent)
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            if aiService.aiEnabled && !aiService.insights.isEmpty {
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
            } else {
                // Placeholder card when no insights
                VStack(alignment: .leading, spacing: 16) {
                    // AI Coach badge
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 12))
                        Text("AI COACH")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1)
                    }
                    .foregroundStyle(tealAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tealAccent.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(tealAccent.opacity(0.3), lineWidth: 1)
                    )

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("INSIGHTS LOADING")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("AI-powered insights based on your health data will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    VStack {
                        LinearGradient(
                            colors: [tealDeep, tealAccent, Color(hex: "1dd1a1")],
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
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .padding(.top, 8)
        .task {
            await aiService.generateInsights()
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

    private let tealAccent = Color(hex: "00d2d3")
    private let tealDeep = Color(hex: "01a3a4")
    private let cardBg = Color(hex: "161616")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // AI Coach badge
            HStack(spacing: 6) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 12))
                Text("AI COACH")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1)
            }
            .foregroundStyle(tealAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [tealAccent.opacity(0.2), Color(hex: "1dd1a1").opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(tealAccent.opacity(0.3), lineWidth: 1)
            )

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.title.uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)
            }

            // Action buttons
            HStack(spacing: 12) {
                if let actionLabel = insight.actionLabel {
                    Button(action: onAction) {
                        Text(actionLabel)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [tealDeep, tealAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
        .padding(24)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            // Teal accent bar at top
            VStack {
                LinearGradient(
                    colors: [tealDeep, tealAccent, Color(hex: "1dd1a1")],
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
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .overlay(
            // Teal glow in corner
            RadialGradient(
                colors: [tealAccent.opacity(0.1), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 150
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .allowsHitTesting(false)
        )
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
        VStack(alignment: .leading, spacing: 12) {
            // Header with Edit button (outside card)
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "1dd1a1"))
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

            // Card content
            Group {
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
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
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
            .presentationDragIndicator(.visible)
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

// MARK: - Today's Recovery Section
struct TodayRecoverySection: View {
    @Binding var selectedTab: Tab

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "ff6b6b"))
                Text("Today's Recovery")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            // Recovery Card (shared component)
            RecoveryCard {
                selectedTab = .health
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// TodayRecoveryCard removed - now using shared RecoveryCard component from Components/RecoveryCard.swift

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
        CachedFormatters.monthYear.string(from: Date())
    }

    var body: some View {
        // Week days
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

    private var dayFormatter: DateFormatter { CachedFormatters.day }
    private var dateFormatter: DateFormatter { CachedFormatters.date }
    private var fullDateFormatter: DateFormatter { CachedFormatters.fullDate }

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

// MARK: - Today's Focus Section (Workout + Challenge as Separate Cards)
struct CurrentActivitySection: View {
    let activeChallenges: [Challenge]
    let currentUserParticipant: (Challenge) -> ChallengeParticipant?
    @Binding var selectedTab: Tab
    var onShowWorkoutPopup: ((Workout) -> Void)?

    private let teal = Color(hex: "00d2d3")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Text("Today's Workout")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Workout Card
            TodaysWorkoutCard(
                selectedTab: $selectedTab,
                onShowWorkoutPopup: onShowWorkoutPopup
            )

            // Challenge Card (if active)
            if let challenge = activeChallenges.first {
                TodaysChallengeCard(
                    challenge: challenge,
                    currentUserParticipant: currentUserParticipant,
                    selectedTab: $selectedTab
                )
            }
        }
    }
}

// MARK: - Today's Workout Card (Featured Card Style)
struct TodaysWorkoutCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var activeProgramManager: ActiveProgramManager

    @Binding var selectedTab: Tab
    var onShowWorkoutPopup: ((Workout) -> Void)?

    @State private var showWorkoutExecution = false

    private var activeSession: WorkoutSession? {
        workoutManager.currentSession
    }

    private var currentWorkout: Workout? {
        if let sessionWorkout = activeSession?.workout {
            return sessionWorkout
        }
        return activeProgramManager.currentWorkout
    }

    private var isWorkoutInProgress: Bool {
        activeSession != nil && workoutManager.currentPhase != .idle && workoutManager.currentPhase != .completed
    }

    // Colors from HTML design
    private let cardBg = Color(hex: "141414")
    private let cardBorder = Color.white.opacity(0.06)
    private let teal = Color(hex: "00d2d3")
    private let tealDark = Color(hex: "01a3a4")
    private let sage = Color(hex: "1dd1a1")
    private let textMuted = Color(hex: "666666")

    var body: some View {
        Button {
            themeManager.mediumImpact()
            if let workout = currentWorkout {
                if isWorkoutInProgress {
                    showWorkoutExecution = true
                } else {
                    onShowWorkoutPopup?(workout)
                }
            } else {
                selectedTab = .programs
            }
        } label: {
            VStack(spacing: 0) {
                // Gradient Header
                ZStack(alignment: .bottomLeading) {
                    // Gradient background
                    LinearGradient(
                        colors: [tealDark, teal, sage],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 140)

                    // Clean shine overlay
                    ZStack {
                        // Diagonal shine
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.4),
                                .init(color: .white.opacity(0.15), location: 0.45),
                                .init(color: .white.opacity(0.25), location: 0.5),
                                .init(color: .white.opacity(0.15), location: 0.55),
                                .init(color: .clear, location: 0.6),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        // Top highlight glow
                        VStack {
                            LinearGradient(
                                colors: [.white.opacity(0.12), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 70)
                            Spacer()
                        }
                    }

                    // Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(sage)
                            .frame(width: 8, height: 8)
                        Text(isWorkoutInProgress ? "In Progress" : "Up Next")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6))
                    .background(.ultraThinMaterial.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(16)
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        topTrailingRadius: 24
                    )
                )

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    if let workout = currentWorkout {
                        // Title
                        Text(workout.name)
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .foregroundStyle(.white)

                        // Subtitle
                        if let programName = workout.sourceProgramName, !programName.isEmpty {
                            Text("\(programName) • Week \(workout.programWeekNumber), Day \(workout.programSessionNumber)")
                                .font(.system(size: 13))
                                .foregroundStyle(textMuted)
                        }

                        // Stats row
                        HStack(spacing: 20) {
                            WorkoutStatItem(value: "\(workout.exerciseCount)", label: "EXERCISES")
                            WorkoutStatItem(value: "\(workout.estimatedDuration)", label: "MINUTES")
                            WorkoutStatItem(value: "\(workout.exercises?.reduce(0) { $0 + $1.targetSets } ?? 0)", label: "SETS")
                        }
                        .padding(.top, 4)

                        // Start button
                        Text("Start Workout")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [tealDark, teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        // No workout state
                        Text("No Workout Scheduled")
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .foregroundStyle(.white)

                        Text("Choose from your saved programs or workouts")
                            .font(.system(size: 13))
                            .foregroundStyle(textMuted)

                        Text("Browse Programs")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [tealDark, teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            if let workout = currentWorkout {
                WorkoutExecutionView(workout: workout)
                    .environmentObject(workoutManager)
            }
        }
    }
}

struct WorkoutStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(Color(hex: "666666"))
        }
    }
}

// MARK: - Today's Challenge Card (Featured Card Style - Matching Workout Card)
struct TodaysChallengeCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navigationState: NavigationState

    let challenge: Challenge
    let currentUserParticipant: (Challenge) -> ChallengeParticipant?
    @Binding var selectedTab: Tab

    private let cardBg = Color(hex: "141414")
    private let cardBorder = Color.white.opacity(0.06)
    private let goldAccent = Color(hex: "feca57")
    private let goldDark = Color(hex: "e8b339")
    private let orange = Color(hex: "ff9f43")
    private let textMuted = Color(hex: "666666")

    var body: some View {
        let participant = currentUserParticipant(challenge)
        let completedDays = participant?.completedDays ?? 0
        let progress = Double(completedDays) / Double(max(1, challenge.durationDays))
        let currentWeek = min(4, (challenge.currentDay / 7) + 1)
        let totalWeeks = max(1, challenge.durationDays / 7)

        Button {
            themeManager.mediumImpact()
            selectedTab = .programs
            navigationState.showChallenges = true
        } label: {
            VStack(spacing: 0) {
                // Gradient Header (matching workout card)
                ZStack(alignment: .bottomLeading) {
                    // Gradient background
                    LinearGradient(
                        colors: [goldDark, goldAccent, orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 140)

                    // Clean shine overlay
                    ZStack {
                        // Diagonal shine
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.4),
                                .init(color: .white.opacity(0.15), location: 0.45),
                                .init(color: .white.opacity(0.25), location: 0.5),
                                .init(color: .white.opacity(0.15), location: 0.55),
                                .init(color: .clear, location: 0.6),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        // Top highlight glow
                        VStack {
                            LinearGradient(
                                colors: [.white.opacity(0.12), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 70)
                            Spacer()
                        }
                    }

                    // Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(orange)
                            .frame(width: 8, height: 8)
                        Text("Day \(challenge.currentDay) of \(challenge.durationDays)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6))
                    .background(.ultraThinMaterial.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(16)
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        topTrailingRadius: 24
                    )
                )

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Title (serif font like workout card)
                    Text(challenge.name)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(.white)

                    // Subtitle
                    Text("Week \(currentWeek) of \(totalWeeks) • \(Int(progress * 100))% Complete")
                        .font(.system(size: 13))
                        .foregroundStyle(textMuted)

                    // Stats row
                    HStack(spacing: 20) {
                        HomeChallengeStatItem(value: "\(completedDays)", label: "DAYS")
                        HomeChallengeStatItem(value: "\(challenge.durationDays - completedDays)", label: "REMAINING")
                        HomeChallengeStatItem(value: "\(challenge.participants?.count ?? 0)", label: "MEMBERS")
                    }
                    .padding(.top, 4)

                    // View Challenge button
                    Text("View Challenge")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [goldDark, goldAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(20)
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HomeChallengeStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(Color(hex: "666666"))
        }
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

    // Vibrant cyan/blue gradient
    private let gradientStart = Color(hex: "54a0ff")
    private let gradientEnd = Color(hex: "2e86de")

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
                        Text("No Current Workout")
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
    @State private var ringPulse = false
    @State private var checkmarkAnimating = false
    @State private var checkmarkColor: Color = .white

    private let hydrationTips: [(icon: String, tip: String)] = [
        ("sunrise.fill", "Drink water first thing in the morning"),
        ("clock.fill", "Set reminders every 2 hours to stay hydrated"),
        ("fork.knife", "Have water before each meal to aid digestion"),
        ("figure.run", "Drink extra water before and after exercise")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background droplets falling continuously
                WaterDropletBackground()

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
                            // Large progress ring with animated glow
                            ZStack {
                                // Pulsing glow behind ring
                                Circle()
                                    .fill(Color.white.opacity(ringPulse ? 0.15 : 0.05))
                                    .frame(width: 180, height: 180)
                                    .blur(radius: 20)

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
                                    .shadow(color: waterManager.hasReachedGoal ? Color.accentGreen.opacity(0.6) : Color.accentBlue.opacity(0.4), radius: ringPulse ? 12 : 6)

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

                            // Status message with animated checkmark
                            if waterManager.hasReachedGoal {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(checkmarkColor)
                                        .scaleEffect(checkmarkAnimating ? 1.3 : 1.0)
                                        .shadow(color: checkmarkColor == .green ? Color.green.opacity(0.8) : Color.clear, radius: checkmarkAnimating ? 10 : 0)
                                    Text("Daily goal reached!")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                .scaleEffect(showCelebration ? 1.1 : 1.0)
                                .onAppear {
                                    animateGoalReached()
                                }
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
                // Start ring pulse animation
                startRingPulse()
            }
        }
    }

    // MARK: - Animations

    private func startRingPulse() {
        // Continuous subtle pulse for the ring glow
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            ringPulse = true
        }
    }

    private func animateGoalReached() {
        // Animate checkmark from white to green with pulse
        withAnimation(.easeInOut(duration: 0.3)) {
            checkmarkColor = .green
        }

        // Pulse animation - scale up and down 3 times
        let pulseDuration = 0.4
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * pulseDuration * 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkAnimating = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * pulseDuration * 2 + pulseDuration) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkAnimating = false
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
                size: CGFloat.random(in: 18...36),
                delay: Double(index) * 0.08,
                duration: Double.random(in: 1.5...2.5),
                opacity: Double.random(in: 0.6...0.95)
            )
        }
    }
}

// MARK: - Water Droplet Background (Continuous)
struct WaterDropletBackground: View {
    @State private var droplets: [ContinuousWaterDroplet] = []
    @State private var dropletCounter = 0
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(droplets) { droplet in
                    ContinuousDropletView(droplet: droplet, screenHeight: geometry.size.height)
                }
            }
            .onAppear {
                // Create initial batch of droplets
                for i in 0..<15 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                        addDroplet(in: geometry.size)
                    }
                }
            }
            .onReceive(timer) { _ in
                addDroplet(in: geometry.size)
                // Clean up old droplets
                droplets.removeAll { $0.createdAt.timeIntervalSinceNow < -5 }
            }
        }
        .allowsHitTesting(false)
    }

    private func addDroplet(in size: CGSize) {
        dropletCounter += 1
        let droplet = ContinuousWaterDroplet(
            id: dropletCounter,
            x: CGFloat.random(in: 20...(size.width - 20)),
            size: CGFloat.random(in: 16...32),
            duration: Double.random(in: 3.5...6.0),
            opacity: Double.random(in: 0.2...0.45),
            createdAt: Date()
        )
        droplets.append(droplet)
    }
}

struct ContinuousWaterDroplet: Identifiable {
    let id: Int
    let x: CGFloat
    let size: CGFloat
    let duration: Double
    let opacity: Double
    let createdAt: Date
}

struct ContinuousDropletView: View {
    let droplet: ContinuousWaterDroplet
    let screenHeight: CGFloat
    @State private var yOffset: CGFloat = -50

    var body: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: droplet.size))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.accentBlue.opacity(droplet.opacity), Color.accentTeal.opacity(droplet.opacity * 0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .position(x: droplet.x, y: yOffset)
            .onAppear {
                withAnimation(.linear(duration: droplet.duration)) {
                    yOffset = screenHeight + 50
                }
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

// MARK: - Cached DateFormatters (Performance: avoid recreating on every render)
private enum CachedFormatters {
    static let dateString: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let day: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    static let date: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()
}

// MARK: - Wallet Style Components

// MARK: - Stats Grid Section (Dashboard Style)

struct StatsGridSection: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var selectedTab: Tab

    private var recoveryScore: Int {
        healthKitManager.calculateOverallScore()
    }

    private var hrvValue: Int {
        guard let hrv = healthKitManager.healthData.hrv else { return 0 }
        return Int(hrv)
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1fh", hours)
    }

    // Colors from HTML design
    private let cardBg = Color(hex: "141414")
    private let cardBorder = Color.white.opacity(0.06)
    private let coral = Color(hex: "ff6b6b")
    private let coralDark = Color(hex: "e85555")
    private let teal = Color(hex: "00d2d3")
    private let tealDark = Color(hex: "01a3a4")
    private let cyan = Color(hex: "54a0ff")
    private let textMuted = Color(hex: "666666")

    var body: some View {
        HStack(spacing: 12) {
            // Recovery Card
            DashboardStatCard(
                icon: "heart",
                iconColor: coral,
                iconBg: coral.opacity(0.15),
                value: "\(recoveryScore)",
                label: "RECOVERY",
                accentGradient: [coralDark, coral],
                action: { selectedTab = .health }
            )

            // HRV Card
            DashboardStatCard(
                icon: "waveform.path.ecg",
                iconColor: teal,
                iconBg: teal.opacity(0.15),
                value: hrvValue > 0 ? "\(hrvValue)" : "--",
                label: "HRV",
                accentGradient: [tealDark, teal],
                action: { selectedTab = .health }
            )

            // Sleep Card
            DashboardStatCard(
                icon: "moon.fill",
                iconColor: cyan,
                iconBg: cyan.opacity(0.15),
                value: sleepValue,
                label: "SLEEP",
                accentGradient: [cyan, Color(hex: "2e86de")],
                action: { selectedTab = .health }
            )
        }
    }
}

struct DashboardStatCard: View {
    let icon: String
    let iconColor: Color
    let iconBg: Color
    let value: String
    let label: String
    let accentGradient: [Color]
    var action: (() -> Void)? = nil

    private let cardBg = Color(hex: "141414")
    private let cardBorder = Color.white.opacity(0.06)
    private let textMuted = Color(hex: "666666")

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 10) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBg)
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                // Value
                Text(value)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(iconColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Label
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .overlay(alignment: .bottom) {
                // Bottom accent bar
                LinearGradient(
                    colors: accentGradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 20
                    )
                )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekly Activity Section

struct DayActivity {
    let day: String
    let minutes: Int
    let isToday: Bool
}

struct WeeklyActivitySection: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var selectedTab: Tab

    @State private var selectedTimeframe = 0 // 0: Week, 1: Month, 2: Year

    private let cardBg = Color(hex: "141414")
    private let cardBorder = Color.white.opacity(0.06)
    private let teal = Color(hex: "00d2d3")
    private let sage = Color(hex: "1dd1a1")
    private let textPrimary = Color.white
    private let textMuted = Color(hex: "666666")

    // Mock data - replace with actual workout data
    private var weeklyData: [DayActivity] {
        [
            DayActivity(day: "Sun", minutes: 65, isToday: false),
            DayActivity(day: "Mon", minutes: 45, isToday: false),
            DayActivity(day: "Tue", minutes: 95, isToday: false),
            DayActivity(day: "Wed", minutes: 0, isToday: true),
            DayActivity(day: "Thu", minutes: 0, isToday: false),
            DayActivity(day: "Fri", minutes: 0, isToday: false),
            DayActivity(day: "Sat", minutes: 0, isToday: false)
        ]
    }

    private var totalMinutes: Int {
        weeklyData.reduce(0) { $0 + $1.minutes }
    }

    private var workoutCount: Int {
        weeklyData.filter { $0.minutes > 0 }.count
    }

    private var maxMinutes: Int {
        max(weeklyData.map { $0.minutes }.max() ?? 100, 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Weekly Activity")
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundStyle(textPrimary)

                Spacer()

                Button {
                    selectedTab = .progress
                } label: {
                    Text("Details")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(teal)
                }
            }

            // Chart Card
            VStack(spacing: 20) {
                // Timeframe tabs
                HStack(spacing: 8) {
                    ForEach(["Week", "Month", "Year"].indices, id: \.self) { index in
                        Button {
                            selectedTimeframe = index
                        } label: {
                            Text(["Week", "Month", "Year"][index])
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedTimeframe == index ? Color(hex: "000000") : textMuted)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedTimeframe == index ? textPrimary : Color.clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }

                // Bar Chart
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(weeklyData.indices, id: \.self) { index in
                        let data = weeklyData[index]
                        let barHeight = data.minutes > 0 ? CGFloat(data.minutes) / CGFloat(maxMinutes) * 100 : 0

                        VStack(spacing: 8) {
                            // Bar
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    data.minutes > 0 ?
                                    LinearGradient(colors: [teal, sage], startPoint: .bottom, endPoint: .top) :
                                    LinearGradient(colors: [teal.opacity(0.2), teal.opacity(0.2)], startPoint: .bottom, endPoint: .top)
                                )
                                .frame(width: 28, height: max(barHeight, 4))

                            // Day label
                            Text(data.day)
                                .font(.system(size: 11, weight: data.isToday ? .semibold : .medium))
                                .foregroundStyle(data.isToday ? textPrimary : textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)

                // Stats row
                HStack(spacing: 0) {
                    ChartStat(value: "\(totalMinutes)", label: "MINUTES")
                    Spacer()
                    ChartStat(value: "\(workoutCount)", label: "WORKOUTS")
                    Spacer()
                    ChartStat(value: "12", label: "DAY STREAK") // TODO: Calculate actual streak
                }
                .padding(.top, 16)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(cardBorder)
                        .frame(height: 1)
                }
            }
            .padding(20)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(cardBorder, lineWidth: 1)
            )
        }
    }
}

struct ChartStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(Color(hex: "666666"))
        }
    }
}

struct PercentageChangeBadge: View {
    let value: Double

    private var isPositive: Bool { value >= 0 }

    var body: some View {
        Text(String(format: "%@%.1f%%", isPositive ? "+" : "", value))
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isPositive ? Color(hex: "22C55E") : Color(hex: "EF4444"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (isPositive ? Color(hex: "22C55E") : Color(hex: "EF4444")).opacity(0.15)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MetricListRow: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let subtitle: String
    let value: String
    let change: Double?
    var action: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: iconGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6B7280"))
                }

                Spacer()

                // Values
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    if let change = change {
                        Text(String(format: "%@%.1f%%", change >= 0 ? "+" : "", change))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(change >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "16161F"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct MetricListSection: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var selectedTab: Tab

    private var recoveryScore: Int {
        healthKitManager.calculateOverallScore()
    }

    private var hrvValue: String {
        guard let hrv = healthKitManager.healthData.hrv else { return "--" }
        return "\(Int(hrv)) ms"
    }

    private var sleepValue: String {
        guard let hours = healthKitManager.healthData.sleepHours else { return "--" }
        return String(format: "%.1f hrs", hours)
    }

    private var stepsValue: String {
        guard let steps = healthKitManager.healthData.steps else { return "--" }
        return NumberFormatter.localizedString(from: NSNumber(value: steps), number: .decimal)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sort row header
            HStack {
                Text("Sorted by importance")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6B7280"))

                Spacer()

                HStack(spacing: 4) {
                    Text("Today")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "6B7280"))
                }
            }
            .padding(.vertical, 12)

            // Metric rows
            VStack(spacing: 8) {
                MetricListRow(
                    icon: "heart.fill",
                    iconGradient: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                    title: "Recovery Score",
                    subtitle: "Current",
                    value: "\(recoveryScore)",
                    change: 4.2,
                    action: { selectedTab = .health }
                )

                MetricListRow(
                    icon: "waveform.path.ecg",
                    iconGradient: [Color(hex: "8B5CF6"), Color(hex: "7C3AED")],
                    title: "HRV",
                    subtitle: "Heart Rate Variability",
                    value: hrvValue,
                    change: 3.9,
                    action: { selectedTab = .health }
                )

                MetricListRow(
                    icon: "moon.fill",
                    iconGradient: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
                    title: "Sleep",
                    subtitle: "Last night",
                    value: sleepValue,
                    change: -12.5,
                    action: { selectedTab = .health }
                )

                MetricListRow(
                    icon: "figure.walk",
                    iconGradient: [Color(hex: "F97316"), Color(hex: "EA580C")],
                    title: "Steps",
                    subtitle: "Today",
                    value: stepsValue,
                    change: 24.1,
                    action: { selectedTab = .progress }
                )
            }
        }
    }
}

// MARK: - Quick Actions FAB

struct FABAction: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
}

struct QuickActionsFAB: View {
    @Binding var selectedTab: Tab
    let onCheckIn: () -> Void
    let onWaterIntake: () -> Void

    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var isExpanded = false
    @State private var showBackground = false

    private var actions: [FABAction] {
        [
            FABAction(
                icon: "checkmark.circle.fill",
                label: "Check-In",
                color: Color(hex: "ff6b6b"),
                action: {
                    themeManager.mediumImpact()
                    onCheckIn()
                    collapse()
                }
            ),
            FABAction(
                icon: "drop.fill",
                label: "Water",
                color: Color(hex: "54a0ff"),
                action: {
                    themeManager.mediumImpact()
                    onWaterIntake()
                    collapse()
                }
            ),
            FABAction(
                icon: "figure.highintensity.intervaltraining",
                label: "Exercises",
                color: Color(hex: "ff9f43"),
                action: {
                    themeManager.mediumImpact()
                    selectedTab = .programs
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigationState.showExercises = true
                    }
                    collapse()
                }
            ),
            FABAction(
                icon: "flag.checkered",
                label: "Challenges",
                color: Color(hex: "feca57"),
                action: {
                    themeManager.mediumImpact()
                    selectedTab = .programs
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigationState.showChallenges = true
                    }
                    collapse()
                }
            )
        ]
    }

    var body: some View {
        ZStack {
            // Dimmed background when expanded
            if showBackground {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        collapse()
                    }
                    .transition(.opacity)
            }

            // FAB and menu positioned at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    ZStack(alignment: .bottom) {
                        // Action items
                        VStack(spacing: 16) {
                            ForEach(Array(actions.enumerated().reversed()), id: \.element.id) { index, action in
                                FABActionItem(
                                    action: action,
                                    isVisible: isExpanded,
                                    delay: Double(actions.count - 1 - index) * 0.05
                                )
                            }
                        }
                        .padding(.bottom, 70)
                        .opacity(isExpanded ? 1 : 0)

                        // Main FAB button
                        Button {
                            themeManager.mediumImpact()
                            toggle()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: isExpanded
                                                ? [Color(hex: "576574"), Color(hex: "474f59")]
                                                : [Color(hex: "54a0ff"), Color(hex: "2e86de")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(
                                        color: isExpanded
                                            ? Color.black.opacity(0.3)
                                            : Color(hex: "54a0ff").opacity(0.4),
                                        radius: isExpanded ? 8 : 12,
                                        y: 4
                                    )

                                Image(systemName: "plus")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundStyle(.white)
                                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isExpanded ? "Close quick actions" : "Open quick actions")
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showBackground)
    }

    private func toggle() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    private func expand() {
        showBackground = true
        isExpanded = true
    }

    private func collapse() {
        isExpanded = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if !isExpanded {
                showBackground = false
            }
        }
    }
}

struct FABActionItem: View {
    let action: FABAction
    let isVisible: Bool
    let delay: Double

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            // Label
            Text(action.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(hex: "1a1a1a"))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                )

            // Icon button
            Button {
                action.action()
            } label: {
                ZStack {
                    Circle()
                        .fill(action.color)
                        .frame(width: 48, height: 48)
                        .shadow(color: action.color.opacity(0.4), radius: 8, y: 2)

                    Image(systemName: action.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .scaleEffect(appeared ? 1 : 0.8)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                        appeared = true
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    appeared = false
                }
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
