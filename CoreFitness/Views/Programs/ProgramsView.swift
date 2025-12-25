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
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with + button
                    HStack {
                        Text("Programs")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        // Quick Add Menu Button (same as Home)
                        Menu {
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

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search programs & exercises", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(12)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Current Active Program - Hero Card
                    CurrentProgramCard()

                    // Exercises Card
                    ExercisesCard(onTap: { showExerciseLibrary = true })

                    // My Programs Card
                    SavedProgramsSection()

                    // Challenges Card
                    ChallengesCard(onTap: { showChallenges = true })

                    // Discover Programs Section - 2x2 Grid
                    DiscoverProgramsSection()
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
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
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
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
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
                gradientColors: [Color(hex: "6366f1"), Color(hex: "8b5cf6")],
                action: onAICreate
            )

            QuickActionCard(
                title: "Import",
                icon: "doc.badge.plus",
                gradientColors: [Color(hex: "f97316"), Color(hex: "fb923c")],
                action: onImportWorkout
            )

            QuickActionCard(
                title: "Exercises",
                icon: "dumbbell.fill",
                gradientColors: [Color(hex: "0ea5e9"), Color(hex: "38bdf8")],
                action: onExerciseLibrary
            )
        }
    }
}

struct QuickActionCard: View {

    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
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

// MARK: - Current Program Card (Hero)
struct CurrentProgramCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    @State private var showWorkoutExecution = false
    @State private var sampleWorkout: Workout?

    private let progress: Double = 0.33
    private let weekNumber: Int = 4
    private let totalWeeks: Int = 12

    // Gradient colors matching the HTML mockup
    private let gradientColors = [
        Color(hex: "6366f1"),
        Color(hex: "8b5cf6"),
        Color(hex: "a855f7")
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Header with progress ring and info
            HStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 7)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("12-Week Strength Builder")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Week \(weekNumber) of \(totalWeeks) • 4 days/week")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))

                    // Week progress dots
                    HStack(spacing: 3) {
                        ForEach(1...totalWeeks, id: \.self) { week in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(weekDotColor(for: week))
                                .frame(width: 14, height: 4)
                                .shadow(color: week == weekNumber ? .white.opacity(0.6) : .clear, radius: 4)
                        }
                    }
                }

                Spacer()
            }

            // Today's Workout
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Workout")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Upper Body Push")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    if sampleWorkout == nil {
                        sampleWorkout = SampleWorkoutData.loadOrCreateSampleWorkout(in: modelContext)
                    }
                    if sampleWorkout != nil {
                        showWorkoutExecution = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text("Start")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color(hex: "6366f1"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            // Decorative circles
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: 100, y: -80)

                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(x: -80, y: 100)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            if let workout = sampleWorkout {
                WorkoutExecutionView(workout: workout)
                    .environmentObject(workoutManager)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            if sampleWorkout == nil {
                sampleWorkout = SampleWorkoutData.loadOrCreateSampleWorkout(in: modelContext)
            }
        }
    }

    private func weekDotColor(for week: Int) -> Color {
        if week < weekNumber {
            return .white
        } else if week == weekNumber {
            return .white
        } else {
            return .white.opacity(0.3)
        }
    }
}

// MARK: - Saved Programs Section
struct SavedProgramsSection: View {
    @State private var showSavedPrograms = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showSavedPrograms = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8b5cf6"), Color(hex: "a855f7")],
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
                    .foregroundStyle(Color(hex: "8b5cf6"))
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
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
    @State private var selectedFilter: ProgramFilter = .all
    @State private var searchText = ""

    enum ProgramFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case userCreated = "My Programs"
        case aiGenerated = "AI Created"
        case imported = "Imported"
    }

    // Sample programs - replace with SwiftData query
    private let samplePrograms: [SampleProgram] = [
        SampleProgram(name: "Push Pull Legs", exercises: 18, duration: 60, difficulty: .intermediate, creationType: .userCreated, isActive: true, hasStarted: true, completedSessions: 12, prsHit: 5, createdAt: Date().addingTimeInterval(-86400 * 30)),
        SampleProgram(name: "Full Body Strength", exercises: 12, duration: 45, difficulty: .beginner, creationType: .aiGenerated, isActive: false, hasStarted: true, completedSessions: 8, prsHit: 3, createdAt: Date().addingTimeInterval(-86400 * 14)),
        SampleProgram(name: "HIIT Cardio Blast", exercises: 8, duration: 30, difficulty: .advanced, creationType: .preset, isActive: false, hasStarted: false, completedSessions: 0, prsHit: 0, createdAt: Date().addingTimeInterval(-86400 * 7)),
        SampleProgram(name: "Upper Body Focus", exercises: 10, duration: 50, difficulty: .intermediate, creationType: .imported, isActive: false, hasStarted: true, completedSessions: 4, prsHit: 2, createdAt: Date().addingTimeInterval(-86400 * 21)),
        SampleProgram(name: "Core & Mobility", exercises: 6, duration: 25, difficulty: .beginner, creationType: .userCreated, isActive: false, hasStarted: false, completedSessions: 0, prsHit: 0, createdAt: Date().addingTimeInterval(-86400 * 3))
    ]

    var filteredPrograms: [SampleProgram] {
        var programs = samplePrograms

        // Apply filter
        switch selectedFilter {
        case .all: break
        case .active: programs = programs.filter { $0.isActive }
        case .userCreated: programs = programs.filter { $0.creationType == .userCreated }
        case .aiGenerated: programs = programs.filter { $0.creationType == .aiGenerated }
        case .imported: programs = programs.filter { $0.creationType == .imported }
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
                        ForEach(filteredPrograms) { program in
                            SavedProgramCard(program: program)
                        }
                    }
                    .padding(.horizontal)

                    if filteredPrograms.isEmpty {
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

// Sample program struct for preview
struct SampleProgram: Identifiable {
    let id = UUID()
    let name: String
    let exercises: Int
    let duration: Int
    let difficulty: Difficulty
    let creationType: CreationType
    let isActive: Bool
    let hasStarted: Bool
    let completedSessions: Int
    let prsHit: Int
    let createdAt: Date
}

struct SavedProgramCard: View {
    let program: SampleProgram
    @State private var isPressed = false

    private var creationTypeColor: Color {
        switch program.creationType {
        case .userCreated: return .accentBlue
        case .aiGenerated: return .purple
        case .imported: return .accentOrange
        case .preset: return .accentGreen
        }
    }

    private var difficultyColor: Color {
        switch program.difficulty {
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

                        Image(systemName: program.creationType.icon)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Title and active badge
                        HStack(spacing: 8) {
                            Text(program.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if program.isActive {
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
                            Label("\(program.exercises)", systemImage: "figure.run")
                            Label("\(program.duration) min", systemImage: "clock")
                            Text(program.difficulty.rawValue)
                                .foregroundStyle(difficultyColor)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        // Tags row
                        HStack(spacing: 8) {
                            // Creation type
                            HStack(spacing: 4) {
                                Image(systemName: program.creationType.icon)
                                Text(program.creationType.displayName)
                            }
                            .font(.caption2)
                            .foregroundStyle(creationTypeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(creationTypeColor.opacity(0.12))
                            .clipShape(Capsule())

                            // Status
                            if program.hasStarted {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("\(program.completedSessions) sessions")
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
                if program.hasStarted {
                    Divider()
                    HStack(spacing: 0) {
                        ProgramStatItem(
                            icon: "trophy.fill",
                            value: "\(program.prsHit)",
                            label: "PRs",
                            color: .accentOrange
                        )

                        Divider().frame(height: 24)

                        ProgramStatItem(
                            icon: "calendar",
                            value: program.createdAt.formatted(.dateTime.month(.abbreviated).day()),
                            label: "Created",
                            color: .secondary
                        )

                        Divider().frame(height: 24)

                        ProgramStatItem(
                            icon: "flame.fill",
                            value: "\(program.completedSessions)",
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

// MARK: - Discover Programs Section
struct DiscoverProgramsSection: View {
    @State private var showChallenges = false

    // Discover items with their colors
    private let discoverItems: [(title: String, subtitle: String, icon: String, colors: [Color])] = [
        ("Challenges", "Compete with friends", "trophy.fill", [Color(hex: "22c55e"), Color(hex: "16a34a")]),
        ("Muscle Builder", "12 weeks • Advanced", "dumbbell.fill", [Color(hex: "f97316"), Color(hex: "ea580c")]),
        ("Fat Burner", "8 weeks • HIIT", "flame.fill", [Color(hex: "ef4444"), Color(hex: "dc2626")]),
        ("Recovery", "4 weeks • Mobility", "leaf.fill", [Color(hex: "0ea5e9"), Color(hex: "0284c7")])
    ]

    var body: some View {
        VStack(spacing: 14) {
            // Section Header
            HStack {
                Text("Discover")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Text("Browse All →")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "6366f1"))
            }

            // 2x2 Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(discoverItems.indices, id: \.self) { index in
                    let item = discoverItems[index]
                    Button {
                        if index == 0 {
                            showChallenges = true
                        }
                    } label: {
                        DiscoverGridCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            icon: item.icon,
                            gradientColors: item.colors
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .fullScreenCover(isPresented: $showChallenges) {
            ChallengesView()
        }
    }
}

struct DiscoverGridCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(height: 72)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(exercise.isFavorite ? Color.accentRed : Color.secondary)
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
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
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
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
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
