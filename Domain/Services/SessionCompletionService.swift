import Foundation
import SwiftData

struct SessionCompletionService {
    private let context: ModelContext
    private let volumeCalculator: VolumeCalculator
    private let rirAnalyzer: RIRAnalyzer
    private let painEvaluator: PainThresholdEvaluator

    init(
        context: ModelContext,
        volumeCalculator: VolumeCalculator = VolumeCalculator(),
        rirAnalyzer: RIRAnalyzer = RIRAnalyzer(),
        painEvaluator: PainThresholdEvaluator = PainThresholdEvaluator()
    ) {
        self.context = context
        self.volumeCalculator = volumeCalculator
        self.rirAnalyzer = rirAnalyzer
        self.painEvaluator = painEvaluator
    }

    @discardableResult
    func completeSession(
        _ session: SessionLog,
        note: String?,
        at completedAt: Date = .now
    ) throws -> SessionLog {
        let completedSets = session.exerciseLogs
            .flatMap(\.setLogs)
            .filter(\.isCompleted)

        session.completedAt = completedAt
        session.durationSeconds = max(Int(completedAt.timeIntervalSince(session.startedAt)), 0)
        session.status = .completed
        session.overallNotes = note?.trimmedNonEmpty
        session.maxPain = completedSets.compactMap(\.pain).max()
        session.averageRIR = averageRIR(from: completedSets)

        let totalVolume = volumeCalculator.totalVolumeKg(from: completedSets)
        session.totalVolumeKg = totalVolume > 0 ? totalVolume : nil
        session.warningMessages = warnings(for: session, completedSets: completedSets)
        session.updatedAt = completedAt

        session.workoutPlan?.status = .completed
        session.workoutPlan?.updatedAt = completedAt

        for exerciseLog in session.exerciseLogs {
            let exerciseCompleted = exerciseLog.setLogs.contains { $0.isCompleted }
            exerciseLog.isCompleted = exerciseCompleted
            exerciseLog.completedAt = exerciseCompleted ? completedAt : nil
            exerciseLog.updatedAt = completedAt
        }

        try context.save()
        return session
    }

    func refreshSummary(for session: SessionLog) {
        let completedSets = session.exerciseLogs
            .flatMap(\.setLogs)
            .filter(\.isCompleted)

        session.maxPain = completedSets.compactMap(\.pain).max()
        session.averageRIR = averageRIR(from: completedSets)

        let totalVolume = volumeCalculator.totalVolumeKg(from: completedSets)
        session.totalVolumeKg = totalVolume > 0 ? totalVolume : nil
        session.warningMessages = warnings(for: session, completedSets: completedSets)
    }

    private func averageRIR(from completedSets: [SetLog]) -> Double? {
        let rirValues = completedSets.compactMap(\.rir)
        guard !rirValues.isEmpty else { return nil }
        return rirValues.reduce(0, +) / Double(rirValues.count)
    }

    private func warnings(for session: SessionLog, completedSets: [SetLog]) -> [String] {
        var warnings: [String] = []

        if completedSets.isEmpty {
            warnings.append("Keine abgeschlossenen Saetze erfasst.")
        }

        for exerciseLog in session.exerciseLogs.sorted(by: sortExerciseLogs) {
            guard let plannedExercise = exerciseLog.plannedExercise else { continue }
            let exerciseName = plannedExercise.exercise?.name ?? "Unbekannte Uebung"

            for setLog in exerciseLog.setLogs.sorted(by: { $0.setNumber < $1.setNumber }) where setLog.isCompleted {
                appendPainWarning(
                    for: setLog,
                    plannedExercise: plannedExercise,
                    exerciseName: exerciseName,
                    to: &warnings
                )
                appendRIRWarning(
                    for: setLog,
                    plannedExercise: plannedExercise,
                    exerciseName: exerciseName,
                    to: &warnings
                )
            }
        }

        return warnings
    }

    private func appendPainWarning(
        for setLog: SetLog,
        plannedExercise: PlannedExercise,
        exerciseName: String,
        to warnings: inout [String]
    ) {
        switch painEvaluator.evaluate(actualPain: setLog.pain, targetText: plannedExercise.painTargetText) {
        case let .warning(actualPain, maxPain):
            warnings.append("\(exerciseName), Satz \(setLog.setNumber): Schmerz \(actualPain)/10 ueber Ziel max \(maxPain)/10.")
        case let .invalidActualPain(actualPain):
            warnings.append("\(exerciseName), Satz \(setLog.setNumber): ungueltiger Schmerz \(actualPain)/10.")
        case let .invalidTarget(target):
            warnings.append("\(exerciseName): Schmerz-Ziel \"\(target)\" konnte nicht gelesen werden.")
        default:
            break
        }

        if let pain = setLog.pain, pain >= 7 {
            warnings.append("\(exerciseName), Satz \(setLog.setNumber): hoher Schmerz \(pain)/10.")
        }
    }

    private func appendRIRWarning(
        for setLog: SetLog,
        plannedExercise: PlannedExercise,
        exerciseName: String,
        to warnings: inout [String]
    ) {
        switch rirAnalyzer.evaluate(actualRIR: setLog.rir, targetText: plannedExercise.targetRIRText) {
        case let .tooEasy(actualRIR, range):
            warnings.append("\(exerciseName), Satz \(setLog.setNumber): RIR \(format(actualRIR)) ueber Ziel \(format(range)).")
        case let .tooHeavy(actualRIR, range):
            warnings.append("\(exerciseName), Satz \(setLog.setNumber): RIR \(format(actualRIR)) unter Ziel \(format(range)).")
        case let .invalidTarget(target):
            warnings.append("\(exerciseName): RIR-Ziel \"\(target)\" konnte nicht gelesen werden.")
        default:
            break
        }
    }

    private func sortExerciseLogs(_ lhs: ExerciseLog, _ rhs: ExerciseLog) -> Bool {
        (lhs.plannedExercise?.sortOrder ?? 0) < (rhs.plannedExercise?.sortOrder ?? 0)
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func format(_ range: ClosedRange<Double>) -> String {
        range.lowerBound == range.upperBound
            ? format(range.lowerBound)
            : "\(format(range.lowerBound))-\(format(range.upperBound))"
    }
}

struct SessionEditingService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func addSet(to exerciseLog: ExerciseLog, at date: Date = .now) throws -> SetLog {
        let setLogs = sortedSetLogs(exerciseLog.setLogs)
        let lastSet = setLogs.last
        let plannedExercise = exerciseLog.plannedExercise
        let setLog = SetLog(
            setNumber: setLogs.count + 1,
            plannedRepsText: plannedExercise?.repsPrescription,
            loggedReps: lastSet?.loggedReps,
            plannedWeightText: plannedExercise?.plannedWeightText,
            loggedWeightKg: lastSet?.loggedWeightKg,
            rir: lastSet?.rir,
            pain: lastSet?.pain,
            createdAt: date,
            updatedAt: date,
            exerciseLog: exerciseLog
        )

        exerciseLog.setLogs.append(setLog)
        exerciseLog.updatedAt = date
        exerciseLog.sessionLog?.updatedAt = date
        context.insert(setLog)
        try context.save()
        return setLog
    }

    func deleteSet(_ setLog: SetLog, at date: Date = .now) throws {
        guard let exerciseLog = setLog.exerciseLog else {
            context.delete(setLog)
            try context.save()
            return
        }

        context.delete(setLog)
        renumberSets(for: exerciseLog, excluding: setLog.id, at: date)
        exerciseLog.updatedAt = date
        exerciseLog.sessionLog?.updatedAt = date
        SessionCompletionService(context: context).refreshSummary(for: exerciseLog.sessionLog)
        try context.save()
    }

    func save(setLog: SetLog, at date: Date = .now) throws {
        setLog.notes = setLog.notes?.trimmedNonEmpty
        setLog.updatedAt = date
        setLog.exerciseLog?.updatedAt = date
        setLog.exerciseLog?.sessionLog?.updatedAt = date
        if let sessionLog = setLog.exerciseLog?.sessionLog {
            SessionCompletionService(context: context).refreshSummary(for: sessionLog)
        }
        try context.save()
    }

    private func renumberSets(for exerciseLog: ExerciseLog, excluding deletedID: UUID, at date: Date) {
        let remainingSets = sortedSetLogs(exerciseLog.setLogs).filter { $0.id != deletedID }
        for (index, setLog) in remainingSets.enumerated() {
            setLog.setNumber = index + 1
            setLog.updatedAt = date
        }
    }

    private func sortedSetLogs(_ setLogs: [SetLog]) -> [SetLog] {
        setLogs.sorted { $0.setNumber < $1.setNumber }
    }
}

private extension SessionCompletionService {
    func refreshSummary(for session: SessionLog?) {
        guard let session else { return }
        refreshSummary(for: session)
    }
}
