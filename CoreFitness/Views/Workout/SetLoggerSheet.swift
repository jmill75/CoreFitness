import SwiftUI

struct SetLoggerSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var reps: Int = 10
    @State private var weight: Double = 0
    @State private var selectedRPE: Int? = nil


    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Set number header with exercise name
                    VStack(spacing: 8) {
                        Text(workoutManager.currentExercise?.exercise?.name ?? "Exercise")
                            .font(.headline)
                            .foregroundStyle(.gray)

                        Text("Set \(workoutManager.currentSetNumber)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
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
