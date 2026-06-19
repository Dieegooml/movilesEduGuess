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
    let questionTemplates: [String]
    let category: AttributeCategory

    func generateQuestion() -> String {
        questionTemplates.randomElement() ?? questionTemplates.first ?? "¿\(key)?"
    }
}

extension AttributeDefinition {
    static let pool: [AttributeDefinition] = [
        // Identity
        .init(key: "isReal", questionTemplates: ["¿Tu personaje es una persona real?", "¿Existió en la vida real?", "¿Es un personaje de la vida real?"], category: .identity),
        .init(key: "isFictional", questionTemplates: ["¿Tu personaje es ficticio?", "¿Es inventado?", "¿Pertenece a una obra de ficción?"], category: .identity),
        .init(key: "isHistorical", questionTemplates: ["¿Tu personaje es histórico?", "¿Vivió en el pasado?", "¿Es una figura importante de la historia?"], category: .identity),
        .init(key: "isAlive", questionTemplates: ["¿Tu personaje está vivo actualmente?", "¿Sigue con vida?", "¿Está vivo hoy en día?"], category: .identity),

        // Origin
        .init(key: "isFromMovie", questionTemplates: ["¿Tu personaje aparece en películas?", "¿Lo has visto en el cine?", "¿Ha sido protagonista de una película?"], category: .origin),
        .init(key: "isFromBook", questionTemplates: ["¿Tu personaje aparece en libros?", "¿Es de una novela o cuento?", "¿Lo conoces por algún libro?"], category: .origin),
        .init(key: "isFromTV", questionTemplates: ["¿Tu personaje aparece en televisión?", "¿Lo has visto en la tele?", "¿Es de alguna serie o programa de TV?"], category: .origin),
        .init(key: "isFromVideoGame", questionTemplates: ["¿Tu personaje es de un videojuego?", "¿Aparece en algún videojuego?", "¿Es un personaje de videojuegos?"], category: .origin),
        .init(key: "isFromComic", questionTemplates: ["¿Tu personaje es de un cómic?", "¿Aparece en historietas?", "¿Sale en cómics o mangas?"], category: .origin),
        .init(key: "isFromMythology", questionTemplates: ["¿Tu personaje es de la mitología?", "¿Pertenece a leyendas antiguas?", "¿Es parte de algún mito o leyenda?"], category: .origin),
        .init(key: "isFromAnime", questionTemplates: ["¿Tu personaje es de un anime?", "¿Es de una serie animada japonesa?", "¿Aparece en algún anime?"], category: .origin),
        .init(key: "isFromPeru", questionTemplates: ["¿Tu personaje es peruano?", "¿Nació en Perú?", "¿Es originario del Perú?"], category: .origin),
        .init(key: "isLatinAmerican", questionTemplates: ["¿Tu personaje es latinoamericano?", "¿Es de algún país de Latinoamérica?", "¿Nació en América Latina?"], category: .origin),

        // Franchise
        .init(key: "isFromMarvel", questionTemplates: ["¿Tu personaje es de Marvel?", "¿Pertenece al universo Marvel?", "¿Es de los cómics de Marvel?"], category: .franchise),
        .init(key: "isFromDC", questionTemplates: ["¿Tu personaje es de DC?", "¿Es del universo DC?", "¿Pertenece a DC Comics?"], category: .franchise),
        .init(key: "isFromDisney", questionTemplates: ["¿Tu personaje es de Disney?", "¿Pertenece al mundo Disney?", "¿Es un personaje de Disney?"], category: .franchise),
        .init(key: "isFromStarWars", questionTemplates: ["¿Tu personaje es de Star Wars?", "¿Pertenece a la saga Star Wars?", "¿Vive en una galaxia muy lejana?"], category: .franchise),

        // Nature
        .init(key: "isHuman", questionTemplates: ["¿Tu personaje es humano?", "¿Es un ser humano?", "¿Pertenece a la raza humana?"], category: .nature),
        .init(key: "isAnimal", questionTemplates: ["¿Tu personaje es un animal?", "¿No es humano, sino animal?", "¿Es una criatura no humana?"], category: .nature),
        .init(key: "isMagical", questionTemplates: ["¿Tu personaje es mágico?", "¿Tiene habilidades mágicas?", "¿Usa magia o hechizos?"], category: .nature),
        .init(key: "isSuperhero", questionTemplates: ["¿Tu personaje es un superhéroe?", "¿Tiene identidad secreta?", "¿Se dedica a salvar personas?"], category: .nature),
        .init(key: "isVillain", questionTemplates: ["¿Tu personaje es un villano?", "¿Es uno de los malos?", "¿Es un antagonista?"], category: .nature),
        .init(key: "isRoyalty", questionTemplates: ["¿Tu personaje es de la realeza?", "¿Es rey, reina o princesa?", "¿Pertenece a una familia real?"], category: .nature),

        // Appearance
        .init(key: "hasHair", questionTemplates: ["¿Tu personaje tiene cabello?", "¿Tiene pelo visible?", "¿Se le ve cabello?"], category: .appearance),
        .init(key: "wearsGlasses", questionTemplates: ["¿Tu personaje usa gafas?", "¿Lleva anteojos?", "¿Usa lentes?"], category: .appearance),
        .init(key: "hasBeard", questionTemplates: ["¿Tu personaje tiene barba?", "¿Lleva barba o bigote?", "¿Tiene vello facial?"], category: .appearance),
        .init(key: "isFemale", questionTemplates: ["¿Tu personaje es mujer?", "¿Es del género femenino?", "¿Estamos hablando de una mujer?"], category: .appearance),
        .init(key: "isChild", questionTemplates: ["¿Tu personaje es un niño?", "¿Es menor de edad?", "¿Es un personaje infantil?"], category: .appearance),
        .init(key: "isElderly", questionTemplates: ["¿Tu personaje es anciano?", "¿Es una persona mayor?", "¿Tiene avanzada edad?"], category: .appearance),

        // Abilities
        .init(key: "usesMagic", questionTemplates: ["¿Tu personaje usa magia?", "¿Lanza hechizos?", "¿Practica la brujería o hechicería?"], category: .abilities),
        .init(key: "usesTechnology", questionTemplates: ["¿Tu personaje usa tecnología avanzada?", "¿Maneja dispositivos tecnológicos?", "¿Usa aparatos de alta tecnología?"], category: .abilities),
        .init(key: "hasSuperpowers", questionTemplates: ["¿Tu personaje tiene superpoderes?", "¿Posee habilidades sobrehumanas?", "¿Tiene poderes especiales?"], category: .abilities),
        .init(key: "isStrong", questionTemplates: ["¿Tu personaje es físicamente fuerte?", "¿Tiene una fuerza fuera de lo común?", "¿Es conocido por su fortaleza?"], category: .abilities),
        .init(key: "isSmart", questionTemplates: ["¿Tu personaje es muy inteligente?", "¿Se caracteriza por su intelecto?", "¿Es un genio o muy astuto?"], category: .abilities),

        // Items
        .init(key: "hasWeapon", questionTemplates: ["¿Tu personaje usa un arma?", "¿Porta algún tipo de arma?", "¿Utiliza armas para pelear?"], category: .items),
        .init(key: "drivesVehicle", questionTemplates: ["¿Tu personaje conduce un vehículo?", "¿Maneja algún medio de transporte?", "¿Tiene un vehículo característico?"], category: .items),
        .init(key: "wearsCape", questionTemplates: ["¿Tu personaje usa capa?", "¿Lleva una capa puesta?", "¿Usa capa o manto?"], category: .items),
        .init(key: "wearsHat", questionTemplates: ["¿Tu personaje usa sombrero?", "¿Lleva algún tipo de gorro?", "¿Usa un sombrero distintivo?"], category: .items),
    ]
}
