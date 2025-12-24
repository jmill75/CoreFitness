import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProgramsView: View {

    // MARK: - State
    @State private var showAIWorkoutCreation = false
    @State private var showImportWorkout = false
    @State private var showExerciseLibrary = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        // Current Active Program - Hero Card
                        CurrentProgramCard()
                            .id("top")

                        // Quick Actions - Gradient Buttons
                        QuickActionsSection(
                            onAICreate: { showAIWorkoutCreation = true },
                            onImportWorkout: { showImportWorkout = true },
                            onExerciseLibrary: { showExerciseLibrary = true }
                        )

                        // Saved Programs Section
                        SavedProgramsSection()

                        // Discover Programs Section
                        DiscoverProgramsSection()
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.headline)
                            .foregroundStyle(Color.brandPrimary)
                        Text("Programs")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search programs & exercises")
            .sheet(isPresented: $showAIWorkoutCreation) {
                AIWorkoutCreationView()
                    .presentationBackground(.regularMaterial)
            }
            .sheet(isPresented: $showImportWorkout) {
                ImportWorkoutView()
                    .presentationBackground(.regularMaterial)
            }
            .sheet(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView()
                    .presentationBackground(.regularMaterial)
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {

    let onAICreate: () -> Void
    let onImportWorkout: () -> Void
    let onExerciseLibrary: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                title: "AI Create",
                icon: "sparkles",
                gradient: AppGradients.primary,
                action: onAICreate
            )

            QuickActionCard(
                title: "Import",
                icon: "doc.badge.plus",
                gradient: AppGradients.energetic,
                action: onImportWorkout
            )

            QuickActionCard(
                title: "Exercises",
                icon: "figure.strengthtraining.traditional",
                gradient: AppGradients.ocean,
                action: onExerciseLibrary
            )
        }
    }
}

struct QuickActionCard: View {

    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.brandPrimary.opacity(0.2), radius: 8, y: 4)
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

    var body: some View {
        VStack(spacing: 16) {
            // Header with progress
            HStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("12-Week Strength Builder")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Week \(weekNumber) of \(totalWeeks) • 4 days/week")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()
            }

            // Today's Workout
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
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
                    // Load or create sample workout if needed
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
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(AppGradients.primary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.brandPrimary.opacity(0.25), radius: 10, y: 6)
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            if let workout = sampleWorkout {
                WorkoutExecutionView(workout: workout)
                    .environmentObject(workoutManager)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            // Load or create sample workout
            if sampleWorkout == nil {
                sampleWorkout = SampleWorkoutData.loadOrCreateSampleWorkout(in: modelContext)
            }
        }
    }
}

// MARK: - Saved Programs Section
struct SavedProgramsSection: View {
    @State private var showSavedPrograms = false

    // Sample data - replace with actual SwiftData query
    private let programCount = 5
    private let activeProgram = "Push Pull Legs"

    var body: some View {
        Button {
            showSavedPrograms = true
        } label: {
            VStack(spacing: 16) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Programs")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("\(programCount) saved programs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("View All")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
                }

                // Active program indicator
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentGreen.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentGreen)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentGreen)
                                .clipShape(Capsule())

                            Spacer()
                        }

                        Text(activeProgram)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Quick stats row
                HStack(spacing: 0) {
                    SavedProgramsStatItem(value: "12", label: "Workouts", icon: "figure.run")
                    Divider().frame(height: 30)
                    SavedProgramsStatItem(value: "8", label: "PRs Hit", icon: "trophy.fill")
                    Divider().frame(height: 30)
                    SavedProgramsStatItem(value: "3", label: "This Week", icon: "calendar")
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSavedPrograms) {
            SavedProgramsDetailView()
                .presentationDragIndicator(.visible)
        }
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

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            // Create new program
                        } label: {
                            Label("Create Program", systemImage: "plus")
                        }

                        Button {
                            // Import program
                        } label: {
                            Label("Import Program", systemImage: "square.and.arrow.down")
                        }

                        Button {
                            // Generate with AI
                        } label: {
                            Label("Generate with AI", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.brandPrimary)
                    }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Discover")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text("Browse All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.brandPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Challenges - tappable
                    Button {
                        showChallenges = true
                    } label: {
                        DiscoverProgramCard(
                            title: "Challenges",
                            subtitle: "Compete with friends",
                            icon: "trophy.fill",
                            gradient: AppGradients.success
                        )
                    }
                    .buttonStyle(.plain)

                    DiscoverProgramCard(
                        title: "Muscle Builder",
                        subtitle: "12 weeks • Advanced",
                        icon: "figure.strengthtraining.traditional",
                        gradient: AppGradients.energetic
                    )

                    DiscoverProgramCard(
                        title: "Fat Burner",
                        subtitle: "8 weeks • HIIT",
                        icon: "flame.fill",
                        gradient: AppGradients.health
                    )

                    DiscoverProgramCard(
                        title: "Recovery Focus",
                        subtitle: "4 weeks • Mobility",
                        icon: "leaf.fill",
                        gradient: AppGradients.ocean
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showChallenges) {
            ChallengesView()
                .presentationBackground(.regularMaterial)
        }
    }
}

struct DiscoverProgramCard: View {

    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .frame(width: 140, height: 130)
        .padding()
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Placeholder Views
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
            let matchesCategory = selectedCategory == nil || exercise.category == selectedCategory

            // Difficulty filter
            let matchesDifficulty = selectedDifficulty == nil || exercise.difficulty == selectedDifficulty

            // Location filter
            let matchesLocation = selectedLocation == nil ||
                exercise.location == selectedLocation ||
                exercise.location == .both

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
        switch exercise.difficulty {
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

                    Image(systemName: exercise.category.icon)
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
                        Text(exercise.difficulty.displayName)
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
                            Image(systemName: exercise.location.icon)
                                .font(.caption2)
                            Text(exercise.location.displayName)
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
        switch exercise.difficulty {
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

                        Image(systemName: exercise.category.icon)
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
                            Label(exercise.difficulty.displayName, systemImage: "chart.bar.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(difficultyColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(difficultyColor.opacity(0.15))
                                .clipShape(Capsule())

                            // Category
                            Label(exercise.category.displayName, systemImage: exercise.category.icon)
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
                            icon: exercise.location.icon,
                            value: exercise.location.displayName,
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
