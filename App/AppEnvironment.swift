import SwiftData

struct AppEnvironment {
    let modelContainer: ModelContainer
    let makeDashboardViewModel: () -> DashboardViewModel

    static func live() -> AppEnvironment {
        let modelContainer = GymTrackerModelContainer.make()
        let context = ModelContext(modelContainer)
        _ = try? SeedDataService().importChristianHemkerB1IfNeeded(into: context)

        return AppEnvironment(
            modelContainer: modelContainer,
            makeDashboardViewModel: {
                DashboardViewModel(summary: .empty)
            }
        )
    }
}
