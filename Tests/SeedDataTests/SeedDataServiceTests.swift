import Foundation
import SwiftData
import Testing
@testable import GymTracker

struct SeedDataServiceTests {
    @Test
    func christianHemkerB1FixtureHasExpectedShape() throws {
        let service = SeedDataService()

        let fixture = try service.loadChristianHemkerB1Fixture()
        let result = try service.validate(fixture)

        #expect(fixture.source == "Trainingsplan Christian Hemker B1.xlsx")
        #expect(fixture.trainingBlock.name == "Wettkampfvorbereitung bis 20.06.2026")
        #expect(fixture.trainingBlock.athleteName == "Christian Hemker")
        #expect(result.weeks == 6)
        #expect(result.sessions == 18)
        #expect(result.exerciseRows == 108)
    }

    @Test
    func importCreatesTrainingGraphOnce() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let service = SeedDataService()

        let firstImport = try service.importChristianHemkerB1IfNeeded(into: context)
        let secondImport = try service.importChristianHemkerB1IfNeeded(into: context)

        #expect(firstImport.didImport)
        #expect(!secondImport.didImport)
        #expect(firstImport.weeks == 6)
        #expect(firstImport.sessions == 18)
        #expect(firstImport.exerciseRows == 108)

        let blocks = try context.fetch(FetchDescriptor<TrainingBlock>())
        let weeks = try context.fetch(FetchDescriptor<TrainingWeek>())
        let workoutPlans = try context.fetch(FetchDescriptor<WorkoutPlan>())
        let plannedExercises = try context.fetch(FetchDescriptor<PlannedExercise>())
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let markers = try context.fetch(FetchDescriptor<PersistentTrainingMarker>())

        #expect(blocks.count == 1)
        #expect(weeks.count == 6)
        #expect(workoutPlans.count == 18)
        #expect(plannedExercises.count == 108)
        #expect(exercises.count == 16)
        #expect(markers.count == 1)
    }

    @Test
    func importPreservesPlanValuesFromDocumentation() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        try SeedDataService().importChristianHemkerB1IfNeeded(into: context)

        let block = try #require(try context.fetch(FetchDescriptor<TrainingBlock>()).first)
        let weekOne = try #require(block.weeks.first { $0.weekNumber == 1 })
        let dayOne = try #require(weekOne.workoutPlans.first { $0.dayNumber == 1 })
        let firstExercise = try #require(dayOne.plannedExercises.first { $0.sortOrder == 1 })
        let weekTwo = try #require(block.weeks.first { $0.weekNumber == 2 })
        let dayThree = try #require(weekTwo.workoutPlans.first { $0.dayNumber == 3 })
        let pullUp = try #require(dayThree.plannedExercises.first { $0.sortOrder == 3 })

        #expect(firstExercise.exercise?.name == "Kniebeugen")
        #expect(firstExercise.cueing == "Auf Druck unter den Fußsohlen achten")
        #expect(firstExercise.tempo == "kontrolliert langsam mit Pause")
        #expect(firstExercise.setsPrescription == "5")
        #expect(firstExercise.repsPrescription == "5")
        #expect(firstExercise.plannedWeightText == "80")
        #expect(firstExercise.targetRIRText == "2-3")
        #expect(firstExercise.painTargetText == "max 3/10")
        #expect(firstExercise.notes == "Barfuß")

        #expect(pullUp.exercise?.name == "Klimmzüge (mit Zusatzgewicht)")
        #expect(pullUp.tempo == "explosiv hoch")
        #expect(pullUp.plannedWeightText == "5")
        #expect(pullUp.notes == "Nur 3 Wiederholungen mit dem Gewicht")
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
