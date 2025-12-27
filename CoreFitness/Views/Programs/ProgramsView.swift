import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    @State private var showCreateProgram = false
    @State private var showAIWorkoutCreation = false
    @State private var showImportWorkout = false
    @State private var showExerciseLibrary = false
    @State private var showChallenges = false
    @State private var showSavedPrograms = false
    @State private var animationStage = 0

    // Get active challenge
    private var activeChallenge: Challenge? {
        challenges.first { $0.isActive && !$0.isCompleted }
    }

    // Get current workout
    private var currentWorkout: Workout? {
        workouts.first
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header
                        ProgramsHeader()
                            .id("top")
                            .opacity(animationStage >= 1 ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (animationStage >= 1 ? 0 : 10))
                            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: animationStage)

                    // MARK: - Quick Create Actions
                    QuickCreateActions(
                        onCreateProgram: { showCreateProgram = true },
                        onAICreate: { showAIWorkoutCreation = true },
                        onImport: { showImportWorkout = true }
                    )
                    .opacity(animationStage >= 2 ? 1 : 0)
                    .offset(y: reduceMotion ? 0 : (animationStage >= 2 ? 0 : 15))
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: animationStage)

                    // MARK: - Active Workout Hero Card
                    if let workout = currentWorkout {
                        ActiveWorkoutHeroCard(workout: workout)
                            .opacity(animationStage >= 3 ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (animationStage >= 3 ? 0 : 15))
                            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: animationStage)
                    }

                    // MARK: - Active Challenge Card
                    if let challenge = activeChallenge {
                        ActiveChallengeHeroCard(challenge: challenge, onTap: { showChallenges = true })
                            .opacity(animationStage >= 4 ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (animationStage >= 4 ? 0 : 15))
                            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.15), value: animationStage)
                    }

                    // MARK: - Library Section
                    VStack(spacing: 12) {
                        LibrarySectionHeader(title: "Library")
                            .opacity(animationStage >= 5 ? 1 : 0)
                            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: animationStage)

                        LibraryGrid(
                            workoutCount: workouts.count,
                            onMyPrograms: { showSavedPrograms = true },
                            onExercises: { showExerciseLibrary = true },
                            onChallenges: { showChallenges = true }
                        )
                        .opacity(animationStage >= 5 ? 1 : 0)
                        .offset(y: reduceMotion ? 0 : (animationStage >= 5 ? 0 : 10))
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.25), value: animationStage)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
                .scrollIndicators(.hidden)
                .background(Color(.systemGroupedBackground))
                .toolbar(.hidden, for: .navigationBar)
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
                    if newTab == .programs {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("top", anchor: .top)
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
        }
    }
}

// MARK: - Programs Header
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

// MARK: - Active Workout Hero Card
private struct ActiveWorkoutHeroCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let workout: Workout

    @State private var showWorkoutExecution = false
    @State private var isPressed = false

    // Pine green gradient
    private let gradientStart = Color(hex: "2d6a4f")
    private let gradientEnd = Color(hex: "1b4332")

    var body: some View {
        Button {
            themeManager.mediumImpact()
            showWorkoutExecution = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Top section with icon and status
                HStack(alignment: .top) {
                    // Left: Icon and info
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 56, height: 56)

                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT WORKOUT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .tracking(0.5)
                                .foregroundStyle(.white.opacity(0.7))

                            Text(workout.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    // Right: Play button
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)

                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(gradientStart)
                    }
                }
                .padding(20)

                // Bottom stats bar
                HStack(spacing: 0) {
                    WorkoutStatPill(icon: "dumbbell.fill", value: "\(workout.exerciseCount)", label: "Exercises")

                    Divider()
                        .frame(height: 24)
                        .background(Color.white.opacity(0.2))

                    WorkoutStatPill(icon: "clock.fill", value: "\(workout.estimatedDuration)", label: "Minutes")

                    Divider()
                        .frame(height: 24)
                        .background(Color.white.opacity(0.2))

                    WorkoutStatPill(icon: "chart.bar.fill", value: workout.difficulty.shortName, label: "Level")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.15))
            }
            .background(
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: gradientStart.opacity(0.35), radius: 12, y: 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            WorkoutExecutionView(workout: workout)
                .environmentObject(workoutManager)
                .environmentObject(themeManager)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.name). \(workout.exerciseCount) exercises, \(workout.estimatedDuration) minutes")
        .accessibilityHint("Double tap to start workout")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Workout Stat Pill
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

// MARK: - Library Grid
private struct LibraryGrid: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let workoutCount: Int
    let onMyPrograms: () -> Void
    let onExercises: () -> Void
    let onChallenges: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Top row - My Programs (full width)
            LibraryCard(
                icon: "folder.fill",
                title: "My Programs",
                subtitle: "\(workoutCount) saved",
                gradient: [Color(hex: "475569"), Color(hex: "64748b")],
                action: onMyPrograms
            )

            // Bottom row - Exercises and Challenges
            HStack(spacing: 12) {
                LibraryCardCompact(
                    icon: "dumbbell.fill",
                    title: "Exercises",
                    gradient: [Color(hex: "0ea5e9"), Color(hex: "38bdf8")],
                    action: onExercises
                )

                LibraryCardCompact(
                    icon: "trophy.fill",
                    title: "Challenges",
                    gradient: [Color(hex: "22c55e"), Color(hex: "16a34a")],
                    action: onChallenges
                )
            }
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
    @State private var searchText = ""

    enum ProgramFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case userCreated = "My Programs"
        case aiGenerated = "AI Created"
        case imported = "Imported"
    }

    var filteredWorkouts: [Workout] {
        var programs = workouts

        switch selectedFilter {
        case .all: break
        case .active: programs = programs.filter { $0.isActive }
        case .userCreated: programs = programs.filter { $0.safeCreationType == .userCreated }
        case .aiGenerated: programs = programs.filter { $0.safeCreationType == .aiGenerated }
        case .imported: programs = programs.filter { $0.safeCreationType == .imported }
        }

        if !searchText.isEmpty {
            programs = programs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return programs
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Filter chips
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

                            Text("No programs found")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text("Try adjusting your filters or create a new program")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, prompt: "Search programs")
            .navigationTitle("My Programs")
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

// MARK: - Saved Workout Card
struct SavedWorkoutCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let workout: Workout

    @State private var isPressed = false
    @State private var showWorkoutExecution = false

    private var creationTypeColor: Color {
        switch workout.safeCreationType {
        case .userCreated: return Color(hex: "2d6a4f")
        case .aiGenerated: return Color(hex: "6366f1")
        case .imported: return Color(hex: "0ea5e9")
        case .preset: return Color(hex: "22c55e")
        }
    }

    private var difficultyColor: Color {
        switch workout.difficulty {
        case .beginner: return .accentGreen
        case .intermediate: return .accentOrange
        case .advanced: return .accentRed
        }
    }

    var body: some View {
        Button {
            themeManager.mediumImpact()
            showWorkoutExecution = true
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [creationTypeColor, creationTypeColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: workout.safeCreationType.icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if workout.isActive {
                            Text("ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentGreen)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 10) {
                        Label("\(workout.exerciseCount)", systemImage: "dumbbell.fill")
                        Label("\(workout.estimatedDuration)m", systemImage: "clock")
                        Text(workout.difficulty.rawValue)
                            .foregroundStyle(difficultyColor)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Play button
                ZStack {
                    Circle()
                        .fill(creationTypeColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(creationTypeColor)
                }
            }
            .padding(14)
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
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            WorkoutExecutionView(workout: workout)
                .environmentObject(workoutManager)
                .environmentObject(themeManager)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.name). \(workout.exerciseCount) exercises, \(workout.estimatedDuration) minutes")
        .accessibilityHint("Double tap to start workout")
        .accessibilityAddTraits(.isButton)
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
    @State private var showFilePicker = false
    @State private var importedFileName: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "0ea5e9").opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: "0ea5e9"))
                    }
                    .padding(.top, 32)

                    Text("Import Workout")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Import your workout routines from various file formats.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

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

                    if let fileName = importedFileName {
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

                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
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
                        importedFileName = url.lastPathComponent
                    }
                case .failure(let error):
                    print("Import error: \(error.localizedDescription)")
                }
            }
        }
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

                Button {
                    showFavoritesOnly = true
                    selectedCategory = nil
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: "0ea5e9"))
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

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? color : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise

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
                    ZStack {
                        Circle()
                            .fill(Color(hex: "0ea5e9").opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: exercise.safeCategory.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: "0ea5e9"))
                    }
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
}
