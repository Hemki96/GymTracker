import Foundation
import SwiftData
import Testing
@testable import GymTracker

@Suite(.serialized)
struct PlanActionServiceTests {
    @Test
    @MainActor
    func createPlanPersistsDefaultDraftPlan() throws {
        let context = try Self.makeContext()
        let service = PlanActionService(context: context)

        let plan = try service.createPlan()

        #expect(plan.name == "Neuer Trainingsplan")
        #expect(plan.goal == "")
        #expect(plan.status == .planned)

        let persistedPlans = try context.fetch(FetchDescriptor<TrainingPlan>())
        #expect(persistedPlans.map(\.id) == [plan.id])
    }

    @Test
    @MainActor
    func archivePlanMarksPlanArchivedAndUpdatesTimestamp() throws {
        let context = try Self.makeContext()
        let service = PlanActionService(context: context)
        let plan = TrainingPlan(
            name: "Block",
            goal: "Kraft",
            status: .active,
            updatedAt: Date(timeIntervalSince1970: 1)
        )
        context.insert(plan)
        try context.save()

        try service.archive(plan, at: Date(timeIntervalSince1970: 2))

        #expect(plan.status == .archived)
        #expect(plan.updatedAt == Date(timeIntervalSince1970: 2))
    }

    @Test
    @MainActor
    func deletePlanRemovesItFromTheContext() throws {
        let context = try Self.makeContext()
        let service = PlanActionService(context: context)
        let plan = TrainingPlan(name: "Block", goal: "Kraft")
        context.insert(plan)
        try context.save()

        try service.delete(plan)

        let persistedPlans = try context.fetch(FetchDescriptor<TrainingPlan>())
        #expect(persistedPlans.isEmpty)
    }

    @Test
    @MainActor
    func duplicatePlanCreatesEditableCopy() throws {
        let context = try Self.makeContext()
        let service = PlanActionService(context: context)
        let plan = TrainingPlan(name: "Demo", goal: "Ausprobieren", isDemoPlan: true)
        let week = TrainingWeek(weekNumber: 1, title: "Woche 1")
        let workout = WorkoutPlan(dayNumber: 1, title: "Upper", sortOrder: 1)
        let exercise = Exercise(name: "Bankdruecken")
        let plannedExercise = PlannedExercise(
            sortOrder: 1,
            setsPrescription: "3",
            repsPrescription: "8",
            exercise: exercise
        )
        workout.plannedExercises = [plannedExercise]
        week.workoutPlans = [workout]
        plan.weeks = [week]
        context.insert(plan)
        try context.save()

        let copy = try service.duplicate(plan)

        #expect(copy.id != plan.id)
        #expect(copy.name == "Demo Kopie")
        #expect(copy.isDemoPlan == false)
        #expect(copy.weeks.count == 1)
        #expect(copy.weeks.first?.workoutPlans.first?.plannedExercises.first?.exercise?.name == "Bankdruecken")
    }

    @MainActor
    private static func makeContext() throws -> ModelContext {
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
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
