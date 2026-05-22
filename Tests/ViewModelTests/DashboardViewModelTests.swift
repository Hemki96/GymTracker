import Testing
@testable import GymTracker

struct DashboardViewModelTests {
    @Test
    func exposesEmptyDashboardSummary() {
        let viewModel = DashboardViewModel(summary: .empty)

        #expect(viewModel.title == "Dashboard")
        #expect(viewModel.subtitle == "Dein Trainingsueberblick entsteht hier.")
    }
}
