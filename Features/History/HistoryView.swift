import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(
        filter: #Predicate<SessionLog> { session in
            session.statusRaw == "completed"
        },
        sort: \SessionLog.completedAt,
        order: .reverse
    ) private var completedSessions: [SessionLog]

    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    ContentUnavailableView(
                        "Keine Historie",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Abgeschlossene Sessions erscheinen hier.")
                    )
                } else {
                    List(completedSessions, id: \.id) { session in
                        NavigationLink {
                            SessionHistoryDetailView(sessionLog: session)
                        } label: {
                            HistorySessionRow(sessionLog: session)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Historie")
        }
    }
}

struct SessionHistoryDetailView: View {
    let sessionLog: SessionLog
    @State private var exportURL: URL?

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
                notesSection
                warningsSection
                exercisesSection
            }
            .padding(AppTheme.Spacing.screen)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sessiondetails")
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
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HistoryMetricCard(title: "Dauer", value: durationText, systemImage: "clock")
            HistoryMetricCard(title: "Volumen", value: volumeText, systemImage: "scalemass")
            HistoryMetricCard(title: "Ø RIR", value: averageRIRText, systemImage: "gauge.with.dots.needle.bottom.50percent")
            HistoryMetricCard(title: "Max. Schmerz", value: maxPainText, systemImage: "cross.case")
            HistoryMetricCard(title: "Saetze", value: "\(completedSetCount)", systemImage: "checkmark.circle")
            HistoryMetricCard(title: "Warnungen", value: "\(sessionLog.warningMessages.count)", systemImage: "exclamationmark.triangle")
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if let overallNotes = sessionLog.overallNotes, !overallNotes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Session-Notiz")
                    .font(.headline)

                Text(overallNotes)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppTheme.Spacing.large)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
        }
    }

    @ViewBuilder
    private var warningsSection: some View {
        if sessionLog.warningMessages.isEmpty {
            EmptyView()
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
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.12))
            }
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uebungen")
                .font(.headline)

            ForEach(exerciseLogs, id: \.id) { exerciseLog in
                if let exercise = exerciseLog.plannedExercise?.exercise {
                    NavigationLink {
                        ExerciseProgressView(exercise: exercise)
                    } label: {
                        SessionExerciseHistoryRow(exerciseLog: exerciseLog, showsDisclosure: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    SessionExerciseHistoryRow(exerciseLog: exerciseLog, showsDisclosure: false)
                }
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
        return "\(HistoryFormatters.decimal(totalVolumeKg)) kg"
    }

    private var averageRIRText: String {
        guard let averageRIR = sessionLog.averageRIR else { return "-" }
        return HistoryFormatters.decimal(averageRIR)
    }

    private var maxPainText: String {
        guard let maxPain = sessionLog.maxPain else { return "-" }
        return "\(maxPain)/10"
    }

    private func refreshExportURL() {
        exportURL = try? TrainingExportService().fileURL(forSession: sessionLog)
    }
}

struct ExerciseProgressView: View {
    let exercise: Exercise

    @Query(
        filter: #Predicate<SessionLog> { session in
            session.statusRaw == "completed"
        },
        sort: \SessionLog.completedAt,
        order: .reverse
    ) private var completedSessions: [SessionLog]

    private var entries: [ExerciseProgressEntry] {
        ExerciseProgressCalculator.entries(for: exercise, in: completedSessions)
    }

    private var bests: ExerciseProgressBests {
        ExerciseProgressCalculator.bests(from: entries)
    }

    private var latestEntry: ExerciseProgressEntry? {
        entries.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                header

                if entries.isEmpty {
                    ContentUnavailableView(
                        "Keine Übungshistorie",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Abgeschlossene Saetze fuer diese Übung erscheinen hier.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    latestSection
                    bestsSection
                    progressionSection
                }
            }
            .padding(AppTheme.Spacing.screen)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Übungsdetails")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text("\(entries.count) abgeschlossene Einheiten")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.large)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    @ViewBuilder
    private var latestSection: some View {
        if let latestEntry {
            VStack(alignment: .leading, spacing: 12) {
                Text("Letzte Werte")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    HistoryMetricCard(title: "Top-Satz", value: latestEntry.bestSetText, systemImage: "dumbbell")
                    HistoryMetricCard(title: "Volumen", value: "\(HistoryFormatters.decimal(latestEntry.volumeKg)) kg", systemImage: "scalemass")
                    HistoryMetricCard(title: "Ø RIR", value: latestEntry.averageRIRText, systemImage: "gauge.with.dots.needle.bottom.50percent")
                    HistoryMetricCard(title: "Max. Schmerz", value: latestEntry.maxPainText, systemImage: "cross.case")
                }

                if !latestEntry.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notizen")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(latestEntry.notes, id: \.self) { note in
                            Text(note)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.large)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
        }
    }

    private var bestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bestwerte")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HistoryMetricCard(title: "Gewicht", value: bests.maxWeightText, systemImage: "dumbbell")
                HistoryMetricCard(title: "Reps", value: bests.maxRepsText, systemImage: "number")
                HistoryMetricCard(title: "Satzvolumen", value: bests.maxSetVolumeText, systemImage: "chart.bar.fill")
                HistoryMetricCard(title: "Sessionvolumen", value: bests.maxSessionVolumeText, systemImage: "scalemass")
            }
        }
    }

    private var progressionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verlauf")
                .font(.headline)

            ForEach(entries, id: \.id) { entry in
                ExerciseProgressEntryRow(entry: entry)
            }
        }
    }
}

private struct HistorySessionRow: View {
    let sessionLog: SessionLog

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(sessionLog.workoutPlan?.title ?? "Training")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(dateText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label(durationText, systemImage: "clock")
                Label(volumeText, systemImage: "scalemass")
                Label(warningText, systemImage: "exclamationmark.triangle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var dateText: String {
        (sessionLog.completedAt ?? sessionLog.startedAt).formatted(date: .abbreviated, time: .shortened)
    }

    private var durationText: String {
        guard let durationSeconds = sessionLog.durationSeconds else { return "-" }
        return "\(max(durationSeconds / 60, 1)) min"
    }

    private var volumeText: String {
        guard let totalVolumeKg = sessionLog.totalVolumeKg else { return "-" }
        return "\(totalVolumeKg.formatted(.number.precision(.fractionLength(0...0)))) kg"
    }

    private var warningText: String {
        "\(sessionLog.warningMessages.count)"
    }
}

private struct SessionExerciseHistoryRow: View {
    let exerciseLog: ExerciseLog
    let showsDisclosure: Bool

    private var completedSets: [SetLog] {
        exerciseLog.setLogs
            .filter(\.isCompleted)
            .sorted { $0.setNumber < $1.setNumber }
    }

    private var volume: Double {
        VolumeCalculator().totalVolumeKg(from: completedSets)
    }

    private var bestSetText: String {
        let bestSet = completedSets.max {
            setStrengthValue($0) < setStrengthValue($1)
        }

        guard let bestSet else { return "-" }
        return HistoryFormatters.setText(bestSet)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseLog.plannedExercise?.exercise?.name ?? "Unbekannte Uebung")
                        .font(.headline)
                        .lineLimit(2)

                    Text(planSummary)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                CompactHistoryValue(title: "Saetze", value: "\(completedSets.count)")
                CompactHistoryValue(title: "Top-Satz", value: bestSetText)
                CompactHistoryValue(title: "Volumen", value: "\(HistoryFormatters.decimal(volume)) kg")
                CompactHistoryValue(title: "Notizen", value: notesSummary)
            }

            if !setRows.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(setRows, id: \.self) { row in
                        Text(row)
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    private var setRows: [String] {
        completedSets.map { setLog in
            "Satz \(setLog.setNumber): \(HistoryFormatters.setText(setLog)), RIR \(HistoryFormatters.optionalDecimal(setLog.rir)), Schmerz \(HistoryFormatters.optionalPain(setLog.pain))"
        }
    }

    private var notesSummary: String {
        let notes = ([exerciseLog.plannedExercise?.notes, exerciseLog.notes] + completedSets.map(\.notes))
            .compactMap { $0?.trimmedNonEmpty }
        return notes.isEmpty ? "-" : notes.joined(separator: " / ")
    }

    private var planSummary: String {
        guard let plannedExercise = exerciseLog.plannedExercise else { return "Keine Planvorgabe" }

        let parts = [
            "\(plannedExercise.setsPrescription) Saetze",
            "\(plannedExercise.repsPrescription) Wdh.",
            plannedExercise.plannedWeightText.map { "\($0) kg" },
            plannedExercise.targetRIRText.map { "RIR \($0)" },
            plannedExercise.painTargetText.map { "Schmerz \($0)" }
        ].compactMap(\.self)

        return parts.joined(separator: " · ")
    }

    private func setStrengthValue(_ setLog: SetLog) -> Double {
        let weight = setLog.loggedWeightKg ?? 0
        let reps = Double(setLog.loggedReps ?? 0)
        return weight * max(reps, 1)
    }
}

private struct ExerciseProgressEntryRow: View {
    let entry: ExerciseProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(entry.dateText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(HistoryFormatters.decimal(entry.volumeKg)) kg")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                CompactHistoryValue(title: "Top-Satz", value: entry.bestSetText)
                CompactHistoryValue(title: "Saetze", value: "\(entry.sets.count)")
                CompactHistoryValue(title: "Ø RIR", value: entry.averageRIRText)
                CompactHistoryValue(title: "Max. Schmerz", value: entry.maxPainText)
            }

            if !entry.notes.isEmpty {
                ForEach(entry.notes, id: \.self) { note in
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

private struct HistoryMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(AppTheme.Spacing.large)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

private struct CompactHistoryValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }
}

private struct ExerciseProgressEntry: Identifiable {
    let id: UUID
    let title: String
    let completedAt: Date
    let sets: [SetLog]
    let notes: [String]

    var dateText: String {
        completedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var volumeKg: Double {
        VolumeCalculator().totalVolumeKg(from: sets)
    }

    var bestSetText: String {
        guard let set = sets.max(by: { setStrengthValue($0) < setStrengthValue($1) }) else {
            return "-"
        }

        return HistoryFormatters.setText(set)
    }

    var averageRIRText: String {
        let values = sets.compactMap(\.rir)
        guard !values.isEmpty else { return "-" }
        return HistoryFormatters.decimal(values.reduce(0, +) / Double(values.count))
    }

    var maxPainText: String {
        guard let maxPain = sets.compactMap(\.pain).max() else { return "-" }
        return "\(maxPain)/10"
    }

    private func setStrengthValue(_ setLog: SetLog) -> Double {
        let weight = setLog.loggedWeightKg ?? 0
        let reps = Double(setLog.loggedReps ?? 0)
        return weight * max(reps, 1)
    }
}

private struct ExerciseProgressBests {
    let maxWeight: Double?
    let maxReps: Int?
    let maxSetVolume: Double?
    let maxSessionVolume: Double?

    var maxWeightText: String {
        guard let maxWeight else { return "-" }
        return "\(HistoryFormatters.decimal(maxWeight)) kg"
    }

    var maxRepsText: String {
        guard let maxReps else { return "-" }
        return "\(maxReps)"
    }

    var maxSetVolumeText: String {
        guard let maxSetVolume else { return "-" }
        return "\(HistoryFormatters.decimal(maxSetVolume)) kg"
    }

    var maxSessionVolumeText: String {
        guard let maxSessionVolume else { return "-" }
        return "\(HistoryFormatters.decimal(maxSessionVolume)) kg"
    }
}

private enum ExerciseProgressCalculator {
    static func entries(for exercise: Exercise, in sessions: [SessionLog]) -> [ExerciseProgressEntry] {
        sessions.compactMap { session in
            let matchingLogs = session.exerciseLogs.filter { exerciseLog in
                exerciseLog.plannedExercise?.exercise?.id == exercise.id
            }

            let completedSets = matchingLogs
                .flatMap(\.setLogs)
                .filter(\.isCompleted)
                .sorted { $0.setNumber < $1.setNumber }

            guard !completedSets.isEmpty else { return nil }

            let notes = matchingLogs
                .flatMap { exerciseLog in
                    [exerciseLog.notes] + exerciseLog.setLogs.map(\.notes)
                }
                .compactMap { $0?.trimmedNonEmpty }

            return ExerciseProgressEntry(
                id: session.id,
                title: session.workoutPlan?.title ?? "Training",
                completedAt: session.completedAt ?? session.startedAt,
                sets: completedSets,
                notes: notes
            )
        }
        .sorted { $0.completedAt > $1.completedAt }
    }

    static func bests(from entries: [ExerciseProgressEntry]) -> ExerciseProgressBests {
        let sets = entries.flatMap(\.sets)
        let setVolumes = sets.map { VolumeCalculator().setVolume(weightKg: $0.loggedWeightKg, reps: $0.loggedReps) }
        let sessionVolumes = entries.map(\.volumeKg)

        return ExerciseProgressBests(
            maxWeight: sets.compactMap(\.loggedWeightKg).max(),
            maxReps: sets.compactMap(\.loggedReps).max(),
            maxSetVolume: setVolumes.filter { $0 > 0 }.max(),
            maxSessionVolume: sessionVolumes.filter { $0 > 0 }.max()
        )
    }
}

private enum HistoryFormatters {
    static func decimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    static func optionalDecimal(_ value: Double?) -> String {
        guard let value else { return "-" }
        return decimal(value)
    }

    static func optionalPain(_ value: Int?) -> String {
        guard let value else { return "-" }
        return "\(value)/10"
    }

    static func setText(_ setLog: SetLog) -> String {
        let weight = setLog.loggedWeightKg.map { "\(decimal($0)) kg" } ?? "-"
        let reps = setLog.loggedReps.map { "\($0)" } ?? "-"
        return "\(weight) x \(reps)"
    }
}

#if DEBUG
#Preview {
    HistoryView()
        .modelContainer(PlanPreviewData.container)
}
#endif
