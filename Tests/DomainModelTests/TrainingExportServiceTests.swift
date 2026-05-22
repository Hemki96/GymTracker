import Foundation
import Testing
@testable import GymTracker

@Suite(.serialized)
struct TrainingExportServiceTests {
    @Test
    func markdownExportContainsPlanAndActualValues() throws {
        let graph = makeTrainingGraph()
        let markdown = try TrainingExportService().markdown(for: graph.session)

        #expect(markdown.contains("# Unterkoerper A"))
        #expect(markdown.contains("- Datum: 2026-05-20"))
        #expect(markdown.contains("- Block: Block B1"))
        #expect(markdown.contains("| Dauer | 1 h 10 min |"))
        #expect(markdown.contains("| Volumen | 480 kg |"))
        #expect(markdown.contains("- Plan: 3 x 6-8"))
        #expect(markdown.contains("- Gewicht geplant: 80 kg"))
        #expect(markdown.contains("| Satz | Plan Wdh. | Ist Wdh. | Plan Gewicht | Ist Gewicht kg | RIR | Schmerz | Erledigt |"))
        #expect(markdown.contains("| 1 | 6-8 | 6 | 80 kg | 80 | 2 | 1 | ja |"))
        #expect(markdown.contains("| 2 | 6-8 | 6 | 80 kg | 80 | 1 | 2 | ja |"))
    }

    @Test
    func csvExportContainsWholeBlockWithEscapingPlanAndActualValues() {
        let graph = makeTrainingGraph(blockName: "Block, B1")
        let csv = TrainingExportService().csv(for: graph.block)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.first == "Block,Woche,Tag,Workout,Plan-Datum,Uebung,Plan-Saetze,Plan-Wdh,Plan-Gewicht,Ziel-RIR,Schmerz-Ziel,Satz,Satz-Plan-Wdh,Satz-Plan-Gewicht,Session-Start,Session-Ende,Ist-Wdh,Ist-Gewicht-kg,Ist-RIR,Ist-Schmerz,Erledigt,Notizen")
        #expect(lines.contains("\"Block, B1\",1,1,Unterkoerper A,2026-05-20,Trapbar Kreuzheben,3,6-8,80 kg,1-2,max 3/10,1,6-8,80 kg,2026-05-20 08:00,2026-05-20 09:10,6,80,2,1,ja,\"stabil | sauber, kontrolliert\""))
        #expect(lines.contains("\"Block, B1\",1,1,Unterkoerper A,2026-05-20,Trapbar Kreuzheben,3,6-8,80 kg,1-2,max 3/10,2,6-8,80 kg,2026-05-20 08:00,2026-05-20 09:10,6,80,1,2,ja,stabil"))
    }

    @Test
    func exportFileNamesUseDateAndBlockName() throws {
        let graph = makeTrainingGraph(blockName: "Block B1 Aufbau")
        let service = TrainingExportService()

        let sessionURL = try service.fileURL(forSession: graph.session)
        let blockURL = try service.fileURL(forBlock: graph.block)

        #expect(sessionURL.lastPathComponent == "2026-05-20_block-b1-aufbau_unterkoerper-a.md")
        #expect(blockURL.lastPathComponent == "2026-05-01_block-b1-aufbau.csv")
    }

    @Test
    func markdownExportFailsWithoutWorkoutPlan() {
        let session = SessionLog(startedAt: Date(timeIntervalSince1970: 1_777_000_000))

        do {
            _ = try TrainingExportService().markdown(for: session)
            Issue.record("Expected export without workout plan to fail")
        } catch let error as TrainingExportService.ExportError {
            #expect(error == .missingWorkoutPlan)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func makeTrainingGraph(blockName: String = "Block B1") -> (
        block: TrainingBlock,
        session: SessionLog
    ) {
        let block = TrainingBlock(
            name: blockName,
            goal: "Kraft",
            startDate: date(year: 2026, month: 5, day: 1, hour: 0, minute: 0),
            createdAt: date(year: 2026, month: 5, day: 1, hour: 0, minute: 0)
        )
        let week = TrainingWeek(weekNumber: 1, title: "Woche 1", block: block)
        let workout = WorkoutPlan(
            dayNumber: 1,
            title: "Unterkoerper A",
            plannedDate: date(year: 2026, month: 5, day: 20, hour: 0, minute: 0),
            sortOrder: 1,
            week: week
        )
        let exercise = Exercise(name: "Trapbar Kreuzheben", category: .hinge)
        let plannedExercise = PlannedExercise(
            sortOrder: 1,
            tempo: "3-1-1",
            setsPrescription: "3",
            repsPrescription: "6-8",
            plannedWeightText: "80 kg",
            targetRIRText: "1-2",
            painTargetText: "max 3/10",
            workoutPlan: workout,
            exercise: exercise
        )
        let session = SessionLog(
            startedAt: date(year: 2026, month: 5, day: 20, hour: 8, minute: 0),
            completedAt: date(year: 2026, month: 5, day: 20, hour: 9, minute: 10),
            durationSeconds: 4_200,
            status: .completed,
            overallNotes: "Gute Einheit.",
            maxPain: 2,
            averageRIR: 1.5,
            totalVolumeKg: 480,
            workoutPlan: workout
        )
        let exerciseLog = ExerciseLog(
            notes: "stabil",
            isCompleted: true,
            sessionLog: session,
            plannedExercise: plannedExercise
        )
        let firstSet = SetLog(
            setNumber: 1,
            plannedRepsText: "6-8",
            loggedReps: 6,
            plannedWeightText: "80 kg",
            loggedWeightKg: 80,
            rir: 2,
            pain: 1,
            notes: "sauber, kontrolliert",
            isCompleted: true,
            exerciseLog: exerciseLog
        )
        let secondSet = SetLog(
            setNumber: 2,
            plannedRepsText: "6-8",
            loggedReps: 6,
            plannedWeightText: "80 kg",
            loggedWeightKg: 80,
            rir: 1,
            pain: 2,
            isCompleted: true,
            exerciseLog: exerciseLog
        )

        block.weeks = [week]
        week.workoutPlans = [workout]
        workout.plannedExercises = [plannedExercise]
        workout.sessionLogs = [session]
        session.exerciseLogs = [exerciseLog]
        exerciseLog.setLogs = [firstSet, secondSet]

        return (block, session)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
