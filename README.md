EduGuess - La IA que Adivina Personajes 🧠

Descripción del Proyecto

EduGuess es una aplicación educativa interactiva desarrollada en SwiftUI que implementa un juego estilo "20 Preguntas". La aplicación utiliza un sistema de filtrado inteligente donde un usuario piensa en un personaje y la "IA" realiza preguntas de sí/no para intentar adivinarlo.

Características Principales

- Juego interactivo basado en preguntas de sí/no
- Sistema de filtrado inteligente de personajes
- Interfaz moderna con gradientes y animaciones
- Diseño responsivo para iOS, iPadOS y macOS
- Interfaz en español
- Navegación con NavigationStack
- Pantallas de acierto y fallo
- Arquitectura MVVM

Requerimientos

- macOS: 12.0 o superior
- Xcode: 14.0 o superior
- iOS: 15.0 o superior
- Swift: 5.7 o superior

Estructura de Carpetas

EduGuess/
├── EduGuess/
│   ├── EduGuessApp.swift
│   ├── ContentView.swift
│   ├── Assets/
│   │   └── Assets.xcassets/
│   ├── Models/
│   │   ├── GameState.swift
│   │   ├── Question.swift
│   │   └── Character.swift
│   ├── ViewModels/
│   │   └── GameViewModel.swift
│   ├── Views/
│   │   ├── SplashView.swift
│   │   ├── HomeView.swift
│   │   ├── QuestionView.swift
│   │   ├── CorrectGuessView.swift
│   │   └── WrongGuessView.swift
│   ├── Components/
│   │   ├── AnswerButton.swift
│   │   ├── CategoryButton.swift
│   │   ├── ProgressBar.swift
│   │   ├── QuestionCard.swift
│   │   └── RobotAvatar.swift
│   └── Services/
│       ├── AIService.swift
│       └── DataService.swift
└── EduGuess.xcodeproj/

Abrir y Ejecutar en Xcode

1) Desde la terminal: open EduGuess.xcodeproj
2) O abrir Xcode y seleccionar File → Open → EduGuess.xcodeproj
3) Seleccionar un simulador o dispositivo y presionar Cmd+R

Agregar Preguntas y Personajes

- Las preguntas y personajes se definen en `GameViewModel.swift`.
- Cada pregunta tiene `attributeKey` que debe coincidir con las claves booleanas en `Character.attributes`.
- Todos los personajes deben incluir las mismas claves de atributos.

Posibles Mejoras

- Integración con IA (OpenAI) para generar preguntas dinámicas.
- Cargar datos desde API o Base de Datos (Core Data, CloudKit).
- Gamificación: puntos, logros y rankings.
- Mejoras de diseño y accesibilidad.
- Tests unitarios y de UI.

Notas rápidas

- Flujo: SplashView → HomeView → QuestionView (en desarrollo) → Correct/Wrong View
- Lógica: `GameViewModel` filtra personajes según respuestas (atributos booleanos)

Contacto

- Creadora Original: Daniela Nicol Salazar Quina

¡Disfruta mejorando EduGuess! 🎮✨
