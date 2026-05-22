import Foundation
import SwiftData
import Testing
@testable import GymTracker

@Suite(.serialized)
struct SessionCompletionServiceTests {
    @Test
    func completeSessionStoresSummaryAndMarksWorkoutCompleted() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let workout = makeWorkoutPlan()
        let startedAt = Date(timeIntervalSince1970: 1_777_000_000)
        let completedAt = startedAt.addingTimeInterval(4_200)
        context.insert(workout)

        let session = try SessionStartService(context: context).startSession(from: workout, at: startedAt)
        let squatLog = try #require(session.exerciseLogs.first { $0.plannedExercise?.exercise?.name == "Kniebeugen" })
        let squatSets = squatLog.setLogs.sorted { $0.setNumber < $1.setNumber }
        squatSets[0].loggedWeightKg = 80
        squatSets[0].loggedReps = 5
        squatSets[0].rir = 1
        squatSets[0].pain = 2
        squatSets[0].isCompleted = true
        squatSets[1].loggedWeightKg = 82.5
        squatSets[1].loggedReps = 5
        squatSets[1].rir = 0
        squatSets[1].pain = 5
        squatSets[1].isCompleted = true

        try SessionCompletionService(context: context).completeSession(
            session,
            note: "  Schwer, aber stabil.  ",
            at: completedAt
        )

        #expect(session.status == .completed)
        #expect(session.completedAt == completedAt)
        #expect(session.durationSeconds == 4_200)
        #expect(session.totalVolumeKg == 812.5)
        #expect(session.averageRIR == 0.5)
        #expect(session.maxPain == 5)
        #expect(session.overallNotes == "Schwer, aber stabil.")
        #expect(session.workoutPlan?.status == .completed)
        #expect(squatLog.isCompleted)
        #expect(squatLog.completedAt == completedAt)
    }

    @Test
    func completeSessionCollectsWarnings() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let workout = makeWorkoutPlan()
        context.insert(workout)

        let session = try SessionStartService(context: context).startSession(from: workout)
        let squatLog = try #require(session.exerciseLogs.first { $0.plannedExercise?.exercise?.name == "Kniebeugen" })
        let set = try #require(squatLog.setLogs.sorted { $0.setNumber < $1.setNumber }.first)
        set.loggedWeightKg = 80
        set.loggedReps = 5
        set.rir = 4
        set.pain = 8
        set.isCompleted = true

        try SessionCompletionService(context: context).completeSession(session, note: nil)

        #expect(session.warningMessages.contains("Kniebeugen, Satz 1: Schmerz 8/10 ueber Ziel max 3/10."))
        #expect(session.warningMessages.contains("Kniebeugen, Satz 1: hoher Schmerz 8/10."))
        #expect(session.warningMessages.contains("Kniebeugen, Satz 1: RIR 4 ueber Ziel 1-2."))
    }

    @Test
    func completedSessionCanBeFetchedForHistory() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let workout = makeWorkoutPlan()
        context.insert(workout)

        let session = try SessionStartService(context: context).startSession(from: workout)
        try SessionCompletionService(context: context).completeSession(session, note: nil)

        let completedRaw = SessionStatus.completed.rawValue
        let descriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate { session in
                session.statusRaw == completedRaw
            }
        )
        let historySessions = try context.fetch(descriptor)

        #expect(historySessions.map(\.id) == [session.id])
    }

    @Test
    func editingServiceAddsCopiesDeletesRenumbersAndRefreshesSummary() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let workout = makeWorkoutPlan()
        context.insert(workout)

        let session = try SessionStartService(context: context).startSession(from: workout)
        let exerciseLog = try #require(session.exerciseLogs.first)
        let firstSet = try #require(exerciseLog.setLogs.first)
        firstSet.loggedWeightKg = 80
        firstSet.loggedReps = 5
        firstSet.rir = 2
        firstSet.pain = 1
        firstSet.isCompleted = true
        try SessionEditingService(context: context).save(setLog: firstSet)

        let addedSet = try SessionEditingService(context: context).addSet(to: exerciseLog)

        #expect(addedSet.setNumber == 3)
        #expect(addedSet.loggedWeightKg == 80)
        #expect(addedSet.loggedReps == 5)
        #expect(addedSet.rir == 2)
        #expect(addedSet.pain == 1)
        #expect(session.totalVolumeKg == 400)

        try SessionEditingService(context: context).deleteSet(firstSet)

        let remainingNumbers = exerciseLog.setLogs
            .filter { $0.id != firstSet.id }
            .map(\.setNumber)
            .sorted()
        #expect(remainingNumbers == [1, 2])
    }

    private func makeWorkoutPlan() -> WorkoutPlan {
        let workoutPlan = WorkoutPlan(dayNumber: 1, title: "Tag 1", sortOrder: 1)
        let squat = Exercise(name: "Kniebeugen", category: .squat)

        workoutPlan.plannedExercises = [
            PlannedExercise(
                sortOrder: 1,
                setsPrescription: "2",
                repsPrescription: "5",
                plannedWeightText: "80",
                targetRIRText: "1-2",
                painTargetText: "max 3/10",
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
