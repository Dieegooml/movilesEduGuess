import Foundation

class AIService {

    static let shared = AIService()

    private let pool = AttributeDefinition.pool

    /// Attributes that are semantically related. When a user answers "yes" to a
    /// parent attribute, we boost the related attributes so the next questions
    /// stay on-topic and narrow the candidate pool faster.
    private let relatedAttributes: [String: [String]] = [
        "isFootballer": ["isAthlete", "isLatinAmerican", "isFromEurope", "isFromAfrica", "isFromAsia", "isStrong", "drivesVehicle", "isFamous", "isControversial", "isGoalkeeper", "isForward", "isMidfielder", "isDefender", "isCaptain", "isTall", "hasTattoos", "isBald", "isLeftFooted", "isWinger", "isStriker", "isFromBrazil", "isFromArgentina", "isFromSpain", "isFromEngland", "isFromFrance", "isFromGermany", "isFromItaly", "isFromPortugal", "isFromMexico", "isFromColombia", "isFromChile", "isFromUruguay", "isFromNetherlands", "isFromBelgium", "isFromCroatia", "isFromNorway"],
        "isSinger": ["isMusician", "isFamous", "isFromMovie", "isActor", "isDancer", "isControversial", "isLatinAmerican", "isFromEurope", "isFromNorthAmerica", "isFromUSA", "isFromCanada", "isFromUK", "isFromSpain", "isFromMexico", "isFromColombia", "isFromPuertoRico", "isRapper", "isRockSinger", "isPopSinger", "isCountrySinger", "isOperaSinger", "isReggaetonSinger", "isSalsaSinger", "isVeteran"],
        "isActor": ["isFromMovie", "isFromTV", "isFamous", "isControversial", "isSinger", "isDancer", "isFromUSA", "isFromCanada", "isFromUK", "isFromSpain", "isFromMexico"],
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
        "isLatinAmerican": ["isFootballer", "isSinger", "isPolitician", "isFromBrazil", "isFromArgentina", "isFromMexico", "isFromColombia", "isFromChile", "isFromUruguay", "isFromEcuador", "isFromVenezuela", "isFromParaguay", "isFromBolivia", "isFromPuertoRico", "isFromPeru"],
        "isFromPeru": ["isLatinAmerican", "isPolitician", "isMusician", "isAthlete"],
        "isAthlete": ["isFootballer", "isStrong", "isFamous", "drivesVehicle", "isTall", "isWinger", "isStriker", "isVeteran"],
        "isWriter": ["isFromBook", "isSmart", "isScientist", "isPolitician"],
        "isReligious": ["isHistorical", "isRoyalty", "isPolitician"],
        "hasSuperpowers": ["isSuperhero", "isFromComic", "isFromMovie", "isStrong", "isMagical"],
        "usesTechnology": ["isScientist", "isFromStarWars"],
        "isDancer": ["isSinger", "isActor", "isFamous"],
        "isMusician": ["isSinger", "isFamous", "isFromTV"],
        "isFamous": ["isActor", "isSinger", "isAthlete", "isControversial"],
        "isControversial": ["isFamous", "isPolitician", "isActor", "isSinger"],
        "isFromEurope": ["isFootballer", "isActor", "isSinger", "isFromSpain", "isFromEngland", "isFromFrance", "isFromGermany", "isFromItaly", "isFromPortugal", "isFromNetherlands", "isFromBelgium", "isFromCroatia", "isFromUK", "isFromSweden", "isFromPoland", "isFromNorway"],
        "isFromAfrica": ["isFootballer", "isAthlete"],
        "isFromAsia": ["isFootballer", "isFromVideoGame", "isFromAnime"],
        "isFromNorthAmerica": ["isActor", "isSinger", "isFromUSA", "isFromCanada"],
        "isFromBrazil": ["isFootballer", "isAthlete", "isLatinAmerican", "isStrong", "isFamous"],
        "isFromArgentina": ["isFootballer", "isAthlete", "isLatinAmerican", "isStrong", "isFamous"],
        "isFromSpain": ["isFootballer", "isAthlete", "isFromEurope", "isActor", "isSinger", "isFamous"],
        "isFromEngland": ["isFootballer", "isAthlete", "isFromEurope", "isActor", "isSinger", "isFamous"],
        "isFromFrance": ["isFootballer", "isAthlete", "isFromEurope", "isFamous"],
        "isFromGermany": ["isFootballer", "isAthlete", "isFromEurope", "isScientist", "isFamous"],
        "isFromItaly": ["isFootballer", "isAthlete", "isFromEurope", "isFamous"],
        "isFromPortugal": ["isFootballer", "isAthlete", "isFromEurope", "isFamous"],
        "isFromMexico": ["isFootballer", "isAthlete", "isLatinAmerican", "isActor", "isSinger", "isFamous"],
        "isFromColombia": ["isFootballer", "isAthlete", "isLatinAmerican", "isSinger", "isFamous"],
        "isFromChile": ["isFootballer", "isAthlete", "isLatinAmerican", "isFamous"],
        "isFromUruguay": ["isFootballer", "isAthlete", "isLatinAmerican", "isFamous"],
        "isFromUSA": ["isActor", "isSinger", "isFromNorthAmerica", "isFamous", "isControversial", "isPopSinger", "isRapper", "isFromMovie", "isFromTV", "isFromCartoon"],
        "isFromCanada": ["isActor", "isSinger", "isFromNorthAmerica", "isFamous", "isPopSinger"],
        "isFromNetherlands": ["isFootballer", "isAthlete", "isFromEurope", "isFamous"],
        "isFromBelgium": ["isFootballer", "isAthlete", "isFromEurope", "isFamous"],
        "isFromCroatia": ["isFootballer", "isAthlete", "isFromEurope", "isFamous"],
        "isFromUK": ["isActor", "isSinger", "isFromEurope", "isRockSinger", "isFamous"],
        "isFromPuertoRico": ["isSinger", "isLatinAmerican", "isReggaetonSinger", "isSalsaSinger", "isFamous"],
        "isFromNorway": ["isFootballer", "isAthlete", "isFromEurope", "isStriker", "isFamous"],
        "isRapper": ["isSinger", "isFromUSA", "isFamous", "isControversial"],
        "isRockSinger": ["isSinger", "isFromUK", "isFromUSA", "isFamous"],
        "isPopSinger": ["isSinger", "isFromUSA", "isFromCanada", "isFamous"],
        "isCountrySinger": ["isSinger", "isFromUSA", "isFamous"],
        "isOperaSinger": ["isSinger", "isFromEurope", "isVeteran", "isFamous"],
        "isReggaetonSinger": ["isSinger", "isLatinAmerican", "isFromPuertoRico", "isFromColombia", "isFamous"],
        "isSalsaSinger": ["isSinger", "isLatinAmerican", "isFromPuertoRico", "isFamous"],
        "isWinger": ["isFootballer", "isAthlete", "isStrong", "isFamous"],
        "isStriker": ["isFootballer", "isAthlete", "isStrong", "isFamous"],
        "isVeteran": ["isFootballer", "isAthlete", "isSinger", "isActor", "isFamous"],
        "isBlonde": ["isFemale", "isSinger", "isActor", "isPopSinger", "isFamous"],
    ]

    /// Theme groups define a strong contextual "topic". Once the user has
    /// answered yes to enough attributes that clearly point to a theme,
    /// attributes outside that theme are heavily penalized so the game focuses
    /// on narrowing the candidate pool within the topic.
    ///
    /// Format: [triggering attribute] -> [attributes considered in-theme]
    /// Attributes NOT in any active theme group (except safe general ones)
    /// receive a heavy penalty.
    private let themeGroups: [String: [String]] = [
        "isFootballer": ["isAthlete", "isFootballer", "isFamous", "isControversial", "isStrong", "isTall", "drivesVehicle", "hasTattoos", "isBald", "isLeftFooted", "isCaptain", "isGoalkeeper", "isForward", "isMidfielder", "isDefender", "isWinger", "isStriker", "isVeteran", "isFromEurope", "isFromAfrica", "isFromAsia", "isFromNorthAmerica", "isLatinAmerican", "isFromPeru", "isFromBrazil", "isFromArgentina", "isFromSpain", "isFromEngland", "isFromFrance", "isFromGermany", "isFromItaly", "isFromPortugal", "isFromMexico", "isFromColombia", "isFromChile", "isFromUruguay", "isFromNetherlands", "isFromBelgium", "isFromCroatia", "isFromNorway", "isYoung", "isAlive", "isReal"],
        "isAthlete": ["isAthlete", "isFootballer", "isStrong", "isTall", "isFamous", "isControversial", "drivesVehicle", "hasTattoos", "isBald", "isWinger", "isStriker", "isVeteran", "isFromEurope", "isFromAfrica", "isFromAsia", "isFromNorthAmerica", "isLatinAmerican", "isFromBrazil", "isFromArgentina", "isFromSpain", "isFromEngland", "isFromFrance", "isFromGermany", "isFromItaly", "isFromPortugal", "isFromMexico", "isFromColombia", "isFromChile", "isFromUruguay", "isFromNetherlands", "isFromBelgium", "isFromCroatia", "isFromNorway", "isYoung", "isAlive", "isReal"],
        "isSinger": ["isMusician", "isSinger", "isActor", "isDancer", "isFamous", "isControversial", "isFromMovie", "isFromTV", "isFromDisney", "isFromEurope", "isFromNorthAmerica", "isLatinAmerican", "isFromUSA", "isFromCanada", "isFromUK", "isFromSpain", "isFromMexico", "isFromColombia", "isFromPuertoRico", "isRapper", "isRockSinger", "isPopSinger", "isCountrySinger", "isOperaSinger", "isReggaetonSinger", "isSalsaSinger", "isBlonde", "isVeteran", "isYoung", "isAlive", "isReal"],
        "isActor": ["isActor", "isFromMovie", "isFromTV", "isFromDisney", "isSinger", "isDancer", "isFamous", "isControversial", "isFromEurope", "isFromNorthAmerica", "isLatinAmerican", "isFromUSA", "isFromCanada", "isFromUK", "isFromSpain", "isFromMexico", "isBlonde", "isYoung", "isAlive", "isReal"],
        "isFromMarvel": ["isFromMarvel", "isFromDC", "isSuperhero", "isFromMovie", "isFromComic", "hasSuperpowers", "isStrong", "isVillain", "wearsCape", "wearsHat", "isFamous"],
        "isFromDC": ["isFromMarvel", "isFromDC", "isSuperhero", "isFromMovie", "isFromComic", "hasSuperpowers", "isStrong", "isVillain", "wearsCape", "wearsHat", "isFamous"],
        "isSuperhero": ["isSuperhero", "isFromMarvel", "isFromDC", "isFromMovie", "isFromComic", "hasSuperpowers", "isStrong", "isVillain", "wearsCape", "isFamous"],
        "isFromAnime": ["isFromAnime", "isFromTV", "isFromVideoGame", "isFromComic", "isFromManga", "hasSuperpowers", "isMagical", "isHuman", "isChild", "isYoung"],
        "isFromMythology": ["isFromMythology", "isMagical", "hasSuperpowers", "isRoyalty", "isReligious", "isFromMovie", "isFromBook", "isFromComic", "isStrong", "isFamous"],
        "isScientist": ["isScientist", "isSmart", "usesTechnology", "isFromBook", "isWriter", "isHistorical", "isElderly", "isAlive", "isReal", "isFamous"],
        "isFromVideoGame": ["isFromVideoGame", "isFromMovie", "isFromTV", "isFromAnime", "hasSuperpowers", "isStrong", "isHuman", "isAnimal", "isMagical"],
        "isFromDisney": ["isFromDisney", "isFromMovie", "isFromTV", "isFromCartoon", "isMagical", "hasSuperpowers", "isHuman", "isAnimal", "isChild", "isRoyalty"],
        "isFromStarWars": ["isFromStarWars", "isFromMovie", "isFromTV", "isFromComic", "usesTechnology", "hasSuperpowers", "isVillain", "isHuman"],
        "isMagical": ["isMagical", "usesMagic", "hasSuperpowers", "isFromMythology", "isFromMovie", "isFromTV", "isFromDisney", "isFromAnime", "isWizard", "isWitch"],
        "isAnimal": ["isAnimal", "isFromCartoon", "isFromDisney", "isFromMovie", "isFromTV", "isMagical", "hasSuperpowers", "isChild"],
        "isPolitician": ["isPolitician", "isFamous", "isControversial", "isReligious", "isWriter", "isHistorical", "isElderly", "isAlive", "isReal"],
        "isFromBrazil": ["isFromBrazil", "isFootballer", "isAthlete", "isLatinAmerican", "isStrong", "isFamous", "isControversial", "isAlive", "isReal"],
        "isFromArgentina": ["isFromArgentina", "isFootballer", "isAthlete", "isLatinAmerican", "isStrong", "isFamous", "isControversial", "isLeftFooted", "isAlive", "isReal"],
        "isFromSpain": ["isFromSpain", "isFootballer", "isAthlete", "isFromEurope", "isActor", "isSinger", "isFamous", "isAlive", "isReal"],
        "isFromEngland": ["isFromEngland", "isFootballer", "isAthlete", "isFromEurope", "isActor", "isSinger", "isRockSinger", "isFamous", "isAlive", "isReal"],
        "isFromFrance": ["isFromFrance", "isFootballer", "isAthlete", "isFromEurope", "isFamous", "isAlive", "isReal"],
        "isFromGermany": ["isFromGermany", "isFootballer", "isAthlete", "isFromEurope", "isScientist", "isFamous", "isAlive", "isReal"],
        "isFromItaly": ["isFromItaly", "isFootballer", "isAthlete", "isFromEurope", "isFamous", "isAlive", "isReal"],
        "isFromPortugal": ["isFromPortugal", "isFootballer", "isAthlete", "isFromEurope", "isFamous", "isAlive", "isReal"],
        "isFromMexico": ["isFromMexico", "isFootballer", "isAthlete", "isLatinAmerican", "isActor", "isSinger", "isFamous", "isAlive", "isReal"],
        "isFromColombia": ["isFromColombia", "isFootballer", "isAthlete", "isLatinAmerican", "isSinger", "isReggaetonSinger", "isFamous", "isAlive", "isReal"],
        "isFromUSA": ["isFromUSA", "isFromNorthAmerica", "isActor", "isSinger", "isPopSinger", "isRapper", "isRockSinger", "isCountrySinger", "isFromMovie", "isFromTV", "isFromCartoon", "isFamous", "isControversial", "isVeteran", "isAlive", "isReal"],
        "isFromUK": ["isFromUK", "isFromEurope", "isActor", "isSinger", "isRockSinger", "isFamous", "isVeteran", "isAlive", "isReal"],
        "isFromPuertoRico": ["isFromPuertoRico", "isLatinAmerican", "isSinger", "isReggaetonSinger", "isSalsaSinger", "isFamous", "isAlive", "isReal"],
    ]

    /// General attributes that are always safe to ask regardless of theme.
    private let safeGeneralAttributes: Set<String> = [
        "isReal", "isFictional", "isHuman", "isAlive", "isHistorical",
        "isFemale", "isChild", "isElderly", "isFamous"
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

        // Determine active theme(s) based on positive answers
        let activeThemeAttributes = activeThemeAttributes(for: positiveSet)
        let hasStrongTheme = positiveSet.count >= 2 && !activeThemeAttributes.isEmpty

        var bestAttribute: AttributeDefinition?
        var bestScore: Double = -1

        for attribute in available {
            let gain = informationGain(
                attributeKey: attribute.key,
                characters: possibleCharacters
            )

            // Boost attributes related to previously positive answers
            let relatedBoost = relatedBoostTargets[attribute.key] ?? 0

            // Theme enforcement: heavy penalties for off-theme attributes once a
            // strong theme is established. Safe general attributes are exempt.
            var themePenalty: Double = 0
            if hasStrongTheme && !safeGeneralAttributes.contains(attribute.key) {
                if !activeThemeAttributes.contains(attribute.key) {
                    themePenalty = -0.7
                } else {
                    // Slightly boost in-theme attributes beyond relatedness
                    themePenalty = 0.15
                }
            }

            // Slightly penalize attributes that are unrelated to any positive answer
            // once we have established a clear theme (only after 3+ positive answers)
            let unrelatedPenalty: Double
            if positiveSet.count >= 3 && relatedBoost == 0 && !positiveSet.isEmpty && !activeThemeAttributes.contains(attribute.key) && !safeGeneralAttributes.contains(attribute.key) {
                unrelatedPenalty = -0.08
            } else {
                unrelatedPenalty = 0
            }

            let score = gain + relatedBoost + themePenalty + unrelatedPenalty

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

    // MARK: - Theme Enforcement

    private func activeThemeAttributes(for positiveAttributes: Set<String>) -> Set<String> {
        var active: Set<String> = []

        for positiveKey in positiveAttributes {
            if let themeAttributes = themeGroups[positiveKey] {
                active.formUnion(themeAttributes)
            }
        }

        return active
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
