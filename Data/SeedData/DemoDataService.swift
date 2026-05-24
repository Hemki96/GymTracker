import Foundation
import SwiftData

struct DemoDataService {
    static let bundledDemoPlanIdentifier = "demo.trainingPlan.christianHemkerB1.v1"

    // MARK: - Properties

    private let seedDataService: SeedDataService

    // MARK: - Lifecycle

    init(seedDataService: SeedDataService = SeedDataService()) {
        self.seedDataService = seedDataService
    }

    // MARK: - Bundled Demo Plan

    func loadBundledDemoPlan(
        into context: ModelContext,
        bundle: Bundle = .main
    ) throws -> SeedDataService.ImportResult {
        try seedDataService.importSeedPlanIfNeeded(
            .bundledDemoPlan,
            into: context,
            bundle: bundle,
            isDemoPlan: true,
            demoSourceIdentifier: Self.bundledDemoPlanIdentifier
        )
    }

    @discardableResult
    func deleteBundledDemoPlan(from context: ModelContext) throws -> Int {
        // Demo deletion removes both imported blocks and their marker. That lets
        // users reset sample data and import it again without touching real plans.
        let plans = try bundledDemoPlans(in: context)
        for plan in plans {
            context.delete(plan)
        }

        let markerKey = SeedDataService.SeedPlanDescriptor.bundledDemoPlan.markerKey
        let markers = try context.fetch(
            FetchDescriptor<PersistentTrainingMarker>(
                predicate: #Predicate { $0.key == markerKey }
            )
        )
        for marker in markers {
            context.delete(marker)
        }

        try context.save()
        return plans.count
    }

    // MARK: - Copying

    func duplicateDemoPlan(
        _ demoPlan: TrainingPlan,
        name: String? = nil,
        in context: ModelContext
    ) throws -> TrainingPlan {
        let copy = TrainingPlan(
            name: name ?? "\(demoPlan.name) Kopie",
            athleteName: demoPlan.athleteName,
            goal: demoPlan.goal,
            startDate: demoPlan.startDate,
            endDate: demoPlan.endDate,
            status: demoPlan.status,
            isDemoPlan: false,
            demoSourceIdentifier: nil
        )

        // Copies are intentionally not marked as demo plans. They are editable
        // user-owned starting points derived from the bundled resource.
        for week in demoPlan.weeks.sorted(by: { $0.weekNumber < $1.weekNumber }) {
            let weekCopy = TrainingWeek(
                weekNumber: week.weekNumber,
                title: week.title,
                focus: week.focus,
                notes: week.notes
            )

            for workout in week.workoutPlans.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let workoutCopy = WorkoutPlan(
                    dayNumber: workout.dayNumber,
                    title: workout.title,
                    plannedDate: workout.plannedDate,
                    status: workout.status,
                    sortOrder: workout.sortOrder
                )

                for plannedExercise in workout.plannedExercises.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                    let plannedExerciseCopy = PlannedExercise(
                        sortOrder: plannedExercise.sortOrder,
                        cueing: plannedExercise.cueing,
                        tempo: plannedExercise.tempo,
                        setsPrescription: plannedExercise.setsPrescription,
                        repsPrescription: plannedExercise.repsPrescription,
                        plannedWeightText: plannedExercise.plannedWeightText,
                        targetRIRText: plannedExercise.targetRIRText,
                        painTargetText: plannedExercise.painTargetText,
                        notes: plannedExercise.notes,
                        exercise: plannedExercise.exercise
                    )
                    plannedExerciseCopy.plannedSets = plannedExercise.plannedSets
                        .sorted(by: { $0.setNumber < $1.setNumber })
                        .map { set in
                            PlannedSet(
                                setNumber: set.setNumber,
                                repsText: set.repsText,
                                weightText: set.weightText,
                                targetRIRText: set.targetRIRText,
                                painTargetText: set.painTargetText,
                                notes: set.notes,
                                isWarmup: set.isWarmup,
                                plannedExercise: plannedExerciseCopy
                            )
                        }
                    workoutCopy.plannedExercises.append(plannedExerciseCopy)
                }

                weekCopy.workoutPlans.append(workoutCopy)
            }

            copy.weeks.append(weekCopy)
        }

        context.insert(copy)
        try context.save()
        return copy
    }

    // MARK: - Queries

    private func bundledDemoPlans(in context: ModelContext) throws -> [TrainingPlan] {
        let demoIdentifier: String? = Self.bundledDemoPlanIdentifier
        return try context.fetch(
            FetchDescriptor<TrainingPlan>(
                predicate: #Predicate {
                    $0.isDemoPlan && $0.demoSourceIdentifier == demoIdentifier
                }
            )
        )
    }
}
