import Foundation

struct WeeklyVolumePoint: Identifiable, Equatable {
    let id: Date
    let weekStart: Date
    let weekEnd: Date
    let totalVolumeKg: Double
    let sessionCount: Int

    init(weekStart: Date, weekEnd: Date, totalVolumeKg: Double, sessionCount: Int) {
        self.id = weekStart
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.totalVolumeKg = totalVolumeKg
        self.sessionCount = sessionCount
    }
}

struct MetricTrendPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let value: Double
    let title: String
}

struct ExerciseWeightPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let exerciseID: UUID
    let exerciseName: String
    let maxWeightKg: Double
}

struct ExerciseFilterOption: Identifiable, Equatable {
    let id: UUID
    let name: String
}

struct ChartDataMapper {
    // MARK: - Properties

    var calendar: Calendar = .autoupdatingCurrent
    private let volumeCalculator = VolumeCalculator()

    // MARK: - Lifecycle

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    // MARK: - Mapping

    func weeklyVolume(from sessions: [SessionLog]) -> [WeeklyVolumePoint] {
        let completedSessions = completed(sessions)
        let grouped = Dictionary(grouping: completedSessions) { session in
            weekInterval(for: date(for: session)).start
        }

        return grouped.compactMap { weekStart, sessions in
            let weekInterval = weekInterval(for: weekStart)
            let totalVolume = sessions.reduce(0) { total, session in
                total + volume(for: session)
            }
            guard totalVolume > 0 else { return nil }

            return WeeklyVolumePoint(
                weekStart: weekStart,
                weekEnd: weekInterval.end,
                totalVolumeKg: totalVolume,
                sessionCount: sessions.count
            )
        }
        .sorted { $0.weekStart < $1.weekStart }
    }

    func painTrend(from sessions: [SessionLog]) -> [MetricTrendPoint] {
        completed(sessions).compactMap { session in
            guard let pain = maxPain(for: session) else { return nil }
            return MetricTrendPoint(
                id: session.id,
                date: date(for: session),
                value: Double(pain),
                title: title(for: session)
            )
        }
        .sorted { $0.date < $1.date }
    }

    func rirTrend(from sessions: [SessionLog]) -> [MetricTrendPoint] {
        completed(sessions).compactMap { session in
            guard let rir = averageRIR(for: session) else { return nil }
            return MetricTrendPoint(
                id: session.id,
                date: date(for: session),
                value: rir,
                title: title(for: session)
            )
        }
        .sorted { $0.date < $1.date }
    }

    func exerciseOptions(from sessions: [SessionLog]) -> [ExerciseFilterOption] {
        let pairs = completed(sessions)
            .flatMap(\.exerciseLogs)
            .compactMap { exerciseLog -> ExerciseFilterOption? in
                guard let exercise = exerciseLog.plannedExercise?.exercise else { return nil }
                return ExerciseFilterOption(id: exercise.id, name: exercise.name)
            }

        return Dictionary(grouping: pairs, by: \.id)
            .compactMap { _, options in options.first }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func weightTrend(for exerciseID: UUID?, in sessions: [SessionLog]) -> [ExerciseWeightPoint] {
        guard let exerciseID else { return [] }

        return completed(sessions).compactMap { session in
            let matchingExerciseLogs = session.exerciseLogs.filter {
                $0.plannedExercise?.exercise?.id == exerciseID
            }
            let completedSets = matchingExerciseLogs
                .flatMap(\.setLogs)
                .filter { $0.isCompleted && !$0.isWarmup }

            // Warmup sets are excluded from max-weight trends because they are
            // preparation volume, not progression evidence.
            guard
                let maxWeight = completedSets.compactMap(\.loggedWeightKg).max(),
                maxWeight > 0,
                let exerciseName = matchingExerciseLogs.compactMap({ $0.plannedExercise?.exercise?.name }).first
            else {
                return nil
            }

            return ExerciseWeightPoint(
                id: session.id,
                date: date(for: session),
                exerciseID: exerciseID,
                exerciseName: exerciseName,
                maxWeightKg: maxWeight
            )
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Helpers

    private func completed(_ sessions: [SessionLog]) -> [SessionLog] {
        sessions.filter { $0.status == .completed }
    }

    private func date(for session: SessionLog) -> Date {
        session.completedAt ?? session.startedAt
    }

    private func title(for session: SessionLog) -> String {
        session.workoutPlan?.title ?? "Training"
    }

    private func weekInterval(for date: Date) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 24 * 60 * 60)
    }

    private func volume(for session: SessionLog) -> Double {
        if let totalVolumeKg = session.totalVolumeKg {
            return totalVolumeKg
        }

        // Older or partially edited sessions may not have cached summaries yet;
        // charts recompute as a fallback instead of dropping historical data.
        let completedSets = session.exerciseLogs
            .flatMap(\.setLogs)
            .filter(\.isCompleted)
        return volumeCalculator.totalVolumeKg(from: completedSets)
    }

    private func maxPain(for session: SessionLog) -> Int? {
        session.maxPain ?? completedSets(for: session).compactMap(\.pain).max()
    }

    private func averageRIR(for session: SessionLog) -> Double? {
        if let averageRIR = session.averageRIR {
            return averageRIR
        }

        let values = completedSets(for: session).compactMap(\.rir)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func completedSets(for session: SessionLog) -> [SetLog] {
        session.exerciseLogs
            .flatMap(\.setLogs)
            .filter(\.isCompleted)
    }
}
