import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct PlanView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \TrainingBlock.createdAt) private var blocks: [TrainingBlock]

    // MARK: - State

    @State private var path: [UUID] = []
    @State private var errorMessage: String?
    @State private var isImporting = false
    @State private var pendingDeletion: TrainingPlan?

    // MARK: - Derived State

    private var viewModel: PlanOverviewViewModel {
        PlanOverviewViewModel(plans: blocks)
    }

    private var planActions: PlanActionService {
        PlanActionService(context: modelContext)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    overview
                }
            }
            .appGroupedBackground()
            .navigationTitle("Trainingspläne")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            createPlan()
                        } label: {
                            Label("Neuen Trainingsplan erstellen", systemImage: "plus")
                        }

                        Button {
                            loadDemoPlan()
                        } label: {
                            Label("Demo-Plan laden", systemImage: "tray.and.arrow.down")
                        }

                        Button {
                            isImporting = true
                        } label: {
                            Label("Trainingsplan importieren", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Plan hinzufügen", systemImage: "plus.circle")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { planID in
                PlanDetailView(selectedBlockID: planID)
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                importPlan(from: result)
            }
            .confirmationDialog(
                "Trainingsplan löschen?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                presenting: pendingDeletion
            ) { plan in
                Button("Plan löschen", role: .destructive) {
                    delete(plan)
                }
            } message: { plan in
                Text("\"\(plan.name)\" wird dauerhaft entfernt.")
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

    // MARK: - UI

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            EmptyStateView(
                title: viewModel.emptyTitle,
                message: viewModel.emptyDescription,
                systemImage: "figure.strengthtraining.traditional"
            )

            VStack(spacing: 12) {
                PrimaryButton(title: "Neuen Trainingsplan erstellen", systemImage: "plus") {
                    createPlan()
                }

                SecondaryButton(title: "Demo-Plan laden", systemImage: "tray.and.arrow.down") {
                    loadDemoPlan()
                }

                SecondaryButton(title: "Trainingsplan importieren", systemImage: "square.and.arrow.down") {
                    isImporting = true
                }
            }
            .controlSize(.large)
            .frame(maxWidth: 420)

            Spacer(minLength: 24)
        }
        .padding(AppTheme.Spacing.screen)
    }

    private var overview: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ModernNavigationBar(
                    title: "Trainingsplaene",
                    subtitle: "Waehle einen Plan zum Tracken aus oder bereite den naechsten Trainingsblock vor.",
                    systemImage: "calendar"
                )

                overviewMetrics

                ForEach(viewModel.sections) { section in
                    PlanOverviewSectionView(
                        section: section,
                        viewModel: viewModel,
                        open: { path.append($0.id) },
                        duplicate: duplicate,
                        archive: archive,
                        delete: { pendingDeletion = $0 }
                    )
                }
            }
            .appScreenPadding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var overviewMetrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.medium) {
            MetricCard(title: "Aktiv", value: "\(viewModel.activePlans.count)", systemImage: "bolt.circle", tint: .blue)
            MetricCard(title: "Entwuerfe", value: "\(viewModel.draftPlans.count)", systemImage: "doc.text", tint: .orange)
        }
    }

    // MARK: - Actions

    private func createPlan() {
        do {
            let plan = try planActions.createPlan()
            path.append(plan.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadDemoPlan() {
        do {
            if let demo = try planActions.loadDemoPlan(existingPlans: blocks) {
                path.append(demo.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importPlan(from result: Result<[URL], Error>) {
        // fileImporter returns security-scoped URLs. PlanActionService owns the
        // scoped access and import mapping so this view only coordinates routing
        // and user-visible errors.
        do {
            if let imported = try planActions.importPlan(from: result, existingPlans: blocks) {
                path.append(imported.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func duplicate(_ plan: TrainingPlan) {
        do {
            let copy = try planActions.duplicate(plan)
            path.append(copy.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func archive(_ plan: TrainingPlan) {
        do {
            try planActions.archive(plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ plan: TrainingPlan) {
        pendingDeletion = nil

        do {
            try planActions.delete(plan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Presentation Helpers

    static func visibleWeeks(from weeks: [TrainingWeek]) -> [TrainingWeek] {
        PlanDetailPresentation.visibleWeeks(from: weeks)
    }

    static func visibleWorkouts(for week: TrainingWeek?) -> [WorkoutPlan] {
        PlanDetailPresentation.visibleWorkouts(for: week)
    }

    static func trainingDaySummary(for workouts: [WorkoutPlan]) -> String {
        PlanDetailPresentation.trainingDaySummary(for: workouts)
    }
}

private struct PlanOverviewSectionView: View {
    // MARK: - Properties

    let section: PlanOverviewViewModel.Section
    let viewModel: PlanOverviewViewModel
    let open: (TrainingPlan) -> Void
    let duplicate: (TrainingPlan) -> Void
    let archive: (TrainingPlan) -> Void
    let delete: (TrainingPlan) -> Void

    // MARK: - Body

    var body: some View {
        SectionContainer(section.title, subtitle: section.subtitle, systemImage: section.systemImage) {
            if section.plans.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .appCardSurface()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(section.plans, id: \.id) { plan in
                        PlanOverviewRow(
                            plan: plan,
                            badgeText: viewModel.badgeText(for: plan),
                            open: { open(plan) },
                            duplicate: { duplicate(plan) },
                            archive: { archive(plan) },
                            delete: { delete(plan) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Display

    private var emptyText: String {
        switch section.id {
        case .active:
            "Keine aktiven Pläne."
        case .planned:
            "Keine Entwürfe."
        case .completed:
            "Keine abgeschlossenen Pläne."
        case .archived:
            "Keine archivierten Pläne."
        }
    }
}

private struct PlanOverviewRow: View {
    // MARK: - Properties

    let plan: TrainingPlan
    let badgeText: String
    let open: () -> Void
    let duplicate: () -> Void
    let archive: () -> Void
    let delete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Text(badgeText)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.tint.opacity(plan.isDemoPlan ? 0.16 : 0.10), in: Capsule())
                            .foregroundStyle(plan.isDemoPlan ? Color.accentColor : Color.secondary)
                    }

                    if !plan.goal.isEmpty {
                        Text(plan.goal)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 12) {
                        Label("\(plan.weeks.count) Wochen", systemImage: "calendar")
                        Label("\(workoutCount) Einheiten", systemImage: "dumbbell")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Menu {
                Button(action: open) {
                    Label("Plan öffnen", systemImage: "arrow.right.circle")
                }

                Button(action: duplicate) {
                    Label("Plan duplizieren", systemImage: "plus.square.on.square")
                }

                if plan.status != .archived {
                    Button(action: archive) {
                        Label("Plan archivieren", systemImage: "archivebox")
                    }
                }

                Button(role: .destructive, action: delete) {
                    Label("Plan löschen", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(16)
        .appCardSurface()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Display

    private var workoutCount: Int {
        plan.weeks.reduce(0) { $0 + $1.workoutPlans.count }
    }
}

private struct PlanDetailView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \TrainingBlock.createdAt) private var blocks: [TrainingBlock]

    // MARK: - Properties

    let selectedBlockID: UUID

    // MARK: - State

    @State private var selectedWeekNumber = 1
    @State private var blockExportURL: URL?
    @State private var errorMessage: String?
    @State private var isEditingPlan = false

    // MARK: - Derived State

    private var selectedBlock: TrainingBlock? {
        blocks.first { $0.id == selectedBlockID }
    }

    private var visibleWeeks: [TrainingWeek] {
        PlanDetailPresentation.visibleWeeks(from: selectedBlock?.weeks ?? [])
    }

    private var selectedWeek: TrainingWeek? {
        visibleWeeks.first { $0.weekNumber == selectedWeekNumber } ?? visibleWeeks.first
    }

    private var workouts: [WorkoutPlan] {
        PlanDetailPresentation.visibleWorkouts(for: selectedWeek)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                planContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.screen)
        }
        .appGroupedBackground()
        .navigationTitle(selectedBlock?.name ?? "Trainingsplan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditingPlan = true
                } label: {
                    Label("Plan bearbeiten", systemImage: "slider.horizontal.3")
                }
                .disabled(selectedBlock == nil)
            }

            ToolbarItem(placement: .topBarTrailing) {
                exportButton
            }
        }
        .sheet(isPresented: $isEditingPlan) {
            if let selectedBlock {
                NavigationStack {
                    TrainingPlanEditorView(plan: selectedBlock)
                }
            }
        }
        .task {
            normalizeSelectedWeek()
            refreshBlockExportURL()
        }
        .onChange(of: selectedBlock?.id) { _, _ in
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

    // MARK: - UI

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
        if let selectedBlock, visibleWeeks.isEmpty {
            emptyPlanDetailState(for: selectedBlock)
        } else if selectedBlock == nil {
            ContentUnavailableView(
                "Plan nicht gefunden",
                systemImage: "exclamationmark.triangle",
                description: Text("Der ausgewählte Trainingsplan ist nicht mehr vorhanden.")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            if let selectedBlock {
                planHeader(selectedBlock)
            }

            WeekSelector(weeks: visibleWeeks, selectedWeekNumber: $selectedWeekNumber)
                .padding(.horizontal, -AppTheme.Spacing.screen)

            if let selectedWeek {
                weekHeader(selectedWeek)
                workoutLinks
            }
        }
    }

    private func planHeader(_ block: TrainingBlock) -> some View {
        DashboardCard(
            title: block.name,
            subtitle: block.goal.isEmpty ? nil : block.goal,
            systemImage: "calendar.badge.clock"
        ) {
            HStack(spacing: AppTheme.Spacing.small) {
                AppStatusPill(
                    title: block.status == .planned ? "Entwurf" : block.status.rawValue.capitalized,
                    systemImage: nil,
                    tint: block.status == .active ? .green : .secondary
                )

                if block.isDemoPlan {
                    AppStatusPill(title: "Demo", systemImage: "doc.badge.gearshape", tint: AppTheme.ColorToken.primary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.medium) {
                compactHeaderMetric(title: "Wochen", value: "\(visibleWeeks.count)")
                compactHeaderMetric(title: "Trainingstage", value: "\(workouts.count)")
            }

            if let description = block.descriptionText, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func compactHeaderMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .appControlSurface()
    }

    private func emptyPlanDetailState(for block: TrainingBlock) -> some View {
        ContentUnavailableView(
            "\(block.name) ist noch leer",
            systemImage: "calendar.badge.plus",
            description: Text("Füge Wochen und Trainingstage hinzu, um mit diesem Plan zu arbeiten.")
        )
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private func weekHeader(_ week: TrainingWeek) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(week.title)
                .font(.title2.weight(.semibold))
            Text(PlanDetailPresentation.trainingDaySummary(for: workouts))
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

    // MARK: - Export

    private func refreshBlockExportURL() {
        guard let selectedBlock else {
            blockExportURL = nil
            return
        }

        blockExportURL = try? TrainingExportService().fileURL(forBlock: selectedBlock)
    }

    // MARK: - Selection

    private func normalizeSelectedWeek() {
        // Plan edits can remove or renumber weeks while this detail screen is
        // visible. Normalizing keeps the WeekSelector bound to an existing week
        // instead of leaving the UI on an empty stale selection.
        guard let firstWeek = visibleWeeks.first else { return }
        if !visibleWeeks.contains(where: { $0.weekNumber == selectedWeekNumber }) {
            selectedWeekNumber = firstWeek.weekNumber
        }
    }

}

#Preview("Empty State") {
    PlanView()
        .modelContainer(PlanPreviewData.emptyContainer)
}

#Preview("Planübersicht") {
    PlanView()
        .modelContainer(PlanPreviewData.container)
}
