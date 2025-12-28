import SwiftUI
import SwiftData

struct ProgramBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @Query(sort: \ProgramTemplate.name) private var allPrograms: [ProgramTemplate]
    @Query private var userPrograms: [UserProgram]

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedDifficulty: Difficulty?
    @State private var selectedGoal: ProgramGoal?
    @State private var showFilters = false
    @State private var selectedProgram: ProgramTemplate?

    private var activeProgram: UserProgram? {
        userPrograms.first { $0.status == .active }
    }

    private var filteredPrograms: [ProgramTemplate] {
        allPrograms.filter { program in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                program.name.localizedCaseInsensitiveContains(searchText) ||
                program.programDescription.localizedCaseInsensitiveContains(searchText)

            // Category filter
            let matchesCategory = selectedCategory == nil || program.category == selectedCategory

            // Difficulty filter
            let matchesDifficulty = selectedDifficulty == nil || program.difficulty == selectedDifficulty

            // Goal filter
            let matchesGoal = selectedGoal == nil || program.goal == selectedGoal

            return matchesSearch && matchesCategory && matchesDifficulty && matchesGoal
        }
    }

    private var featuredPrograms: [ProgramTemplate] {
        filteredPrograms.filter { $0.isFeatured }
    }

    private var programsByCategory: [ExerciseCategory: [ProgramTemplate]] {
        Dictionary(grouping: filteredPrograms) { $0.category }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Active Program Banner
                        if let active = activeProgram, let template = active.template {
                            ActiveProgramBanner(program: active, template: template)
                                .padding(.horizontal)
                        }

                        // Search Bar
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.gray)
                                TextField("Search programs...", text: $searchText)
                                    .foregroundStyle(.white)
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button {
                                showFilters.toggle()
                            } label: {
                                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .font(.title2)
                                    .foregroundStyle(hasActiveFilters ? .cyan : .gray)
                            }
                        }
                        .padding(.horizontal)

                        // Active Filters
                        if hasActiveFilters {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if let category = selectedCategory {
                                        FilterChip(label: category.displayName, color: categoryColor(category)) {
                                            selectedCategory = nil
                                        }
                                    }
                                    if let difficulty = selectedDifficulty {
                                        FilterChip(label: difficulty.displayName, color: difficultyColor(difficulty)) {
                                            selectedDifficulty = nil
                                        }
                                    }
                                    if let goal = selectedGoal {
                                        FilterChip(label: goal.displayName, color: .purple) {
                                            selectedGoal = nil
                                        }
                                    }
                                    Button("Clear All") {
                                        clearFilters()
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Featured Programs
                        if !featuredPrograms.isEmpty && !hasActiveFilters {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Featured Programs")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(featuredPrograms) { program in
                                            FeaturedProgramCard(program: program) {
                                                selectedProgram = program
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Category Sections
                        if selectedCategory == nil {
                            // Show all categories
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                if let programs = programsByCategory[category], !programs.isEmpty {
                                    CategorySection(
                                        category: category,
                                        programs: programs,
                                        onSelect: { program in
                                            selectedProgram = program
                                        }
                                    )
                                }
                            }
                        } else {
                            // Show filtered results in grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(filteredPrograms) { program in
                                    ProgramGridCard(program: program) {
                                        selectedProgram = program
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Empty State
                        if filteredPrograms.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.gray)
                                Text("No programs found")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Try adjusting your search or filters")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                Button("Clear Filters") {
                                    clearFilters()
                                    searchText = ""
                                }
                                .buttonStyle(.bordered)
                                .tint(.cyan)
                            }
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Browse Programs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.cyan)
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    selectedCategory: $selectedCategory,
                    selectedDifficulty: $selectedDifficulty,
                    selectedGoal: $selectedGoal
                )
            }
            .sheet(item: $selectedProgram) { program in
                ProgramDetailView(program: program, activeProgram: activeProgram)
            }
            .onAppear {
                // Seed programs if needed
                ProgramData.seedPrograms(in: modelContext)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDifficulty != nil || selectedGoal != nil
    }

    private func clearFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        selectedGoal = nil
    }

    private func categoryColor(_ category: ExerciseCategory) -> Color {
        switch category {
        case .strength: return .blue
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .teal
        case .hiit: return .orange
        case .stretching: return .green
        case .running: return .yellow
        case .cycling: return .blue
        case .swimming: return .cyan
        case .calisthenics: return .orange
        }
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Active Program Banner
struct ActiveProgramBanner: View {
    let program: UserProgram
    let template: ProgramTemplate

    var body: some View {
        HStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: program.progressPercentage / 100)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(program.progressPercentage))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Currently Active")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Week \(program.currentWeek) of \(template.durationWeeks)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color.green.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - Featured Program Card
struct FeaturedProgramCard: View {
    let program: ProgramTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and difficulty
                HStack {
                    Image(systemName: program.category.icon)
                        .font(.title2)
                        .foregroundStyle(categoryColor)

                    Spacer()

                    Text(program.difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.2))
                        .clipShape(Capsule())
                }

                Text(program.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(program.programDescription)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Stats row
                HStack(spacing: 16) {
                    Label("\(program.durationWeeks)w", systemImage: "calendar")
                    Label("\(program.workoutsPerWeek)/wk", systemImage: "figure.run")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
            .frame(width: 240, height: 180)
            .background(
                LinearGradient(
                    colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(categoryColor.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var categoryColor: Color {
        switch program.category {
        case .strength: return .blue
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .teal
        case .hiit: return .orange
        case .stretching: return .green
        case .running: return .yellow
        case .cycling: return .blue
        case .swimming: return .cyan
        case .calisthenics: return .orange
        }
    }

    private var difficultyColor: Color {
        switch program.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: ExerciseCategory
    let programs: [ProgramTemplate]
    let onSelect: (ProgramTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(categoryColor)
                Text(category.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(programs.count) programs")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(programs) { program in
                        ProgramCard(program: program) {
                            onSelect(program)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var categoryColor: Color {
        switch category {
        case .strength: return .blue
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .teal
        case .hiit: return .orange
        case .stretching: return .green
        case .running: return .yellow
        case .cycling: return .blue
        case .swimming: return .cyan
        case .calisthenics: return .orange
        }
    }
}

// MARK: - Program Card
struct ProgramCard: View {
    let program: ProgramTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Difficulty badge
                HStack {
                    Spacer()
                    Text(program.difficulty.shortName)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(difficultyColor.opacity(0.2))
                        .clipShape(Capsule())
                }

                Text(program.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                HStack(spacing: 8) {
                    Text("\(program.durationWeeks)w")
                        .font(.caption2)
                    Text("•")
                    Text("\(program.workoutsPerWeek)x/wk")
                        .font(.caption2)
                }
                .foregroundStyle(.gray)
            }
            .padding(12)
            .frame(width: 150, height: 110)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var difficultyColor: Color {
        switch program.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Program Grid Card
struct ProgramGridCard: View {
    let program: ProgramTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: program.category.icon)
                        .font(.title3)
                        .foregroundStyle(categoryColor)
                    Spacer()
                    Text(program.difficulty.shortName)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(difficultyColor.opacity(0.2))
                        .clipShape(Capsule())
                }

                Text(program.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                HStack(spacing: 8) {
                    Label("\(program.durationWeeks)w", systemImage: "calendar")
                    Spacer()
                    Label("\(program.workoutsPerWeek)x", systemImage: "figure.run")
                }
                .font(.caption2)
                .foregroundStyle(.gray)
            }
            .padding(12)
            .frame(height: 130)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var categoryColor: Color {
        switch program.category {
        case .strength: return .blue
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .teal
        case .hiit: return .orange
        case .stretching: return .green
        case .running: return .yellow
        case .cycling: return .blue
        case .swimming: return .cyan
        case .calisthenics: return .orange
        }
    }

    private var difficultyColor: Color {
        switch program.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ExerciseCategory?
    @Binding var selectedDifficulty: Difficulty?
    @Binding var selectedGoal: ProgramGoal?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Category Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.headline)
                                .foregroundStyle(.white)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                    FilterButton(
                                        label: category.displayName,
                                        icon: category.icon,
                                        isSelected: selectedCategory == category,
                                        color: categoryColor(category)
                                    ) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                        }

                        // Difficulty Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.headline)
                                .foregroundStyle(.white)

                            HStack(spacing: 10) {
                                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                    FilterButton(
                                        label: difficulty.displayName,
                                        isSelected: selectedDifficulty == difficulty,
                                        color: difficultyColor(difficulty)
                                    ) {
                                        selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                                    }
                                }
                            }
                        }

                        // Goal Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goal")
                                .font(.headline)
                                .foregroundStyle(.white)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ProgramGoal.allCases, id: \.self) { goal in
                                    FilterButton(
                                        label: goal.displayName,
                                        icon: goal.icon,
                                        isSelected: selectedGoal == goal,
                                        color: .purple
                                    ) {
                                        selectedGoal = selectedGoal == goal ? nil : goal
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        selectedCategory = nil
                        selectedDifficulty = nil
                        selectedGoal = nil
                    }
                    .foregroundStyle(.gray)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.cyan)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private func categoryColor(_ category: ExerciseCategory) -> Color {
        switch category {
        case .strength: return .blue
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .teal
        case .hiit: return .orange
        case .stretching: return .green
        case .running: return .yellow
        case .cycling: return .blue
        case .swimming: return .cyan
        case .calisthenics: return .orange
        }
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

struct FilterButton: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : .gray)
            .background(isSelected ? color.opacity(0.3) : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    ProgramBrowserView()
        .environmentObject(ThemeManager())
}
