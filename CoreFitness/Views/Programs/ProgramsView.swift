import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProgramsView: View {

    // MARK: - State
    @State private var showCreateProgram = false
    @State private var showAIWorkoutCreation = false
    @State private var showImportWorkout = false
    @State private var showExerciseLibrary = false
    @State private var showChallenges = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with + button
                    ViewHeader("Programs") {
                        Button {
                            showCreateProgram = true
                        } label: {
                            Label("Create Program", systemImage: "plus")
                        }

                        Button {
                            showAIWorkoutCreation = true
                        } label: {
                            Label("AI Create", systemImage: "sparkles")
                        }

                        Button {
                            showImportWorkout = true
                        } label: {
                            Label("Import", systemImage: "doc.badge.plus")
                        }
                    }

                    // Current Programs Card (Combined)
                    CurrentProgramsCard(onChallengeTap: { showChallenges = true })

                    // Exercises Card
                    ExercisesCard(onTap: { showExerciseLibrary = true })

                    // My Programs Card
                    SavedProgramsSection()

                    // Challenges Card
                    ChallengesSectionCard(onTap: { showChallenges = true })
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showCreateProgram) {
                CreateProgramView()
                    .background(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $showAIWorkoutCreation) {
                AIWorkoutCreationView()
                    .background(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $showImportWorkout) {
                ImportWorkoutView()
                    .background(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView()
                    .background(.ultraThinMaterial)
            }
            .fullScreenCover(isPresented: $showChallenges) {
                ChallengesView()
                    .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Exercises Card
struct ExercisesCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            themeManager.mediumImpact()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0ea5e9"), Color(hex: "38bdf8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Library")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Browse all exercises")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenges Card
struct ChallengesCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            themeManager.mediumImpact()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "f97316"), Color(hex: "fb923c")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenges")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Compete with friends")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("View All")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "f97316"))
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {

    let onAICreate: () -> Void
    let onImportWorkout: () -> Void
    let onExerciseLibrary: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            QuickActionCard(
                title: "AI Create",
                icon: "sparkles",
                gradientColors: [Color(hex: "0ea5e9"), Color(hex: "06b6d4")], // Cyan/Teal
                action: onAICreate
            )

            QuickActionCard(
                title: "Import",
                icon: "doc.badge.plus",
                gradientColors: [Color(hex: "f97316"), Color(hex: "fb923c")], // Orange
                action: onImportWorkout
            )

            QuickActionCard(
                title: "Exercises",
                icon: "dumbbell.fill",
                gradientColors: [Color(hex: "3b82f6"), Color(hex: "60a5fa")], // Blue
                action: onExerciseLibrary
            )
        }
    }
}

struct QuickActionCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            themeManager.mediumImpact()
            action()
        }) {
            VStack(spacing: 8) {
                // Gradient icon background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Current Programs Card (Combined Workout + Challenge)
struct CurrentProgramsCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.startDate, order: .reverse) private var challenges: [Challenge]
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]

    let onChallengeTap: () -> Void

    @State private var showWorkoutExecution = false
    @State private var showStartConfirmation = false
    @State private var selectedWorkout: Workout?

    // Get active challenge from SwiftData (same logic as ChallengesView)
    private var activeChallenge: Challenge? {
        challenges.first { $0.isActive && !$0.isCompleted }
    }

    // Get most recent workout (user-created or any available)
    private var currentWorkout: Workout? {
        workouts.first
    }

    // Check if we have any content to show
    private var hasContent: Bool {
        currentWorkout != nil || activeChallenge != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Current Programs")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Workout Row - only show if we have a workout
            if let workout = currentWorkout {
                HStack(spacing: 12) {
                    // Workout icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "0891b2").opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "0891b2"))
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("\(workout.exerciseCount) exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Start Button
                    Button {
                        selectedWorkout = workout
                        showStartConfirmation = true
                    } label: {
                        Text("Start")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(hex: "0891b2"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Show empty state if no content
            if !hasContent {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No active programs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            // Challenge Row - only show if there's an active challenge
            if let challenge = activeChallenge {
                if currentWorkout != nil {
                    Divider()
                        .padding(.horizontal, 16)
                }

                Button(action: {
                    themeManager.lightImpact()
                    onChallengeTap()
                }) {
                    HStack(spacing: 12) {
                        // Trophy icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "10b981").opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "trophy.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "10b981"))
                        }

                        // Info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(challenge.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text("Day \(challenge.currentDay) • \(challenge.daysRemaining) days left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Progress
                        Text("\(Int(challenge.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "10b981"))

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .alert("Start Workout?", isPresented: $showStartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                startWorkout()
            }
        } message: {
            if let workout = selectedWorkout {
                Text("Are you sure you want to begin \(workout.name)? This workout is approximately \(workout.estimatedDuration) minutes.")
            } else {
                Text("Are you sure you want to start this workout?")
            }
        }
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            if let workout = selectedWorkout {
                WorkoutExecutionView(workout: workout)
                    .environmentObject(workoutManager)
                    .environmentObject(themeManager)
            }
        }
    }

    private func startWorkout() {
        workoutManager.resetState()
        guard let workout = selectedWorkout, workout.exerciseCount > 0 else { return }
        themeManager.mediumImpact()
        showWorkoutExecution = true
    }
}

// MARK: - Saved Programs Section
struct SavedProgramsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSavedPrograms = false

    var body: some View {
        Button(action: {
            themeManager.mediumImpact()
            showSavedPrograms = true
        }) {
            HStack(spacing: 16) {
                // Icon - using gray/slate color
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "475569"), Color(hex: "64748b")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("My Programs")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("View all saved programs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("View All")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentBlue)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showSavedPrograms) {
            SavedProgramsDetailView()
                .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Mini Program Card
struct MiniProgramCard: View {
    let name: String
    let exercises: Int
    let icon: String
    let gradientColors: [Color]

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(exercises) exercises")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SavedProgramsStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color.brandPrimary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Saved Programs Detail View
struct SavedProgramsDetailView: View {
    @Environment(\.dismiss) private var dismiss
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

        // Apply filter
        switch selectedFilter {
        case .all: break
        case .active: programs = programs.filter { $0.isActive }
        case .userCreated: programs = programs.filter { $0.safeCreationType == .userCreated }
        case .aiGenerated: programs = programs.filter { $0.safeCreationType == .aiGenerated }
        case .imported: programs = programs.filter { $0.safeCreationType == .imported }
        }

        // Apply search
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
                                    withAnimation(.spring(response: 0.3)) {
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
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                            Text("No programs found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Try adjusting your filters or create a new program")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
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

struct ProgramFilterChip: View {
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
                .padding(.vertical, 8)
                .background(isSelected ? Color.brandPrimary : Color(.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Saved Workout Card (Uses real Workout data)
struct SavedWorkoutCard: View {
    let workout: Workout
    @State private var isPressed = false

    private var creationTypeColor: Color {
        switch workout.safeCreationType {
        case .userCreated: return .accentBlue
        case .aiGenerated: return Color(hex: "06b6d4") // Cyan
        case .imported: return .accentOrange
        case .preset: return .accentGreen
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
            // Open program detail
        } label: {
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 14) {
                    // Icon with gradient
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [creationTypeColor, creationTypeColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: workout.safeCreationType.icon)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Title and active badge
                        HStack(spacing: 8) {
                            Text(workout.name)
                                .font(.headline)
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

                        // Info row
                        HStack(spacing: 12) {
                            Label("\(workout.exerciseCount)", systemImage: "figure.run")
                            Label("\(workout.estimatedDuration) min", systemImage: "clock")
                            Text(workout.difficulty.rawValue)
                                .foregroundStyle(difficultyColor)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        // Tags row
                        HStack(spacing: 8) {
                            // Creation type
                            HStack(spacing: 4) {
                                Image(systemName: workout.safeCreationType.icon)
                                Text(workout.safeCreationType.displayName)
                            }
                            .font(.caption2)
                            .foregroundStyle(creationTypeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(creationTypeColor.opacity(0.12))
                            .clipShape(Capsule())

                            // Status
                            if workout.hasBeenStarted {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("\(workout.completedSessionsCount) sessions")
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.accentGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentGreen.opacity(0.12))
                                .clipShape(Capsule())
                            } else {
                                Text("Not started")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)

                // Bottom stats bar
                if workout.hasBeenStarted {
                    Divider()
                    HStack(spacing: 0) {
                        ProgramStatItem(
                            icon: "trophy.fill",
                            value: "\(workout.personalRecordsCount)",
                            label: "PRs",
                            color: .accentOrange
                        )

                        Divider().frame(height: 24)

                        ProgramStatItem(
                            icon: "calendar",
                            value: workout.createdAt.formatted(.dateTime.month(.abbreviated).day()),
                            label: "Created",
                            color: .secondary
                        )

                        Divider().frame(height: 24)

                        ProgramStatItem(
                            icon: "flame.fill",
                            value: "\(workout.completedSessionsCount)",
                            label: "Sessions",
                            color: .accentRed
                        )
                    }
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground).opacity(0.5))
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ProgramStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Challenges Section Card
struct ChallengesSectionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            themeManager.mediumImpact()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "22c55e"), Color(hex: "16a34a")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenges")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Compete with friends & stay motivated")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("View All")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "22c55e"))
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views
struct CreateProgramView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Hero illustration
                ZStack {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "plus.rectangle.on.folder")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentBlue)
                }
                .padding(.top, 40)

                Text("Create Program")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Build a custom workout program by adding exercises and setting your schedule.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                GradientButton("Coming Soon", icon: "plus", gradient: AppGradients.primary) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
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
                // Hero illustration
                ZStack {
                    Circle()
                        .fill(AppGradients.primary.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.brandPrimary)
                }
                .padding(.top, 40)

                Text("Create with AI")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Tell us your goals and we'll create a personalized workout program just for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                GradientButton("Coming Soon", icon: "sparkles", gradient: AppGradients.primary) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Create with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
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
                    // Hero illustration
                    ZStack {
                        Circle()
                            .fill(AppGradients.energetic.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentOrange)
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

                    // Import options
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
                            icon: "doc.richtext.fill",
                            title: "Word Document",
                            subtitle: "Import .doc or .docx files",
                            color: .accentBlue
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

                        ImportOptionCard(
                            icon: "plus.circle.fill",
                            title: "More Formats",
                            subtitle: "Coming soon...",
                            color: .secondary
                        ) {
                            // More formats coming soon
                        }
                    }
                    .padding(.horizontal)

                    // Status indicator
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
            .navigationTitle("Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
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
                        // TODO: Parse and import the workout file
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
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedDifficulty: Difficulty?
    @State private var selectedLocation: ExerciseLocation?
    @State private var showFavoritesOnly = false
    @State private var selectedExercise: Exercise?

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)

            // Category filter
            let matchesCategory = selectedCategory == nil || exercise.safeCategory == selectedCategory

            // Difficulty filter
            let matchesDifficulty = selectedDifficulty == nil || exercise.safeDifficulty == selectedDifficulty

            // Location filter
            let matchesLocation = selectedLocation == nil ||
                exercise.safeLocation == selectedLocation ||
                exercise.safeLocation == .both

            // Favorites filter
            let matchesFavorites = !showFavoritesOnly || exercise.isFavorite

            return matchesSearch && matchesCategory && matchesDifficulty && matchesLocation && matchesFavorites
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Favorites toggle
                            FilterChip(
                                title: "Favorites",
                                icon: "heart.fill",
                                isSelected: showFavoritesOnly,
                                color: .accentRed
                            ) {
                                showFavoritesOnly.toggle()
                            }

                            Divider()
                                .frame(height: 24)

                            // Category chips
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.displayName,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category,
                                    color: .accentBlue
                                ) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Secondary filters
                    HStack(spacing: 8) {
                        // Difficulty picker
                        Menu {
                            Button("All Levels") { selectedDifficulty = nil }
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                Button(difficulty.displayName) {
                                    selectedDifficulty = difficulty
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.bar.fill")
                                Text(selectedDifficulty?.displayName ?? "Difficulty")
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedDifficulty != nil ? Color.accentBlue.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedDifficulty != nil ? Color.accentBlue : .primary)
                            .clipShape(Capsule())
                        }

                        // Location picker
                        Menu {
                            Button("Anywhere") { selectedLocation = nil }
                            ForEach(ExerciseLocation.allCases, id: \.self) { location in
                                Button(location.displayName) {
                                    selectedLocation = location
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: selectedLocation?.icon ?? "mappin.and.ellipse")
                                Text(selectedLocation?.displayName ?? "Location")
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedLocation != nil ? Color.accentBlue.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedLocation != nil ? Color.accentBlue : .primary)
                            .clipShape(Capsule())
                        }

                        Spacer()

                        // Results count
                        Text("\(filteredExercises.count) exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Exercise list
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExercises) { exercise in
                            ExerciseListCard(exercise: exercise) {
                                selectedExercise = exercise
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
                    .presentationDetents([.large])
            }
            .task {
                // Seed exercises if needed (will be implemented via ExerciseData)
                // ExerciseData.seedExercises(in: modelContext)
            }
        }
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
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: exercise.safeCategory.icon)
                        .font(.title3)
                        .foregroundStyle(Color.accentBlue)
                }

                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        // Difficulty badge
                        Text(exercise.safeDifficulty.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(difficultyColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor.opacity(0.15))
                            .clipShape(Capsule())

                        // Equipment
                        HStack(spacing: 2) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.caption2)
                            Text(exercise.equipment.displayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)

                        // Location
                        HStack(spacing: 2) {
                            Image(systemName: exercise.safeLocation.icon)
                                .font(.caption2)
                            Text(exercise.safeLocation.displayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Favorite button
                Button {
                    exercise.isFavorite.toggle()
                    try? modelContext.save()
                    themeManager.lightImpact()
                } label: {
                    Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(exercise.isFavorite ? Color.accentRed : Color.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

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
                    // Hero section
                    ZStack {
                        Circle()
                            .fill(Color.accentBlue.opacity(0.1))
                            .frame(width: 120, height: 120)

                        Image(systemName: exercise.safeCategory.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(Color.accentBlue)
                    }
                    .padding(.top, 20)

                    // Title and badges
                    VStack(spacing: 12) {
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            // Difficulty
                            Label(exercise.safeDifficulty.displayName, systemImage: "chart.bar.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(difficultyColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(difficultyColor.opacity(0.15))
                                .clipShape(Capsule())

                            // Category
                            Label(exercise.safeCategory.displayName, systemImage: exercise.safeCategory.icon)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.accentBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentBlue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    // Stats cards
                    HStack(spacing: 12) {
                        ExerciseStatCard(
                            icon: exercise.safeLocation.icon,
                            value: exercise.safeLocation.displayName,
                            label: "Location"
                        )

                        ExerciseStatCard(
                            icon: "flame.fill",
                            value: "\(exercise.caloriesPerMinute)",
                            label: "Cal/min"
                        )

                        ExerciseStatCard(
                            icon: "wrench.and.screwdriver",
                            value: exercise.equipment.displayName,
                            label: "Equipment"
                        )
                    }
                    .padding(.horizontal)

                    // Muscle group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Muscle")
                            .font(.headline)
                            .fontWeight(.semibold)

                        HStack(spacing: 12) {
                            Image(systemName: exercise.muscleGroup.icon)
                                .font(.title2)
                                .foregroundStyle(Color.accentBlue)
                                .frame(width: 44, height: 44)
                                .background(Color.accentBlue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text(exercise.muscleGroup.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Instructions
                    if let instructions = exercise.instructions {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to Perform")
                                .font(.headline)
                                .fontWeight(.semibold)

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

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            exercise.isFavorite.toggle()
                            try? modelContext.save()
                            themeManager.mediumImpact()
                        } label: {
                            HStack {
                                Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                                Text(exercise.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(exercise.isFavorite ? .white : .accentRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(exercise.isFavorite ? Color.accentRed : Color.accentRed.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        Button {
                            // TODO: Add to workout functionality
                            themeManager.mediumImpact()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Workout")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
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
                .foregroundStyle(Color.accentBlue)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProgramsView()
        .environmentObject(WorkoutManager())
}
