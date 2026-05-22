import SwiftData

struct AppEnvironment {
    let modelContainer: ModelContainer
    let makeDashboardViewModel: () -> DashboardViewModel

    static func live() -> AppEnvironment {
        let modelContainer = GymTrackerModelContainer.make()

        return AppEnvironment(
            modelContainer: modelContainer,
            makeDashboardViewModel: {
                DashboardViewModel(summary: .empty)
            }
        )
    }
}
