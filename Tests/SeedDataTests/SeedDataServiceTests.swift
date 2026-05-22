import Foundation
import SwiftData
import Testing
@testable import GymTracker

@Suite(.serialized)
struct SeedDataServiceTests {
    @Test
    func demoFixtureHasExpectedShape() throws {
        let service = SeedDataService()

        let fixture = try service.loadDemoFixture()
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

        let firstImport = try service.importDemoPlanIfNeeded(into: context)
        let secondImport = try service.importDemoPlanIfNeeded(into: context)

        #expect(firstImport.didImport)
        #expect(!secondImport.didImport)
        #expect(firstImport.weeks == 6)
        #expect(firstImport.sessions == 18)
        #expect(firstImport.exerciseRows == 108)

        let blocks = try context.fetch(FetchDescriptor<TrainingBlock>())
        let weeks = try context.fetch(FetchDescriptor<TrainingWeek>())
        let workoutPlans = try context.fetch(FetchDescriptor<WorkoutPlan>())
        let plannedExercises = try context.fetch(FetchDescriptor<PlannedExercise>())
        let plannedSets = try context.fetch(FetchDescriptor<PlannedSet>())
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let markers = try context.fetch(FetchDescriptor<PersistentTrainingMarker>())

        #expect(blocks.count == 1)
        #expect(weeks.count == 6)
        #expect(workoutPlans.count == 18)
        #expect(plannedExercises.count == 108)
        #expect(plannedSets.count > plannedExercises.count)
        #expect(exercises.count == 16)
        #expect(markers.count == 1)
    }

    @Test
    func importPreservesPlanValuesFromDocumentation() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        _ = try SeedDataService().importDemoPlanIfNeeded(into: context)

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
        #expect(firstExercise.plannedSets.count == 5)
        #expect(firstExercise.plannedSets.allSatisfy { $0.repsText == "5" })
        #expect(firstExercise.plannedSets.allSatisfy { $0.targetRIRText == "2-3" })
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

    @Test
    func validationRejectsIncompleteFixture() throws {
        let invalidFixture = SeedTrainingFixture(
            source: "invalid.json",
            trainingBlock: SeedTrainingBlock(
                name: "Invalid",
                athleteName: "Athlete",
                goal: "Goal",
                weeks: [
                    SeedTrainingWeek(
                        weekNumber: 1,
                        title: "Woche 1",
                        days: [
                            SeedTrainingDay(
                                dayNumber: 1,
                                title: "Tag 1",
                                exercises: []
                            )
                        ]
                    )
                ]
            )
        )

        do {
            _ = try SeedDataService().validate(invalidFixture)
            Issue.record("Expected incomplete seed fixture to fail validation")
        } catch let error as SeedDataService.SeedError {
            #expect(error == .invalidFixture("At least one planned exercise is required."))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func validationAcceptsAnyWellFormedTrainingBlockShape() throws {
        let fixture = SeedTrainingFixture(
            source: "generic-demo.json",
            trainingBlock: SeedTrainingBlock(
                name: "Generic Strength Block",
                athleteName: nil,
                goal: "General strength",
                weeks: [
                    SeedTrainingWeek(
                        weekNumber: 7,
                        title: "Accumulation",
                        days: [
                            SeedTrainingDay(
                                dayNumber: 4,
                                title: "Upper Body",
                                exercises: [
                                    SeedPlannedExercise(
                                        sortOrder: 1,
                                        name: "Incline Press",
                                        cueing: "",
                                        tempo: "",
                                        sets: "2",
                                        reps: "8-12",
                                        plannedWeight: "",
                                        targetRIR: "",
                                        painTarget: "",
                                        notes: ""
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        )

        let result = try SeedDataService().validate(fixture)

        #expect(result.weeks == 1)
        #expect(result.sessions == 1)
        #expect(result.exerciseRows == 1)
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
