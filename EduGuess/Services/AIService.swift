import Foundation

class AIService {

    static let shared = AIService()

    private let pool = AttributeDefinition.pool
    private let learningService = AttributeLearningService.shared

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

    /// Attributes that are logically implied by other attributes. If the parent
    /// attribute has been answered positively, asking the implied attribute is
    /// usually redundant and should be penalized.
    private let impliedAttributes: [String: [String]] = [
        "isFootballer": ["isAthlete", "isFamous"],
        "isAthlete": ["isReal", "isAlive"],
        "isSinger": ["isMusician", "isFamous"],
        "isActor": ["isFamous"],
        "isSuperhero": ["isFictional", "hasSuperpowers"],
        "isFromMarvel": ["isSuperhero", "isFictional", "isFromComic"],
        "isFromDC": ["isSuperhero", "isFictional", "isFromComic"],
        "isFromDisney": ["isFictional"],
        "isFromAnime": ["isFictional", "isFromTV"],
        "isFromVideoGame": ["isFictional"],
        "isFromMythology": ["isFictional", "isMagical"],
        "isMagical": ["hasSuperpowers"],
        "isWizard": ["isMagical", "usesMagic"],
        "isWitch": ["isMagical", "usesMagic"],
        "isRoyalty": ["isFamous"],
        "isPolitician": ["isReal", "isFamous"],
        "isScientist": ["isReal", "isSmart"],
        "isWriter": ["isReal", "isSmart"],
        "isFromBrazil": ["isLatinAmerican"],
        "isFromArgentina": ["isLatinAmerican"],
        "isFromMexico": ["isLatinAmerican"],
        "isFromColombia": ["isLatinAmerican"],
        "isFromChile": ["isLatinAmerican"],
        "isFromUruguay": ["isLatinAmerican"],
        "isFromPeru": ["isLatinAmerican"],
        "isFromPuertoRico": ["isLatinAmerican"],
        "isFromSpain": ["isFromEurope"],
        "isFromEngland": ["isFromEurope"],
        "isFromFrance": ["isFromEurope"],
        "isFromGermany": ["isFromEurope"],
        "isFromItaly": ["isFromEurope"],
        "isFromPortugal": ["isFromEurope"],
        "isFromNetherlands": ["isFromEurope"],
        "isFromBelgium": ["isFromEurope"],
        "isFromCroatia": ["isFromEurope"],
        "isFromNorway": ["isFromEurope"],
        "isFromUK": ["isFromEurope"],
        "isFromUSA": ["isFromNorthAmerica"],
        "isFromCanada": ["isFromNorthAmerica"],
        "isRapper": ["isSinger"],
        "isRockSinger": ["isSinger"],
        "isPopSinger": ["isSinger"],
        "isCountrySinger": ["isSinger"],
        "isOperaSinger": ["isSinger"],
        "isReggaetonSinger": ["isSinger"],
        "isSalsaSinger": ["isSinger"],
        "isWinger": ["isFootballer", "isAthlete"],
        "isStriker": ["isFootballer", "isAthlete"],
        "isGoalkeeper": ["isFootballer", "isAthlete"],
        "isDefender": ["isFootballer", "isAthlete"],
        "isMidfielder": ["isFootballer", "isAthlete"],
        "isForward": ["isFootballer", "isAthlete"],
        "isCaptain": ["isFootballer", "isAthlete"],
    ]

    // MARK: - Available Attributes (not yet asked)

    private func availableAttributes(askedAttributes: Set<String>) -> [AttributeDefinition] {
        pool.filter { !askedAttributes.contains($0.key) }
    }

    // MARK: - Select Next Attribute

    func selectNextAttribute(
        askedAttributes: Set<String>,
        positiveAttributes: [String],
        possibleCharacters: [Character],
        allCharacters: [Character],
        characterScores: [UUID: Int]
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

        let positiveSet = Set(positiveAttributes)
        let availableKeys = Set(available.map { $0.key })
        let relatedBoostTargets = relatedBoostTargets(for: positiveSet, availableKeys: availableKeys)

        // Determine active theme(s) based on positive answers
        let activeThemeAttributes = activeThemeAttributes(for: positiveSet)
        let hasStrongTheme = positiveSet.count >= 2 && !activeThemeAttributes.isEmpty

        // Top candidates by score
        let sortedCandidates = possibleCharacters.sorted {
            (characterScores[$0.id] ?? 0) > (characterScores[$1.id] ?? 0)
        }
        let topCandidates = Array(sortedCandidates.prefix(min(5, sortedCandidates.count)))

        // Learning boost from past games
        let learningBoosts = learningService.boosts(for: availableKeys)

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
            var themeAdjustment: Double = 0
            if hasStrongTheme && !safeGeneralAttributes.contains(attribute.key) {
                if !activeThemeAttributes.contains(attribute.key) {
                    themeAdjustment = -1.2
                } else {
                    // Strongly boost in-theme attributes
                    themeAdjustment = 0.35
                }
            }

            // Discriminative boost: prefer attributes that split the top candidates
            let discriminatorBoost = discriminatorBoost(
                attributeKey: attribute.key,
                topCandidates: topCandidates
            )

            // Unique-attribute boost: prefer attributes that the top candidate has true
            // and other top candidates do not, helping confirm a clear leader.
            let uniqueBoost = uniqueConfirmBoost(
                attributeKey: attribute.key,
                topCandidates: topCandidates
            )

            // Learning boost from historical success
            let learningBoost = learningBoosts[attribute.key] ?? 0

            // Penalize redundant attributes already implied by positive answers
            let redundancyPenalty = redundancyPenalty(for: attribute.key, positiveSet: positiveSet)

            // Slightly penalize attributes that are unrelated to any positive answer
            // once we have established a clear theme (only after 3+ positive answers)
            let unrelatedPenalty: Double
            if positiveSet.count >= 3 && relatedBoost == 0 && !positiveSet.isEmpty && !activeThemeAttributes.contains(attribute.key) && !safeGeneralAttributes.contains(attribute.key) {
                unrelatedPenalty = -0.15
            } else {
                unrelatedPenalty = 0
            }

            let score = gain + relatedBoost + themeAdjustment + discriminatorBoost + uniqueBoost + learningBoost + redundancyPenalty + unrelatedPenalty

            if score > bestScore {
                bestScore = score
                bestAttribute = attribute
            }
        }

        return bestAttribute ?? available.first
    }

    /// Penalizes attributes that are logically implied by already-positive answers.
    /// Asking them is usually redundant unless needed to break ties.
    private func redundancyPenalty(for attributeKey: String, positiveSet: Set<String>) -> Double {
        for positiveKey in positiveSet {
            if let implied = impliedAttributes[positiveKey], implied.contains(attributeKey) {
                return -0.5
            }
        }
        return 0
    }

    /// Returns a boost for attributes that create disagreement among the top candidates.
    /// Such attributes are highly valuable because they can quickly eliminate runners-up.
    private func discriminatorBoost(attributeKey: String, topCandidates: [Character]) -> Double {
        guard topCandidates.count >= 2 else { return 0 }
        let values = topCandidates.map { $0.attributes[attributeKey] }
        let trueCount = values.filter { $0 == true }.count
        let falseCount = values.filter { $0 == false }.count
        let nilCount = values.filter { $0 == nil }.count

        // Perfect split: some true, some false/nil
        let hasSplit = (trueCount > 0 && falseCount + nilCount > 0) || (falseCount > 0 && nilCount > 0)
        guard hasSplit else { return 0 }

        // Reward balanced splits more (more informative)
        let total = Double(topCandidates.count)
        let trueRatio = Double(trueCount) / total
        let balance = 1.0 - abs(trueRatio - 0.5) * 2
        return 0.25 + balance * 0.15
    }

    /// Returns a boost for attributes that the top candidate has true and the other
    /// top candidates do not. This helps confirm a dominant candidate faster.
    private func uniqueConfirmBoost(attributeKey: String, topCandidates: [Character]) -> Double {
        guard let top = topCandidates.first else { return 0 }
        let topValue = top.attributes[attributeKey]
        guard topValue == true else { return 0 }

        let others = topCandidates.dropFirst()
        let othersFalseOrNil = others.allSatisfy { $0.attributes[attributeKey] != true }
        return othersFalseOrNil ? 0.4 : 0
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

        // Single-pass count: true, false, and nil buckets.
        var trueCount = 0
        var falseCount = 0
        for character in characters {
            let value = character.attributes[attributeKey]
            if value == true {
                trueCount += 1
            } else if value == false {
                falseCount += 1
            }
        }
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
