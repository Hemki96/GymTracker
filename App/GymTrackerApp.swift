import SwiftData
import SwiftUI

@main
struct GymTrackerApp: App {
    private let environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            PlanView()
        }
        .modelContainer(environment.modelContainer)
    }
}
