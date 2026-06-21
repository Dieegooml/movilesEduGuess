import Foundation

struct AttributeDefinition {
    let key: String
    let questionTemplates: [String]

    func generateQuestion() -> String {
        questionTemplates.randomElement() ?? questionTemplates.first ?? "¿\(key)?"
    }
}

extension AttributeDefinition {
    static let pool: [AttributeDefinition] = [
        // ── IDENTITY ──
        .init(key: "isReal", questionTemplates: [
            "¿Tu personaje es una persona real?",
            "¿Existió o existe en la vida real?",
            "¿Es un personaje de la vida real?",
            "¿Podrías encontrarlo en el mundo real?",
            "¿Está basado en alguien que realmente existe?",
        ]),
        .init(key: "isFictional", questionTemplates: [
            "¿Tu personaje es ficticio?",
            "¿Es inventado?",
            "¿Pertenece a una obra de ficción?",
            "¿Es producto de la imaginación?",
            "¿No existe en el mundo real?",
        ]),
        .init(key: "isHistorical", questionTemplates: [
            "¿Tu personaje es histórico?",
            "¿Vivió en el pasado?",
            "¿Es una figura importante de la historia?",
            "¿Aparece en los libros de historia?",
            "¿Es alguien del pasado lejano?",
        ]),
        .init(key: "isAlive", questionTemplates: [
            "¿Tu personaje está vivo actualmente?",
            "¿Sigue con vida?",
            "¿Está vivo hoy en día?",
            "¿Podrías encontrarlo vivo ahora?",
            "¿Aún no ha fallecido?",
        ]),

        // ── ORIGIN MEDIA ──
        .init(key: "isFromMovie", questionTemplates: [
            "¿Tu personaje aparece en películas?",
            "¿Lo has visto en el cine?",
            "¿Ha sido protagonista de una película?",
            "¿Ha aparecido en la pantalla grande?",
            "¿Tiene una película propia?",
        ]),
        .init(key: "isFromBook", questionTemplates: [
            "¿Tu personaje aparece en libros?",
            "¿Es de una novela o cuento?",
            "¿Lo conoces por algún libro?",
            "¿Podrías leer sobre él en una biblioteca?",
            "¿Es parte de una obra literaria?",
        ]),
        .init(key: "isFromTV", questionTemplates: [
            "¿Tu personaje aparece en televisión?",
            "¿Lo has visto en la tele?",
            "¿Es de alguna serie o programa de TV?",
            "¿Tiene un programa de televisión propio?",
            "¿Aparece en la pantalla chica?",
        ]),
        .init(key: "isFromVideoGame", questionTemplates: [
            "¿Tu personaje es de un videojuego?",
            "¿Aparece en algún videojuego?",
            "¿Es un personaje de videojuegos?",
            "¿Puedes jugar con él en un videojuego?",
            "¿Es conocido en el mundo gamer?",
        ]),
        .init(key: "isFromComic", questionTemplates: [
            "¿Tu personaje es de un cómic?",
            "¿Aparece en historietas?",
            "¿Sale en cómics o mangas?",
            "¿Tiene su propia serie de cómics?",
            "¿Lo encuentras en viñetas?",
        ]),
        .init(key: "isFromMythology", questionTemplates: [
            "¿Tu personaje es de la mitología?",
            "¿Pertenece a leyendas antiguas?",
            "¿Es parte de algún mito o leyenda?",
            "¿Proviene de creencias ancestrales?",
            "¿Es un dios o ser mitológico?",
        ]),
        .init(key: "isFromAnime", questionTemplates: [
            "¿Tu personaje es de un anime?",
            "¿Es de una serie animada japonesa?",
            "¿Aparece en algún anime?",
            "¿Es un personaje de animación japonesa?",
            "¿Tiene ojos grandes y estilo anime?",
        ]),
        .init(key: "isFromPeru", questionTemplates: [
            "¿Tu personaje es peruano?",
            "¿Nació en Perú?",
            "¿Es originario del Perú?",
            "¿Tiene raíces peruanas?",
            "¿Es conocido en el Perú?",
        ]),
        .init(key: "isFromEurope", questionTemplates: [
            "¿Tu personaje es europeo?",
            "¿Nació en Europa?",
            "¿Es de algún país de Europa?",
            "¿Tiene raíces europeas?",
            "¿Es del Viejo Continente?",
        ]),
        .init(key: "isFromAsia", questionTemplates: [
            "¿Tu personaje es asiático?",
            "¿Nació en Asia?",
            "¿Es de algún país asiático?",
            "¿Tiene raíces asiáticas?",
            "¿Es del continente asiático?",
        ]),
        .init(key: "isFromAfrica", questionTemplates: [
            "¿Tu personaje es africano?",
            "¿Nació en África?",
            "¿Es de algún país africano?",
            "¿Tiene raíces africanas?",
            "¿Es del continente africano?",
        ]),
        .init(key: "isFromNorthAmerica", questionTemplates: [
            "¿Tu personaje es norteamericano?",
            "¿Nació en Norteamérica?",
            "¿Es de EE.UU. o Canadá?",
            "¿Tiene raíces norteamericanas?",
            "¿Es del continente norteamericano?",
        ]),
        .init(key: "isLatinAmerican", questionTemplates: [
            "¿Tu personaje es latinoamericano?",
            "¿Es de algún país de Latinoamérica?",
            "¿Nació en América Latina?",
            "¿Habla español con acento latino?",
            "¿Es parte de la cultura latina?",
        ]),

        // ── FRANCHISE ──
        .init(key: "isFromMarvel", questionTemplates: [
            "¿Tu personaje es de Marvel?",
            "¿Pertenece al universo Marvel?",
            "¿Es de los cómics de Marvel?",
            "¿Aparece en el MCU?",
            "¿Stan Lee lo creó?",
        ]),
        .init(key: "isFromDC", questionTemplates: [
            "¿Tu personaje es de DC?",
            "¿Es del universo DC?",
            "¿Pertenece a DC Comics?",
            "¿Es de los mundos de DC?",
            "¿Aparece en películas de DC?",
        ]),
        .init(key: "isFromDisney", questionTemplates: [
            "¿Tu personaje es de Disney?",
            "¿Pertenece al mundo Disney?",
            "¿Es un personaje de Disney?",
            "¿Aparece en películas de Disney?",
            "¿Lo creó Walt Disney?",
        ]),
        .init(key: "isFromStarWars", questionTemplates: [
            "¿Tu personaje es de Star Wars?",
            "¿Pertenece a la saga Star Wars?",
            "¿Vive en una galaxia muy lejana?",
            "¿Usa la Fuerza?",
            "¿Es parte del universo Star Wars?",
        ]),

        // ── NATURE ──
        .init(key: "isHuman", questionTemplates: [
            "¿Tu personaje es humano?",
            "¿Es un ser humano?",
            "¿Pertenece a la raza humana?",
            "¿Es de carne y hueso como nosotros?",
            "¿No tiene poderes sobrenaturales?",
        ]),
        .init(key: "isAnimal", questionTemplates: [
            "¿Tu personaje es un animal?",
            "¿No es humano, sino animal?",
            "¿Es una criatura no humana?",
            "¿Camina en cuatro patas?",
            "¿Es una mascota o animal parlante?",
        ]),
        .init(key: "isMagical", questionTemplates: [
            "¿Tu personaje es mágico?",
            "¿Tiene habilidades mágicas?",
            "¿Usa magia o hechizos?",
            "¿Pertenece a un mundo de fantasía?",
            "¿Lo rodea un aura mágica?",
        ]),
        .init(key: "isSuperhero", questionTemplates: [
            "¿Tu personaje es un superhéroe?",
            "¿Tiene identidad secreta?",
            "¿Se dedica a salvar personas?",
            "¿Usa un traje de superhéroe?",
            "¿Lucha contra el crimen?",
        ]),
        .init(key: "isVillain", questionTemplates: [
            "¿Tu personaje es un villano?",
            "¿Es uno de los malos?",
            "¿Es un antagonista?",
            "¿Suele ser el enemigo del héroe?",
            "¿Tiene malas intenciones?",
        ]),
        .init(key: "isRoyalty", questionTemplates: [
            "¿Tu personaje es de la realeza?",
            "¿Es rey, reina o princesa?",
            "¿Pertenece a una familia real?",
            "¿Tiene un título nobiliario?",
            "¿Vive en un castillo?",
        ]),

        // ── APPEARANCE ──
        .init(key: "hasHair", questionTemplates: [
            "¿Tu personaje tiene cabello?",
            "¿Tiene pelo visible?",
            "¿Se le ve cabello?",
            "¿No es calvo?",
            "¿Tiene algún peinado distintivo?",
        ]),
        .init(key: "wearsGlasses", questionTemplates: [
            "¿Tu personaje usa gafas?",
            "¿Lleva anteojos?",
            "¿Usa lentes?",
            "¿Tiene problemas de visión?",
            "¿Usa lentes de contacto?",
        ]),
        .init(key: "hasBeard", questionTemplates: [
            "¿Tu personaje tiene barba?",
            "¿Lleva barba o bigote?",
            "¿Tiene vello facial?",
            "¿Usa barba frondosa?",
            "¿Tiene un bigote llamativo?",
        ]),
        .init(key: "isFemale", questionTemplates: [
            "¿Tu personaje es mujer?",
            "¿Es del género femenino?",
            "¿Estamos hablando de una mujer?",
            "¿Tu personaje es ella?",
            "¿Tiene apariencia femenina?",
        ]),
        .init(key: "isChild", questionTemplates: [
            "¿Tu personaje es un niño?",
            "¿Es menor de edad?",
            "¿Es un personaje infantil?",
            "¿Tiene menos de 18 años?",
            "¿Es un infante o adolescente?",
        ]),
        .init(key: "isElderly", questionTemplates: [
            "¿Tu personaje es anciano?",
            "¿Es una persona mayor?",
            "¿Tiene avanzada edad?",
            "¿Tiene el cabello canoso?",
            "¿Necesita bastón para caminar?",
        ]),

        // ── ABILITIES ──
        .init(key: "usesMagic", questionTemplates: [
            "¿Tu personaje usa magia?",
            "¿Lanza hechizos?",
            "¿Practica la brujería o hechicería?",
            "¿Estudió en una escuela de magia?",
            "¿Tiene un libro de hechizos?",
        ]),
        .init(key: "usesTechnology", questionTemplates: [
            "¿Tu personaje usa tecnología avanzada?",
            "¿Maneja dispositivos tecnológicos?",
            "¿Usa aparatos de alta tecnología?",
            "¿Es experto en gadgets?",
            "¿Usa un celular o computadora?",
        ]),
        .init(key: "hasSuperpowers", questionTemplates: [
            "¿Tu personaje tiene superpoderes?",
            "¿Posee habilidades sobrehumanas?",
            "¿Tiene poderes especiales?",
            "¿Puede hacer cosas que un humano no puede?",
            "¿Tiene un poder único?",
        ]),
        .init(key: "isStrong", questionTemplates: [
            "¿Tu personaje es físicamente fuerte?",
            "¿Tiene una fuerza fuera de lo común?",
            "¿Es conocido por su fortaleza?",
            "¿Puede levantar objetos pesados?",
            "¿Gana peleas fácilmente?",
        ]),
        .init(key: "isSmart", questionTemplates: [
            "¿Tu personaje es muy inteligente?",
            "¿Se caracteriza por su intelecto?",
            "¿Es un genio o muy astuto?",
            "¿Resuelve problemas complejos?",
            "¿Es conocido por su sabiduría?",
        ]),

        // ── ITEMS ──
        .init(key: "hasWeapon", questionTemplates: [
            "¿Tu personaje usa un arma?",
            "¿Porta algún tipo de arma?",
            "¿Utiliza armas para pelear?",
            "¿Lleva una espada o pistola?",
            "¿Tiene un arma característica?",
        ]),
        .init(key: "drivesVehicle", questionTemplates: [
            "¿Tu personaje conduce un vehículo?",
            "¿Maneja algún medio de transporte?",
            "¿Tiene un vehículo característico?",
            "¿Conduce un auto o moto?",
            "¿Pilotea una nave o avión?",
        ]),
        .init(key: "wearsCape", questionTemplates: [
            "¿Tu personaje usa capa?",
            "¿Lleva una capa puesta?",
            "¿Usa capa o manto?",
            "¿Su atuendo incluye una capa?",
            "¿Viste una capa que ondea al viento?",
        ]),
        .init(key: "wearsHat", questionTemplates: [
            "¿Tu personaje usa sombrero?",
            "¿Lleva algún tipo de gorro?",
            "¿Usa un sombrero distintivo?",
            "¿Su cabeza está cubierta?",
            "¿Tiene un tocado característico?",
        ]),

        // ── ROLE / OCCUPATION ──
        .init(key: "isAthlete", questionTemplates: [
            "¿Tu personaje es un deportista?",
            "¿Practica algún deporte?",
            "¿Es un atleta profesional?",
            "¿Juega en un equipo deportivo?",
            "¿Gana medallas o trofeos?",
        ]),
        .init(key: "isFootballer", questionTemplates: [
            "¿Tu personaje es futbolista?",
            "¿Juega fútbol profesionalmente?",
            "¿Es conocido por jugar al fútbol?",
            "¿Patea un balón por trabajo?",
            "¿Ha jugado en un equipo de fútbol?",
        ]),
        .init(key: "isGoalkeeper", questionTemplates: [
            "¿Tu personaje es portero?",
            "¿Defiende la portería?",
            "¿Usa guantes de arquero?",
            "¿Es arquero de fútbol?",
            "¿Ataja penales?",
        ]),
        .init(key: "isForward", questionTemplates: [
            "¿Tu personaje es delantero?",
            "¿Juega en la delantera?",
            "¿Su trabajo es marcar goles?",
            "¿Es un goleador?",
            "¿Ataca en su equipo?",
        ]),
        .init(key: "isMidfielder", questionTemplates: [
            "¿Tu personaje es mediocampista?",
            "¿Juega en el mediocampo?",
            "¿Distribuye el balón?",
            "¿Es volante?",
            "¿Controla el juego desde el centro?",
        ]),
        .init(key: "isDefender", questionTemplates: [
            "¿Tu personaje es defensa?",
            "¿Juega en la defensa?",
            "¿Su trabajo es evitar goles?",
            "¿Es zaguero o lateral?",
            "¿Detiene ataques rivales?",
        ]),
        .init(key: "isCaptain", questionTemplates: [
            "¿Tu personaje es capitán de su equipo?",
            "¿Lleva el brazalete de capitán?",
            "¿Es líder dentro del campo?",
            "¿Es el capitán?",
            "¿Dirige a sus compañeros?",
        ]),
        .init(key: "isLeftFooted", questionTemplates: [
            "¿Tu personaje es zurdo?",
            "¿Usa más la pierna izquierda?",
            "¿Patea con la izquierda?",
            "¿Es diestro o zurdo?",
            "¿Su pierna dominante es la izquierda?",
        ]),
        .init(key: "isTall", questionTemplates: [
            "¿Tu personaje es alto?",
            "¿Mide más de 1.80 m?",
            "¿Destaca por su estatura?",
            "¿Es una persona alta?",
            "¿Tiene gran altura?",
        ]),
        .init(key: "hasTattoos", questionTemplates: [
            "¿Tu personaje tiene tatuajes visibles?",
            "¿Está tatuado?",
            "¿Tiene tatuajes en brazos o cuerpo?",
            "¿Lleva tinta en la piel?",
            "¿Se le ven tatuajes?",
        ]),
        .init(key: "isBald", questionTemplates: [
            "¿Tu personaje es calvo?",
            "¿No tiene cabello?",
            "¿Afeita su cabeza?",
            "¿Tiene la cabeza rapada?",
            "¿Es pelado?",
        ]),

        .init(key: "isMusician", questionTemplates: [
            "¿Tu personaje es músico?",
            "¿Canta o toca un instrumento?",
            "¿Es parte de una banda musical?",
            "¿Se dedica a la música?",
            "¿Es conocido por su voz?",
        ]),
        .init(key: "isPolitician", questionTemplates: [
            "¿Tu personaje es un político?",
            "¿Gobierna o gobernó un país?",
            "¿Es presidente o ministro?",
            "¿Participa en la política?",
            "¿Tiene un cargo de gobierno?",
        ]),
        .init(key: "isWriter", questionTemplates: [
            "¿Tu personaje es escritor?",
            "¿Ha escrito libros o poemas?",
            "¿Se dedica a la literatura?",
            "¿Es autor de obras famosas?",
            "¿Ganó un premio literario?",
        ]),
        .init(key: "isScientist", questionTemplates: [
            "¿Tu personaje es científico?",
            "¿Se dedica a la ciencia?",
            "¿Hace experimentos o investiga?",
            "¿Tiene un laboratorio?",
            "¿Es inventor o investigador?",
        ]),
        .init(key: "isReligious", questionTemplates: [
            "¿Tu personaje es religioso?",
            "¿Es un líder espiritual?",
            "¿Representa a una iglesia o fe?",
            "¿Es un santo o figura religiosa?",
            "¿Predica una religión?",
        ]),

        // ── NEW ATTRIBUTES ──
        .init(key: "isFromCartoon", questionTemplates: [
            "¿Tu personaje es de una caricatura o dibujo animado?",
            "¿Aparece en dibujos animados occidentales?",
            "¿Es de un cartoon?",
            "¿Tiene estilo de animación occidental?",
            "¿Es de una serie animada no anime?",
        ]),

        .init(key: "isDancer", questionTemplates: [
            "¿Tu personaje es bailarín?",
            "¿Baila profesionalmente?",
            "¿Es conocido por sus movimientos?",
            "¿Participa en coreografías?",
            "¿Es un artista de la danza?",
        ]),
        .init(key: "isActor", questionTemplates: [
            "¿Tu personaje es actor o actriz?",
            "¿Actúa en películas o teatro?",
            "¿Es reconocido por interpretar personajes?",
            "¿Ha ganado premios de actuación?",
            "¿Es famoso por su trabajo en cine o TV?",
        ]),
        .init(key: "isSinger", questionTemplates: [
            "¿Tu personaje es cantante?",
            "¿Canta profesionalmente?",
            "¿Es conocido por su voz o música?",
            "¿Ha lanzado canciones o álbumes?",
            "¿Es un artista musical?",
        ]),
        .init(key: "isFamous", questionTemplates: [
            "¿Tu personaje es muy famoso?",
            "¿Es conocido mundialmente?",
            "¿Aparece en medios de comunicación?",
            "¿Tiene millones de seguidores?",
            "¿Es una celebridad?",
        ]),
        .init(key: "isControversial", questionTemplates: [
            "¿Tu personaje es controversial o polémico?",
            "¿Genera opiniones divididas?",
            "¿Ha estado en escándalos?",
            "¿Es amado y odiado a la vez?",
            "¿Su historia genera debate?",
        ]),
        .init(key: "isYoung", questionTemplates: [
            "¿Tu personaje es joven?",
            "¿Tiene menos de 30 años?",
            "¿Está en la flor de la vida?",
            "¿Es un adulto joven?",
            "¿No es niño ni anciano?",
        ]),
    ]
}
