import Foundation
import SwiftData
import Testing
@testable import GymTracker

@Suite(.serialized)
struct DemoDataServiceTests {
    @Test
    func appContainerStartsWithoutDemoPlan() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let plans = try context.fetch(FetchDescriptor<TrainingPlan>())

        #expect(plans.isEmpty)
    }

    @Test
    func loadingDemoPlanIsExplicitAndMarksThePlan() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let service = DemoDataService(seedDataService: SeedDataService())

        let result = try service.loadBundledDemoPlan(into: context)

        let plans = try context.fetch(FetchDescriptor<TrainingPlan>())
        let plan = try #require(plans.first)
        #expect(result.didImport)
        #expect(plans.count == 1)
        #expect(plan.isDemoPlan)
        #expect(plan.demoSourceIdentifier == DemoDataService.bundledDemoPlanIdentifier)
        #expect(plan.name == "Wettkampfvorbereitung bis 20.06.2026")
    }

    @Test
    func deletingDemoPlanRemovesOnlyDemoPlan() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let service = DemoDataService(seedDataService: SeedDataService())

        _ = try service.loadBundledDemoPlan(into: context)
        context.insert(TrainingPlan(name: "Eigener Aufbauplan", goal: "Hypertrophie"))
        try context.save()

        let deletedCount = try service.deleteBundledDemoPlan(from: context)

        let plans = try context.fetch(FetchDescriptor<TrainingPlan>())
        #expect(deletedCount == 1)
        #expect(plans.count == 1)
        #expect(plans.first?.name == "Eigener Aufbauplan")
        #expect(plans.first?.isDemoPlan == false)
    }

    @Test
    func duplicatingDemoPlanCreatesEditableNonDemoCopy() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let service = DemoDataService(seedDataService: SeedDataService())

        _ = try service.loadBundledDemoPlan(into: context)
        let demoPlan = try #require(try context.fetch(FetchDescriptor<TrainingPlan>()).first)

        let copy = try service.duplicateDemoPlan(demoPlan, name: "Mein B1 Template", in: context)

        #expect(!copy.isDemoPlan)
        #expect(copy.demoSourceIdentifier == nil)
        #expect(copy.name == "Mein B1 Template")
        #expect(copy.id != demoPlan.id)
        #expect(copy.weeks.count == demoPlan.weeks.count)

        let copiedWeek = try #require(copy.weeks.first { $0.weekNumber == 1 })
        let sourceWeek = try #require(demoPlan.weeks.first { $0.weekNumber == 1 })
        let copiedWorkout = try #require(copiedWeek.workoutPlans.first { $0.dayNumber == 1 })
        let sourceWorkout = try #require(sourceWeek.workoutPlans.first { $0.dayNumber == 1 })
        let copiedExercise = try #require(copiedWorkout.plannedExercises.first { $0.sortOrder == 1 })
        let sourceExercise = try #require(sourceWorkout.plannedExercises.first { $0.sortOrder == 1 })

        #expect(copiedWeek.id != sourceWeek.id)
        #expect(copiedWorkout.id != sourceWorkout.id)
        #expect(copiedExercise.id != sourceExercise.id)
        #expect(copiedExercise.plannedSets.count == sourceExercise.plannedSets.count)
    }

    @Test
    @MainActor
    func previewDataUsesIndependentNonDemoFixture() throws {
        let context = ModelContext(PlanPreviewData.container)

        let plans = try context.fetch(FetchDescriptor<TrainingPlan>())
        let plan = try #require(plans.first)

        #expect(plans.count == 1)
        #expect(plan.name == "Preview Strength Block")
        #expect(!plan.isDemoPlan)
        #expect(plan.demoSourceIdentifier == nil)
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
