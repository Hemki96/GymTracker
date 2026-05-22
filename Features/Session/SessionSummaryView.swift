import SwiftData
import SwiftUI

struct SessionSummaryView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var sessionLog: SessionLog

    @State private var noteText: String
    @State private var exportURL: URL?

    init(sessionLog: SessionLog) {
        self.sessionLog = sessionLog
        _noteText = State(initialValue: sessionLog.overallNotes ?? "")
    }

    private var exerciseLogs: [ExerciseLog] {
        sessionLog.exerciseLogs.sorted {
            ($0.plannedExercise?.sortOrder ?? 0) < ($1.plannedExercise?.sortOrder ?? 0)
        }
    }

    private var completedSetCount: Int {
        sessionLog.exerciseLogs.flatMap(\.setLogs).filter(\.isCompleted).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                header
                metricGrid
                noteSection
                warningsSection
                exerciseSection
            }
            .padding(AppTheme.Spacing.screen)
        }
        .appGroupedBackground()
        .navigationTitle("Session-Zusammenfassung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Exportieren", systemImage: "square.and.arrow.up")
                }
            }
        }
        .task {
            refreshExportURL()
        }
        .onChange(of: noteText) { _, newValue in
            saveNote(newValue)
            refreshExportURL()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sessionLog.workoutPlan?.title ?? "Training")
                .font(.largeTitle.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(dateLine)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryMetric(title: "Dauer", value: durationText, systemImage: "clock")
            summaryMetric(title: "Volumen", value: volumeText, systemImage: "scalemass")
            summaryMetric(title: "Ø RIR", value: averageRIRText, systemImage: "gauge.with.dots.needle.bottom.50percent")
            summaryMetric(title: "Max. Schmerz", value: maxPainText, systemImage: "cross.case")
            summaryMetric(title: "Saetze", value: "\(completedSetCount)", systemImage: "checkmark.circle")
            summaryMetric(title: "Warnungen", value: "\(sessionLog.warningMessages.count)", systemImage: "exclamationmark.triangle")
        }
    }

    private func summaryMetric(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session-Notiz")
                .font(.headline)

            TextField("Wie lief die Einheit?", text: $noteText, axis: .vertical)
                .lineLimit(4...8)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 96)
        }
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }

    @ViewBuilder
    private var warningsSection: some View {
        if sessionLog.warningMessages.isEmpty {
            Label("Keine Warnungen", systemImage: "checkmark.shield")
                .font(.headline)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.large)
                .appTintedCardSurface(.green)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label("Warnungen", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                ForEach(sessionLog.warningMessages, id: \.self) { warning in
                    Text(warning)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppTheme.Spacing.large)
            .appTintedCardSurface(.orange)
        }
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uebungen")
                .font(.headline)

            ForEach(exerciseLogs, id: \.id) { exerciseLog in
                ExerciseSummaryRow(exerciseLog: exerciseLog)
            }
        }
    }

    private var dateLine: String {
        let started = sessionLog.startedAt.formatted(date: .abbreviated, time: .shortened)
        guard let completedAt = sessionLog.completedAt else { return started }
        return "\(started) bis \(completedAt.formatted(date: .omitted, time: .shortened))"
    }

    private var durationText: String {
        guard let durationSeconds = sessionLog.durationSeconds else { return "-" }
        let minutes = durationSeconds / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours) h \(remainingMinutes) min" : "\(max(minutes, 1)) min"
    }

    private var volumeText: String {
        guard let totalVolumeKg = sessionLog.totalVolumeKg else { return "-" }
        return "\(totalVolumeKg.formatted(.number.precision(.fractionLength(0...1)))) kg"
    }

    private var averageRIRText: String {
        guard let averageRIR = sessionLog.averageRIR else { return "-" }
        return averageRIR.formatted(.number.precision(.fractionLength(0...1)))
    }

    private var maxPainText: String {
        guard let maxPain = sessionLog.maxPain else { return "-" }
        return "\(maxPain)/10"
    }

    private func saveNote(_ note: String) {
        sessionLog.overallNotes = note.trimmedNonEmpty
        sessionLog.updatedAt = .now
        try? modelContext.save()
    }

    private func refreshExportURL() {
        exportURL = try? TrainingExportService().fileURL(forSession: sessionLog)
    }
}

private struct ExerciseSummaryRow: View {
    let exerciseLog: ExerciseLog

    private var completedSets: [SetLog] {
        exerciseLog.setLogs
            .filter(\.isCompleted)
            .sorted { $0.setNumber < $1.setNumber }
    }

    private var volume: Double {
        VolumeCalculator().totalVolumeKg(from: completedSets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseLog.plannedExercise?.exercise?.name ?? "Unbekannte Uebung")
                .font(.headline)

            HStack(spacing: 10) {
                Label("\(completedSets.count) Saetze", systemImage: "checkmark.circle")
                Label("\(volume.formatted(.number.precision(.fractionLength(0...1)))) kg", systemImage: "scalemass")
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }
}

#if DEBUG
#Preview {
    let workout = WorkoutPlan(dayNumber: 1, title: "Tag 1", status: .completed, sortOrder: 1)
    let session = SessionLog(
        startedAt: Date(timeIntervalSince1970: 1_777_000_000),
        completedAt: Date(timeIntervalSince1970: 1_777_004_200),
        durationSeconds: 4_200,
        status: .completed,
        overallNotes: "Solide Einheit.",
        maxPain: 4,
        averageRIR: 1.5,
        totalVolumeKg: 2_480,
        warningMessages: [],
        workoutPlan: workout
    )

    NavigationStack {
        SessionSummaryView(sessionLog: session)
    }
}
#endif
