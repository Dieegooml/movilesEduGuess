import Foundation

class AIService {

    static let shared = AIService()

    private let pool = AttributeDefinition.pool

    /// Attributes that are semantically related. When a user answers "yes" to a
    /// parent attribute, we boost the related attributes so the next questions
    /// stay on-topic and narrow the candidate pool faster.
    private let relatedAttributes: [String: [String]] = [
        "isFootballer": ["isAthlete", "isLatinAmerican", "isFromEurope", "isStrong", "drivesVehicle", "isFamous", "isControversial"],
        "isSinger": ["isMusician", "isFamous", "isFromMovie", "isActor", "isDancer", "isControversial", "isLatinAmerican"],
        "isActor": ["isFromMovie", "isFromTV", "isFamous", "isControversial", "isSinger", "isDancer"],
        "isFromMarvel": ["isSuperhero", "isFromMovie", "isFromComic", "hasSuperpowers", "isStrong", "isVillain"],
        "isFromDC": ["isSuperhero", "isFromMovie", "isFromComic", "hasSuperpowers", "isStrong", "isVillain"],
        "isSuperhero": ["hasSuperpowers", "isFromMovie", "isFromComic", "isStrong", "isVillain", "wearsCape"],
        "isVillain": ["isFromMovie", "isFromComic", "hasSuperpowers", "isMagical", "isStrong"],
        "isMagical": ["usesMagic", "hasSuperpowers", "isFromMythology", "isFromMovie"],
        "isFromDisney": ["isFromMovie", "isFromTV", "isMagical", "hasSuperpowers"],
        "isFromStarWars": ["isFromMovie", "usesTechnology", "hasSuperpowers", "isVillain"],
        "isScientist": ["isSmart", "usesTechnology", "isFromBook", "isWriter"],
        "isPolitician": ["isFamous", "isControversial", "isReligious", "isWriter"],
        "isReal": ["isHistorical", "isAlive", "isPolitician", "isScientist", "isAthlete"],
        "isFictional": ["isFromMovie", "isFromTV", "isFromBook", "isFromVideoGame", "isFromComic", "isMagical", "hasSuperpowers"],
        "isAnimal": ["isFromCartoon", "isFromDisney", "isMagical"],
        "isChild": ["isFromCartoon", "isFromDisney", "isFromTV"],
        "isElderly": ["isScientist", "isPolitician", "isReligious", "hasBeard"],
        "isFemale": ["isSinger", "isActor", "isRoyalty"],
        "isRoyalty": ["isFromMythology", "isFromDisney", "isHistorical", "isPolitician"],
        "isFromMythology": ["isMagical", "hasSuperpowers", "isRoyalty", "isReligious"],
        "isFromAnime": ["isFromTV", "isFromVideoGame", "isFromComic", "hasSuperpowers", "isMagical"],
        "isFromVideoGame": ["isFromMovie", "isFromTV", "hasSuperpowers", "isStrong"],
        "isLatinAmerican": ["isFootballer", "isSinger", "isPolitician"],
        "isFromPeru": ["isLatinAmerican", "isPolitician", "isMusician", "isAthlete"],
        "isAthlete": ["isFootballer", "isStrong", "isFamous", "drivesVehicle"],
        "isWriter": ["isFromBook", "isSmart", "isScientist", "isPolitician"],
        "isReligious": ["isHistorical", "isRoyalty", "isPolitician"],
        "hasSuperpowers": ["isSuperhero", "isFromComic", "isFromMovie", "isStrong", "isMagical"],
        "usesTechnology": ["isScientist", "isFromStarWars", "isRobot", "isEngineer"],
        "isRobot": ["usesTechnology", "isFromMovie", "isFromTV"],
        "isAlien": ["isFromMovie", "isFromTV", "hasSuperpowers"],
        "isGhost": ["isFromMovie", "isFromTV", "isMagical"],
        "isPirate": ["isFromMovie", "isFromTV", "hasWeapon", "isVillain"],
        "isNinja": ["isFromAnime", "hasWeapon", "isStrong"],
        "isSamurai": ["hasWeapon", "isFromMovie", "isHistorical"],
        "isDoctor": ["isScientist", "isSmart", "isHuman"],
        "isEngineer": ["usesTechnology", "isScientist", "isSmart"],
        "isArtist": ["isFamous", "isControversial", "isHistorical"],
        "isDancer": ["isSinger", "isActor", "isFamous"],
        "isMusician": ["isSinger", "isFamous", "isFromTV"],
        "isFamous": ["isActor", "isSinger", "isAthlete", "isControversial"],
        "isControversial": ["isFamous", "isPolitician", "isActor", "isSinger"],
    ]

    // MARK: - Available Attributes (not yet asked)

    private func availableAttributes(askedAttributes: Set<String>) -> [AttributeDefinition] {
        pool.filter { !askedAttributes.contains($0.key) }
    }

    // MARK: - Select Next Attribute

    func selectNextAttribute(
        askedAttributes: [String],
        positiveAttributes: [String],
        possibleCharacters: [Character],
        allCharacters: [Character]
    ) -> AttributeDefinition? {
        let askedSet = Set(askedAttributes)
        let available = availableAttributes(askedAttributes: askedSet)
        guard !available.isEmpty else { return nil }

        // No conocidos aún → orden por defecto (categorías generales primero)
        guard !allCharacters.isEmpty else {
            return available.first
        }

        // Perfil no coincide con ningún conocido → orden por defecto
        guard !possibleCharacters.isEmpty else {
            return available.first
        }

        let positiveSet = Set(positiveAttributes)
        let relatedBoostTargets = relatedBoostTargets(for: positiveSet, availableKeys: Set(available.map(\.key)))

        var bestAttribute: AttributeDefinition?
        var bestScore: Double = -1

        for attribute in available {
            let gain = informationGain(
                attributeKey: attribute.key,
                characters: possibleCharacters
            )

            // Boost attributes related to previously positive answers
            let relatedBoost = relatedBoostTargets[attribute.key] ?? 0

            // Slightly penalize attributes that are unrelated to any positive answer
            // once we have established a clear theme (only after 3+ positive answers)
            let unrelatedPenalty: Double
            if positiveSet.count >= 3 && relatedBoost == 0 && !positiveSet.isEmpty {
                unrelatedPenalty = -0.08
            } else {
                unrelatedPenalty = 0
            }

            let score = gain + relatedBoost + unrelatedPenalty

            if score > bestScore {
                bestScore = score
                bestAttribute = attribute
            }
        }

        return bestAttribute ?? available.first
    }

    // MARK: - Relatedness Boost

    private func relatedBoostTargets(for positiveAttributes: Set<String>, availableKeys: Set<String>) -> [String: Double] {
        var boosts: [String: Double] = [:]

        for positiveKey in positiveAttributes {
            guard let related = relatedAttributes[positiveKey] else { continue }
            for relatedKey in related where availableKeys.contains(relatedKey) {
                boosts[relatedKey, default: 0] += 0.35
            }
        }

        return boosts
    }

    // MARK: - Generate Question Text

    func generateQuestion(for attributeKey: String) -> String {
        pool.first(where: { $0.key == attributeKey })?.generateQuestion()
            ?? "¿\(attributeKey)?"
    }

    // MARK: - Information Gain (entropy-based, supports true/false/nil)

    private func informationGain(
        attributeKey: String,
        characters: [Character]
    ) -> Double {
        let total = characters.count
        guard total > 1 else { return 0 }

        let trueCount = characters.filter { $0.attributes[attributeKey] == true }.count
        let falseCount = characters.filter { $0.attributes[attributeKey] == false }.count
        let nilCount = total - trueCount - falseCount

        // Attributes that are uniform or nearly uniform give low gain
        let nonZeroGroups = [trueCount, falseCount, nilCount].filter { $0 > 0 }
        guard nonZeroGroups.count >= 2 else { return 0 }

        // Entropy of a uniformly distributed set of N items: H(S) = log2(N)
        let entropyBefore = log2(Double(total))

        // Conditional entropy: weighted average of subgroup entropies
        // H(S|A) = Σ P(group) * log2(|S_group|)
        let counts = [trueCount, falseCount, nilCount]
        var entropyAfter: Double = 0
        for count in counts where count > 0 {
            let p = Double(count) / Double(total)
            entropyAfter += p * log2(Double(count))
        }

        // Bonus for attributes that split into 3 groups (more informative)
        let splitBonus = nonZeroGroups.count == 3 ? 0.05 : 0.0

        return (entropyBefore - entropyAfter) + splitBonus
    }
}
