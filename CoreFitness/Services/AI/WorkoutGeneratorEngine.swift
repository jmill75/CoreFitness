import Foundation
import SwiftUI
import SwiftData

// MARK: - Workout Generator Engine

@MainActor
class WorkoutGeneratorEngine: ObservableObject {
    static let shared = WorkoutGeneratorEngine()

    // MARK: - Published Properties

    @Published var questionnaire = WorkoutQuestionnaire()
    @Published var currentStep: QuestionnaireStep = .goal
    @Published var generatedPlan: GeneratedWorkoutPlan?
    @Published var isGenerating = false
    @Published var generationError: Error?
    @Published var generationProgress: Double = 0

    // MARK: - Private Properties

    private var modelContext: ModelContext?

    private init() {}

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Navigation

    func nextStep() {
        guard let nextIndex = QuestionnaireStep.allCases.firstIndex(of: currentStep),
              nextIndex < QuestionnaireStep.allCases.count - 1 else { return }
        currentStep = QuestionnaireStep.allCases[nextIndex + 1]
    }

    func previousStep() {
        guard let currentIndex = QuestionnaireStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        currentStep = QuestionnaireStep.allCases[currentIndex - 1]
    }

    func goToStep(_ step: QuestionnaireStep) {
        currentStep = step
    }

    func reset() {
        questionnaire = WorkoutQuestionnaire()
        currentStep = .goal
        generatedPlan = nil
        generationError = nil
        generationProgress = 0
    }

    // MARK: - Validation

    var canProceed: Bool {
        switch currentStep {
        case .goal:
            return true // Goal is always selected
        case .schedule:
            return questionnaire.daysPerWeek >= 2 && questionnaire.daysPerWeek <= 7
        case .location:
            return !questionnaire.availableEquipment.isEmpty || questionnaire.location == .outdoor
        case .cardio:
            return true // All options valid
        case .experience:
            return true // Always selected
        case .preferences:
            return true // Optional
        case .review:
            return true
        }
    }

    // MARK: - Generation

    /// Generate a workout plan based on the questionnaire
    func generateWorkoutPlan() async throws -> GeneratedWorkoutPlan {
        guard AIConfigManager.shared.isAIEnabled else {
            throw AIError.providerUnavailable
        }

        isGenerating = true
        generationError = nil
        generationProgress = 0

        defer {
            isGenerating = false
            generationProgress = 1.0
        }

        do {
            generationProgress = 0.1

            // Build the prompt from questionnaire
            let prompt = buildGenerationPrompt()
            generationProgress = 0.2

            // Call AI service
            let response = try await AIProxyService.shared.generateWorkout(prompt: prompt)
            generationProgress = 0.7

            // Parse the response
            let plan = try parseWorkoutPlan(from: response.content)
            generationProgress = 0.9

            generatedPlan = plan
            return plan

        } catch {
            generationError = error
            throw error
        }
    }

    /// Save the generated plan to the database
    func saveGeneratedPlan() async throws {
        guard let plan = generatedPlan,
              let context = modelContext else {
            throw AIError.configurationError("No plan to save or context not configured")
        }

        // Create the program template
        let program = ProgramTemplate(
            name: plan.name,
            description: plan.description,
            category: categoryForGoal(questionnaire.primaryGoal),
            difficulty: difficultyForLevel(questionnaire.experienceLevel),
            durationWeeks: plan.weeks,
            workoutsPerWeek: plan.workoutsPerWeek,
            isPremium: false
        )

        context.insert(program)

        // Create workouts for the program
        for generatedWorkout in plan.workouts {
            let workout = Workout(
                name: generatedWorkout.name,
                estimatedDuration: generatedWorkout.estimatedDuration,
                creationType: .aiGenerated
            )

            context.insert(workout)

            // Create workout exercises
            for (index, genExercise) in generatedWorkout.exercises.enumerated() {
                // Try to find matching exercise in database
                let exercise = findOrCreateExercise(name: genExercise.exerciseName, in: context)

                let workoutExercise = WorkoutExercise(
                    order: index,
                    targetSets: genExercise.sets,
                    targetReps: parseReps(genExercise.reps),
                    restDuration: genExercise.restSeconds
                )
                workoutExercise.exercise = exercise
                workoutExercise.workout = workout

                if let notes = genExercise.notes {
                    workoutExercise.notes = notes
                }

                context.insert(workoutExercise)
            }
        }

        try context.save()
    }

    // MARK: - Private Methods

    private func buildGenerationPrompt() -> String {
        var parts: [String] = []

        // Goal
        parts.append("Goal: \(questionnaire.primaryGoal.rawValue)")

        // Schedule
        parts.append("Training days per week: \(questionnaire.daysPerWeek)")
        parts.append("Program length: \(questionnaire.programWeeks) weeks")
        parts.append("Session duration: \(questionnaire.sessionDuration.rawValue) minutes")

        // Location and equipment
        parts.append("Training location: \(questionnaire.location.rawValue)")
        let equipmentList = questionnaire.availableEquipment.map { $0.rawValue }.joined(separator: ", ")
        parts.append("Available equipment: \(equipmentList)")

        // Cardio
        if questionnaire.includeCardio {
            parts.append("Include cardio: Yes")
            parts.append("Cardio frequency: \(questionnaire.cardioFrequency.rawValue)")
            if !questionnaire.cardioTypes.isEmpty {
                let cardioList = questionnaire.cardioTypes.map { $0.rawValue }.joined(separator: ", ")
                parts.append("Preferred cardio: \(cardioList)")
            }
        } else {
            parts.append("Include cardio: No")
        }

        // Experience
        parts.append("Experience level: \(questionnaire.experienceLevel.rawValue)")

        // Focus areas
        if !questionnaire.focusAreas.isEmpty {
            let focusList = questionnaire.focusAreas.map { $0.rawValue }.joined(separator: ", ")
            parts.append("Focus areas: \(focusList)")
        }

        // Avoid exercises
        if !questionnaire.avoidExercises.isEmpty {
            parts.append("Exercises to avoid: \(questionnaire.avoidExercises.joined(separator: ", "))")
        }

        // Additional notes
        if !questionnaire.additionalNotes.isEmpty {
            parts.append("Additional notes: \(questionnaire.additionalNotes)")
        }

        let userContext = parts.joined(separator: "\n")

        return """
            Create a personalized \(questionnaire.programWeeks)-week workout program with the following specifications:

            \(userContext)

            Generate a complete workout plan with:
            - A creative, motivating program name
            - Brief program description
            - \(questionnaire.daysPerWeek) workouts per week
            - Each workout should include:
              - Day number (1-\(questionnaire.daysPerWeek))
              - Descriptive workout name (e.g., "Push Day", "Lower Body Power")
              - 5-8 exercises per workout
              - Sets, reps, and rest periods for each exercise
              - Any relevant notes

            Use common exercise names. Ensure progressive structure across the program.
            Balance muscle groups appropriately for the training frequency.

            Return the response as a JSON object with this structure:
            {
              "name": "Program Name",
              "description": "Brief description",
              "weeks": \(questionnaire.programWeeks),
              "workoutsPerWeek": \(questionnaire.daysPerWeek),
              "workouts": [
                {
                  "dayNumber": 1,
                  "name": "Workout Name",
                  "estimatedDuration": 45,
                  "exercises": [
                    {
                      "exerciseName": "Exercise Name",
                      "sets": 3,
                      "reps": "8-12",
                      "restSeconds": 90,
                      "notes": "optional notes"
                    }
                  ]
                }
              ]
            }
            """
    }

    private func parseWorkoutPlan(from content: String) throws -> GeneratedWorkoutPlan {
        // Clean the response
        var cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to extract JSON if wrapped in other text
        if let jsonStart = cleanContent.firstIndex(of: "{"),
           let jsonEnd = cleanContent.lastIndex(of: "}") {
            cleanContent = String(cleanContent[jsonStart...jsonEnd])
        }

        guard let data = cleanContent.data(using: .utf8) else {
            throw AIError.parsingError("Invalid response encoding")
        }

        do {
            let decoder = JSONDecoder()
            var plan = try decoder.decode(GeneratedWorkoutPlan.self, from: data)

            // Ensure IDs are set
            plan = GeneratedWorkoutPlan(
                id: UUID(),
                name: plan.name,
                description: plan.description,
                weeks: plan.weeks,
                workoutsPerWeek: plan.workoutsPerWeek,
                workouts: plan.workouts.map { workout in
                    GeneratedWorkout(
                        id: UUID(),
                        dayNumber: workout.dayNumber,
                        name: workout.name,
                        exercises: workout.exercises.map { exercise in
                            GeneratedExercise(
                                id: UUID(),
                                exerciseName: exercise.exerciseName,
                                sets: exercise.sets,
                                reps: exercise.reps,
                                restSeconds: exercise.restSeconds,
                                notes: exercise.notes
                            )
                        },
                        estimatedDuration: workout.estimatedDuration,
                        notes: workout.notes
                    )
                }
            )

            return plan
        } catch {
            throw AIError.parsingError("Failed to parse workout plan: \(error.localizedDescription)")
        }
    }

    private func categoryForGoal(_ goal: QWorkoutGoal) -> ExerciseCategory {
        switch goal {
        case .strength: return .strength
        case .muscle: return .strength
        case .fatLoss: return .hiit
        case .endurance: return .cardio
        case .general: return .strength
        case .athletic: return .hiit
        }
    }

    private func difficultyForLevel(_ level: ExperienceLevel) -> Difficulty {
        switch level {
        case .beginner: return .beginner
        case .intermediate: return .intermediate
        case .advanced: return .advanced
        }
    }

    private func findOrCreateExercise(name: String, in context: ModelContext) -> Exercise {
        // Try to find existing exercise
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)

        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.name.localizedStandardContains(normalizedName)
            }
        )

        if let exercises = try? context.fetch(descriptor),
           let existing = exercises.first {
            return existing
        }

        // Create new exercise
        let exercise = Exercise(
            name: name,
            muscleGroup: .fullBody,
            equipment: .bodyweight,
            category: .strength,
            difficulty: .intermediate
        )

        context.insert(exercise)
        return exercise
    }

    private func parseReps(_ reps: String) -> Int {
        // Parse rep ranges like "8-12" to get the target (middle or first number)
        let numbers = reps.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }

        if numbers.count >= 2 {
            return (numbers[0] + numbers[1]) / 2
        } else if let first = numbers.first {
            return first
        }

        return 10 // Default
    }
}
