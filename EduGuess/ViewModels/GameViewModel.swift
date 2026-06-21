import Foundation
import SwiftUI
import SwiftData

enum AnswerType: String {
    case yes = "yes"
    case probablyYes = "probably_yes"
    case unknown = "unknown"
    case probablyNo = "probably_no"
    case no = "no"
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
    @Published var isRevealing: Bool = false
    @Published var guessCandidate: Character?
    @Published var generationError: Bool = false
    @Published var isGenerating: Bool = false

    // MARK: - Internal State

    private let dataService = DataService()
    private var modelContext: ModelContext?
    private let totalAttributes = AttributeDefinition.pool.count
    private let minimumQuestionsBeforeGuess = 18

    private var characterProfile: [String: Bool] = [:]
    private var askedAttributes: [String] = []
    private var sessionQuestions: [String] = []
    private var sessionAnswers: [AnswerType] = []
    private var allCharacters: [Character] = []
    private var possibleCharacters: [Character] = []
    private var characterScores: [UUID: Int] = [:]
    private let eliminationThreshold = -10
    private var generationTask: Task<Void, Never>?
    private var hasForcedGuessAt30 = false

    // MARK: - Read-Only Exports

    var askedAttributeKeys: [String] { sessionQuestions }
    var givenAnswers: [AnswerType] { sessionAnswers }
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
        generationTask?.cancel()
        modelContext = context
        characterProfile = [:]
        askedAttributes = []
        sessionQuestions = []
        sessionAnswers = []
        allCharacters = characters
        possibleCharacters = allCharacters
        characterScores = Dictionary(uniqueKeysWithValues: characters.map { ($0.id, 0) })
        questionsAskedCount = 0
        guessedCharacter = nil
        finalProfile = [:]
        isAttemptingGuess = false
        isRevealing = false
        guessCandidate = nil
        hasForcedGuessAt30 = false
        gameState = .playing

        Task { await generateNextQuestion() }
    }

    // MARK: - Answer Question (5-level fuzzy scoring)

    func answerQuestion(answer: AnswerType) {
        let key = currentAttributeKey
        characterProfile[key] = answerValue(for: answer)
        sessionQuestions.append(key)
        sessionAnswers.append(answer)
        askedAttributes.append(key)
        questionsAskedCount += 1

        // Apply fuzzy scoring to all possible characters
        for character in possibleCharacters {
            let value = character.attributes[key]
            let delta = scoreDelta(answer: answer, attributeValue: value)
            characterScores[character.id, default: 0] += delta
        }

        // Sort by score descending and eliminate very low scores
        possibleCharacters.sort { (a, b) in
            (characterScores[a.id] ?? 0) > (characterScores[b.id] ?? 0)
        }
        possibleCharacters.removeAll { (characterScores[$0.id] ?? 0) <= eliminationThreshold }

        // Fallback: if everyone got eliminated, restore all characters and keep going
        if possibleCharacters.isEmpty {
            possibleCharacters = allCharacters
            for c in possibleCharacters {
                characterScores[c.id] = 0
            }
        }

        evaluateGameState()

        if gameState == .playing {
            if shouldAttemptGuess() {
                attemptGuess()
            } else {
                Task { await generateNextQuestion() }
            }
        }
    }

    private func answerValue(for answer: AnswerType) -> Bool? {
        switch answer {
        case .yes: return true
        case .probablyYes: return true
        case .unknown: return nil
        case .probablyNo: return false
        case .no: return false
        }
    }

    /// Fuzzy scoring with higher precision.
    /// Definitive answers are more strongly weighted to separate candidates faster.
    /// Probabilistic answers use softer deltas to avoid eliminating the real character
    /// when the user is unsure. Unknown/nil attributes are slightly penalized on
    /// definitive answers (the profile should ideally know) and rewarded on
    /// probabilistic answers (keeps incompletely-known characters alive).
    private func scoreDelta(answer: AnswerType, attributeValue: Bool?) -> Int {
        switch answer {
        case .yes:
            // Definitive yes: +4 if true, -4 if false, -1 if unknown
            if attributeValue == true { return 4 }
            if attributeValue == false { return -4 }
            return -1
        case .probablyYes:
            // Probably yes: +2 if true, -2 if false, +1 if unknown
            if attributeValue == true { return 2 }
            if attributeValue == false { return -2 }
            return 1
        case .unknown:
            return 0
        case .probablyNo:
            // Probably no: -2 if true, +2 if false, +1 if unknown
            if attributeValue == true { return -2 }
            if attributeValue == false { return 2 }
            return 1
        case .no:
            // Definitive no: -4 if true, +4 if false, -1 if unknown
            if attributeValue == true { return -4 }
            if attributeValue == false { return 4 }
            return -1
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

        // User said "No, it's not this character" — heavy penalty but not instant elimination
        if let character = guessCandidate {
            characterScores[character.id, default: 0] -= 8
            possibleCharacters.sort { (a, b) in
                (characterScores[a.id] ?? 0) > (characterScores[b.id] ?? 0)
            }
            possibleCharacters.removeAll { (characterScores[$0.id] ?? 0) <= eliminationThreshold }
        }
        guessCandidate = nil

        // Fallback if everyone eliminated
        if possibleCharacters.isEmpty {
            possibleCharacters = allCharacters
            for c in possibleCharacters {
                characterScores[c.id] = 0
            }
        }

        evaluateGameState()

        if gameState == .playing {
            Task { await generateNextQuestion() }
        }
    }

    // MARK: - Guess Logic (score-gap based)

    private func shouldAttemptGuess() -> Bool {
        guard questionsAskedCount >= minimumQuestionsBeforeGuess, !possibleCharacters.isEmpty else {
            return false
        }

        // Always reveal if only 1 character remains
        if possibleCharacters.count == 1 { return true }

        // Force a guess at exactly 30 questions if we haven't already.
        // If the user rejects it, the game continues normally past question 30.
        if questionsAskedCount >= 30 && !hasForcedGuessAt30 {
            hasForcedGuessAt30 = true
            return true
        }

        // Calculate score gap between #1 and #2
        let sorted = possibleCharacters
        guard sorted.count >= 2 else { return true }
        let topScore = characterScores[sorted[0].id] ?? 0
        let secondScore = characterScores[sorted[1].id] ?? 0
        let gap = topScore - secondScore

        // High confidence: big gap after many questions
        if questionsAskedCount >= 20 && gap >= 8 { return true }
        if questionsAskedCount >= 25 && gap >= 6 { return true }

        // Very high confidence regardless of question count
        if gap >= 12 { return true }

        // If we are down to just 2 characters, ask the user only after thorough filtering
        if possibleCharacters.count == 2 && questionsAskedCount >= 22 { return true }

        return false
    }

    private func attemptGuess() {
        guard let candidate = possibleCharacters.first else { return }
        guessCandidate = candidate
        if possibleCharacters.count == 1 {
            isRevealing = true
        } else {
            isAttemptingGuess = true
        }
    }

    func confirmGuess() {
        guard let character = guessCandidate else { return }
        guessedCharacter = character
        finalProfile = characterProfile
        isRevealing = false
        gameState = .guessed
    }

    // MARK: - Evaluation

    private func evaluateGameState() {
        // Only fail if we have exhausted all attributes and still can't decide
        if possibleCharacters.isEmpty {
            possibleCharacters = allCharacters
            for c in possibleCharacters {
                characterScores[c.id] = 0
            }
        }
        if askedAttributes.count >= totalAttributes && possibleCharacters.count > 1 {
            // If we used all attributes and still have multiple, pick the top scorer
            if let best = possibleCharacters.first {
                guessedCharacter = best
                finalProfile = characterProfile
                gameState = .guessed
            }
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
        let positiveAttributes = characterProfile.compactMap { $0.value ? $0.key : nil }
        guard let attribute = AIService.shared.selectNextAttribute(
            askedAttributes: askedAttributes,
            positiveAttributes: positiveAttributes,
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

        // Fetch saved questions on main actor first (SwiftData context is main-thread bound)
        let savedKeys = Set(
            dataService.fetchGeneratedQuestions(for: attributeKeys, context: context)
                .map(\.attributeKey)
        )
        let needsGeneration = attributeKeys.filter { !savedKeys.contains($0) }.prefix(2)
        guard !needsGeneration.isEmpty else { return }

        generationTask?.cancel()
        generationTask = Task(priority: .background) { [weak self] in
            guard let self = self else { return }

            for key in needsGeneration {
                guard !Task.isCancelled else { return }
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

    // MARK: - Save Guessed Character as New

    /// Saves the current guess candidate as a new character using the built profile.
    /// Returns true if saved, false if a character with this name already exists.
    func saveGuessedCharacterAsNew() -> Bool {
        guard let candidate = guessCandidate else { return false }
        guard let context = modelContext else { return false }

        // Build full attributes from profile (fill missing with false)
        let allKeys = AttributeDefinition.pool.map(\.key)
        var fullAttributes: [String: Bool] = Dictionary(uniqueKeysWithValues: allKeys.map { ($0, false) })
        for (key, value) in characterProfile {
            fullAttributes[key] = value
        }

        // Check for duplicate by name (case-insensitive)
        let allExisting = dataService.fetchCharacters(context: context)
        let lowerName = candidate.name.lowercased()
        if allExisting.contains(where: { $0.name.lowercased() == lowerName }) {
            return false
        }

        dataService.addCharacter(
            name: candidate.name,
            image: "",
            attributes: fullAttributes,
            context: context
        )

        // Also add to in-memory lists so it can be guessed in future games
        let newChar = dataService.fetchCharacters(context: context).first { $0.name.lowercased() == lowerName }
        if let newChar = newChar {
            allCharacters.append(newChar)
            possibleCharacters.append(newChar)
            characterScores[newChar.id] = 0
        }

        return true
    }

    // MARK: - Reset

    func resetGame() {
        generationTask?.cancel()
        characterProfile = [:]
        askedAttributes = []
        sessionQuestions = []
        sessionAnswers = []
        allCharacters = []
        possibleCharacters = []
        characterScores = [:]
        questionsAskedCount = 0
        currentQuestion = ""
        currentAttributeKey = ""
        guessedCharacter = nil
        finalProfile = [:]
        isAttemptingGuess = false
        isRevealing = false
        guessCandidate = nil
        hasForcedGuessAt30 = false
        gameState = .playing
    }
}
