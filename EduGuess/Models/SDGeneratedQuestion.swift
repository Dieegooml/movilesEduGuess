import Foundation
import SwiftData

@Model
final class SDGeneratedQuestion {
    @Attribute(.unique) var id: UUID = UUID()
    var attributeKey: String
    var questionText: String
    var timesUsed: Int = 0
    var createdAt: Date = Date()

    init(attributeKey: String, questionText: String) {
        self.attributeKey = attributeKey
        self.questionText = questionText
    }
}
