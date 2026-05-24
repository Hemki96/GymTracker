import Foundation
import SwiftData
import Testing
@testable import GymTracker

@Suite(.serialized)
struct TrainingModelTests {
    @Test
    func trainingBlockInitializesWithDefaultsAndRelationships() throws {
        let createdAt = Date(timeIntervalSince1970: 1_770_000_000)
        let week = TrainingWeek(weekNumber: 1, title: "Woche 1")
        let block = TrainingBlock(
            name: "Block A",
            athleteName: "Athlete",
            goal: "Strength",
            status: .active,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        week.block = block

        #expect(block.name == "Block A")
        #expect(block.athleteName == "Athlete")
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

        let block = TrainingBlock(name: "Strength Block", goal: "Aufbau")
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
        let setLog = SetLog(
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
        workoutPlan.plannedExercises.append(plannedExercise)
        workoutPlan.sessionLogs.append(sessionLog)
        sessionLog.exerciseLogs.append(exerciseLog)
        exerciseLog.setLogs.append(setLog)
        context.insert(block)
        context.insert(exercise)

        try context.save()

        let blocks = try context.fetch(FetchDescriptor<TrainingBlock>())
        #expect(blocks.count == 1)
        #expect(blocks[0].weeks.count == 1)
        #expect(blocks[0].weeks[0].workoutPlans.count == 1)
        let persistedWorkout = try #require(blocks[0].weeks[0].workoutPlans.first)
        #expect(persistedWorkout.plannedExercises.count == 1)
        #expect(persistedWorkout.sessionLogs.count == 1)
        let persistedSession = try #require(persistedWorkout.sessionLogs.first)
        #expect(persistedSession.exerciseLogs.count == 1)
        let persistedExerciseLog = try #require(persistedSession.exerciseLogs.first)
        #expect(persistedExerciseLog.setLogs.count == 1)
        #expect(persistedExerciseLog.setLogs.first?.loggedWeightKg == 80)
    }

    @Test
    func gymTrackerModelContainerCanCreateInMemoryContainer() throws {
        let container = try GymTrackerModelContainer.make(isStoredInMemoryOnly: true)
        let context = ModelContext(container)
        let block = TrainingBlock(name: "Container Smoke", goal: "Robust start")

        context.insert(block)
        try context.save()

        let persistedBlocks: [TrainingBlock] = try context.fetch(FetchDescriptor<TrainingBlock>())
        #expect(persistedBlocks.map(\.name) == ["Container Smoke"])
    }

    @Test
    func genericPlanSupportsVariableShapeAndSeparatePlannedAndCompletedData() throws {
        let planID = UUID()
        let weekID = UUID()
        let sessionID = UUID()
        let exerciseID = UUID()
        let plannedSetID = UUID()
        let completedSessionID = UUID()
        let completedExerciseID = UUID()
        let completedSetID = UUID()

        let plan = TrainingPlan(
            id: planID,
            name: "Any Plan",
            athleteName: nil,
            goal: "Move better"
        )
        let week = TrainingWeek(id: weekID, weekNumber: 9, title: "Deload")
        let plannedSession = TrainingSession(
            id: sessionID,
            dayNumber: 4,
            title: "Optional Mobility",
            sortOrder: 99
        )
        let exercise = Exercise(id: exerciseID, name: "Custom Movement")
        let plannedExercise = PlannedExercise(
            sortOrder: 12,
            setsPrescription: "custom",
            repsPrescription: "as prescribed",
            targetRIRText: "coach note",
            painTargetText: "athlete-defined",
            workoutPlan: plannedSession,
            exercise: exercise
        )
        let plannedSet = PlannedSet(
            id: plannedSetID,
            setNumber: 7,
            repsText: "30 sec",
            weightText: "band",
            targetRIRText: "easy",
            painTargetText: "stop on symptoms",
            plannedExercise: plannedExercise
        )
        let completedSession = CompletedSession(
            id: completedSessionID,
            status: .completed,
            workoutPlan: plannedSession
        )
        let completedExercise = CompletedExercise(
            id: completedExerciseID,
            isCompleted: true,
            sessionLog: completedSession,
            plannedExercise: plannedExercise
        )
        let completedSet = CompletedSet(
            id: completedSetID,
            setNumber: plannedSet.setNumber,
            plannedRepsText: plannedSet.repsText,
            loggedReps: nil,
            plannedWeightText: plannedSet.weightText,
            loggedWeightKg: nil,
            rir: 4.5,
            pain: 11,
            isCompleted: true,
            exerciseLog: completedExercise,
            plannedSet: plannedSet
        )

        plan.weeks = [week]
        week.workoutPlans = [plannedSession]
        plannedSession.plannedExercises = [plannedExercise]
        plannedExercise.plannedSets = [plannedSet]
        plannedSession.sessionLogs = [completedSession]
        completedSession.exerciseLogs = [completedExercise]
        completedExercise.setLogs = [completedSet]

        #expect(plan.id == planID)
        #expect(week.id == weekID)
        #expect(plannedSession.id == sessionID)
        #expect(exercise.id == exerciseID)
        #expect(plannedSet.id == plannedSetID)
        #expect(completedSession.id == completedSessionID)
        #expect(completedExercise.id == completedExerciseID)
        #expect(completedSet.id == completedSetID)
        #expect(plan.weeks.count == 1)
        #expect(week.workoutPlans.count == 1)
        #expect(plannedSession.plannedExercises.count == 1)
        #expect(plannedExercise.plannedSets.count == 1)
        #expect(completedExercise.setLogs.first?.plannedSet === plannedSet)
        #expect(completedSet.rir == 4.5)
        #expect(completedSet.pain == 11)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
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
}
