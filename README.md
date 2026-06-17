# EduGuess - La IA que Adivina Personajes

## Descripción

EduGuess es una aplicación educativa interactiva desarrollada en SwiftUI para iOS 17+ que implementa un juego estilo "20 Preguntas". El usuario piensa en un personaje y la "IA" realiza preguntas de sí/no para intentar adivinarlo.

## Características Principales

- Juego interactivo basado en preguntas de sí/no con filtrado inteligente
- **Autenticación**: Email/Password, Google Sign-In y Facebook Login
- **Firestore**: perfiles de usuario, sesiones de juego y leaderboard global
- **Leaderboard**: ranking all-time y semanal con puntuaciones
- **Perfil de usuario**: estadísticas de partidas, victorias, puntaje total
- **Seed automático**: 31 personajes peruanos y latinoamericanos importados al primer inicio
- **Sistema de puntuación**: (20 − preguntas) × 10 por acierto
- **Interfaz moderna**: gradientes, animaciones, español, NavigationStack
- **Arquitectura MVVM** + SwiftData local + Firestore online

## Requerimientos

- iOS 17.0 o superior
- Xcode 15.0 o superior
- macOS 14.0+ (para compilar)
- Swift 5.9+

## Estructura del Proyecto

```
EduGuess/
├── EduGuess/
│   ├── EduGuessApp.swift              # @main, SwiftData container, auth guard
│   ├── AppDelegate.swift              # Firebase, Facebook SDK, GIDSignIn setup
│   ├── Info.plist                     # URL schemes (Google, Facebook), FacebookAppID
│   ├── GoogleService-Info.plist       # Firebase config (NO Facebook keys)
│   ├── characters_seed.json           # 31 personajes de semilla
│   ├── Models/
│   │   ├── AttributeDefinition.swift  # Pool de 38 atributos booleanos
│   │   ├── Character.swift            # SDCharacter (SwiftData)
│   │   ├── GameState.swift            # enum: playing, guessed, failed
│   │   ├── Question.swift             # SDQuestion (SwiftData)
│   │   └── UserStats.swift            # Firestore codable models + scoring
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift        # Estado de autenticación observable
│   │   └── GameViewModel.swift        # Lógica central del juego
│   ├── Views/
│   │   ├── SplashView.swift           # Pantalla inicial
│   │   ├── HomeView.swift             # Pantalla principal + logout
│   │   ├── LoginView.swift            # Login/registro + Google + Facebook
│   │   ├── QuestionView.swift         # Preguntas con SwiftData
│   │   ├── CorrectGuessView.swift     # Pantalla de victoria
│   │   ├── WrongGuessView.swift       # Pantalla de derrota
│   │   ├── ProfileView.swift          # Estadísticas del usuario
│   │   └── LeaderboardView.swift      # Ranking global all-time/semanal
│   ├── Components/
│   │   ├── AnswerButton.swift         # Botón Sí/No
│   │   ├── CategoryButton.swift       # Botón de categoría
│   │   ├── ProgressBar.swift          # Barra de progreso
│   │   ├── QuestionCard.swift         # Tarjeta de pregunta
│   │   └── RobotAvatar.swift          # Avatar de IA
│   └── Services/
│       ├── AIService.swift            # Placeholder para IA externa
│       ├── DataService.swift          # SwiftData CRUD + saveSessionToFirestore
│       ├── FirebaseAuthService.swift  # Auth unificado (email, Google, Facebook)
│       ├── FirestoreService.swift     # CRUD Firestore (users, sessions, leaderboard)
│       └── SeedManager.swift          # Importa characters_seed.json al primer launch
├── scripts/
│   └── scrape_and_classify.py         # Scraper + LLM para generar personajes
├── GUIA_FIREBASE.md                   # Guía completa de configuración Firebase
├── TROUBLESHOOTING.md                 # Historial de errores y soluciones
└── EduGuess.xcodeproj/
```

## Dependencias (Swift Package Manager)

- **FirebaseAuth** v12.15.0 — autenticación Email/Password, Google, Facebook
- **FirebaseFirestore** v12.15.0 — base de datos en la nube
- **GoogleSignIn-iOS** v7.1.0 — Google Sign-In nativo
- **facebook-ios-sdk** v17.4.0 — Facebook Login nativo (producto: `FacebookLogin`)

## Configuración Inicial

1. Clonar el repositorio
2. Abrir `EduGuess.xcodeproj` en Xcode
3. **File → Add Package Dependencies...** si los paquetes no se resuelven automáticamente
4. Ir a [Firebase Console](https://console.firebase.google.com) y crear proyecto
5. Registrar app iOS con Bundle ID `com.tecsup.EduGuess`
6. Descargar `GoogleService-Info.plist` y agregarlo al proyecto
7. Habilitar Authentication: Email/Password, Google, Facebook
8. Crear Firestore Database en modo prueba
9. Registrar una app de Facebook en [developers.facebook.com](https://developers.facebook.com) y obtener App ID y Client Token
10. En el `Info.plist` del proyecto, verificar que `FacebookAppID`, `FacebookClientToken` y `FacebookDisplayName` estén configurados
11. **Product → Clean Build Folder** y **Run**

## Flujo de Autenticación

- La app usa `@UIApplicationDelegateAdaptor(AppDelegate.self)` para inicializar Firebase, Facebook SDK y GIDSignIn
- `AuthViewModel` observa el estado de autenticación; la pantalla de login se oculta hasta que el estado se resuelve (`isReady` guard)
- Soporta tres métodos: Email/Password, Google Sign-In (GIDSignIn), Facebook Login (LoginManager + FacebookAuthProvider)
- Las sesiones se cachean en UserDefaults para persistencia entre lanzamientos

## Seed de Personajes

`SeedManager.swift` verifica si la base de datos SwiftData está vacía al primer inicio. Si lo está, importa automáticamente los 31 personajes desde `characters_seed.json`. Los personajes incluyen figuras peruanas y latinoamericanas (reales y ficticias) con 38 atributos booleanos cada uno.

## Scoring

- Victoria: (20 − preguntasRealizadas) × 10
- Derrota: 0 puntos
- Las sesiones se guardan en Firestore con userId, userName, characterName, score, won, preguntasRealizadas

## Arquitectura de Datos

```
                    ┌──────────────────────────┐
                    │      EduGuess App        │
                    │  (SwiftUI + SwiftData)    │
                    └──────────┬───────────────┘
                               │
              ┌────────────────┼─────────────────┐
              │                │                  │
              ▼                ▼                  ▼
    ┌────────────────┐ ┌──────────────┐ ┌──────────────────┐
    │  Firebase Auth  │ │  Firestore   │ │    SwiftData      │
    │(email/Google/FB)│ │(online sync) │ │  (local cache)    │
    └────────────────┘ └──────────────┘ └──────────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │     Firestore DB      │
                    │  - users/{uid}        │
                    │  - game_sessions/{id} │
                    │  - leaderboard (vista)│
                    └──────────────────────┘
```

## Contacto

- Creadora Original: Daniela Nicol Salazar Quina
- Repositorio: github.com/Dieegooml/movilesEduGuess

¡Disfruta mejorando EduGuess!
