import Foundation
import SwiftData
import Testing
@testable import GymTracker

struct TrainingModelTests {
    @Test
    func trainingBlockInitializesWithDefaultsAndRelationships() throws {
        let createdAt = Date(timeIntervalSince1970: 1_770_000_000)
        let week = TrainingWeek(weekNumber: 1, title: "Woche 1")
        let block = TrainingBlock(
            name: "Block A",
            athleteName: "Christian",
            goal: "Strength",
            status: .active,
            createdAt: createdAt,
            updatedAt: createdAt,
            weeks: [week]
        )

        #expect(block.name == "Block A")
        #expect(block.athleteName == "Christian")
        #expect(block.goal == "Strength")
        #expect(block.status == .active)
        #expect(block.createdAt == createdAt)
        #expect(block.updatedAt == createdAt)
        #expect(block.weeks.count == 1)
        #expect(week.block === block)
    }

    @Test
    func planValuesStayTextWhileActualSetValuesAreStructured() {
        let exercise = Exercise(name: "Kniebeugen", category: .squat)
        let plannedExercise = PlannedExercise(
            sortOrder: 1,
            cueing: "Tief bleiben",
            tempo: "3-1-1",
            setsPrescription: "5",
            repsPrescription: "6-10 oder AMRAP",
            plannedWeightText: "Koerpergewicht + 20 kg",
            targetRIRText: "2-3",
            painTargetText: "max 3/10",
            exercise: exercise
        )
        let exerciseLog = ExerciseLog(plannedExercise: plannedExercise)
        let setLog = SetLog(
            setNumber: 1,
            plannedRepsText: plannedExercise.repsPrescription,
            loggedReps: 8,
            plannedWeightText: plannedExercise.plannedWeightText,
            loggedWeightKg: 62.5,
            rir: 2,
            pain: 1,
            isCompleted: true,
            exerciseLog: exerciseLog
        )

        #expect(plannedExercise.repsPrescription == "6-10 oder AMRAP")
        #expect(plannedExercise.plannedWeightText == "Koerpergewicht + 20 kg")
        #expect(setLog.plannedRepsText == "6-10 oder AMRAP")
        #expect(setLog.loggedReps == 8)
        #expect(setLog.plannedWeightText == "Koerpergewicht + 20 kg")
        #expect(setLog.loggedWeightKg == 62.5)
        #expect(setLog.exerciseLog === exerciseLog)
        #expect(exerciseLog.setLogs.count == 1)
        #expect(plannedExercise.exercise === exercise)
    }

    @Test
    func fullTrainingGraphPersistsInMemory() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let block = TrainingBlock(name: "B1", goal: "Aufbau")
        let week = TrainingWeek(weekNumber: 1, title: "Woche 1")
        let workoutPlan = WorkoutPlan(dayNumber: 1, title: "Tag 1", sortOrder: 1)
        let exercise = Exercise(name: "Trapbar Kreuzheben", category: .hinge)
        let plannedExercise = PlannedExercise(
            sortOrder: 1,
            setsPrescription: "4",
            repsPrescription: "5-6",
            plannedWeightText: "moderat",
            workoutPlan: workoutPlan,
            exercise: exercise
        )
        let sessionLog = SessionLog(status: .completed, workoutPlan: workoutPlan)
        let exerciseLog = ExerciseLog(isCompleted: true, sessionLog: sessionLog, plannedExercise: plannedExercise)
        _ = SetLog(
            setNumber: 1,
            plannedRepsText: "5-6",
            loggedReps: 6,
            plannedWeightText: "moderat",
            loggedWeightKg: 80,
            isCompleted: true,
            exerciseLog: exerciseLog
        )

        block.weeks.append(week)
        week.workoutPlans.append(workoutPlan)
        context.insert(block)
        context.insert(exercise)

        try context.save()

        let blocks = try context.fetch(FetchDescriptor<TrainingBlock>())
        #expect(blocks.count == 1)
        #expect(blocks[0].weeks.count == 1)
        #expect(blocks[0].weeks[0].workoutPlans.count == 1)
        #expect(blocks[0].weeks[0].workoutPlans[0].plannedExercises.count == 1)
        #expect(blocks[0].weeks[0].workoutPlans[0].sessionLogs.count == 1)
        #expect(blocks[0].weeks[0].workoutPlans[0].sessionLogs[0].exerciseLogs.count == 1)
        #expect(blocks[0].weeks[0].workoutPlans[0].sessionLogs[0].exerciseLogs[0].setLogs.count == 1)
        #expect(blocks[0].weeks[0].workoutPlans[0].sessionLogs[0].exerciseLogs[0].setLogs[0].loggedWeightKg == 80)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            PersistentTrainingMarker.self,
            TrainingBlock.self,
            TrainingWeek.self,
            WorkoutPlan.self,
            Exercise.self,
            PlannedExercise.self,
            SessionLog.self,
            ExerciseLog.self,
            SetLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
