import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Programs View (Redesigned)
struct ProgramsView: View {

    // MARK: - Environment
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Bindings
    @Binding var selectedTab: Tab

    // MARK: - Queries
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]

    // MARK: - State
    @State private var selectedSegment: ProgramSegment = .dashboard
    @State private var showCreateProgram = false
    @State private var showAIWorkoutCreation = false
    @State private var showImportWorkout = false
    @State private var showExerciseLibrary = false
    @State private var showChallenges = false
    @State private var showSavedPrograms = false
    @State private var showProgramBrowser = false
    @State private var showCreateMenu = false
    @State private var animationStage = 0

    // Segment options
    enum ProgramSegment: String, CaseIterable {
        case dashboard = "Dashboard"
        case discover = "Discover"
        case library = "Library"
    }

    // Get active challenge
    private var activeChallenge: Challenge? {
        challenges.first { $0.isActive && !$0.isCompleted }
    }

    // Get current workout (active one)
    private var currentWorkout: Workout? {
        workouts.first { $0.isActive }
    }

    // True black background
    private let backgroundColor = Color.black

    var body: some View {
        NavigationStack {
            ZStack {
                // Pure black background
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Refined Header
                    programsHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    // MARK: - Segmented Control
                    segmentedPicker
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // MARK: - Content
                    ScrollView {
                        VStack(spacing: 28) {
                            switch selectedSegment {
                            case .dashboard:
                                dashboardContent
                            case .discover:
                                discoverContent
                            case .library:
                                libraryContent
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if reduceMotion {
                    animationStage = 5
                } else {
                    for stage in 1...5 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(stage) * 0.08) {
                            animationStage = stage
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCreateProgram) {
                CreateProgramView()
            }
            .fullScreenCover(isPresented: $showAIWorkoutCreation) {
                AIWorkoutCreationView()
            }
            .fullScreenCover(isPresented: $showImportWorkout) {
                ImportWorkoutView()
            }
            .fullScreenCover(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView()
            }
            .fullScreenCover(isPresented: $showChallenges) {
                ChallengesView()
            }
            .fullScreenCover(isPresented: $showSavedPrograms) {
                SavedProgramsDetailView()
            }
            .fullScreenCover(isPresented: $showProgramBrowser) {
                ProgramBrowserView()
            }
            .onChange(of: navigationState.showChallenges) { _, newValue in
                if newValue {
                    showChallenges = true
                    navigationState.showChallenges = false
                }
            }
            .onChange(of: navigationState.showExercises) { _, newValue in
                if newValue {
                    showExerciseLibrary = true
                    navigationState.showExercises = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showSavedWorkouts)) { _ in
                // Switch to Library tab and show saved workouts
                selectedSegment = .library
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showSavedPrograms = true
                }
            }
        }
    }

    // MARK: - Header
    private var programsHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Programs")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Create Menu Button
            Menu {
                Button {
                    showCreateProgram = true
                } label: {
                    Label("Create Workout", systemImage: "plus")
                }

                Button {
                    showAIWorkoutCreation = true
                } label: {
                    Label("AI Generate", systemImage: "sparkles")
                }

                Button {
                    showImportWorkout = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .opacity(animationStage >= 1 ? 1 : 0)
        .offset(y: reduceMotion ? 0 : (animationStage >= 1 ? 0 : -10))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animationStage)
    }

    // MARK: - Segmented Picker
    private var segmentedPicker: some View {
        HStack(spacing: 4) {
            ForEach(ProgramSegment.allCases, id: \.self) { segment in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedSegment = segment
                    }
                    themeManager.lightImpact()
                } label: {
                    Text(segment.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selectedSegment == segment ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSegment == segment
                                ? Color.white
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(animationStage >= 2 ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animationStage)
    }

    // MARK: - Dashboard Content
    private var dashboardContent: some View {
        VStack(spacing: 24) {
            // Workout Dashboard
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Workout Dashboard")
                WorkoutDashboardView()
            }
            .opacity(animationStage >= 3 ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animationStage)

            // Active Workout
            if let workout = currentWorkout {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Active Workout")
                    ActiveWorkoutHeroCard(workout: workout)
                }
                .opacity(animationStage >= 4 ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animationStage)
            } else {
                // Empty state for no active workout
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Active Workout")
                    emptyWorkoutCard
                }
                .opacity(animationStage >= 4 ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animationStage)
            }

            // Active Challenge
            if let challenge = activeChallenge {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Active Challenge")
                    ActiveChallengeHeroCard(challenge: challenge, onTap: { showChallenges = true })
                }
                .opacity(animationStage >= 5 ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animationStage)
            }
        }
    }

    // MARK: - Discover Content
    private var discoverContent: some View {
        VStack(spacing: 24) {
            // Quick Create Row (moved to top)
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Create")
                quickCreateRow
            }
            .opacity(animationStage >= 3 ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animationStage)

            // Browse Programs
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Find Your Program")
                DiscoverProgramsCard { showProgramBrowser = true }
            }
            .opacity(animationStage >= 4 ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animationStage)

            // Challenges
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Challenges")
                DiscoverChallengesCard(challengeCount: challenges.count) { showChallenges = true }
            }
            .opacity(animationStage >= 5 ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animationStage)
        }
    }

    // MARK: - Library Content
    private var libraryContent: some View {
        VStack(spacing: 24) {
            // My Programs
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    sectionHeader("My Workouts")
                    Spacer()
                    Text("\(workouts.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                LibraryRowCard(
                    icon: "folder.fill",
                    title: "Saved Workouts",
                    subtitle: "View all your programs",
                    accentColor: Color(hex: "6366f1")
                ) { showSavedPrograms = true }
            }
            .opacity(animationStage >= 3 ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animationStage)

            // Exercises
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Exercise Library")
                LibraryRowCard(
                    icon: "dumbbell.fill",
                    title: "Browse Exercises",
                    subtitle: "1300+ exercises with demos",
                    accentColor: Color(hex: "22c55e")
                ) { showExerciseLibrary = true }
            }
            .opacity(animationStage >= 4 ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animationStage)
        }
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.5))
            .textCase(.uppercase)
            .tracking(1)
    }

    // MARK: - Empty Workout Card
    private var emptyWorkoutCard: some View {
        Button {
            showProgramBrowser = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 56, height: 56)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("No Active Workout")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("Browse programs to get started")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Create Row
    private var quickCreateRow: some View {
        HStack(spacing: 12) {
            QuickCreatePill(icon: "plus", title: "Create", color: Color(hex: "2d6a4f")) {
                showCreateProgram = true
            }

            QuickCreatePill(icon: "sparkles", title: "AI", color: Color(hex: "8b5cf6")) {
                showAIWorkoutCreation = true
            }

            QuickCreatePill(icon: "square.and.arrow.down", title: "Import", color: Color(hex: "0ea5e9")) {
                showImportWorkout = true
            }
        }
    }
}

// MARK: - Discover Programs Card (Refined)
private struct DiscoverProgramsCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Top section with gradient
                HStack(spacing: 16) {
                    // Icon with glow
                    ZStack {
                        // Ambient glow
                        Circle()
                            .fill(Color(hex: "6366f1").opacity(0.3))
                            .frame(width: 70, height: 70)
                            .blur(radius: 20)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6366f1"), Color(hex: "8b5cf6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("100+ Programs")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Strength • Cardio • Yoga • HIIT")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    // Arrow
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(24)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(hex: "6366f1").opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Discover Challenges Card (Refined)
private struct DiscoverChallengesCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let challengeCount: Int
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            HStack(spacing: 16) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(Color(hex: "f97316").opacity(0.25))
                        .frame(width: 60, height: 60)
                        .blur(radius: 15)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "f97316"), Color(hex: "ea580c")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenges")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(challengeCount) available")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Quick Create Pill (Professional)
private struct QuickCreatePill: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            VStack(spacing: 12) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: color.opacity(0.4), radius: 8, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Library Row Card (Refined)
private struct LibraryRowCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            HStack(spacing: 16) {
                // Icon with subtle glow
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Programs Header (Legacy - kept for compatibility)
private struct ProgramsHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Programs")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Build your fitness journey")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Quick Create Actions
private struct QuickCreateActions: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let onCreateProgram: () -> Void
    let onAICreate: () -> Void
    let onImport: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickCreateButton(
                icon: "plus",
                title: "Create",
                gradient: [Color(hex: "2d6a4f"), Color(hex: "1b4332")],
                action: onCreateProgram
            )

            QuickCreateButton(
                icon: "sparkles",
                title: "AI Create",
                gradient: [Color(hex: "6366f1"), Color(hex: "8b5cf6")],
                action: onAICreate
            )

            QuickCreateButton(
                icon: "square.and.arrow.down",
                title: "Import",
                gradient: [Color(hex: "0ea5e9"), Color(hex: "06b6d4")],
                action: onImport
            )
        }
    }
}

// MARK: - Quick Create Button
private struct QuickCreateButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let icon: String
    let title: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: gradient[0].opacity(0.4), radius: 8, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Active Workout Hero Card (Matches HomeView ActiveWorkoutCard)
private struct ActiveWorkoutHeroCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Query private var allWorkouts: [Workout]

    let workout: Workout

    @State private var showWorkoutExecution = false
    @State private var isPressed = false

    /// Ensures this workout is active
    private func ensureWorkoutActive() {
        guard !workout.isActive else { return }
        // Deactivate all other workouts
        for w in allWorkouts where w.isActive && w.id != workout.id {
            w.isActive = false
        }
        workout.isActive = true
        workout.status = .active
        try? modelContext.save()
    }

    // Dynamic gradient based on workout goal
    private var gradientColors: (start: Color, end: Color) {
        switch workout.goal {
        case .strength, .muscleBuilding:
            return (Color(hex: "2d6a4f"), Color(hex: "1b4332"))  // Pine green
        case .cardio:
            return (Color(hex: "dc2626"), Color(hex: "991b1b"))  // Red
        case .fatLoss:
            return (Color(hex: "f59e0b"), Color(hex: "d97706"))  // Amber
        case .endurance:
            return (Color(hex: "0891b2"), Color(hex: "0e7490"))  // Cyan
        case .flexibility:
            return (Color(hex: "7c3aed"), Color(hex: "6d28d9"))  // Purple
        default:
            return (Color(hex: "2d6a4f"), Color(hex: "1b4332"))  // Pine green
        }
    }

    private var statusText: String {
        switch workout.status {
        case .created, .draft: return "READY TO START"
        case .active, .inProgress: return "CONTINUE WORKOUT"
        case .savedInMiddle: return "RESUME WORKOUT"
        case .completed: return "COMPLETED"
        default: return "START"
        }
    }

    var body: some View {
        Button {
            themeManager.mediumImpact()
            ensureWorkoutActive()
            showWorkoutExecution = true
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Workout icon based on goal
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: workout.goal.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Status + Type badges
                        HStack(spacing: 6) {
                            Text(statusText)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(0.5)
                                .foregroundStyle(.white.opacity(0.8))

                            if workout.workoutType == .challenge {
                                HStack(spacing: 3) {
                                    Image(systemName: "trophy.fill")
                                    Text("Challenge")
                                }
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow.opacity(0.2))
                                .clipShape(Capsule())
                            }

                            if workout.isTrophyEligible {
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                            }
                        }

                        // Title
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(1)

                        // Goal + Difficulty row
                        HStack(spacing: 8) {
                            Label(workout.goal.displayName, systemImage: workout.goal.icon)
                            Text("•")
                                .foregroundStyle(.white.opacity(0.5))
                            Text(workout.difficulty.displayName)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))

                        // Stats row
                        HStack(spacing: 14) {
                            Label("\(workout.exerciseCount)", systemImage: "dumbbell.fill")
                            Label("\(workout.estimatedDuration) min", systemImage: "clock")
                            if workout.totalSessions > 1 {
                                Label("\(workout.completedSessionsCount)/\(workout.totalSessions)", systemImage: "checkmark.circle")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    // Play/Go button
                    VStack(spacing: 6) {
                        // Creation type badge
                        Image(systemName: workout.creationType.icon)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 50)
                            Image(systemName: workout.status == .completed ? "arrow.counterclockwise" : "play.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(20)

                // Progress bar (if multi-session)
                if workout.totalSessions > 1 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.15))

                            Rectangle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: geo.size.width * CGFloat(workout.progressPercentage / 100))
                        }
                    }
                    .frame(height: 4)
                }

                // Stats footer (if workout has history)
                if workout.hasBeenStarted {
                    HStack(spacing: 16) {
                        if workout.totalCaloriesBurned > 0 {
                            Label("\(workout.totalCaloriesBurned) cal", systemImage: "flame.fill")
                        }
                        if workout.personalRecordsCount > 0 {
                            Label("\(workout.personalRecordsCount) PRs", systemImage: "star.fill")
                        }
                        Spacer()
                        if let lastDate = workout.lastSessionDate {
                            Text("Last: \(lastDate, style: .relative)")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.15))
                }
            }
            .background(
                LinearGradient(
                    colors: [gradientColors.start, gradientColors.end],
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
            WorkoutExecutionView(workout: workout)
                .environmentObject(workoutManager)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Workout Stat Pill (Legacy - kept for compatibility)
private struct WorkoutStatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Challenge Hero Card
private struct ActiveChallengeHeroCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let challenge: Challenge
    let onTap: () -> Void

    @State private var isPressed = false

    // Orange gradient
    private let gradientStart = Color(hex: "f97316")
    private let gradientEnd = Color(hex: "ea580c")

    private var totalParticipants: Int {
        challenge.participants?.count ?? 0
    }

    var body: some View {
        Button {
            themeManager.mediumImpact()
            onTap()
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
                    // Status badge
                    HStack(spacing: 8) {
                        Text("ACTIVE CHALLENGE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(0.5)
                            .foregroundStyle(.white.opacity(0.7))

                        if totalParticipants > 0 {
                            Text("•")
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(totalParticipants) participants")
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
            .shadow(color: gradientStart.opacity(0.3), radius: 10, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.name). Day \(challenge.currentDay). \(Int(challenge.progress * 100)) percent complete")
        .accessibilityHint("Double tap to view challenge")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Library Section Header
private struct LibrarySectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Spacer()
        }
    }
}

// MARK: - Browse Programs Card
private struct BrowseProgramsCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let action: () -> Void

    @State private var isPressed = false

    // Gradient colors
    private let gradientStart = Color(hex: "6366f1")
    private let gradientEnd = Color(hex: "8b5cf6")

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("DISCOVER")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(0.5)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("100+ Workout Programs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Strength, Cardio, Yoga & more")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Arrow
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: gradientStart.opacity(0.35), radius: 12, y: 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("Browse over 100 workout programs")
        .accessibilityHint("Double tap to browse programs")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Challenges Section Card
private struct ChallengesSectionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let challengeCount: Int
    let onTap: () -> Void

    @State private var isPressed = false

    // Green gradient
    private let gradientStart = Color(hex: "22c55e")
    private let gradientEnd = Color(hex: "16a34a")

    var body: some View {
        Button {
            themeManager.mediumImpact()
            onTap()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("COMPETE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(0.5)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("Fitness Challenges")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("\(challengeCount) challenges available")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Arrow
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: gradientStart.opacity(0.35), radius: 12, y: 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("View fitness challenges")
        .accessibilityHint("Double tap to browse challenges")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Library Grid
private struct LibraryGrid: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let workoutCount: Int
    let onMyPrograms: () -> Void
    let onExercises: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // My Programs (full width)
            LibraryCard(
                icon: "folder.fill",
                title: "My Programs",
                subtitle: "\(workoutCount) saved",
                gradient: [Color(hex: "475569"), Color(hex: "64748b")],
                action: onMyPrograms
            )

            // Exercises (full width)
            LibraryCard(
                icon: "dumbbell.fill",
                title: "Exercises",
                subtitle: "Browse & discover",
                gradient: [Color(hex: "0ea5e9"), Color(hex: "38bdf8")],
                action: onExercises
            )
        }
    }
}

// MARK: - Library Card
private struct LibraryCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Library Card Compact
private struct LibraryCardCompact: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let icon: String
    let title: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            themeManager.mediumImpact()
            action()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Saved Programs Detail View
struct SavedProgramsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @State private var selectedFilter: ProgramFilter = .all
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var selectedGoalFilter: GoalFilter = .all
    @State private var selectedWeek: Int = 0  // 0 = All weeks
    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var sortBySchedule = true  // Sort by session number if true

    // Source filter
    enum ProgramFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case favorites = "Favorites"
        case userCreated = "My Programs"
        case aiGenerated = "AI Created"
        case imported = "Imported"
        case challenges = "Challenges"
        case programWorkouts = "Program"  // New: filter to program workouts only
    }

    // Status filter
    enum StatusFilter: String, CaseIterable {
        case all = "Any Status"
        case created = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        case saved = "Saved"
    }

    // Goal filter
    enum GoalFilter: String, CaseIterable {
        case all = "Any Goal"
        case strength = "Strength"
        case cardio = "Cardio"
        case muscleBuilding = "Muscle"
        case fatLoss = "Fat Loss"
        case endurance = "Endurance"
        case flexibility = "Flexibility"
    }

    // Get available weeks from workouts
    private var availableWeeks: [Int] {
        let weeks = Set(workouts.compactMap { $0.programWeekNumber > 0 ? $0.programWeekNumber : nil })
        return Array(weeks).sorted()
    }

    // Get max weeks for current program
    private var maxWeeks: Int {
        workouts.map { $0.totalWeeks }.max() ?? 12
    }

    var filteredWorkouts: [Workout] {
        var programs = workouts.filter { !$0.isArchived && $0.status != .deleted }

        // Source filter
        switch selectedFilter {
        case .all: break
        case .active: programs = programs.filter { $0.isActive }
        case .favorites: programs = programs.filter { $0.isFavorite }
        case .userCreated: programs = programs.filter { $0.creationType == .userCreated }
        case .aiGenerated: programs = programs.filter { $0.creationType == .aiGenerated }
        case .imported: programs = programs.filter { $0.creationType == .imported }
        case .challenges: programs = programs.filter { $0.workoutType == .challenge }
        case .programWorkouts: programs = programs.filter { $0.programWeekNumber > 0 }
        }

        // Status filter
        switch selectedStatusFilter {
        case .all: break
        case .created: programs = programs.filter { $0.status == .created || $0.status == .draft }
        case .inProgress: programs = programs.filter { $0.status == .inProgress || $0.status == .active }
        case .completed: programs = programs.filter { $0.status == .completed }
        case .saved: programs = programs.filter { $0.status == .savedInMiddle }
        }

        // Goal filter
        switch selectedGoalFilter {
        case .all: break
        case .strength: programs = programs.filter { $0.goal == .strength }
        case .cardio: programs = programs.filter { $0.goal == .cardio }
        case .muscleBuilding: programs = programs.filter { $0.goal == .muscleBuilding }
        case .fatLoss: programs = programs.filter { $0.goal == .fatLoss }
        case .endurance: programs = programs.filter { $0.goal == .endurance }
        case .flexibility: programs = programs.filter { $0.goal == .flexibility }
        }

        // Week filter
        if selectedWeek > 0 {
            programs = programs.filter { $0.programWeekNumber == selectedWeek }
        }

        if !searchText.isEmpty {
            programs = programs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Sort by schedule order if enabled (session number) or by date
        if sortBySchedule {
            programs = programs.sorted {
                if $0.programSessionNumber != $1.programSessionNumber {
                    return $0.programSessionNumber < $1.programSessionNumber
                }
                return $0.createdAt > $1.createdAt
            }
        }

        return programs
    }

    private var activeFilterCount: Int {
        var count = 0
        if selectedFilter != .all { count += 1 }
        if selectedStatusFilter != .all { count += 1 }
        if selectedGoalFilter != .all { count += 1 }
        if selectedWeek > 0 { count += 1 }
        return count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary stats row
                    HStack(spacing: 12) {
                        WorkoutStatBubble(
                            count: workouts.filter { !$0.isArchived }.count,
                            label: "Total",
                            icon: "folder.fill",
                            color: .blue
                        )
                        WorkoutStatBubble(
                            count: workouts.filter { $0.status == .completed }.count,
                            label: "Completed",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        WorkoutStatBubble(
                            count: workouts.filter { $0.status == .inProgress || $0.status == .active }.count,
                            label: "Active",
                            icon: "play.circle.fill",
                            color: .orange
                        )
                        WorkoutStatBubble(
                            count: workouts.filter { $0.isFavorite }.count,
                            label: "Favorites",
                            icon: "heart.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)

                    // Source filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ProgramFilter.allCases, id: \.self) { filter in
                                ProgramFilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation(reduceMotion ? .none : .spring(response: 0.3)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Additional filter row (Status + Goal + Filter button)
                    HStack(spacing: 8) {
                        // Status picker
                        Menu {
                            ForEach(StatusFilter.allCases, id: \.self) { status in
                                Button {
                                    selectedStatusFilter = status
                                } label: {
                                    HStack {
                                        Text(status.rawValue)
                                        if selectedStatusFilter == status {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                Text(selectedStatusFilter.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedStatusFilter != .all ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedStatusFilter != .all ? Color(hex: "2d6a4f") : Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                        }

                        // Goal picker
                        Menu {
                            ForEach(GoalFilter.allCases, id: \.self) { goal in
                                Button {
                                    selectedGoalFilter = goal
                                } label: {
                                    HStack {
                                        Text(goal.rawValue)
                                        if selectedGoalFilter == goal {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "target")
                                Text(selectedGoalFilter.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedGoalFilter != .all ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedGoalFilter != .all ? Color(hex: "2d6a4f") : Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                        }

                        // Week picker (only show if there are program workouts)
                        if !availableWeeks.isEmpty {
                            Menu {
                                Button {
                                    selectedWeek = 0
                                } label: {
                                    HStack {
                                        Text("All Weeks")
                                        if selectedWeek == 0 {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }

                                Divider()

                                ForEach(1...maxWeeks, id: \.self) { week in
                                    Button {
                                        selectedWeek = week
                                    } label: {
                                        HStack {
                                            Text("Week \(week)")
                                            if selectedWeek == week {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text(selectedWeek > 0 ? "Week \(selectedWeek)" : "All Weeks")
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedWeek > 0 ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedWeek > 0 ? Color(hex: "2d6a4f") : Color(.tertiarySystemGroupedBackground))
                                .clipShape(Capsule())
                            }
                        }

                        Spacer()

                        // Clear filters button
                        if activeFilterCount > 0 {
                            Button {
                                withAnimation {
                                    selectedFilter = .all
                                    selectedStatusFilter = .all
                                    selectedGoalFilter = .all
                                    selectedWeek = 0
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Clear (\(activeFilterCount))")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Results count
                    HStack {
                        Text("\(filteredWorkouts.count) workout\(filteredWorkouts.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Programs list
                    LazyVStack(spacing: 12) {
                        ForEach(filteredWorkouts) { workout in
                            SavedWorkoutCard(workout: workout)
                        }
                    }
                    .padding(.horizontal)

                    if filteredWorkouts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 56))
                                .foregroundStyle(.tertiary)

                            Text("No workouts found")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text("Try adjusting your filters or create a new workout")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)

                            if activeFilterCount > 0 {
                                Button {
                                    withAnimation {
                                        selectedFilter = .all
                                        selectedStatusFilter = .all
                                        selectedGoalFilter = .all
                                        selectedWeek = 0
                                    }
                                } label: {
                                    Text("Clear All Filters")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, prompt: "Search workouts")
            .navigationTitle("My Workouts")
            .navigationBarTitleDisplayMode(.large)
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
}

// MARK: - Workout Stat Bubble
private struct WorkoutStatBubble: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Program Filter Chip
private struct ProgramFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "2d6a4f") : Color(.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Enhanced Saved Workout Card
struct SavedWorkoutCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Query private var allWorkouts: [Workout]

    let workout: Workout

    @State private var showWorkoutExecution = false
    @State private var showWorkoutDetail = false
    @State private var isPressed = false

    /// Activates this workout and deactivates all others
    private func activateWorkout() {
        // Deactivate all other workouts
        for w in allWorkouts where w.isActive && w.id != workout.id {
            w.isActive = false
        }
        // Activate this workout
        workout.isActive = true
        workout.status = .active
        try? modelContext.save()
    }

    // Dynamic gradient based on workout status
    private var gradientColors: (start: Color, end: Color) {
        switch workout.status {
        case .completed:
            return (Color(hex: "16a34a"), Color(hex: "15803d"))  // Green
        case .inProgress, .active:
            return (Color(hex: "2d6a4f"), Color(hex: "1b4332"))  // Pine green
        case .savedInMiddle:
            return (Color(hex: "f59e0b"), Color(hex: "d97706"))  // Amber
        case .abandoned:
            return (Color(hex: "6b7280"), Color(hex: "4b5563"))  // Gray
        default:
            return (Color(hex: "2d6a4f"), Color(hex: "1b4332"))  // Pine green
        }
    }

    private var statusText: String {
        switch workout.status {
        case .draft: return "DRAFT"
        case .created: return "READY TO START"
        case .active: return "ACTIVE"
        case .inProgress: return "IN PROGRESS"
        case .completed: return "COMPLETED"
        case .savedInMiddle: return "SAVED"
        case .abandoned: return "ABANDONED"
        case .deleted: return "DELETED"
        }
    }

    var body: some View {
        Button {
            themeManager.mediumImpact()
            activateWorkout()
            showWorkoutExecution = true
        } label: {
            VStack(spacing: 0) {
                // Main card content
                HStack(spacing: 14) {
                    // Workout icon with goal indicator
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 52, height: 52)
                        Image(systemName: workout.goal.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Top row: Status + Type + Trophy badges
                        HStack(spacing: 6) {
                            // Status badge
                            Text(statusText)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(0.5)
                                .foregroundStyle(.white.opacity(0.8))

                            // Workout type badge
                            if workout.workoutType != .regular {
                                WorkoutTypeBadge(type: workout.workoutType)
                            }

                            // Trophy badge
                            if workout.isTrophyEligible {
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                            }
                        }

                        // Title with optional week/session info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .lineLimit(1)

                            // Show week/session for program workouts
                            if workout.programWeekNumber > 0 {
                                HStack(spacing: 6) {
                                    Text("Week \(workout.programWeekNumber)")
                                        .fontWeight(.semibold)
                                    if workout.programSessionNumber > 0 {
                                        Text("•")
                                        Text("Session \(workout.programSessionNumber)")
                                    }
                                    if let scheduledDate = workout.scheduledDate {
                                        Text("•")
                                        Text(scheduledDate, style: .date)
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        // Goal and difficulty
                        HStack(spacing: 8) {
                            Label(workout.goal.displayName, systemImage: workout.goal.icon)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))

                            Text("•")
                                .foregroundStyle(.white.opacity(0.5))

                            Text(workout.difficulty.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        // Stats row
                        HStack(spacing: 12) {
                            Label("\(workout.exerciseCount)", systemImage: "dumbbell.fill")
                            Label("\(workout.estimatedDuration) min", systemImage: "clock")
                            if workout.totalSessions > 1 {
                                Label("\(workout.completedSessionsCount)/\(workout.totalSessions)", systemImage: "checkmark.circle")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    }

                    Spacer()

                    // Right side: Progress + Action
                    VStack(alignment: .trailing, spacing: 8) {
                        // Creation type icon
                        Image(systemName: workout.creationType.icon)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))

                        Spacer()

                        // Play button
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: workout.status == .completed ? "arrow.counterclockwise" : "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(16)

                // Progress bar (if multi-session workout)
                if workout.totalSessions > 1 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.15))

                            Rectangle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: geo.size.width * CGFloat(workout.progressPercentage / 100))
                        }
                    }
                    .frame(height: 4)
                }

                // Stats footer (if workout has been used)
                if workout.hasBeenStarted {
                    HStack(spacing: 16) {
                        if workout.totalCaloriesBurned > 0 {
                            Label("\(workout.totalCaloriesBurned) cal", systemImage: "flame.fill")
                        }
                        if workout.totalMinutesCompleted > 0 {
                            Label("\(workout.totalMinutesCompleted) min", systemImage: "timer")
                        }
                        if workout.personalRecordsCount > 0 {
                            Label("\(workout.personalRecordsCount) PRs", systemImage: "star.fill")
                        }
                        Spacer()
                        if let lastDate = workout.lastSessionDate {
                            Text(lastDate, style: .relative)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.15))
                }
            }
            .background(
                LinearGradient(
                    colors: [gradientColors.start, gradientColors.end],
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
        .contextMenu {
            Button {
                showWorkoutDetail = true
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button {
                activateWorkout()
                showWorkoutExecution = true
            } label: {
                Label("Start Workout", systemImage: "play.fill")
            }

            if workout.isFavorite {
                Button {
                    workout.isFavorite = false
                } label: {
                    Label("Remove from Favorites", systemImage: "heart.slash")
                }
            } else {
                Button {
                    workout.isFavorite = true
                } label: {
                    Label("Add to Favorites", systemImage: "heart")
                }
            }

            Divider()

            Button(role: .destructive) {
                workout.status = .deleted
                workout.isArchived = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            WorkoutExecutionView(workout: workout)
                .environmentObject(workoutManager)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showWorkoutDetail) {
            WorkoutDetailSheet(workout: workout)
        }
    }
}

// MARK: - Workout Type Badge
private struct WorkoutTypeBadge: View {
    let type: WorkoutType

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: type.icon)
            Text(type.displayName)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Workout Detail Sheet
private struct WorkoutDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let workout: Workout

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(goalColor.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: workout.goal.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(goalColor)
                        }

                        Text(workout.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = workout.workoutDescription {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Tags
                        if !workout.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(workout.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.accentColor.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()

                    // Info Cards
                    VStack(spacing: 12) {
                        // Status & Type
                        DetailInfoCard(title: "Status & Type") {
                            DetailRow(icon: workout.status.icon, label: "Status", value: workout.status.displayName, color: statusColor)
                            DetailRow(icon: workout.workoutType.icon, label: "Type", value: workout.workoutType.displayName)
                            DetailRow(icon: workout.creationType.icon, label: "Created", value: workout.creationType.displayName)
                        }

                        // Goal & Difficulty
                        DetailInfoCard(title: "Goal & Difficulty") {
                            DetailRow(icon: workout.goal.icon, label: "Goal", value: workout.goal.displayName, color: goalColor)
                            DetailRow(icon: "speedometer", label: "Difficulty", value: workout.difficulty.displayName, color: difficultyColor)
                            DetailRow(icon: workout.category.icon, label: "Category", value: workout.category.displayName)
                        }

                        // Duration & Schedule
                        DetailInfoCard(title: "Duration & Schedule") {
                            DetailRow(icon: "clock", label: "Session Length", value: "\(workout.sessionLength) min")
                            if workout.totalWeeks > 1 {
                                DetailRow(icon: "calendar", label: "Duration", value: "\(workout.totalWeeks) weeks")
                            }
                            if workout.totalDays > 1 {
                                DetailRow(icon: "calendar.day.timeline.left", label: "Days/Week", value: "\(workout.totalDays) days")
                            }
                            DetailRow(icon: "number", label: "Total Sessions", value: "\(workout.totalSessions)")
                        }

                        // Progress
                        if workout.hasBeenStarted {
                            DetailInfoCard(title: "Progress") {
                                DetailRow(icon: "checkmark.circle", label: "Completed", value: "\(workout.completedSessionsCount)/\(workout.totalSessions) sessions")
                                DetailRow(icon: "percent", label: "Progress", value: String(format: "%.0f%%", workout.progressPercentage))
                                if workout.totalCaloriesBurned > 0 {
                                    DetailRow(icon: "flame.fill", label: "Calories Burned", value: "\(workout.totalCaloriesBurned)")
                                }
                                if workout.totalMinutesCompleted > 0 {
                                    DetailRow(icon: "timer", label: "Total Time", value: "\(workout.totalMinutesCompleted) min")
                                }
                                if workout.personalRecordsCount > 0 {
                                    DetailRow(icon: "star.fill", label: "PRs Set", value: "\(workout.personalRecordsCount)")
                                }
                            }
                        }

                        // Trophy
                        if workout.isTrophyEligible {
                            DetailInfoCard(title: "Trophy") {
                                DetailRow(icon: "trophy.fill", label: "Trophy Eligible", value: "Yes", color: .yellow)
                                if let category = workout.trophyCategory {
                                    DetailRow(icon: "tag", label: "Category", value: category)
                                }
                                if let requirement = workout.trophyRequirement {
                                    DetailRow(icon: "target", label: "Requirement", value: requirement)
                                }
                                if let achievedAt = workout.trophyAchievedAt {
                                    DetailRow(icon: "checkmark.seal.fill", label: "Achieved", value: achievedAt.formatted(date: .abbreviated, time: .omitted))
                                }
                            }
                        }

                        // Dates
                        DetailInfoCard(title: "Dates") {
                            DetailRow(icon: "calendar.badge.plus", label: "Created", value: workout.createdAt.formatted(date: .abbreviated, time: .omitted))
                            if let startedAt = workout.firstStartedAt {
                                DetailRow(icon: "play.circle", label: "First Started", value: startedAt.formatted(date: .abbreviated, time: .omitted))
                            }
                            if let completedAt = workout.lastCompletedAt {
                                DetailRow(icon: "checkmark.circle", label: "Last Completed", value: completedAt.formatted(date: .abbreviated, time: .omitted))
                            }
                        }

                        // Exercises preview
                        if workout.exerciseCount > 0 {
                            DetailInfoCard(title: "Exercises (\(workout.exerciseCount))") {
                                ForEach(workout.sortedExercises.prefix(5)) { workoutExercise in
                                    if let exercise = workoutExercise.exercise {
                                        HStack {
                                            Image(systemName: exercise.muscleGroup.icon)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 24)
                                            Text(exercise.name)
                                                .font(.subheadline)
                                            Spacer()
                                            Text("\(workoutExercise.targetSets)×\(workoutExercise.targetReps)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                if workout.exerciseCount > 5 {
                                    Text("+ \(workout.exerciseCount - 5) more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var goalColor: Color {
        switch workout.goal {
        case .strength: return .blue
        case .cardio: return .red
        case .muscleBuilding: return .orange
        case .fatLoss: return .yellow
        case .endurance: return .green
        case .flexibility: return .purple
        default: return .accentColor
        }
    }

    private var statusColor: Color {
        switch workout.status {
        case .completed: return .green
        case .inProgress, .active: return .blue
        case .savedInMiddle: return .orange
        case .abandoned, .deleted: return .red
        default: return .secondary
        }
    }

    private var difficultyColor: Color {
        switch workout.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Detail Info Card
private struct DetailInfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                content
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Detail Row
private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .font(.subheadline)
    }
}

// MARK: - Placeholder Views
struct CreateProgramView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(hex: "2d6a4f").opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "plus.rectangle.on.folder")
                        .font(.system(size: 50))
                        .foregroundStyle(Color(hex: "2d6a4f"))
                }

                Text("Create Program")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Build a custom workout program by adding exercises and setting your schedule.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Coming Soon")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "2d6a4f"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AIWorkoutCreationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(hex: "6366f1").opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(Color(hex: "6366f1"))
                }

                Text("Create with AI")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Tell us your goals and we'll create a personalized workout program just for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Coming Soon")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "6366f1"), Color(hex: "8b5cf6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ImportWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showFilePicker = false
    @State private var importedFileName: String?
    @State private var isProcessing = false
    @State private var importSuccess = false
    @State private var errorMessage: String?

    // Naming step
    @State private var pendingWorkout: Workout?
    @State private var customWorkoutName: String = ""
    @State private var showNamingStep = false
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if showNamingStep {
                        // Naming step UI
                        namingStepContent
                    } else {
                        // Initial import UI
                        initialImportContent
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(showNamingStep ? "Name Your Workout" : "Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if showNamingStep {
                        Button("Cancel") {
                            cancelNaming()
                        }
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .plainText, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        parseWorkoutFile(from: url)
                    }
                case .failure(let error):
                    errorMessage = "Import error: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Initial Import Content
    private var initialImportContent: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "0ea5e9").opacity(0.15))
                    .frame(width: 100, height: 100)

                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if importSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: "0ea5e9"))
                }
            }
            .padding(.top, 32)

            Text(importSuccess ? "Import Successful!" : "Import Workout")
                .font(.title2)
                .fontWeight(.bold)

            Text(importSuccess ?
                 "Your workout has been added to My Programs." :
                 "Import your workout routines from various file formats.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if !importSuccess {
                VStack(spacing: 12) {
                    ImportOptionCard(
                        icon: "doc.text.fill",
                        title: "PDF Document",
                        subtitle: "Import from PDF files",
                        color: .accentRed
                    ) {
                        showFilePicker = true
                    }

                    ImportOptionCard(
                        icon: "tablecells.fill",
                        title: "CSV Spreadsheet",
                        subtitle: "Import from CSV files",
                        color: .accentGreen
                    ) {
                        showFilePicker = true
                    }
                }
                .padding(.horizontal)
            }

            if let fileName = importedFileName, importSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Imported: \(fileName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            if importSuccess {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "2d6a4f"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - Naming Step Content
    private var namingStepContent: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "0ea5e9").opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "pencil.line")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: "0ea5e9"))
            }
            .padding(.top, 32)

            Text("Name Your Workout")
                .font(.title2)
                .fontWeight(.bold)

            Text("Give your imported workout a custom name")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Name text field
            VStack(alignment: .leading, spacing: 8) {
                Text("Workout Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                TextField("Enter workout name", text: $customWorkoutName)
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isNameFieldFocused)
            }
            .padding(.horizontal)

            // Original filename hint
            if let fileName = importedFileName {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.secondary)
                    Text("Original: \(fileName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            Spacer()

            // Save button
            VStack(spacing: 12) {
                Button {
                    saveWorkout()
                } label: {
                    Text("Save Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(customWorkoutName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color(hex: "2d6a4f"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(customWorkoutName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    cancelNaming()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }

    private func parseWorkoutFile(from url: URL) {
        isProcessing = true
        errorMessage = nil

        // Get security-scoped access
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Unable to access file"
            isProcessing = false
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        let fileName = url.deletingPathExtension().lastPathComponent
        importedFileName = url.lastPathComponent

        // Create a workout from the imported file (but don't save yet)
        let workout = Workout(
            name: fileName,
            description: "Imported from \(url.lastPathComponent)",
            estimatedDuration: 45,
            difficulty: .intermediate,
            creationType: .imported
        )

        // Parse file content based on type
        do {
            let fileExtension = url.pathExtension.lowercased()

            if fileExtension == "csv" {
                try parseCSV(from: url, into: workout)
            } else if fileExtension == "pdf" {
                // For PDF, we'll create a placeholder - full PDF parsing would require PDFKit
                workout.workoutDescription = "Imported PDF workout. Add exercises manually."
            } else {
                // Plain text
                try parseTextFile(from: url, into: workout)
            }

            // Store the pending workout and show naming step
            pendingWorkout = workout
            customWorkoutName = fileName  // Pre-fill with the file name

            withAnimation {
                isProcessing = false
                showNamingStep = true
            }
        } catch {
            errorMessage = "Failed to parse file: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func saveWorkout() {
        guard let workout = pendingWorkout else { return }

        // Apply the custom name
        workout.name = customWorkoutName.trimmingCharacters(in: .whitespaces)

        // Now save to the database
        modelContext.insert(workout)
        do {
            try modelContext.save()
            themeManager.notifySuccess()
            withAnimation {
                showNamingStep = false
                importSuccess = true
            }
        } catch {
            errorMessage = "Failed to save workout: \(error.localizedDescription)"
        }
    }

    private func cancelNaming() {
        // Clear pending workout and go back
        pendingWorkout = nil
        customWorkoutName = ""
        withAnimation {
            showNamingStep = false
        }
    }

    private func parseCSV(from url: URL, into workout: Workout) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        // Skip header row if present
        let dataLines = lines.count > 1 && lines[0].lowercased().contains("exercise") ? Array(lines.dropFirst()) : lines

        for (index, line) in dataLines.enumerated() {
            let columns = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            if columns.isEmpty { continue }

            let exerciseName = columns[0]
            let sets = columns.count > 1 ? Int(columns[1]) ?? 3 : 3
            let reps = columns.count > 2 ? Int(columns[2]) ?? 10 : 10
            let weight = columns.count > 3 ? Double(columns[3]) : nil

            let workoutExercise = WorkoutExercise(
                order: index,
                targetSets: sets,
                targetReps: reps,
                targetWeight: weight,
                restDuration: 60
            )

            // Create exercise if needed
            let exercise = Exercise(
                name: exerciseName,
                muscleGroup: .fullBody,
                category: .strength,
                difficulty: .intermediate
            )
            modelContext.insert(exercise)
            workoutExercise.exercise = exercise
            workoutExercise.workout = workout
            modelContext.insert(workoutExercise)
        }
    }

    private func parseTextFile(from url: URL, into workout: Workout) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for (index, line) in lines.enumerated() {
            // Try to parse lines like "Bench Press 3x10" or "Squats - 4 sets of 8"
            let exerciseName = extractExerciseName(from: line)

            if !exerciseName.isEmpty {
                let workoutExercise = WorkoutExercise(
                    order: index,
                    targetSets: 3,
                    targetReps: 10,
                    targetWeight: nil,
                    restDuration: 60
                )

                let exercise = Exercise(
                    name: exerciseName,
                    muscleGroup: .fullBody,
                    category: .strength,
                    difficulty: .intermediate
                )
                modelContext.insert(exercise)
                workoutExercise.exercise = exercise
                workoutExercise.workout = workout
                modelContext.insert(workoutExercise)
            }
        }
    }

    private func extractExerciseName(from line: String) -> String {
        // Remove common patterns like "1.", "- ", numbers, etc.
        var name = line
        // Remove leading numbers and punctuation
        name = name.replacingOccurrences(of: "^[0-9]+[.\\)\\-\\s]*", with: "", options: .regularExpression)
        // Remove set/rep patterns like "3x10", "4 sets", etc.
        name = name.replacingOccurrences(of: "\\s*[0-9]+\\s*[xX]\\s*[0-9]+.*", with: "", options: .regularExpression)
        name = name.replacingOccurrences(of: "\\s*-?\\s*[0-9]+\\s*sets?.*", with: "", options: .regularExpression)
        return name.trimmingCharacters(in: .whitespaces)
    }
}

struct ImportOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedEquipment: Equipment?
    @State private var selectedDifficulty: Difficulty?
    @State private var showFavoritesOnly = false
    @State private var selectedExercise: Exercise?
    @State private var viewMode: ExerciseViewMode = .browse
    @State private var animationStage = 0
    @State private var showFavoritesSheet = false

    enum ExerciseViewMode {
        case browse, search
    }

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || exercise.safeCategory == selectedCategory
            let matchesMuscle = selectedMuscleGroup == nil || exercise.muscleGroup == selectedMuscleGroup
            let matchesEquipment = selectedEquipment == nil || exercise.equipment == selectedEquipment
            let matchesDifficulty = selectedDifficulty == nil || exercise.safeDifficulty == selectedDifficulty
            let matchesFavorites = !showFavoritesOnly || exercise.isFavorite
            return matchesSearch && matchesCategory && matchesMuscle && matchesEquipment && matchesDifficulty && matchesFavorites
        }
    }

    private var favoriteExercises: [Exercise] {
        exercises.filter { $0.isFavorite }
    }

    private func exerciseCount(for category: ExerciseCategory) -> Int {
        exercises.filter { $0.safeCategory == category }.count
    }

    private var hasActiveFilters: Bool {
        selectedMuscleGroup != nil || selectedEquipment != nil || selectedDifficulty != nil || showFavoritesOnly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if searchText.isEmpty && selectedCategory == nil {
                        // Browse Mode - Show categories
                        browseContent
                    } else {
                        // Filter/Search Mode - Show results
                        searchResultsContent
                    }
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showFavoritesSheet) {
                FavoritesSheet(exercises: favoriteExercises) { exercise in
                    showFavoritesSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedExercise = exercise
                    }
                }
            }
            .onAppear {
                if reduceMotion {
                    animationStage = 3
                } else {
                    for stage in 1...3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(stage) * 0.08) {
                            animationStage = stage
                        }
                    }
                }
            }
        }
    }

    // MARK: - Browse Content
    private var browseContent: some View {
        VStack(spacing: 24) {
            // Quick Stats Header
            quickStatsHeader
                .opacity(animationStage >= 1 ? 1 : 0)
                .offset(y: reduceMotion ? 0 : (animationStage >= 1 ? 0 : 10))
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: animationStage)

            // Favorites Section (if any)
            if !favoriteExercises.isEmpty {
                favoritesSection
                    .opacity(animationStage >= 2 ? 1 : 0)
                    .offset(y: reduceMotion ? 0 : (animationStage >= 2 ? 0 : 10))
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8).delay(0.05), value: animationStage)
            }

            // Categories Grid
            categoriesGrid
                .opacity(animationStage >= 3 ? 1 : 0)
                .offset(y: reduceMotion ? 0 : (animationStage >= 3 ? 0 : 10))
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8).delay(0.1), value: animationStage)

            // Quick Filters
            quickFiltersSection
                .opacity(animationStage >= 3 ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: animationStage)
        }
        .padding(.bottom, 100)
    }

    // MARK: - Quick Stats Header
    private var quickStatsHeader: some View {
        HStack(spacing: 16) {
            ExerciseStatBadge(
                value: "\(exercises.count)",
                label: "Total",
                icon: "dumbbell.fill",
                color: Color(hex: "0ea5e9")
            )

            ExerciseStatBadge(
                value: "\(favoriteExercises.count)",
                label: "Favorites",
                icon: "heart.fill",
                color: .accentRed
            )

            ExerciseStatBadge(
                value: "\(ExerciseCategory.allCases.count)",
                label: "Categories",
                icon: "square.grid.2x2.fill",
                color: Color(hex: "22c55e")
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Favorites Section
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.accentRed)
                Text("Favorites")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if favoriteExercises.count > 1 {
                    Button {
                        showFavoritesSheet = true
                    } label: {
                        Text("See All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(hex: "0ea5e9"))
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favoriteExercises.prefix(8)) { exercise in
                        FavoriteExerciseCard(exercise: exercise) {
                            selectedExercise = exercise
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Categories Grid
    private var categoriesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        count: exerciseCount(for: category)
                    ) {
                        themeManager.mediumImpact()
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Quick Filters Section
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Filters")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // By Muscle Group
                    QuickFilterButton(
                        title: "Muscle Group",
                        icon: "figure.arms.open",
                        color: Color(hex: "f97316")
                    ) {
                        // Show muscle group picker
                    }

                    // By Equipment
                    QuickFilterButton(
                        title: "Equipment",
                        icon: "dumbbell.fill",
                        color: Color(hex: "8b5cf6")
                    ) {
                        // Show equipment picker
                    }

                    // By Difficulty
                    QuickFilterButton(
                        title: "Difficulty",
                        icon: "chart.bar.fill",
                        color: Color(hex: "22c55e")
                    ) {
                        // Show difficulty picker
                    }

                    // Home Workouts
                    QuickFilterButton(
                        title: "Home",
                        icon: "house.fill",
                        color: Color(hex: "0ea5e9")
                    ) {
                        selectedEquipment = .bodyweight
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Search Results Content
    private var searchResultsContent: some View {
        VStack(spacing: 16) {
            // Active filters bar
            if selectedCategory != nil || hasActiveFilters {
                activeFiltersBar
            }

            // Results header
            HStack {
                Text("\(filteredExercises.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if selectedCategory != nil || hasActiveFilters {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            clearAllFilters()
                        }
                    } label: {
                        Text("Clear All")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(hex: "0ea5e9"))
                    }
                }
            }
            .padding(.horizontal)

            // Exercise list
            if filteredExercises.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredExercises) { exercise in
                        ExerciseListCard(exercise: exercise) {
                            selectedExercise = exercise
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Active Filters Bar
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = selectedCategory {
                    ActiveFilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        color: categoryColor(for: category)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = nil
                        }
                    }
                }

                if showFavoritesOnly {
                    ActiveFilterChip(
                        title: "Favorites",
                        icon: "heart.fill",
                        color: .accentRed
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            showFavoritesOnly = false
                        }
                    }
                }

                if let muscle = selectedMuscleGroup {
                    ActiveFilterChip(
                        title: muscle.displayName,
                        icon: "figure.arms.open",
                        color: Color(hex: "f97316")
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMuscleGroup = nil
                        }
                    }
                }

                if let equipment = selectedEquipment {
                    ActiveFilterChip(
                        title: equipment.displayName,
                        icon: "dumbbell.fill",
                        color: Color(hex: "8b5cf6")
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedEquipment = nil
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No exercises found")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Try adjusting your filters or search term")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Button {
                clearAllFilters()
            } label: {
                Text("Clear Filters")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0ea5e9"))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers
    private func clearAllFilters() {
        selectedCategory = nil
        selectedMuscleGroup = nil
        selectedEquipment = nil
        selectedDifficulty = nil
        showFavoritesOnly = false
        searchText = ""
    }

    private func categoryColor(for category: ExerciseCategory) -> Color {
        switch category {
        case .strength: return Color(hex: "0ea5e9")
        case .cardio: return .accentRed
        case .yoga: return Color(hex: "a78bfa")
        case .pilates: return Color(hex: "2dd4bf")
        case .hiit: return .accentOrange
        case .stretching: return .accentGreen
        case .running: return Color(hex: "fbbf24")
        case .cycling: return Color(hex: "60a5fa")
        case .swimming: return Color(hex: "22d3ee")
        case .calisthenics: return Color(hex: "f97316")
        }
    }
}

// MARK: - Exercise Stat Badge
private struct ExerciseStatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Card
private struct CategoryCard: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let category: ExerciseCategory
    let count: Int
    let action: () -> Void

    @State private var isPressed = false

    private var gradient: LinearGradient {
        let colors: [Color] = {
            switch category {
            case .strength: return [Color(hex: "0ea5e9"), Color(hex: "0284c7")]
            case .cardio: return [Color(hex: "ef4444"), Color(hex: "dc2626")]
            case .yoga: return [Color(hex: "a78bfa"), Color(hex: "8b5cf6")]
            case .pilates: return [Color(hex: "2dd4bf"), Color(hex: "14b8a6")]
            case .hiit: return [Color(hex: "f97316"), Color(hex: "ea580c")]
            case .stretching: return [Color(hex: "22c55e"), Color(hex: "16a34a")]
            case .running: return [Color(hex: "fbbf24"), Color(hex: "f59e0b")]
            case .cycling: return [Color(hex: "60a5fa"), Color(hex: "3b82f6")]
            case .swimming: return [Color(hex: "22d3ee"), Color(hex: "06b6d4")]
            case .calisthenics: return [Color(hex: "fb923c"), Color(hex: "f97316")]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: category.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }

                Spacer()

                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(height: 110)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Favorite Exercise Card
private struct FavoriteExerciseCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let exercise: Exercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "0ea5e9").opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: exercise.safeCategory.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "0ea5e9"))
                }

                Text(exercise.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(exercise.safeCategory.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Favorites Sheet
private struct FavoritesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(exercises) { exercise in
                        FavoriteGridCard(exercise: exercise) {
                            onSelect(exercise)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Favorite Grid Card
private struct FavoriteGridCard: View {
    let exercise: Exercise
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.accentRed.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: exercise.safeCategory.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Color.accentRed)
                    }

                    Spacer()

                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentRed)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(exercise.safeCategory.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(height: 130)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Quick Filter Button
private struct QuickFilterButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Filter Chip
private struct ActiveFilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}


// MARK: - Exercise List Card
struct ExerciseListCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise
    let onTap: () -> Void

    private var difficultyColor: Color {
        switch exercise.safeDifficulty {
        case .beginner: return .accentGreen
        case .intermediate: return .accentOrange
        case .advanced: return .accentRed
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "0ea5e9").opacity(0.15))
                        .frame(width: 46, height: 46)

                    Image(systemName: exercise.safeCategory.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "0ea5e9"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(exercise.safeDifficulty.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(difficultyColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor.opacity(0.15))
                            .clipShape(Capsule())

                        Text(exercise.equipment.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    exercise.isFavorite.toggle()
                    try? modelContext.save()
                    themeManager.lightImpact()
                } label: {
                    Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(exercise.isFavorite ? Color.accentRed : Color.secondary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise

    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var showingStartPosition = true  // For cycling animation

    private var difficultyColor: Color {
        switch exercise.safeDifficulty {
        case .beginner: return .accentGreen
        case .intermediate: return .accentOrange
        case .advanced: return .accentRed
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise Demo - Cycling Animation
                    VStack(spacing: 6) {
                        // Single image container with cycling animation
                        ZStack {
                            // Current position image
                            if let imageName = showingStartPosition
                                ? exercise.startImageName
                                : exercise.endImageName,
                               UIImage(named: imageName) != nil {
                                Image(imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .id(imageName)
                                    .transition(.opacity)
                            } else {
                                // Fallback when no image
                                VStack(spacing: 8) {
                                    Image(systemName: exercise.safeCategory.icon)
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(showingStartPosition ? Color(hex: "0ea5e9").opacity(0.7) : Color.accentGreen.opacity(0.7))
                                    Text(showingStartPosition ? "Start" : "End")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .frame(height: 240)
                        .onTapGesture {
                            selectedImageIndex = 0  // Always start with start position
                            showImageViewer = true
                            themeManager.lightImpact()
                        }
                        .onAppear {
                            startCyclingAnimation()
                        }

                        // Position indicator and tap hint
                        HStack(spacing: 12) {
                            // Position dots
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(showingStartPosition ? Color.primary : Color.secondary.opacity(0.4))
                                    .frame(width: 6, height: 6)
                                Circle()
                                    .fill(!showingStartPosition ? Color.primary : Color.secondary.opacity(0.4))
                                    .frame(width: 6, height: 6)
                            }

                            Spacer()

                            // Tap to view hint
                            Button {
                                selectedImageIndex = 0  // Always start with start position
                                showImageViewer = true
                                themeManager.lightImpact()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 10, weight: .medium))
                                    Text("Enlarge")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            Label(exercise.safeDifficulty.displayName, systemImage: "chart.bar.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(difficultyColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(difficultyColor.opacity(0.15))
                                .clipShape(Capsule())

                            Label(exercise.safeCategory.displayName, systemImage: exercise.safeCategory.icon)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color(hex: "0ea5e9"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: "0ea5e9").opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    // Stats
                    HStack(spacing: 12) {
                        ExerciseStatCard(icon: exercise.safeLocation.icon, value: exercise.safeLocation.displayName, label: "Location")
                        ExerciseStatCard(icon: "flame.fill", value: "\(exercise.caloriesPerMinute)", label: "Cal/min")
                        ExerciseStatCard(icon: "wrench.and.screwdriver", value: exercise.equipment.displayName, label: "Equipment")
                    }
                    .padding(.horizontal)

                    // Instructions
                    if let instructions = exercise.instructions {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to Perform")
                                .font(.headline)

                            Text(instructions)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    // Action button
                    Button {
                        exercise.isFavorite.toggle()
                        try? modelContext.save()
                        themeManager.mediumImpact()
                    } label: {
                        HStack {
                            Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                            Text(exercise.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                        }
                        .font(.headline)
                        .foregroundStyle(exercise.isFavorite ? .white : .accentRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(exercise.isFavorite ? Color.accentRed : Color.accentRed.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .fullScreenCover(isPresented: $showImageViewer) {
                ExerciseImageViewer(
                    startImageName: exercise.startImageName,
                    endImageName: exercise.endImageName,
                    exerciseName: exercise.name,
                    selectedIndex: $selectedImageIndex
                )
            }
        }
    }

    private func startCyclingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                showingStartPosition.toggle()
            }
        }
    }
}

struct ExerciseStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(hex: "0ea5e9"))
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProgramsView(selectedTab: .constant(.programs))
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
        .environmentObject(NavigationState())
        .environmentObject(UserProfileManager())
}
