import Foundation

class AIService {

    static let shared = AIService()

    private let pool = AttributeDefinition.pool

    // MARK: - Available Attributes (not yet asked)

    private func availableAttributes(askedAttributes: [String]) -> [AttributeDefinition] {
        pool.filter { !askedAttributes.contains($0.key) }
    }

    // MARK: - Select Next Attribute

    func selectNextAttribute(
        askedAttributes: [String],
        possibleCharacters: [Character],
        allCharacters: [Character]
    ) -> AttributeDefinition? {
        let available = availableAttributes(askedAttributes: askedAttributes)
        guard !available.isEmpty else { return nil }

        // No conocidos aún → orden por defecto (categorías generales primero)
        guard !allCharacters.isEmpty else {
            return available.first
        }

        // Perfil no coincide con ningún conocido → orden por defecto
        guard !possibleCharacters.isEmpty else {
            return available.first
        }

        var bestAttribute: AttributeDefinition?
        var bestGain: Double = -1

        for attribute in available {
            let gain = informationGain(
                attributeKey: attribute.key,
                characters: possibleCharacters
            )
            if gain > bestGain {
                bestGain = gain
                bestAttribute = attribute
            }
        }

        return bestAttribute ?? available.first
    }

    // MARK: - Generate Question Text

    func generateQuestion(for attributeKey: String) -> String {
        pool.first(where: { $0.key == attributeKey })?.generateQuestion()
            ?? "¿\(attributeKey)?"
    }

    // MARK: - Information Gain (entropy-based)

    private func informationGain(
        attributeKey: String,
        characters: [Character]
    ) -> Double {
        let total = characters.count
        guard total > 1 else { return 0 }

        let trueCount = characters.filter { $0.attributes[attributeKey] == true }.count
        let falseCount = total - trueCount

        guard trueCount > 0 && falseCount > 0 else { return 0 }

        // H(S) = log2(|S|)
        let entropyBefore = log2(Double(total))

        // H(S|A) = P(v) * log2(|S_v|) + P(¬v) * log2(|S_¬v|)
        let pTrue = Double(trueCount) / Double(total)
        let pFalse = Double(falseCount) / Double(total)
        let entropyAfter = pTrue * log2(Double(trueCount)) + pFalse * log2(Double(falseCount))

        return entropyBefore - entropyAfter
    }
}
