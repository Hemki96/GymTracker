import SwiftData

struct AppEnvironment {
    let modelContainer: ModelContainer
    let makeDashboardViewModel: () -> DashboardViewModel

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
