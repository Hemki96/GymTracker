import SwiftData

enum PlanPreviewData {
    @MainActor
    static let container: ModelContainer = {
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

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            _ = try SeedDataService().importChristianHemkerB1IfNeeded(into: context)

            let workouts = try context.fetch(FetchDescriptor<WorkoutPlan>())
            workouts.first { $0.week?.weekNumber == 1 && $0.dayNumber == 1 }?.status = .completed
            workouts.first { $0.week?.weekNumber == 1 && $0.dayNumber == 2 }?.status = .planned
            try context.save()

            return container
        } catch {
            fatalError("Failed to create plan preview data: \(error)")
        }
    }()
}
