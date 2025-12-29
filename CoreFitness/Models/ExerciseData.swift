import Foundation
import SwiftData

// MARK: - Exercise Data
/// Contains all predefined exercises for the library
struct ExerciseData {

    // MARK: - Seed Exercises
    @MainActor
    static func seedExercises(in context: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else {
            // Even if exercises exist, update missing data and clean up duplicates
            removeDuplicateExercises(in: context)
            updateExerciseVideoURLs(in: context)
            updateExerciseImageIds(in: context)
            return
        }

        // Create all exercises
        let exercises = allExercises()
        for exercise in exercises {
            context.insert(exercise)
        }

        try? context.save()
    }

    // MARK: - Update Video URLs
    /// Updates existing exercises with video URLs if they're missing
    @MainActor
    static func updateExerciseVideoURLs(in context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        guard let existingExercises = try? context.fetch(descriptor) else { return }

        // Create a lookup of video URLs by exercise name
        let templateExercises = allExercises()
        var videoURLLookup: [String: String] = [:]
        for exercise in templateExercises {
            if let url = exercise.videoURL, !url.isEmpty {
                videoURLLookup[exercise.name.lowercased()] = url
            }
        }

        var updatedCount = 0
        for exercise in existingExercises {
            // Only update if exercise doesn't have a video URL
            if exercise.videoURL == nil || exercise.videoURL?.isEmpty == true {
                if let url = videoURLLookup[exercise.name.lowercased()] {
                    exercise.videoURL = url
                    updatedCount += 1
                }
            }
        }

        if updatedCount > 0 {
            try? context.save()
            print("Updated \(updatedCount) exercises with video URLs")
        }
    }

    // MARK: - Remove Duplicate Exercises
    /// Removes duplicate exercises from the database, keeping the one with the most complete data
    @MainActor
    static func removeDuplicateExercises(in context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let allExercises = try? context.fetch(descriptor) else { return }

        // Group exercises by lowercase name
        var exercisesByName: [String: [Exercise]] = [:]
        for exercise in allExercises {
            let key = exercise.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            exercisesByName[key, default: []].append(exercise)
        }

        var deletedCount = 0

        for (_, exercises) in exercisesByName {
            guard exercises.count > 1 else { continue }

            // Sort by completeness score (prefer exercises with more data)
            let sorted = exercises.sorted { e1, e2 in
                let score1 = completenessScore(for: e1)
                let score2 = completenessScore(for: e2)
                return score1 > score2
            }

            // Keep the first (most complete), delete the rest
            let toKeep = sorted[0]
            for exercise in sorted.dropFirst() {
                // Don't delete if it's referenced by workouts
                if exercise.workoutExercises?.isEmpty == false {
                    // Merge data into the one we're keeping if needed
                    mergeExerciseData(from: exercise, into: toKeep)
                }
                context.delete(exercise)
                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            try? context.save()
            print("Removed \(deletedCount) duplicate exercises")
        }
    }

    /// Calculate a completeness score for an exercise (higher = more complete)
    private static func completenessScore(for exercise: Exercise) -> Int {
        var score = 0
        if let imageId = exercise.imageId, !imageId.isEmpty { score += 3 }
        if let videoURL = exercise.videoURL, !videoURL.isEmpty { score += 2 }
        if let instructions = exercise.instructions, !instructions.isEmpty { score += 2 }
        if let calories = exercise.estimatedCaloriesPerMinute, calories > 0 { score += 1 }
        // Prefer exercises that are used in workouts
        if let workouts = exercise.workoutExercises, !workouts.isEmpty { score += 5 }
        return score
    }

    /// Merge data from source exercise into target if target is missing data
    private static func mergeExerciseData(from source: Exercise, into target: Exercise) {
        if (target.imageId == nil || target.imageId?.isEmpty == true), let sourceImageId = source.imageId {
            target.imageId = sourceImageId
        }
        if (target.videoURL == nil || target.videoURL?.isEmpty == true), let sourceVideoURL = source.videoURL {
            target.videoURL = sourceVideoURL
        }
        if (target.instructions == nil || target.instructions?.isEmpty == true), let sourceInstructions = source.instructions {
            target.instructions = sourceInstructions
        }
    }

    // MARK: - Update Image IDs
    /// Updates existing exercises with imageIds if they're missing
    @MainActor
    static func updateExerciseImageIds(in context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        guard let existingExercises = try? context.fetch(descriptor) else { return }

        // Create a lookup of imageIds by exercise name
        let templateExercises = allExercises()
        var imageIdLookup: [String: String] = [:]
        for exercise in templateExercises {
            if let imageId = exercise.imageId, !imageId.isEmpty {
                imageIdLookup[exercise.name.lowercased()] = imageId
            }
        }

        var updatedCount = 0
        for exercise in existingExercises {
            // Only update if exercise doesn't have an imageId
            if exercise.imageId == nil || exercise.imageId?.isEmpty == true {
                if let imageId = imageIdLookup[exercise.name.lowercased()] {
                    exercise.imageId = imageId
                    updatedCount += 1
                }
            }
        }

        if updatedCount > 0 {
            try? context.save()
            print("Updated \(updatedCount) exercises with imageIds")
        }
    }

    // MARK: - All Exercises
    static func allExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        // Strength - Chest
        exercises.append(contentsOf: [
            Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Lie on bench, grip barbell slightly wider than shoulder width. Lower to chest, press up.", imageId: "Barbell_Bench_Press_-_Medium_Grip"),
            Exercise(name: "Incline Bench Press", muscleGroup: .chest, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Set bench to 30-45 degree incline. Press barbell from upper chest.", imageId: "Barbell_Incline_Bench_Press_-_Medium_Grip"),
            Exercise(name: "Decline Bench Press", muscleGroup: .chest, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Set bench to decline. Press barbell from lower chest.", imageId: "Decline_Barbell_Bench_Press"),
            Exercise(name: "Dumbbell Bench Press", muscleGroup: .chest, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 6, instructions: "Lie on bench with dumbbells. Press up, bringing dumbbells together at top.", imageId: "Dumbbell_Bench_Press"),
            Exercise(name: "Dumbbell Flyes", muscleGroup: .chest, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Lie on bench, arms extended. Lower weights in arc motion, squeeze chest to bring back up.", imageId: "Dumbbell_Flyes"),
            Exercise(name: "Push-Ups", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 8, instructions: "Hands shoulder-width apart, lower chest to ground, push back up. Keep core tight.", imageId: "Pushups"),
            Exercise(name: "Diamond Push-Ups", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 8, instructions: "Hands together forming diamond shape. Lower and press up.", imageId: "Push-Ups_-_Close_Triceps_Position"),
            Exercise(name: "Wide Push-Ups", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 7, instructions: "Hands wider than shoulder width. Lower and press up.", imageId: "Push-Up_Wide"),
            Exercise(name: "Cable Crossover", muscleGroup: .chest, equipment: .cable, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Stand between cables, bring handles together in front of chest in arc motion.", imageId: "Cable_Crossover"),
            Exercise(name: "Chest Dips", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 8, instructions: "On dip bars, lean forward slightly. Lower body, press back up.", imageId: "Dips_-_Chest_Version"),
        ])

        // Strength - Back
        exercises.append(contentsOf: [
            Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell, category: .strength, difficulty: .advanced, location: .gym, estimatedCaloriesPerMinute: 10, instructions: "Stand with feet hip-width, grip barbell. Keep back straight, lift by extending hips and knees.", imageId: "Barbell_Deadlift"),
            Exercise(name: "Bent Over Row", muscleGroup: .back, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Hinge at hips, pull barbell to lower chest. Squeeze shoulder blades together.", imageId: "Bent_Over_Barbell_Row"),
            Exercise(name: "Pull-Ups", muscleGroup: .back, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 9, instructions: "Hang from bar, pull chin above bar. Lower with control.", imageId: "Pullups"),
            Exercise(name: "Chin-Ups", muscleGroup: .back, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 9, instructions: "Underhand grip, pull chin above bar. Focus on squeezing biceps and back.", imageId: "Chin-Up"),
            Exercise(name: "Lat Pulldown", muscleGroup: .back, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 6, instructions: "Grip bar wide, pull down to upper chest. Squeeze lats at bottom.", imageId: "Wide-Grip_Lat_Pulldown"),
            Exercise(name: "Seated Cable Row", muscleGroup: .back, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 6, instructions: "Sit with feet on platform, pull handle to torso. Keep back straight.", imageId: "Seated_Cable_Rows"),
            Exercise(name: "Single Arm Dumbbell Row", muscleGroup: .back, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 6, instructions: "One hand and knee on bench, row dumbbell to hip.", imageId: "One-Arm_Dumbbell_Row"),
            Exercise(name: "T-Bar Row", muscleGroup: .back, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Straddle barbell, grip handle, row weight to chest.", imageId: "T-Bar_Row_with_Handle"),
            Exercise(name: "Face Pull", muscleGroup: .back, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Pull rope attachment to face level, separating hands at end.", imageId: "Face_Pull"),
            Exercise(name: "Inverted Row", muscleGroup: .back, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Hang under bar, pull chest to bar keeping body straight.", imageId: "Inverted_Row"),
        ])

        // Strength - Shoulders
        exercises.append(contentsOf: [
            Exercise(name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Stand with barbell at shoulders, press overhead. Keep core tight.", imageId: "Barbell_Shoulder_Press"),
            Exercise(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 6, instructions: "Seated or standing, press dumbbells overhead from shoulder level.", imageId: "Dumbbell_Shoulder_Press"),
            Exercise(name: "Arnold Press", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 6, instructions: "Start with palms facing you, rotate as you press overhead.", imageId: "Arnold_Dumbbell_Press"),
            Exercise(name: "Lateral Raises", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Arms at sides, raise dumbbells out to shoulder height.", imageId: "Side_Lateral_Raise"),
            Exercise(name: "Front Raises", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Arms in front, raise dumbbells to shoulder height.", imageId: "Front_Dumbbell_Raise"),
            Exercise(name: "Rear Delt Flyes", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Bent over, raise dumbbells out to sides squeezing rear delts.", imageId: "Seated_Bent-Over_Rear_Delt_Raise"),
            Exercise(name: "Pike Push-Ups", muscleGroup: .shoulders, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 7, instructions: "In pike position (inverted V), lower head toward ground.", imageId: "Decline_Push-Up"),
            Exercise(name: "Handstand Push-Ups", muscleGroup: .shoulders, equipment: .bodyweight, category: .calisthenics, difficulty: .advanced, location: .home, estimatedCaloriesPerMinute: 9, instructions: "Against wall in handstand, lower head to ground and press up.", imageId: "Handstand_Push-Ups"),
            Exercise(name: "Upright Row", muscleGroup: .shoulders, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 6, instructions: "Grip barbell close, pull up to chin leading with elbows.", imageId: "Upright_Barbell_Row"),
            Exercise(name: "Shrugs", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 4, instructions: "Hold dumbbells at sides, shrug shoulders up toward ears.", imageId: "Dumbbell_Shrug"),
        ])

        // Strength - Arms
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Curl", muscleGroup: .biceps, equipment: .barbell, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Stand with barbell, curl up keeping elbows stationary.", imageId: "Barbell_Curl"),
            Exercise(name: "Dumbbell Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Curl dumbbells alternating or together. Control the movement.", imageId: "Dumbbell_Bicep_Curl"),
            Exercise(name: "Hammer Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Palms facing each other, curl dumbbells up.", imageId: "Hammer_Curls"),
            Exercise(name: "Preacher Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Arms on preacher bench pad, curl weight up.", imageId: "Preacher_Curl"),
            Exercise(name: "Concentration Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 4, instructions: "Seated, elbow on inner thigh, curl dumbbell up.", imageId: "Concentration_Curls"),
            Exercise(name: "Tricep Pushdown", muscleGroup: .triceps, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Push cable attachment down, keeping elbows at sides.", imageId: "Triceps_Pushdown"),
            Exercise(name: "Skull Crushers", muscleGroup: .triceps, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Lie on bench, lower barbell to forehead, extend arms.", imageId: "EZ-Bar_Skullcrusher"),
            Exercise(name: "Overhead Tricep Extension", muscleGroup: .triceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Hold dumbbell overhead, lower behind head, extend.", imageId: "Standing_Dumbbell_Triceps_Extension"),
            Exercise(name: "Tricep Dips", muscleGroup: .triceps, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Hands on bench behind you, lower and press up.", imageId: "Bench_Dips"),
            Exercise(name: "Close Grip Bench Press", muscleGroup: .triceps, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Hands close together on barbell, press focusing on triceps.", imageId: "Close-Grip_Barbell_Bench_Press"),
        ])

        // Strength - Legs
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Squat", muscleGroup: .quadriceps, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 9, instructions: "Bar on upper back, squat down until thighs parallel. Drive through heels.", imageId: "Barbell_Squat"),
            Exercise(name: "Front Squat", muscleGroup: .quadriceps, equipment: .barbell, category: .strength, difficulty: .advanced, location: .gym, estimatedCaloriesPerMinute: 9, instructions: "Bar on front of shoulders, squat keeping torso upright.", imageId: "Front_Barbell_Squat"),
            Exercise(name: "Goblet Squat", muscleGroup: .quadriceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 8, instructions: "Hold dumbbell at chest, squat down between legs.", imageId: "Goblet_Squat"),
            Exercise(name: "Leg Press", muscleGroup: .quadriceps, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Press platform away, lower with control. Don't lock knees.", imageId: "Leg_Press"),
            Exercise(name: "Leg Extension", muscleGroup: .quadriceps, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Extend legs against pad, squeeze quads at top.", imageId: "Leg_Extensions"),
            Exercise(name: "Lunges", muscleGroup: .quadriceps, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Step forward, lower back knee toward ground. Push back up.", imageId: "Dumbbell_Lunges"),
            Exercise(name: "Walking Lunges", muscleGroup: .quadriceps, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 8, instructions: "Continuous lunges moving forward. Keep torso upright.", imageId: "Bodyweight_Walking_Lunge"),
            Exercise(name: "Bulgarian Split Squat", muscleGroup: .quadriceps, equipment: .bodyweight, category: .strength, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 8, instructions: "Rear foot elevated, squat on front leg.", imageId: "Split_Squat_with_Dumbbells"),
            Exercise(name: "Romanian Deadlift", muscleGroup: .hamstrings, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 8, instructions: "Slight knee bend, hinge at hips lowering bar along legs.", imageId: "Romanian_Deadlift"),
            Exercise(name: "Leg Curl", muscleGroup: .hamstrings, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Curl legs under pad, squeeze hamstrings.", imageId: "Lying_Leg_Curls"),
            Exercise(name: "Hip Thrust", muscleGroup: .glutes, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Upper back on bench, thrust hips up with barbell on hips.", imageId: "Barbell_Hip_Thrust"),
            Exercise(name: "Glute Bridge", muscleGroup: .glutes, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Lie on back, drive hips up squeezing glutes.", imageId: "Barbell_Glute_Bridge"),
            Exercise(name: "Calf Raises", muscleGroup: .calves, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 4, instructions: "Rise up on toes, lower with control. Can add weight.", imageId: "Standing_Calf_Raises"),
            Exercise(name: "Seated Calf Raises", muscleGroup: .calves, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 4, instructions: "Seated, raise heels up against pad.", imageId: "Seated_Calf_Raise"),
        ])

        // Core
        exercises.append(contentsOf: [
            Exercise(name: "Plank", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Hold push-up position on forearms. Keep body straight, core tight.", imageId: "Plank"),
            Exercise(name: "Side Plank", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 4, instructions: "On side, prop on elbow. Keep body in straight line.", imageId: "Side_Bridge"),
            Exercise(name: "Crunches", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Lie on back, curl shoulders toward hips. Don't pull on neck.", imageId: "Crunches"),
            Exercise(name: "Bicycle Crunches", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 7, instructions: "Alternate elbow to opposite knee in cycling motion.", imageId: "Air_Bike"),
            Exercise(name: "Leg Raises", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Lie flat, raise legs to vertical. Lower with control.", imageId: "Flat_Bench_Lying_Leg_Raise"),
            Exercise(name: "Hanging Leg Raises", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .advanced, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Hang from bar, raise legs to parallel or higher.", imageId: "Hanging_Leg_Raise"),
            Exercise(name: "Russian Twists", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Seated, lean back, rotate torso side to side.", imageId: "Russian_Twist"),
            Exercise(name: "Dead Bug", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "On back, alternate extending opposite arm and leg.", imageId: "Dead_Bug"),
            Exercise(name: "Mountain Climbers", muscleGroup: .core, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 10, instructions: "In plank position, drive knees alternately toward chest quickly.", imageId: "Mountain_Climbers"),
            Exercise(name: "Ab Wheel Rollout", muscleGroup: .core, equipment: .other, category: .calisthenics, difficulty: .advanced, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Kneel with ab wheel, roll out keeping core tight. Roll back.", imageId: "Ab_Roller"),
        ])

        // Cardio
        exercises.append(contentsOf: [
            Exercise(name: "Running", muscleGroup: .fullBody, equipment: .bodyweight, category: .running, difficulty: .beginner, location: .outdoor, estimatedCaloriesPerMinute: 12, instructions: "Maintain steady pace. Land midfoot, keep posture upright.", imageId: "Running_Treadmill"),
            Exercise(name: "Sprints", muscleGroup: .fullBody, equipment: .bodyweight, category: .running, difficulty: .intermediate, location: .outdoor, estimatedCaloriesPerMinute: 15, instructions: "Maximum effort short bursts. Full recovery between.", imageId: "Wind_Sprints"),
            Exercise(name: "Treadmill Running", muscleGroup: .fullBody, equipment: .machine, category: .running, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 11, instructions: "Adjust speed and incline. Maintain good running form.", imageId: "Running_Treadmill"),
            Exercise(name: "Cycling", muscleGroup: .quadriceps, equipment: .machine, category: .cycling, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 10, instructions: "Maintain steady cadence. Adjust resistance as needed.", imageId: "Bicycling_Stationary"),
            Exercise(name: "Spinning", muscleGroup: .quadriceps, equipment: .machine, category: .cycling, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 12, instructions: "High intensity cycling with varying resistance.", imageId: "Bicycling_Stationary"),
            Exercise(name: "Rowing Machine", muscleGroup: .fullBody, equipment: .machine, category: .cardio, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 11, instructions: "Drive with legs first, then pull with back and arms.", imageId: "Rowing_Stationary"),
            Exercise(name: "Stair Climber", muscleGroup: .quadriceps, equipment: .machine, category: .cardio, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 10, instructions: "Climb stairs at steady pace. Hold rails lightly for balance only.", imageId: "Step_Mill"),
            Exercise(name: "Elliptical", muscleGroup: .fullBody, equipment: .machine, category: .cardio, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 9, instructions: "Smooth elliptical motion. Use arms for full body workout.", imageId: "Elliptical_Trainer"),
            Exercise(name: "Jump Rope", muscleGroup: .fullBody, equipment: .other, category: .cardio, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 13, instructions: "Jump with both feet, turn rope with wrists.", imageId: "Rope_Jumping"),
            Exercise(name: "Swimming Laps", muscleGroup: .fullBody, equipment: .other, category: .swimming, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 11, instructions: "Continuous laps using preferred stroke."),
        ])

        // HIIT
        exercises.append(contentsOf: [
            Exercise(name: "Burpees", muscleGroup: .fullBody, equipment: .bodyweight, category: .hiit, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 14, instructions: "Squat down, kick back to plank, push-up, jump up with hands overhead.", imageId: "Bottoms_Up"),
            Exercise(name: "Box Jumps", muscleGroup: .quadriceps, equipment: .other, category: .hiit, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 12, instructions: "Jump onto box, step or jump down. Land softly.", imageId: "Box_Jump_Multiple_Response"),
            Exercise(name: "Jumping Jacks", muscleGroup: .fullBody, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 9, instructions: "Jump spreading legs and raising arms. Return to start.", imageId: "Star_Jump"),
            Exercise(name: "High Knees", muscleGroup: .fullBody, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 10, instructions: "Run in place bringing knees up high quickly.", imageId: "Fast_Skipping"),
            Exercise(name: "Squat Jumps", muscleGroup: .quadriceps, equipment: .bodyweight, category: .hiit, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 11, instructions: "Squat down, explode upward. Land softly.", imageId: "Freehand_Jump_Squat"),
            Exercise(name: "Battle Ropes", muscleGroup: .fullBody, equipment: .other, category: .hiit, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 13, instructions: "Create waves with heavy ropes using alternating or double arm movements.", imageId: "Battling_Ropes"),
            Exercise(name: "Kettlebell Swings", muscleGroup: .fullBody, equipment: .kettlebell, category: .hiit, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 12, instructions: "Hinge at hips, swing kettlebell between legs and up to shoulder height.", imageId: "One-Arm_Kettlebell_Swings"),
            Exercise(name: "Sled Push", muscleGroup: .fullBody, equipment: .other, category: .hiit, difficulty: .advanced, location: .gym, estimatedCaloriesPerMinute: 14, instructions: "Push weighted sled across floor. Drive with legs.", imageId: "Sled_Push"),
            Exercise(name: "Tuck Jumps", muscleGroup: .quadriceps, equipment: .bodyweight, category: .hiit, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 12, instructions: "Jump up bringing knees to chest. Land softly.", imageId: "Knee_Tuck_Jump"),
            Exercise(name: "Skaters", muscleGroup: .quadriceps, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 10, instructions: "Leap side to side, landing on one leg like a speed skater.", imageId: "Skating"),
        ])

        // Yoga
        exercises.append(contentsOf: [
            Exercise(name: "Downward Dog", muscleGroup: .fullBody, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 4, instructions: "Form inverted V shape. Hands and feet on ground, hips high."),
            Exercise(name: "Warrior I", muscleGroup: .quadriceps, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 4, instructions: "Lunge position, back foot angled. Arms overhead, hips forward."),
            Exercise(name: "Warrior II", muscleGroup: .quadriceps, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 4, instructions: "Wide stance, front knee bent. Arms extended, gaze over front hand."),
            Exercise(name: "Warrior III", muscleGroup: .fullBody, equipment: .bodyweight, category: .yoga, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Balance on one leg, body parallel to ground, arms forward."),
            Exercise(name: "Tree Pose", muscleGroup: .core, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 3, instructions: "Stand on one leg, other foot on inner thigh. Arms overhead or at heart."),
            Exercise(name: "Chair Pose", muscleGroup: .quadriceps, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Feet together, sit back as if in chair. Arms overhead."),
            Exercise(name: "Cobra Pose", muscleGroup: .back, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 3, instructions: "Lie face down, press up arching back. Keep hips on ground."),
            Exercise(name: "Child's Pose", muscleGroup: .fullBody, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Kneel, sit back on heels, reach arms forward. Rest forehead on ground."),
            Exercise(name: "Cat-Cow Stretch", muscleGroup: .back, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 3, instructions: "On all fours, alternate arching and rounding spine."),
            Exercise(name: "Pigeon Pose", muscleGroup: .glutes, equipment: .bodyweight, category: .yoga, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 3, instructions: "One leg bent in front, other extended back. Deep hip stretch."),
            Exercise(name: "Triangle Pose", muscleGroup: .fullBody, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 4, instructions: "Wide stance, reach down to shin, other arm up. Open chest."),
            Exercise(name: "Bridge Pose", muscleGroup: .glutes, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 4, instructions: "Lie on back, lift hips. Clasp hands under back if able."),
            Exercise(name: "Plank Pose", muscleGroup: .core, equipment: .bodyweight, category: .yoga, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Hold top of push-up position. Keep body straight."),
            Exercise(name: "Boat Pose", muscleGroup: .core, equipment: .bodyweight, category: .yoga, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Balance on sit bones, legs and torso lifted in V shape."),
            Exercise(name: "Crow Pose", muscleGroup: .core, equipment: .bodyweight, category: .yoga, difficulty: .advanced, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Balance on hands with knees on upper arms."),
        ])

        // Stretching
        exercises.append(contentsOf: [
            Exercise(name: "Quad Stretch", muscleGroup: .quadriceps, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Standing or lying, pull foot to glutes. Keep knees together."),
            Exercise(name: "Hamstring Stretch", muscleGroup: .hamstrings, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Extend leg on elevated surface or seated, reach toward toes."),
            Exercise(name: "Hip Flexor Stretch", muscleGroup: .quadriceps, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Lunge position, push hips forward feeling stretch in front hip."),
            Exercise(name: "Chest Stretch", muscleGroup: .chest, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Arm on wall or doorframe, rotate body away to stretch chest."),
            Exercise(name: "Shoulder Stretch", muscleGroup: .shoulders, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Pull arm across body with other hand. Hold 20-30 seconds."),
            Exercise(name: "Tricep Stretch", muscleGroup: .triceps, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Reach arm overhead, bend elbow, push elbow with other hand."),
            Exercise(name: "Neck Rolls", muscleGroup: .fullBody, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Slowly roll head in circles. Reverse direction."),
            Exercise(name: "Spinal Twist", muscleGroup: .back, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Seated or lying, rotate torso looking opposite of knees."),
            Exercise(name: "Butterfly Stretch", muscleGroup: .glutes, equipment: .bodyweight, category: .stretching, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 2, instructions: "Seated, soles of feet together, press knees down gently."),
            Exercise(name: "Foam Rolling", muscleGroup: .fullBody, equipment: .other, category: .stretching, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 3, instructions: "Roll muscles over foam roller to release tension."),
        ])

        return exercises
    }
}
