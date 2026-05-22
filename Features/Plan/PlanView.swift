import SwiftData
import SwiftUI

struct PlanView: View {
    @Query(sort: \TrainingWeek.weekNumber) private var weeks: [TrainingWeek]
    @State private var selectedWeekNumber = 1
    @State private var blockExportURL: URL?

    private var visibleWeeks: [TrainingWeek] {
        weeks
            .filter { (1...6).contains($0.weekNumber) }
            .sorted { $0.weekNumber < $1.weekNumber }
    }

    private var selectedWeek: TrainingWeek? {
        visibleWeeks.first { $0.weekNumber == selectedWeekNumber } ?? visibleWeeks.first
    }

    private var selectedBlock: TrainingBlock? {
        selectedWeek?.block ?? visibleWeeks.compactMap(\.block).first
    }

    private var workouts: [WorkoutPlan] {
        selectedWeek?.workoutPlans
            .filter { (1...3).contains($0.dayNumber) }
            .sorted { $0.dayNumber < $1.dayNumber } ?? []
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
                                Text("Tag 1 bis Tag 3")
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
                refreshBlockExportURL()
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
}

#Preview {
    PlanView()
        .modelContainer(PlanPreviewData.container)
}
