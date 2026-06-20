import Foundation
import SwiftUI
import SwiftData

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
    @Published var generationError: Bool = false
    @Published var isGenerating: Bool = false

    // MARK: - Internal State

    private let dataService = DataService()
    private var modelContext: ModelContext?
    private let totalAttributes = AttributeDefinition.pool.count
    private let minimumQuestionsBeforeGuess = 15

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
    var progressRatio: Double {
        guard !allCharacters.isEmpty else { return 0 }
        return 1.0 - Double(possibleCharacters.count) / Double(allCharacters.count)
    }
    var finalScore: Int {
        guard gameState == .guessed else { return 0 }
        return GameScoring.calculateScore(questionsAsked: questionsAskedCount, won: true)
    }

    // MARK: - Start Game

    func startNewGame(characters: [Character], context: ModelContext) {
        modelContext = context
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

        Task { await generateNextQuestion() }
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
                Task { await generateNextQuestion() }
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
            Task { await generateNextQuestion() }
        }
    }

    // MARK: - Guess Logic (Akinator-style)

    private func shouldAttemptGuess() -> Bool {
        guard questionsAskedCount >= minimumQuestionsBeforeGuess, !possibleCharacters.isEmpty else {
            return false
        }
        let ratio = Double(possibleCharacters.count) / Double(max(allCharacters.count, 1))
        if ratio <= 0.05 {
            return true
        }
        let guessInterval = max(4, totalAttributes / 6)
        return possibleCharacters.count <= 2 || questionsAskedCount % guessInterval == 0
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

    private func generateNextQuestion() async {
        await MainActor.run { isGenerating = true }

        guard let context = modelContext else {
            await MainActor.run {
                generationError = true
                isGenerating = false
            }
            return
        }

        let remainingKeys = AttributeDefinition.pool.map(\.key).filter { !askedAttributes.contains($0) }

        // 1 — prefer least-used saved question
        let saved = dataService.fetchGeneratedQuestions(for: remainingKeys, context: context)
        if let best = saved.first {
            let key = best.attributeKey
            let question = best.questionText
            dataService.markGeneratedQuestionUsed(best, context: context)
            await MainActor.run {
                generationError = false
                isGenerating = false
                currentAttributeKey = key
                currentQuestion = question
            }
            // background: generate more questions for future rounds
            generateAndCacheQuestions(for: remainingKeys.filter { $0 != key })
            return
        }

        // 2 — fallback to template question
        guard let attribute = AIService.shared.selectNextAttribute(
            askedAttributes: askedAttributes,
            possibleCharacters: possibleCharacters,
            allCharacters: allCharacters
        ) else {
            await MainActor.run {
                finalProfile = characterProfile
                gameState = .failed
                isGenerating = false
            }
            return
        }

        await MainActor.run {
            generationError = false
            isGenerating = false
            currentAttributeKey = attribute.key
            currentQuestion = AIService.shared.generateQuestion(for: attribute.key)
        }

        // background: generate questions for remaining attributes
        generateAndCacheQuestions(for: remainingKeys)
    }

    /// Picks attributes with fewest saved questions and asks Gemini to generate new ones.
    private func generateAndCacheQuestions(for attributeKeys: [String]) {
        guard let context = modelContext else { return }

        Task.detached(priority: .background) {
            let savedKeys = Set(
                self.dataService.fetchGeneratedQuestions(for: attributeKeys, context: context)
                    .map(\.attributeKey)
            )
            // pick up to 2 attributes that have NO saved question yet
            let needsGeneration = attributeKeys.filter { !savedKeys.contains($0) }.prefix(2)
            guard !needsGeneration.isEmpty else { return }

            for key in needsGeneration {
                guard let attribute = AttributeDefinition.pool.first(where: { $0.key == key }) else { continue }
                // call Gemini to generate a question for this specific attribute
                let prompt = """
                Genera una pregunta en español para un juego de adivinanza tipo Akinator.
                La pregunta debe ser para determinar si un personaje tiene el atributo "\(attribute.key)".
                Responde SOLO con el texto de la pregunta, sin explicaciones ni formato.
                """
                guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(GenerativeAIConfig.apiKey)"),
                      GenerativeAIConfig.apiKey != "YOUR_GEMINI_API_KEY_HERE" else { continue }

                let body: [String: Any] = [
                    "contents": [["parts": [["text": prompt]]]],
                    "generationConfig": ["temperature": 0.8]
                ]
                guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { continue }

                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.timeoutInterval = 10
                req.httpBody = bodyData

                guard let (data, _) = try? await URLSession.shared.data(for: req),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let candidates = json["candidates"] as? [[String: Any]],
                      let content = candidates.first?["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let text = parts.first?["text"] as? String else { continue }

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // save to DB on main context
                await MainActor.run {
                    self.dataService.saveGeneratedQuestion(attributeKey: key, questionText: trimmed, context: context)
                }
            }
        }
    }

    func retryQuestion() {
        Task { await generateNextQuestion() }
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
