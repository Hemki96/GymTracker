import SwiftData
import SwiftUI

struct PlanView: View {
    @Query(sort: \TrainingWeek.weekNumber) private var weeks: [TrainingWeek]
    @State private var selectedWeekNumber = 1
    @State private var blockExportURL: URL?

    private var visibleWeeks: [TrainingWeek] {
        Self.visibleWeeks(from: weeks)
    }

    private var selectedWeek: TrainingWeek? {
        visibleWeeks.first { $0.weekNumber == selectedWeekNumber } ?? visibleWeeks.first
    }

    private var selectedBlock: TrainingBlock? {
        selectedWeek?.block ?? visibleWeeks.compactMap(\.block).first
    }

    private var workouts: [WorkoutPlan] {
        Self.visibleWorkouts(for: selectedWeek)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    if visibleWeeks.isEmpty {
                        ContentUnavailableView(
                            "Kein Plan vorhanden",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("Der Trainingsplan wurde noch nicht importiert.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 320)
                    } else {
                        WeekSelector(weeks: visibleWeeks, selectedWeekNumber: $selectedWeekNumber)
                            .padding(.horizontal, -AppTheme.Spacing.screen)

                        if let selectedWeek {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(selectedWeek.title)
                                    .font(.title2.weight(.semibold))
                                Text(Self.trainingDaySummary(for: workouts))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(workouts, id: \.id) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutDayCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.screen)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trainingsplan")
            .toolbar {
                if let blockExportURL {
                    ShareLink(item: blockExportURL) {
                        Label("CSV exportieren", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .task {
                normalizeSelectedWeek()
                refreshBlockExportURL()
            }
            .onChange(of: visibleWeeks.map(\.weekNumber)) { _, _ in
                normalizeSelectedWeek()
            }
            .onChange(of: selectedWeekNumber) { _, _ in
                refreshBlockExportURL()
            }
            .onChange(of: weeks.count) { _, _ in
                refreshBlockExportURL()
            }
        }
    }

    private func refreshBlockExportURL() {
        guard let selectedBlock else {
            blockExportURL = nil
            return
        }

        blockExportURL = try? TrainingExportService().fileURL(forBlock: selectedBlock)
    }

    private func normalizeSelectedWeek() {
        guard let firstWeek = visibleWeeks.first else { return }
        if !visibleWeeks.contains(where: { $0.weekNumber == selectedWeekNumber }) {
            selectedWeekNumber = firstWeek.weekNumber
        }
    }

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

#Preview {
    PlanView()
        .modelContainer(PlanPreviewData.container)
}
