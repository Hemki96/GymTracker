import SwiftData
import SwiftUI

@main
struct GymTrackerApp: App {
    private let environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: environment.makeDashboardViewModel())
        }
        .modelContainer(environment.modelContainer)
    }
}
