import Foundation
import SwiftData

enum SessionStartError: Error, Equatable {
    case activeSessionAlreadyExists
}

struct SessionStartService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

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

    @discardableResult
    func startOrResumeSession(from workoutPlan: WorkoutPlan, at startDate: Date = .now) throws -> SessionLog {
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
