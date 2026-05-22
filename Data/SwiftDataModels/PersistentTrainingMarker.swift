import Foundation
import SwiftData

@Model
final class PersistentTrainingMarker {
    var id: UUID
    var createdAt: Date

    init(id: UUID = UUID(), createdAt: Date = .now) {
        self.id = id
        self.createdAt = createdAt
    }
}
