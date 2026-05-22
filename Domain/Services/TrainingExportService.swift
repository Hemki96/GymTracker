import Foundation

struct TrainingExportService {
    enum ExportError: Error, Equatable {
        case missingWorkoutPlan
        case missingTrainingBlock
    }

    private let calendar: Calendar

    init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        var calendar = calendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        self.calendar = calendar
    }

    func markdown(for session: SessionLog) throws -> String {
        guard let workout = session.workoutPlan else { throw ExportError.missingWorkoutPlan }

        var lines: [String] = []
        lines.append("# \(workout.title)")
        lines.append("")
        lines.append("- Datum: \(dateString(session.completedAt ?? session.startedAt))")
        lines.append("- Woche: \(workout.week?.weekNumber.description ?? "-")")
        lines.append("- Tag: \(workout.dayNumber)")
        if let blockName = workout.week?.block?.name {
            lines.append("- Block: \(blockName)")
        }
        lines.append("")
        lines.append("## Zusammenfassung")
        lines.append("")
        lines.append("| Wert | Ist |")
        lines.append("| --- | --- |")
        lines.append("| Dauer | \(durationString(session.durationSeconds)) |")
        lines.append("| Volumen | \(numberString(session.totalVolumeKg, suffix: " kg")) |")
        lines.append("| Durchschnitt RIR | \(numberString(session.averageRIR)) |")
        lines.append("| Max. Schmerz | \(session.maxPain.map { "\($0)/10" } ?? "-") |")
        lines.append("")

        if let notes = session.overallNotes, !notes.isEmpty {
            lines.append("## Notizen")
            lines.append("")
            lines.append(notes)
            lines.append("")
        }

        if !session.warningMessages.isEmpty {
            lines.append("## Warnungen")
            lines.append("")
            for warning in session.warningMessages {
                lines.append("- \(warning)")
            }
            lines.append("")
        }

        lines.append("## Uebungen")
        lines.append("")

        for exerciseLog in sortedExerciseLogs(session.exerciseLogs) {
            let plannedExercise = exerciseLog.plannedExercise
            lines.append("### \(plannedExercise?.exercise?.name ?? "Unbekannte Uebung")")
            lines.append("")
            lines.append("- Plan: \(plannedExercise?.setsPrescription ?? "-") x \(plannedExercise?.repsPrescription ?? "-")")
            lines.append("- Gewicht geplant: \(plannedExercise?.plannedWeightText ?? "-")")
            lines.append("- Ziel-RIR: \(plannedExercise?.targetRIRText ?? "-")")
            lines.append("- Schmerz-Ziel: \(plannedExercise?.painTargetText ?? "-")")
            if let tempo = plannedExercise?.tempo, !tempo.isEmpty {
                lines.append("- Tempo: \(tempo)")
            }
            if let cueing = plannedExercise?.cueing, !cueing.isEmpty {
                lines.append("- Cueing: \(cueing)")
            }
            lines.append("")
            lines.append("| Satz | Plan Wdh. | Ist Wdh. | Plan Gewicht | Ist Gewicht kg | RIR | Schmerz | Erledigt |")
            lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")

            for setLog in sortedSetLogs(exerciseLog.setLogs) {
                lines.append([
                    "\(setLog.setNumber)",
                    setLog.plannedRepsText ?? "-",
                    setLog.loggedReps.map(String.init) ?? "-",
                    setLog.plannedWeightText ?? "-",
                    numberString(setLog.loggedWeightKg),
                    numberString(setLog.rir),
                    setLog.pain.map(String.init) ?? "-",
                    setLog.isCompleted ? "ja" : "nein"
                ].joined(separator: " | ").tableRow)
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    func csv(for block: TrainingBlock) -> String {
        var rows: [[String]] = [[
            "Block",
            "Woche",
            "Tag",
            "Workout",
            "Plan-Datum",
            "Uebung",
            "Plan-Saetze",
            "Plan-Wdh",
            "Plan-Gewicht",
            "Ziel-RIR",
            "Schmerz-Ziel",
            "Satz",
            "Satz-Plan-Wdh",
            "Satz-Plan-Gewicht",
            "Session-Start",
            "Session-Ende",
            "Ist-Wdh",
            "Ist-Gewicht-kg",
            "Ist-RIR",
            "Ist-Schmerz",
            "Erledigt",
            "Notizen"
        ]]

        for week in block.weeks.sorted(by: { $0.weekNumber < $1.weekNumber }) {
            for workout in week.workoutPlans.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let sessions = workout.sessionLogs.sorted {
                    ($0.completedAt ?? $0.startedAt) < ($1.completedAt ?? $1.startedAt)
                }

                for plannedExercise in workout.plannedExercises.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                    let exerciseRows = rowsForExercise(
                        block: block,
                        week: week,
                        workout: workout,
                        plannedExercise: plannedExercise,
                        sessions: sessions
                    )
                    rows.append(contentsOf: exerciseRows)
                }
            }
        }

        return rows.map(csvLine).joined(separator: "\n")
    }

    func fileURL(forSession session: SessionLog) throws -> URL {
        let workout = try requireWorkout(for: session)
        let blockName = workout.week?.block?.name ?? workout.title
        let fileName = "\(dateString(session.completedAt ?? session.startedAt))_\(slug(blockName))_\(slug(workout.title)).md"
        return try write(markdown(for: session), fileName: fileName)
    }

    func fileURL(forBlock block: TrainingBlock) throws -> URL {
        let exportDate = block.endDate ?? block.startDate ?? block.createdAt
        let fileName = "\(dateString(exportDate))_\(slug(block.name)).csv"
        return try write(csv(for: block), fileName: fileName)
    }

    private func rowsForExercise(
        block: TrainingBlock,
        week: TrainingWeek,
        workout: WorkoutPlan,
        plannedExercise: PlannedExercise,
        sessions: [SessionLog]
    ) -> [[String]] {
        let matchingLogs = sessions.flatMap { session in
            session.exerciseLogs
                .filter { $0.plannedExercise?.id == plannedExercise.id }
                .map { (session, $0) }
        }

        guard !matchingLogs.isEmpty else {
            return [baseRow(
                block: block,
                week: week,
                workout: workout,
                plannedExercise: plannedExercise
            ) + Array(repeating: "", count: 11)]
        }

        return matchingLogs.flatMap { session, exerciseLog in
            sortedSetLogs(exerciseLog.setLogs).map { setLog in
                let planRow = baseRow(block: block, week: week, workout: workout, plannedExercise: plannedExercise)
                let notes = [exerciseLog.notes, setLog.notes]
                    .compactMap { $0?.trimmedNonEmpty }
                    .joined(separator: " | ")
                let actualRow = [
                    "\(setLog.setNumber)",
                    setLog.plannedRepsText ?? "",
                    setLog.plannedWeightText ?? "",
                    dateTimeString(session.startedAt),
                    session.completedAt.map(dateTimeString) ?? "",
                    setLog.loggedReps.map(String.init) ?? "",
                    numberString(setLog.loggedWeightKg, empty: ""),
                    numberString(setLog.rir, empty: ""),
                    setLog.pain.map(String.init) ?? "",
                    setLog.isCompleted ? "ja" : "nein",
                    notes
                ]
                return planRow + actualRow
            }
        }
    }

    private func baseRow(
        block: TrainingBlock,
        week: TrainingWeek,
        workout: WorkoutPlan,
        plannedExercise: PlannedExercise
    ) -> [String] {
        [
            block.name,
            "\(week.weekNumber)",
            "\(workout.dayNumber)",
            workout.title,
            workout.plannedDate.map(dateString) ?? "",
            plannedExercise.exercise?.name ?? "",
            plannedExercise.setsPrescription,
            plannedExercise.repsPrescription,
            plannedExercise.plannedWeightText ?? "",
            plannedExercise.targetRIRText ?? "",
            plannedExercise.painTargetText ?? ""
        ]
    }

    private func sortedExerciseLogs(_ exerciseLogs: [ExerciseLog]) -> [ExerciseLog] {
        exerciseLogs.sorted {
            ($0.plannedExercise?.sortOrder ?? 0) < ($1.plannedExercise?.sortOrder ?? 0)
        }
    }

    private func sortedSetLogs(_ setLogs: [SetLog]) -> [SetLog] {
        setLogs.sorted { $0.setNumber < $1.setNumber }
    }

    private func requireWorkout(for session: SessionLog) throws -> WorkoutPlan {
        guard let workout = session.workoutPlan else { throw ExportError.missingWorkoutPlan }
        return workout
    }

    private func csvLine(_ fields: [String]) -> String {
        fields
            .map { field in
                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                return field.contains(",") || field.contains("\"") || field.contains("\n")
                    ? "\"\(escaped)\""
                    : escaped
            }
            .joined(separator: ",")
    }

    private func write(_ content: String, fileName: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("GymTrackerExports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func dateString(_ date: Date) -> String {
        components(from: date).date
    }

    private func dateTimeString(_ date: Date) -> String {
        let parts = components(from: date)
        return "\(parts.date) \(parts.time)"
    }

    private func components(from date: Date) -> (date: String, time: String) {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return (
            String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0),
            String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
        )
    }

    private func durationString(_ durationSeconds: Int?) -> String {
        guard let durationSeconds else { return "-" }
        let minutes = durationSeconds / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours) h \(remainingMinutes) min" : "\(max(minutes, 1)) min"
    }

    private func numberString(_ value: Double?, suffix: String = "", empty: String = "-") -> String {
        guard let value else { return empty }
        let formatted = value.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).precision(.fractionLength(0...2)))
        return "\(formatted)\(suffix)"
    }

    private func slug(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let folded = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let scalars = folded.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        return String(scalars)
            .split(separator: "-")
            .joined(separator: "-")
            .lowercased()
    }
}

private extension String {
    var tableRow: String {
        "| \(self) |"
    }
}
