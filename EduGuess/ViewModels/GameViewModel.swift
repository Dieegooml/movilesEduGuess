//
//  GameViewModel.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentQuestionIndex = 0
    @Published var gameState: GameState = .playing
    @Published var filteredCharacters: [Character] = []

    // MARK: - Properties (loaded from SwiftData)

    @Published var questions: [Question] = []
    @Published var characters: [Character] = []

    // MARK: - Init

    init() {
        // Data is loaded from SwiftData via loadData()
    }

    // MARK: - Current Question

    var currentQuestion: Question {
        guard currentQuestionIndex < questions.count else {
            return Question(text: "No hay preguntas", attributeKey: "")
        }
        return questions[currentQuestionIndex]
    }

    // MARK: - Answer Logic

    func answerQuestion(answer: Bool) {
        let key = currentQuestion.attributeKey

        filteredCharacters = filteredCharacters.filter {
            $0.attributes[key] == answer
        }

        nextQuestion()
    }

    // MARK: - Next Question

    func nextQuestion() {
        if filteredCharacters.count == 1 {
            gameState = .guessed
            return
        }

        if filteredCharacters.isEmpty {
            gameState = .failed
            return
        }

        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            gameState = .failed
        }
    }

    // MARK: - Reset Game

    func resetGame() {
        currentQuestionIndex = 0
        filteredCharacters = characters
        gameState = .playing
    }

    // MARK: - Load Data from SwiftData

    func loadData(characters: [Character], questions: [Question]) {
        self.characters = characters
        self.questions = questions
        resetGame()
    }

    // MARK: - Final Character

    var guessedCharacter: Character? {
        filteredCharacters.first
    }

    // MARK: - Game Status

    var hasValidData: Bool {
        !characters.isEmpty && !questions.isEmpty
    }
}
