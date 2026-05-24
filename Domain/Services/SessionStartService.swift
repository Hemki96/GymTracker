import Foundation
import SwiftData

enum SessionStartError: Error, Equatable {
    case activeSessionAlreadyExists
}

struct SessionStartService {
    // MARK: - Properties

    private let context: ModelContext

    // MARK: - Lifecycle

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Queries

    func activeSession() throws -> SessionLog? {
        let activeRaw = SessionStatus.active.rawValue
        var descriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate { session in
                session.statusRaw == activeRaw
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    func activeSession(for workoutPlan: WorkoutPlan) throws -> SessionLog? {
        guard let activeSession = try activeSession(),
              activeSession.workoutPlan?.id == workoutPlan.id else {
            return nil
        }

        return activeSession
    }

    // MARK: - Session Creation

    @discardableResult
    func startOrResumeSession(from workoutPlan: WorkoutPlan, at startDate: Date = .now) throws -> SessionLog {
        // Resuming is deliberately scoped to the same workout. Starting another
        // workout while any session is active is blocked in startSession so the
        // app has one unambiguous live training state.
        if let existingSession = try activeSession(for: workoutPlan) {
            return existingSession
        }

        return try startSession(from: workoutPlan, at: startDate)
    }

    @discardableResult
    func startSession(from workoutPlan: WorkoutPlan, at startDate: Date = .now) throws -> SessionLog {
        if try activeSession() != nil {
            throw SessionStartError.activeSessionAlreadyExists
        }

        // The session is a mutable training log derived from the plan. We copy
        // prescriptions into SetLog rows so later plan edits do not rewrite what
        // the athlete actually saw during this workout.
        let session = SessionLog(
            startedAt: startDate,
            status: .active,
            createdAt: startDate,
            updatedAt: startDate,
            workoutPlan: workoutPlan
        )

        workoutPlan.status = .active
        workoutPlan.updatedAt = startDate

        let exerciseLogs = workoutPlan.plannedExercises
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { plannedExercise in
                makeExerciseLog(from: plannedExercise, session: session, at: startDate)
            }

        session.exerciseLogs = exerciseLogs
        context.insert(session)
        try context.save()

        return session
    }

    // MARK: - Helpers

    private func makeExerciseLog(
        from plannedExercise: PlannedExercise,
        session: SessionLog,
        at date: Date
    ) -> ExerciseLog {
        let exerciseLog = ExerciseLog(
            createdAt: date,
            updatedAt: date,
            sessionLog: session,
            plannedExercise: plannedExercise
        )

        let plannedSets = plannedExercise.plannedSets.sorted { $0.setNumber < $1.setNumber }

        if plannedSets.isEmpty {
            // Imported plans sometimes only carry "3 x 8-10" style prescriptions.
            // In that case we synthesize set rows from the first number so the
            // live tracker remains fully editable.
            exerciseLog.setLogs = (1...plannedSetCount(from: plannedExercise.setsPrescription)).map { setNumber in
                SetLog(
                    setNumber: setNumber,
                    plannedRepsText: plannedExercise.repsPrescription,
                    plannedWeightText: plannedExercise.plannedWeightText,
                    createdAt: date,
                    updatedAt: date,
                    exerciseLog: exerciseLog
                )
            }
        } else {
            exerciseLog.setLogs = plannedSets.map { plannedSet in
                SetLog(
                    setNumber: plannedSet.setNumber,
                    plannedRepsText: plannedSet.repsText ?? plannedExercise.repsPrescription,
                    plannedWeightText: plannedSet.weightText ?? plannedExercise.plannedWeightText,
                    isWarmup: plannedSet.isWarmup,
                    createdAt: date,
                    updatedAt: date,
                    exerciseLog: exerciseLog,
                    plannedSet: plannedSet
                )
            }
        }

        return exerciseLog
    }

    private func plannedSetCount(from prescription: String) -> Int {
        let firstNumber = prescription
            .split { !$0.isNumber }
            .first
            .flatMap { Int($0) }

        return max(firstNumber ?? 1, 1)
    }
}
