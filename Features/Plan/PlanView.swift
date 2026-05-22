import SwiftData
import SwiftUI

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingBlock.createdAt) private var blocks: [TrainingBlock]
    @State private var selectedBlockID: UUID?
    @State private var selectedWeekNumber = 1
    @State private var blockExportURL: URL?
    @State private var errorMessage: String?

    private var visibleBlocks: [TrainingBlock] {
        blocks.sorted { $0.createdAt < $1.createdAt }
    }

    private var selectedBlock: TrainingBlock? {
        if let selectedBlockID,
           let block = visibleBlocks.first(where: { $0.id == selectedBlockID }) {
            return block
        }
        return visibleBlocks.first
    }

    private var visibleWeeks: [TrainingWeek] {
        Self.visibleWeeks(from: selectedBlock?.weeks ?? [])
    }

    private var selectedWeek: TrainingWeek? {
        visibleWeeks.first { $0.weekNumber == selectedWeekNumber } ?? visibleWeeks.first
    }

    private var workouts: [WorkoutPlan] {
        Self.visibleWorkouts(for: selectedWeek)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    planContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.screen)
            }
            .appGroupedBackground()
            .navigationTitle("Trainingsplan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    demoActionsMenu
                }

                ToolbarItem(placement: .topBarTrailing) {
                    exportButton
                }
            }
            .task {
                normalizeSelectedBlock()
                normalizeSelectedWeek()
                refreshBlockExportURL()
            }
            .onChange(of: visibleBlocks.map(\.id)) { _, _ in
                normalizeSelectedBlock()
                normalizeSelectedWeek()
                refreshBlockExportURL()
            }
            .onChange(of: selectedBlockID) { _, _ in
                normalizeSelectedWeek()
                refreshBlockExportURL()
            }
            .onChange(of: selectedWeekNumber) { _, _ in
                refreshBlockExportURL()
            }
            .onChange(of: visibleWeeks.map(\.weekNumber)) { _, _ in
                normalizeSelectedWeek()
                refreshBlockExportURL()
            }
            .alert("Aktion fehlgeschlagen", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var demoActionsMenu: some View {
        if selectedBlock?.isDemoPlan == true {
            Menu {
                Button {
                    duplicateDemoPlan()
                } label: {
                    Label("Als eigenen Plan duplizieren", systemImage: "plus.square.on.square")
                }

                Button(role: .destructive) {
                    deleteDemoPlan()
                } label: {
                    Label("Demo-Plan löschen", systemImage: "trash")
                }
            } label: {
                Label("Demo-Aktionen", systemImage: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var exportButton: some View {
        if let blockExportURL {
            ShareLink(item: blockExportURL) {
                Label("CSV exportieren", systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var planContent: some View {
        if visibleWeeks.isEmpty {
            emptyPlanState
        } else {
            planPicker

            WeekSelector(weeks: visibleWeeks, selectedWeekNumber: $selectedWeekNumber)
                .padding(.horizontal, -AppTheme.Spacing.screen)

            if let selectedWeek {
                weekHeader(selectedWeek)
                workoutLinks
            }
        }
    }

    private var emptyPlanState: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "Kein Plan vorhanden",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("Lege einen eigenen Plan an oder lade den Beispielplan.")
            )
            Button {
                loadDemoPlan()
            } label: {
                Label("Beispielplan laden", systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    @ViewBuilder
    private var planPicker: some View {
        if visibleBlocks.count > 1 {
            Menu {
                ForEach(visibleBlocks, id: \.id) { block in
                    Button {
                        selectedBlockID = block.id
                    } label: {
                        Label(block.name, systemImage: block.isDemoPlan ? "doc.badge.gearshape" : "doc.text")
                    }
                }
            } label: {
                Label(selectedBlock?.name ?? "Plan", systemImage: "doc.on.doc")
            }
        }
    }

    private func weekHeader(_ week: TrainingWeek) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(week.title)
                    .font(.title2.weight(.semibold))
                if selectedBlock?.isDemoPlan == true {
                    Label("Demo", systemImage: "doc.badge.gearshape")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Text(Self.trainingDaySummary(for: workouts))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var workoutLinks: some View {
        ForEach(workouts, id: \.id) { workout in
            NavigationLink {
                WorkoutDetailView(workout: workout)
            } label: {
                WorkoutDayCard(workout: workout)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadDemoPlan() {
        do {
            _ = try DemoDataService().loadBundledDemoPlan(into: modelContext)
            normalizeSelectedBlock()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteDemoPlan() {
        do {
            _ = try DemoDataService().deleteBundledDemoPlan(from: modelContext)
            selectedBlockID = nil
            normalizeSelectedBlock()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func duplicateDemoPlan() {
        guard let selectedBlock else { return }
        do {
            let copy = try DemoDataService().duplicateDemoPlan(selectedBlock, in: modelContext)
            selectedBlockID = copy.id
        } catch {
            errorMessage = error.localizedDescription
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

    private func normalizeSelectedBlock() {
        guard let firstBlock = visibleBlocks.first else {
            selectedBlockID = nil
            return
        }
        if selectedBlockID == nil || !visibleBlocks.contains(where: { $0.id == selectedBlockID }) {
            selectedBlockID = firstBlock.id
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
