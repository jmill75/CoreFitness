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
        powerlifting.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Heavy Squat", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Heavy Bench", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Heavy Deadlift", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Volume Day", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        powerlifting.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Heavy Squat", description: "Primary squat focus", estimatedMinutes: 75, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 5, reps: "3", weight: "85-90% 1RM", restSeconds: 300),
                ProgramExerciseDefinition(exerciseName: "Pause Squats", sets: 3, reps: "3", weight: "70%", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 3, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 3, reps: "8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Ab Wheel", sets: 3, reps: "10-12", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Heavy Bench", description: "Primary bench focus", estimatedMinutes: 75, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 5, reps: "3", weight: "85-90% 1RM", restSeconds: 300),
                ProgramExerciseDefinition(exerciseName: "Close Grip Bench Press", sets: 3, reps: "5", weight: "75%", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Rows", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 3, reps: "6-8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Tricep Pushdowns", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Heavy Deadlift", description: "Primary deadlift focus", estimatedMinutes: 75, exercises: [
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 5, reps: "3", weight: "85-90% 1RM", restSeconds: 300),
                ProgramExerciseDefinition(exerciseName: "Deficit Deadlift", sets: 3, reps: "3", weight: "70%", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 4, reps: "6-8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Pull-ups", sets: 3, reps: "6-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "15-20", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Volume Day", description: "Lighter technique work", estimatedMinutes: 70, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 4, reps: "6", weight: "70%", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 4, reps: "6", weight: "70%", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 3, reps: "5", weight: "65%", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12-15", restSeconds: 60)
            ])
        ]
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
        gvt.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Chest & Back", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Legs & Abs", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Arms & Shoulders", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: "Light Recovery", isRest: false)
        ]
        gvt.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Chest & Back", description: "10x10 antagonist supersets", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 10, reps: "10", weight: "60% 1RM", restSeconds: 90, notes: "Superset with rows"),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 10, reps: "10", weight: "60% 1RM", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Flyes", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Cable Rows", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Legs & Abs", description: "10x10 leg destroyer", estimatedMinutes: 65, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 10, reps: "10", weight: "60% 1RM", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 10, reps: "10", weight: "60% 1RM", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 3, reps: "15-20", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Hanging Leg Raises", sets: 3, reps: "15-20", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Arms & Shoulders", description: "10x10 arm pump", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dips", sets: 10, reps: "10", weight: "Bodyweight", restSeconds: 90, notes: "Superset with curls"),
                ProgramExerciseDefinition(exerciseName: "Barbell Curls", sets: 10, reps: "10", weight: "60% 1RM", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Reverse Flyes", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Light Recovery", description: "Active recovery", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 3, reps: "12", weight: "Light", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 3, reps: "12", weight: "Light", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "15", restSeconds: 45),
                ProgramExerciseDefinition(exerciseName: "Ab Wheel", sets: 3, reps: "10-12", restSeconds: 45)
            ])
        ]
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
        startingStrength.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Workout A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Workout B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Workout A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        startingStrength.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Workout A", description: "Squat, Press, Deadlift", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 3, reps: "5", weight: "Add 5lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 3, reps: "5", weight: "Add 2.5lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 1, reps: "5", weight: "Add 10lbs/session", restSeconds: 180)
            ]),
            ProgramWorkoutDefinition(name: "Workout B", description: "Squat, Bench, Power Clean", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 3, reps: "5", weight: "Add 5lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 3, reps: "5", weight: "Add 2.5lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Power Clean", sets: 5, reps: "3", weight: "Add 5lbs/session", restSeconds: 180)
            ])
        ]
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
        arnoldSplit.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Chest & Back A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Shoulders & Arms A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Legs A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Chest & Back B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Shoulders & Arms B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Legs B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        arnoldSplit.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Chest & Back A", description: "Heavy chest and back", estimatedMinutes: 70, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 5, reps: "6-8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Press", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Pull-ups", sets: 5, reps: "8-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Cable Flyes", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Pullovers", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Shoulders & Arms A", description: "Heavy shoulders and arms", estimatedMinutes: 65, exercises: [
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 4, reps: "6-8", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 4, reps: "10-12", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Barbell Curls", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Skull Crushers", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Reverse Flyes", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Wrist Curls", sets: 3, reps: "15-20", restSeconds: 45)
            ]),
            ProgramWorkoutDefinition(name: "Legs A", description: "Heavy leg day", estimatedMinutes: 70, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 5, reps: "6-8", restSeconds: 150),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 4, reps: "10-12", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Extensions", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Standing Calf Raises", sets: 5, reps: "15-20", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Chest & Back B", description: "Volume chest and back", estimatedMinutes: 70, exercises: [
                ProgramExerciseDefinition(exerciseName: "Incline Barbell Press", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Bench Press", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Seated Cable Row", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Pec Deck", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Straight Arm Pulldowns", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Shoulders & Arms B", description: "Volume shoulders and arms", estimatedMinutes: 65, exercises: [
                ProgramExerciseDefinition(exerciseName: "Arnold Press", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Cable Lateral Raises", sets: 4, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Curls", sets: 4, reps: "10-12", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Tricep Pushdowns", sets: 4, reps: "10-12", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "15-20", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Hammer Curls", sets: 3, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Legs B", description: "Volume leg day", estimatedMinutes: 70, exercises: [
                ProgramExerciseDefinition(exerciseName: "Front Squats", sets: 4, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Walking Lunges", sets: 3, reps: "12-15", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Seated Calf Raises", sets: 4, reps: "15-20", restSeconds: 60)
            ])
        ]
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
        minimalist.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Day A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Day B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Day A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        minimalist.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Day A", description: "Squat and Press", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 3, reps: "5", weight: "Add 5lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Overhead Press", sets: 3, reps: "5", weight: "Add 2.5lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Pull-ups", sets: 3, reps: "AMRAP", restSeconds: 120)
            ]),
            ProgramWorkoutDefinition(name: "Day B", description: "Deadlift and Bench", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Deadlift", sets: 1, reps: "5", weight: "Add 10lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Barbell Bench Press", sets: 3, reps: "5", weight: "Add 2.5lbs/session", restSeconds: 180),
                ProgramExerciseDefinition(exerciseName: "Barbell Rows", sets: 3, reps: "5", weight: "Add 5lbs/session", restSeconds: 120)
            ])
        ]
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
        gluteBuilder.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Glute Focus A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Upper Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Glute Focus B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Lower", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        gluteBuilder.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Glute Focus A", description: "Heavy glute emphasis", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Hip Thrusts", sets: 4, reps: "8-10", weight: "Heavy", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Bulgarian Split Squats", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Cable Kickbacks", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Banded Clamshells", sets: 3, reps: "15-20", restSeconds: 45)
            ]),
            ProgramWorkoutDefinition(name: "Upper Body", description: "Light upper maintenance", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dumbbell Shoulder Press", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Lat Pulldown", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 3, reps: "10-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "15-20", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Tricep Pushdowns", sets: 2, reps: "12-15", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Glute Focus B", description: "Volume glute work", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sumo Deadlift", sets: 4, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Glute Bridge", sets: 4, reps: "12-15", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Step Ups", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Banded Hip Abduction", sets: 3, reps: "15-20", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Frog Pumps", sets: 3, reps: "20-25", restSeconds: 45)
            ]),
            ProgramWorkoutDefinition(name: "Full Lower", description: "Complete lower body", estimatedMinutes: 55, exercises: [
                ProgramExerciseDefinition(exerciseName: "Barbell Squats", sets: 4, reps: "8-10", restSeconds: 120),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 3, reps: "12-15", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Hip Thrusts", sets: 3, reps: "12-15", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 3, reps: "15-20", restSeconds: 60)
            ])
        ]
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
        dumbbellOnly.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Upper Body A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Lower Body A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Upper Body B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Lower Body B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        dumbbellOnly.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Upper Body A", description: "Push focus", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dumbbell Bench Press", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Rows", sets: 4, reps: "8-10", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Shoulder Press", sets: 3, reps: "10-12", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Curls", sets: 3, reps: "10-12", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Overhead Tricep Extension", sets: 3, reps: "10-12", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Lower Body A", description: "Quad focus", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Goblet Squats", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlift", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Walking Lunges", sets: 3, reps: "12-15", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Calf Raises", sets: 3, reps: "15-20", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Plank", sets: 3, reps: "30-60s", restSeconds: 45)
            ]),
            ProgramWorkoutDefinition(name: "Upper Body B", description: "Pull focus", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Press", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Pullovers", sets: 3, reps: "10-12", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Arnold Press", sets: 3, reps: "10-12", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Reverse Flyes", sets: 3, reps: "12-15", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Hammer Curls", sets: 3, reps: "10-12", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Skull Crushers", sets: 3, reps: "10-12", restSeconds: 60)
            ]),
            ProgramWorkoutDefinition(name: "Lower Body B", description: "Glute/ham focus", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dumbbell Sumo Squats", sets: 4, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Single Leg Romanian Deadlift", sets: 3, reps: "10-12", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Step Ups", sets: 3, reps: "10-12", restSeconds: 75),
                ProgramExerciseDefinition(exerciseName: "Glute Bridge", sets: 3, reps: "15-20", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 3, reps: "10-12", restSeconds: 45)
            ])
        ]
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
        beginnerCardio.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Walk & Jog Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Steady Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Walk & Jog Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Long Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        beginnerCardio.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Walk & Jog Intervals", description: "Alternate walking and light jogging", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Walk", sets: 1, reps: "5 min", restSeconds: 0, notes: "Easy pace"),
                ProgramExerciseDefinition(exerciseName: "Walk/Jog Intervals", sets: 8, reps: "1 min jog / 1.5 min walk", restSeconds: 0, notes: "Jog at conversational pace"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Steady Walk", description: "Brisk walking session", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Easy Walk", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Brisk Walk", sets: 1, reps: "20 min", restSeconds: 0, notes: "Walk with purpose, slightly breathless"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Long Walk", description: "Extended easy walk", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Continuous Walk", sets: 1, reps: "40 min", restSeconds: 0, notes: "Comfortable pace, enjoy the scenery"),
                ProgramExerciseDefinition(exerciseName: "Stretching", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        fatBurn.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Fasted LISS", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Moderate Steady State", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Incline Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Moderate Steady State", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Long LISS", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        fatBurn.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Fasted LISS", description: "Low intensity steady state before breakfast", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Walk", sets: 1, reps: "5 min", restSeconds: 0, notes: "Easy pace to warm up"),
                ProgramExerciseDefinition(exerciseName: "Brisk Walk/Light Jog", sets: 1, reps: "30 min", restSeconds: 0, notes: "Keep heart rate at 55-65% max. Fat burning zone"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0, notes: "Gradual slowdown")
            ]),
            ProgramWorkoutDefinition(name: "Moderate Steady State", description: "Moderate effort cardio session", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dynamic Warmup", sets: 1, reps: "5 min", restSeconds: 0, notes: "Leg swings, high knees, arm circles"),
                ProgramExerciseDefinition(exerciseName: "Steady Jog/Bike", sets: 1, reps: "25 min", restSeconds: 0, notes: "65-75% max HR. Challenging but sustainable"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Incline Walk", description: "Treadmill incline for calorie burn", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Flat Walk Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Incline Walk", sets: 1, reps: "30 min", restSeconds: 0, notes: "10-15% incline, 3.0-3.5 mph. Hold onto rails minimally"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Flat Walk", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Long LISS", description: "Extended low intensity session", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Easy Cardio", sets: 1, reps: "40 min", restSeconds: 0, notes: "Walk, bike, or elliptical. Keep effort easy, 55-65% max HR"),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        stairs.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Steady Climb", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Interval Stairs", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Endurance Climb", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        stairs.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Steady Climb", description: "Consistent pace stair climbing", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Walk", sets: 1, reps: "5 min", restSeconds: 0, notes: "Flat walking or easy stairs"),
                ProgramExerciseDefinition(exerciseName: "Steady Stair Climb", sets: 1, reps: "15 min", restSeconds: 0, notes: "Moderate pace you can maintain. Level 5-7 on StairMaster"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0, notes: "Easy pace, let legs recover")
            ]),
            ProgramWorkoutDefinition(name: "Interval Stairs", description: "Hard/easy stair intervals", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0, notes: "Light stair climbing"),
                ProgramExerciseDefinition(exerciseName: "Hard Intervals", sets: 6, reps: "1 min hard / 1 min easy", restSeconds: 0, notes: "Push hard then recover. Skip steps on hard intervals"),
                ProgramExerciseDefinition(exerciseName: "Steady Climb", sets: 1, reps: "6 min", restSeconds: 0, notes: "Moderate pace"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Endurance Climb", description: "Extended stair session", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Continuous Climb", sets: 1, reps: "25 min", restSeconds: 0, notes: "Find sustainable rhythm. Focus on form, drive through heels"),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0, notes: "Quad and calf stretches")
            ])
        ]
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
        rowing.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Steady State Row", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Interval Row", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Pyramid Row", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Long Distance Row", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        rowing.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Steady State Row", description: "Build aerobic base with consistent rowing", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Row", sets: 1, reps: "5 min", restSeconds: 0, notes: "Easy strokes, focus on form"),
                ProgramExerciseDefinition(exerciseName: "Steady Row", sets: 1, reps: "20 min", restSeconds: 0, notes: "20-22 strokes/min. Aim for consistent split time"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Row", sets: 1, reps: "5 min", restSeconds: 0, notes: "Very easy pace")
            ]),
            ProgramWorkoutDefinition(name: "Interval Row", description: "High/low intensity rowing intervals", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Hard Row Intervals", sets: 8, reps: "1 min hard / 1 min easy", restSeconds: 0, notes: "26-28 strokes/min on hard efforts"),
                ProgramExerciseDefinition(exerciseName: "Moderate Row", sets: 1, reps: "8 min", restSeconds: 0, notes: "Recover at conversational pace"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Pyramid Row", description: "Ascending and descending intervals", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "1 min Hard", sets: 1, reps: "1 min", restSeconds: 60, notes: "Build intensity"),
                ProgramExerciseDefinition(exerciseName: "2 min Hard", sets: 1, reps: "2 min", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "3 min Hard", sets: 1, reps: "3 min", restSeconds: 90, notes: "Peak effort"),
                ProgramExerciseDefinition(exerciseName: "2 min Hard", sets: 1, reps: "2 min", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "1 min Hard", sets: 1, reps: "1 min", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Easy Row", sets: 1, reps: "8 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Long Distance Row", description: "Extended endurance row", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Distance Row", sets: 1, reps: "35 min", restSeconds: 0, notes: "Steady 18-20 strokes/min. Focus on power through legs"),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        jumpRope.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Basics & Rhythm", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Interval Skipping", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Footwork Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Conditioning Circuit", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        jumpRope.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Basics & Rhythm", description: "Foundation jump rope skills", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Light Jog Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Basic Bounce", sets: 5, reps: "30 sec", restSeconds: 30, notes: "Bounce on balls of feet, slight knee bend"),
                ProgramExerciseDefinition(exerciseName: "Alternate Foot Step", sets: 4, reps: "30 sec", restSeconds: 30, notes: "Like running in place"),
                ProgramExerciseDefinition(exerciseName: "Basic Bounce", sets: 3, reps: "1 min", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Cool Down Stretch", sets: 1, reps: "3 min", restSeconds: 0, notes: "Calves, shoulders, wrists")
            ]),
            ProgramWorkoutDefinition(name: "Interval Skipping", description: "Work/rest intervals for conditioning", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Jumps", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Fast Skipping", sets: 8, reps: "30 sec fast / 30 sec rest", restSeconds: 0, notes: "Maximum speed during work"),
                ProgramExerciseDefinition(exerciseName: "Moderate Continuous", sets: 1, reps: "5 min", restSeconds: 0, notes: "Steady sustainable pace"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Footwork Focus", description: "Learn jump rope variations", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "High Knees", sets: 4, reps: "20 sec", restSeconds: 20, notes: "Drive knees up with each jump"),
                ProgramExerciseDefinition(exerciseName: "Side to Side", sets: 4, reps: "20 sec", restSeconds: 20, notes: "Small lateral hops"),
                ProgramExerciseDefinition(exerciseName: "Front to Back", sets: 4, reps: "20 sec", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Single Leg Hops", sets: 4, reps: "15 sec each leg", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Combo Practice", sets: 3, reps: "1 min", restSeconds: 30, notes: "Mix all variations"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Conditioning Circuit", description: "Full conditioning workout", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jump Rope", sets: 1, reps: "2 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Burpees", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jump Rope", sets: 1, reps: "2 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 1, reps: "30 sec", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jump Rope", sets: 1, reps: "2 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Squat Jumps", sets: 1, reps: "15 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jump Rope", sets: 1, reps: "2 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Push Ups", sets: 1, reps: "15 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jump Rope Finisher", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        elliptical.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Steady State", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Resistance Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Incline Challenge", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Long Endurance", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        elliptical.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Steady State", description: "Consistent pace cardio", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0, notes: "Low resistance, easy pace"),
                ProgramExerciseDefinition(exerciseName: "Steady Elliptical", sets: 1, reps: "20 min", restSeconds: 0, notes: "Moderate resistance (level 5-7). 60-70 RPM"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Resistance Intervals", description: "Alternate high and low resistance", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "High Resistance Intervals", sets: 6, reps: "2 min high / 2 min low", restSeconds: 0, notes: "High = level 10+, Low = level 5"),
                ProgramExerciseDefinition(exerciseName: "Steady Finish", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Incline Challenge", description: "Work with varied incline", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Incline Pyramid", sets: 1, reps: "5 min each", restSeconds: 0, notes: "Incline 5 → 10 → 15 → 10 → 5"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Long Endurance", description: "Extended cardio session", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Endurance Elliptical", sets: 1, reps: "35 min", restSeconds: 0, notes: "Moderate effort, find sustainable rhythm. Can watch TV or listen to music"),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        mixedCardio.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Treadmill Day", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Bike Day", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Row & Ski Erg", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Mix It Up", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        mixedCardio.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Treadmill Day", description: "Running and walking intervals", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Walk Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Run Intervals", sets: 5, reps: "3 min run / 2 min walk", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Incline Walk", sets: 1, reps: "5 min", restSeconds: 0, notes: "10% incline"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Bike Day", description: "Cycling intervals and steady state", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Easy Spin Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "High Cadence Intervals", sets: 6, reps: "1 min fast / 1 min easy", restSeconds: 0, notes: "100+ RPM on fast"),
                ProgramExerciseDefinition(exerciseName: "Heavy Resistance Climb", sets: 3, reps: "3 min", restSeconds: 60, notes: "High resistance, out of saddle if able"),
                ProgramExerciseDefinition(exerciseName: "Steady Ride", sets: 1, reps: "8 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Row & Ski Erg", description: "Upper body focused cardio", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Row Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Rowing Intervals", sets: 4, reps: "2 min hard / 1 min easy", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Ski Erg", sets: 1, reps: "10 min", restSeconds: 0, notes: "If no ski erg, do arm bike"),
                ProgramExerciseDefinition(exerciseName: "Row Finish", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Mix It Up", description: "Rotate through machines", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Choice", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Treadmill", sets: 1, reps: "8 min", restSeconds: 0, notes: "Moderate jog"),
                ProgramExerciseDefinition(exerciseName: "Bike", sets: 1, reps: "8 min", restSeconds: 0, notes: "Steady cycling"),
                ProgramExerciseDefinition(exerciseName: "Elliptical", sets: 1, reps: "8 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Rower", sets: 1, reps: "8 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        heartHealth.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Moderate Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Light Activity", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Moderate Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Weekend Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        heartHealth.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Moderate Walk", description: "Brisk walking for heart health", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Easy Walk Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Brisk Walk", sets: 1, reps: "20 min", restSeconds: 0, notes: "Walk briskly - you should be slightly breathless but able to talk"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Light Activity", description: "Gentle movement session", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Light Walk", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 2, reps: "30 sec each direction", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Marching in Place", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Side Steps", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Gentle Stretching", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Weekend Walk", description: "Longer enjoyable walk", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warm Up Walk", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Continuous Walk", sets: 1, reps: "30 min", restSeconds: 0, notes: "Find a nice route. Moderate pace, enjoy the scenery"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        advancedCardio.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "VO2 Max Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Tempo Session", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Sprint Training", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Cross Training", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Long Endurance", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        advancedCardio.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "VO2 Max Intervals", description: "High intensity intervals for maximum oxygen uptake", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "10 min", restSeconds: 0, notes: "Progressive intensity"),
                ProgramExerciseDefinition(exerciseName: "VO2 Max Intervals", sets: 5, reps: "3 min @ 95% effort / 3 min recovery", restSeconds: 0, notes: "Push to near max effort. Recovery should be active"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Tempo Session", description: "Sustained threshold effort", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Tempo Effort", sets: 2, reps: "15 min @ 80-85%", restSeconds: 180, notes: "Comfortably hard - can speak in short sentences"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "10 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Sprint Training", description: "Short explosive efforts", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Extended Warmup", sets: 1, reps: "15 min", restSeconds: 0, notes: "Include dynamic stretches"),
                ProgramExerciseDefinition(exerciseName: "Sprint Intervals", sets: 10, reps: "30 sec all-out / 90 sec recovery", restSeconds: 0, notes: "Maximum effort sprints"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Jog", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Cross Training", description: "Multi-modality conditioning", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Row Hard", sets: 1, reps: "5 min", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Bike Sprints", sets: 5, reps: "1 min hard / 1 min easy", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Assault Bike/Ski Erg", sets: 1, reps: "10 min", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Treadmill Run", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Long Endurance", description: "Extended aerobic session", estimatedMinutes: 60, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Steady State Cardio", sets: 1, reps: "50 min", restSeconds: 0, notes: "70-75% effort. Build mental toughness"),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        walkingProgram.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Power Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Interval Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Incline Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Steady Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Long Walk", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        walkingProgram.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Power Walk", description: "Brisk walking with arm engagement", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Easy Walk Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Power Walk", sets: 1, reps: "30 min", restSeconds: 0, notes: "Walk as fast as you can without running. Pump arms actively"),
                ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Interval Walk", description: "Fast and slow walking intervals", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Walk", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Fast/Slow Intervals", sets: 10, reps: "2 min fast / 1 min easy", restSeconds: 0, notes: "Fast = almost jogging, Easy = comfortable stroll"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Incline Walk", description: "Hill or treadmill incline walking", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Flat Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Incline Walk", sets: 1, reps: "25 min", restSeconds: 0, notes: "10-12% incline or find hills. 3.0-3.5 mph"),
                ProgramExerciseDefinition(exerciseName: "Flat Walk", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Steady Walk", description: "Moderate consistent pace", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Steady Walk", sets: 1, reps: "25 min", restSeconds: 0, notes: "Comfortable brisk pace. Focus on good posture"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Long Walk", description: "Extended walking session", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Continuous Walk", sets: 1, reps: "40 min", restSeconds: 0, notes: "Comfortable pace. Listen to music or podcast"),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        morningFlow.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Sun Salutation Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Energizing Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Sun Salutation Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Gentle Wake Up", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Energizing Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        morningFlow.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Sun Salutation Flow", description: "Classic morning sequence", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Seated Breathing", sets: 1, reps: "1 min", restSeconds: 0, notes: "Set intention for the day"),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow Stretch", sets: 1, reps: "8 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 5, reps: "1 round", restSeconds: 0, notes: "One breath per movement"),
                ProgramExerciseDefinition(exerciseName: "Standing Side Stretch", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Forward Fold", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Mountain Pose", sets: 1, reps: "5 breaths", restSeconds: 0, notes: "Close eyes, feel grounded")
            ]),
            ProgramWorkoutDefinition(name: "Energizing Flow", description: "Wake up the whole body", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow Stretch", sets: 1, reps: "6 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Downward Dog", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Low Lunge + Twist", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Warrior II Flow", sets: 2, reps: "3 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Triangle Pose", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Wide Leg Forward Fold", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Seated Twist", sets: 1, reps: "5 breaths each side", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Gentle Wake Up", description: "Soft morning practice", estimatedMinutes: 15, exercises: [
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "5 breaths each side", restSeconds: 0, notes: "Stay in bed if you like"),
                ProgramExerciseDefinition(exerciseName: "Knees to Chest", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Seated Side Stretch", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Seated Cat-Cow", sets: 1, reps: "6 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Neck Rolls", sets: 1, reps: "3 each direction", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Forward Fold", sets: 1, reps: "8 breaths", restSeconds: 0, notes: "Hang loose, sway gently")
            ])
        ]
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
        powerYoga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Power Flow A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Strength Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Power Flow B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Core & Balance", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        powerYoga.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Power Flow A", description: "Dynamic full body flow", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation B", sets: 5, reps: "1 round", restSeconds: 0, notes: "Build heat quickly"),
                ProgramExerciseDefinition(exerciseName: "Chair Pose Flow", sets: 3, reps: "5 breaths + twist", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Warrior I → Warrior III", sets: 1, reps: "5 breaths each, each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Crescent Lunge Pulses", sets: 1, reps: "10 each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Chaturanga Push-ups", sets: 3, reps: "8 reps", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Crow Pose Attempts", sets: 3, reps: "5-10 sec holds", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Wheel Pose", sets: 3, reps: "5 breaths", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Strength Focus", description: "Hold challenging poses", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 3, reps: "1 min", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Side Plank", sets: 2, reps: "30 sec each side", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Chair Pose Hold", sets: 3, reps: "45 sec", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Warrior III Hold", sets: 2, reps: "30 sec each side", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Boat Pose", sets: 3, reps: "30 sec", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Dolphin Pose", sets: 3, reps: "30 sec", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Bridge Lifts", sets: 3, reps: "15 reps", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Supine Core Work", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Power Flow B", description: "Advanced flow sequence", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation B", sets: 3, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Extended Side Angle Flow", sets: 2, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Half Moon Pose", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Split", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Handstand Practice", sets: 5, reps: "30 sec attempts", restSeconds: 30, notes: "Use wall if needed"),
                ProgramExerciseDefinition(exerciseName: "Forearm Stand Practice", sets: 3, reps: "30 sec attempts", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Core & Balance", description: "Core strength and balance work", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Boat Pose Variations", sets: 4, reps: "30 sec", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Plank to Downward Dog", sets: 3, reps: "10 reps", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Tree Pose", sets: 2, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Eagle Pose", sets: 2, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Dancer's Pose", sets: 2, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Crow to Chaturanga", sets: 5, reps: "1 rep", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Headstand Practice", sets: 3, reps: "30 sec", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Cooling Stretches", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        athleteYoga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Hip & Hamstring Release", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Upper Body Mobility", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Recovery Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        athleteYoga.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Hip & Hamstring Release", description: "Target common tight areas for athletes", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "10 breaths each side", restSeconds: 0, notes: "Sink deep into hip flexor stretch"),
                ProgramExerciseDefinition(exerciseName: "Half Split", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "2 min each side", restSeconds: 0, notes: "Use block under hip if needed"),
                ProgramExerciseDefinition(exerciseName: "Figure Four Stretch", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Frog Pose", sets: 1, reps: "2 min", restSeconds: 0, notes: "Go to your edge, don't force"),
                ProgramExerciseDefinition(exerciseName: "Supine Hamstring Stretch", sets: 1, reps: "10 breaths each side", restSeconds: 0, notes: "Use strap if needed"),
                ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "10 breaths", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Upper Body Mobility", description: "Shoulders, chest, and back", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Puppy Pose", sets: 1, reps: "10 breaths", restSeconds: 0, notes: "Melt chest toward floor"),
                ProgramExerciseDefinition(exerciseName: "Eagle Arms", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cow Face Arms", sets: 1, reps: "10 breaths each side", restSeconds: 0, notes: "Use strap if hands don't reach"),
                ProgramExerciseDefinition(exerciseName: "Chest Opener on Block", sets: 1, reps: "2 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sphinx Pose", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Shoulder Stretch at Wall", sets: 1, reps: "1 min each arm", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supported Fish Pose", sets: 1, reps: "2 min", restSeconds: 0, notes: "Block under upper back")
            ]),
            ProgramWorkoutDefinition(name: "Recovery Flow", description: "Gentle restorative practice", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "2 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supported Bridge", sets: 1, reps: "2 min", restSeconds: 0, notes: "Block under sacrum"),
                ProgramExerciseDefinition(exerciseName: "Reclined Butterfly", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Gentle Spinal Twist", sets: 1, reps: "2 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "2 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0, notes: "Complete rest and recovery")
            ])
        ]
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
        eveningYoga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Calming Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Bedtime Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Calming Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Restorative Rest", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Bedtime Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        eveningYoga.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Calming Flow", description: "Gentle movements to release tension", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Seated Breathing", sets: 1, reps: "2 min", restSeconds: 0, notes: "4-count inhale, 6-count exhale"),
                ProgramExerciseDefinition(exerciseName: "Neck Rolls", sets: 1, reps: "5 each direction", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Seated Side Stretch", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "8 slow rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Bedtime Stretch", description: "Prepare body for sleep", estimatedMinutes: 15, exercises: [
                ProgramExerciseDefinition(exerciseName: "Deep Breathing", sets: 1, reps: "1 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Forward Fold (Seated)", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Butterfly Pose", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supine Figure Four", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "8 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Knees to Chest", sets: 1, reps: "8 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "3 min", restSeconds: 0, notes: "Can transition to bed")
            ]),
            ProgramWorkoutDefinition(name: "Restorative Rest", description: "Deep relaxation practice", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Supported Child's Pose", sets: 1, reps: "3 min", restSeconds: 0, notes: "Pillow under chest"),
                ProgramExerciseDefinition(exerciseName: "Supported Fish Pose", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Reclined Butterfly", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana with Blanket", sets: 1, reps: "5 min", restSeconds: 0, notes: "Cover yourself, complete rest")
            ])
        ]
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
        vinyasa.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Flow Fundamentals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Standing Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Hip Opening Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Vinyasa Practice", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        vinyasa.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Flow Fundamentals", description: "Learn the vinyasa transitions", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Centering & Breath", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow Flow", sets: 1, reps: "10 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 5, reps: "1 round", restSeconds: 0, notes: "Focus on breath-movement link"),
                ProgramExerciseDefinition(exerciseName: "Sun Salutation B", sets: 3, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Sequence", sets: 2, reps: "each side", restSeconds: 0, notes: "Warrior I → II → Reverse Warrior"),
                ProgramExerciseDefinition(exerciseName: "Seated Forward Fold", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Bridge Pose", sets: 3, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Standing Flow", description: "Dynamic standing sequences", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation Warmup", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Warrior Flow", sets: 3, reps: "each side", restSeconds: 0, notes: "Warrior I → II → III → Standing Split"),
                ProgramExerciseDefinition(exerciseName: "Triangle to Half Moon", sets: 2, reps: "each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Extended Side Angle Flow", sets: 2, reps: "each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Chair Pose Variations", sets: 3, reps: "5 breaths each", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Eagle Pose Flow", sets: 2, reps: "each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Forward Fold", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Hip Opening Flow", description: "Target hips in flowing sequence", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 3, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Low Lunge Flow", sets: 2, reps: "each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Lizard Pose", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Pigeon Flow", sets: 1, reps: "12 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Half Split → Full Split Attempt", sets: 1, reps: "each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Frog Pose", sets: 1, reps: "15 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Reclined Butterfly", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Full Vinyasa Practice", description: "Complete flowing practice", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Centering", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sun Salutation B", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Series", sets: 1, reps: "both sides", restSeconds: 0, notes: "All standing poses linked with vinyasa"),
                ProgramExerciseDefinition(exerciseName: "Balance Poses", sets: 1, reps: "both sides", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Seated Sequence", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Backbends", sets: 3, reps: "5 breaths", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Inversions (Optional)", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Closing Sequence", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        yinYoga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Lower Body Yin", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Upper Body & Spine", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Body Yin", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        yinYoga.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Lower Body Yin", description: "Deep hip and leg stretches", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Butterfly Pose", sets: 1, reps: "5 min", restSeconds: 0, notes: "Fold forward, relax completely"),
                ProgramExerciseDefinition(exerciseName: "Dragon Pose (Low Lunge)", sets: 1, reps: "4 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sleeping Swan (Pigeon)", sets: 1, reps: "5 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Square Pose", sets: 1, reps: "4 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Dragonfly (Wide Straddle)", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Upper Body & Spine", description: "Spine and shoulder release", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Melting Heart Pose", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sphinx Pose", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Seal Pose", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Twisted Roots", sets: 1, reps: "4 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Caterpillar (Forward Fold)", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Fish Pose (Supported)", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Full Body Yin", description: "Complete yin sequence", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Dragon Pose", sets: 1, reps: "3 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sphinx Pose", sets: 1, reps: "4 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sleeping Swan", sets: 1, reps: "4 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Caterpillar", sets: 1, reps: "4 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "4 min each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        backPainYoga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Gentle Spine Relief", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Core Stability", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Hip & Lower Back", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Posture & Strength", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        backPainYoga.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Gentle Spine Relief", description: "Release back tension gently", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Knees to Chest", sets: 1, reps: "10 breaths", restSeconds: 0, notes: "Rock gently side to side"),
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "10 slow rounds", restSeconds: 0, notes: "Move with your breath"),
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sphinx Pose", sets: 1, reps: "8 breaths", restSeconds: 0, notes: "Gentle backbend"),
                ProgramExerciseDefinition(exerciseName: "Constructive Rest", sets: 1, reps: "3 min", restSeconds: 0, notes: "Feet flat, knees together")
            ]),
            ProgramWorkoutDefinition(name: "Core Stability", description: "Build core to support back", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 3, reps: "8 each side", restSeconds: 20, notes: "Keep lower back pressed down"),
                ProgramExerciseDefinition(exerciseName: "Bird Dog", sets: 3, reps: "8 each side", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Bridge Pose", sets: 3, reps: "8 reps", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Modified Plank (Forearms)", sets: 3, reps: "20 sec", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "8 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "10 breaths", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Hip & Lower Back", description: "Release hip tension affecting back", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Figure Four Stretch", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "8 breaths each side", restSeconds: 0, notes: "Back knee down, gentle hip flexor stretch"),
                ProgramExerciseDefinition(exerciseName: "Half Pigeon (Modified)", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Constructive Rest", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Posture & Strength", description: "Build postural awareness", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Mountain Pose", sets: 1, reps: "10 breaths", restSeconds: 0, notes: "Focus on alignment"),
                ProgramExerciseDefinition(exerciseName: "Wall Angels", sets: 2, reps: "10 reps", restSeconds: 20),
                ProgramExerciseDefinition(exerciseName: "Cobra Pose", sets: 3, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Locust Pose", sets: 3, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "6 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Forward Fold", sets: 1, reps: "10 breaths", restSeconds: 0, notes: "Bend knees, let spine hang"),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "3 min", restSeconds: 0)
            ])
        ]
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
        ashtanga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Half Primary", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Full Primary", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Half Primary", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Full Primary", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Half Primary", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true, notes: "Moon day or rest"),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        ashtanga.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Half Primary", description: "First half of primary series", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sun Salutation B", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Padangusthasana", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Padahastasana", sets: 1, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Trikonasana", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Parivrtta Trikonasana", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Utthita Parsvakonasana", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Prasarita Padottanasana A-D", sets: 1, reps: "5 breaths each", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Parsvottanasana", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Closing Sequence", sets: 1, reps: "as traditional", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "10 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Full Primary", description: "Complete primary series", estimatedMinutes: 75, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sun Salutation B", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Sequence", sets: 1, reps: "complete", restSeconds: 0, notes: "All standing poses"),
                ProgramExerciseDefinition(exerciseName: "Seated Sequence", sets: 1, reps: "complete", restSeconds: 0, notes: "Paschimottanasana through Setu Bandhasana"),
                ProgramExerciseDefinition(exerciseName: "Finishing Sequence", sets: 1, reps: "complete", restSeconds: 0, notes: "Shoulderstand, headstand, lotus sequence"),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "15 min", restSeconds: 0)
            ])
        ]
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
        deskYoga.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Neck & Shoulders", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Hip Openers", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Spine & Posture", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Body Release", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        deskYoga.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Neck & Shoulders", description: "Release upper body tension", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Neck Rolls", sets: 1, reps: "5 each direction", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Ear to Shoulder", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Eagle Arms", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Puppy Pose", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cow Face Arms", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Shoulder Stretch", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supported Fish", sets: 1, reps: "2 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Hip Openers", description: "Counteract sitting", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "8 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Lizard Pose", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Half Pigeon", sets: 1, reps: "10 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Figure Four", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "8 breaths each side", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Spine & Posture", description: "Improve alignment", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Mountain Pose", sets: 1, reps: "10 breaths", restSeconds: 0, notes: "Focus on posture"),
                ProgramExerciseDefinition(exerciseName: "Standing Forward Fold", sets: 1, reps: "8 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "10 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cobra Pose", sets: 3, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Locust Pose", sets: 2, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Spinal Twist (Seated)", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Full Body Release", description: "Complete desk worker reset", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "1 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Eagle Arms", sets: 1, reps: "5 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "8 rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Downward Dog", sets: 1, reps: "8 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Low Lunge + Twist", sets: 1, reps: "5 breaths each", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Seated Forward Fold", sets: 1, reps: "10 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "8 breaths each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "3 min", restSeconds: 0)
            ])
        ]
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
        hotYogaPrep.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Heat Building Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Endurance Practice", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Flexibility Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Practice Simulation", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        hotYogaPrep.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Heat Building Flow", description: "Build internal heat", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation B", sets: 8, reps: "1 round", restSeconds: 0, notes: "Build heat quickly"),
                ProgramExerciseDefinition(exerciseName: "Chair Pose Hold", sets: 3, reps: "30 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Warrior Sequence", sets: 2, reps: "each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Balancing Poses", sets: 1, reps: "30 sec each", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Locust Pose", sets: 3, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Bow Pose", sets: 2, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Camel Pose", sets: 2, reps: "5 breaths", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Endurance Practice", description: "Build stamina for long holds", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Sun Salutation A", sets: 5, reps: "1 round", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Pose Holds", sets: 1, reps: "1 min each pose", restSeconds: 0, notes: "Warrior I, II, Triangle, Extended Side Angle"),
                ProgramExerciseDefinition(exerciseName: "Balance Challenge", sets: 1, reps: "30 sec each", restSeconds: 0, notes: "Tree, Eagle, Dancer, Warrior III"),
                ProgramExerciseDefinition(exerciseName: "Floor Series", sets: 1, reps: "as traditional", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Spine Strengthening", sets: 1, reps: "as traditional", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Flexibility Focus", description: "Deep stretching preparation", estimatedMinutes: 40, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Flow", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Head to Knee Prep", sets: 1, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Bow Prep", sets: 1, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Separate Leg Stretches", sets: 1, reps: "1 min each", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Floor Bow Pose", sets: 2, reps: "30 sec", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Fixed Firm Pose", sets: 1, reps: "1 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Spine Twist", sets: 1, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Full Practice Simulation", description: "Complete practice run", estimatedMinutes: 50, exercises: [
                ProgramExerciseDefinition(exerciseName: "Pranayama Breathing", sets: 1, reps: "1 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Half Moon Pose", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Awkward Pose Series", sets: 1, reps: "as traditional", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Eagle Pose", sets: 1, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Head to Knee", sets: 1, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Bow", sets: 1, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Balancing Stick", sets: 1, reps: "10 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Triangle Pose", sets: 1, reps: "30 sec each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Floor Series (Abbreviated)", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Final Savasana", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        corePilates.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Deep Core Activation", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Oblique Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Powerhouse Builder", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Core Integration", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        corePilates.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Deep Core Activation",
                description: "Target transverse abdominis and pelvic floor",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Breathing with Core Engagement", sets: 1, reps: "10 breaths", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 3, reps: "10 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Stretch", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Scissors", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Lower Lift", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Criss Cross", sets: 1, reps: "10 each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Oblique Focus",
                description: "Build rotational core strength",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Side Plank", sets: 2, reps: "30 sec each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Bicycle", sets: 1, reps: "20 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Criss Cross", sets: 2, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Spine Twist", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Side Bend", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Mermaid Stretch", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Russian Twist", sets: 2, reps: "15 each side", restSeconds: 30)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Powerhouse Builder",
                description: "Build overall core power",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Over", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Teaser Prep", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 3, reps: "45 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Leg Pull Front", sets: 1, reps: "5 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Leg Pull Back", sets: 1, reps: "5 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "30 counts", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Core Integration",
                description: "Full core workout combining all elements",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Circles", sets: 1, reps: "5 each direction each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Series of Five", sets: 1, reps: "10 each exercise", restSeconds: 0, notes: "Single, double, scissors, lower, criss cross"),
                    ProgramExerciseDefinition(exerciseName: "Spine Stretch Forward", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Open Leg Rocker", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Corkscrew", sets: 1, reps: "3 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Teaser", sets: 1, reps: "3 reps", restSeconds: 0)
                ]
            )
        ]
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
        reformer.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Footwork & Basics", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Arms & Core", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Reformer Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        reformer.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Footwork & Basics",
                description: "Learn reformer basics and footwork series",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Footwork - Toes", sets: 1, reps: "10 reps", restSeconds: 0, notes: "Medium springs"),
                    ProgramExerciseDefinition(exerciseName: "Footwork - Arches", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Footwork - Heels", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Footwork - Tendon Stretch", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hundred on Reformer", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Frog", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Leg Circles", sets: 1, reps: "5 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Stomach Massage - Round", sets: 1, reps: "10 reps", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Arms & Core",
                description: "Upper body and core on reformer",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 1, reps: "8 each direction", restSeconds: 0, notes: "Light springs"),
                    ProgramExerciseDefinition(exerciseName: "Chest Expansion", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Bicep Curls", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Rowing - From Chest", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Rowing - From Hips", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Short Box - Round Back", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Short Box - Flat Back", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Long Stretch", sets: 1, reps: "5 reps", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Reformer Flow",
                description: "Complete reformer session",
                estimatedMinutes: 50,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Footwork Series", sets: 1, reps: "8 each position", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Coordination", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Stomach Massage Series", sets: 1, reps: "8 each variation", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Short Spine", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Long Stretch Series", sets: 1, reps: "5 each", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Side Splits", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Running", sets: 1, reps: "20 counts", restSeconds: 0)
                ]
            )
        ]
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
        posturePilates.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Spine Alignment", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Upper Back Strength", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Core for Posture", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Posture Reset", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        posturePilates.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Spine Alignment",
                description: "Learn proper spinal alignment",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Wall Angels", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Chin Tucks", sets: 2, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Pelvic Tilts", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Spine Stretch Forward", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Down Against Wall", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Posture Check", sets: 1, reps: "1 min hold", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Upper Back Strength",
                description: "Strengthen upper back muscles",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Prone Arm Lifts", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Swan Prep", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "20 counts", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Dart", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Prone Y-T-W", sets: 2, reps: "8 each position", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Opener Stretch", sets: 1, reps: "60 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Core for Posture",
                description: "Core strength to support posture",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Breathing with Core Engagement", sets: 1, reps: "10 breaths", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 2, reps: "10 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Bird Dog", sets: 2, reps: "8 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Modified Plank", sets: 2, reps: "30 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Side Plank Modified", sets: 2, reps: "20 sec each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Glute Bridge", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "60 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Posture Reset",
                description: "Complete posture-focused session",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Wall Angels", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chin Tucks", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swan Prep", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "20 counts", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Stretch", sets: 1, reps: "60 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Posture Hold", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            )
        ]
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
        advancedMat.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Advanced Core Series", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Advanced Spine Work", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Ring Challenge", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Advanced Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        advancedMat.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Advanced Core Series",
                description: "Challenging core exercises",
                estimatedMinutes: 50,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0, notes: "Legs at 45 degrees"),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Over", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Teaser 1, 2, 3", sets: 1, reps: "3 each variation", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "5 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Corkscrew", sets: 1, reps: "5 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Scissors", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Bicycle", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Jack Knife", sets: 1, reps: "5 reps", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Advanced Spine Work",
                description: "Advanced spinal mobility and strength",
                estimatedMinutes: 50,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Spine Twist", sets: 1, reps: "6 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swan Dive", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Kick", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Rocking", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Pull", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Bridge", sets: 1, reps: "5 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Twist", sets: 1, reps: "3 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Boomerang", sets: 1, reps: "5 reps", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Ring Challenge",
                description: "Advanced work with Pilates ring",
                estimatedMinutes: 50,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Ring Squeezes - Inner Thigh", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Squeezes - Outer Thigh", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Hundred with Ring", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up with Ring", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Stretch with Ring", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch with Ring", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Press with Ring", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Arm Circles with Ring", sets: 2, reps: "10 each direction", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Advanced Flow",
                description: "Complete advanced mat sequence",
                estimatedMinutes: 55,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Over", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Circles", sets: 1, reps: "5 each direction each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Rolling Like a Ball", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Series of Five", sets: 1, reps: "10 each", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Spine Stretch Forward", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Open Leg Rocker", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Corkscrew", sets: 1, reps: "3 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Saw", sets: 1, reps: "4 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swan Dive", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Teaser", sets: 1, reps: "3 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seal", sets: 1, reps: "8 reps", restSeconds: 0)
                ]
            )
        ]
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
        runnersPilates.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Hip Stability", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Core for Runners", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Runner's Recovery", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        runnersPilates.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Hip Stability",
                description: "Build hip strength for better running",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Single Leg Circles", sets: 1, reps: "8 each direction each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Leg Series", sets: 1, reps: "10 each movement each side", restSeconds: 0, notes: "Lifts, circles, kicks"),
                    ProgramExerciseDefinition(exerciseName: "Clamshells with Band", sets: 2, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Bridge", sets: 2, reps: "10 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Fire Hydrants", sets: 2, reps: "12 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Standing Hip Circles", sets: 1, reps: "10 each direction each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "60 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Core for Runners",
                description: "Running-specific core work",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 2, reps: "10 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Bird Dog", sets: 2, reps: "10 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Scissors", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 2, reps: "45 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Side Plank with Leg Lift", sets: 2, reps: "30 sec each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "30 counts", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Mountain Climber Slow", sets: 2, reps: "10 each side", restSeconds: 30)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Runner's Recovery",
                description: "Active recovery and flexibility for runners",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip Flexor Stretch", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "IT Band Stretch", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Figure Four Stretch", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hamstring Stretch with Band", sets: 1, reps: "60 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Spine Twist", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Down", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Calf Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0)
                ]
            )
        ]
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
        prenatalPilates.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Gentle Core & Pelvic Floor", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Upper Body & Back Care", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Lower Body & Balance", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        prenatalPilates.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Gentle Core & Pelvic Floor",
                description: "Safe core work for pregnancy",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Breathing with Pelvic Floor", sets: 1, reps: "10 breaths", restSeconds: 0, notes: "Gentle engagement"),
                    ProgramExerciseDefinition(exerciseName: "Pelvic Tilts", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Cat-Cow on Ball", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Modified Bird Dog", sets: 2, reps: "8 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Leg Lifts", sets: 2, reps: "10 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Seated Spine Stretch", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Kegels", sets: 3, reps: "10 reps", restSeconds: 30)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Upper Body & Back Care",
                description: "Strengthen upper body and relieve back tension",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Seated Arm Circles", sets: 1, reps: "10 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Push-ups", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Seated Rowing Motion", sets: 2, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Rolls", sets: 1, reps: "10 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Opener on Ball", sets: 1, reps: "60 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "30 sec each direction", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Lower Body & Balance",
                description: "Strengthen legs and improve balance",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip Circles on Ball", sets: 1, reps: "10 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wide Stance Squats", sets: 2, reps: "10 reps", restSeconds: 30, notes: "Hold onto wall or chair"),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Leg Series", sets: 1, reps: "10 each movement each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Balance with Support", sets: 2, reps: "30 sec each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Calf Raises with Support", sets: 2, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Seated Figure Four Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supported Deep Squat", sets: 1, reps: "60 sec hold", restSeconds: 0, notes: "Hold onto stable surface")
                ]
            )
        ]
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
        pilatesSculpt.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Sculpt Arms & Core", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Sculpt Legs & Glutes", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Full Body Sculpt", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Sculpt & Tone", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        pilatesSculpt.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Sculpt Arms & Core",
                description: "Tone arms and strengthen core",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Arm Circles with Weights", sets: 2, reps: "15 each direction", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Bicep Curls", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Tricep Kickbacks", sets: 3, reps: "12 each arm", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Chest Fly", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Criss Cross", sets: 2, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Plank with Arm Reach", sets: 2, reps: "10 each arm", restSeconds: 30)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Sculpt Legs & Glutes",
                description: "Tone and lift lower body",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Plie Squats with Weights", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Leg Series", sets: 1, reps: "15 each movement each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Bridge", sets: 3, reps: "12 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Clam Shells", sets: 3, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Donkey Kicks", sets: 3, reps: "15 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Fire Hydrants", sets: 3, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Inner Thigh Lifts", sets: 2, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Standing Leg Pulses", sets: 2, reps: "20 each leg", restSeconds: 30)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Body Sculpt",
                description: "Total body toning session",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred with Weights", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Press", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Plie Squats", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Row with Weights", sets: 3, reps: "12 each arm", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Stretch", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Side Plank with Dip", sets: 2, reps: "10 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "30 counts", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Sculpt & Tone",
                description: "High rep toning focus",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Arm Pulses", sets: 3, reps: "30 sec", restSeconds: 20),
                    ProgramExerciseDefinition(exerciseName: "Small Arm Circles", sets: 3, reps: "30 sec each direction", restSeconds: 20),
                    ProgramExerciseDefinition(exerciseName: "Toe Taps", sets: 2, reps: "20 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Bicycle", sets: 2, reps: "20 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Leg Pulse Series", sets: 1, reps: "20 each position each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Glute Bridge Pulses", sets: 3, reps: "30 pulses", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 2, reps: "45 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Full Body Stretch", sets: 1, reps: "3 min", restSeconds: 0)
                ]
            )
        ]
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
        wallPilates.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Wall Core Basics", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Wall Lower Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Wall Upper Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Wall Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        wallPilates.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Wall Core Basics",
                description: "Core work using wall support",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Wall Roll Down", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Sit with Core Hold", sets: 3, reps: "30 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Plank", sets: 2, reps: "30 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Push-up", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Legs Up Wall Crunch", sets: 2, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Bridge", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Stretch", sets: 1, reps: "60 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Wall Lower Body",
                description: "Leg work with wall support",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Wall Sit", sets: 3, reps: "45 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Squat Pulses", sets: 3, reps: "20 pulses", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Wall Sit", sets: 2, reps: "20 sec each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Side Leg Lifts", sets: 2, reps: "15 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Calf Raises", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Legs Up Wall - Straddle", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Hip Flexor Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Wall Upper Body",
                description: "Upper body using wall for support",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Wall Angels", sets: 2, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Push-ups", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Tricep Press", sets: 2, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Plank Hold", sets: 3, reps: "30 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Shoulder Stretch", sets: 1, reps: "45 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Chest Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Lat Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Wall Flow",
                description: "Complete wall Pilates session",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Wall Roll Down", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Angels", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Push-ups", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Sit", sets: 2, reps: "45 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Plank", sets: 2, reps: "30 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Wall Side Leg Lifts", sets: 1, reps: "12 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Bridge", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Legs Up Wall - Straddle", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Stretches", sets: 1, reps: "3 min", restSeconds: 0)
                ]
            )
        ]
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
        classicalPilates.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Classical Beginner Sequence", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Classical Intermediate A", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Classical Intermediate B", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Classical Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        classicalPilates.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Classical Beginner Sequence",
                description: "Foundation of the classical mat work",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Circles", sets: 1, reps: "5 each direction each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Rolling Like a Ball", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Stretch", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Spine Stretch Forward", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swan", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Kick", sets: 1, reps: "10 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Side Kicks", sets: 1, reps: "8 each movement each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seal", sets: 1, reps: "8 reps", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Classical Intermediate A",
                description: "First half of intermediate sequence",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Over", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Circles", sets: 1, reps: "5 each direction each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Rolling Like a Ball", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Series of Five", sets: 1, reps: "10 each", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Spine Stretch Forward", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Open Leg Rocker", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Corkscrew", sets: 1, reps: "3 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Saw", sets: 1, reps: "4 each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Classical Intermediate B",
                description: "Second half of intermediate sequence",
                estimatedMinutes: 45,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Swan Dive", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Kick", sets: 1, reps: "10 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Kick", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Pull", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Scissors", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Bicycle", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Bridge", sets: 1, reps: "5 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Spine Twist", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Side Kick Series", sets: 1, reps: "8 each movement each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Teaser", sets: 1, reps: "3 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "30 counts", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seal", sets: 1, reps: "8 reps", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Classical Flow",
                description: "Complete classical mat sequence",
                estimatedMinutes: 50,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "The Hundred", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Over", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Circles", sets: 1, reps: "5 each direction each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Rolling Like a Ball", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Series of Five", sets: 1, reps: "10 each", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Spine Stretch Forward", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Open Leg Rocker", sets: 1, reps: "6 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Corkscrew", sets: 1, reps: "3 each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Saw", sets: 1, reps: "4 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swan Dive", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Pull", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Bridge", sets: 1, reps: "5 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Side Kick Series", sets: 1, reps: "6 each movement each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Teaser", sets: 1, reps: "3 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Swimming", sets: 1, reps: "30 counts", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seal", sets: 1, reps: "8 reps", restSeconds: 0)
                ]
            )
        ]
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
        ringPilates.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Ring Upper Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Ring Lower Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Ring Full Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        ringPilates.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Ring Upper Body",
                description: "Arms, chest, and back with ring",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Ring Chest Press", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Overhead Press", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Bicep Curls", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Tricep Press Behind", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Lat Pull", sets: 2, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Hundred with Ring", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up with Ring", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Arm Circles with Ring", sets: 2, reps: "10 each direction", restSeconds: 30)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Ring Lower Body",
                description: "Inner and outer thighs with ring",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Ring Inner Thigh Squeeze - Supine", sets: 3, reps: "20 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Inner Thigh Squeeze - Seated", sets: 3, reps: "20 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Outer Thigh Press", sets: 3, reps: "15 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Bridge with Ring", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Ring Press", sets: 2, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Scissors with Ring", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Stretch with Ring", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Leg Circles with Ring on Ankle", sets: 1, reps: "5 each direction each leg", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Ring Full Body",
                description: "Complete ring workout",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hundred with Ring on Ankles", sets: 1, reps: "100 pulses", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Roll Up with Ring", sets: 1, reps: "8 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Ring Chest Press", sets: 2, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Inner Thigh", sets: 2, reps: "20 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Single Leg Stretch with Ring", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Double Leg Stretch with Ring", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Bridge with Ring", sets: 2, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Ring Overhead Press", sets: 2, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Ring Series", sets: 1, reps: "10 each movement each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Teaser with Ring", sets: 1, reps: "5 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Stretches", sets: 1, reps: "3 min", restSeconds: 0)
                ]
            )
        ]
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
        hiitStarter.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Intro Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Cardio Bursts", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Body Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        hiitStarter.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Intro Intervals", description: "Learn the HIIT format with manageable intervals", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup March", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jumping Jacks", sets: 4, reps: "20 sec work / 40 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Bodyweight Squats", sets: 4, reps: "20 sec work / 40 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Modified Push-ups", sets: 4, reps: "20 sec work / 40 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down Walk", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Cardio Bursts", description: "Short cardio intervals", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "High Knees", sets: 4, reps: "15 sec work / 45 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Butt Kicks", sets: 4, reps: "15 sec work / 45 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Step Jacks", sets: 4, reps: "20 sec work / 40 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Full Body Intervals", description: "Hit all muscle groups", estimatedMinutes: 20, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Squat to Reach", sets: 3, reps: "20 sec work / 40 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Push-up to Plank", sets: 3, reps: "20 sec work / 40 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Reverse Lunges", sets: 3, reps: "20 sec work / 40 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 3, reps: "15 sec work / 45 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "3 min", restSeconds: 0)
            ])
        ]
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
        emom.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "EMOM 20", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "EMOM Strength", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "EMOM Cardio", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "EMOM Challenge", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        emom.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "EMOM 20", description: "20 minute EMOM alternating movements", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Odd Minutes: Kettlebell Swings", sets: 10, reps: "15 reps", restSeconds: 0, notes: "Complete at start of minute, rest remaining time"),
                ProgramExerciseDefinition(exerciseName: "Even Minutes: Burpees", sets: 10, reps: "8 reps", restSeconds: 0, notes: "Complete at start of minute, rest remaining time"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "EMOM Strength", description: "Strength-focused EMOM", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 1: Goblet Squats", sets: 1, reps: "12 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 2: Push-ups", sets: 1, reps: "15 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 3: KB Deadlifts", sets: 1, reps: "12 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 4: Pull-ups or Rows", sets: 1, reps: "8 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Repeat 4 rounds (16 min)", sets: 1, reps: "total", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "EMOM Cardio", description: "Cardio conditioning EMOM", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 1: High Knees", sets: 1, reps: "30 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 2: Mountain Climbers", sets: 1, reps: "20 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 3: Jump Squats", sets: 1, reps: "12 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Repeat 5 rounds (15 min)", sets: 1, reps: "total", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "EMOM Challenge", description: "Extended challenging EMOM", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 1: KB Swings", sets: 1, reps: "20 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 2: Burpees", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 3: Pull-ups", sets: 1, reps: "max reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 4: Box Jumps or Step-ups", sets: 1, reps: "15 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Min 5: Rest", sets: 1, reps: "active recovery", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Repeat 4 rounds (20 min)", sets: 1, reps: "total", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        bodyweightHIIT.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Lower Body Burn", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Upper Body Blast", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Core Crusher", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Total Body Shred", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        bodyweightHIIT.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Lower Body Burn", description: "Legs and glutes on fire", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jump Squats", sets: 4, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Alternating Lunges", sets: 4, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Sumo Squat Pulses", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Glute Bridges", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Wall Sit", sets: 2, reps: "30 sec hold", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Upper Body Blast", description: "Arms, chest, and shoulders", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Push-up Variations", sets: 4, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Tricep Dips", sets: 4, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Plank Shoulder Taps", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Diamond Push-ups", sets: 3, reps: "20 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 2, reps: "30 sec each direction", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Core Crusher", description: "Abs and obliques workout", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 4, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Bicycle Crunches", sets: 4, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 3, reps: "30 sec hold / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Russian Twists", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Leg Raises", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Total Body Shred", description: "Hit everything", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Burpees", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jump Lunges", sets: 3, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Squat Jumps", sets: 3, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Plank Jacks", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        kbHIIT.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "KB Swing Intervals", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "KB Complex", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "KB Circuit", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        kbHIIT.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "KB Swing Intervals", description: "Swing focused HIIT", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "KB Swings", sets: 10, reps: "30 sec work / 30 sec rest", restSeconds: 0, notes: "Explosive hip hinge"),
                ProgramExerciseDefinition(exerciseName: "Goblet Squats", sets: 5, reps: "30 sec work / 30 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "KB Complex", description: "Flow through movements", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "KB Complex (Swing→Clean→Press→Squat)", sets: 5, reps: "5 reps each move, each side", restSeconds: 60, notes: "Don't put KB down during complex"),
                ProgramExerciseDefinition(exerciseName: "KB Snatches", sets: 4, reps: "8 each side", restSeconds: 45),
                ProgramExerciseDefinition(exerciseName: "Turkish Get-up", sets: 2, reps: "2 each side", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "KB Circuit", description: "Full body KB circuit", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "KB Swings", sets: 1, reps: "20 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Goblet Squats", sets: 1, reps: "15 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "KB Clean & Press", sets: 1, reps: "10 each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "KB Rows", sets: 1, reps: "12 each side", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "KB Deadlifts", sets: 1, reps: "15 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Repeat 4 rounds", sets: 1, reps: "circuit", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        sprints.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Short Sprints", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Hill Sprints", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Longer Sprints", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        sprints.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Short Sprints", description: "Explosive short bursts", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Dynamic Warmup", sets: 1, reps: "10 min", restSeconds: 0, notes: "Jog, high knees, butt kicks, leg swings"),
                ProgramExerciseDefinition(exerciseName: "30m Sprints", sets: 8, reps: "100% effort", restSeconds: 60, notes: "Walk back recovery"),
                ProgramExerciseDefinition(exerciseName: "60m Sprints", sets: 4, reps: "100% effort", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Cool Down Jog", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Hill Sprints", description: "Sprint uphill for power", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup Jog", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Hill Sprints", sets: 10, reps: "10-15 sec sprint up", restSeconds: 0, notes: "Walk down recovery (about 60 sec)"),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Longer Sprints", description: "Extended sprint efforts", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "10 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "200m Sprints", sets: 6, reps: "90-95% effort", restSeconds: 120, notes: "Strong pace, not quite all-out"),
                ProgramExerciseDefinition(exerciseName: "100m Sprint", sets: 2, reps: "100% effort", restSeconds: 90, notes: "Finish strong"),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        boxingHIIT.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Punch Combos", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Boxing Cardio", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Power Punches", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Boxing Circuit", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        boxingHIIT.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Punch Combos", description: "Learn and drill punch combinations", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Jump Rope (or Shadow)", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jab-Cross", sets: 6, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jab-Cross-Hook", sets: 6, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Jab-Cross-Hook-Uppercut", sets: 4, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Defensive Slips", sets: 3, reps: "30 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Boxing Cardio", description: "Cardio conditioning with boxing", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Shadow Boxing", sets: 3, reps: "3 min rounds", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "High Knees", sets: 2, reps: "30 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Burpees", sets: 2, reps: "30 sec", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Shadow Boxing", sets: 2, reps: "3 min rounds", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Power Punches", description: "Focus on power shots", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Power Cross", sets: 5, reps: "10 hard punches each side", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Power Hooks", sets: 5, reps: "10 hard punches each side", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Uppercuts", sets: 5, reps: "10 hard punches each side", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Combo Finisher", sets: 3, reps: "2 min rounds", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Boxing Circuit", description: "Full boxing workout", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Jump Rope", sets: 1, reps: "3 min", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Shadow Boxing", sets: 1, reps: "3 min", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 1, reps: "20 reps", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Jab-Cross Combos", sets: 1, reps: "2 min", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 1, reps: "30 sec", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Hook-Uppercut Combos", sets: 1, reps: "2 min", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Burpees", sets: 1, reps: "10 reps", restSeconds: 30),
                ProgramExerciseDefinition(exerciseName: "Repeat circuit 2x", sets: 1, reps: "total", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        amrap.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "AMRAP 12", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "AMRAP 15", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "AMRAP 10", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "AMRAP 20", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        amrap.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "AMRAP 12", description: "12 minute AMRAP", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "12 min AMRAP:", sets: 1, reps: "max rounds", restSeconds: 0, notes: "Complete as many rounds as possible"),
                ProgramExerciseDefinition(exerciseName: "- Air Squats", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Push-ups", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Sit-ups", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "AMRAP 15", description: "15 minute AMRAP", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "15 min AMRAP:", sets: 1, reps: "max rounds", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Burpees", sets: 1, reps: "5 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Box Jumps/Step-ups", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- KB Swings", sets: 1, reps: "15 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "AMRAP 10", description: "Fast-paced 10 minute AMRAP", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "10 min AMRAP:", sets: 1, reps: "max rounds", restSeconds: 0, notes: "Move fast!"),
                ProgramExerciseDefinition(exerciseName: "- Mountain Climbers", sets: 1, reps: "20 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Jumping Lunges", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Plank Hold", sets: 1, reps: "20 sec", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "AMRAP 20", description: "Extended 20 minute AMRAP", estimatedMinutes: 35, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "20 min AMRAP:", sets: 1, reps: "max rounds", restSeconds: 0, notes: "Pace yourself"),
                ProgramExerciseDefinition(exerciseName: "- Goblet Squats", sets: 1, reps: "12 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Push-ups", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Rows", sets: 1, reps: "10 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Jumping Jacks", sets: 1, reps: "20 reps", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        lowImpactHIIT.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Standing HIIT", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Floor HIIT", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Mixed Low Impact", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Low Impact Circuit", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        lowImpactHIIT.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Standing HIIT", description: "No jumping standing exercises", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup March", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Speed Squats (no jump)", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Alternating Lunges", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Knee Drives", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Speed Skaters (no jump)", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Floor HIIT", description: "Mat-based low impact", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Mountain Climbers (slow)", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Plank to Downward Dog", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Glute Bridges", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Dead Bugs", sets: 4, reps: "30 sec work / 20 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Mixed Low Impact", description: "Standing and floor combo", estimatedMinutes: 25, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "3 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Squat to Calf Raise", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Reverse Lunges", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Bird Dogs", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Standing Side Crunches", sets: 3, reps: "30 sec work / 15 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Full Low Impact Circuit", description: "Complete low impact workout", estimatedMinutes: 30, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Marching High Knees", sets: 1, reps: "45 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Squats", sets: 1, reps: "45 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 1, reps: "45 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Lunges", sets: 1, reps: "45 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Plank", sets: 1, reps: "45 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Glute Bridges", sets: 1, reps: "45 sec", restSeconds: 15),
                ProgramExerciseDefinition(exerciseName: "Repeat 3 rounds", sets: 1, reps: "circuit", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Cool Down & Stretch", sets: 1, reps: "5 min", restSeconds: 0)
            ])
        ]
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
        hiitLift.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Upper + HIIT", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Lower + HIIT", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Push + HIIT", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Pull + HIIT", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        hiitLift.workoutDefinitions = [
            ProgramWorkoutDefinition(name: "Upper + HIIT", description: "Upper body strength + HIIT finisher", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Bench Press", sets: 4, reps: "8-10 reps", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Bent Over Rows", sets: 4, reps: "8-10 reps", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Shoulder Press", sets: 3, reps: "10 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Face Pulls", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "HIIT Finisher: 8 min", sets: 1, reps: "total", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Burpees", sets: 4, reps: "30 sec work / 30 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Mountain Climbers", sets: 4, reps: "30 sec work / 30 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Lower + HIIT", description: "Lower body strength + HIIT finisher", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Squats", sets: 4, reps: "8-10 reps", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Romanian Deadlifts", sets: 4, reps: "10 reps", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Leg Press", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Leg Curls", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "HIIT Finisher: 8 min", sets: 1, reps: "total", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Jump Squats (or fast squats)", sets: 4, reps: "30 sec work / 30 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Walking Lunges", sets: 4, reps: "30 sec work / 30 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Push + HIIT", description: "Push muscles + conditioning", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Incline Dumbbell Press", sets: 4, reps: "10 reps", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Flyes", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Lateral Raises", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Tricep Dips", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "HIIT Finisher: 10 min EMOM", sets: 1, reps: "total", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "- Push-ups", sets: 10, reps: "10 reps each minute", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ]),
            ProgramWorkoutDefinition(name: "Pull + HIIT", description: "Pull muscles + conditioning", estimatedMinutes: 45, exercises: [
                ProgramExerciseDefinition(exerciseName: "Warmup", sets: 1, reps: "5 min", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Pull-ups or Lat Pulldown", sets: 4, reps: "8-10 reps", restSeconds: 90),
                ProgramExerciseDefinition(exerciseName: "Cable Rows", sets: 4, reps: "10 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Dumbbell Curls", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "Hammer Curls", sets: 3, reps: "12 reps", restSeconds: 60),
                ProgramExerciseDefinition(exerciseName: "HIIT Finisher: KB Swings", sets: 5, reps: "30 sec work / 30 sec rest", restSeconds: 0),
                ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "3 min", restSeconds: 0)
            ])
        ]
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
        hiitChallenge.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Cardio Blast", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Core Crusher", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Lower Body Burn", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Upper Body Blitz", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Body Fury", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Active Recovery HIIT", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        hiitChallenge.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Cardio Blast",
                description: "Heart-pumping cardio intervals to torch calories",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up: Jumping Jacks", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "High Knees", sets: 4, reps: "30 sec work", restSeconds: 15, notes: "Drive knees to hip height"),
                    ProgramExerciseDefinition(exerciseName: "Burpees", sets: 4, reps: "30 sec work", restSeconds: 15, notes: "Full chest to ground"),
                    ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 4, reps: "30 sec work", restSeconds: 15, notes: "Fast pace"),
                    ProgramExerciseDefinition(exerciseName: "Squat Jumps", sets: 4, reps: "30 sec work", restSeconds: 15, notes: "Explosive"),
                    ProgramExerciseDefinition(exerciseName: "Plank Jacks", sets: 3, reps: "30 sec work", restSeconds: 15),
                    ProgramExerciseDefinition(exerciseName: "Tuck Jumps", sets: 3, reps: "20 sec work", restSeconds: 20, notes: "Bring knees to chest"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Core Crusher",
                description: "Intense core-focused HIIT workout",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up: Torso Twists", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 3, reps: "45 sec", restSeconds: 15, notes: "Tight core"),
                    ProgramExerciseDefinition(exerciseName: "Bicycle Crunches", sets: 4, reps: "30 sec", restSeconds: 10, notes: "Slow and controlled"),
                    ProgramExerciseDefinition(exerciseName: "Russian Twists", sets: 4, reps: "30 sec", restSeconds: 10, notes: "Feet elevated"),
                    ProgramExerciseDefinition(exerciseName: "Leg Raises", sets: 4, reps: "30 sec", restSeconds: 10, notes: "Lower slowly"),
                    ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 3, reps: "30 sec", restSeconds: 10, notes: "Opposite arm and leg"),
                    ProgramExerciseDefinition(exerciseName: "Flutter Kicks", sets: 3, reps: "30 sec", restSeconds: 10, notes: "Low back pressed down"),
                    ProgramExerciseDefinition(exerciseName: "Mountain Climbers", sets: 3, reps: "30 sec", restSeconds: 15),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Stretch", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Lower Body Burn",
                description: "Leg-focused HIIT to build strength and endurance",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up: Leg Swings", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Jump Squats", sets: 4, reps: "30 sec work", restSeconds: 15, notes: "Deep squat, explosive jump"),
                    ProgramExerciseDefinition(exerciseName: "Alternating Lunges", sets: 4, reps: "30 sec work", restSeconds: 15, notes: "Knee to ground"),
                    ProgramExerciseDefinition(exerciseName: "Sumo Squat Pulses", sets: 3, reps: "30 sec work", restSeconds: 15, notes: "Stay low"),
                    ProgramExerciseDefinition(exerciseName: "Jump Lunges", sets: 4, reps: "30 sec work", restSeconds: 20, notes: "Switch in air"),
                    ProgramExerciseDefinition(exerciseName: "Wall Sit", sets: 3, reps: "45 sec", restSeconds: 15, notes: "Thighs parallel"),
                    ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 3, reps: "30 sec fast", restSeconds: 10),
                    ProgramExerciseDefinition(exerciseName: "Glute Bridges", sets: 3, reps: "30 sec", restSeconds: 10, notes: "Squeeze at top"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Stretch", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Upper Body Blitz",
                description: "Push and pull HIIT for upper body conditioning",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up: Arm Circles", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 4, reps: "30 sec", restSeconds: 15, notes: "Chest to ground"),
                    ProgramExerciseDefinition(exerciseName: "Diamond Push-ups", sets: 3, reps: "20 sec", restSeconds: 15, notes: "Tricep focus"),
                    ProgramExerciseDefinition(exerciseName: "Plank Shoulder Taps", sets: 4, reps: "30 sec", restSeconds: 15, notes: "Minimize hip sway"),
                    ProgramExerciseDefinition(exerciseName: "Pike Push-ups", sets: 3, reps: "30 sec", restSeconds: 20, notes: "Shoulder focus"),
                    ProgramExerciseDefinition(exerciseName: "Tricep Dips", sets: 4, reps: "30 sec", restSeconds: 15, notes: "Use chair or bench"),
                    ProgramExerciseDefinition(exerciseName: "Plank to Push-up", sets: 3, reps: "30 sec", restSeconds: 15, notes: "Alternate leading arm"),
                    ProgramExerciseDefinition(exerciseName: "Arm Pulses", sets: 2, reps: "30 sec", restSeconds: 10, notes: "Arms extended"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Stretch", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Body Fury",
                description: "Total body HIIT for maximum calorie burn",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up: Light Jog in Place", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Burpees", sets: 4, reps: "30 sec", restSeconds: 15, notes: "Full range"),
                    ProgramExerciseDefinition(exerciseName: "Jump Squats", sets: 3, reps: "30 sec", restSeconds: 15),
                    ProgramExerciseDefinition(exerciseName: "Push-ups", sets: 3, reps: "30 sec", restSeconds: 15),
                    ProgramExerciseDefinition(exerciseName: "High Knees", sets: 3, reps: "30 sec", restSeconds: 15),
                    ProgramExerciseDefinition(exerciseName: "Plank Hold", sets: 2, reps: "45 sec", restSeconds: 15),
                    ProgramExerciseDefinition(exerciseName: "Skaters", sets: 3, reps: "30 sec", restSeconds: 15, notes: "Side to side"),
                    ProgramExerciseDefinition(exerciseName: "Commandos", sets: 3, reps: "30 sec", restSeconds: 15, notes: "Plank to push-up"),
                    ProgramExerciseDefinition(exerciseName: "Sprawls", sets: 3, reps: "30 sec", restSeconds: 15, notes: "Drop and pop up"),
                    ProgramExerciseDefinition(exerciseName: "Cool Down", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Active Recovery HIIT",
                description: "Lower intensity intervals to promote recovery while staying active",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Light Jog in Place", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Marching in Place", sets: 3, reps: "1 min", restSeconds: 30, notes: "Moderate pace"),
                    ProgramExerciseDefinition(exerciseName: "Bodyweight Squats", sets: 3, reps: "15 reps", restSeconds: 30, notes: "Controlled tempo"),
                    ProgramExerciseDefinition(exerciseName: "Step Touches", sets: 3, reps: "1 min", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Standing Knee Hugs", sets: 2, reps: "1 min", restSeconds: 30, notes: "Alternate legs"),
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 2, reps: "1 min", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Gentle Lunges", sets: 2, reps: "10 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Standing Side Bends", sets: 2, reps: "1 min", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Full Body Stretch", sets: 1, reps: "3 min", restSeconds: 0)
                ]
            )
        ]
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
        dailyStretch.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Full Body Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Lower Body Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Upper Body Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Full Body Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Hip & Back Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Active Recovery", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: "Restorative Stretch", isRest: false)
        ]
        dailyStretch.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Full Body Stretch",
                description: "Quick full body routine for daily maintenance",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Neck Circles", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Rolls", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow Stretch", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Side Bend", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Quad Stretch", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Opener", sets: 1, reps: "45 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Deep Breathing", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Lower Body Focus",
                description: "Target legs and hips",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Ankle Circles", sets: 1, reps: "30 sec each", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Calf Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Quad Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Hamstring Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Figure Four Stretch", sets: 1, reps: "1 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Butterfly Stretch", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Upper Body Focus",
                description: "Target shoulders, arms, and chest",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Stretch", sets: 1, reps: "30 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Tricep Stretch", sets: 1, reps: "30 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Doorway Stretch", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Upper Back Stretch", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wrist Stretches", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "45 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Hip & Back Focus",
                description: "Target tight hips and lower back",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "1 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "1 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Knees to Chest", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Active Recovery",
                description: "Gentle movement with stretching",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Walking in Place", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Leg Swings", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Gentle Lunges", sets: 1, reps: "1 min alternating", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Side Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Ragdoll Forward Fold", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Restorative Stretch",
                description: "Deep relaxation and gentle stretching",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Deep Breathing", sets: 1, reps: "2 min", restSeconds: 0, notes: "Belly breathing"),
                    ProgramExerciseDefinition(exerciseName: "Supported Child's Pose", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Butterfly", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "1 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Legs Up the Wall", sets: 1, reps: "3 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            )
        ]
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
        splits.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Front Split Left", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Front Split Right", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Middle Split", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Hip Prep", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Splits Practice", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        splits.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Front Split Left",
                description: "Focus on left leg front split",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up Hip Circles", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge Left Leg Forward", sets: 1, reps: "90 sec", restSeconds: 0, notes: "Sink hips down"),
                    ProgramExerciseDefinition(exerciseName: "Half Split Left", sets: 1, reps: "2 min", restSeconds: 0, notes: "Straighten front leg"),
                    ProgramExerciseDefinition(exerciseName: "Lizard Pose Left", sets: 1, reps: "90 sec", restSeconds: 0, notes: "Hands inside front foot"),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose Left", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Hamstring Stretch Left", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Front Split Left with Blocks", sets: 3, reps: "60 sec", restSeconds: 30, notes: "Use blocks for support")
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Front Split Right",
                description: "Focus on right leg front split",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up Hip Circles", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge Right Leg Forward", sets: 1, reps: "90 sec", restSeconds: 0, notes: "Sink hips down"),
                    ProgramExerciseDefinition(exerciseName: "Half Split Right", sets: 1, reps: "2 min", restSeconds: 0, notes: "Straighten front leg"),
                    ProgramExerciseDefinition(exerciseName: "Lizard Pose Right", sets: 1, reps: "90 sec", restSeconds: 0, notes: "Hands inside front foot"),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose Right", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Hamstring Stretch Right", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Front Split Right with Blocks", sets: 3, reps: "60 sec", restSeconds: 30, notes: "Use blocks for support")
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Middle Split",
                description: "Focus on middle split (straddle)",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Warm Up Frog Rocks", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Frog Pose", sets: 1, reps: "2 min", restSeconds: 0, notes: "Knees wide, chest down"),
                    ProgramExerciseDefinition(exerciseName: "Seated Straddle", sets: 1, reps: "2 min", restSeconds: 0, notes: "Fold forward"),
                    ProgramExerciseDefinition(exerciseName: "Standing Straddle", sets: 1, reps: "90 sec", restSeconds: 0, notes: "Hands on floor"),
                    ProgramExerciseDefinition(exerciseName: "Wall Straddle", sets: 1, reps: "3 min", restSeconds: 0, notes: "Legs up wall, let gravity help"),
                    ProgramExerciseDefinition(exerciseName: "Middle Split with Blocks", sets: 3, reps: "60 sec", restSeconds: 30, notes: "Hands on blocks")
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Hip Prep",
                description: "Deep hip opening to support splits progress",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "90-90 Stretch Left", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "90-90 Stretch Right", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Butterfly Stretch", sets: 1, reps: "2 min", restSeconds: 0, notes: "Press knees down"),
                    ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Figure Four Each Side", sets: 1, reps: "90 sec each", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Deep Squat Hold", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Splits Practice",
                description: "Practice all splits with active stretching",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Dynamic Leg Swings", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Active Low Lunge Left", sets: 1, reps: "60 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Active Low Lunge Right", sets: 1, reps: "60 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Front Split Left", sets: 2, reps: "90 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Front Split Right", sets: 2, reps: "90 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Middle Split", sets: 2, reps: "90 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Cool Down Child's Pose", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            )
        ]
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
        hipOpener.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Hip Flexor Focus", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "External Rotation", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Internal Rotation", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Complete Hip Circuit", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        hipOpener.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Hip Flexor Focus",
                description: "Target tight hip flexors from sitting",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "1 min each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "90 sec each side", restSeconds: 0, notes: "Push hips forward"),
                    ProgramExerciseDefinition(exerciseName: "Half Kneeling Hip Flexor Stretch", sets: 1, reps: "90 sec each side", restSeconds: 0, notes: "Squeeze glute"),
                    ProgramExerciseDefinition(exerciseName: "Couch Stretch", sets: 1, reps: "60 sec each side", restSeconds: 0, notes: "Foot against wall"),
                    ProgramExerciseDefinition(exerciseName: "Standing Hip Flexor Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "External Rotation",
                description: "Improve hip external rotation",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "2 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "90-90 Stretch", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Figure Four", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated External Rotation", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Fire Hydrant Circles", sets: 1, reps: "10 each direction each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Internal Rotation",
                description: "Improve hip internal rotation",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Frog Pose", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Internal Rotation", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Half Frog Stretch", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Prone Internal Rotation", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Knee Drop", sets: 1, reps: "60 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Complete Hip Circuit",
                description: "Full hip mobility routine",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip CARs", sets: 1, reps: "5 each direction each side", restSeconds: 0, notes: "Controlled Articular Rotations"),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Frog Pose", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "90-90 Switch", sets: 1, reps: "10 transitions", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Deep Squat Hold", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "90 sec", restSeconds: 0)
                ]
            )
        ]
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
        upperMobility.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Shoulder Mobility", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Thoracic Spine", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Chest & Lats", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Complete Upper Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        upperMobility.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Shoulder Mobility",
                description: "Improve shoulder range of motion",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 1, reps: "1 min each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder CARs", sets: 1, reps: "5 each direction each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Slides", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Cross Body Shoulder Stretch", sets: 1, reps: "60 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Sleeper Stretch", sets: 1, reps: "60 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Doorway Stretch", sets: 1, reps: "60 sec each arm position", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Arm Overhead Stretch", sets: 1, reps: "45 sec each arm", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Thoracic Spine",
                description: "Improve upper back mobility",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Foam Roll Thoracic Spine", sets: 1, reps: "2 min", restSeconds: 0, notes: "Roll upper/mid back"),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Open Book Stretch", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thoracic Extension Over Roller", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Quadruped Rotation", sets: 1, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose Reach", sets: 1, reps: "60 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Chest & Lats",
                description: "Open up chest and lengthen lats",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Foam Roll Lats", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Foam Roll Chest", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Doorway Chest Stretch", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Floor Angels", sets: 2, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Lat Stretch on Wall", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose Lat Bias", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Prone Y Raises", sets: 2, reps: "10 reps", restSeconds: 30)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Complete Upper Body",
                description: "Full upper body mobility routine",
                estimatedMinutes: 25,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Foam Roll Full Upper Back", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder CARs", sets: 1, reps: "3 each direction each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wall Slides", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Doorway Chest Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Lat Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "30 sec each direction", restSeconds: 0)
                ]
            )
        ]
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
        postWorkout.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Upper Body Cool Down", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Lower Body Cool Down", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Full Body Cool Down", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Cardio Cool Down", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Active Recovery Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        postWorkout.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Upper Body Cool Down",
                description: "Stretch after upper body training",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Shoulder Rolls", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cross Body Shoulder Stretch", sets: 1, reps: "45 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Tricep Stretch", sets: 1, reps: "45 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Doorway Stretch", sets: 1, reps: "60 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Lat Stretch", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Upper Back Stretch", sets: 1, reps: "60 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "45 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Lower Body Cool Down",
                description: "Stretch after leg training",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Quad Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hamstring Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip Flexor Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Glute Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Calf Stretch", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "IT Band Stretch", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Body Cool Down",
                description: "Complete cool down after full body workout",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Opener", sets: 1, reps: "45 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Deep Breathing", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Cardio Cool Down",
                description: "Stretch after running or cardio",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Walking Cool Down", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Quad Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Calf Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip Flexor Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hamstring Stretch", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "IT Band Stretch", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Deep Breathing", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Active Recovery Stretch",
                description: "Light movement and stretching for recovery days",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Gentle Walking", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "3 min", restSeconds: 0)
                ]
            )
        ]
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
        activeFlexibility.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Active Lower Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Active Upper Body", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Active Hips & Core", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Active Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        activeFlexibility.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Active Lower Body",
                description: "Combine active movement with deep stretches",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Leg Swings", sets: 1, reps: "20 each leg each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Active Straight Leg Raises", sets: 3, reps: "10 each leg", restSeconds: 30, notes: "Controlled movement"),
                    ProgramExerciseDefinition(exerciseName: "Banded Hip Flexor March", sets: 3, reps: "10 each leg", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Deep Squat Hold", sets: 3, reps: "45 sec", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Active Low Lunge", sets: 2, reps: "45 sec each side", restSeconds: 15),
                    ProgramExerciseDefinition(exerciseName: "Banded Glute Bridges", sets: 3, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "90 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Active Upper Body",
                description: "Dynamic shoulder and spine mobility",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 1, reps: "1 min each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Banded Pull Aparts", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Banded Shoulder Dislocates", sets: 3, reps: "10 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Active Hang", sets: 3, reps: "20 sec", restSeconds: 30, notes: "From bar or rings"),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow Flow", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle Active", sets: 2, reps: "10 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Stretch", sets: 1, reps: "60 sec each side", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Active Hips & Core",
                description: "Core strength combined with hip mobility",
                estimatedMinutes: 30,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip CARs", sets: 1, reps: "5 each direction each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Dead Bug", sets: 3, reps: "10 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Active Frog Rocks", sets: 3, reps: "15 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Copenhagen Plank", sets: 2, reps: "20 sec each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Banded Clamshells", sets: 3, reps: "15 each side", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "90-90 Active Transitions", sets: 2, reps: "10 transitions", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Happy Baby Rock", sets: 1, reps: "90 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Active Flow",
                description: "Complete active flexibility session",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Dynamic Warm Up", sets: 1, reps: "3 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip CARs", sets: 1, reps: "3 each direction each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder CARs", sets: 1, reps: "3 each direction each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Active Low Lunge", sets: 2, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Banded Pull Aparts", sets: 2, reps: "12 reps", restSeconds: 30),
                    ProgramExerciseDefinition(exerciseName: "Deep Squat Flow", sets: 2, reps: "10 reps", restSeconds: 30, notes: "Stand up between each"),
                    ProgramExerciseDefinition(exerciseName: "World's Greatest Stretch", sets: 1, reps: "5 each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "60 sec each side", restSeconds: 0)
                ]
            )
        ]
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
        morningMobility.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Wake Up Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Energizing Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Wake Up Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Spine Awakening", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Wake Up Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Energizing Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: "Sunday Reset", isRest: false)
        ]
        morningMobility.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Wake Up Flow",
                description: "Quick full body morning flow",
                estimatedMinutes: 10,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Bed Stretch", sets: 1, reps: "30 sec", restSeconds: 0, notes: "Full body reach"),
                    ProgramExerciseDefinition(exerciseName: "Neck Rolls", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Rolls", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Side Bend", sets: 1, reps: "20 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold", sets: 1, reps: "45 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Deep Breath Stretch", sets: 1, reps: "30 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Energizing Stretch",
                description: "Dynamic stretches to boost energy",
                estimatedMinutes: 10,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Leg Swings", sets: 1, reps: "15 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Hip Circles", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Torso Twist", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Jumping Jacks", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Knee Hugs", sets: 1, reps: "10 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Quad Pull", sets: 1, reps: "20 sec each leg", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Spine Awakening",
                description: "Focus on spinal mobility",
                estimatedMinutes: 10,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Supine Knee Drop", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "45 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cobra Stretch", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Twist", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Reach", sets: 1, reps: "30 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Sunday Reset",
                description: "Gentle start to the day",
                estimatedMinutes: 12,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Gentle Breathing", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Stretch", sets: 1, reps: "45 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Knees to Chest", sets: 1, reps: "45 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "45 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Forward Fold", sets: 1, reps: "45 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Full Body Reach", sets: 1, reps: "30 sec", restSeconds: 0)
                ]
            )
        ]
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
        officeStretches.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Desk Stretch Break", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Neck & Shoulder Relief", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Lower Body Desk Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Desk Stretch Break", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Full Desk Reset", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        officeStretches.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Desk Stretch Break",
                description: "Quick full body stretch at your desk",
                estimatedMinutes: 10,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Neck Rolls", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Shrugs", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Twist", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wrist Circles", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Figure Four", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Opener", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Calf Raise", sets: 1, reps: "15 reps", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Neck & Shoulder Relief",
                description: "Target neck and shoulder tension from desk work",
                estimatedMinutes: 10,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Ear to Shoulder Stretch", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chin Tucks", sets: 1, reps: "10 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Rolls", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cross Body Shoulder Stretch", sets: 1, reps: "30 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Overhead Tricep Stretch", sets: 1, reps: "30 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Doorway Chest Stretch", sets: 1, reps: "45 sec", restSeconds: 0, notes: "Use door frame"),
                    ProgramExerciseDefinition(exerciseName: "Upper Back Stretch", sets: 1, reps: "30 sec", restSeconds: 0, notes: "Clasp hands forward")
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Lower Body Desk Stretch",
                description: "Target tight hips and legs from sitting",
                estimatedMinutes: 10,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Seated Knee Lifts", sets: 1, reps: "10 each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Figure Four", sets: 1, reps: "45 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Hip Flexor Stretch", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Quad Stretch", sets: 1, reps: "30 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Calf Raises", sets: 1, reps: "15 reps", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Ankle Circles", sets: 1, reps: "20 sec each direction each foot", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Forward Fold", sets: 1, reps: "45 sec", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Desk Reset",
                description: "Complete desk stretching routine",
                estimatedMinutes: 12,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Standing Arm Circles", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "30 sec each direction", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Stretch", sets: 1, reps: "20 sec each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Wrist Stretches", sets: 1, reps: "30 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Twist", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Hip Flexor", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Figure Four", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Calf Stretch", sets: 1, reps: "20 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Deep Breathing", sets: 1, reps: "1 min", restSeconds: 0)
                ]
            )
        ]
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
        fullBodyFlex.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Lower Body Deep Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Upper Body & Spine", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: nil, isRest: true),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Hips & Core", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Full Body Flow", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: nil, isRest: true)
        ]
        fullBodyFlex.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Lower Body Deep Stretch",
                description: "Comprehensive leg and hip flexibility",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Leg Swings", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Quad Stretch", sets: 1, reps: "90 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Standing Hamstring Stretch", sets: 1, reps: "90 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge with Strap", sets: 1, reps: "90 sec each side", restSeconds: 0, notes: "Pull back foot with strap"),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "2 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Forward Fold with Strap", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Hamstring Stretch with Strap", sets: 1, reps: "90 sec each leg", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Frog Pose", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Calf Stretch", sets: 1, reps: "60 sec each leg", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Upper Body & Spine",
                description: "Shoulders, chest, back and spinal mobility",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Arm Circles", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder CARs", sets: 1, reps: "5 each direction each arm", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Stretch with Strap", sets: 1, reps: "90 sec", restSeconds: 0, notes: "Hold strap behind back"),
                    ProgramExerciseDefinition(exerciseName: "Lat Stretch", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Side Bend with Strap", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Hips & Core",
                description: "Deep hip opening and core stretching",
                estimatedMinutes: 35,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Hip CARs", sets: 1, reps: "5 each direction each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "90-90 Stretch", sets: 1, reps: "2 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Frog Pose", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Lizard Pose", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Sphinx Pose", sets: 1, reps: "90 sec", restSeconds: 0, notes: "Core stretch"),
                    ProgramExerciseDefinition(exerciseName: "Side Lying Quad Stretch", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Butterfly", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Full Body Flow",
                description: "Complete flexibility session",
                estimatedMinutes: 40,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Sun Salutation Flow", sets: 3, reps: "1 round", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold with Strap", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Low Lunge", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Pigeon Pose", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Straddle", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Chest Opener with Strap", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "60 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "3 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "3 min", restSeconds: 0)
                ]
            )
        ]
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
        bedtimeStretch.schedule = [
            ProgramDaySchedule(dayOfWeek: 1, workoutName: "Relaxing Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 2, workoutName: "Tension Release", isRest: false),
            ProgramDaySchedule(dayOfWeek: 3, workoutName: "Relaxing Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 4, workoutName: "Deep Relaxation", isRest: false),
            ProgramDaySchedule(dayOfWeek: 5, workoutName: "Tension Release", isRest: false),
            ProgramDaySchedule(dayOfWeek: 6, workoutName: "Relaxing Stretch", isRest: false),
            ProgramDaySchedule(dayOfWeek: 7, workoutName: "Sunday Night Calm", isRest: false)
        ]
        bedtimeStretch.workoutDefinitions = [
            ProgramWorkoutDefinition(
                name: "Relaxing Stretch",
                description: "Gentle full body stretch for sleep",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Seated Neck Stretch", sets: 1, reps: "30 sec each side", restSeconds: 0, notes: "Gentle, no strain"),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Rolls", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Seated Side Bend", sets: 1, reps: "30 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow", sets: 1, reps: "2 min", restSeconds: 0, notes: "Slow, with breath"),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "3 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Tension Release",
                description: "Release daily stress and tension",
                estimatedMinutes: 15,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Deep Breathing", sets: 1, reps: "2 min", restSeconds: 0, notes: "4-7-8 breathing"),
                    ProgramExerciseDefinition(exerciseName: "Neck Stretches", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Shoulder Release", sets: 1, reps: "1 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Forward Fold Seated", sets: 1, reps: "2 min", restSeconds: 0, notes: "Let gravity work"),
                    ProgramExerciseDefinition(exerciseName: "Reclined Figure Four", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Happy Baby", sets: 1, reps: "2 min", restSeconds: 0, notes: "Rock gently"),
                    ProgramExerciseDefinition(exerciseName: "Savasana", sets: 1, reps: "2 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Deep Relaxation",
                description: "Restorative stretching for deep rest",
                estimatedMinutes: 18,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Body Scan Breathing", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supported Child's Pose", sets: 1, reps: "3 min", restSeconds: 0, notes: "Use pillow"),
                    ProgramExerciseDefinition(exerciseName: "Supine Butterfly", sets: 1, reps: "3 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Knees to Chest", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Twist", sets: 1, reps: "2 min each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Legs Up Wall", sets: 1, reps: "5 min", restSeconds: 0)
                ]
            ),
            ProgramWorkoutDefinition(
                name: "Sunday Night Calm",
                description: "Extra gentle routine to start the week rested",
                estimatedMinutes: 20,
                exercises: [
                    ProgramExerciseDefinition(exerciseName: "Gentle Breathing", sets: 1, reps: "3 min", restSeconds: 0, notes: "Focus on exhale"),
                    ProgramExerciseDefinition(exerciseName: "Neck Release", sets: 1, reps: "1 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Cat-Cow Very Slow", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Thread the Needle", sets: 1, reps: "90 sec each side", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Child's Pose", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Supine Butterfly", sets: 1, reps: "2 min", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Knees to Chest Rock", sets: 1, reps: "90 sec", restSeconds: 0),
                    ProgramExerciseDefinition(exerciseName: "Savasana with Body Scan", sets: 1, reps: "5 min", restSeconds: 0)
                ]
            )
        ]
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
