import Foundation
import SwiftData

// MARK: - Program Data Seeding
struct ProgramData {

    // Version number - increment this to trigger a re-seed of program data
    private static let currentVersion = 3

    /// Seeds all pre-built workout programs into the database
    static func seedPrograms(in context: ModelContext) {
        let savedVersion = UserDefaults.standard.integer(forKey: "ProgramDataVersion")

        // Check if we need to re-seed (version changed or first time)
        if savedVersion < currentVersion {
            // Delete existing programs to re-seed with updated data
            if savedVersion > 0 {
                let descriptor = FetchDescriptor<ProgramTemplate>()
                if let existingPrograms = try? context.fetch(descriptor) {
                    for program in existingPrograms {
                        context.delete(program)
                    }
                }
            }

            // Seed all categories
            seedStrengthPrograms(in: context)
            seedCardioPrograms(in: context)
            seedYogaPrograms(in: context)
            seedPilatesPrograms(in: context)
            seedHIITPrograms(in: context)
            seedStretchingPrograms(in: context)
            seedRunningPrograms(in: context)
            seedCyclingPrograms(in: context)
            seedSwimmingPrograms(in: context)
            seedCalisthenicsPrograms(in: context)

            try? context.save()

            // Update saved version
            UserDefaults.standard.set(currentVersion, forKey: "ProgramDataVersion")
        }
    }

    // MARK: - Strength Programs (10+)
    static func seedStrengthPrograms(in context: ModelContext) {

        // 1. Push Pull Legs - Classic 12 Week
        let ppl = ProgramTemplate(
            name: "Push Pull Legs Classic",
            description: "The gold standard bodybuilding split. Train each muscle group twice per week with dedicated push, pull, and leg days for maximum muscle growth.",
            category: .strength,
            difficulty: .intermediate,
            durationWeeks: 12,
            workoutsPerWeek: 6,
            estimatedMinutesPerSession: 60,
            goal: .muscleBuilding,
            equipmentRequired: ["Barbell", "Dumbbells", "Cable Machine", "Bench"],
            isFeatured: true
        )
        ppl.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Push Day A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Pull Day A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Legs Day A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Push Day B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Pull Day B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Legs Day B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true, notes: "Active recovery or complete rest")
        ]
        ppl.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Push Day A", description: "Chest, shoulders, triceps focus", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 4, reps: "6-8", weight: "RPE 8", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Press", sets: 3, reps: "8-10", weight: "RPE 7", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 3, reps: "8-10", weight: "RPE 7", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Tricep Pushdowns", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Overhead Tricep Extension", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Pull Day A", description: "Back, biceps, rear delts focus", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 4, reps: "5", weight: "RPE 8", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Pull-ups", sets: 3, reps: "6-10", weight: "Bodyweight", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 3, reps: "8-10", weight: "RPE 7", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "15-20", weight: "RPE 7", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Barbell Curls", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Hammer Curls", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Legs Day A", description: "Quad dominant leg day", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 4, reps: "6-8", weight: "RPE 8", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 3, reps: "10-12", weight: "RPE 7", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Leg Extensions", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 4, reps: "15-20", weight: "RPE 8", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Push Day B", description: "Volume push day", estimatedMinutes: 55, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dumbbell Bench Press", sets: 4, reps: "8-10", weight: "RPE 7", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Cable Flyes", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Arnold Press", sets: 3, reps: "10-12", weight: "RPE 7", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Cable Lateral Raises", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Dips", sets: 3, reps: "8-12", weight: "Bodyweight", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Skull Crushers", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Pull Day B", description: "Volume pull day", estimatedMinutes: 55, exercises: [
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 4, reps: "10-12", weight: "RPE 7", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Seated Cable Row", sets: 3, reps: "10-12", weight: "RPE 7", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Rows", sets: 3, reps: "10-12", weight: "RPE 7", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Reverse Flyes", sets: 3, reps: "15-20", weight: "RPE 7", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Curls", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Cable Curls", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Legs Day B", description: "Hamstring dominant leg day", estimatedMinutes: 55, exercises: [
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 4, reps: "8-10", weight: "RPE 8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Front Squats", sets: 3, reps: "8-10", weight: "RPE 7", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Bulgarian Split Squats", sets: 3, reps: "10-12", weight: "RPE 7", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Hip Thrusts", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Seated Calf Raises", sets: 4, reps: "15-20", weight: "RPE 8", restSeconds: 60)
            ])
        ]
        context.insert(ppl)

        // 2. StrongLifts 5x5
        let stronglifts = ProgramTemplate(
            name: "StrongLifts 5x5",
            description: "Build raw strength with the proven 5x5 method. Simple, effective, and progressive. Perfect for beginners wanting to build a solid strength foundation.",
            category: .strength,
            difficulty: .beginner,
            durationWeeks: 12,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .strength,
            equipmentRequired: ["Barbell", "Squat Rack", "Bench"],
            isFeatured: true
        )
        stronglifts.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Workout A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Workout B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Workout A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        stronglifts.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Workout A", description: "Squat, Bench, Row", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 5, reps: "5", weight: "Add 5lbs each session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 5, reps: "5", weight: "Add 5lbs each session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 5, reps: "5", weight: "Add 5lbs each session", restSeconds: 180)
            ]),
            ProgramWorkoutDefinition(name: "Workout B", description: "Squat, OHP, Deadlift", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 5, reps: "5", weight: "Add 5lbs each session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 5, reps: "5", weight: "Add 5lbs each session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 1, reps: "5", weight: "Add 10lbs each session", restSeconds: 180)
            ])
        ]
        context.insert(stronglifts)

        // 3. Upper Lower Split
        let upperLower = ProgramTemplate(
            name: "Upper Lower Power Building",
            description: "Combine strength and hypertrophy with this 4-day upper/lower split. Two strength days and two volume days for balanced development.",
            category: .strength,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 60,
            goal: .muscleBuilding,
            equipmentRequired: ["Barbell", "Dumbbells", "Cable Machine", "Bench"],
            isFeatured: false
        )
        upperLower.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Upper Strength", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Lower Strength", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Upper Hypertrophy", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Lower Hypertrophy", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        upperLower.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Upper Strength", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 4, reps: "4-6", weight: "RPE 8-9", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 4, reps: "4-6", weight: "RPE 8-9", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 3, reps: "6-8", weight: "RPE 8", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Weighted Pull-ups", sets: 3, reps: "6-8", weight: "RPE 8", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Barbell Curls", sets: 2, reps: "8-10", weight: "RPE 7", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Tricep Pushdowns", sets: 2, reps: "8-10", weight: "RPE 7", restSeconds: 90)
            ]),
            ProgramWorkoutDefinition(name: "Lower Strength", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 4, reps: "4-6", weight: "RPE 8-9", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 4, reps: "6-8", weight: "RPE 8", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 3, reps: "8-10", weight: "RPE 8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "10-12", weight: "RPE 8", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 4, reps: "12-15", weight: "RPE 8", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Upper Hypertrophy", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Press", sets: 4, reps: "10-12", weight: "RPE 7-8", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 4, reps: "10-12", weight: "RPE 7-8", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Shoulder Press", sets: 3, reps: "12-15", weight: "RPE 7", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Cable Rows", sets: 3, reps: "12-15", weight: "RPE 7", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 3, reps: "15-20", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "15-20", weight: "RPE 7", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Curls", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Overhead Tricep Extension", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Lower Hypertrophy", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 4, reps: "12-15", weight: "RPE 7-8", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 3, reps: "10-12", weight: "RPE 7", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Bulgarian Split Squats", sets: 3, reps: "12-15", weight: "RPE 7", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Leg Extensions", sets: 3, reps: "15-20", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "15-20", weight: "RPE 8", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Hip Thrusts", sets: 3, reps: "12-15", weight: "RPE 8", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 4, reps: "15-20", weight: "RPE 8", restSeconds: 60)
            ])
        ]
        context.insert(upperLower)

        // 4. Full Body 3x/Week
        let fullBody = ProgramTemplate(
            name: "Full Body Foundation",
            description: "Hit every muscle group three times per week with this efficient full body routine. Great for building a balanced physique with limited gym time.",
            category: .strength,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 50,
            goal: .general,
            equipmentRequired: ["Barbell", "Dumbbells", "Bench"]
        )
        fullBody.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Full Body A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Full Body B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Body C", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        fullBody.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Full Body A", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 3, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 3, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 3, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Shoulder Press", sets: 2, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Barbell Curls", sets: 2, reps: "10-12", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Tricep Pushdowns", sets: 2, reps: "10-12", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Full Body B", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 3, reps: "6-8", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Press", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 3, reps: "15-20", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Full Body C", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Front Squats", sets: 3, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 3, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Pull-ups", sets: 3, reps: "6-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Rows", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Hammer Curls", sets: 2, reps: "10-12", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Skull Crushers", sets: 2, reps: "10-12", restSeconds: 60)
            ])
        ]
        context.insert(fullBody)

        // 5. Bro Split
        let broSplit = ProgramTemplate(
            name: "Classic Bro Split",
            description: "Train each muscle group once per week with maximum volume. The traditional bodybuilding split used by generations of lifters.",
            category: .strength,
            difficulty: .intermediate,
            durationWeeks: 12,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 60,
            goal: .muscleBuilding,
            equipmentRequired: ["Barbell", "Dumbbells", "Cable Machine", "Machines"]
        )
        broSplit.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Chest", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Back", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Shoulders", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Legs", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Arms", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        broSplit.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Chest", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 4, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Press", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Decline Bench Press", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Cable Flyes", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Pec Deck", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Back", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 4, reps: "6-8", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Pull-ups", sets: 4, reps: "8-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 3, reps: "10-12", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Seated Cable Row", sets: 3, reps: "10-12", restSeconds: 75)
            ]),
            ProgramWorkoutDefinition(name: "Shoulders", estimatedMinutes: 55, exercises: [
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 4, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Arnold Press", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 4, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "15-20", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Reverse Flyes", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Shrugs", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Legs", estimatedMinutes: 65, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 4, reps: "8-10", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 4, reps: "10-12", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Extensions", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 4, reps: "15-20", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Arms", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Curls", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Skull Crushers", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Hammer Curls", sets: 3, reps: "10-12", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Tricep Pushdowns", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Curls", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Overhead Tricep Extension", sets: 3, reps: "12-15", restSeconds: 60)
            ])
        ]
        context.insert(broSplit)

        // 6. Powerlifting Peaking Program
        let powerlifting = ProgramTemplate(
            name: "Powerlifting Peak",
            description: "8-week peaking program for competition or max testing. Progressive overload with strategic deloads to hit PRs on squat, bench, and deadlift.",
            category: .strength,
            difficulty: .advanced,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 75,
            goal: .strength,
            equipmentRequired: ["Barbell", "Squat Rack", "Bench", "Deadlift Platform"]
        )
        context.insert(powerlifting)

        // 7. German Volume Training
        let gvt = ProgramTemplate(
            name: "German Volume Training",
            description: "10 sets of 10 reps - the ultimate mass builder. Not for the faint of heart. This brutal program will pack on muscle fast.",
            category: .strength,
            difficulty: .advanced,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 60,
            goal: .muscleBuilding,
            equipmentRequired: ["Barbell", "Dumbbells", "Bench"]
        )
        context.insert(gvt)

        // 8. Starting Strength
        let startingStrength = ProgramTemplate(
            name: "Starting Strength",
            description: "Mark Rippetoe's legendary novice program. Build serious strength with the fundamentals: squat, press, deadlift, bench, and power clean.",
            category: .strength,
            difficulty: .beginner,
            durationWeeks: 12,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 60,
            goal: .strength,
            equipmentRequired: ["Barbell", "Squat Rack", "Bench"],
            isFeatured: true
        )
        context.insert(startingStrength)

        // 9. Arnold Split
        let arnoldSplit = ProgramTemplate(
            name: "Arnold Split",
            description: "Train like the Oak himself. 6-day split hitting chest/back, shoulders/arms, and legs twice per week for maximum volume.",
            category: .strength,
            difficulty: .advanced,
            durationWeeks: 12,
            workoutsPerWeek: 6,
            estimatedMinutesPerSession: 70,
            goal: .muscleBuilding,
            equipmentRequired: ["Full Gym Access"]
        )
        context.insert(arnoldSplit)

        // 10. Minimalist Strength
        let minimalist = ProgramTemplate(
            name: "Minimalist Strength",
            description: "Maximum results with minimum exercises. Focus on the big lifts: squat, bench, deadlift, and overhead press. Simple and effective.",
            category: .strength,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 40,
            goal: .strength,
            equipmentRequired: ["Barbell", "Squat Rack"]
        )
        context.insert(minimalist)

        // 11. Women's Glute Builder
        let gluteBuilder = ProgramTemplate(
            name: "Glute Builder Program",
            description: "Sculpt and strengthen your glutes with this targeted 8-week program. Includes hip thrusts, glute bridges, and accessory work.",
            category: .strength,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 50,
            goal: .muscleBuilding,
            equipmentRequired: ["Barbell", "Hip Thrust Bench", "Resistance Bands"]
        )
        context.insert(gluteBuilder)

        // 12. Home Dumbbell Only
        let dumbbellOnly = ProgramTemplate(
            name: "Home Dumbbell Program",
            description: "Build muscle at home with just dumbbells. No gym required. Complete full-body development with limited equipment.",
            category: .strength,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .muscleBuilding,
            equipmentRequired: ["Dumbbells", "Adjustable Bench"]
        )
        context.insert(dumbbellOnly)
    }

    // MARK: - Cardio Programs (10+)
    static func seedCardioPrograms(in context: ModelContext) {

        // 1. Beginner Cardio Foundation
        let beginnerCardio = ProgramTemplate(
            name: "Cardio Foundation",
            description: "Build your cardiovascular base with this gentle introduction to cardio. Mix of walking, light jogging, and low-impact activities.",
            category: .cardio,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 30,
            goal: .endurance,
            equipmentRequired: ["None"]
        )
        context.insert(beginnerCardio)

        // 2. Zone 2 Aerobic Base
        let zone2 = ProgramTemplate(
            name: "Zone 2 Aerobic Base",
            description: "Build a massive aerobic engine with low-intensity Zone 2 training. Improve fat burning and endurance without burnout.",
            category: .cardio,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .endurance,
            equipmentRequired: ["Heart Rate Monitor"],
            isFeatured: true
        )
        zone2.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Zone 2 Session", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Active Recovery", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Zone 2 Long Session", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Zone 2 Session", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        zone2.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Zone 2 Session",
                description: "Stay in Zone 2 heart rate (60-70% max HR)",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup Walk/Jog", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Gradually increase pace"),
                    ProgramExerciseDefinition(exerciseName: "Zone 2 Cardio", sets: 1, reps: "35 min", weight: nil, restSeconds: 0, notes: "Keep HR at 60-70% max. Should be able to hold conversation"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Easy pace, let HR come down")
                ],
                warmup: ["Light walking", "Dynamic leg swings"],
                cooldown: ["Walking", "Light stretching"]
            ),
            ProgramWorkoutDefinition(
                name: "Active Recovery",
                description: "Very easy effort to promote recovery",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Easy Walk", sets: 1, reps: "20 min", weight: nil, restSeconds: 0, notes: "Relaxed pace, enjoy the movement"),
                    ProgramExerciseDefinition(exerciseName: "Mobility Work", sets: 1, reps: "10 min", weight: nil, restSeconds: 0, notes: "Hip circles, leg swings, arm circles")
                ],
                warmup: ["Start walking"],
                cooldown: ["Gentle stretching"]
            ),
            ProgramWorkoutDefinition(
                name: "Zone 2 Long Session",
                description: "Extended aerobic session for endurance building",
                estimatedMinutes: 60,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Easy start"),
                    ProgramExerciseDefinition(exerciseName: "Zone 2 Cardio", sets: 1, reps: "50 min", weight: nil, restSeconds: 0, notes: "Maintain Zone 2 HR. Walk if needed to stay in zone"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Gradually reduce intensity")
                ],
                warmup: ["Light walking", "Gentle movement"],
                cooldown: ["Walking", "Full body stretch"]
            )
        ]
        context.insert(zone2)

        // 3. Fat Burning Cardio
        let fatBurn = ProgramTemplate(
            name: "Fat Burning Cardio",
            description: "Optimize your cardio for maximum fat loss. Strategic mix of LISS and moderate intensity to keep burning calories all day.",
            category: .cardio,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 40,
            goal: .fatloss,
            equipmentRequired: ["Treadmill or Outdoor Space"]
        )
        context.insert(fatBurn)

        // 4. Stair Climbing Challenge
        let stairs = ProgramTemplate(
            name: "Stair Climbing Challenge",
            description: "Build leg strength and cardio endurance with progressive stair workouts. Great for building powerful legs and a strong heart.",
            category: .cardio,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .endurance,
            equipmentRequired: ["Stairs or StairMaster"]
        )
        context.insert(stairs)

        // 5. Rowing Endurance
        let rowing = ProgramTemplate(
            name: "Rowing Endurance",
            description: "Full-body cardio with the rowing machine. Build endurance while working 86% of your muscles. Low impact, high results.",
            category: .cardio,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 35,
            goal: .endurance,
            equipmentRequired: ["Rowing Machine"]
        )
        context.insert(rowing)

        // 6. Jump Rope Conditioning
        let jumpRope = ProgramTemplate(
            name: "Jump Rope Conditioning",
            description: "Learn to skip rope and build incredible conditioning. From beginner basics to advanced footwork and double-unders.",
            category: .cardio,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .athleticPerformance,
            equipmentRequired: ["Jump Rope"]
        )
        context.insert(jumpRope)

        // 7. Elliptical Endurance
        let elliptical = ProgramTemplate(
            name: "Elliptical Endurance Builder",
            description: "Low-impact cardio progression on the elliptical. Perfect for those with joint issues who still want serious cardio gains.",
            category: .cardio,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 35,
            goal: .endurance,
            equipmentRequired: ["Elliptical Machine"]
        )
        context.insert(elliptical)

        // 8. Mixed Cardio Circuit
        let mixedCardio = ProgramTemplate(
            name: "Mixed Cardio Circuit",
            description: "Never get bored with this variety-packed program. Different cardio modalities each session keep things fresh and effective.",
            category: .cardio,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .general,
            equipmentRequired: ["Various Cardio Equipment"]
        )
        context.insert(mixedCardio)

        // 9. Heart Health Cardio
        let heartHealth = ProgramTemplate(
            name: "Heart Health Program",
            description: "Doctor-approved cardio program designed to improve cardiovascular health markers. Safe, effective, and sustainable.",
            category: .cardio,
            difficulty: .beginner,
            durationWeeks: 12,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 30,
            goal: .maintenance,
            equipmentRequired: ["None"]
        )
        context.insert(heartHealth)

        // 10. Advanced Cardio Athlete
        let advancedCardio = ProgramTemplate(
            name: "Advanced Cardio Athlete",
            description: "Push your cardiovascular limits with this demanding program. For experienced athletes looking to reach peak conditioning.",
            category: .cardio,
            difficulty: .advanced,
            durationWeeks: 8,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 50,
            goal: .athleticPerformance,
            equipmentRequired: ["Various Cardio Equipment"]
        )
        context.insert(advancedCardio)

        // 11. Walking Weight Loss
        let walkingProgram = ProgramTemplate(
            name: "Walking Weight Loss",
            description: "Lose weight with progressive walking workouts. Includes incline walks, power walking, and interval walking sessions.",
            category: .cardio,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 40,
            goal: .fatloss,
            equipmentRequired: ["None"]
        )
        context.insert(walkingProgram)
    }

    // MARK: - Yoga Programs (10+)
    static func seedYogaPrograms(in context: ModelContext) {

        // 1. Yoga for Beginners
        let beginnerYoga = ProgramTemplate(
            name: "Yoga for Beginners",
            description: "Start your yoga journey with foundational poses and breathing techniques. Build flexibility, strength, and mindfulness from scratch.",
            category: .yoga,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat"],
            isFeatured: true
        )
        beginnerYoga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Foundation Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Strength & Balance", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Flexibility Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        beginnerYoga.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Foundation Flow",
                description: "Learn fundamental poses and breathing",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Mountain Pose (Tadasana)", sets: 1, reps: "5 breaths", weight: nil, restSeconds: 0, notes: "Ground through feet, crown reaching up"),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold (Uttanasana)", sets: 1, reps: "5 breaths", weight: nil, restSeconds: 0, notes: "Bend knees if needed"),
                    ProgramExerciseDefinition(exerciseName: "Downward Dog", sets: 1, reps: "8 breaths", weight: nil, restSeconds: 0, notes: "Pedal feet, press through hands"),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow Stretch", sets: 1, reps: "10 rounds", weight: nil, restSeconds: 0, notes: "Sync movement with breath"),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "8 breaths", weight: nil, restSeconds: 0, notes: "Arms extended or by sides"),
                    ProgramExerciseDefinition(exerciseName: "Cobra Pose", sets: 1, reps: "5 breaths", weight: nil, restSeconds: 0, notes: "Keep elbows close to body"),
                    ProgramExerciseDefinition(exerciseName: "Seated Forward Fold", sets: 1, reps: "8 breaths", weight: nil, restSeconds: 0, notes: "Hinge from hips, not lower back"),
                    ProgramExerciseDefinition(exerciseName: "Corpse Pose (Savasana)", sets: 1, reps: "3-5 min", weight: nil, restSeconds: 0, notes: "Complete relaxation")
                ],
                warmup: ["Seated breathing", "Neck rolls", "Shoulder circles"],
                cooldown: ["Gentle twists", "Savasana"]
            ),
            ProgramWorkoutDefinition(
                name: "Strength & Balance",
                description: "Build stability and core strength",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 3, reps: "1 round", weight: nil, restSeconds: 0, notes: "Move slowly, one breath per pose"),
                    ProgramExerciseDefinition(exerciseName: "Warrior I", sets: 1, reps: "5 breaths each side", weight: nil, restSeconds: 0, notes: "Square hips forward"),
                    ProgramExerciseDefinition(exerciseName: "Warrior II", sets: 1, reps: "5 breaths each side", weight: nil, restSeconds: 0, notes: "Gaze over front hand"),
                    ProgramExerciseDefinition(exerciseName: "Tree Pose", sets: 1, reps: "5 breaths each side", weight: nil, restSeconds: 0, notes: "Use wall if needed"),
                    ProgramExerciseDefinition(exerciseName: "Chair Pose", sets: 1, reps: "5 breaths", weight: nil, restSeconds: 0, notes: "Sit back, weight in heels"),
                    ProgramExerciseDefinition(exerciseName: "Plank Pose", sets: 1, reps: "5 breaths", weight: nil, restSeconds: 0, notes: "Engage core, straight line"),
                    ProgramExerciseDefinition(exerciseName: "Bridge Pose", sets: 1, reps: "5 breaths", weight: nil, restSeconds: 0, notes: "Press through feet, lift hips"),
                    ProgramExerciseDefinition(exerciseName: "Corpse Pose (Savasana)", sets: 1, reps: "3-5 min", weight: nil, restSeconds: 0, notes: "Complete relaxation")
                ],
                warmup: ["Cat-Cow", "Gentle twists"],
                cooldown: ["Supine twist", "Happy baby", "Savasana"]
            ),
            ProgramWorkoutDefinition(
                name: "Flexibility Focus",
                description: "Deep stretching and hip openers",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Butterfly Pose", sets: 1, reps: "10 breaths", weight: nil, restSeconds: 0, notes: "Gently press knees down"),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "10 breaths each side", weight: nil, restSeconds: 0, notes: "Use block under hip if needed"),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "8 breaths each side", weight: nil, restSeconds: 0, notes: "Sink hips forward and down"),
                    ProgramExerciseDefinition(exerciseName: "Lizard Pose", sets: 1, reps: "8 breaths each side", weight: nil, restSeconds: 0, notes: "Forearms down for deeper stretch"),
                    ProgramExerciseDefinition(exerciseName: "Seated Spinal Twist", sets: 1, reps: "8 breaths each side", weight: nil, restSeconds: 0, notes: "Lengthen spine on inhale, twist on exhale"),
                    ProgramExerciseDefinition(exerciseName: "Supine Figure Four", sets: 1, reps: "10 breaths each side", weight: nil, restSeconds: 0, notes: "Keep head and shoulders down"),
                    ProgramExerciseDefinition(exerciseName: "Legs Up The Wall", sets: 1, reps: "3-5 min", weight: nil, restSeconds: 0, notes: "Restorative inversion"),
                    ProgramExerciseDefinition(exerciseName: "Corpse Pose (Savasana)", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Complete relaxation")
                ],
                warmup: ["Gentle neck stretches", "Cat-Cow"],
                cooldown: ["Knees to chest", "Savasana"]
            )
        ]
        context.insert(beginnerYoga)

        // 2. Morning Flow
        let morningFlow = ProgramTemplate(
            name: "Morning Yoga Flow",
            description: "Start your day energized with this invigorating morning practice. Wake up your body and mind with sun salutations and gentle flows.",
            category: .yoga,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 20,
            goal: .general,
            equipmentRequired: ["Yoga Mat"]
        )
        context.insert(morningFlow)

        // 3. Power Yoga
        let powerYoga = ProgramTemplate(
            name: "Power Yoga Challenge",
            description: "Build strength and flexibility with this athletic yoga practice. Fast-paced flows that will challenge your body and mind.",
            category: .yoga,
            difficulty: .advanced,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .strength,
            equipmentRequired: ["Yoga Mat"]
        )
        context.insert(powerYoga)

        // 4. Yoga for Athletes
        let athleteYoga = ProgramTemplate(
            name: "Yoga for Athletes",
            description: "Complement your training with yoga designed for athletes. Improve mobility, prevent injury, and enhance recovery.",
            category: .yoga,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 35,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat", "Yoga Blocks"]
        )
        context.insert(athleteYoga)

        // 5. Evening Wind Down
        let eveningYoga = ProgramTemplate(
            name: "Evening Wind Down Yoga",
            description: "Relax and prepare for restful sleep with this gentle evening practice. Calm your nervous system and release the day's tension.",
            category: .yoga,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 20,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat"]
        )
        context.insert(eveningYoga)

        // 6. Vinyasa Flow
        let vinyasa = ProgramTemplate(
            name: "Vinyasa Flow Program",
            description: "Master the art of vinyasa with progressive flow sequences. Link breath to movement in this dynamic practice.",
            category: .yoga,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .general,
            equipmentRequired: ["Yoga Mat"]
        )
        context.insert(vinyasa)

        // 7. Yin Yoga Deep Stretch
        let yinYoga = ProgramTemplate(
            name: "Yin Yoga Deep Stretch",
            description: "Hold poses for extended periods to target deep connective tissues. Improve flexibility and cultivate patience and mindfulness.",
            category: .yoga,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat", "Yoga Bolster", "Yoga Blocks"]
        )
        context.insert(yinYoga)

        // 8. Yoga for Back Pain
        let backPainYoga = ProgramTemplate(
            name: "Yoga for Back Pain Relief",
            description: "Gentle yoga sequences designed to alleviate back pain and prevent future issues. Strengthen your core and improve posture.",
            category: .yoga,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .rehabilitation,
            equipmentRequired: ["Yoga Mat"]
        )
        context.insert(backPainYoga)

        // 9. Ashtanga Primary Series
        let ashtanga = ProgramTemplate(
            name: "Ashtanga Primary Series",
            description: "Master the traditional Ashtanga Primary Series. A challenging and transformative practice for dedicated yogis.",
            category: .yoga,
            difficulty: .advanced,
            durationWeeks: 12,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 75,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat"]
        )
        context.insert(ashtanga)

        // 10. Desk Worker Yoga
        let deskYoga = ProgramTemplate(
            name: "Yoga for Desk Workers",
            description: "Counter the effects of sitting all day. Target tight hips, shoulders, and neck with poses designed for office workers.",
            category: .yoga,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat"]
        )
        context.insert(deskYoga)

        // 11. Hot Yoga Preparation
        let hotYogaPrep = ProgramTemplate(
            name: "Hot Yoga Preparation",
            description: "Prepare your body for hot yoga classes. Build the flexibility and endurance needed to thrive in heated practice.",
            category: .yoga,
            difficulty: .intermediate,
            durationWeeks: 4,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat", "Towel"]
        )
        context.insert(hotYogaPrep)
    }

    // MARK: - Pilates Programs (10+)
    static func seedPilatesPrograms(in context: ModelContext) {

        // 1. Pilates Fundamentals
        let pilatesFundamentals = ProgramTemplate(
            name: "Pilates Fundamentals",
            description: "Learn the core principles of Pilates. Build a strong foundation with proper breathing, alignment, and controlled movements.",
            category: .pilates,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .general,
            equipmentRequired: ["Pilates Mat"],
            isFeatured: true
        )
        pilatesFundamentals.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Core Basics", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Spinal Mobility", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Body Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        pilatesFundamentals.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Core Basics",
                description: "Foundation core exercises with proper breathing",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Pilates Breathing", sets: 1, reps: "10 breaths", weight: nil, restSeconds: 0, notes: "Lateral thoracic breathing"),
                    ProgramExerciseDefinition(exerciseName: "Pelvic Tilts", sets: 1, reps: "10 reps", weight: nil, restSeconds: 0, notes: "Imprint and release spine"),
                    ProgramExerciseDefinition(exerciseName: "The Hundred (Modified)", sets: 1, reps: "50-100 pulses", weight: nil, restSeconds: 0, notes: "Head down if needed"),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch", sets: 1, reps: "10 each side", weight: nil, restSeconds: 0, notes: "Keep lower back pressed down"),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Stretch", sets: 1, reps: "8 reps", weight: nil, restSeconds: 0, notes: "Reach long, circle arms"),
                    ProgramExerciseDefinition(exerciseName: "Toe Taps", sets: 1, reps: "10 each side", weight: nil, restSeconds: 0, notes: "Maintain neutral spine"),
                    ProgramExerciseDefinition(exerciseName: "Spine Stretch Forward", sets: 1, reps: "5 reps", weight: nil, restSeconds: 0, notes: "Articulate through spine")
                ],
                warmup: ["Breathing exercises", "Pelvic tilts"],
                cooldown: ["Rest position", "Gentle stretches"]
            ),
            ProgramWorkoutDefinition(
                name: "Spinal Mobility",
                description: "Improve spine flexibility and control",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Cat Stretch", sets: 1, reps: "8 reps", weight: nil, restSeconds: 0, notes: "Articulate each vertebra"),
                    ProgramExerciseDefinition(exerciseName: "Spine Twist", sets: 1, reps: "5 each side", weight: nil, restSeconds: 0, notes: "Sit tall, rotate from waist"),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "6 reps", weight: nil, restSeconds: 0, notes: "Controlled movement up and down"),
                    ProgramExerciseDefinition(exerciseName: "Rolling Like a Ball", sets: 1, reps: "8 reps", weight: nil, restSeconds: 0, notes: "Stay in tight ball shape"),
                    ProgramExerciseDefinition(exerciseName: "Swan Prep", sets: 1, reps: "6 reps", weight: nil, restSeconds: 0, notes: "Extend through upper back"),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Spine Twist", sets: 1, reps: "5 each side", weight: nil, restSeconds: 0, notes: "Open chest to ceiling"),
                    ProgramExerciseDefinition(exerciseName: "Shell Stretch", sets: 1, reps: "Hold 30 sec", weight: nil, restSeconds: 0, notes: "Rest and breathe")
                ],
                warmup: ["Breathing", "Pelvic circles"],
                cooldown: ["Rest position", "Seated stretches"]
            ),
            ProgramWorkoutDefinition(
                name: "Full Body Flow",
                description: "Integrate all fundamental movements",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", weight: nil, restSeconds: 0, notes: "Pump arms with vigor"),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "5 reps", weight: nil, restSeconds: 0, notes: "Smooth, controlled"),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Circles", sets: 1, reps: "5 each direction", weight: nil, restSeconds: 0, notes: "Stable pelvis"),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch", sets: 1, reps: "10 each side", weight: nil, restSeconds: 0, notes: "Coordinate breath"),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Bridge", sets: 1, reps: "5 reps", weight: nil, restSeconds: 0, notes: "Articulate spine up and down"),
                    ProgramExerciseDefinition(exerciseName: "Side Kick Series", sets: 1, reps: "8 each movement", weight: nil, restSeconds: 0, notes: "Front/back, up/down, circles"),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "20 counts", weight: nil, restSeconds: 0, notes: "Opposite arm and leg"),
                    ProgramExerciseDefinition(exerciseName: "Mermaid Stretch", sets: 1, reps: "3 each side", weight: nil, restSeconds: 0, notes: "Lengthen side body")
                ],
                warmup: ["Pilates breathing", "Gentle twists"],
                cooldown: ["Shell stretch", "Seated breathing"]
            )
        ]
        context.insert(pilatesFundamentals)

        // 2. Core Strength Pilates
        let corePilates = ProgramTemplate(
            name: "Core Strength Pilates",
            description: "Develop an unshakeable core with targeted Pilates exercises. Build deep abdominal strength and spinal stability.",
            category: .pilates,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 35,
            goal: .strength,
            equipmentRequired: ["Pilates Mat"]
        )
        context.insert(corePilates)

        // 3. Reformer Basics
        let reformer = ProgramTemplate(
            name: "Reformer Pilates Basics",
            description: "Introduction to Reformer Pilates. Learn to use this versatile machine for a full-body workout with spring resistance.",
            category: .pilates,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .general,
            equipmentRequired: ["Pilates Reformer"]
        )
        context.insert(reformer)

        // 4. Pilates for Posture
        let posturePilates = ProgramTemplate(
            name: "Pilates for Better Posture",
            description: "Correct postural imbalances and stand taller. Strengthen the muscles that support good posture and alignment.",
            category: .pilates,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .rehabilitation,
            equipmentRequired: ["Pilates Mat"]
        )
        context.insert(posturePilates)

        // 5. Advanced Mat Pilates
        let advancedMat = ProgramTemplate(
            name: "Advanced Mat Pilates",
            description: "Take your Pilates practice to the next level. Challenge yourself with advanced exercises and longer sequences.",
            category: .pilates,
            difficulty: .advanced,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 50,
            goal: .strength,
            equipmentRequired: ["Pilates Mat", "Pilates Ring"]
        )
        context.insert(advancedMat)

        // 6. Pilates for Runners
        let runnersPilates = ProgramTemplate(
            name: "Pilates for Runners",
            description: "Strengthen your running with Pilates. Build core stability, hip strength, and prevent common running injuries.",
            category: .pilates,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .athleticPerformance,
            equipmentRequired: ["Pilates Mat", "Resistance Band"]
        )
        context.insert(runnersPilates)

        // 7. Prenatal Pilates
        let prenatalPilates = ProgramTemplate(
            name: "Prenatal Pilates",
            description: "Safe and effective Pilates modified for pregnancy. Maintain strength and flexibility while preparing for birth.",
            category: .pilates,
            difficulty: .beginner,
            durationWeeks: 12,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .maintenance,
            equipmentRequired: ["Pilates Mat", "Pilates Ball"]
        )
        context.insert(prenatalPilates)

        // 8. Pilates Sculpt
        let pilatesSculpt = ProgramTemplate(
            name: "Pilates Body Sculpt",
            description: "Sculpt lean muscles with this toning-focused Pilates program. Combine classical exercises with modern variations.",
            category: .pilates,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .muscleBuilding,
            equipmentRequired: ["Pilates Mat", "Light Dumbbells"]
        )
        context.insert(pilatesSculpt)

        // 9. Wall Pilates
        let wallPilates = ProgramTemplate(
            name: "Wall Pilates Program",
            description: "Use the wall for support and resistance in this unique Pilates variation. Great for beginners and those with mobility issues.",
            category: .pilates,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .flexibility,
            equipmentRequired: ["Wall Space"]
        )
        context.insert(wallPilates)

        // 10. Classical Pilates
        let classicalPilates = ProgramTemplate(
            name: "Classical Pilates Journey",
            description: "Follow Joseph Pilates' original mat sequence. Experience Pilates as it was meant to be practiced.",
            category: .pilates,
            difficulty: .intermediate,
            durationWeeks: 10,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .general,
            equipmentRequired: ["Pilates Mat"]
        )
        context.insert(classicalPilates)

        // 11. Pilates Ring Challenge
        let ringPilates = ProgramTemplate(
            name: "Pilates Ring Challenge",
            description: "Add resistance with the Pilates ring for extra toning. Target inner thighs, chest, and arms with this versatile tool.",
            category: .pilates,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 35,
            goal: .muscleBuilding,
            equipmentRequired: ["Pilates Mat", "Pilates Ring"]
        )
        context.insert(ringPilates)
    }

    // MARK: - HIIT Programs (10+)
    static func seedHIITPrograms(in context: ModelContext) {

        // 1. HIIT Starter
        let hiitStarter = ProgramTemplate(
            name: "HIIT Starter Program",
            description: "Introduction to high-intensity interval training. Shorter work periods and longer rest to build your HIIT foundation safely.",
            category: .hiit,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 20,
            goal: .fatloss,
            equipmentRequired: ["None"]
        )
        context.insert(hiitStarter)

        // 2. Tabata Challenge
        let tabata = ProgramTemplate(
            name: "Tabata Fat Burn",
            description: "The original 4-minute HIIT protocol. 20 seconds all-out, 10 seconds rest. Brief but brutally effective.",
            category: .hiit,
            difficulty: .advanced,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .fatloss,
            equipmentRequired: ["None"],
            isFeatured: true
        )
        tabata.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Tabata Lower Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Tabata Upper Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Tabata Full Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Tabata Cardio Blast", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        tabata.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Tabata Lower Body",
                description: "8 rounds of 20 sec work / 10 sec rest focusing on legs",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Jump Squats", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Max effort each round"),
                    ProgramExerciseDefinition(exerciseName: "Alternating Lunges", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Explosive movement"),
                    ProgramExerciseDefinition(exerciseName: "Squat Pulses", sets: 4, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Stay low, small pulses"),
                    ProgramExerciseDefinition(exerciseName: "Glute Bridges", sets: 4, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Squeeze at top")
                ],
                warmup: ["Light jog in place", "Leg swings", "Air squats"],
                cooldown: ["Walking", "Quad stretch", "Hamstring stretch"]
            ),
            ProgramWorkoutDefinition(
                name: "Tabata Upper Body",
                description: "8 rounds focusing on arms, chest and core",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Max reps each round"),
                    ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Fast pace"),
                    ProgramExerciseDefinition(exerciseName: "Plank Shoulder Taps", sets: 4, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Minimize hip sway"),
                    ProgramExerciseDefinition(exerciseName: "Tricep Dips", sets: 4, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Use chair or bench")
                ],
                warmup: ["Arm circles", "Shoulder rolls", "Light push-ups"],
                cooldown: ["Chest stretch", "Shoulder stretch", "Cat-cow stretch"]
            ),
            ProgramWorkoutDefinition(
                name: "Tabata Full Body",
                description: "Hit every muscle group in this total body blast",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Burpees", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Full burpee with jump"),
                    ProgramExerciseDefinition(exerciseName: "Thrusters (Bodyweight)", sets: 4, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Squat to overhead press motion"),
                    ProgramExerciseDefinition(exerciseName: "Plank Jacks", sets: 4, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Jump feet in and out"),
                    ProgramExerciseDefinition(exerciseName: "Speed Skaters", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Side to side jumps")
                ],
                warmup: ["Jumping jacks", "Arm swings", "Hip circles"],
                cooldown: ["Walking", "Full body stretch", "Deep breathing"]
            ),
            ProgramWorkoutDefinition(
                name: "Tabata Cardio Blast",
                description: "Pure cardio conditioning at maximum intensity",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "High Knees", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Drive knees to chest"),
                    ProgramExerciseDefinition(exerciseName: "Butt Kicks", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Fast foot turnover"),
                    ProgramExerciseDefinition(exerciseName: "Jumping Jacks", sets: 8, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Full range of motion"),
                    ProgramExerciseDefinition(exerciseName: "Tuck Jumps", sets: 4, reps: "20 sec", weight: "Bodyweight", restSeconds: 10, notes: "Bring knees to chest mid-air")
                ],
                warmup: ["Light jog", "Dynamic stretches"],
                cooldown: ["Slow walk", "Deep breathing", "Leg stretches"]
            )
        ]
        context.insert(tabata)

        // 3. EMOM Madness
        let emom = ProgramTemplate(
            name: "EMOM Conditioning",
            description: "Every Minute On the Minute workouts that build work capacity. Complete prescribed reps at the start of each minute.",
            category: .hiit,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 30,
            goal: .endurance,
            equipmentRequired: ["Kettlebell", "Pull-up Bar"]
        )
        context.insert(emom)

        // 4. Bodyweight HIIT
        let bodyweightHIIT = ProgramTemplate(
            name: "Bodyweight HIIT Shred",
            description: "No equipment needed for this intense fat-burning program. Burn calories and build endurance anywhere, anytime.",
            category: .hiit,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .fatloss,
            equipmentRequired: ["None"]
        )
        context.insert(bodyweightHIIT)

        // 5. Kettlebell HIIT
        let kbHIIT = ProgramTemplate(
            name: "Kettlebell HIIT",
            description: "Combine the power of kettlebells with HIIT intervals. Build strength and conditioning simultaneously.",
            category: .hiit,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .fatloss,
            equipmentRequired: ["Kettlebell"]
        )
        context.insert(kbHIIT)

        // 6. Sprint Intervals
        let sprints = ProgramTemplate(
            name: "Sprint Interval Training",
            description: "All-out sprints followed by rest. The most effective form of cardio for fat loss and athletic performance.",
            category: .hiit,
            difficulty: .advanced,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 25,
            goal: .athleticPerformance,
            equipmentRequired: ["Track or Treadmill"]
        )
        context.insert(sprints)

        // 7. Boxing HIIT
        let boxingHIIT = ProgramTemplate(
            name: "Boxing HIIT Workout",
            description: "Throw punches and burn fat with this boxing-inspired HIIT program. No bag or partner required.",
            category: .hiit,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 30,
            goal: .fatloss,
            equipmentRequired: ["None"]
        )
        context.insert(boxingHIIT)

        // 8. AMRAP Challenge
        let amrap = ProgramTemplate(
            name: "AMRAP Challenge",
            description: "As Many Rounds As Possible workouts. Race against the clock to complete maximum rounds within the time cap.",
            category: .hiit,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 30,
            goal: .endurance,
            equipmentRequired: ["Various"]
        )
        context.insert(amrap)

        // 9. Low Impact HIIT
        let lowImpactHIIT = ProgramTemplate(
            name: "Low Impact HIIT",
            description: "High intensity without jumping. Perfect for apartment dwellers or those with joint concerns.",
            category: .hiit,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .fatloss,
            equipmentRequired: ["None"]
        )
        context.insert(lowImpactHIIT)

        // 10. HIIT and Lift
        let hiitLift = ProgramTemplate(
            name: "HIIT & Lift Hybrid",
            description: "Combine strength training with HIIT finishers. Build muscle and burn fat in the same session.",
            category: .hiit,
            difficulty: .advanced,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .muscleBuilding,
            equipmentRequired: ["Dumbbells", "Barbell"]
        )
        context.insert(hiitLift)

        // 11. 30-Day HIIT Challenge
        let hiitChallenge = ProgramTemplate(
            name: "30-Day HIIT Challenge",
            description: "Transform your body in 30 days with daily HIIT workouts. Progressive difficulty builds your conditioning fast.",
            category: .hiit,
            difficulty: .intermediate,
            durationWeeks: 4,
            workoutsPerWeek: 6,
            estimatedMinutesPerSession: 20,
            goal: .fatloss,
            equipmentRequired: ["None"]
        )
        context.insert(hiitChallenge)
    }

    // MARK: - Stretching Programs (10+)
    static func seedStretchingPrograms(in context: ModelContext) {

        // 1. Daily Stretch Routine
        let dailyStretch = ProgramTemplate(
            name: "Daily Stretch Routine",
            description: "Quick daily stretches to maintain flexibility and prevent stiffness. Perfect as a morning or evening ritual.",
            category: .stretching,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 7,
            estimatedMinutesPerSession: 15,
            goal: .flexibility,
            equipmentRequired: ["None"]
        )
        context.insert(dailyStretch)

        // 2. Flexibility Overhaul
        let flexibilityOverhaul = ProgramTemplate(
            name: "Flexibility Overhaul",
            description: "Comprehensive stretching program to dramatically improve flexibility. Target all major muscle groups progressively.",
            category: .stretching,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 30,
            goal: .flexibility,
            equipmentRequired: ["Yoga Strap"],
            isFeatured: true
        )
        flexibilityOverhaul.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Lower Body Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Upper Body Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Hip & Back Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Body Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Active Recovery Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        flexibilityOverhaul.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Lower Body Stretch",
                description: "Comprehensive leg and hip flexibility",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Standing Quad Stretch", sets: 1, reps: "60 sec each side", weight: nil, restSeconds: 0, notes: "Hold ankle, push hip forward"),
                    ProgramExerciseDefinition(exerciseName: "Standing Hamstring Stretch", sets: 1, reps: "60 sec each side", weight: nil, restSeconds: 0, notes: "Foot elevated, hinge forward"),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "90 sec each side", weight: nil, restSeconds: 0, notes: "Relax into the stretch"),
                    ProgramExerciseDefinition(exerciseName: "Frog Stretch", sets: 1, reps: "90 sec", weight: nil, restSeconds: 0, notes: "Knees wide, sink hips"),
                    ProgramExerciseDefinition(exerciseName: "Seated Forward Fold", sets: 1, reps: "90 sec", weight: nil, restSeconds: 0, notes: "Use strap if needed"),
                    ProgramExerciseDefinition(exerciseName: "Butterfly Stretch", sets: 1, reps: "60 sec", weight: nil, restSeconds: 0, notes: "Gently press knees down"),
                    ProgramExerciseDefinition(exerciseName: "Calf Stretch", sets: 1, reps: "45 sec each side", weight: nil, restSeconds: 0, notes: "Wall stretch, keep heel down")
                ],
                warmup: ["Light walking", "Leg swings"],
                cooldown: ["Relaxed breathing", "Gentle movement"]
            ),
            ProgramWorkoutDefinition(
                name: "Upper Body Stretch",
                description: "Shoulders, chest, and arms flexibility",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Doorway Chest Stretch", sets: 1, reps: "60 sec each arm", weight: nil, restSeconds: 0, notes: "Elbow at 90 degrees"),
                    ProgramExerciseDefinition(exerciseName: "Cross-Body Shoulder Stretch", sets: 1, reps: "45 sec each side", weight: nil, restSeconds: 0, notes: "Pull arm across chest"),
                    ProgramExerciseDefinition(exerciseName: "Tricep Overhead Stretch", sets: 1, reps: "45 sec each side", weight: nil, restSeconds: 0, notes: "Reach down back"),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "60 sec each side", weight: nil, restSeconds: 0, notes: "Rotate through upper back"),
                    ProgramExerciseDefinition(exerciseName: "Lat Stretch", sets: 1, reps: "60 sec each side", weight: nil, restSeconds: 0, notes: "Reach overhead, side bend"),
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "30 sec each direction", weight: nil, restSeconds: 0, notes: "Ear to shoulder, chin to chest"),
                    ProgramExerciseDefinition(exerciseName: "Wrist Circles & Stretches", sets: 1, reps: "2 min", weight: nil, restSeconds: 0, notes: "Flex and extend")
                ],
                warmup: ["Arm circles", "Shoulder rolls"],
                cooldown: ["Deep breathing", "Gentle shakes"]
            ),
            ProgramWorkoutDefinition(
                name: "Hip & Back Focus",
                description: "Deep hip opening and spinal mobility",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "2 min", weight: nil, restSeconds: 0, notes: "Flow with breath"),
                    ProgramExerciseDefinition(exerciseName: "90-90 Hip Stretch", sets: 1, reps: "90 sec each side", weight: nil, restSeconds: 0, notes: "Both legs at 90 degrees"),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "60 sec each side", weight: nil, restSeconds: 0, notes: "Sink hips forward"),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "90 sec each side", weight: nil, restSeconds: 0, notes: "Keep both shoulders down"),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "2 min", weight: nil, restSeconds: 0, notes: "Arms extended, relax"),
                    ProgramExerciseDefinition(exerciseName: "Scorpion Stretch", sets: 1, reps: "45 sec each side", weight: nil, restSeconds: 0, notes: "Prone, reach foot across"),
                    ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "90 sec", weight: nil, restSeconds: 0, notes: "Pull knees toward armpits")
                ],
                warmup: ["Gentle rocking", "Hip circles"],
                cooldown: ["Savasana", "Deep breaths"]
            ),
            ProgramWorkoutDefinition(
                name: "Full Body Flow",
                description: "Dynamic stretching flow for all muscles",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Sun Salutation Flow", sets: 3, reps: "1 round", weight: nil, restSeconds: 0, notes: "Slow, intentional movement"),
                    ProgramExerciseDefinition(exerciseName: "World's Greatest Stretch", sets: 1, reps: "5 each side", weight: nil, restSeconds: 0, notes: "Lunge, rotate, reach"),
                    ProgramExerciseDefinition(exerciseName: "Downward Dog to Cobra Flow", sets: 1, reps: "8 reps", weight: nil, restSeconds: 0, notes: "Smooth transitions"),
                    ProgramExerciseDefinition(exerciseName: "Standing Side Bend", sets: 1, reps: "45 sec each side", weight: nil, restSeconds: 0, notes: "Reach overhead, lean"),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold to Flat Back", sets: 1, reps: "10 reps", weight: nil, restSeconds: 0, notes: "Halfway lift each time"),
                    ProgramExerciseDefinition(exerciseName: "Deep Squat Hold", sets: 1, reps: "2 min", weight: nil, restSeconds: 0, notes: "Heels down if possible"),
                    ProgramExerciseDefinition(exerciseName: "Seated Full Body Stretch", sets: 1, reps: "3 min", weight: nil, restSeconds: 0, notes: "Legs extended, fold forward")
                ],
                warmup: ["Light movement", "Joint circles"],
                cooldown: ["Gentle breathing", "Relaxation"]
            ),
            ProgramWorkoutDefinition(
                name: "Active Recovery Stretch",
                description: "Gentle stretching for recovery days",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Gentle Neck Rolls", sets: 1, reps: "10 each direction", weight: nil, restSeconds: 0, notes: "Slow and controlled"),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Rolls", sets: 1, reps: "20 reps", weight: nil, restSeconds: 0, notes: "Forward and backward"),
                    ProgramExerciseDefinition(exerciseName: "Seated Side Stretch", sets: 1, reps: "45 sec each side", weight: nil, restSeconds: 0, notes: "Reach and breathe"),
                    ProgramExerciseDefinition(exerciseName: "Supine Figure Four", sets: 1, reps: "60 sec each side", weight: nil, restSeconds: 0, notes: "Gentle hip opener"),
                    ProgramExerciseDefinition(exerciseName: "Knees to Chest", sets: 1, reps: "90 sec", weight: nil, restSeconds: 0, notes: "Rock gently side to side"),
                    ProgramExerciseDefinition(exerciseName: "Legs Up The Wall", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Restorative, relax completely")
                ],
                warmup: ["Deep breathing"],
                cooldown: ["Savasana"]
            )
        ]
        context.insert(flexibilityOverhaul)

        // 3. Splits Training
        let splits = ProgramTemplate(
            name: "Learn the Splits",
            description: "Progressive stretching program to achieve front and middle splits. Patient, consistent work leads to impressive flexibility.",
            category: .stretching,
            difficulty: .intermediate,
            durationWeeks: 12,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 25,
            goal: .flexibility,
            equipmentRequired: ["Yoga Blocks"]
        )
        context.insert(splits)

        // 4. Hip Opener Program
        let hipOpener = ProgramTemplate(
            name: "Hip Opener Program",
            description: "Target tight hips from sitting with dedicated hip stretches. Improve mobility for squats, running, and daily life.",
            category: .stretching,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 20,
            goal: .flexibility,
            equipmentRequired: ["None"]
        )
        context.insert(hipOpener)

        // 5. Upper Body Mobility
        let upperMobility = ProgramTemplate(
            name: "Upper Body Mobility",
            description: "Improve shoulder, chest, and thoracic spine mobility. Essential for overhead movements and good posture.",
            category: .stretching,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 20,
            goal: .flexibility,
            equipmentRequired: ["Foam Roller"]
        )
        context.insert(upperMobility)

        // 6. Post-Workout Stretch
        let postWorkout = ProgramTemplate(
            name: "Post-Workout Recovery",
            description: "Dedicated cool-down stretching routines for after training. Reduce soreness and improve recovery.",
            category: .stretching,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 15,
            goal: .flexibility,
            equipmentRequired: ["None"]
        )
        context.insert(postWorkout)

        // 7. Active Flexibility
        let activeFlexibility = ProgramTemplate(
            name: "Active Flexibility Training",
            description: "Build flexibility you can use in movement. Combine stretching with active range of motion exercises.",
            category: .stretching,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 30,
            goal: .flexibility,
            equipmentRequired: ["Resistance Bands"]
        )
        context.insert(activeFlexibility)

        // 8. Morning Mobility
        let morningMobility = ProgramTemplate(
            name: "Morning Mobility Routine",
            description: "Wake up your body with dynamic stretches and mobility work. Feel loose and ready for the day ahead.",
            category: .stretching,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 7,
            estimatedMinutesPerSession: 10,
            goal: .flexibility,
            equipmentRequired: ["None"]
        )
        context.insert(morningMobility)

        // 9. Office Stretches
        let officeStretches = ProgramTemplate(
            name: "Office Desk Stretches",
            description: "Quick stretches you can do at your desk. Combat the effects of sitting without leaving your workspace.",
            category: .stretching,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 10,
            goal: .flexibility,
            equipmentRequired: ["Chair"]
        )
        context.insert(officeStretches)

        // 10. Full Body Flexibility
        let fullBodyFlex = ProgramTemplate(
            name: "Full Body Flexibility",
            description: "Complete stretching program targeting every muscle group. Build total-body flexibility systematically.",
            category: .stretching,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 35,
            goal: .flexibility,
            equipmentRequired: ["Yoga Mat", "Yoga Strap"]
        )
        context.insert(fullBodyFlex)

        // 11. Bedtime Stretches
        let bedtimeStretch = ProgramTemplate(
            name: "Bedtime Wind-Down",
            description: "Gentle stretches to relax your body before sleep. Release tension and prepare for restful sleep.",
            category: .stretching,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 7,
            estimatedMinutesPerSession: 15,
            goal: .flexibility,
            equipmentRequired: ["None"]
        )
        context.insert(bedtimeStretch)
    }

    // MARK: - Running Programs (10+)
    static func seedRunningPrograms(in context: ModelContext) {

        // 1. Couch to 5K
        let c25k = ProgramTemplate(
            name: "Couch to 5K",
            description: "The classic beginner running program. Go from non-runner to completing a 5K in 9 weeks with gradual progression.",
            category: .running,
            difficulty: .beginner,
            durationWeeks: 9,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .endurance,
            equipmentRequired: ["Running Shoes"],
            isFeatured: true
        )
        c25k.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Run Day 1", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Run Day 2", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Run Day 3", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        c25k.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Run Day 1",
                description: "Week 1-3: Walk/Run Intervals",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Brisk Walk Warmup", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Get blood flowing"),
                    ProgramExerciseDefinition(exerciseName: "Run Interval", sets: 8, reps: "60 sec", weight: nil, restSeconds: 0, notes: "Easy conversational pace"),
                    ProgramExerciseDefinition(exerciseName: "Walk Interval", sets: 8, reps: "90 sec", weight: nil, restSeconds: 0, notes: "Active recovery between runs"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Gradually slow pace")
                ],
                warmup: ["Light walking", "Leg swings", "Arm circles"],
                cooldown: ["Walking", "Quad stretch", "Calf stretch"]
            ),
            ProgramWorkoutDefinition(
                name: "Run Day 2",
                description: "Week 4-6: Extended Run Intervals",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Brisk Walk Warmup", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Prepare your body"),
                    ProgramExerciseDefinition(exerciseName: "Run Interval", sets: 5, reps: "3 min", weight: nil, restSeconds: 0, notes: "Steady pace you can maintain"),
                    ProgramExerciseDefinition(exerciseName: "Walk Interval", sets: 5, reps: "90 sec", weight: nil, restSeconds: 0, notes: "Catch your breath"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Easy walking")
                ],
                warmup: ["Walking", "Dynamic stretches"],
                cooldown: ["Walking", "Hip flexor stretch", "Hamstring stretch"]
            ),
            ProgramWorkoutDefinition(
                name: "Run Day 3",
                description: "Week 7-9: Continuous Running",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Brisk Walk Warmup", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Easy pace warmup"),
                    ProgramExerciseDefinition(exerciseName: "Continuous Run", sets: 1, reps: "20-25 min", weight: nil, restSeconds: 0, notes: "Run the entire time at comfortable pace"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", weight: nil, restSeconds: 0, notes: "Gradually reduce pace")
                ],
                warmup: ["Walking", "Leg swings", "High knees"],
                cooldown: ["Walking", "Full leg stretching routine"]
            )
        ]
        context.insert(c25k)

        // 2. 5K to 10K
        let fiveTo10k = ProgramTemplate(
            name: "5K to 10K Bridge",
            description: "Ready for more? Build from 5K to 10K with this progressive program. Increase distance while maintaining good form.",
            category: .running,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .endurance,
            equipmentRequired: ["Running Shoes"]
        )
        context.insert(fiveTo10k)

        // 3. Half Marathon Training
        let halfMarathon = ProgramTemplate(
            name: "Half Marathon Training",
            description: "12-week program to conquer 13.1 miles. Includes long runs, tempo work, and recovery runs for race-day success.",
            category: .running,
            difficulty: .intermediate,
            durationWeeks: 12,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 50,
            goal: .endurance,
            equipmentRequired: ["Running Shoes", "GPS Watch"]
        )
        context.insert(halfMarathon)

        // 4. Marathon Training
        let marathon = ProgramTemplate(
            name: "Marathon Training Plan",
            description: "Complete 16-week marathon preparation. Build the endurance and mental toughness to finish 26.2 miles.",
            category: .running,
            difficulty: .advanced,
            durationWeeks: 16,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 60,
            goal: .competition,
            equipmentRequired: ["Running Shoes", "GPS Watch"]
        )
        context.insert(marathon)

        // 5. Speed Training
        let speedRunning = ProgramTemplate(
            name: "Running Speed Work",
            description: "Get faster with dedicated speed workouts. Intervals, tempo runs, and fartlek training to improve your pace.",
            category: .running,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .athleticPerformance,
            equipmentRequired: ["Running Shoes", "Track Access"]
        )
        context.insert(speedRunning)

        // 6. Trail Running
        let trailRunning = ProgramTemplate(
            name: "Trail Running Intro",
            description: "Take your running off-road. Build the skills and conditioning for trail running with varied terrain.",
            category: .running,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .endurance,
            equipmentRequired: ["Trail Running Shoes"]
        )
        context.insert(trailRunning)

        // 7. Run Streak Challenge
        let runStreak = ProgramTemplate(
            name: "30-Day Run Streak",
            description: "Run every day for 30 days. Build the habit with minimum 1-mile daily runs. Some days easy, some days hard.",
            category: .running,
            difficulty: .intermediate,
            durationWeeks: 4,
            workoutsPerWeek: 7,
            estimatedMinutesPerSession: 20,
            goal: .endurance,
            equipmentRequired: ["Running Shoes"]
        )
        context.insert(runStreak)

        // 8. Base Building
        let baseBuilding = ProgramTemplate(
            name: "Running Base Building",
            description: "Build your aerobic base with easy running. Increase weekly mileage gradually before adding intensity.",
            category: .running,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 35,
            goal: .endurance,
            equipmentRequired: ["Running Shoes"]
        )
        context.insert(baseBuilding)

        // 9. 5K PR Program
        let fivekPR = ProgramTemplate(
            name: "5K Personal Record",
            description: "Already running 5K? Get faster with this PR-focused program. Specific workouts to improve your race time.",
            category: .running,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .competition,
            equipmentRequired: ["Running Shoes"]
        )
        context.insert(fivekPR)

        // 10. Run-Walk Method
        let runWalk = ProgramTemplate(
            name: "Run-Walk Method",
            description: "Use strategic walk breaks to run longer distances. The Galloway method makes running accessible to everyone.",
            category: .running,
            difficulty: .beginner,
            durationWeeks: 10,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 35,
            goal: .endurance,
            equipmentRequired: ["Running Shoes"]
        )
        context.insert(runWalk)

        // 11. Treadmill Training
        let treadmill = ProgramTemplate(
            name: "Treadmill Training Program",
            description: "Make the most of treadmill running. Incline intervals, speed work, and endurance sessions for indoor training.",
            category: .running,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 35,
            goal: .endurance,
            equipmentRequired: ["Treadmill"]
        )
        context.insert(treadmill)
    }

    // MARK: - Cycling Programs (10+)
    static func seedCyclingPrograms(in context: ModelContext) {

        // 1. Beginner Cycling
        let beginnerCycling = ProgramTemplate(
            name: "Cycling for Beginners",
            description: "Start your cycling journey with this progressive program. Build endurance and confidence on the bike.",
            category: .cycling,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .endurance,
            equipmentRequired: ["Bicycle", "Helmet"]
        )
        context.insert(beginnerCycling)

        // 2. Indoor Cycling
        let indoorCycling = ProgramTemplate(
            name: "Indoor Cycling Program",
            description: "Spin class-style workouts for your stationary bike. High energy rides with intervals and climbs.",
            category: .cycling,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .fatloss,
            equipmentRequired: ["Stationary Bike"],
            isFeatured: true
        )
        indoorCycling.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Interval Ride", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Hill Climb", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Endurance Ride", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Power Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        indoorCycling.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Interval Ride",
                description: "High-intensity intervals with recovery periods",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup (Easy Spin)", sets: 1, reps: "5 min", weight: "RPE 3-4", restSeconds: 0, notes: "Light resistance, high cadence"),
                    ProgramExerciseDefinition(exerciseName: "Interval Sprint", sets: 8, reps: "45 sec", weight: "RPE 8-9", restSeconds: 0, notes: "High resistance, max effort"),
                    ProgramExerciseDefinition(exerciseName: "Recovery Spin", sets: 8, reps: "90 sec", weight: "RPE 4", restSeconds: 0, notes: "Easy pedaling between sprints"),
                    ProgramExerciseDefinition(exerciseName: "Moderate Push", sets: 2, reps: "5 min", weight: "RPE 6-7", restSeconds: 0, notes: "Steady effort"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", weight: "RPE 3", restSeconds: 0, notes: "Easy spin, reduce resistance")
                ],
                warmup: ["Easy pedaling", "Gradually increase cadence"],
                cooldown: ["Easy spin", "Light stretching off bike"]
            ),
            ProgramWorkoutDefinition(
                name: "Hill Climb",
                description: "Simulated climbing with heavy resistance",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", weight: "RPE 3-4", restSeconds: 0, notes: "Light spinning"),
                    ProgramExerciseDefinition(exerciseName: "Seated Climb", sets: 3, reps: "4 min", weight: "RPE 7", restSeconds: 0, notes: "High resistance, low cadence (60-70 RPM)"),
                    ProgramExerciseDefinition(exerciseName: "Recovery", sets: 3, reps: "2 min", weight: "RPE 4", restSeconds: 0, notes: "Reduce resistance"),
                    ProgramExerciseDefinition(exerciseName: "Standing Climb", sets: 3, reps: "2 min", weight: "RPE 8", restSeconds: 0, notes: "Out of saddle, heavy resistance"),
                    ProgramExerciseDefinition(exerciseName: "Summit Push", sets: 1, reps: "5 min", weight: "RPE 8-9", restSeconds: 0, notes: "Final push to the top"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Descent", sets: 1, reps: "5 min", weight: "RPE 3", restSeconds: 0, notes: "Light resistance, easy spin")
                ],
                warmup: ["Easy spin"],
                cooldown: ["Gradual resistance decrease", "Stretching"]
            ),
            ProgramWorkoutDefinition(
                name: "Endurance Ride",
                description: "Steady-state aerobic conditioning",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", weight: "RPE 3", restSeconds: 0, notes: "Easy start"),
                    ProgramExerciseDefinition(exerciseName: "Steady State Ride", sets: 1, reps: "35 min", weight: "RPE 5-6", restSeconds: 0, notes: "Consistent effort, conversational pace"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", weight: "RPE 3", restSeconds: 0, notes: "Easy spinning")
                ],
                warmup: ["Light pedaling"],
                cooldown: ["Easy spin", "Stretching"]
            ),
            ProgramWorkoutDefinition(
                name: "Power Intervals",
                description: "Short, explosive power bursts",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "8 min", weight: "RPE 4", restSeconds: 0, notes: "Include some accelerations"),
                    ProgramExerciseDefinition(exerciseName: "Power Burst", sets: 10, reps: "20 sec", weight: "RPE 9-10", restSeconds: 0, notes: "Maximum effort sprint"),
                    ProgramExerciseDefinition(exerciseName: "Recovery", sets: 10, reps: "40 sec", weight: "RPE 3", restSeconds: 0, notes: "Very easy spin"),
                    ProgramExerciseDefinition(exerciseName: "Tempo Block", sets: 2, reps: "5 min", weight: "RPE 7", restSeconds: 0, notes: "Solid effort"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "7 min", weight: "RPE 3", restSeconds: 0, notes: "Easy spin, HR recovery")
                ],
                warmup: ["Progressive warmup with bursts"],
                cooldown: ["Extended easy spin", "Stretching"]
            )
        ]
        context.insert(indoorCycling)

        // 3. Century Ride Training
        let century = ProgramTemplate(
            name: "Century Ride Training",
            description: "Train to complete a 100-mile ride. Progressive long rides build the endurance for this epic achievement.",
            category: .cycling,
            difficulty: .advanced,
            durationWeeks: 12,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 75,
            goal: .endurance,
            equipmentRequired: ["Road Bike", "Cycling Computer"]
        )
        context.insert(century)

        // 4. Cycling Intervals
        let cyclingIntervals = ProgramTemplate(
            name: "Cycling Power Intervals",
            description: "Build explosive power and speed with structured interval training. Improve your FTP and race performance.",
            category: .cycling,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 50,
            goal: .athleticPerformance,
            equipmentRequired: ["Bicycle", "Power Meter"]
        )
        context.insert(cyclingIntervals)

        // 5. Commuter Cycling
        let commuter = ProgramTemplate(
            name: "Bike Commuter Program",
            description: "Start cycling to work safely and efficiently. Build fitness while saving money and helping the environment.",
            category: .cycling,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 30,
            goal: .general,
            equipmentRequired: ["Bicycle", "Helmet", "Lights"]
        )
        context.insert(commuter)

        // 6. Hill Climbing
        let hillClimbing = ProgramTemplate(
            name: "Hill Climbing Mastery",
            description: "Conquer the climbs with specific hill training. Build leg strength and climbing technique.",
            category: .cycling,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 50,
            goal: .strength,
            equipmentRequired: ["Bicycle", "Hilly Terrain"]
        )
        context.insert(hillClimbing)

        // 7. Cycling Endurance
        let cyclingEndurance = ProgramTemplate(
            name: "Cycling Endurance Builder",
            description: "Long, steady rides to build your aerobic base. Foundation training for any cycling goal.",
            category: .cycling,
            difficulty: .intermediate,
            durationWeeks: 10,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 60,
            goal: .endurance,
            equipmentRequired: ["Bicycle"]
        )
        context.insert(cyclingEndurance)

        // 8. Peloton-Style
        let pelotonStyle = ProgramTemplate(
            name: "Peloton-Style Program",
            description: "Structured spin workouts inspired by popular cycling apps. Mix of endurance, intervals, and music-driven rides.",
            category: .cycling,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .fatloss,
            equipmentRequired: ["Spin Bike"]
        )
        context.insert(pelotonStyle)

        // 9. Mountain Biking
        let mtb = ProgramTemplate(
            name: "Mountain Bike Fitness",
            description: "Build the specific fitness for mountain biking. Combines cardio, strength, and technical skill development.",
            category: .cycling,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 50,
            goal: .athleticPerformance,
            equipmentRequired: ["Mountain Bike", "Helmet"]
        )
        context.insert(mtb)

        // 10. Recovery Rides
        let recoveryRides = ProgramTemplate(
            name: "Active Recovery Cycling",
            description: "Easy cycling for recovery between hard training days. Flush the legs and maintain fitness without fatigue.",
            category: .cycling,
            difficulty: .beginner,
            durationWeeks: 4,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .maintenance,
            equipmentRequired: ["Bicycle"]
        )
        context.insert(recoveryRides)

        // 11. FTP Builder
        let ftpBuilder = ProgramTemplate(
            name: "FTP Builder Program",
            description: "Increase your Functional Threshold Power with structured training. Sweet spot and threshold workouts for gains.",
            category: .cycling,
            difficulty: .advanced,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 60,
            goal: .athleticPerformance,
            equipmentRequired: ["Bicycle", "Power Meter"]
        )
        context.insert(ftpBuilder)
    }

    // MARK: - Swimming Programs (10+)
    static func seedSwimmingPrograms(in context: ModelContext) {

        // 1. Learn to Swim
        let learnToSwim = ProgramTemplate(
            name: "Learn to Swim",
            description: "From zero to confident swimmer. Build water confidence and learn basic strokes in a safe, progressive manner.",
            category: .swimming,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .general,
            equipmentRequired: ["Pool Access", "Goggles"]
        )
        context.insert(learnToSwim)

        // 2. Lap Swimming
        let lapSwimming = ProgramTemplate(
            name: "Lap Swimming Fitness",
            description: "Structured lap swimming workouts for fitness. Build endurance and technique while getting a full-body workout.",
            category: .swimming,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .endurance,
            equipmentRequired: ["Pool Access", "Goggles", "Swim Cap"],
            isFeatured: true
        )
        lapSwimming.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Endurance Swim", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Drill & Technique", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Interval Training", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        lapSwimming.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Endurance Swim",
                description: "Build swimming endurance with steady laps",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup Swim", sets: 1, reps: "200m", weight: nil, restSeconds: 0, notes: "Easy freestyle, focus on form"),
                    ProgramExerciseDefinition(exerciseName: "Freestyle Main Set", sets: 4, reps: "200m", weight: nil, restSeconds: 30, notes: "Steady pace, 30 sec rest between"),
                    ProgramExerciseDefinition(exerciseName: "Backstroke", sets: 2, reps: "100m", weight: nil, restSeconds: 20, notes: "Active recovery stroke"),
                    ProgramExerciseDefinition(exerciseName: "Pull Set (with buoy)", sets: 4, reps: "50m", weight: nil, restSeconds: 15, notes: "Arms only, focus on catch"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "200m", weight: nil, restSeconds: 0, notes: "Easy mixed strokes")
                ],
                warmup: ["Pool stretching", "Easy laps"],
                cooldown: ["Easy swimming", "Pool stretching"]
            ),
            ProgramWorkoutDefinition(
                name: "Drill & Technique",
                description: "Improve stroke efficiency with focused drills",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "300m", weight: nil, restSeconds: 0, notes: "Easy swimming, mix strokes"),
                    ProgramExerciseDefinition(exerciseName: "Catch-Up Drill", sets: 4, reps: "50m", weight: nil, restSeconds: 15, notes: "Touch hands before next stroke"),
                    ProgramExerciseDefinition(exerciseName: "Fingertip Drag", sets: 4, reps: "50m", weight: nil, restSeconds: 15, notes: "High elbow recovery"),
                    ProgramExerciseDefinition(exerciseName: "Kick with Board", sets: 4, reps: "50m", weight: nil, restSeconds: 20, notes: "Flutter kick, face in water"),
                    ProgramExerciseDefinition(exerciseName: "3-3-3 Breathing", sets: 4, reps: "75m", weight: nil, restSeconds: 20, notes: "Breathe every 3 strokes"),
                    ProgramExerciseDefinition(exerciseName: "Build Swim", sets: 4, reps: "50m", weight: nil, restSeconds: 15, notes: "Start slow, finish fast"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "200m", weight: nil, restSeconds: 0, notes: "Easy backstroke")
                ],
                warmup: ["Shoulder circles in water", "Easy laps"],
                cooldown: ["Gentle swimming", "Stretching"]
            ),
            ProgramWorkoutDefinition(
                name: "Interval Training",
                description: "Speed work with structured rest intervals",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "300m", weight: nil, restSeconds: 0, notes: "Progressive pace warmup"),
                    ProgramExerciseDefinition(exerciseName: "Sprint Set", sets: 8, reps: "25m", weight: nil, restSeconds: 20, notes: "Fast freestyle, 20 sec rest"),
                    ProgramExerciseDefinition(exerciseName: "Recovery", sets: 1, reps: "100m", weight: nil, restSeconds: 0, notes: "Easy backstroke"),
                    ProgramExerciseDefinition(exerciseName: "Pyramid Set", sets: 1, reps: "50-100-150-100-50m", weight: nil, restSeconds: 15, notes: "Build up then back down"),
                    ProgramExerciseDefinition(exerciseName: "IM Set", sets: 2, reps: "100m", weight: nil, restSeconds: 30, notes: "Butterfly-Back-Breast-Free"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "200m", weight: nil, restSeconds: 0, notes: "Easy choice of stroke")
                ],
                warmup: ["Dynamic stretching", "Easy laps"],
                cooldown: ["Easy swimming", "Pool wall stretches"]
            )
        ]
        context.insert(lapSwimming)

        // 3. Triathlon Swim
        let triSwim = ProgramTemplate(
            name: "Triathlon Swim Training",
            description: "Prepare for the swim leg of your triathlon. Open water skills, pacing, and endurance for race day success.",
            category: .swimming,
            difficulty: .intermediate,
            durationWeeks: 10,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .competition,
            equipmentRequired: ["Pool Access", "Wetsuit", "Goggles"]
        )
        context.insert(triSwim)

        // 4. Stroke Improvement
        let strokeImprovement = ProgramTemplate(
            name: "Stroke Technique Program",
            description: "Refine your swimming technique with drills and focused practice. Swim more efficiently with less effort.",
            category: .swimming,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 40,
            goal: .athleticPerformance,
            equipmentRequired: ["Pool Access", "Pull Buoy", "Kickboard"]
        )
        context.insert(strokeImprovement)

        // 5. Masters Swimming
        let masters = ProgramTemplate(
            name: "Masters Swimming",
            description: "Structured workouts for adult fitness swimmers. Mix of technique, endurance, and speed work.",
            category: .swimming,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 60,
            goal: .endurance,
            equipmentRequired: ["Pool Access", "Goggles", "Fins"]
        )
        context.insert(masters)

        // 6. Pool HIIT
        let poolHIIT = ProgramTemplate(
            name: "Pool HIIT Workout",
            description: "High-intensity interval training in the pool. Burn calories with sprint sets and minimal rest.",
            category: .swimming,
            difficulty: .advanced,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 35,
            goal: .fatloss,
            equipmentRequired: ["Pool Access", "Goggles"]
        )
        context.insert(poolHIIT)

        // 7. Water Aerobics
        let waterAerobics = ProgramTemplate(
            name: "Water Aerobics",
            description: "Low-impact aquatic exercise for all fitness levels. Great for joint health and cardiovascular fitness.",
            category: .swimming,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .general,
            equipmentRequired: ["Pool Access", "Water Weights"]
        )
        context.insert(waterAerobics)

        // 8. Distance Swimming
        let distanceSwim = ProgramTemplate(
            name: "Distance Swimming",
            description: "Build endurance for longer swims. Progressive distance increases to swim a mile or more continuously.",
            category: .swimming,
            difficulty: .intermediate,
            durationWeeks: 10,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 50,
            goal: .endurance,
            equipmentRequired: ["Pool Access", "Goggles"]
        )
        context.insert(distanceSwim)

        // 9. Butterfly Mastery
        let butterfly = ProgramTemplate(
            name: "Butterfly Stroke Mastery",
            description: "Learn and master the butterfly stroke. The most challenging and impressive swimming technique.",
            category: .swimming,
            difficulty: .advanced,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .athleticPerformance,
            equipmentRequired: ["Pool Access", "Fins", "Paddles"]
        )
        context.insert(butterfly)

        // 10. Swim for Weight Loss
        let swimWeightLoss = ProgramTemplate(
            name: "Swimming for Weight Loss",
            description: "Use swimming to burn calories and lose weight. Full-body, low-impact cardio that's easy on joints.",
            category: .swimming,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 40,
            goal: .fatloss,
            equipmentRequired: ["Pool Access", "Goggles"]
        )
        context.insert(swimWeightLoss)

        // 11. Open Water Prep
        let openWater = ProgramTemplate(
            name: "Open Water Swimming Prep",
            description: "Transition from pool to open water. Navigation, sighting, and dealing with waves and currents.",
            category: .swimming,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .athleticPerformance,
            equipmentRequired: ["Pool/Open Water Access", "Wetsuit", "Brightly Colored Swim Cap"]
        )
        context.insert(openWater)
    }

    // MARK: - Calisthenics Programs (10+)
    static func seedCalisthenicsPrograms(in context: ModelContext) {

        // 1. Calisthenics Fundamentals
        let calisthenicsBasics = ProgramTemplate(
            name: "Calisthenics Fundamentals",
            description: "Master your bodyweight with foundational calisthenics. Push-ups, pull-ups, dips, and squats done right.",
            category: .calisthenics,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 40,
            goal: .strength,
            equipmentRequired: ["Pull-up Bar"],
            isFeatured: true
        )
        // Add workout definitions
        calisthenicsBasics.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Day A - Push Focus",
                description: "Build pushing strength with progressions",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 3, reps: "8-12", weight: "Bodyweight", restSeconds: 60, notes: "Keep core tight, full range of motion"),
                    ProgramExerciseDefinition(exerciseName: "Wide Push-ups", sets: 3, reps: "8-10", weight: "Bodyweight", restSeconds: 60, notes: "Hands wider than shoulder width"),
                    ProgramExerciseDefinition(exerciseName: "Diamond Push-ups", sets: 3, reps: "6-10", weight: "Bodyweight", restSeconds: 60, notes: "Hands form diamond shape"),
                    ProgramExerciseDefinition(exerciseName: "Pike Push-ups", sets: 3, reps: "6-8", weight: "Bodyweight", restSeconds: 60, notes: "Hips high, target shoulders"),
                    ProgramExerciseDefinition(exerciseName: "Tricep Dips (Bench)", sets: 3, reps: "10-12", weight: "Bodyweight", restSeconds: 60, notes: "Use bench or chair"),
                    ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 3, reps: "30-45 sec", weight: "Bodyweight", restSeconds: 45, notes: "Keep body in straight line")
                ],
                warmup: ["Arm circles", "Shoulder rolls", "Wrist circles", "Light jogging in place"],
                cooldown: ["Chest stretch", "Shoulder stretch", "Tricep stretch"]
            ),
            ProgramWorkoutDefinition(
                name: "Day B - Pull Focus",
                description: "Develop pulling strength and back muscles",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Pull-ups", sets: 3, reps: "5-8", weight: "Bodyweight", restSeconds: 90, notes: "Use assisted if needed"),
                    ProgramExerciseDefinition(exerciseName: "Chin-ups", sets: 3, reps: "5-8", weight: "Bodyweight", restSeconds: 90, notes: "Palms facing you"),
                    ProgramExerciseDefinition(exerciseName: "Australian Rows", sets: 3, reps: "10-12", weight: "Bodyweight", restSeconds: 60, notes: "Use low bar or table"),
                    ProgramExerciseDefinition(exerciseName: "Negative Pull-ups", sets: 3, reps: "5", weight: "Bodyweight", restSeconds: 90, notes: "5 second lowering phase"),
                    ProgramExerciseDefinition(exerciseName: "Scapular Pull-ups", sets: 3, reps: "10", weight: "Bodyweight", restSeconds: 45, notes: "Focus on shoulder blade movement"),
                    ProgramExerciseDefinition(exerciseName: "Dead Hang", sets: 3, reps: "20-30 sec", weight: "Bodyweight", restSeconds: 45, notes: "Build grip strength")
                ],
                warmup: ["Arm swings", "Band pull-aparts", "Cat-cow stretches"],
                cooldown: ["Lat stretch", "Bicep stretch", "Forearm stretch"]
            ),
            ProgramWorkoutDefinition(
                name: "Day C - Legs & Core",
                description: "Lower body and core stability work",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Bodyweight Squats", sets: 3, reps: "15-20", weight: "Bodyweight", restSeconds: 60, notes: "Full depth, knees track toes"),
                    ProgramExerciseDefinition(exerciseName: "Lunges", sets: 3, reps: "10 each leg", weight: "Bodyweight", restSeconds: 60, notes: "Alternate legs"),
                    ProgramExerciseDefinition(exerciseName: "Bulgarian Split Squats", sets: 3, reps: "8 each leg", weight: "Bodyweight", restSeconds: 60, notes: "Rear foot elevated"),
                    ProgramExerciseDefinition(exerciseName: "Glute Bridges", sets: 3, reps: "15", weight: "Bodyweight", restSeconds: 45, notes: "Squeeze glutes at top"),
                    ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 3, reps: "20 each side", weight: "Bodyweight", restSeconds: 45, notes: "Controlled pace"),
                    ProgramExerciseDefinition(exerciseName: "Leg Raises", sets: 3, reps: "12-15", weight: "Bodyweight", restSeconds: 45, notes: "Keep lower back pressed down"),
                    ProgramExerciseDefinition(exerciseName: "Hollow Body Hold", sets: 3, reps: "20-30 sec", weight: "Bodyweight", restSeconds: 45, notes: "Arms overhead, legs extended")
                ],
                warmup: ["Leg swings", "Hip circles", "Bodyweight good mornings"],
                cooldown: ["Quad stretch", "Hamstring stretch", "Hip flexor stretch", "Pigeon pose"]
            )
        ]
        // Add schedule (Mon/Wed/Fri pattern)
        calisthenicsBasics.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Day A - Push Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Day B - Pull Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Day C - Legs & Core", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        context.insert(calisthenicsBasics)

        // 2. First Pull-up
        let firstPullup = ProgramTemplate(
            name: "First Pull-up Program",
            description: "Can't do a pull-up yet? This program will get you there. Progressive exercises to build pulling strength.",
            category: .calisthenics,
            difficulty: .beginner,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .strength,
            equipmentRequired: ["Pull-up Bar", "Resistance Bands"]
        )
        context.insert(firstPullup)

        // 3. Street Workout
        let streetWorkout = ProgramTemplate(
            name: "Street Workout Program",
            description: "Train like the street workout pros. Build impressive strength and skills using just your body and bars.",
            category: .calisthenics,
            difficulty: .intermediate,
            durationWeeks: 12,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 50,
            goal: .strength,
            equipmentRequired: ["Pull-up Bar", "Parallel Bars"]
        )
        context.insert(streetWorkout)

        // 4. Muscle-up Journey
        let muscleUp = ProgramTemplate(
            name: "Muscle-up Mastery",
            description: "Progress towards the impressive muscle-up. Build the strength and technique for this iconic movement.",
            category: .calisthenics,
            difficulty: .advanced,
            durationWeeks: 12,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 45,
            goal: .strength,
            equipmentRequired: ["Pull-up Bar", "Rings"]
        )
        context.insert(muscleUp)

        // 5. Push-up Mastery
        let pushupMastery = ProgramTemplate(
            name: "100 Push-ups Program",
            description: "Build up to 100 consecutive push-ups. Progressive program with variations to keep you challenged.",
            category: .calisthenics,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .endurance,
            equipmentRequired: ["None"]
        )
        context.insert(pushupMastery)

        // 6. Handstand Training
        let handstand = ProgramTemplate(
            name: "Handstand Training",
            description: "Learn to hold a freestanding handstand. Progressive exercises from wall walks to balance drills.",
            category: .calisthenics,
            difficulty: .intermediate,
            durationWeeks: 10,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 30,
            goal: .athleticPerformance,
            equipmentRequired: ["Wall Space"]
        )
        context.insert(handstand)

        // 7. Pistol Squat Program
        let pistolSquat = ProgramTemplate(
            name: "Pistol Squat Program",
            description: "Build single-leg strength for the pistol squat. Mobility and strength progressions for this challenging move.",
            category: .calisthenics,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 35,
            goal: .strength,
            equipmentRequired: ["None"]
        )
        context.insert(pistolSquat)

        // 8. Prison Workout
        let prisonWorkout = ProgramTemplate(
            name: "Prison-Style Workout",
            description: "No equipment, no excuses. High-volume bodyweight training that builds serious muscle and endurance.",
            category: .calisthenics,
            difficulty: .intermediate,
            durationWeeks: 8,
            workoutsPerWeek: 5,
            estimatedMinutesPerSession: 40,
            goal: .muscleBuilding,
            equipmentRequired: ["None"]
        )
        context.insert(prisonWorkout)

        // 9. Gymnastic Rings
        let rings = ProgramTemplate(
            name: "Gymnastic Rings Training",
            description: "Unlock the power of rings training. Unstable surface builds incredible strength and body control.",
            category: .calisthenics,
            difficulty: .advanced,
            durationWeeks: 10,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 45,
            goal: .strength,
            equipmentRequired: ["Gymnastic Rings"]
        )
        context.insert(rings)

        // 10. Core Calisthenics
        let coreCalisthenics = ProgramTemplate(
            name: "Core Calisthenics",
            description: "Build an iron core with bodyweight exercises. From hollow holds to dragon flags and L-sits.",
            category: .calisthenics,
            difficulty: .intermediate,
            durationWeeks: 6,
            workoutsPerWeek: 4,
            estimatedMinutesPerSession: 25,
            goal: .strength,
            equipmentRequired: ["Pull-up Bar"]
        )
        context.insert(coreCalisthenics)

        // 11. Planche Training
        let planche = ProgramTemplate(
            name: "Planche Progression",
            description: "Work towards the incredible planche hold. One of the most impressive feats of bodyweight strength.",
            category: .calisthenics,
            difficulty: .advanced,
            durationWeeks: 16,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 40,
            goal: .strength,
            equipmentRequired: ["Parallettes", "Floor Space"]
        )
        context.insert(planche)

        // 12. Beginner Bodyweight
        let beginnerBodyweight = ProgramTemplate(
            name: "Beginner Bodyweight",
            description: "Start your fitness journey with zero equipment. Build strength and conditioning from home.",
            category: .calisthenics,
            difficulty: .beginner,
            durationWeeks: 6,
            workoutsPerWeek: 3,
            estimatedMinutesPerSession: 30,
            goal: .general,
            equipmentRequired: ["None"]
        )
        context.insert(beginnerBodyweight)
    }
}
