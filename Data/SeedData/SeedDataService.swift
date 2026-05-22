import Foundation
import SwiftData

struct SeedDataService {
    enum SeedError: Error, Equatable {
        case missingResource(String)
        case invalidFixture(expectedWeeks: Int, actualWeeks: Int, expectedSessions: Int, actualSessions: Int, expectedExerciseRows: Int, actualExerciseRows: Int)
    }

    struct ImportResult: Equatable {
        let didImport: Bool
        let weeks: Int
        let sessions: Int
        let exerciseRows: Int
    }

    private static let christianHemkerB1MarkerKey = "seed.trainingPlan.christianHemkerB1.v1"
    private static let christianHemkerB1ResourceName = "seed_christian_b1_plan"

    func importChristianHemkerB1IfNeeded(
        into context: ModelContext,
        bundle: Bundle = .main
    ) throws -> ImportResult {
        let markerKey = Self.christianHemkerB1MarkerKey
        let existingMarker = try context.fetch(
            FetchDescriptor<PersistentTrainingMarker>(
                predicate: #Predicate { $0.key == markerKey }
            )
        ).first

        let fixture = try loadChristianHemkerB1Fixture(from: bundle)
        let summary = try validate(fixture)

        guard existingMarker == nil else {
            return ImportResult(
                didImport: false,
                weeks: summary.weeks,
                sessions: summary.sessions,
                exerciseRows: summary.exerciseRows
            )
        }

        let blockFixture = fixture.trainingBlock
        let block = TrainingBlock(
            name: blockFixture.name,
            athleteName: blockFixture.athleteName,
            goal: blockFixture.goal
        )

        var exercisesByName: [String: Exercise] = [:]

        for weekFixture in blockFixture.weeks.sorted(by: { $0.weekNumber < $1.weekNumber }) {
            let week = TrainingWeek(
                weekNumber: weekFixture.weekNumber,
                title: weekFixture.title
            )

            for dayFixture in weekFixture.days.sorted(by: { $0.dayNumber < $1.dayNumber }) {
                let workoutPlan = WorkoutPlan(
                    dayNumber: dayFixture.dayNumber,
                    title: dayFixture.title,
                    sortOrder: dayFixture.dayNumber
                )

                for exerciseFixture in dayFixture.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                    let exercise = exercisesByName[exerciseFixture.name] ?? Exercise(
                        name: exerciseFixture.name,
                        category: category(for: exerciseFixture.name),
                        defaultCueing: normalizedOptional(exerciseFixture.cueing),
                        defaultTempo: normalizedOptional(exerciseFixture.tempo),
                        isUnilateral: isUnilateral(exerciseFixture.name),
                        usesBodyweight: usesBodyweight(exerciseFixture.name)
                    )
                    exercisesByName[exerciseFixture.name] = exercise

                    let plannedExercise = PlannedExercise(
                        sortOrder: exerciseFixture.sortOrder,
                        cueing: normalizedOptional(exerciseFixture.cueing),
                        tempo: normalizedOptional(exerciseFixture.tempo),
                        setsPrescription: exerciseFixture.sets,
                        repsPrescription: exerciseFixture.reps,
                        plannedWeightText: normalizedOptional(exerciseFixture.plannedWeight),
                        targetRIRText: normalizedOptional(exerciseFixture.targetRIR),
                        painTargetText: normalizedOptional(exerciseFixture.painTarget),
                        notes: normalizedOptional(exerciseFixture.notes),
                        exercise: exercise
                    )
                    workoutPlan.plannedExercises.append(plannedExercise)
                }

                week.workoutPlans.append(workoutPlan)
            }

            block.weeks.append(week)
        }

        context.insert(block)
        for exercise in exercisesByName.values {
            context.insert(exercise)
        }
        context.insert(PersistentTrainingMarker(key: Self.christianHemkerB1MarkerKey))

        try context.save()

        return ImportResult(
            didImport: true,
            weeks: summary.weeks,
            sessions: summary.sessions,
            exerciseRows: summary.exerciseRows
        )
    }

    func loadChristianHemkerB1Fixture(from bundle: Bundle = .main) throws -> ChristianHemkerB1SeedFixture {
        guard let url = bundle.url(forResource: Self.christianHemkerB1ResourceName, withExtension: "json") else {
            throw SeedError.missingResource("\(Self.christianHemkerB1ResourceName).json")
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ChristianHemkerB1SeedFixture.self, from: data)
    }

    @discardableResult
    func validate(_ fixture: ChristianHemkerB1SeedFixture) throws -> ImportResult {
        let weeks = fixture.trainingBlock.weeks.count
        let sessions = fixture.trainingBlock.weeks.reduce(0) { $0 + $1.days.count }
        let exerciseRows = fixture.trainingBlock.weeks.reduce(0) { weekTotal, week in
            weekTotal + week.days.reduce(0) { $0 + $1.exercises.count }
        }

        guard weeks == 6, sessions == 18, exerciseRows == 108 else {
            throw SeedError.invalidFixture(
                expectedWeeks: 6,
                actualWeeks: weeks,
                expectedSessions: 18,
                actualSessions: sessions,
                expectedExerciseRows: 108,
                actualExerciseRows: exerciseRows
            )
        }

        return ImportResult(didImport: false, weeks: weeks, sessions: sessions, exerciseRows: exerciseRows)
    }

    private func normalizedOptional(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
    }

    private func category(for exerciseName: String) -> ExerciseCategory {
        switch exerciseName {
        case "Kniebeugen":
            return .squat
        case "Kreuzheben mit Trapbar", "Hyperextensions mit Glute Fokus":
            return .hinge
        case "Latziehen", "Rudern mit V-Griff", "Klimmzüge (mit Zusatzgewicht)", "Überzüge mit Kurzhantel":
            return .pull
        case "Kurzhantel über Kopf drücken, stehend":
            return .push
        case "Ab Wheel", "Pallof Rotations", "Hollow Body Hold", "Superman Hold":
            return .core
        case "Bulgarian Split Squats", "Beinbeuger", "Beinstrecker":
            return .lowerBody
        case "Lu Raises":
            return .upperBody
        default:
            return .unknown
        }
    }

    private func isUnilateral(_ exerciseName: String) -> Bool {
        exerciseName == "Bulgarian Split Squats"
    }

    private func usesBodyweight(_ exerciseName: String) -> Bool {
        ["Ab Wheel", "Hollow Body Hold", "Superman Hold", "Klimmzüge (mit Zusatzgewicht)"].contains(exerciseName)
    }
}

struct ChristianHemkerB1SeedFixture: Decodable {
    let source: String
    let trainingBlock: SeedTrainingBlock
}

struct SeedTrainingBlock: Decodable {
    let name: String
    let athleteName: String
    let goal: String
    let weeks: [SeedTrainingWeek]
}

struct SeedTrainingWeek: Decodable {
    let weekNumber: Int
    let title: String
    let days: [SeedTrainingDay]
}

struct SeedTrainingDay: Decodable {
    let dayNumber: Int
    let title: String
    let exercises: [SeedPlannedExercise]
}

struct SeedPlannedExercise: Decodable {
    let sortOrder: Int
    let name: String
    let cueing: String
    let tempo: String
    let sets: String
    let reps: String
    let plannedWeight: String
    let targetRIR: String
    let painTarget: String
    let notes: String
}
