import Foundation

struct PlanOverviewViewModel {
    struct Section: Identifiable {
        let id: BlockStatus
        let title: String
        let subtitle: String
        let systemImage: String
        let plans: [TrainingPlan]
    }

    let plans: [TrainingPlan]

    var isEmpty: Bool {
        plans.isEmpty
    }

    let emptyTitle = "Noch kein Trainingsplan"
    let emptyDescription = "Starte mit einem eigenen Plan, lade den Demo-Plan oder importiere eine vorhandene Planung."

    var activePlans: [TrainingPlan] {
        sortedPlans.filter { $0.status == .active || $0.status == .completed }
    }

    var draftPlans: [TrainingPlan] {
        sortedPlans.filter { $0.status == .planned }
    }

    var archivedPlans: [TrainingPlan] {
        sortedPlans.filter { $0.status == .archived }
    }

    var sections: [Section] {
        [
            Section(
                id: .active,
                title: "Aktive Pläne",
                subtitle: "Pläne, die gerade im Training genutzt werden.",
                systemImage: "bolt.circle",
                plans: activePlans
            ),
            Section(
                id: .planned,
                title: "Entwürfe",
                subtitle: "Vorbereitete Pläne, die noch nicht aktiv sind.",
                systemImage: "doc.text",
                plans: draftPlans
            ),
            Section(
                id: .archived,
                title: "Archivierte Pläne",
                subtitle: "Abgeschlossene oder abgelegte Trainingsphasen.",
                systemImage: "archivebox",
                plans: archivedPlans
            )
        ]
    }

    func badgeText(for plan: TrainingPlan) -> String {
        if plan.isDemoPlan {
            return "Demo"
        }

        switch plan.status {
        case .planned:
            return "Entwurf"
        case .active:
            return "Aktiv"
        case .completed:
            return "Abgeschlossen"
        case .archived:
            return "Archiv"
        }
    }

    private var sortedPlans: [TrainingPlan] {
        plans.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}

enum PlanDetailPresentation {
    static func visibleWeeks(from weeks: [TrainingWeek]) -> [TrainingWeek] {
        weeks.sorted { $0.weekNumber < $1.weekNumber }
    }

    static func visibleWorkouts(for week: TrainingWeek?) -> [WorkoutPlan] {
        week?.workoutPlans.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.dayNumber < rhs.dayNumber
            }
            return lhs.sortOrder < rhs.sortOrder
        } ?? []
    }

    static func trainingDaySummary(for workouts: [WorkoutPlan]) -> String {
        let count = workouts.count
        return count == 1 ? "1 Trainingstag" : "\(count) Trainingstage"
    }
}
