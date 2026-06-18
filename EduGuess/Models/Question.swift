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

// MARK: - SwiftData Models

@Model
final class SDQuestion {
    @Attribute(.unique) var id: UUID = UUID()
    var text: String
    var attributeKey: String
    
    // MARK: - Learning Statistics
    var timesAsked: Int = 0           // ¿Cuántas veces se preguntó?
    var correctFilters: Int = 0       // ¿Cuántas veces ayudó a filtrar?
    var accuracy: Double = 0.0        // % de efectividad

    init(text: String, attributeKey: String) {
        self.text = text
        self.attributeKey = attributeKey
    }

    func toQuestion() -> Question {
        Question(text: text, attributeKey: attributeKey)
    }
    
    // MARK: - Update Statistics
    func updateStats(wasHelpful: Bool) {
        timesAsked += 1
        if wasHelpful {
            correctFilters += 1
        }
        accuracy = timesAsked > 0 ? Double(correctFilters) / Double(timesAsked) : 0.0
    }
}

// MARK: - Game Session (Learning History)
@Model
final class SDGameSession {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: String = ""
    var userName: String = ""
    var characterName: String
    var attributesData: Data?
    var questionsAsked: [String]
    var answers: [Bool]
    var won: Bool
    var score: Int = 0
    var timestamp: Date = Date()

    var characterAttributes: [String: Bool] {
        get {
            guard let data = attributesData else { return [:] }
            return (try? JSONDecoder().decode([String: Bool].self, from: data)) ?? [:]
        }
        set { attributesData = (try? JSONEncoder().encode(newValue)) }
    }

    init(characterName: String,
         characterAttributes: [String: Bool],
         questionsAsked: [String],
         answers: [Bool],
         won: Bool) {
        self.characterName = characterName
        self.attributesData = (try? JSONEncoder().encode(characterAttributes)) ?? Data()
        self.questionsAsked = questionsAsked
        self.answers = answers
        self.won = won
    }
}
