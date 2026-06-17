EduGuess - La IA que Adivina Personajes

EduGuess es una aplicación educativa interactiva desarrollada para iOS 17+ en SwiftUI que implementa un juego estilo "20 Preguntas". Utiliza SwiftData para persistencia local y Firebase (Auth + Firestore) para autenticación y datos en la nube.

Características Principales

- Juego interactivo basado en preguntas de sí/no con filtrado inteligente
- Autenticación: Email/Password, Google Sign-In, Facebook Login
- Firestore: perfiles de usuario, sesiones de juego, leaderboard global
- Leaderboard all-time y semanal con puntuaciones
- Perfil con estadísticas (partidas, victorias, puntaje total, mejor puntaje, win rate)
- Seed automático de 31 personajes peruanos y latinoamericanos al primer inicio
- Sistema de puntuación: (20 − preguntas) × 10 por acierto, 0 por derrota
- Interfaz moderna con gradientes, animaciones, español
- Arquitectura MVVM + SwiftData local + Firestore online

Requerimientos

- iOS: 17.0 o superior
- Xcode: 15.0 o superior
- macOS: 14.0+ (para compilar)
- Swift: 5.9+

Dependencias (SPM)

- FirebaseAuth v12.15.0
- FirebaseFirestore v12.15.0
- GoogleSignIn-iOS v7.1.0
- facebook-ios-sdk v17.4.0 (producto: FacebookLogin)

Estructura de Carpetas

EduGuess/
├── EduGuess/
│   ├── EduGuessApp.swift              # @main, SwiftData ModelContainer, onAppear
│   ├── AppDelegate.swift              # Firebase, Facebook SDK, GIDSignIn config
│   ├── Info.plist                     # URL schemes, FacebookAppID, ClientToken
│   ├── GoogleService-Info.plist       # Firebase config (sin Facebook keys)
│   ├── characters_seed.json           # 31 personajes de semilla
│   ├── Models/
│   │   ├── AttributeDefinition.swift  # 38 atributos booleanos (pool)
│   │   ├── Character.swift            # SDCharacter @Model + Character struct
│   │   ├── GameState.swift            # enum: playing, guessed, failed
│   │   ├── Question.swift             # SDQuestion @Model + Question struct
│   │   └── UserStats.swift            # FirebaseUser, FirebaseGameSession, LeaderboardEntry, GameScoring
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift        # Observable auth state + signIn/signUp/signOut
│   │   └── GameViewModel.swift        # Lógica del juego, filtrado, scoring
│   ├── Views/
│   │   ├── SplashView.swift           # Pantalla inicial
│   │   ├── HomeView.swift             # Menú principal + botones Perfil/Ranking/logout
│   │   ├── LoginView.swift            # Login/registro + Google + Facebook buttons
│   │   ├── QuestionView.swift         # Preguntas con SwiftData
│   │   ├── CorrectGuessView.swift     # Victoria con puntuación
│   │   ├── WrongGuessView.swift       # Derrota
│   │   ├── ProfileView.swift          # Estadísticas + sesiones recientes
│   │   └── LeaderboardView.swift      # Ranking all-time / semanal
│   ├── Components/
│   │   ├── AnswerButton.swift         # Botón Sí/No
│   │   ├── CategoryButton.swift       # Botón de categoría
│   │   ├── ProgressBar.swift          # Barra de progreso
│   │   ├── QuestionCard.swift         # Tarjeta de pregunta
│   │   └── RobotAvatar.swift          # Avatar de IA
│   └── Services/
│       ├── AIService.swift            # Placeholder para IA externa
│       ├── DataService.swift          # SwiftData CRUD + saveSessionToFirestore
│       ├── FirebaseAuthService.swift  # signIn/signUp/signOut + Google + Facebook
│       ├── FirestoreService.swift     # CRUD Firestore (users, game_sessions, leaderboard)
│       └── SeedManager.swift          # Importa characters_seed.json si BD vacía
├── scripts/
│   └── scrape_and_classify.py         # Scraper Wikipedia + OpenAI classifier
├── GUIA_FIREBASE.md                   # Guía Firebase completa
├── TROUBLESHOOTING.md                 # Errores identificados y soluciones
└── EduGuess.xcodeproj/

Flujo de Autenticación

1. AppDelegate.application(_:didFinishLaunchingWithOptions:) configura Firebase, Facebook SDK y GIDSignIn
2. EduGuessApp.onAppear llama a authVM.configure() que verifica Auth.auth().currentUser o UserDefaults cache
3. Si hay sesión activa → HomeView; si no → LoginView
4. LoginView ofrece tres métodos:
   - Email/Password: signIn(withEmail:password:)
   - Google: GIDSignIn.sharedInstance.signIn(withPresenting:) → GoogleAuthProvider
   - Facebook: LoginManager().logIn(permissions:from:) → FacebookAuthProvider
5. Al registrarse, se crea un documento en Firestore (users/{uid})
6. Al terminar una partida, se guarda la sesión en Firestore (game_sessions/{id})

SeedManager

SeedManager.seedIfNeeded(context:) se llama en EduGuessApp.onAppear. Si la tabla SDCharacter está vacía, carga characters_seed.json y lo inserta en SwiftData. Los 31 personajes incluyen:

- Peruanos: Mario Vargas Llosa, Túpac Amaru II, Susana Baca, Sofía Mulanovich, etc.
- Latinomericanos: Gabriel García Márquez, Frida Kahlo, Lionel Messi, etc.
- Ficticios: El Chavo del 8, La Llorona, El Coco, etc.

Scoring

GameScoring.calculateScore(questionsAsked: Int, won: Bool) -> Int
- Victoria: (20 − questionsAsked) × 10
- Derrota: 0 puntos

Firestore Collections

users/{uid}:
  - name, email, totalGames, wins, losses, totalScore, bestScore

game_sessions/{auto-id}:
  - userId, userName, characterName, won, score, questionsAsked, timestamp

LeaderboardEntry (vista):
  - userId, userName, totalGames, wins, score, winRatio

Reglas de Firestore (producción)

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /game_sessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    match /leaderboard/{entryId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}

Abrir y Ejecutar en Xcode

1) open EduGuess.xcodeproj
2) File → Packages → Resolve Package Versions (si hay errores)
3) Seleccionar simulador (iPhone 15+ para iOS 17+)
4) Cmd+R

Contacto

- Creadora Original: Daniela Nicol Salazar Quina
- Repositorio: github.com/Dieegooml/movilesEduGuess

¡Disfruta jugando y mejorando EduGuess!
