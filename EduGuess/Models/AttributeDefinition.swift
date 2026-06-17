import Foundation

enum AttributeCategory: String, CaseIterable {
    case identity = "Identidad"
    case origin = "Origen"
    case franchise = "Franquicia"
    case nature = "Naturaleza"
    case appearance = "Apariencia"
    case abilities = "Habilidades"
    case items = "Objetos"
}

struct AttributeDefinition {
    let key: String
    let questionTemplate: String
    let category: AttributeCategory

    func generateQuestion() -> String {
        questionTemplate
    }
}

extension AttributeDefinition {
    static let pool: [AttributeDefinition] = [
        // Identity
        .init(key: "isReal", questionTemplate: "¿Tu personaje es una persona real?", category: .identity),
        .init(key: "isFictional", questionTemplate: "¿Tu personaje es ficticio?", category: .identity),
        .init(key: "isHistorical", questionTemplate: "¿Tu personaje es histórico?", category: .identity),
        .init(key: "isAlive", questionTemplate: "¿Tu personaje está vivo actualmente?", category: .identity),

        // Origin
        .init(key: "isFromMovie", questionTemplate: "¿Tu personaje aparece en películas?", category: .origin),
        .init(key: "isFromBook", questionTemplate: "¿Tu personaje aparece en libros?", category: .origin),
        .init(key: "isFromTV", questionTemplate: "¿Tu personaje aparece en televisión?", category: .origin),
        .init(key: "isFromVideoGame", questionTemplate: "¿Tu personaje es de un videojuego?", category: .origin),
        .init(key: "isFromComic", questionTemplate: "¿Tu personaje es de un cómic?", category: .origin),
        .init(key: "isFromMythology", questionTemplate: "¿Tu personaje es de la mitología?", category: .origin),
        .init(key: "isFromAnime", questionTemplate: "¿Tu personaje es de un anime?", category: .origin),
        .init(key: "isFromPeru", questionTemplate: "¿Tu personaje es peruano?", category: .origin),
        .init(key: "isLatinAmerican", questionTemplate: "¿Tu personaje es latinoamericano?", category: .origin),

        // Franchise
        .init(key: "isFromMarvel", questionTemplate: "¿Tu personaje es de Marvel?", category: .franchise),
        .init(key: "isFromDC", questionTemplate: "¿Tu personaje es de DC?", category: .franchise),
        .init(key: "isFromDisney", questionTemplate: "¿Tu personaje es de Disney?", category: .franchise),
        .init(key: "isFromStarWars", questionTemplate: "¿Tu personaje es de Star Wars?", category: .franchise),

        // Nature
        .init(key: "isHuman", questionTemplate: "¿Tu personaje es humano?", category: .nature),
        .init(key: "isAnimal", questionTemplate: "¿Tu personaje es un animal?", category: .nature),
        .init(key: "isMagical", questionTemplate: "¿Tu personaje es mágico?", category: .nature),
        .init(key: "isSuperhero", questionTemplate: "¿Tu personaje es un superhéroe?", category: .nature),
        .init(key: "isVillain", questionTemplate: "¿Tu personaje es un villano?", category: .nature),
        .init(key: "isRoyalty", questionTemplate: "¿Tu personaje es de la realeza?", category: .nature),

        // Appearance
        .init(key: "hasHair", questionTemplate: "¿Tu personaje tiene cabello?", category: .appearance),
        .init(key: "wearsGlasses", questionTemplate: "¿Tu personaje usa gafas?", category: .appearance),
        .init(key: "hasBeard", questionTemplate: "¿Tu personaje tiene barba?", category: .appearance),
        .init(key: "isFemale", questionTemplate: "¿Tu personaje es mujer?", category: .appearance),
        .init(key: "isChild", questionTemplate: "¿Tu personaje es un niño?", category: .appearance),
        .init(key: "isElderly", questionTemplate: "¿Tu personaje es anciano?", category: .appearance),

        // Abilities
        .init(key: "usesMagic", questionTemplate: "¿Tu personaje usa magia?", category: .abilities),
        .init(key: "usesTechnology", questionTemplate: "¿Tu personaje usa tecnología avanzada?", category: .abilities),
        .init(key: "hasSuperpowers", questionTemplate: "¿Tu personaje tiene superpoderes?", category: .abilities),
        .init(key: "isStrong", questionTemplate: "¿Tu personaje es físicamente fuerte?", category: .abilities),
        .init(key: "isSmart", questionTemplate: "¿Tu personaje es muy inteligente?", category: .abilities),

        // Items
        .init(key: "hasWeapon", questionTemplate: "¿Tu personaje usa un arma?", category: .items),
        .init(key: "drivesVehicle", questionTemplate: "¿Tu personaje conduce un vehículo?", category: .items),
        .init(key: "wearsCape", questionTemplate: "¿Tu personaje usa capa?", category: .items),
        .init(key: "wearsHat", questionTemplate: "¿Tu personaje usa sombrero?", category: .items),
    ]
}
