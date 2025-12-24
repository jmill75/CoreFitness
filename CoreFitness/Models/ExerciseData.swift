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

        guard existingCount == 0 else { return }

        // Create all exercises
        let exercises = allExercises()
        for exercise in exercises {
            context.insert(exercise)
        }

        try? context.save()
    }

    // MARK: - All Exercises
    static func allExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        // Strength - Chest
        exercises.append(contentsOf: [
            Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Lie on bench, grip barbell slightly wider than shoulder width. Lower to chest, press up."),
            Exercise(name: "Incline Bench Press", muscleGroup: .chest, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Set bench to 30-45 degree incline. Press barbell from upper chest."),
            Exercise(name: "Decline Bench Press", muscleGroup: .chest, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Set bench to decline. Press barbell from lower chest."),
            Exercise(name: "Dumbbell Bench Press", muscleGroup: .chest, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 6, instructions: "Lie on bench with dumbbells. Press up, bringing dumbbells together at top."),
            Exercise(name: "Dumbbell Flyes", muscleGroup: .chest, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Lie on bench, arms extended. Lower weights in arc motion, squeeze chest to bring back up."),
            Exercise(name: "Push-Ups", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 8, instructions: "Hands shoulder-width apart, lower chest to ground, push back up. Keep core tight."),
            Exercise(name: "Diamond Push-Ups", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 8, instructions: "Hands together forming diamond shape. Lower and press up."),
            Exercise(name: "Wide Push-Ups", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 7, instructions: "Hands wider than shoulder width. Lower and press up."),
            Exercise(name: "Cable Crossover", muscleGroup: .chest, equipment: .cable, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Stand between cables, bring handles together in front of chest in arc motion."),
            Exercise(name: "Chest Dips", muscleGroup: .chest, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 8, instructions: "On dip bars, lean forward slightly. Lower body, press back up."),
        ])

        // Strength - Back
        exercises.append(contentsOf: [
            Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell, category: .strength, difficulty: .advanced, location: .gym, estimatedCaloriesPerMinute: 10, instructions: "Stand with feet hip-width, grip barbell. Keep back straight, lift by extending hips and knees."),
            Exercise(name: "Bent Over Row", muscleGroup: .back, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Hinge at hips, pull barbell to lower chest. Squeeze shoulder blades together."),
            Exercise(name: "Pull-Ups", muscleGroup: .back, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 9, instructions: "Hang from bar, pull chin above bar. Lower with control."),
            Exercise(name: "Chin-Ups", muscleGroup: .back, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 9, instructions: "Underhand grip, pull chin above bar. Focus on squeezing biceps and back."),
            Exercise(name: "Lat Pulldown", muscleGroup: .back, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 6, instructions: "Grip bar wide, pull down to upper chest. Squeeze lats at bottom."),
            Exercise(name: "Seated Cable Row", muscleGroup: .back, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 6, instructions: "Sit with feet on platform, pull handle to torso. Keep back straight."),
            Exercise(name: "Single Arm Dumbbell Row", muscleGroup: .back, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 6, instructions: "One hand and knee on bench, row dumbbell to hip."),
            Exercise(name: "T-Bar Row", muscleGroup: .back, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Straddle barbell, grip handle, row weight to chest."),
            Exercise(name: "Face Pull", muscleGroup: .back, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Pull rope attachment to face level, separating hands at end."),
            Exercise(name: "Inverted Row", muscleGroup: .back, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Hang under bar, pull chest to bar keeping body straight."),
        ])

        // Strength - Shoulders
        exercises.append(contentsOf: [
            Exercise(name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Stand with barbell at shoulders, press overhead. Keep core tight."),
            Exercise(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 6, instructions: "Seated or standing, press dumbbells overhead from shoulder level."),
            Exercise(name: "Arnold Press", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 6, instructions: "Start with palms facing you, rotate as you press overhead."),
            Exercise(name: "Lateral Raises", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Arms at sides, raise dumbbells out to shoulder height."),
            Exercise(name: "Front Raises", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Arms in front, raise dumbbells to shoulder height."),
            Exercise(name: "Rear Delt Flyes", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Bent over, raise dumbbells out to sides squeezing rear delts."),
            Exercise(name: "Pike Push-Ups", muscleGroup: .shoulders, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 7, instructions: "In pike position (inverted V), lower head toward ground."),
            Exercise(name: "Handstand Push-Ups", muscleGroup: .shoulders, equipment: .bodyweight, category: .calisthenics, difficulty: .advanced, location: .home, estimatedCaloriesPerMinute: 9, instructions: "Against wall in handstand, lower head to ground and press up."),
            Exercise(name: "Upright Row", muscleGroup: .shoulders, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 6, instructions: "Grip barbell close, pull up to chin leading with elbows."),
            Exercise(name: "Shrugs", muscleGroup: .shoulders, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 4, instructions: "Hold dumbbells at sides, shrug shoulders up toward ears."),
        ])

        // Strength - Arms
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Curl", muscleGroup: .biceps, equipment: .barbell, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Stand with barbell, curl up keeping elbows stationary."),
            Exercise(name: "Dumbbell Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Curl dumbbells alternating or together. Control the movement."),
            Exercise(name: "Hammer Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Palms facing each other, curl dumbbells up."),
            Exercise(name: "Preacher Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Arms on preacher bench pad, curl weight up."),
            Exercise(name: "Concentration Curl", muscleGroup: .biceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 4, instructions: "Seated, elbow on inner thigh, curl dumbbell up."),
            Exercise(name: "Tricep Pushdown", muscleGroup: .triceps, equipment: .cable, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Push cable attachment down, keeping elbows at sides."),
            Exercise(name: "Skull Crushers", muscleGroup: .triceps, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Lie on bench, lower barbell to forehead, extend arms."),
            Exercise(name: "Overhead Tricep Extension", muscleGroup: .triceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 5, instructions: "Hold dumbbell overhead, lower behind head, extend."),
            Exercise(name: "Tricep Dips", muscleGroup: .triceps, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Hands on bench behind you, lower and press up."),
            Exercise(name: "Close Grip Bench Press", muscleGroup: .triceps, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Hands close together on barbell, press focusing on triceps."),
        ])

        // Strength - Legs
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Squat", muscleGroup: .quadriceps, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 9, instructions: "Bar on upper back, squat down until thighs parallel. Drive through heels."),
            Exercise(name: "Front Squat", muscleGroup: .quadriceps, equipment: .barbell, category: .strength, difficulty: .advanced, location: .gym, estimatedCaloriesPerMinute: 9, instructions: "Bar on front of shoulders, squat keeping torso upright."),
            Exercise(name: "Goblet Squat", muscleGroup: .quadriceps, equipment: .dumbbell, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 8, instructions: "Hold dumbbell at chest, squat down between legs."),
            Exercise(name: "Leg Press", muscleGroup: .quadriceps, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Press platform away, lower with control. Don't lock knees."),
            Exercise(name: "Leg Extension", muscleGroup: .quadriceps, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Extend legs against pad, squeeze quads at top."),
            Exercise(name: "Lunges", muscleGroup: .quadriceps, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Step forward, lower back knee toward ground. Push back up."),
            Exercise(name: "Walking Lunges", muscleGroup: .quadriceps, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 8, instructions: "Continuous lunges moving forward. Keep torso upright."),
            Exercise(name: "Bulgarian Split Squat", muscleGroup: .quadriceps, equipment: .bodyweight, category: .strength, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 8, instructions: "Rear foot elevated, squat on front leg."),
            Exercise(name: "Romanian Deadlift", muscleGroup: .hamstrings, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 8, instructions: "Slight knee bend, hinge at hips lowering bar along legs."),
            Exercise(name: "Leg Curl", muscleGroup: .hamstrings, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 5, instructions: "Curl legs under pad, squeeze hamstrings."),
            Exercise(name: "Hip Thrust", muscleGroup: .glutes, equipment: .barbell, category: .strength, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 7, instructions: "Upper back on bench, thrust hips up with barbell on hips."),
            Exercise(name: "Glute Bridge", muscleGroup: .glutes, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Lie on back, drive hips up squeezing glutes."),
            Exercise(name: "Calf Raises", muscleGroup: .calves, equipment: .bodyweight, category: .strength, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 4, instructions: "Rise up on toes, lower with control. Can add weight."),
            Exercise(name: "Seated Calf Raises", muscleGroup: .calves, equipment: .machine, category: .strength, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 4, instructions: "Seated, raise heels up against pad."),
        ])

        // Core
        exercises.append(contentsOf: [
            Exercise(name: "Plank", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "Hold push-up position on forearms. Keep body straight, core tight."),
            Exercise(name: "Side Plank", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 4, instructions: "On side, prop on elbow. Keep body in straight line."),
            Exercise(name: "Crunches", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Lie on back, curl shoulders toward hips. Don't pull on neck."),
            Exercise(name: "Bicycle Crunches", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 7, instructions: "Alternate elbow to opposite knee in cycling motion."),
            Exercise(name: "Leg Raises", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Lie flat, raise legs to vertical. Lower with control."),
            Exercise(name: "Hanging Leg Raises", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .advanced, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Hang from bar, raise legs to parallel or higher."),
            Exercise(name: "Russian Twists", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 6, instructions: "Seated, lean back, rotate torso side to side."),
            Exercise(name: "Dead Bug", muscleGroup: .core, equipment: .bodyweight, category: .calisthenics, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 5, instructions: "On back, alternate extending opposite arm and leg."),
            Exercise(name: "Mountain Climbers", muscleGroup: .core, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 10, instructions: "In plank position, drive knees alternately toward chest quickly."),
            Exercise(name: "Ab Wheel Rollout", muscleGroup: .core, equipment: .other, category: .calisthenics, difficulty: .advanced, location: .both, estimatedCaloriesPerMinute: 7, instructions: "Kneel with ab wheel, roll out keeping core tight. Roll back."),
        ])

        // Cardio
        exercises.append(contentsOf: [
            Exercise(name: "Running", muscleGroup: .fullBody, equipment: .bodyweight, category: .running, difficulty: .beginner, location: .outdoor, estimatedCaloriesPerMinute: 12, instructions: "Maintain steady pace. Land midfoot, keep posture upright."),
            Exercise(name: "Sprints", muscleGroup: .fullBody, equipment: .bodyweight, category: .running, difficulty: .intermediate, location: .outdoor, estimatedCaloriesPerMinute: 15, instructions: "Maximum effort short bursts. Full recovery between."),
            Exercise(name: "Treadmill Running", muscleGroup: .fullBody, equipment: .machine, category: .running, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 11, instructions: "Adjust speed and incline. Maintain good running form."),
            Exercise(name: "Cycling", muscleGroup: .quadriceps, equipment: .machine, category: .cycling, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 10, instructions: "Maintain steady cadence. Adjust resistance as needed."),
            Exercise(name: "Spinning", muscleGroup: .quadriceps, equipment: .machine, category: .cycling, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 12, instructions: "High intensity cycling with varying resistance."),
            Exercise(name: "Rowing Machine", muscleGroup: .fullBody, equipment: .machine, category: .cardio, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 11, instructions: "Drive with legs first, then pull with back and arms."),
            Exercise(name: "Stair Climber", muscleGroup: .quadriceps, equipment: .machine, category: .cardio, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 10, instructions: "Climb stairs at steady pace. Hold rails lightly for balance only."),
            Exercise(name: "Elliptical", muscleGroup: .fullBody, equipment: .machine, category: .cardio, difficulty: .beginner, location: .gym, estimatedCaloriesPerMinute: 9, instructions: "Smooth elliptical motion. Use arms for full body workout."),
            Exercise(name: "Jump Rope", muscleGroup: .fullBody, equipment: .other, category: .cardio, difficulty: .beginner, location: .both, estimatedCaloriesPerMinute: 13, instructions: "Jump with both feet, turn rope with wrists."),
            Exercise(name: "Swimming Laps", muscleGroup: .fullBody, equipment: .other, category: .swimming, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 11, instructions: "Continuous laps using preferred stroke."),
        ])

        // HIIT
        exercises.append(contentsOf: [
            Exercise(name: "Burpees", muscleGroup: .fullBody, equipment: .bodyweight, category: .hiit, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 14, instructions: "Squat down, kick back to plank, push-up, jump up with hands overhead."),
            Exercise(name: "Box Jumps", muscleGroup: .quadriceps, equipment: .other, category: .hiit, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 12, instructions: "Jump onto box, step or jump down. Land softly."),
            Exercise(name: "Jumping Jacks", muscleGroup: .fullBody, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 9, instructions: "Jump spreading legs and raising arms. Return to start."),
            Exercise(name: "High Knees", muscleGroup: .fullBody, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 10, instructions: "Run in place bringing knees up high quickly."),
            Exercise(name: "Squat Jumps", muscleGroup: .quadriceps, equipment: .bodyweight, category: .hiit, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 11, instructions: "Squat down, explode upward. Land softly."),
            Exercise(name: "Battle Ropes", muscleGroup: .fullBody, equipment: .other, category: .hiit, difficulty: .intermediate, location: .gym, estimatedCaloriesPerMinute: 13, instructions: "Create waves with heavy ropes using alternating or double arm movements."),
            Exercise(name: "Kettlebell Swings", muscleGroup: .fullBody, equipment: .kettlebell, category: .hiit, difficulty: .intermediate, location: .both, estimatedCaloriesPerMinute: 12, instructions: "Hinge at hips, swing kettlebell between legs and up to shoulder height."),
            Exercise(name: "Sled Push", muscleGroup: .fullBody, equipment: .other, category: .hiit, difficulty: .advanced, location: .gym, estimatedCaloriesPerMinute: 14, instructions: "Push weighted sled across floor. Drive with legs."),
            Exercise(name: "Tuck Jumps", muscleGroup: .quadriceps, equipment: .bodyweight, category: .hiit, difficulty: .intermediate, location: .home, estimatedCaloriesPerMinute: 12, instructions: "Jump up bringing knees to chest. Land softly."),
            Exercise(name: "Skaters", muscleGroup: .quadriceps, equipment: .bodyweight, category: .hiit, difficulty: .beginner, location: .home, estimatedCaloriesPerMinute: 10, instructions: "Leap side to side, landing on one leg like a speed skater."),
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
