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
