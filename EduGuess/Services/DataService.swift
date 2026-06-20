//
//  DataService.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation
import SwiftData

class DataService {

    // MARK: - SwiftData Operations

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

    // MARK: - Save Learned Character (agent learning)

    func saveLearnedCharacter(
        name: String,
        attributes: [String: Bool],
        context: ModelContext
    ) {
        // Avoid duplicates with same name
        let descriptor = FetchDescriptor<SDCharacter>(
            predicate: #Predicate { $0.name == name }
        )
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            // Character already known — update attributes
            existing.first?.attributes = attributes
            try? context.save()
            return
        }

        let sdCharacter = SDCharacter(name: name, attributes: attributes)
        context.insert(sdCharacter)
        try? context.save()
    }

    // MARK: - Save Game Session

    func saveGameSession(
        characterName: String,
        characterAttributes: [String: Bool],
        questionsAsked: [String],
        answers: [Bool],
        won: Bool,
        userId: String = "",
        userName: String = "",
        score: Int = 0,
        context: ModelContext
    ) {
        let session = SDGameSession(
            characterName: characterName,
            characterAttributes: characterAttributes,
            questionsAsked: questionsAsked,
            answers: answers,
            won: won
        )
        session.userId = userId
        session.userName = userName
        session.score = score
        context.insert(session)
        try? context.save()
    }

    // MARK: - Save Game Session to Firestore

    @discardableResult
    func saveSessionToFirestore(
        characterName: String,
        characterAttributes: [String: Bool],
        questionsAsked: [String],
        answers: [Bool],
        won: Bool,
        userId: String,
        userName: String,
        score: Int
    ) async -> Bool {
        let fbSession = FirebaseGameSession(
            userId: userId,
            userName: userName,
            characterName: characterName,
            won: won,
            score: score,
            questionsAsked: questionsAsked,
            answers: answers,
            timestamp: Date()
        )
        do {
            try await FirestoreService.shared.saveSession(fbSession)
            try await FirestoreService.shared.updateStats(uid: userId, won: won, score: score)
            let streak = await AchievementService.shared.updateStreak(uid: userId)
            if let fbUser = try? await FirestoreService.shared.fetchUser(uid: userId) {
                let _ = await AchievementService.shared.checkAndUnlock(uid: userId, stats: fbUser.stats, streak: streak, questionsCount: questionsAsked.count)
            }
            return true
        } catch {
            print("Failed to sync to Firestore: \(error)")
            return false
        }
    }

    // MARK: - Number of Known Characters

    func knownCharacterCount(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<SDCharacter>()
        return (try? context.fetch(descriptor).count) ?? 0
    }

    // MARK: - Generated Questions

    func fetchGeneratedQuestion(for attributeKey: String, context: ModelContext) -> SDGeneratedQuestion? {
        var descriptor = FetchDescriptor<SDGeneratedQuestion>(
            predicate: #Predicate { $0.attributeKey == attributeKey }
        )
        descriptor.sortBy = [SortDescriptor(\.timesUsed, order: .forward)]
        return try? context.fetch(descriptor).first
    }

    func fetchGeneratedQuestions(for attributeKeys: [String], context: ModelContext) -> [SDGeneratedQuestion] {
        var descriptor = FetchDescriptor<SDGeneratedQuestion>(
            predicate: #Predicate { attributeKeys.contains($0.attributeKey) }
        )
        descriptor.sortBy = [SortDescriptor(\.timesUsed, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }

    func saveGeneratedQuestion(attributeKey: String, questionText: String, context: ModelContext) {
        let q = SDGeneratedQuestion(attributeKey: attributeKey, questionText: questionText)
        context.insert(q)
        try? context.save()
    }

    func markGeneratedQuestionUsed(_ question: SDGeneratedQuestion, context: ModelContext) {
        question.timesUsed += 1
        try? context.save()
    }
}
