//
//  Question.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation
import SwiftData

// MARK: - In-Memory Representation
struct Question: Identifiable {

    let id: UUID = UUID()
    let text: String
    let attributeKey: String
}

// MARK: - SwiftData Model
@Model
final class SDQuestion {
    @Attribute(.unique) var id: UUID = UUID()
    var text: String
    var attributeKey: String

    init(text: String, attributeKey: String) {
        self.text = text
        self.attributeKey = attributeKey
    }

    func toQuestion() -> Question {
        Question(text: text, attributeKey: attributeKey)
    }
}
