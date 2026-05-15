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

    // MARK: - Questions

    let questions: [Question] = [

        Question(
            text: "¿Tu personaje usa magia?",
            attributeKey: "usesMagic"
        ),

        Question(
            text: "¿Tu personaje usa lentes?",
            attributeKey: "wearsGlasses"
        ),

        Question(
            text: "¿Tu personaje es real?",
            attributeKey: "isReal"
        ),

        Question(
            text: "¿Tu personaje es hombre?",
            attributeKey: "isMale"
        )
    ]

    // MARK: - Characters

    let characters: [Character] = [

        Character(
            name: "Harry Potter",
            image: "harry",
            attributes: [
                "usesMagic": true,
                "wearsGlasses": true,
                "isReal": false,
                "isMale": true
            ]
        ),

        Character(
            name: "Hermione Granger",
            image: "hermione",
            attributes: [
                "usesMagic": true,
                "wearsGlasses": false,
                "isReal": false,
                "isMale": false
            ]
        ),

        Character(
            name: "Albert Einstein",
            image: "einstein",
            attributes: [
                "usesMagic": false,
                "wearsGlasses": false,
                "isReal": true,
                "isMale": true
            ]
        )
    ]

    // MARK: - Init

    init() {
        filteredCharacters = characters
    }

    // MARK: - Current Question

    var currentQuestion: Question {
        questions[currentQuestionIndex]
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

    // MARK: - Final Character

    var guessedCharacter: Character? {
        filteredCharacters.first
    }
}
