import SwiftData
import SwiftUI

@main
struct GymTrackerApp: App {
    private let environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            TabView {
                PlanView()
                    .tabItem {
                        Label("Plan", systemImage: "calendar")
                    }

                HistoryView()
                    .tabItem {
                        Label("Historie", systemImage: "clock.arrow.circlepath")
                    }

                AnalyticsView()
                    .tabItem {
                        Label("Analyse", systemImage: "chart.xyaxis.line")
                    }
            }
            .tabViewStyle(.sidebarAdaptable)
        }
        .modelContainer(environment.modelContainer)
    }
}
