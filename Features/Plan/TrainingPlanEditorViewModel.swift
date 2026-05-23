import Foundation
import SwiftData

enum EditorValidationIssue: Equatable, Hashable {
    case required(String)
    case invalidRange(String)

    var message: String {
        switch self {
        case .required(let field):
            return "\(field) ist erforderlich."
        case .invalidRange(let field):
            return "\(field) ist ungueltig."
        }
    }
}

enum EditorMoveDirection {
    case up
    case down
}

@MainActor
final class TrainingPlanEditorViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func validate(_ plan: TrainingPlan) -> [EditorValidationIssue] {
        trimmed(plan.name).isEmpty ? [.required("Name")] : []
    }

    func validate(_ week: TrainingWeek) -> [EditorValidationIssue] {
        trimmed(week.title).isEmpty ? [.required("Wochentitel")] : []
    }

    func validate(_ session: TrainingSession) -> [EditorValidationIssue] {
        var issues: [EditorValidationIssue] = []
        if trimmed(session.title).isEmpty {
            issues.append(.required("Session-Titel"))
        }
        if let duration = session.plannedDurationMinutes, duration < 1 {
            issues.append(.invalidRange("Geplante Dauer"))
        }
        return issues
    }

    func validate(_ exercise: Exercise) -> [EditorValidationIssue] {
        trimmed(exercise.name).isEmpty ? [.required("Uebungsname")] : []
    }

    func updatePlan(
        _ plan: TrainingPlan,
        name: String,
        description: String?,
        goal: String,
        startDate: Date?,
        status: BlockStatus
    ) throws {
        plan.name = trimmed(name)
        plan.descriptionText = normalized(description)
        plan.goal = trimmed(goal)
        plan.startDate = startDate
        plan.status = status
        plan.updatedAt = .now
        try saveValidated(plan)
    }

    func duplicatePlan(_ plan: TrainingPlan) throws -> TrainingPlan {
        let copy = clone(plan)
        context.insert(copy)
        try context.save()
        return copy
    }

    func deletePlan(_ plan: TrainingPlan) throws {
        context.delete(plan)
        try context.save()
    }

    func addWeek(to plan: TrainingPlan) throws -> TrainingWeek {
        let week = TrainingWeek(weekNumber: plan.weeks.count + 1, title: "Neue Woche", block: plan)
        plan.weeks.append(week)
        renumberWeeks(in: plan)
        try context.save()
        return week
    }

    func updateWeek(_ week: TrainingWeek, title: String, focus: String?, notes: String?) throws {
        week.title = trimmed(title)
        week.focus = normalized(focus)
        week.notes = normalized(notes)
        week.updatedAt = .now
        try saveValidated(week)
    }

    func duplicateWeek(_ week: TrainingWeek, in plan: TrainingPlan) throws -> TrainingWeek {
        let copy = clone(week)
        copy.title = "\(week.title) Kopie"
        copy.block = plan
        insert(copy, after: week, in: &plan.weeks, sortedBy: { $0.weekNumber < $1.weekNumber })
        renumberWeeks(in: plan)
        try context.save()
        return copy
    }

    func deleteWeek(_ week: TrainingWeek, from plan: TrainingPlan) throws {
        plan.weeks.removeAll { $0.id == week.id }
        context.delete(week)
        renumberWeeks(in: plan)
        try context.save()
    }

    func moveWeek(_ week: TrainingWeek, in plan: TrainingPlan, direction: EditorMoveDirection) throws {
        move(week, in: &plan.weeks, sortedBy: { $0.weekNumber < $1.weekNumber }, direction: direction)
        renumberWeeks(in: plan)
        try context.save()
    }

    func addSession(to week: TrainingWeek) throws -> TrainingSession {
        let session = TrainingSession(
            dayNumber: week.workoutPlans.count + 1,
            title: "Neue Session",
            sortOrder: week.workoutPlans.count + 1,
            week: week
        )
        week.workoutPlans.append(session)
        renumberSessions(in: week)
        try context.save()
        return session
    }

    func updateSession(
        _ session: TrainingSession,
        title: String,
        focus: String?,
        plannedDurationMinutes: Int?,
        notes: String?
    ) throws {
        session.title = trimmed(title)
        session.focus = normalized(focus)
        session.plannedDurationMinutes = plannedDurationMinutes
        session.notes = normalized(notes)
        session.updatedAt = .now
        try saveValidated(session)
    }

    func duplicateSession(_ session: TrainingSession, in week: TrainingWeek) throws -> TrainingSession {
        let copy = clone(session)
        copy.title = "\(session.title) Kopie"
        copy.week = week
        insert(copy, after: session, in: &week.workoutPlans, sortedBy: sessionSort)
        renumberSessions(in: week)
        try context.save()
        return copy
    }

    func deleteSession(_ session: TrainingSession, from week: TrainingWeek) throws {
        week.workoutPlans.removeAll { $0.id == session.id }
        context.delete(session)
        renumberSessions(in: week)
        try context.save()
    }

    func moveSession(_ session: TrainingSession, in week: TrainingWeek, direction: EditorMoveDirection) throws {
        move(session, in: &week.workoutPlans, sortedBy: sessionSort, direction: direction)
        renumberSessions(in: week)
        try context.save()
    }

    func addExercise(to session: TrainingSession) throws -> PlannedExercise {
        let exercise = Exercise(name: "Neue Uebung")
        let plannedExercise = PlannedExercise(
            sortOrder: session.plannedExercises.count + 1,
            setsPrescription: "0",
            repsPrescription: "",
            workoutPlan: session,
            exercise: exercise
        )
        session.plannedExercises.append(plannedExercise)
        context.insert(exercise)
        renumberExercises(in: session)
        try context.save()
        return plannedExercise
    }

    func updateExercise(
        _ plannedExercise: PlannedExercise,
        name: String,
        muscleGroup: String?,
        equipment: String?,
        cueing: String?,
        tempo: String?,
        targetRIR: String?,
        painTarget: String?,
        notes: String?
    ) throws {
        let exercise = plannedExercise.exercise ?? Exercise(name: "")
        if plannedExercise.exercise == nil {
            plannedExercise.exercise = exercise
            context.insert(exercise)
        }
        exercise.name = trimmed(name)
        exercise.muscleGroup = normalized(muscleGroup)
        exercise.equipment = normalized(equipment)
        exercise.updatedAt = .now
        plannedExercise.cueing = normalized(cueing)
        plannedExercise.tempo = normalized(tempo)
        plannedExercise.targetRIRText = normalized(targetRIR)
        plannedExercise.painTargetText = normalized(painTarget)
        plannedExercise.notes = normalized(notes)
        plannedExercise.updatedAt = .now
        syncExercisePrescriptions(plannedExercise)
        try saveValidated(exercise)
    }

    func duplicateExercise(_ plannedExercise: PlannedExercise, in session: TrainingSession) throws -> PlannedExercise {
        let copy = clone(plannedExercise)
        if let name = plannedExercise.exercise?.name {
            copy.exercise?.name = "\(name) Kopie"
        }
        copy.workoutPlan = session
        insert(copy, after: plannedExercise, in: &session.plannedExercises, sortedBy: { $0.sortOrder < $1.sortOrder })
        renumberExercises(in: session)
        try context.save()
        return copy
    }

    func deleteExercise(_ plannedExercise: PlannedExercise, from session: TrainingSession) throws {
        session.plannedExercises.removeAll { $0.id == plannedExercise.id }
        context.delete(plannedExercise)
        renumberExercises(in: session)
        try context.save()
    }

    func moveExercise(_ plannedExercise: PlannedExercise, in session: TrainingSession, direction: EditorMoveDirection) throws {
        move(plannedExercise, in: &session.plannedExercises, sortedBy: { $0.sortOrder < $1.sortOrder }, direction: direction)
        renumberExercises(in: session)
        try context.save()
    }

    func addSet(to plannedExercise: PlannedExercise) throws -> PlannedSet {
        let set = PlannedSet(setNumber: plannedExercise.plannedSets.count + 1, plannedExercise: plannedExercise)
        plannedExercise.plannedSets.append(set)
        syncExercisePrescriptions(plannedExercise)
        try context.save()
        return set
    }

    func updateSet(
        _ set: PlannedSet,
        reps: String?,
        weight: String?,
        targetRIR: String?,
        rest: String?,
        tempo: String?,
        setType: PlannedSetType,
        painTarget: String?,
        notes: String?
    ) throws {
        set.repsText = normalized(reps)
        set.weightText = normalized(weight)
        set.targetRIRText = normalized(targetRIR)
        set.restText = normalized(rest)
        set.tempo = normalized(tempo)
        set.setType = setType
        set.painTargetText = normalized(painTarget)
        set.notes = normalized(notes)
        set.updatedAt = .now
        if let plannedExercise = set.plannedExercise {
            syncExercisePrescriptions(plannedExercise)
        }
        try context.save()
    }

    func duplicateSet(_ set: PlannedSet, in plannedExercise: PlannedExercise) throws -> PlannedSet {
        let copy = clone(set)
        copy.plannedExercise = plannedExercise
        insert(copy, after: set, in: &plannedExercise.plannedSets, sortedBy: { $0.setNumber < $1.setNumber })
        renumberSets(in: plannedExercise)
        syncExercisePrescriptions(plannedExercise)
        try context.save()
        return copy
    }

    func deleteSet(_ set: PlannedSet, from plannedExercise: PlannedExercise) throws {
        plannedExercise.plannedSets.removeAll { $0.id == set.id }
        context.delete(set)
        renumberSets(in: plannedExercise)
        syncExercisePrescriptions(plannedExercise)
        try context.save()
    }

    func moveSet(_ set: PlannedSet, in plannedExercise: PlannedExercise, direction: EditorMoveDirection) throws {
        move(set, in: &plannedExercise.plannedSets, sortedBy: { $0.setNumber < $1.setNumber }, direction: direction)
        renumberSets(in: plannedExercise)
        syncExercisePrescriptions(plannedExercise)
        try context.save()
    }

    private func saveValidated(_ plan: TrainingPlan) throws {
        guard validate(plan).isEmpty else { throw TrainingPlanEditorError.validationFailed(validate(plan)) }
        try context.save()
    }

    private func saveValidated(_ week: TrainingWeek) throws {
        guard validate(week).isEmpty else { throw TrainingPlanEditorError.validationFailed(validate(week)) }
        try context.save()
    }

    private func saveValidated(_ session: TrainingSession) throws {
        guard validate(session).isEmpty else { throw TrainingPlanEditorError.validationFailed(validate(session)) }
        try context.save()
    }

    private func saveValidated(_ exercise: Exercise) throws {
        guard validate(exercise).isEmpty else { throw TrainingPlanEditorError.validationFailed(validate(exercise)) }
        try context.save()
    }

    private func clone(_ plan: TrainingPlan) -> TrainingPlan {
        let copy = TrainingPlan(
            name: "\(plan.name) Kopie",
            athleteName: plan.athleteName,
            descriptionText: plan.descriptionText,
            goal: plan.goal,
            startDate: plan.startDate,
            endDate: plan.endDate,
            status: .planned
        )
        copy.weeks = plan.weeks.sorted { $0.weekNumber < $1.weekNumber }.map { week in
            let weekCopy = clone(week)
            weekCopy.block = copy
            return weekCopy
        }
        return copy
    }

    private func clone(_ week: TrainingWeek) -> TrainingWeek {
        let copy = TrainingWeek(weekNumber: week.weekNumber, title: week.title, focus: week.focus, notes: week.notes)
        copy.workoutPlans = week.workoutPlans.sorted(by: sessionSort).map { session in
            let sessionCopy = clone(session)
            sessionCopy.week = copy
            return sessionCopy
        }
        return copy
    }

    private func clone(_ session: TrainingSession) -> TrainingSession {
        let copy = TrainingSession(
            dayNumber: session.dayNumber,
            title: session.title,
            focus: session.focus,
            plannedDurationMinutes: session.plannedDurationMinutes,
            notes: session.notes,
            plannedDate: session.plannedDate,
            status: .planned,
            sortOrder: session.sortOrder
        )
        copy.plannedExercises = session.plannedExercises.sorted { $0.sortOrder < $1.sortOrder }.map { plannedExercise in
            let exerciseCopy = clone(plannedExercise)
            exerciseCopy.workoutPlan = copy
            return exerciseCopy
        }
        return copy
    }

    private func clone(_ plannedExercise: PlannedExercise) -> PlannedExercise {
        let exerciseCopy = plannedExercise.exercise.map { source in
            Exercise(
                name: source.name,
                category: source.category,
                muscleGroup: source.muscleGroup,
                equipment: source.equipment,
                defaultCueing: source.defaultCueing,
                defaultTempo: source.defaultTempo,
                isUnilateral: source.isUnilateral,
                usesBodyweight: source.usesBodyweight
            )
        }
        let copy = PlannedExercise(
            sortOrder: plannedExercise.sortOrder,
            cueing: plannedExercise.cueing,
            tempo: plannedExercise.tempo,
            setsPrescription: plannedExercise.setsPrescription,
            repsPrescription: plannedExercise.repsPrescription,
            plannedWeightText: plannedExercise.plannedWeightText,
            targetRIRText: plannedExercise.targetRIRText,
            painTargetText: plannedExercise.painTargetText,
            notes: plannedExercise.notes,
            exercise: exerciseCopy
        )
        copy.plannedSets = plannedExercise.plannedSets.sorted { $0.setNumber < $1.setNumber }.map { set in
            let setCopy = clone(set)
            setCopy.plannedExercise = copy
            return setCopy
        }
        return copy
    }

    private func clone(_ set: PlannedSet) -> PlannedSet {
        PlannedSet(
            setNumber: set.setNumber,
            repsText: set.repsText,
            weightText: set.weightText,
            targetRIRText: set.targetRIRText,
            painTargetText: set.painTargetText,
            restText: set.restText,
            tempo: set.tempo,
            setType: set.setType,
            notes: set.notes
        )
    }

    private func insert<T: Identifiable>(_ item: T, after reference: T, in items: inout [T], sortedBy areInIncreasingOrder: (T, T) -> Bool) where T.ID == UUID {
        var sorted = items.sorted(by: areInIncreasingOrder)
        let insertionIndex = (sorted.firstIndex { $0.id == reference.id } ?? sorted.endIndex - 1) + 1
        sorted.insert(item, at: min(insertionIndex, sorted.endIndex))
        items = sorted
    }

    private func move<T: Identifiable>(_ item: T, in items: inout [T], sortedBy areInIncreasingOrder: (T, T) -> Bool, direction: EditorMoveDirection) where T.ID == UUID {
        var sorted = items.sorted(by: areInIncreasingOrder)
        guard let index = sorted.firstIndex(where: { $0.id == item.id }) else { return }
        let targetIndex: Int
        switch direction {
        case .up:
            targetIndex = max(sorted.startIndex, index - 1)
        case .down:
            targetIndex = min(sorted.endIndex - 1, index + 1)
        }
        guard index != targetIndex else { return }
        sorted.swapAt(index, targetIndex)
        items = sorted
    }

    private func renumberWeeks(in plan: TrainingPlan) {
        for (index, week) in plan.weeks.enumerated() {
            week.weekNumber = index + 1
            week.updatedAt = .now
        }
        plan.updatedAt = .now
    }

    private func renumberSessions(in week: TrainingWeek) {
        for (index, session) in week.workoutPlans.enumerated() {
            session.dayNumber = index + 1
            session.sortOrder = index + 1
            session.updatedAt = .now
        }
        week.updatedAt = .now
    }

    private func renumberExercises(in session: TrainingSession) {
        for (index, exercise) in session.plannedExercises.enumerated() {
            exercise.sortOrder = index + 1
            exercise.updatedAt = .now
        }
        syncSessionPrescriptions(session)
    }

    private func renumberSets(in plannedExercise: PlannedExercise) {
        for (index, set) in plannedExercise.plannedSets.enumerated() {
            set.setNumber = index + 1
            set.updatedAt = .now
        }
    }

    private func syncSessionPrescriptions(_ session: TrainingSession) {
        session.plannedExercises.forEach(syncExercisePrescriptions)
        session.updatedAt = .now
    }

    private func syncExercisePrescriptions(_ plannedExercise: PlannedExercise) {
        let sortedSets = plannedExercise.plannedSets.sorted { $0.setNumber < $1.setNumber }
        plannedExercise.setsPrescription = "\(sortedSets.count)"
        plannedExercise.repsPrescription = compactJoined(sortedSets.compactMap(\.repsText))
        plannedExercise.plannedWeightText = firstNonEmpty(sortedSets.compactMap(\.weightText))
        plannedExercise.targetRIRText = firstNonEmpty(sortedSets.compactMap(\.targetRIRText))
        plannedExercise.painTargetText = firstNonEmpty(sortedSets.compactMap(\.painTargetText))
        plannedExercise.updatedAt = .now
    }

    private func sessionSort(_ lhs: TrainingSession, _ rhs: TrainingSession) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.dayNumber < rhs.dayNumber
        }
        return lhs.sortOrder < rhs.sortOrder
    }

    private func compactJoined(_ values: [String]) -> String {
        let unique = values.map(trimmed).filter { !$0.isEmpty }.uniqued()
        return unique.joined(separator: ", ")
    }

    private func firstNonEmpty(_ values: [String]) -> String? {
        values.map(trimmed).first { !$0.isEmpty }
    }

    private func normalized(_ value: String?) -> String? {
        let trimmedValue = trimmed(value ?? "")
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TrainingPlanEditorError: Error, Equatable {
    case validationFailed([EditorValidationIssue])
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
