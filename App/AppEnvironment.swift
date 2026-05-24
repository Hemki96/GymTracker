import SwiftData

struct AppEnvironment {
    let modelContainer: ModelContainer
    let makeDashboardViewModel: () -> DashboardViewModel

    // MARK: - Factories

    // Centralizing environment creation keeps SwiftData setup and future service
    // wiring out of view code. Tests and previews can replace this with an
    // in-memory container without touching the feature modules.
    static func live() throws -> AppEnvironment {
        let modelContainer = try GymTrackerModelContainer.make()

        return AppEnvironment(
            modelContainer: modelContainer,
            makeDashboardViewModel: {
                DashboardViewModel(summary: .empty)
            }
        )
    }
}
