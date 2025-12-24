import SwiftUI

struct ProgramsView: View {

    // MARK: - State
    @State private var showAIWorkoutCreation = false
    @State private var showQuickWorkout = false
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
                            onQuickWorkout: { showQuickWorkout = true },
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
            .sheet(isPresented: $showQuickWorkout) {
                QuickWorkoutView()
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
    let onQuickWorkout: () -> Void
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
                title: "Quick Start",
                icon: "bolt.fill",
                gradient: AppGradients.energetic,
                action: onQuickWorkout
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
                    // Create sample workout if needed
                    if sampleWorkout == nil {
                        sampleWorkout = SampleWorkoutData.createSampleWorkout(in: modelContext)
                    }
                    showWorkoutExecution = true
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

    var body: some View {
        Button {
            // Navigate to saved programs
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "folder.fill")
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.brandPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved Programs")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("3 programs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("See All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.brandPrimary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Discover Programs Section
struct DiscoverProgramsSection: View {

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
                    DiscoverProgramCard(
                        title: "30-Day Challenge",
                        subtitle: "Build consistency",
                        icon: "trophy.fill",
                        gradient: AppGradients.success
                    )

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

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .foregroundStyle(.white)
        .frame(width: 140)
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

struct QuickWorkoutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Hero illustration
                ZStack {
                    Circle()
                        .fill(AppGradients.energetic.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentOrange)
                }
                .padding(.top, 40)

                Text("Quick Start")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Jump into a workout right away without any setup.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                GradientButton("Coming Soon", icon: "bolt.fill", gradient: AppGradients.energetic) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Quick Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
        }
    }
}

struct ExerciseLibraryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Hero illustration
                ZStack {
                    Circle()
                        .fill(AppGradients.ocean.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentBlue)
                }
                .padding(.top, 40)

                Text("Exercise Library")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Browse our collection of exercises with detailed instructions and videos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                GradientButton("Coming Soon", icon: "dumbbell.fill", gradient: AppGradients.ocean) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProgramsView()
        .environmentObject(WorkoutManager())
}
