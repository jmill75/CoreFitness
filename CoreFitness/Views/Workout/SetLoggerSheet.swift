import SwiftUI
import SwiftData

struct SetLoggerSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var reps: Int = 10
    @State private var weight: Double = 0
    @State private var selectedRPE: Int? = nil
    @State private var lastWorkoutSets: [CompletedSet] = []
    @State private var lastWorkoutDate: Date?


    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Set number header with exercise name and category
                    VStack(spacing: 8) {
                        Text("Set \(workoutManager.currentSetNumber)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        // Exercise category badge
                        if let category = workoutManager.currentExercise?.exercise?.safeCategory {
                            Text(category.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.5)
                                .foregroundStyle(categoryColor(category))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(categoryColor(category).opacity(0.2))
                                .clipShape(Capsule())
                        }

                        Text(workoutManager.currentExercise?.exercise?.name ?? "Exercise")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.top, 8)

                        // Last workout reference
                        if !lastWorkoutSets.isEmpty {
                            lastWorkoutView
                        }
                    }
                    .padding(.top, 8)

                    // Main input area
                    HStack(spacing: 40) {
                        // Reps input
                        VStack(spacing: 16) {
                            Text("REPS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.gray)
                                .tracking(1)

                            HStack(spacing: 20) {
                                Button {
                                    if reps > 1 { reps -= 1 }
                                    themeManager.lightImpact()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "minus")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                    }
                                }

                                Text("\(reps)")
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundStyle(.cyan)
                                    .frame(width: 80)

                                Button {
                                    reps += 1
                                    themeManager.lightImpact()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.cyan.opacity(0.3))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "plus")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.cyan)
                                    }
                                }
                            }
                        }
                    }

                    // Weight input
                    VStack(spacing: 16) {
                        Text("WEIGHT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                            .tracking(1)

                        HStack(spacing: 16) {
                            // -5 button with press-and-hold
                            RepeatingButton(
                                action: {
                                    if weight >= 5 { weight -= 5 }
                                },
                                label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        Text("-5")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                            )

                            Text(themeManager.formatWeight(weight))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                                .frame(width: 150)

                            // +5 button with press-and-hold
                            RepeatingButton(
                                action: {
                                    weight += 5
                                },
                                label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        Text("+5")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.green)
                                    }
                                }
                            )
                        }

                        // Quick weight adjustments
                        HStack(spacing: 10) {
                            ForEach([-10.0, -2.5, 2.5, 10.0], id: \.self) { adjustment in
                                Button {
                                    weight = max(0, weight + adjustment)
                                    themeManager.lightImpact()
                                } label: {
                                    Text(adjustment > 0 ? "+\(adjustment.formatted())" : "\(adjustment.formatted())")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(adjustment > 0 ? .green : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // RPE Selection (optional)
                    VStack(spacing: 12) {
                        Text("RPE (optional)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                            .tracking(1)

                        HStack(spacing: 8) {
                            ForEach([6, 7, 8, 9, 10], id: \.self) { rpe in
                                Button {
                                    selectedRPE = selectedRPE == rpe ? nil : rpe
                                    themeManager.lightImpact()
                                } label: {
                                    Text("\(rpe)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(selectedRPE == rpe ? .black : .white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            selectedRPE == rpe ?
                                                rpeColor(rpe) :
                                                Color.gray.opacity(0.2)
                                        )
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }

                    Spacer()

                    // Save button
                    Button {
                        workoutManager.logSet(reps: reps, weight: weight, rpe: selectedRPE)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Save Set")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }
                .padding()
            }
            .preferredColorScheme(.dark)
            .onAppear {
                reps = workoutManager.loggedReps
                weight = workoutManager.loggedWeight
                fetchLastWorkout()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        workoutManager.showSetLogger = false
                        workoutManager.currentPhase = .exercising
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 6...7: return .green
        case 8: return .yellow
        case 9: return .orange
        case 10: return .red
        default: return .gray
        }
    }

    private func categoryColor(_ category: ExerciseCategory) -> Color {
        switch category {
        case .strength: return .orange
        case .cardio: return .red
        case .yoga: return .purple
        case .pilates: return .pink
        case .hiit: return .yellow
        case .stretching: return .mint
        case .running: return .blue
        case .cycling: return .green
        case .swimming: return .cyan
        case .calisthenics: return .indigo
        }
    }

    // MARK: - Last Workout View
    private var lastWorkoutView: some View {
        VStack(spacing: 6) {
            // Header with date
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                Text("Last: \(lastWorkoutDateText)")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.5))

            // Sets display
            HStack(spacing: 8) {
                ForEach(lastWorkoutSets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                    Text("\(Int(set.weight))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 12)
    }

    private var lastWorkoutDateText: String {
        guard let date = lastWorkoutDate else { return "" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 14 {
            return "1 week ago"
        } else {
            return "\(days / 7) weeks ago"
        }
    }

    private func fetchLastWorkout() {
        guard let exerciseId = workoutManager.currentExercise?.exercise?.id,
              let currentSessionId = workoutManager.currentSession?.id else { return }

        // Fetch all completed sets
        let descriptor = FetchDescriptor<CompletedSet>()

        do {
            let allSets = try modelContext.fetch(descriptor)

            // Filter to this exercise from previous sessions
            let relevantSets = allSets.filter { set in
                set.workoutExercise?.exercise?.id == exerciseId &&
                set.session?.id != currentSessionId
            }

            // Group by session and get the most recent session's sets
            let sessionGroups = Dictionary(grouping: relevantSets) { $0.session?.id }

            // Find the most recent session
            if let mostRecentEntry = sessionGroups.compactMap({ (sessionId, sets) -> (Date, [CompletedSet])? in
                guard let date = sets.first?.session?.startedAt else { return nil }
                return (date, sets)
            }).sorted(by: { $0.0 > $1.0 }).first {
                lastWorkoutSets = mostRecentEntry.1
                lastWorkoutDate = mostRecentEntry.0
            }
        } catch {
            print("Failed to fetch last workout: \(error)")
        }
    }
}

// MARK: - Repeating Button (Press-and-Hold)
struct RepeatingButton<Label: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var timer: Timer?
    @State private var isPressed = false

    var body: some View {
        label()
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            // Immediate action on press
                            action()
                            themeManager.lightImpact()

                            // Start repeating after delay
                            timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                                action()
                                themeManager.lightImpact()
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        timer?.invalidate()
                        timer = nil
                    }
            )
    }
}

#Preview {
    SetLoggerSheet()
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
