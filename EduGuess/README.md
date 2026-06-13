EduGuess - La IA que Adivina Personajes 🧠

Descripción del Proyecto

EduGuess es una aplicación educativa interactiva desarrollida para iOS 17+ en SwiftUI que implementa un juego estilo "20 Preguntas". Utiliza SwiftData para persistencia de datos, donde un usuario piensa en un personaje y la "IA" realiza preguntas de sí/no para intentar adivinarlo.

Características Principales

- Juego interactivo basado en preguntas de sí/no
- Sistema de filtrado inteligente de personajes
- Interfaz moderna con gradientes y animaciones
- Persistencia de datos con SwiftData
- Datos iniciales automáticos (sin hardcoding)
- Gestión CRUD completa de personajes y preguntas
- Arquitectura MVVM + SOLID principles
- Navegación moderna con NavigationStack y navigationDestination

Requerimientos

- iOS: 17.0 o superior (SwiftData requirement)
- Xcode: 15.0 o superior
- macOS: 14.0+ (para compilar)
- Swift: 5.9+

Estructura de Carpetas

EduGuess/
├── EduGuess/
│   ├── EduGuessApp.swift                 # Punto de entrada + ModelContainer
│   ├── ContentView.swift                 # Vista principal Backup
│   ├── Assets/
│   │   └── Assets.xcassets/
│   ├── Models/
│   │   ├── GameState.swift               # enum: playing, guessed, failed
│   │   ├── Question.swift                # Question + SDQuestion (SwiftData)
│   │   └── Character.swift               # Character + SDCharacter (SwiftData)
│   ├── ViewModels/
│   │   └── GameViewModel.swift           # Lógica central del juego
│   ├── Views/
│   │   ├── SplashView.swift              # Pantalla inicial (2s)
│   │   ├── HomeView.swift                # Pantalla principal
│   │   ├── QuestionView.swift            # Vista de preguntas con SwiftData
│   │   ├── CorrectGuessView.swift        # Pantalla de victoria
│   │   └── WrongGuessView.swift          # Pantalla de derrota
│   ├── Components/
│   │   ├── AnswerButton.swift            # Botón Sí/No
│   │   ├── CategoryButton.swift          # Botón de categoría
│   │   ├── ProgressBar.swift             # Barra de progreso
│   │   ├── QuestionCard.swift            # Tarjeta de pregunta
│   │   └── RobotAvatar.swift             # Avatar de IA
│   └── Services/
│       ├── AIService.swift               # Servicio para IA (placeholder)
│       └── DataService.swift             # Gestión de SwiftData (CRUD)
└── EduGuess.xcodeproj/

Abrir y Ejecutar en Xcode

1) Desde la terminal:
   open EduGuess.xcodeproj

2) O abrir Xcode y seleccionar:
   File → Open → EduGuess.xcodeproj

3) Seleccionar un simulador (iPhone 15+ recomendado para iOS 17+)

4) Presionar Cmd+R o hacer clic en Play

Arquitectura de Datos con SwiftData

Models

Character struct - representación en memoria
- id: UUID
- name: String
- image: String
- attributes: [String: Bool]

SDCharacter @Model - modelo SwiftData persistente
- id: UUID (unique)
- name: String
- image: String
- attributesData: Data (JSON encoded)
- Métodos: toCharacter() para convertir a Character

Question struct - representación en memoria
- id: UUID
- text: String
- attributeKey: String

SDQuestion @Model - modelo SwiftData persistente
- id: UUID (unique)
- text: String
- attributeKey: String
- Métodos: toQuestion() para convertir a Question

Services

DataService - Gestor de SwiftData

Métodos CRUD disponibles:
- saveDefaultDataIfNeeded(context: ModelContext) - Verifica si hay datos (no hay defaults)
- fetchCharacters(context: ModelContext) -> [Character] - Obtiene todos los personajes
- fetchQuestions(context: ModelContext) -> [Question] - Obtiene todas las preguntas
- addCharacter(name:, image:, attributes:, context:) - Añade nuevo personaje
- addQuestion(text:, attributeKey:, context:) - Añade nueva pregunta
- deleteCharacter(_:, context:) - Elimina personaje
- deleteQuestion(_:, context:) - Elimina pregunta
- updateCharacter(..., context:) - Actualiza personaje existente
- updateQuestion(..., context:) - Actualiza pregunta existente

Acceso en ViewModels/Views

import SwiftData

struct MyView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            // ...
        }
        .onAppear {
            let dataService = DataService()
            let characters = dataService.fetchCharacters(context: modelContext)
            let questions = dataService.fetchQuestions(context: modelContext)
            
            // Usar datos
        }
    }
}

Agregar Primeros Personajes y Preguntas

⚠️ IMPORTANTE: La base de datos empieza vacía. Debes agregar tus propios personajes y preguntas para que el juego funcione.

Estructura de Atributos

Define atributos booleanos que se usarán para filtrar personajes. Ejemplos:
- "usesMagic": true/false
- "wearsGlasses": true/false
- "isReal": true/false
- "isMale": true/false

REGLA CRÍTICA: Todos los personajes DEBEN tener exactamente los MISMOS atributos clave.

Ejemplo Completo

```swift
@Environment(\.modelContext) var modelContext
let dataService = DataService()

// Agregar preguntas (primero define el esquema de atributos)
dataService.addQuestion(text: "¿Tu personaje usa magia?", attributeKey: "usesMagic", context: modelContext)
dataService.addQuestion(text: "¿Tu personaje usa lentes?", attributeKey: "wearsGlasses", context: modelContext)
dataService.addQuestion(text: "¿Tu personaje es real?", attributeKey: "isReal", context: modelContext)
dataService.addQuestion(text: "¿Tu personaje es hombre?", attributeKey: "isMale", context: modelContext)

// Agregar personajes CON LOS MISMOS ATRIBUTOS
dataService.addCharacter(
    name: "Harry Potter",
    image: "harry",
    attributes: [
        "usesMagic": true,
        "wearsGlasses": true,
        "isReal": false,
        "isMale": true
    ],
    context: modelContext
)

dataService.addCharacter(
    name: "Hermione Granger",
    image: "hermione",
    attributes: [
        "usesMagic": true,
        "wearsGlasses": false,
        "isReal": false,
        "isMale": false
    ],
    context: modelContext
)
```

Mejores Prácticas

1. **Primero define las preguntas** - decide qué atributos tendrán los personajes
2. **Luego agrega personajes** - todos con los mismos atributos
3. **Verifica consistencia** - todos los personajes deben tener las MISMAS claves
4. **Actualizar datos** - usa updateCharacter() o updateQuestion() para modificar
5. **Eliminar datos** - usa deleteCharacter() o deleteQuestion()

Función para Agregar Múltiples Datos (Recomendado)

```swift
func seedGameData(context: ModelContext) {
    let service = DataService()
    
    // Preguntas
    let questions = [
        ("¿Tu personaje usa magia?", "usesMagic"),
        ("¿Tu personaje usa lentes?", "wearsGlasses"),
        ("¿Tu personaje es real?", "isReal"),
        ("¿Tu personaje es hombre?", "isMale")
    ]
    
    for (text, key) in questions {
        service.addQuestion(text: text, attributeKey: key, context: context)
    }
    
    // Personajes
    let characters = [
        ("Harry Potter", "harry", ["usesMagic": true, "wearsGlasses": true, "isReal": false, "isMale": true]),
        ("Hermione Granger", "hermione", ["usesMagic": true, "wearsGlasses": false, "isReal": false, "isMale": false]),
    ]
    
    for (name, image, attrs) in characters {
        service.addCharacter(name: name, image: image, attributes: attrs, context: context)
    }
}

Próximas Mejoras

- Panel de administración para CRUD desde UI
- Integración con IA (OpenAI API) para generar preguntas dinámicas
- Gamificación: puntos, logros, rankings
- Sistema de categorías
- Sincronización iCloud (CloudKit)
- Respaldo automático de datos
- Tests unitarios y UI tests
- Soporte multiidioma

Notas de Desarrollo

- El proyecto requiere iOS 17+ debido a SwiftData
- Los datos se persisten automáticamente en el dispositivo
- NavigationStack + navigationDestination para navegación moderna
- No hay datos hardcodeados en la app (todo desde SwiftData)
- La BD se inicializa automáticamente en primer launch

Contacto

- Creadora Original: Daniela Nicol Salazar Quina
- Repositorio: github.com/Dieegooml/movilesEduGuess
- Tecnología: SwiftUI, SwiftData, MVVM Architecture

¡Disfruta jugando y mejorando EduGuess! 🎮✨

