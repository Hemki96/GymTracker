import SwiftData
import SwiftUI

@main
struct GymTrackerApp: App {
    private let startupState: StartupState

    init() {
        do {
            startupState = .ready(try AppEnvironment.live())
        } catch {
            startupState = .failed(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch startupState {
            case .ready(let environment):
                RootTabView()
                    .modelContainer(environment.modelContainer)
            case .failed(let message):
                StartupFailureView(message: message)
            }
        }
    }
}

private enum StartupState {
    case ready(AppEnvironment)
    case failed(String)
}

private struct RootTabView: View {
    var body: some View {
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
}

private struct StartupFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "App konnte nicht gestartet werden",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}
