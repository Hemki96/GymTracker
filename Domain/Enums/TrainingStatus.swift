import Foundation

enum BlockStatus: String, Codable, CaseIterable {
    case planned
    case active
    case completed
    case archived
}

enum WorkoutStatus: String, Codable, CaseIterable {
    case planned
    case active
    case completed
    case skipped
}

enum SessionStatus: String, Codable, CaseIterable {
    case active
    case completed
    case cancelled
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case squat
    case hinge
    case pull
    case push
    case core
    case isolation
    case mobility
    case lowerBody
    case upperBody
    case unknown
}

enum PlannedSetType: String, Codable, CaseIterable {
    case working
    case warmup
    case backoff
    case dropSet
    case amrap

    var title: String {
        switch self {
        case .working:
            return "Arbeitssatz"
        case .warmup:
            return "Warm-up"
        case .backoff:
            return "Back-off"
        case .dropSet:
            return "Drop Set"
        case .amrap:
            return "AMRAP"
        }
    }
}
