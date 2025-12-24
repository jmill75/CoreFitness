import SwiftUI
import SwiftData

// MARK: - Sample Workout Data
/// Helper to create sample workout data for testing and development
struct SampleWorkoutData {

    /// Load existing sample workout or create a new one
    static func loadOrCreateSampleWorkout(in context: ModelContext) -> Workout? {
        // Try to fetch existing workout
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.name == "Upper Body Strength" }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        // Create new sample workout
        return createSampleWorkout(in: context)
    }

    /// Create a new sample workout with exercises
    static func createSampleWorkout(in context: ModelContext) -> Workout {
        // Create exercises
        let benchPress = Exercise(
            name: "Bench Press",
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: "Lie on a flat bench, grip the bar slightly wider than shoulder-width. Lower to chest, then press up."
        )

        let inclineDumbbell = Exercise(
            name: "Incline Dumbbell Press",
            muscleGroup: .chest,
            equipment: .dumbbell,
            instructions: "Set bench to 30-45 degrees. Press dumbbells from shoulder level to full extension."
        )

        let barbellRow = Exercise(
            name: "Barbell Row",
            muscleGroup: .back,
            equipment: .barbell,
            instructions: "Hinge at hips, pull barbell to lower chest. Keep back flat and core engaged."
        )

        let overheadPress = Exercise(
            name: "Overhead Press",
            muscleGroup: .shoulders,
            equipment: .barbell,
            instructions: "Press barbell from shoulder level overhead. Keep core tight and avoid excessive back arch."
        )

        let latPulldown = Exercise(
            name: "Lat Pulldown",
            muscleGroup: .back,
            equipment: .cable,
            instructions: "Pull bar to upper chest, squeezing shoulder blades together. Control the negative."
        )

        let tricepPushdown = Exercise(
            name: "Tricep Pushdown",
            muscleGroup: .triceps,
            equipment: .cable,
            instructions: "Keep elbows pinned to sides, extend arms fully. Squeeze at the bottom."
        )

        // Insert exercises
        context.insert(benchPress)
        context.insert(inclineDumbbell)
        context.insert(barbellRow)
        context.insert(overheadPress)
        context.insert(latPulldown)
        context.insert(tricepPushdown)

        // Create workout
        let workout = Workout(
            name: "Upper Body Strength",
            description: "A comprehensive upper body workout targeting chest, back, shoulders, and arms.",
            estimatedDuration: 45,
            difficulty: .intermediate
        )
        context.insert(workout)

        // Create workout exercises with targets
        let workoutExercises = [
            createWorkoutExercise(
                order: 0,
                exercise: benchPress,
                workout: workout,
                targetSets: 4,
                targetReps: 8,
                targetWeight: 135,
                restDuration: 90,
                context: context
            ),
            createWorkoutExercise(
                order: 1,
                exercise: inclineDumbbell,
                workout: workout,
                targetSets: 3,
                targetReps: 10,
                targetWeight: 50,
                restDuration: 75,
                context: context
            ),
            createWorkoutExercise(
                order: 2,
                exercise: barbellRow,
                workout: workout,
                targetSets: 4,
                targetReps: 8,
                targetWeight: 115,
                restDuration: 90,
                context: context
            ),
            createWorkoutExercise(
                order: 3,
                exercise: overheadPress,
                workout: workout,
                targetSets: 3,
                targetReps: 10,
                targetWeight: 85,
                restDuration: 75,
                context: context
            ),
            createWorkoutExercise(
                order: 4,
                exercise: latPulldown,
                workout: workout,
                targetSets: 3,
                targetReps: 12,
                targetWeight: 100,
                restDuration: 60,
                context: context
            ),
            createWorkoutExercise(
                order: 5,
                exercise: tricepPushdown,
                workout: workout,
                targetSets: 3,
                targetReps: 15,
                targetWeight: 40,
                restDuration: 45,
                context: context
            )
        ]

        // Assign exercises to workout
        workout.exercises = workoutExercises

        // Save
        try? context.save()

        return workout
    }

    private static func createWorkoutExercise(
        order: Int,
        exercise: Exercise,
        workout: Workout,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double,
        restDuration: Int,
        context: ModelContext
    ) -> WorkoutExercise {
        let workoutExercise = WorkoutExercise(
            order: order,
            targetSets: targetSets,
            targetReps: targetReps,
            targetWeight: targetWeight,
            restDuration: restDuration
        )
        workoutExercise.exercise = exercise
        workoutExercise.workout = workout
        context.insert(workoutExercise)
        return workoutExercise
    }

    /// Create a quick workout (fewer exercises for quick testing)
    static func createQuickWorkout(in context: ModelContext) -> Workout {
        let benchPress = Exercise(
            name: "Bench Press",
            muscleGroup: .chest,
            equipment: .barbell
        )

        let squat = Exercise(
            name: "Squat",
            muscleGroup: .quadriceps,
            equipment: .barbell
        )

        context.insert(benchPress)
        context.insert(squat)

        let workout = Workout(
            name: "Quick Workout",
            description: "A quick 2-exercise workout for testing.",
            estimatedDuration: 15,
            difficulty: .beginner
        )
        context.insert(workout)

        let exercises = [
            createWorkoutExercise(
                order: 0,
                exercise: benchPress,
                workout: workout,
                targetSets: 3,
                targetReps: 10,
                targetWeight: 135,
                restDuration: 60,
                context: context
            ),
            createWorkoutExercise(
                order: 1,
                exercise: squat,
                workout: workout,
                targetSets: 3,
                targetReps: 10,
                targetWeight: 155,
                restDuration: 90,
                context: context
            )
        ]

        workout.exercises = exercises
        try? context.save()

        return workout
    }
}
