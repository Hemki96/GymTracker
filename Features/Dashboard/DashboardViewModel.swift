import Observation

@Observable
final class DashboardViewModel {
    private let summary: DashboardSummary

    var title: String {
        summary.title
    }

    var subtitle: String {
        summary.subtitle
    }

    init(summary: DashboardSummary) {
        self.summary = summary
    }
}
