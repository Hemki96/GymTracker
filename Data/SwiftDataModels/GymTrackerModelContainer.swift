import SwiftData

enum GymTrackerModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([
            PersistentTrainingMarker.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create GymTracker SwiftData container: \(error)")
        }
    }
}
