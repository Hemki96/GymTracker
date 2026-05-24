import SwiftData
import SwiftUI

@main
struct GymTrackerApp: App {
    // The app builds its persistent environment synchronously at launch so every
    // root tab receives the same SwiftData container. Startup failures stay in
    // UI state instead of crashing, which keeps schema/container issues visible
    // during development and TestFlight installs.
    private let startupState: StartupState

    // MARK: - Lifecycle

    init() {
        do {
            startupState = .ready(try AppEnvironment.live())
        } catch {
            startupState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Scene

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
    // MARK: - Body

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

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

    // MARK: - Body

    var body: some View {
        ContentUnavailableView(
            "App konnte nicht gestartet werden",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}
