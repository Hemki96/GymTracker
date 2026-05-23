import SwiftData

enum PlanPreviewData {
    @MainActor
    static let container: ModelContainer = {
        let schema = Schema([
            PersistentTrainingMarker.self,
            TrainingBlock.self,
            TrainingWeek.self,
            WorkoutPlan.self,
            Exercise.self,
            PlannedExercise.self,
            PlannedSet.self,
            SessionLog.self,
            ExerciseLog.self,
            SetLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            insertPreviewPlan(in: context)
            try context.save()

            return container
        } catch {
            fatalError("Failed to create plan preview data: \(error)")
        }
    }()

    @MainActor
    static let emptyContainer: ModelContainer = {
        do {
            return try makeContainer()
        } catch {
            fatalError("Failed to create empty plan preview data: \(error)")
        }
    }()

    @MainActor
    private static func insertPreviewPlan(in context: ModelContext) {
        let squat = Exercise(name: "Goblet Squat", category: .squat)
        let row = Exercise(name: "Cable Row", category: .pull)
        let press = Exercise(name: "Dumbbell Press", category: .push)

        let block = TrainingPlan(
            name: "Preview Strength Block",
            athleteName: "Preview Athlete",
            goal: "Build reusable preview data"
        )
        let week = TrainingWeek(weekNumber: 1, title: "Foundation Week")

        let lower = WorkoutPlan(dayNumber: 1, title: "Lower Body", status: .completed, sortOrder: 1)
        lower.plannedExercises = [
            plannedExercise(sortOrder: 1, exercise: squat, sets: 3, reps: "8-10", weight: "24", rir: "2"),
            plannedExercise(sortOrder: 2, exercise: row, sets: 2, reps: "10-12", weight: "35", rir: "2-3")
        ]

        let upper = WorkoutPlan(dayNumber: 2, title: "Upper Body", sortOrder: 2)
        upper.plannedExercises = [
            plannedExercise(sortOrder: 1, exercise: press, sets: 3, reps: "8", weight: "18", rir: "2"),
            plannedExercise(sortOrder: 2, exercise: row, sets: 3, reps: "10", weight: "32.5", rir: "3")
        ]

        week.workoutPlans = [lower, upper]
        block.weeks = [week]

        context.insert(block)
        context.insert(squat)
        context.insert(row)
        context.insert(press)
    }

    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            PersistentTrainingMarker.self,
            TrainingBlock.self,
            TrainingWeek.self,
            WorkoutPlan.self,
            Exercise.self,
            PlannedExercise.self,
            PlannedSet.self,
            SessionLog.self,
            ExerciseLog.self,
            SetLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func plannedExercise(
        sortOrder: Int,
        exercise: Exercise,
        sets: Int,
        reps: String,
        weight: String,
        rir: String
    ) -> PlannedExercise {
        let plannedExercise = PlannedExercise(
            sortOrder: sortOrder,
            setsPrescription: "\(sets)",
            repsPrescription: reps,
            plannedWeightText: weight,
            targetRIRText: rir,
            exercise: exercise
        )
        plannedExercise.plannedSets = (1...sets).map { setNumber in
            PlannedSet(
                setNumber: setNumber,
                repsText: reps,
                weightText: weight,
                targetRIRText: rir,
                plannedExercise: plannedExercise
            )
        }
        return plannedExercise
    }
}
