import Foundation

struct DashboardSummary: Equatable {
    let title: String
    let subtitle: String

    static let empty = DashboardSummary(
        title: "Dashboard",
        subtitle: "Dein Trainingsueberblick entsteht hier."
    )
}
