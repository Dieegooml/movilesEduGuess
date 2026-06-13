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
        // Empty - users must add their own characters via CRUD
        return []
    }

    private func getDefaultQuestions() -> [Question] {
        // Empty - users must add their own questions via CRUD
        return []
    }

    // MARK: - SwiftData Operations

    func saveDefaultDataIfNeeded(context: ModelContext) {
        // Check if data already exists (no default data to load)
        let charDescriptor = FetchDescriptor<SDCharacter>()
        let questionDescriptor = FetchDescriptor<SDQuestion>()

        guard (try? context.fetch(charDescriptor).isEmpty) ?? true,
              (try? context.fetch(questionDescriptor).isEmpty) ?? true else {
            return // Data already exists
        }

        // No default data to save - database starts empty
        // Users will add data through the admin interface
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
        let characterName = character.name
        let descriptor = FetchDescriptor<SDCharacter>(
            predicate: #Predicate { $0.name == characterName }
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
        let questionText = question.text
        let descriptor = FetchDescriptor<SDQuestion>(
            predicate: #Predicate { $0.text == questionText }
        )
        guard let sdQuestions = try? context.fetch(descriptor),
              let sdQuestion = sdQuestions.first else {
            return
        }
        context.delete(sdQuestion)
        try? context.save()
    }

    // MARK: - Update Character

    func updateCharacter(
        _ character: Character,
        newName: String? = nil,
        newImage: String? = nil,
        newAttributes: [String: Bool]? = nil,
        context: ModelContext
    ) {
        let characterName = character.name
        let descriptor = FetchDescriptor<SDCharacter>(
            predicate: #Predicate { $0.name == characterName }
        )
        guard let sdCharacters = try? context.fetch(descriptor),
              let sdCharacter = sdCharacters.first else {
            return
        }

        if let name = newName {
            sdCharacter.name = name
        }
        if let image = newImage {
            sdCharacter.image = image
        }
        if let attributes = newAttributes {
            sdCharacter.attributes = attributes
        }

        try? context.save()
    }

    // MARK: - Update Question

    func updateQuestion(
        _ question: Question,
        newText: String? = nil,
        newAttributeKey: String? = nil,
        context: ModelContext
    ) {
        let questionText = question.text
        let descriptor = FetchDescriptor<SDQuestion>(
            predicate: #Predicate { $0.text == questionText }
        )
        guard let sdQuestions = try? context.fetch(descriptor),
              let sdQuestion = sdQuestions.first else {
            return
        }

        if let text = newText {
            sdQuestion.text = text
        }
        if let key = newAttributeKey {
            sdQuestion.attributeKey = key
        }

        try? context.save()
    }
}
