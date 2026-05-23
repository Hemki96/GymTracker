import Foundation
import SwiftData

@Model
final class TrainingBlock {
    @Attribute(.unique) var id: UUID
    var name: String
    var athleteName: String?
    var descriptionText: String?
    var goal: String
    var startDate: Date?
    var endDate: Date?
    var statusRaw: String
    var isDemoPlan: Bool = false
    var demoSourceIdentifier: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TrainingWeek.block)
    var weeks: [TrainingWeek]

    var status: BlockStatus {
        get { BlockStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        athleteName: String? = nil,
        descriptionText: String? = nil,
        goal: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: BlockStatus = .planned,
        isDemoPlan: Bool = false,
        demoSourceIdentifier: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        weeks: [TrainingWeek] = []
    ) {
        self.id = id
        self.name = name
        self.athleteName = athleteName
        self.descriptionText = descriptionText
        self.goal = goal
        self.startDate = startDate
        self.endDate = endDate
        self.statusRaw = status.rawValue
        self.isDemoPlan = isDemoPlan
        self.demoSourceIdentifier = demoSourceIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.weeks = weeks
    }
}

@Model
final class TrainingWeek {
    @Attribute(.unique) var id: UUID
    var weekNumber: Int
    var title: String
    var focus: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var block: TrainingBlock?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutPlan.week)
    var workoutPlans: [WorkoutPlan]

    init(
        id: UUID = UUID(),
        weekNumber: Int,
        title: String,
        focus: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        block: TrainingBlock? = nil,
        workoutPlans: [WorkoutPlan] = []
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.title = title
        self.focus = focus
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.block = block
        self.workoutPlans = workoutPlans
    }
}

@Model
final class WorkoutPlan {
    @Attribute(.unique) var id: UUID
    var dayNumber: Int
    var title: String
    var focus: String?
    var plannedDurationMinutes: Int?
    var notes: String?
    var plannedDate: Date?
    var statusRaw: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var week: TrainingWeek?

    @Relationship(deleteRule: .cascade, inverse: \PlannedExercise.workoutPlan)
    var plannedExercises: [PlannedExercise]

    @Relationship(deleteRule: .cascade, inverse: \SessionLog.workoutPlan)
    var sessionLogs: [SessionLog]

    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        title: String,
        focus: String? = nil,
        plannedDurationMinutes: Int? = nil,
        notes: String? = nil,
        plannedDate: Date? = nil,
        status: WorkoutStatus = .planned,
        sortOrder: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        week: TrainingWeek? = nil,
        plannedExercises: [PlannedExercise] = [],
        sessionLogs: [SessionLog] = []
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.focus = focus
        self.plannedDurationMinutes = plannedDurationMinutes
        self.notes = notes
        self.plannedDate = plannedDate
        self.statusRaw = status.rawValue
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.week = week
        self.plannedExercises = plannedExercises
        self.sessionLogs = sessionLogs
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var muscleGroup: String?
    var equipment: String?
    var defaultCueing: String?
    var defaultTempo: String?
    var isUnilateral: Bool
    var usesBodyweight: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \PlannedExercise.exercise)
    var plannedExercises: [PlannedExercise]

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .unknown }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory = .unknown,
        muscleGroup: String? = nil,
        equipment: String? = nil,
        defaultCueing: String? = nil,
        defaultTempo: String? = nil,
        isUnilateral: Bool = false,
        usesBodyweight: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        plannedExercises: [PlannedExercise] = []
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.defaultCueing = defaultCueing
        self.defaultTempo = defaultTempo
        self.isUnilateral = isUnilateral
        self.usesBodyweight = usesBodyweight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.plannedExercises = plannedExercises
    }
}

@Model
final class PlannedExercise {
    @Attribute(.unique) var id: UUID
    var sortOrder: Int
    var cueing: String?
    var tempo: String?
    var setsPrescription: String
    var repsPrescription: String
    var plannedWeightText: String?
    var targetRIRText: String?
    var painTargetText: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var workoutPlan: WorkoutPlan?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \PlannedSet.plannedExercise)
    var plannedSets: [PlannedSet]

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.plannedExercise)
    var exerciseLogs: [ExerciseLog]

    init(
        id: UUID = UUID(),
        sortOrder: Int,
        cueing: String? = nil,
        tempo: String? = nil,
        setsPrescription: String,
        repsPrescription: String,
        plannedWeightText: String? = nil,
        targetRIRText: String? = nil,
        painTargetText: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        workoutPlan: WorkoutPlan? = nil,
        exercise: Exercise? = nil,
        plannedSets: [PlannedSet] = [],
        exerciseLogs: [ExerciseLog] = []
    ) {
        self.id = id
        self.sortOrder = sortOrder
        self.cueing = cueing
        self.tempo = tempo
        self.setsPrescription = setsPrescription
        self.repsPrescription = repsPrescription
        self.plannedWeightText = plannedWeightText
        self.targetRIRText = targetRIRText
        self.painTargetText = painTargetText
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.workoutPlan = workoutPlan
        self.exercise = exercise
        self.plannedSets = plannedSets
        self.exerciseLogs = exerciseLogs
    }
}

@Model
final class PlannedSet {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var repsText: String?
    var weightText: String?
    var targetRIRText: String?
    var painTargetText: String?
    var restText: String?
    var tempo: String?
    var setTypeRaw: String?
    var notes: String?
    var isWarmup: Bool
    var createdAt: Date
    var updatedAt: Date
    var plannedExercise: PlannedExercise?

    @Relationship(deleteRule: .nullify, inverse: \SetLog.plannedSet)
    var setLogs: [SetLog]

    init(
        id: UUID = UUID(),
        setNumber: Int,
        repsText: String? = nil,
        weightText: String? = nil,
        targetRIRText: String? = nil,
        painTargetText: String? = nil,
        restText: String? = nil,
        tempo: String? = nil,
        setType: PlannedSetType = .working,
        notes: String? = nil,
        isWarmup: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        plannedExercise: PlannedExercise? = nil,
        setLogs: [SetLog] = []
    ) {
        self.id = id
        self.setNumber = setNumber
        self.repsText = repsText
        self.weightText = weightText
        self.targetRIRText = targetRIRText
        self.painTargetText = painTargetText
        self.restText = restText
        self.tempo = tempo
        self.setTypeRaw = setType.rawValue
        self.notes = notes
        self.isWarmup = isWarmup || setType == .warmup
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.plannedExercise = plannedExercise
        self.setLogs = setLogs
    }

    var setType: PlannedSetType {
        get {
            if let setTypeRaw, let setType = PlannedSetType(rawValue: setTypeRaw) {
                return setType
            }
            return isWarmup ? .warmup : .working
        }
        set {
            setTypeRaw = newValue.rawValue
            isWarmup = newValue == .warmup
        }
    }
}

@Model
final class SessionLog {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var durationSeconds: Int?
    var statusRaw: String
    var overallNotes: String?
    var maxPain: Int?
    var averageRIR: Double?
    var totalVolumeKg: Double?
    var warningMessages: [String]
    var createdAt: Date
    var updatedAt: Date
    var workoutPlan: WorkoutPlan?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.sessionLog)
    var exerciseLogs: [ExerciseLog]

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        completedAt: Date? = nil,
        durationSeconds: Int? = nil,
        status: SessionStatus = .active,
        overallNotes: String? = nil,
        maxPain: Int? = nil,
        averageRIR: Double? = nil,
        totalVolumeKg: Double? = nil,
        warningMessages: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        workoutPlan: WorkoutPlan? = nil,
        exerciseLogs: [ExerciseLog] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.statusRaw = status.rawValue
        self.overallNotes = overallNotes
        self.maxPain = maxPain
        self.averageRIR = averageRIR
        self.totalVolumeKg = totalVolumeKg
        self.warningMessages = warningMessages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.workoutPlan = workoutPlan
        self.exerciseLogs = exerciseLogs
    }
}

@Model
final class ExerciseLog {
    @Attribute(.unique) var id: UUID
    var startedAt: Date?
    var completedAt: Date?
    var actualRIR: Double?
    var actualPain: Int?
    var notes: String?
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var sessionLog: SessionLog?
    var plannedExercise: PlannedExercise?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exerciseLog)
    var setLogs: [SetLog]

    init(
        id: UUID = UUID(),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        actualRIR: Double? = nil,
        actualPain: Int? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sessionLog: SessionLog? = nil,
        plannedExercise: PlannedExercise? = nil,
        setLogs: [SetLog] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.actualRIR = actualRIR
        self.actualPain = actualPain
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sessionLog = sessionLog
        self.plannedExercise = plannedExercise
        self.setLogs = setLogs
    }
}

@Model
final class SetLog {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var plannedRepsText: String?
    var loggedReps: Int?
    var plannedWeightText: String?
    var loggedWeightKg: Double?
    var rir: Double?
    var pain: Int?
    var notes: String?
    var isWarmup: Bool
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var exerciseLog: ExerciseLog?
    var plannedSet: PlannedSet?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        plannedRepsText: String? = nil,
        loggedReps: Int? = nil,
        plannedWeightText: String? = nil,
        loggedWeightKg: Double? = nil,
        rir: Double? = nil,
        pain: Int? = nil,
        notes: String? = nil,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        exerciseLog: ExerciseLog? = nil,
        plannedSet: PlannedSet? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.plannedRepsText = plannedRepsText
        self.loggedReps = loggedReps
        self.plannedWeightText = plannedWeightText
        self.loggedWeightKg = loggedWeightKg
        self.rir = rir
        self.pain = pain
        self.notes = notes
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.exerciseLog = exerciseLog
        self.plannedSet = plannedSet
    }
}

typealias TrainingPlan = TrainingBlock
typealias TrainingSession = WorkoutPlan
typealias CompletedSession = SessionLog
typealias CompletedExercise = ExerciseLog
typealias CompletedSet = SetLog
