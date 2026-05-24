import SwiftData
import SwiftUI

struct DashboardView: View {
    // MARK: - Queries

    @Query(sort: \TrainingBlock.createdAt, order: .reverse) private var blocks: [TrainingBlock]
    @Query(sort: \SessionLog.startedAt, order: .reverse) private var sessions: [SessionLog]

    // MARK: - Properties

    private let injectedViewModel: DashboardViewModel?

    // MARK: - Lifecycle

    init(viewModel: DashboardViewModel? = nil) {
        self.injectedViewModel = viewModel
    }

    // MARK: - Derived State

    private var completedSessions: [SessionLog] {
        sessions.filter { $0.status == .completed }
    }

    private var activePlan: TrainingBlock? {
        blocks.first { $0.status == .active } ?? blocks.first { $0.status == .planned }
    }

    private var nextWorkout: WorkoutPlan? {
        // Dashboard chooses the first non-finished workout from the current plan
        // instead of requiring a separate scheduling table. The sort mirrors the
        // plan detail screen so both surfaces agree on what "next" means.
        activePlan?.weeks
            .sorted { $0.weekNumber < $1.weekNumber }
            .flatMap { week in
                week.workoutPlans.sorted {
                    if $0.sortOrder == $1.sortOrder { return $0.dayNumber < $1.dayNumber }
                    return $0.sortOrder < $1.sortOrder
                }
            }
            .first { $0.status != .completed && $0.status != .skipped }
    }

    private var lastSession: SessionLog? {
        completedSessions.first
    }

    private var weeklyVolume: Double {
        let calendar = Calendar.current
        return completedSessions
            .filter { calendar.isDate($0.completedAt ?? $0.startedAt, equalTo: .now, toGranularity: .weekOfYear) }
            .compactMap(\.totalVolumeKg)
            .reduce(0, +)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    ModernNavigationBar(
                        title: injectedViewModel?.title ?? "Dashboard",
                        subtitle: injectedViewModel?.subtitle ?? dashboardSubtitle,
                        systemImage: "figure.strengthtraining.traditional"
                    )

                    metricGrid
                    nextWorkoutCard
                    quickActions
                    recentActivity
                }
                .appScreenPadding()
            }
            .appGroupedBackground()
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - UI

    private var dashboardSubtitle: String {
        if let activePlan {
            return "Aktiver Fokus: \(activePlan.name)"
        }

        return "Starte mit einem Plan und baue deinen Trainingsrhythmus auf."
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.medium) {
            MetricCard(
                title: "Plaene",
                value: "\(blocks.count)",
                systemImage: "calendar",
                tint: .blue
            )
            MetricCard(
                title: "Sessions",
                value: "\(completedSessions.count)",
                systemImage: "checkmark.circle",
                tint: .green
            )
            MetricCard(
                title: "Wochenvolumen",
                value: weeklyVolumeText,
                systemImage: "scalemass",
                tint: .purple
            )
            MetricCard(
                title: "Letzte Dauer",
                value: lastDurationText,
                systemImage: "clock",
                tint: .orange
            )
        }
    }

    private var nextWorkoutCard: some View {
        DashboardCard(
            title: "Naechste Einheit",
            subtitle: nextWorkout == nil ? "Noch kein aktiver Trainingsfokus" : activePlan?.name,
            systemImage: "play.circle.fill"
        ) {
            if let nextWorkout {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(nextWorkout.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)

                    HStack(spacing: AppTheme.Spacing.medium) {
                        Label("Tag \(nextWorkout.dayNumber)", systemImage: "calendar.day.timeline.left")
                        if let duration = nextWorkout.plannedDurationMinutes {
                            Label("\(duration) min", systemImage: "clock")
                        }
                        Label("\(nextWorkout.plannedExercises.count) Uebungen", systemImage: "list.bullet.clipboard")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                    if let focus = nextWorkout.focus, !focus.isEmpty {
                        Text(focus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Text("Erstelle oder aktiviere einen Plan, damit hier automatisch die naechste Einheit erscheint.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickActions: some View {
        SectionContainer("Quick Actions", subtitle: "Die wichtigsten Einstiege ohne Umwege.", systemImage: "bolt") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.medium) {
                NavigationLink {
                    PlanView()
                } label: {
                    quickActionLabel("Plan oeffnen", systemImage: "calendar")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AnalyticsView()
                } label: {
                    quickActionLabel("Analyse", systemImage: "chart.xyaxis.line")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentActivity: some View {
        SectionContainer("Letzte Aktivitaet", subtitle: "Kurzueberblick ueber deinen letzten Abschluss.", systemImage: "clock.arrow.circlepath") {
            if let lastSession {
                AppCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(lastSession.workoutPlan?.title ?? "Training")
                            .font(.headline)

                        HStack(spacing: AppTheme.Spacing.medium) {
                            Label(lastSessionDateText, systemImage: "calendar")
                            Label(lastDurationText, systemImage: "clock")
                            Label(lastVolumeText, systemImage: "scalemass")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                }
            } else {
                EmptyStateView(
                    title: "Noch keine abgeschlossene Session",
                    message: "Sobald du eine Einheit abschliesst, landet sie mit Kennzahlen hier.",
                    systemImage: "checkmark.circle"
                )
            }
        }
    }

    private func quickActionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: systemImage)
                .frame(width: 28, height: 28)
                .appTintedCardSurface(AppTheme.ColorToken.primary)
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }

    // MARK: - Display

    private var weeklyVolumeText: String {
        guard weeklyVolume > 0 else { return "-" }
        return "\(weeklyVolume.formatted(.number.precision(.fractionLength(0...0)))) kg"
    }

    private var lastDurationText: String {
        guard let durationSeconds = lastSession?.durationSeconds else { return "-" }
        let minutes = max(durationSeconds / 60, 1)
        return "\(minutes) min"
    }

    private var lastVolumeText: String {
        guard let totalVolumeKg = lastSession?.totalVolumeKg else { return "-" }
        return "\(totalVolumeKg.formatted(.number.precision(.fractionLength(0...0)))) kg"
    }

    private var lastSessionDateText: String {
        guard let lastSession else { return "-" }
        return (lastSession.completedAt ?? lastSession.startedAt).formatted(date: .abbreviated, time: .shortened)
    }
}

#Preview {
    DashboardView()
        .modelContainer(PlanPreviewData.container)
}
