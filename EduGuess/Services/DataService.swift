//
//  DataService.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation
import SwiftData

class DataService {

    // MARK: - Default/Seed Data

    private func getDefaultCharacters() -> [Character] {
        [
            Character(name: "Harry Potter", image: "harry", attributes: [
                "usesMagic": true,
                "wearsGlasses": true,
                "isReal": false,
                "isMale": true
            ]),
            Character(name: "Hermione Granger", image: "hermione", attributes: [
                "usesMagic": true,
                "wearsGlasses": false,
                "isReal": false,
                "isMale": false
            ]),
            Character(name: "Albert Einstein", image: "einstein", attributes: [
                "usesMagic": false,
                "wearsGlasses": false,
                "isReal": true,
                "isMale": true
            ])
        ]
    }

    private func getDefaultQuestions() -> [Question] {
        [
            Question(text: "¿Tu personaje usa magia?", attributeKey: "usesMagic"),
            Question(text: "¿Tu personaje usa lentes?", attributeKey: "wearsGlasses"),
            Question(text: "¿Tu personaje es real?", attributeKey: "isReal"),
            Question(text: "¿Tu personaje es hombre?", attributeKey: "isMale")
        ]
    }

    // MARK: - SwiftData Operations

    func saveDefaultDataIfNeeded(context: ModelContext) {
        // Check if data already exists
        let charDescriptor = FetchDescriptor<SDCharacter>()
        let questionDescriptor = FetchDescriptor<SDQuestion>()

        guard (try? context.fetch(charDescriptor).isEmpty) ?? true,
              (try? context.fetch(questionDescriptor).isEmpty) ?? true else {
            return // Data already exists
        }

        // Insert default characters
        for character in getDefaultCharacters() {
            let sdCharacter = SDCharacter(
                name: character.name,
                image: character.image,
                attributes: character.attributes
            )
            context.insert(sdCharacter)
        }

        // Insert default questions
        for question in getDefaultQuestions() {
            let sdQuestion = SDQuestion(
                text: question.text,
                attributeKey: question.attributeKey
            )
            context.insert(sdQuestion)
        }

        try? context.save()
    }

    func fetchCharacters(context: ModelContext) -> [Character] {
        let descriptor = FetchDescriptor<SDCharacter>(sortBy: [SortDescriptor(\.name)])
        guard let sdCharacters = try? context.fetch(descriptor) else {
            return []
        }
        return sdCharacters.map { $0.toCharacter() }
    }

    func fetchQuestions(context: ModelContext) -> [Question] {
        let descriptor = FetchDescriptor<SDQuestion>(sortBy: [SortDescriptor(\.text)])
        guard let sdQuestions = try? context.fetch(descriptor) else {
            return []
        }
        return sdQuestions.map { $0.toQuestion() }
    }

    // MARK: - Add Character

    func addCharacter(
        name: String,
        image: String,
        attributes: [String: Bool],
        context: ModelContext
    ) {
        let sdCharacter = SDCharacter(name: name, image: image, attributes: attributes)
        context.insert(sdCharacter)
        try? context.save()
    }

    // MARK: - Add Question

    func addQuestion(
        text: String,
        attributeKey: String,
        context: ModelContext
    ) {
        let sdQuestion = SDQuestion(text: text, attributeKey: attributeKey)
        context.insert(sdQuestion)
        try? context.save()
    }

    // MARK: - Delete Character

    func deleteCharacter(_ character: Character, context: ModelContext) {
        let descriptor = FetchDescriptor<SDCharacter>(
            predicate: #Predicate { $0.name == character.name }
        )
        guard let sdCharacters = try? context.fetch(descriptor),
              let sdCharacter = sdCharacters.first else {
            return
        }
        context.delete(sdCharacter)
        try? context.save()
    }

    // MARK: - Delete Question

    func deleteQuestion(_ question: Question, context: ModelContext) {
        let descriptor = FetchDescriptor<SDQuestion>(
            predicate: #Predicate { $0.text == question.text }
        )
        guard let sdQuestions = try? context.fetch(descriptor),
              let sdQuestion = sdQuestions.first else {
            return
        }
        context.delete(sdQuestion)
        try? context.save()
    }
}
