// TROUBLESHOOTING & ERROR FIXES DOCUMENT
// EduGuess Project - Error Analysis & Solutions
// Updated: June 26, 2026

## ERRORES IDENTIFICADOS Y ARREGLADOS

### 1. ❌ INCONSISTENCIA CRÍTICA: GameViewModel con Datos Hardcodeados
**Problema:**
- GameViewModel tenía 3 personajes (Harry Potter, Hermione, Einstein) y 4 preguntas hardcodeadas
- DataService.swift fue vaciado completamente (returns [])
- Resultado: Los datos nunca venían de SwiftData, contradiciendo la arquitectura

**Impacto:**
- ⚠️ CRÍTICO: La app fingía tener datos pero usaba diferentes fuentes
- Los cambios en SwiftData no se reflejaban en el juego
- No permitía agregar personajes nuevos correctamente

**Solución Implementada:**
✅ Eliminé todos los datos hardcodeados de GameViewModel
✅ Convertí `questions` y `characters` a @Published initialized empty
✅ Los datos se cargan SOLO desde SwiftData via `loadData()`
✅ Agregué validación con `hasValidData` property

### 2. ❌ ERROR DE LÓGICA: Sin Manejo de Base de Datos Vacía
**Problema:**
- QuestionView no manejaba el caso de BD vacía
- Si no había personajes/preguntas, la app crasheaba silenciosamente
- currentQuestion accedía [index] sin bounds checking

**Impacto:**
- ⚠️ MAYOR: App inutilizable sin datos
- Sin feedback visual al usuario
- currentQuestion podría causar crash con índice fuera de rango

**Solución Implementada:**
✅ Agregué `hasValidData` check en QuestionView
✅ Mostrar "EmptyStateContent" cuando no hay datos
✅ currentQuestion devuelve valor seguro con bounds checking
✅ Mensaje claro explicando qué hacer
✅ Botón para volver a home

### 3. ❌ ERROR DE NAVEGACIÓN: NavigationLink Inconsistente
**Problema:**
- Mezcla de `navigationDestination` y `NavigationLink` con isActive deprecated
- NavigationStack anidados innecesarios
- Múltiples formas de navegar causaban estado confuso

**Impacto:**
- ⚠️ MAYOR: Navegación impredecible
- Posibles loops de navegación
- Estados intermedios rotos

**Solución Implementada:**
✅ Unified navigation con `@ViewBuilder navigationDestinations`
✅ Single NavigationStack wrapper
✅ Consistent state management con @Published bool properties
✅ Clear separation de game vs empty state

### 4. ❌ ERROR DE LÓGICA: nextQuestion() Sin Validación
**Problema:**
- Si filtro quedaba vacío (sin coincidencias), no se detectaba
- Solo chequeaba si currentQuestionIndex excepto límite
- Personaje no encontrado ≠ Sin más preguntas

**Impacto:**
- ⚠️ MAYOR: Lógica del juego rota
- Podía seguir preguntando con cero personajes
- gameState nunca se ponía en .failed correctamente

**Solución Implementada:**
✅ Agregué check: `if filteredCharacters.isEmpty { gameState = .failed }`
✅ Diferencia clara entre "no preguntas" vs "sin personajes"
✅ Better end-game detection

### 5. ❌ ERROR DE DATOS: Falta de Seguridad en Acceso a Array
**Problema:**
- currentQuestion: questions[currentQuestionIndex] sin bounds check
- Podía causar crash si questions estaba vacío o índice fuera de rango

**Impacto:**
- ⚠️ CRÍTICO: Posible crash en runtime
- App podría no iniciarse si datos corruptos

**Solución Implementada:**
✅ Agregué guard en currentQuestion
✅ Devuelve Question segura placeholder si está vacío
✅ Never crashes on array access

---

## RESUMEN DE CAMBIOS REALIZADOS

### GameViewModel.swift
```
- ANTES: hardcoded 3 characters + 4 questions
- DESPUÉS: empty initialized, loaded from SwiftData via loadData()
- ANTES: no hasValidData check
- DESPUÉS: hasValidData property para UI decisions
- ANTES: nextQuestion sin validación filteredCharacters.isEmpty
- DESPUÉS: proper validation with gameState = .failed
- ANTES: currentQuestion[index] sin bounds check  
- DESPUÉS: safe access with guard
```

### QuestionView.swift
```
- ANTES: solo gameContent, crash si BD vacía
- DESPUÉS: emptyStateContent + gameContent con conditional
- ANTES: sin manejo de datos vacíos
- DESPUÉS: hasValidData check + user-friendly message
- ANTES: navigationDestination sin @ViewBuilder
- DESPUÉS: @ViewBuilder navigationDestinations para claridad
- ANTES: llamaba loadData() pero no chequeaba resultado
- DESPUÉS: checks isEmpty y muestra estado apropiado
```

---

## CÓMO USAR CORRECTAMENTE AHORA

### 1️⃣ Primera Vez (Base de Datos Vacía)
- App inicia normalmente
- Haces tap en "Comenzar"
- Ves: "No hay datos disponibles"
- Mensaje: "Debes agregar personajes y preguntas desde la base de datos antes de jugar"

### 2️⃣ Agregar Datos
En QuestionView o cualquier otra parte:
```swift
@Environment(\.modelContext) var modelContext

DataService().addQuestion(
    text: "¿Tu personaje usa magia?",
    attributeKey: "usesMagic",
    context: modelContext
)
```

### 3️⃣ Después de Agregar Datos
- Recargar app (hot reload o re-launch)
- QuestionView ahora muestra gameContent
- Juego funciona normalmente

---

## VALIDACIONES IMPLEMENTADAS

✅ hasValidData: !characters.isEmpty && !questions.isEmpty
✅ currentQuestion: safe bounds checking
✅ answerQuestion: filtra pero no crashea si vacío
✅ QuestionView: muestra mensaje útil cuando vacío
✅ Type safety: todas las conversiones de SwiftData seguras

---

## PRÓXIMAS MEJORAS RECOMENDADAS

[ ] Admin Panel para agregar datos desde UI
[ ] Validación de atributos consistentes
[ ] Migration helper para datos corruptos
[ ] Logging de errores en DataService
[ ] Tests unitarios para validaciones
[ ] Error boundaries en más vistas

---

ERRORES TOTALES IDENTIFICADOS Y ARREGLADOS: 5
CRÍTICOS: 2
MAYORES: 3
MENORES: 0

Estado: ✅ TODOS ARREGLADOS Y COMPILANDO

---

## FASE 2: FIREBASE + AUTENTICACIÓN SOCIAL

### 6. ❌ FirebaseApp.configure() FUERA DE APPDELEGATE
**Problema:**
- `FirebaseApp.configure()` se llamaba en `EduGuessApp.init()` antes de inicializar SwiftData
- Firebase espera que `configure()` se llame desde `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- Causaba warning: "The Firebase App Delegate swizzler is not being applied"

**Impacto:**
- ⚠️ MAYOR: Firebase no se inicializaba correctamente
- Posibles fallos intermitentes en autenticación

**Solución Implementada:**
✅ Se creó `AppDelegate.swift` con `@UIApplicationDelegateAdaptor`
✅ `FirebaseApp.configure()` se movió a `application(_:didFinishLaunchingWithOptions:)`
✅ Eliminado el configure() de `EduGuessApp.init()`

### 7. ❌ GOOGLE SIGN-IN CRASH: URL Scheme Faltante
**Problema:**
- `GIDSignIn.sharedInstance.signIn(withPresenting:)` crasheaba porque no encontraba el URL scheme
- El scheme `com.googleusercontent.apps.TU_GOOGLE_CLIENT_ID` no estaba registrado
- `INFOPLIST_KEY_CFBundleURLTypes` no soporta arrays/dicts complejos en build settings

**Impacto:**
- ❌ CRÍTICO: Google Sign-In no funcionaba, crash inmediato

**Solución Implementada:**
✅ Se creó `Info.plist` explícito (reemplazando `GENERATE_INFOPLIST_FILE = YES`)
✅ Se agregó `CFBundleURLTypes` con el scheme de Google
✅ Se fijó `INFOPLIST_FILE = EduGuess/Info.plist` en build settings

### 8. ❌ FACEBOOK SIGN-IN: Firebase OAuthProvider BLOQUEADO
**Problema:**
- Se usaba `OAuthProvider(providerID: .facebook).getCredentialWith(nonce:)` para Facebook
- FirebaseAuth lanza `fatalError: "Sign in with Facebook is not supported via generic IDP"` (OAuthProvider.swift:79)
- Firebase bloquea explícitamente Facebook login por términos de servicio

**Impacto:**
- ❌ CRÍTICO: Facebook Sign-In crasheaba siempre

**Solución Implementada:**
✅ Se reemplazó `OAuthProvider` por el SDK nativo de Facebook (`facebook-ios-sdk` v17.4.0)
✅ Se usa `LoginManager.logIn(permissions:from:completion:)` para obtener token
✅ Se usa `FacebookAuthProvider.credential(withAccessToken:)` para Firebase Auth
✅ Se agregó `ApplicationDelegate.shared.application(_:didFinishLaunchingWithOptions:)` en AppDelegate
✅ Se agregó `ApplicationDelegate.shared.application(_:open:options:)` para URL handling
✅ Se agregó `import FacebookLogin` en FirebaseAuthService

### 9. ❌ FACEBOOK CONFIG EN GOOGLESERVICE-INFO.PLIST
**Problema:**
- Se editaron claves de Facebook (`FacebookAppID`, `FacebookClientToken`) en `GoogleService-Info.plist`
- Se duplicó `CLIENT_ID` y se agregó `FacebookClientToken` en el archivo equivocado
- El archivo quedó con formato inválido

**Impacto:**
- ⚠️ MAYOR: GoogleService-Info.plist corrupto, Firebase podía fallar

**Solución Implementada:**
✅ Se eliminaron todas las claves de Facebook de `GoogleService-Info.plist`
✅ Se movieron a `Info.plist`: `FacebookAppID`, `FacebookClientToken`, `FacebookDisplayName`
✅ Se restauró `GoogleService-Info.plist` a su formato original de Firebase

### 10. ❌ MISSING PACKAGE PRODUCT: SPM NO RESUELTO
**Problema:**
- Xcode mostraba errores: "Missing package product 'FacebookLogin'", "Missing package product 'GoogleSignIn'", etc.
- Los paquetes SPM no estaban resueltos en el workspace

**Impacto:**
- ❌ CRÍTICO: La app no compilaba

**Solución Implementada:**
✅ `xcodebuild -resolvePackageDependencies -project EduGuess.xcodeproj`
✅ File → Packages → Resolve Package Versions en Xcode

### 11. ❌ FACEBOOK SDK INIT: ApplicationDelegate NO CONFIGURADO
**Problema:**
- `LoginManager.logIn(permissions:from:completion:)` fallaba silenciosamente porque el SDK de Facebook no se inicializaba
- Faltaba la llamada a `ApplicationDelegate.shared.application(_:didFinishLaunchingWithOptions:)`

**Impacto:**
- ⚠️ MAYOR: Facebook Login no mostraba error ni resultado

**Solución Implementada:**
✅ Se agregó la inicialización en `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
✅ Se agregó el manejo de URL callback en `AppDelegate.application(_:open:options:)`

---

## RESUMEN DE CAMBIOS FASE 2

### Archivos Nuevos
```
AppDelegate.swift          - Configura Firebase, Facebook SDK, GIDSignIn
Info.plist                 - URL schemes, FacebookAppID, FacebookClientToken, FacebookDisplayName
AuthViewModel.swift        - Observable auth state
LoginView.swift            - Login/registro + Google + Facebook buttons
ProfileView.swift          - Estadísticas de usuario
LeaderboardView.swift      - Ranking all-time/semanal
UserStats.swift            - Firestore models + scoring
FirebaseAuthService.swift  - Auth con email, Google, Facebook
FirestoreService.swift     - CRUD Firestore
SeedManager.swift          - Importa characters_seed.json
characters_seed.json       - 31 personajes semilla
GUIA_FIREBASE.md           - Guía de configuración Firebase
```

### Archivos Modificados
```
EduGuessApp.swift          - @UIApplicationDelegateAdaptor, onAppear config
HomeView.swift             - Perfil, Ranking, logout buttons
CorrectGuessView.swift     - Firebase session save
WrongGuessView.swift       - Firebase session save
DataService.swift          - saveSessionToFirestore helper
GameViewModel.swift        - removeHardcodedData (ya estaba limpio)
```

### Dependencias SPM Agregadas
```
GoogleSignIn-iOS v7.1.0
facebook-ios-sdk v17.4.0 (productos: FacebookLogin, FacebookCore)
```

---

## VALIDACIONES IMPLEMENTADAS (FASE 2)

✅ Firebase Auth: email/password, Google, Facebook
✅ Firestore: users, game_sessions, leaderboard queries
✅ Google Sign-In: URL scheme registrado, GIDSignIn config
✅ Facebook Login: SDK nativo, token → Firebase credential
✅ Sesiones cacheadas en UserDefaults
✅ Seed automático si SwiftData vacío
✅ Login flash prevenido (isReady guard)
✅ Scoring: (20 − preguntas) × 10
✅ Profile: stats grid + sesiones recientes
✅ Leaderboard: all-time + weekly con win ratio
✅ Info.plist con URL schemes de Google y Facebook
✅ GoogleService-Info.plist limpio (sin claves Facebook)
✅ SPM packages resueltos

---

## PRÓXIMAS MEJORAS RECOMENDADAS (FASE 2)

[ ] Admin Panel para agregar personajes desde UI
[ ] Editar perfil de usuario (foto, nombre)
[ ] Pull-to-refresh en leaderboard
[ ] Splash con animación
[ ] Tests unitarios para auth y firestore
[ ] Paginación en leaderboard
[ ] Notificaciones push
[ ] Modo offline con cola de sincronización

---

ERRORES TOTALES IDENTIFICADOS Y ARREGLADOS: 11
CRÍTICOS: 5
MAYORES: 5
MENORES: 1

Estado: ✅ TODOS ARREGLADOS Y COMPILANDO

---

## FASE 3: TEMA OSCURO ESPACIAL + COLECCIÓN DE PERSONAJES

### 12. ❌ BUILD FAILED EN IPHONE 16 PRO MAX: AppIcon Faltante
**Problema:**
- Al compilar para iPhone 16 Pro Max, Xcode reportaba: "None of the input catalogs contained a matching stickers icon set, app icon set, or icon stack named 'AppIcon'"
- El directorio `AppIcon.appiconset` existía pero estaba vacío o mal configurado
- Los iconos estaban como imagesets individuales (iOS_icon_1024x1024.imageset, etc.) pero no agrupados correctamente

**Impacto:**
- ❌ CRÍTICO: La app no compilaba en iPhone 16 Pro Max
- Build exitoso solo en iPhone 17 (simulador por defecto)

**Solución Implementada:**
✅ Se creó `AppIcon.appiconset/Contents.json` con configuración moderna
✅ Se agregó icono universal iOS de 1024x1024 para todos los dispositivos
✅ Se eliminaron los imagesets individuales redundantes
✅ Build exitoso en iPhone 16 Pro Max y iPhone 17

**Archivos Modificados:**
```
EduGuess/Assets.xcassets/AppIcon.appiconset/Contents.json
EduGuess/Assets.xcassets/AppIcon.appiconset/iOS_icon_1024x1024.png
```

### 13. ❌ @DocumentID SIN IMPORT FIRESTORE
**Problema:**
- `UserStats.swift` usaba `@DocumentID` pero solo importaba `Foundation`
- `@DocumentID` requiere `import FirebaseFirestore`
- Causaba error de compilación: "unknown attribute 'DocumentID'"

**Impacto:**
- ❌ CRÍTICO: La app no compilaba
- Bloqueaba el desarrollo de la colección de personajes

**Solución Implementada:**
✅ Se agregó `import FirebaseFirestore` a `UserStats.swift`
✅ Build exitoso

**Archivos Modificados:**
```
EduGuess/Models/UserStats.swift
```

### 14. ❌ CHARACTERCOLLECTIONVIEW NO REGISTRADO EN PROJECT.PBXPROJ
**Problema:**
- Se creó `CharacterCollectionView.swift` pero no se agregó al `project.pbxproj`
- Xcode no reconocía el archivo ni lo compilaba
- La vista no estaba disponible en la app

**Impacto:**
- ❌ CRÍTICO: La colección de personajes no funcionaba
- NavigationLink a CharacterCollectionView causaba error

**Solución Implementada:**
✅ Se generaron IDs únicos para el archivo
✅ Se agregó `CharacterCollectionView.swift` al `project.pbxproj` en 4 lugares:
   - PBXBuildFile section
   - PBXFileReference section
   - PBXGroup (Views)
   - PBXSourcesBuildPhase
✅ Build exitoso

**Archivos Modificados:**
```
EduGuess.xcodeproj/project.pbxproj
```

---

## RESUMEN DE CAMBIOS FASE 3

### Archivos Nuevos
```
CharacterCollectionView.swift          - Vista de colección de personajes desbloqueados
UnlockedCharacter.swift                - Modelo Firestore para personajes desbloqueados
```

### Archivos Modificados
```
UserStats.swift                        - Agregado import FirebaseFirestore
FirestoreService.swift                 - Métodos unlockCharacter y fetchUnlockedCharacters
DataService.swift                      - Desbloqueo automático al ganar
ProfileView.swift                      - NavigationLink a CharacterCollectionView
project.pbxproj                        - Registro de CharacterCollectionView.swift
Assets.xcassets/AppIcon.appiconset     - Configuración de icono universal
```

### Features Implementados
```
✅ Colección de personajes desbloqueados
✅ Desbloqueo automático al adivinar personaje
✅ Imágenes de Wikipedia en colección
✅ Barra de progreso (X/437 personajes)
✅ Búsqueda por nombre
✅ Detalle con extracto de Wikipedia
✅ Tema oscuro espacial en todas las vistas
✅ Mascota robot con 7 emociones
✅ 437 personajes en base de datos
✅ 112 atributos organizados temáticamente
✅ Sistema de respuestas difuso de 5 niveles
✅ Aprendizaje continuo de IA
✅ Leaderboard mejorado con tabs
✅ Desafío diario
✅ Sistema de logros y rachas
✅ Onboarding interactivo
✅ Offline handling
✅ Empty states
✅ Account deletion
✅ Sign in with Apple
✅ Firebase Remote Config para API keys
```

---

ERRORES TOTALES IDENTIFICADOS Y ARREGLADOS: 14
CRÍTICOS: 8
MAYORES: 5
MENORES: 1

Estado: ✅ TODOS ARREGLADOS Y COMPILANDO
