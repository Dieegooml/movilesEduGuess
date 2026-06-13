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

Métodos disponibles:
- saveDefaultDataIfNeeded(context: ModelContext) - Inicializa datos por defecto si BD está vacía
- fetchCharacters(context: ModelContext) -> [Character] - Obtiene todos los personajes
- fetchQuestions(context: ModelContext) -> [Question] - Obtiene todas las preguntas
- addCharacter(..., context: ModelContext) - Añade nuevo personaje
- addQuestion(..., context: ModelContext) - Añade nueva pregunta
- deleteCharacter(..., context: ModelContext) - Elimina personaje
- deleteQuestion(..., context: ModelContext) - Elimina pregunta

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

Añadir Nuevos Personajes

// Opción 1: Programátically en SwiftData
DataService().addCharacter(
    name: "Spiderman",
    image: "spiderman",
    attributes: [
        "usesMagic": false,
        "wearsGlasses": false,
        "isReal": false,
        "isMale": true
    ],
    context: modelContext
)

// Opción 2: Ver de administración (próxima feature)
// - Crear admin panel para CRUD desde UI

Añadir Nuevas Preguntas

DataService().addQuestion(
    text: "¿Tu personaje tiene superpoderes?",
    attributeKey: "hasSuperPowers",
    context: modelContext
)

IMPORTANTE: Después de añadir preguntas, actualizar TODOS los personajes
con este nuevo atributo, o el juego fallará en el filtrado.

Inicializar Datos por Defecto

Los datos por defecto se cargan automáticamente la primera vez que se abre
la app (en QuestionView.onAppear). Si la BD ya contiene datos, se saltará.

Para resetear a datos por defecto:
1. Eliminar app del simulador/device
2. Recompilar y ejecutar

O manualmente (en DataService):
DataService().saveDefaultDataIfNeeded(context: modelContext)

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

