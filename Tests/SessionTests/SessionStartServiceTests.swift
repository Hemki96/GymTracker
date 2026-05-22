import Foundation
import SwiftData
import Testing
@testable import GymTracker

@Suite(.serialized)
struct SessionStartServiceTests {
    @Test
    func startSessionCreatesActiveLogGraphFromWorkoutPlan() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let workoutPlan = makeWorkoutPlan()
        let startedAt = Date(timeIntervalSince1970: 1_777_000_000)
        context.insert(workoutPlan)

        let session = try SessionStartService(context: context).startSession(
            from: workoutPlan,
            at: startedAt
        )

        #expect(session.status == .active)
        #expect(session.startedAt == startedAt)
        #expect(session.createdAt == startedAt)
        #expect(session.updatedAt == startedAt)
        #expect(session.workoutPlan === workoutPlan)
        #expect(workoutPlan.status == .active)
        #expect(session.exerciseLogs.count == 2)

        let firstExerciseLog = try #require(session.exerciseLogs.first { $0.plannedExercise?.sortOrder == 1 })
        let secondExerciseLog = try #require(session.exerciseLogs.first { $0.plannedExercise?.sortOrder == 2 })

        #expect(firstExerciseLog.plannedExercise?.exercise?.name == "Kniebeugen")
        #expect(firstExerciseLog.sessionLog === session)
        #expect(firstExerciseLog.setLogs.count == 3)
        #expect(firstExerciseLog.setLogs.map(\.setNumber).sorted() == [1, 2, 3])
        #expect(firstExerciseLog.setLogs.allSatisfy { $0.plannedRepsText == "5-6" })
        #expect(firstExerciseLog.setLogs.allSatisfy { $0.plannedWeightText == "80" })
        #expect(firstExerciseLog.setLogs.allSatisfy { !$0.isCompleted })

        #expect(secondExerciseLog.plannedExercise?.exercise?.name == "Bankdruecken")
        #expect(secondExerciseLog.setLogs.count == 4)
        #expect(secondExerciseLog.setLogs.allSatisfy { $0.plannedRepsText == "8-10" })
        #expect(secondExerciseLog.setLogs.allSatisfy { $0.plannedWeightText == "60" })

        #expect(try context.fetch(FetchDescriptor<SessionLog>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<ExerciseLog>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<SetLog>()).count == 7)
    }

    @Test
    func activeSessionCanBeFoundAfterContextRestart() throws {
        let container = try makeInMemoryContainer()
        let setupContext = ModelContext(container)
        let workoutPlan = makeWorkoutPlan()
        let startedAt = Date(timeIntervalSince1970: 1_777_100_000)
        setupContext.insert(workoutPlan)

        let createdSession = try SessionStartService(context: setupContext).startSession(
            from: workoutPlan,
            at: startedAt
        )

        let restartedContext = ModelContext(container)
        let activeSession = try #require(try SessionStartService(context: restartedContext).activeSession())

        #expect(activeSession.id == createdSession.id)
        #expect(activeSession.status == .active)
        #expect(activeSession.startedAt == startedAt)
    }

    @Test
    func startOrResumeSessionReturnsExistingWorkoutSessionAfterContextRestart() throws {
        let container = try makeInMemoryContainer()
        let setupContext = ModelContext(container)
        let workoutPlan = makeWorkoutPlan()
        setupContext.insert(workoutPlan)
        let createdSession = try SessionStartService(context: setupContext).startSession(from: workoutPlan)

        let restartedContext = ModelContext(container)
        let workouts = try restartedContext.fetch(FetchDescriptor<WorkoutPlan>())
        let reloadedWorkout = try #require(workouts.first { $0.id == workoutPlan.id })
        let resumedSession = try SessionStartService(context: restartedContext).startOrResumeSession(from: reloadedWorkout)

        #expect(resumedSession.id == createdSession.id)
        #expect(resumedSession.workoutPlan?.id == reloadedWorkout.id)
        #expect(try restartedContext.fetch(FetchDescriptor<SessionLog>()).count == 1)
    }

    @Test
    func startSessionFailsWhenAnActiveSessionAlreadyExists() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let firstWorkout = makeWorkoutPlan(dayNumber: 1)
        let secondWorkout = makeWorkoutPlan(dayNumber: 2)
        context.insert(firstWorkout)
        context.insert(secondWorkout)

        try SessionStartService(context: context).startSession(from: firstWorkout)

        do {
            try SessionStartService(context: context).startSession(from: secondWorkout)
            Issue.record("Expected starting a second active session to fail")
        } catch let error as SessionStartError {
            #expect(error == .activeSessionAlreadyExists)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let sessions = try context.fetch(FetchDescriptor<SessionLog>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.workoutPlan === firstWorkout)
    }

    private func makeWorkoutPlan(dayNumber: Int = 1) -> WorkoutPlan {
        let workoutPlan = WorkoutPlan(
            dayNumber: dayNumber,
            title: "Tag \(dayNumber)",
            sortOrder: dayNumber
        )

        let squat = Exercise(name: "Kniebeugen", category: .squat)
        let benchPress = Exercise(name: "Bankdruecken", category: .push)

        workoutPlan.plannedExercises = [
            PlannedExercise(
                sortOrder: 2,
                setsPrescription: "4",
                repsPrescription: "8-10",
                plannedWeightText: "60",
                workoutPlan: workoutPlan,
                exercise: benchPress
            ),
            PlannedExercise(
                sortOrder: 1,
                setsPrescription: "3",
                repsPrescription: "5-6",
                plannedWeightText: "80",
                workoutPlan: workoutPlan,
                exercise: squat
            )
        ]

        return workoutPlan
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
