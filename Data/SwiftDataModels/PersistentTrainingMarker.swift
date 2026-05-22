import Foundation
import SwiftData

@Model
final class PersistentTrainingMarker {
    var id: UUID
    @Attribute(.unique) var key: String
    var createdAt: Date

    init(id: UUID = UUID(), key: String = UUID().uuidString, createdAt: Date = .now) {
        self.id = id
        self.key = key
        self.createdAt = createdAt
    }
}
