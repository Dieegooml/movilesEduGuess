import Foundation
import SwiftUI

enum AnswerType {
    case yes
    case no
    case unknown
}

class GameViewModel: ObservableObject {

    // MARK: - Published Properties (UI State)

    @Published var gameState: GameState = .playing
    @Published var currentQuestion: String = ""
    @Published var currentAttributeKey: String = ""
    @Published var questionsAskedCount: Int = 0
    @Published var guessedCharacter: Character?
    @Published var finalProfile: [String: Bool] = [:]
    @Published var isAttemptingGuess: Bool = false
    @Published var guessCandidate: Character?

    // MARK: - Internal State

    private let aiService = AIService.shared
    private let totalAttributes = AttributeDefinition.pool.count
    private let minimumQuestionsBeforeGuess = 5

    private var characterProfile: [String: Bool] = [:]
    private var askedAttributes: [String] = []
    private var sessionQuestions: [String] = []
    private var sessionAnswers: [Bool] = []
    private var allCharacters: [Character] = []
    private var possibleCharacters: [Character] = []

    // MARK: - Read-Only Exports

    var askedAttributeKeys: [String] { sessionQuestions }
    var givenAnswers: [Bool] { sessionAnswers }
    var hasValidData: Bool { true }
    var remainingAttributes: Int { totalAttributes - askedAttributes.count }
    var finalScore: Int {
        guard gameState == .guessed else { return 0 }
        return GameScoring.calculateScore(questionsAsked: questionsAskedCount, won: true)
    }

    // MARK: - Start Game

    func startNewGame(characters: [Character]) {
        characterProfile = [:]
        askedAttributes = []
        sessionQuestions = []
        sessionAnswers = []
        allCharacters = characters
        possibleCharacters = allCharacters
        questionsAskedCount = 0
        guessedCharacter = nil
        finalProfile = [:]
        isAttemptingGuess = false
        guessCandidate = nil
        gameState = .playing

        generateNextQuestion()
    }

    // MARK: - Answer Question (Sí / No / No sé)

    func answerQuestion(answer: AnswerType) {
        switch answer {
        case .yes:
            characterProfile[currentAttributeKey] = true
            possibleCharacters = possibleCharacters.filter {
                $0.attributes[currentAttributeKey] == true
            }
            sessionQuestions.append(currentAttributeKey)
            sessionAnswers.append(true)

        case .no:
            characterProfile[currentAttributeKey] = false
            possibleCharacters = possibleCharacters.filter {
                $0.attributes[currentAttributeKey] == false
            }
            sessionQuestions.append(currentAttributeKey)
            sessionAnswers.append(false)

        case .unknown:
            break
        }

        askedAttributes.append(currentAttributeKey)
        questionsAskedCount += 1

        evaluateGameState()

        if gameState == .playing {
            if shouldAttemptGuess() {
                attemptGuess()
            } else {
                generateNextQuestion()
            }
        }
    }

    // MARK: - Respond to Guess Attempt

    func respondToGuess(correct: Bool) {
        isAttemptingGuess = false

        if correct, let character = guessCandidate {
            guessedCharacter = character
            finalProfile = characterProfile
            gameState = .guessed
            guessCandidate = nil
            return
        }

        if let character = guessCandidate {
            possibleCharacters.removeAll { $0.id == character.id }
        }
        guessCandidate = nil

        evaluateGameState()

        if gameState == .playing {
            generateNextQuestion()
        }
    }

    // MARK: - Guess Logic (Akinator-style)

    private func shouldAttemptGuess() -> Bool {
        guard questionsAskedCount >= minimumQuestionsBeforeGuess, !possibleCharacters.isEmpty else {
            return false
        }
        let ratio = Double(possibleCharacters.count) / Double(max(allCharacters.count, 1))
        if ratio <= 0.1 {
            return true
        }
        let guessInterval = max(3, totalAttributes / 6)
        return possibleCharacters.count <= 3 || questionsAskedCount % guessInterval == 0
    }

    private func attemptGuess() {
        guessCandidate = possibleCharacters.first
        isAttemptingGuess = true
    }

    // MARK: - Evaluation

    private func evaluateGameState() {
        if possibleCharacters.count == 1, questionsAskedCount >= minimumQuestionsBeforeGuess {
            guessedCharacter = possibleCharacters.first
            finalProfile = characterProfile
            gameState = .guessed
        } else if possibleCharacters.isEmpty {
            finalProfile = characterProfile
            gameState = .failed
        }
    }

    // MARK: - Generate Next Question

    private func generateNextQuestion() {
        guard let attribute = aiService.selectNextAttribute(
            askedAttributes: askedAttributes,
            possibleCharacters: possibleCharacters,
            allCharacters: allCharacters
        ) else {
            finalProfile = characterProfile
            gameState = .failed
            return
        }

        currentAttributeKey = attribute.key
        currentQuestion = aiService.generateQuestion(for: attribute.key)
    }

    // MARK: - Reset

    func resetGame() {
        characterProfile = [:]
        askedAttributes = []
        sessionQuestions = []
        sessionAnswers = []
        allCharacters = []
        possibleCharacters = []
        questionsAskedCount = 0
        currentQuestion = ""
        currentAttributeKey = ""
        guessedCharacter = nil
        finalProfile = [:]
        isAttemptingGuess = false
        guessCandidate = nil
        gameState = .playing
    }
}
