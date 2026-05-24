import SwiftData

enum GymTrackerModelContainer {
    // MARK: - Factory

    // App, previews, and tests should all build containers from the same schema
    // list. Keeping it here avoids subtle drift when SwiftData model types change.
    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = makeSchema()
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    // MARK: - Schema

    private static func makeSchema() -> Schema {
        Schema([
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
    }
}
