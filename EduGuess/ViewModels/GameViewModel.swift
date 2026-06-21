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
    private let minimumQuestionsBeforeGuess = 12
    private let maximumQuestionsBeforeFail = 55
    private let minimumScoreToGuess = 8
    /// Question counts at which the AI must attempt a guess, even if confidence is low.
    private let forcedGuessMilestones: [Int] = [20, 30, 40, 50, 60]

    private var characterProfile: [String: Bool] = [:]
    private var askedAttributes: Set<String> = []
    private var sessionQuestions: [String] = []
    private var sessionAnswers: [AnswerType] = []
    private var allCharacters: [Character] = []
    private var possibleCharacters: [Character] = []
    private var characterScores: [UUID: Int] = [:]
    private let eliminationThreshold = -10
    private var generationTask: Task<Void, Never>?
    private var completedForcedGuesses: Set<Int> = []

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
        completedForcedGuesses.removeAll()
        gameState = .playing

        Task { await generateNextQuestion() }
    }

    // MARK: - Answer Question (5-level fuzzy scoring)

    func answerQuestion(answer: AnswerType) {
        let key = currentAttributeKey
        characterProfile[key] = answerValue(for: answer)
        sessionQuestions.append(key)
        sessionAnswers.append(answer)
        askedAttributes.insert(key)
        questionsAskedCount += 1

        let poolBefore = possibleCharacters.count

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

        // Learn from this attribute's usefulness (async, non-blocking)
        AttributeLearningService.shared.recordUse(
            attributeKey: key,
            poolBefore: poolBefore,
            poolAfter: possibleCharacters.count,
            ledToGuess: false,
            guessCorrect: false
        )

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
            // Definitive yes: strong reward for true, strong penalty for false
            if attributeValue == true { return 5 }
            if attributeValue == false { return -5 }
            return -1
        case .probablyYes:
            // Probably yes: moderate reward/penalty, small boost for unknown
            if attributeValue == true { return 2 }
            if attributeValue == false { return -2 }
            return 1
        case .unknown:
            return 0
        case .probablyNo:
            // Probably no: moderate penalty/reward, small boost for unknown
            if attributeValue == true { return -2 }
            if attributeValue == false { return 2 }
            return 1
        case .no:
            // Definitive no: strong penalty for true, strong reward for false
            if attributeValue == true { return -5 }
            if attributeValue == false { return 5 }
            return -1
        }
    }

    // MARK: - Respond to Guess Attempt

    func respondToGuess(correct: Bool) {
        isAttemptingGuess = false

        // Record learning for the attribute that triggered this guess
        if let lastAttribute = sessionQuestions.last {
            AttributeLearningService.shared.recordUse(
                attributeKey: lastAttribute,
                poolBefore: possibleCharacters.count,
                poolAfter: possibleCharacters.count,
                ledToGuess: true,
                guessCorrect: correct
            )
        }

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

        // If this was the final forced guess milestone (60) and it was wrong, fail the game.
        if questionsAskedCount >= forcedGuessMilestones.last ?? 60 {
            gameState = .failed
            finalProfile = characterProfile
            return
        }

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

    // MARK: - Guess Logic (score-gap and dominance based)

    private func shouldAttemptGuess() -> Bool {
        guard questionsAskedCount >= minimumQuestionsBeforeGuess, !possibleCharacters.isEmpty else {
            return false
        }

        // Always reveal if only 1 character remains
        if possibleCharacters.count == 1 { return true }

        let sorted = possibleCharacters.sorted {
            (characterScores[$0.id] ?? 0) > (characterScores[$1.id] ?? 0)
        }
        let topScore = characterScores[sorted[0].id] ?? 0
        let secondScore = sorted.count > 1 ? (characterScores[sorted[1].id] ?? 0) : Int.min
        let gap = topScore - secondScore

        // Dominance ratio: how much of the top-N score mass belongs to #1
        let topN = Array(sorted.prefix(min(5, sorted.count)))
        let totalTopScore = topN.reduce(0) { $0 + (characterScores[$1.id] ?? 0) }
        let dominanceRatio = totalTopScore > 0 ? Double(topScore) / Double(totalTopScore) : 0

        // Unique attributes of top candidate not shared by #2
        let topUniqueAttributes = uniqueTrueAttributes(candidate: sorted[0], comparedTo: Array(sorted.dropFirst()))

        // Early guess when the top candidate is clearly dominant
        if dominanceRatio >= 0.65 && topScore >= 10 { return true }
        if dominanceRatio >= 0.70 && topScore >= 6 { return true }

        // Big absolute gap thresholds
        if gap >= 10 { return true }
        if questionsAskedCount >= 15 && gap >= 7 { return true }
        if questionsAskedCount >= 20 && gap >= 5 { return true }

        // Top candidate has unique identifying attributes and a decent lead
        if !topUniqueAttributes.isEmpty && gap >= 4 && questionsAskedCount >= 14 {
            return true
        }

        // Very small pool: guess sooner
        if possibleCharacters.count == 2 && questionsAskedCount >= 16 { return true }
        if possibleCharacters.count == 3 && questionsAskedCount >= 18 && gap >= 4 { return true }

        // Force a guess at configured milestones if we haven't already.
        // If the user rejects it, the game continues until the next milestone.
        for milestone in forcedGuessMilestones {
            if questionsAskedCount >= milestone && !completedForcedGuesses.contains(milestone) {
                completedForcedGuesses.insert(milestone)
                return true
            }
        }

        return false
    }

    /// Attributes that the candidate has true and none of the compared characters have true.
    private func uniqueTrueAttributes(candidate: Character, comparedTo others: [Character]) -> [String] {
        candidate.attributes.compactMap { key, value -> String? in
            guard value == true else { return nil }
            let unique = others.allSatisfy { $0.attributes[key] != true }
            return unique ? key : nil
        }
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
        // Restore all characters if everyone was eliminated so the game can continue
        if possibleCharacters.isEmpty {
            possibleCharacters = allCharacters
            for c in possibleCharacters {
                characterScores[c.id] = 0
            }
        }

        // After many questions, if no candidate has a strong enough score, give up.
        // This improves precision by avoiding wild guesses when the user's answers
        // no longer match any known character well.
        if questionsAskedCount >= maximumQuestionsBeforeFail && gameState == .playing {
            let sorted = possibleCharacters.sorted {
                (characterScores[$0.id] ?? 0) > (characterScores[$1.id] ?? 0)
            }
            let bestScore = sorted.first.flatMap { characterScores[$0.id] } ?? 0
            let secondScore = sorted.dropFirst().first.flatMap { characterScores[$0.id] } ?? 0
            let gap = bestScore - secondScore

            // If there is a clear leader, attempt a guess instead of failing
            if bestScore >= minimumScoreToGuess && gap >= 4 {
                attemptGuess()
                return
            }

            // Otherwise fail
            gameState = .failed
            finalProfile = characterProfile
            return
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
            allCharacters: allCharacters,
            characterScores: characterScores
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
                      !GenerativeAIConfig.apiKey.isEmpty else { continue }

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
        completedForcedGuesses.removeAll()
        gameState = .playing
    }
}
