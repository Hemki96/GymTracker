import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingBlock.createdAt) private var blocks: [TrainingBlock]
    @State private var path: [UUID] = []
    @State private var errorMessage: String?
    @State private var isImporting = false
    @State private var pendingDeletion: TrainingPlan?

    private var viewModel: PlanOverviewViewModel {
        PlanOverviewViewModel(plans: blocks)
    }

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

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            ContentUnavailableView {
                Label(viewModel.emptyTitle, systemImage: "figure.strengthtraining.traditional")
            } description: {
                Text(viewModel.emptyDescription)
            }

            VStack(spacing: 12) {
                Button {
                    createPlan()
                } label: {
                    Label("Neuen Trainingsplan erstellen", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    loadDemoPlan()
                } label: {
                    Label("Demo-Plan laden", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    isImporting = true
                } label: {
                    Label("Trainingsplan importieren", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
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
                overviewHeader

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
            .padding(AppTheme.Spacing.screen)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var overviewHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deine Trainingspläne")
                .font(.title2.weight(.semibold))
            Text("Wähle einen Plan zum Tracken aus oder bereite den nächsten Trainingsblock vor.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func createPlan() {
        let plan = TrainingPlan(
            name: "Neuer Trainingsplan",
            goal: "",
            status: .planned
        )
        modelContext.insert(plan)

        do {
            try modelContext.save()
            path.append(plan.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadDemoPlan() {
        do {
            let knownIDs = Set(blocks.map(\.id))
            _ = try DemoDataService().loadBundledDemoPlan(into: modelContext)
            if let demo = newestPlan(excluding: knownIDs) ?? blocks.first(where: { $0.isDemoPlan }) {
                path.append(demo.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importPlan(from result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let knownIDs = Set(blocks.map(\.id))
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            _ = try SeedDataService().importSeedPlan(from: url, into: modelContext)
            if let imported = newestPlan(excluding: knownIDs) {
                path.append(imported.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func duplicate(_ plan: TrainingPlan) {
        do {
            let copy = try DemoDataService().duplicateDemoPlan(plan, name: "\(plan.name) Kopie", in: modelContext)
            path.append(copy.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func archive(_ plan: TrainingPlan) {
        plan.status = .archived
        plan.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ plan: TrainingPlan) {
        modelContext.delete(plan)
        pendingDeletion = nil

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func newestPlan(excluding knownIDs: Set<UUID>) -> TrainingPlan? {
        blocks
            .filter { !knownIDs.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

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
    let section: PlanOverviewViewModel.Section
    let viewModel: PlanOverviewViewModel
    let open: (TrainingPlan) -> Void
    let duplicate: (TrainingPlan) -> Void
    let archive: (TrainingPlan) -> Void
    let delete: (TrainingPlan) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: section.systemImage)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.headline)
                    Text(section.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

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
    let plan: TrainingPlan
    let badgeText: String
    let open: () -> Void
    let duplicate: () -> Void
    let archive: () -> Void
    let delete: () -> Void

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
    }

    private var workoutCount: Int {
        plan.weeks.reduce(0) { $0 + $1.workoutPlans.count }
    }
}

private struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingBlock.createdAt) private var blocks: [TrainingBlock]
    let selectedBlockID: UUID
    @State private var selectedWeekNumber = 1
    @State private var blockExportURL: URL?
    @State private var errorMessage: String?
    @State private var isEditingPlan = false

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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(block.status == .planned ? "Entwurf" : block.status.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if block.isDemoPlan {
                    Label("Demo", systemImage: "doc.badge.gearshape")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }

            if !block.goal.isEmpty {
                Text(block.goal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let description = block.descriptionText, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
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

}

#Preview("Empty State") {
    PlanView()
        .modelContainer(PlanPreviewData.emptyContainer)
}

#Preview("Planübersicht") {
    PlanView()
        .modelContainer(PlanPreviewData.container)
}
