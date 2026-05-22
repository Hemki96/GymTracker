import Foundation
import SwiftData

struct SeedDataService {
    enum SeedError: Error, Equatable {
        case missingResource(String)
        case invalidFixture(String)
    }

    struct SeedPlanDescriptor: Equatable {
        let markerKey: String
        let resourceName: String

        static let bundledDemoPlan = SeedPlanDescriptor(
            markerKey: "seed.trainingPlan.christianHemkerB1.v1",
            resourceName: "seed_christian_b1_plan"
        )
    }

    struct ImportResult: Equatable {
        let didImport: Bool
        let weeks: Int
        let sessions: Int
        let exerciseRows: Int
    }

    func importDemoPlanIfNeeded(
        into context: ModelContext,
        bundle: Bundle = .main
    ) throws -> ImportResult {
        try importSeedPlanIfNeeded(
            .bundledDemoPlan,
            into: context,
            bundle: bundle,
            isDemoPlan: true,
            demoSourceIdentifier: DemoDataService.bundledDemoPlanIdentifier
        )
    }

    func importSeedPlanIfNeeded(
        _ descriptor: SeedPlanDescriptor,
        into context: ModelContext,
        bundle: Bundle = .main,
        isDemoPlan: Bool = false,
        demoSourceIdentifier: String? = nil
    ) throws -> ImportResult {
        let markerKey = descriptor.markerKey
        let existingMarker = try context.fetch(
            FetchDescriptor<PersistentTrainingMarker>(
                predicate: #Predicate { $0.key == markerKey }
            )
        ).first

        let fixture = try loadSeedFixture(resourceName: descriptor.resourceName, from: bundle)
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
            goal: blockFixture.goal,
            isDemoPlan: isDemoPlan,
            demoSourceIdentifier: demoSourceIdentifier
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
                    plannedExercise.plannedSets = makePlannedSets(
                        from: exerciseFixture,
                        for: plannedExercise
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
        context.insert(PersistentTrainingMarker(key: markerKey))

        try context.save()

        return ImportResult(
            didImport: true,
            weeks: summary.weeks,
            sessions: summary.sessions,
            exerciseRows: summary.exerciseRows
        )
    }

    func loadDemoFixture(from bundle: Bundle = .main) throws -> SeedTrainingFixture {
        try loadSeedFixture(resourceName: SeedPlanDescriptor.bundledDemoPlan.resourceName, from: bundle)
    }

    func loadSeedFixture(resourceName: String, from bundle: Bundle = .main) throws -> SeedTrainingFixture {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw SeedError.missingResource("\(resourceName).json")
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SeedTrainingFixture.self, from: data)
    }

    @discardableResult
    func validate(_ fixture: SeedTrainingFixture) throws -> ImportResult {
        guard !fixture.trainingBlock.name.trimmedNonEmpty.isNilOrEmpty else {
            throw SeedError.invalidFixture("Training block name is required.")
        }
        guard !fixture.trainingBlock.weeks.isEmpty else {
            throw SeedError.invalidFixture("At least one training week is required.")
        }

        let weeks = fixture.trainingBlock.weeks.count
        let sessions = fixture.trainingBlock.weeks.reduce(0) { $0 + $1.days.count }
        let exerciseRows = fixture.trainingBlock.weeks.reduce(0) { weekTotal, week in
            weekTotal + week.days.reduce(0) { $0 + $1.exercises.count }
        }

        guard sessions > 0 else {
            throw SeedError.invalidFixture("At least one workout day is required.")
        }
        guard exerciseRows > 0 else {
            throw SeedError.invalidFixture("At least one planned exercise is required.")
        }

        for week in fixture.trainingBlock.weeks {
            guard week.weekNumber > 0 else {
                throw SeedError.invalidFixture("Week numbers must be positive.")
            }
            guard !week.days.isEmpty else {
                throw SeedError.invalidFixture("Week \(week.weekNumber) must contain at least one workout day.")
            }

            for day in week.days {
                guard day.dayNumber > 0 else {
                    throw SeedError.invalidFixture("Day numbers must be positive.")
                }
                guard !day.exercises.isEmpty else {
                    throw SeedError.invalidFixture("Week \(week.weekNumber), day \(day.dayNumber) must contain at least one exercise.")
                }

                for exercise in day.exercises {
                    guard exercise.sortOrder > 0 else {
                        throw SeedError.invalidFixture("Exercise sort order must be positive.")
                    }
                    guard !exercise.name.trimmedNonEmpty.isNilOrEmpty else {
                        throw SeedError.invalidFixture("Exercise name is required.")
                    }
                    guard !exercise.sets.trimmedNonEmpty.isNilOrEmpty else {
                        throw SeedError.invalidFixture("Sets prescription is required.")
                    }
                    guard !exercise.reps.trimmedNonEmpty.isNilOrEmpty else {
                        throw SeedError.invalidFixture("Reps prescription is required.")
                    }
                }
            }
        }

        return ImportResult(didImport: false, weeks: weeks, sessions: sessions, exerciseRows: exerciseRows)
    }

    private func normalizedOptional(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
    }

    private func makePlannedSets(
        from exercise: SeedPlannedExercise,
        for plannedExercise: PlannedExercise
    ) -> [PlannedSet] {
        (1...plannedSetCount(from: exercise.sets)).map { setNumber in
            PlannedSet(
                setNumber: setNumber,
                repsText: normalizedOptional(exercise.reps),
                weightText: normalizedOptional(exercise.plannedWeight),
                targetRIRText: normalizedOptional(exercise.targetRIR),
                painTargetText: normalizedOptional(exercise.painTarget),
                plannedExercise: plannedExercise
            )
        }
    }

    private func plannedSetCount(from prescription: String) -> Int {
        let firstNumber = prescription
            .split { !$0.isNumber }
            .first
            .flatMap { Int($0) }

        return max(firstNumber ?? 1, 1)
    }

    private func category(for _: String) -> ExerciseCategory {
        .unknown
    }

    private func isUnilateral(_: String) -> Bool {
        false
    }

    private func usesBodyweight(_: String) -> Bool {
        false
    }
}

private extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

struct SeedTrainingFixture: Decodable {
    let source: String
    let trainingBlock: SeedTrainingBlock
}

struct SeedTrainingBlock: Decodable {
    let name: String
    let athleteName: String?
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
