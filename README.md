# EduGuess - La IA que Adivina Personajes

## Descripción

EduGuess es una aplicación educativa interactiva desarrollada en SwiftUI para iOS 17+ que implementa un juego estilo "Akinator". El usuario piensa en un personaje y la "IA" realiza preguntas de sí/no para intentar adivinarlo usando un algoritmo de entropía.

## Características Principales

- Juego interactivo basado en preguntas de sí/no con filtrado inteligente (entropía)
- **Autenticación**: Email/Password, Google Sign-In y Facebook Login
- **Firestore**: perfiles de usuario, sesiones de juego y leaderboard global
- **Leaderboard**: ranking all-time y semanal con puntuaciones
- **Perfil de usuario**: estadísticas de partidas, victorias, puntaje total
- **Seed automático**: 31 personajes peruanos y latinoamericanos importados al primer inicio
- **Sistema de puntuación**: (38 − preguntas) × 10 por acierto (mínimo 10 pts)
- **Sin límite de preguntas**: la IA pregunta hasta estar segura o agotar atributos
- **38 atributos booleanos** agrupados en 7 categorías
- **Catálogo de personajes** con búsqueda y detalle + info de Wikipedia
- **Historial de partidas** con filtro de victorias/derrotas
- **Panel de administración** CRUD para crear/editar/eliminar personajes
- **Tutorial interactivo** de 4 pasos (HowToPlayView)
- **Filtro por categoría** antes de jugar (Peruanos, Ficticios, Superhéroes, etc.)
- **Interfaz moderna**: gradientes, animaciones spring, haptics, español, NavigationStack
- **Arquitectura MVVM** + SwiftData local + Firestore online
- **REST API**: Wikipedia summary para información adicional de personajes
- **Offline handling**: detección de conectividad con NWPathMonitor
- **Pull-to-refresh** en ranking y perfil

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
│   │   ├── SplashView.swift           # Pantalla inicial animada
│   │   ├── HomeView.swift             # Pantalla principal con menú animado
│   │   ├── LoginView.swift            # Login/registro + Google + Facebook
│   │   ├── QuestionView.swift         # Juego con transiciones animadas
│   │   ├── CorrectGuessView.swift     # Pantalla de victoria animada
│   │   ├── WrongGuessView.swift       # Pantalla de derrota + aprender
│   │   ├── CategorySelectView.swift   # Filtro por categoría antes de jugar
│   │   ├── CharacterListView.swift    # Catálogo con búsqueda
│   │   ├── CharacterDetailView.swift  # Detalle con atributos + Wikipedia
│   │   ├── GameHistoryView.swift      # Historial con filtro y empty state
│   │   ├── GameSessionDetailView.swift# Detalle de sesión QA
│   │   ├── AdminListView.swift        # CRUD con confirmación al eliminar
│   │   ├── CharacterFormView.swift    # Formulario de 38 atributos
│   │   ├── ProfileView.swift          # Estadísticas con pull-to-refresh
│   │   ├── LeaderboardView.swift      # Ranking con offline handling
│   │   ├── HowToPlayView.swift        # Tutorial swipeable de 4 pasos
│   │   └── SettingsView.swift         # Ajustes, nombre, borrar datos
│   ├── Components/
│   │   ├── AnswerButton.swift         # Botón Sí/No
│   │   ├── CategoryButton.swift       # Botón de categoría
│   │   ├── ProgressBar.swift          # Barra de progreso
│   │   ├── QuestionCard.swift         # Tarjeta de pregunta
│   │   ├── RobotAvatar.swift          # Avatar de IA
│   │   └── ToastView.swift            # Toast animado con auto-dismiss
│   └── Services/
│       ├── AIService.swift            # Algoritmo de entropía
│       ├── DataService.swift          # SwiftData CRUD + Firestore sync
│       ├── FirebaseAuthService.swift  # Auth: email, Google, Facebook
│       ├── FirestoreService.swift     # CRUD Firestore (users, sessions, leaderboard)
│       ├── NetworkMonitor.swift       # NWPathMonitor + conectividad
│       ├── SeedManager.swift          # Importa characters_seed.json
│       └── WikiService.swift          # Wikipedia REST API (actor + cache)
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

## Capturas de Pantalla

> Para completar esta sección, ejecuta la app en el simulador y toma capturas de las siguientes pantallas.
> Luego reemplaza `ruta/a/la/imagen.png` con las rutas reales dentro de `Assets/` o URLs externas.

### Onboarding y Autenticación

| Splash Screen | Login | Home |
|---|---|---|
| `![Splash](ruta/a/splash.png)` | `![Login](ruta/a/login.png)` | `![Home](ruta/a/home.png)` |

### Juego

| Categorías | Pregunta | Adivinanza correcta | Adivinanza fallida |
|---|---|---|---|
| `![Categorías](ruta/a/categorias.png)` | `![Pregunta](ruta/a/pregunta.png)` | `![Acierto](ruta/a/acierto.png)` | `![Fallo](ruta/a/fallo.png)` |

### Catálogo y Detalle

| Lista de personajes | Detalle con Wikipedia |
|---|---|
| `![Catálogo](ruta/a/catalogo.png)` | `![Detalle](ruta/a/detalle.png)` |

### Historial

| Historial de partidas | Detalle de sesión |
|---|---|
| `![Historial](ruta/a/historial.png)` | `![Sesión](ruta/a/sesion.png)` |

### Administración

| Admin list | Formulario de edición |
|---|---|
| `![Admin](ruta/a/admin.png)` | `![Formulario](ruta/a/formulario.png)` |

### Perfil y Ranking

| Perfil | Ranking all-time | Ranking semanal |
|---|---|---|
| `![Perfil](ruta/a/perfil.png)` | `![Ranking](ruta/a/ranking.png)` | `![Semanal](ruta/a/semanal.png)` |

### Otras pantallas

| Tutorial (paso 1) | Ajustes |
|---|---|
| `![Tutorial](ruta/a/tutorial.png)` | `![Ajustes](ruta/a/ajustes.png)` |

### Video Demo

[![Video Demo](https://img.youtube.com/vi/ID_DEL_VIDEO/maxresdefault.jpg)](https://youtu.be/ID_DEL_VIDEO)

> Reemplaza `ID_DEL_VIDEO` con el ID de YouTube una vez subido el video de 3–5 minutos.

## Seed de Personajes

`SeedManager.swift` verifica si la base de datos SwiftData está vacía al primer inicio. Si lo está, importa automáticamente los 31 personajes desde `characters_seed.json`. Los personajes incluyen figuras peruanas y latinoamericanas (reales y ficticias) con 38 atributos booleanos cada uno.

## Scoring

- Victoria: `max(10, (38 − preguntasRealizadas) × 10)`
- Derrota: 0 puntos
- Sin límite máximo de preguntas — la IA usa un algoritmo de entropía para seleccionar la mejor pregunta en cada turno
- Las sesiones se guardan localmente en SwiftData y se sincronizan con Firestore

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
