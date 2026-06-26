# Plan de Implementación: EduGuess → App Store

> **Versión:** 1.1  
> **Fecha:** 26 de junio de 2026  
> **Estado:** En progreso  
> **Tiempo total estimado:** 64-82 horas (~4 semanas)  
> **Última actualización:** Tema oscuro espacial, colección de personajes, mejoras de IA

---

## Tabla de Contenidos

1. [Visión General](#1-visión-general)
2. [FASE 1: Bloqueantes de Apple](#2-fase-1-bloqueantes-de-apple)
3. [FASE 2: Seguridad y Backend](#3-fase-2-seguridad-y-backend)
4. [FASE 3: UX/UI Polish](#4-fase-3-uxui-polish)
5. [FASE 4: Accesibilidad](#5-fase-4-accesibilidad)
6. [FASE 5: Testing y Pre-Launch](#6-fase-5-testing-y-pre-launch)
7. [FASE 6: Submit y Post-Launch](#7-fase-6-submit-y-post-launch)
8. [Calendario de Ejecución](#8-calendario-de-ejecución)
9. [Checklist Final Pre-Submit](#9-checklist-final-pre-submit)

---

## 1. Visión General

Este documento detalla el plan completo para llevar EduGuess desde su estado actual hasta la publicación en la App Store. Las fases están diseñadas para ejecutarse **secuencialmente**, ya que muchas dependen de las anteriores.

### Prioridades

| Prioridad | Fase | Justificación |
|-----------|------|---------------|
| **P0 - Crítico** | Fase 1 | Apple rechazará la app inmediatamente si falta Sign in with Apple, Account Deletion, o Privacy Policy |
| **P1 - Alto** | Fase 2 | API keys expuestas y datos en UserDefaults son vulnerabilidades de seguridad |
| **P2 - Medio** | Fase 3 | UX pulido aumenta retención y ratings 5 estrellas |
| **P3 - Medio** | Fase 4 | Accesibilidad es requerida por Guideline 4.1 y amplía el público |
| **P4 - Bajo** | Fase 5-6 | Testing y submit son los pasos finales |

### Recursos Necesarios

- **Cuenta Apple Developer** ($99/año) — para certificates, App Store Connect, TestFlight
- **Cuenta Firebase** (plan Spark/gratuito suficiente para inicio)
- **Meta Developer Account** — para Facebook Login en producción
- **GitHub Pages** — para hosting de Privacy Policy (gratuito)
- **Dispositivo físico iOS** — para probar Sign in with Apple y App Attest

---

## 2. FASE 1: Bloqueantes de Apple

> **Tiempo estimado:** 16-20 horas  
> **Semana:** 1  
> **Estado:** 🟡 Pendiente

### 2.1 Sign in with Apple (REQUERIDO)

**Guideline 4.8:** Si tu app usa login de terceros (Google/Facebook), **DEBES** ofrecer Sign in with Apple.

**Impacto:** Rechazo inmediato en review si falta.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 1.1.1 | Agregar `AuthenticationServices` framework | `EduGuess.xcodeproj` → Build Phases | ✅ |
| 1.1.2 | Importar `AuthenticationServices` en FirebaseAuthService | `Services/FirebaseAuthService.swift` | ✅ |
| 1.1.3 | Crear método `signInWithApple()` con nonce SHA-256 | `Services/FirebaseAuthService.swift` | ✅ |
| 1.1.4 | Agregar botón `ASAuthorizationAppleIDButton` en LoginView | `Views/LoginView.swift` | ✅ |
| 1.1.5 | Manejar callback de Apple Sign In en AppDelegate | `AppDelegate.swift` | ✅ |
| 1.1.6 | Configurar Apple Sign-In en Firebase Console | [Firebase Console](https://console.firebase.google.com) | 🔲 |
| 1.1.7 | Configurar Apple Sign-In en Apple Developer Portal | [Apple Developer](https://developer.apple.com) | 🔲 |
| 1.1.8 | Probar flujo end-to-end: registro, login, logout, re-login | Simulator + Device | 🔲 |

#### Notas Técnicas

- Reutilizar el método `randomNonceString()` y `sha256()` que ya existen en `FirebaseAuthService`
- El botón de Apple debe usar el estilo nativo (`ASAuthorizationAppleIDButton`) — Apple prohíbe botones custom
- Guardar el `appleUserID` en Firestore para permitir re-autenticación silenciosa

---

### 2.2 Account Deletion (REQUERIDO)

**Guideline 5.1.1(v):** Las apps que permiten crear cuentas deben permitir eliminarlas desde la app.

**Impacto:** Rechazo inmediato si falta.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 1.2.1 | Agregar sección "Zona de Peligro" en SettingsView | `Views/SettingsView.swift` | ✅ |
| 1.2.2 | Crear modal de confirmación con re-autenticación | `Views/SettingsView.swift` | ✅ |
| 1.2.3 | Implementar `deleteAccount()` en AuthViewModel | `ViewModels/AuthViewModel.swift` | ✅ |
| 1.2.4 | Re-autenticar usuario antes de borrar (Firebase lo exige) | `ViewModels/AuthViewModel.swift` | ✅ |
| 1.2.5 | Borrar documento `users/{uid}` en Firestore | `Services/FirestoreService.swift` | ✅ |
| 1.2.6 | Borrar sesiones de `game_sessions` del usuario | `Services/FirestoreService.swift` | ✅ |
| 1.2.7 | Llamar `Auth.auth().currentUser?.delete()` | `Services/FirebaseAuthService.swift` | ✅ |
| 1.2.8 | Limpiar SwiftData local y Keychain/UserDefaults | `ViewModels/AuthViewModel.swift` | ✅ |
| 1.2.9 | Navegar a LoginView tras eliminación | `Views/SettingsView.swift` | ✅ |
| 1.2.10 | Test: verificar que el usuario ya no puede loguearse | Manual | 🔲 |

#### Flujo de Eliminación

```
Usuario toca "Eliminar cuenta"
  ↓
Modal de confirmación: "¿Estás seguro? Esta acción no se puede deshacer."
  ↓
Re-autenticación (solicitar contraseña actual, o re-login con Apple/Google/Facebook)
  ↓
Borrar datos en Firestore (users/{uid}, game_sessions/*)
  ↓
Borrar cuenta de Firebase Auth
  ↓
Borrar datos locales (SwiftData, Keychain, UserDefaults)
  ↓
Navegar a LoginView
```

---

### 2.3 App Tracking Transparency (ATT)

**Guideline 5.1.2:** Facebook SDK y Google Sign-In rastrean al usuario. Debes solicitar permiso explícito.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 1.3.1 | Agregar `NSUserTrackingUsageDescription` a Info.plist | `Info.plist` | ✅ |
| 1.3.2 | Importar `AppTrackingTransparency` en AppDelegate | `AppDelegate.swift` | ✅ |
| 1.3.3 | Solicitar permiso ATT al inicio (después del splash) | `AppDelegate.swift` o `EduGuessApp.swift` | ✅ |
| 1.3.4 | Configurar Facebook SDK para respetar estado de ATT | `AppDelegate.swift` | ✅ |
| 1.3.5 | Configurar Google Sign-In para respetar estado de ATT | `AppDelegate.swift` | ✅ |
| 1.3.6 | Probar: Denegar ATT → verificar que login social funciona | Device físico | 🔲 |

#### Info.plist Requerido

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Tu información se usará para mejorar la experiencia de inicio de sesión y publicidad personalizada.</string>
```

---

### 2.4 Privacy Policy & Terms of Service

**Guideline 5.1.1:** Requerido para apps con autenticación y almacenamiento de datos.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 1.4.1 | Crear repositorio GitHub Pages para legal | GitHub | 🔲 |
| 1.4.2 | Redactar Privacy Policy en español | Markdown | 🔲 |
| 1.4.3 | Redactar Privacy Policy en inglés | Markdown | 🔲 |
| 1.4.4 | Redactar Terms of Service | Markdown | 🔲 |
| 1.4.5 | Listar TODOS los datos recolectados | Documento | 🔲 |
| 1.4.6 | Explicar propósito de cada dato | Documento | 🔲 |
| 1.4.7 | Mencionar proveedores de terceros | Documento | 🔲 |
| 1.4.8 | Instrucciones para ejercer derechos GDPR/COPPA | Documento | 🔲 |
| 1.4.9 | Agregar links en LoginView (antes de registrarse) | `Views/LoginView.swift` | 🔲 |
| 1.4.10 | Agregar links en SettingsView | `Views/SettingsView.swift` | 🔲 |
| 1.4.11 | Ingresar URL de privacidad en App Store Connect | App Store Connect | 🔲 |

#### Datos Recolectados (para Privacy Policy)

| Dato | Propósito | Proveedor |
|------|-----------|-----------|
| Nombre | Perfil de usuario, leaderboard | Firebase Auth |
| Email | Autenticación, recuperación de cuenta | Firebase Auth |
| Avatar/Foto | Personalización de perfil | Firestore |
| Puntuaciones y sesiones | Leaderboard, estadísticas | Firestore |
| Device ID (IDFA) | Publicidad personalizada | Facebook, Google |
| ID de usuario anónimo | Funcionalidad offline | Local |

---

## 3. FASE 2: Seguridad y Backend

> **Tiempo estimado:** 12-16 horas  
> **Semana:** 2  
> **Dependencias:** Fase 1 completada  
> **Estado:** 🟡 Pendiente

### 3.1 Proteger API Key de Gemini

**Problema:** La API key de Gemini está hardcodeada en el binario. Cualquier usuario puede extraerla.

**Solución recomendada:** Cloud Function de Firebase.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 2.1.1 | Crear Cloud Function `generateQuestion` | `functions/index.js` | 🔲 |
| 2.1.2 | La CF recibe `attributeKey` y devuelve pregunta | Cloud Function | 🔲 |
| 2.1.3 | Validar `App Check token` en la CF | Cloud Function | 🔲 |
| 2.1.4 | Rate limiting: max 10 req/min por uid | Cloud Function | 🔲 |
| 2.1.5 | Eliminar `GenerativeAIConfig.swift` del proyecto | `Config/GenerativeAIConfig.swift` | 🔲 |
| 2.1.6 | Actualizar `GameViewModel` para llamar a la CF | `ViewModels/GameViewModel.swift` | 🔲 |
| 2.1.7 | Manejar error de rate limit en UI | `ViewModels/GameViewModel.swift` | 🔲 |
| 2.1.8 | Deploy de Cloud Function | Firebase CLI | 🔲 |

#### Alternativa (si no se quiere Cloud Function)

Mover la API key a un archivo `.xcconfig` que no se sube al repo, y rotar la key periódicamente. **Menos seguro pero más rápido.**

---

### 3.2 Migrar Auth de UserDefaults a Keychain

**Problema:** UID, email y nombre se guardan en texto plano en UserDefaults.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 2.2.1 | Agregar `KeychainSwift` vía SPM | Xcode → SPM | 🔲 |
| 2.2.2 | Crear `KeychainService.swift` wrapper | `Services/KeychainService.swift` | 🔲 |
| 2.2.3 | Migrar `AuthKeys` de UserDefaults a Keychain | `Services/KeychainService.swift` | 🔲 |
| 2.2.4 | Actualizar `FirebaseAuthService` para usar Keychain | `Services/FirebaseAuthService.swift` | 🔲 |
| 2.2.5 | Actualizar `AuthViewModel` para usar Keychain | `ViewModels/AuthViewModel.swift` | 🔲 |
| 2.2.6 | Migración automática: si hay datos en UserDefaults, mover a Keychain y limpiar | `Services/KeychainService.swift` | 🔲 |

---

### 3.3 Firebase App Check (App Attest)

**Objetivo:** Proteger Firebase de abuso en producción.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 2.3.1 | Habilitar App Check en Firebase Console | Firebase Console | 🔲 |
| 2.3.2 | Agregar `FirebaseAppCheck` como dependencia SPM | Xcode | 🔲 |
| 2.3.3 | Configurar `AppAttestProvider` en AppDelegate | `AppDelegate.swift` | 🔲 |
| 2.3.4 | Actualizar Cloud Functions para verificar token | Cloud Functions | 🔲 |
| 2.3.5 | Probar en device físico | Device | 🔲 |

**Nota:** App Attest **no funciona en simulador**. Se requiere un device físico para testing.

---

### 3.4 Firestore Rules de Producción

**Problema actual:** Las reglas usan `allow read, write: if true` en modo prueba.

#### Rules Recomendadas (Producción)

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Perfil de usuario: solo el dueño puede leer/escribir
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Sesiones de juego: crear propias, leer propias
    match /game_sessions/{sessionId} {
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
    
    // Desafío diario: lectura pública, escritura propia
    match /daily_challenges/{challenge}/scores/{userId} {
      allow read: if true;
      allow write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Leaderboard: solo lectura pública
    match /leaderboard/{entryId} {
      allow read: if true;
      allow write: if false;
    }
    
    // Logros: lectura propia, escritura propia
    match /users/{userId}/achievements/{achievementId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
  }
}
```

#### Tareas

| # | Tarea | Plataforma | Estado |
|---|-------|------------|--------|
| 2.4.1 | Escribir reglas de producción completas | Firebase Console | 🔲 |
| 2.4.2 | Validar con 2 cuentas diferentes | Firebase Console | 🔲 |
| 2.4.3 | Deploy rules | Firebase CLI | 🔲 |

---

## 4. FASE 3: UX/UI Polish

> **Tiempo estimado:** 14-18 horas  
> **Semana:** 3  
> **Dependencias:** Fase 1 y 2 completadas  
> **Estado:** 🟡 Pendiente

### 4.1 Onboarding para Primer Uso

**Objetivo:** Los usuarios nuevos entiendan qué hacer sin confusión.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 3.1.1 | Crear `OnboardingView.swift` (3-4 pantallas swipeables) | `Views/OnboardingView.swift` | ✅ |
| 3.1.2 | Pantalla 1: "Piensa en un personaje" + animación | `Views/OnboardingView.swift` | ✅ |
| 3.1.3 | Pantalla 2: "Responde Sí o No" | `Views/OnboardingView.swift` | ✅ |
| 3.1.4 | Pantalla 3: "La IA adivinará" + demo visual | `Views/OnboardingView.swift` | ✅ |
| 3.1.5 | Pantalla 4: "Compite en el ranking" | `Views/OnboardingView.swift` | ✅ |
| 3.1.6 | Guardar flag `hasSeenOnboarding` en UserDefaults | `EduGuessApp.swift` | ✅ |
| 3.1.7 | Mostrar onboarding antes del login si `!hasSeenOnboarding` | `EduGuessApp.swift` | ✅ |
| 3.1.8 | Agregar botón "Saltir" y dots de progreso | `Views/OnboardingView.swift` | ✅ |

---

### 4.2 Splash Screen Reactivo

**Problema:** Timer fijo de 2 segundos obliga al usuario a esperar innecesariamente.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 3.2.1 | Eliminar `DispatchQueue.main.asyncAfter(deadline: .now() + 2)` | `Views/SplashView.swift` | 🔲 |
| 3.2.2 | Navegar a HomeView tan pronto como `authVM.isReady` | `Views/SplashView.swift` | 🔲 |
| 3.2.3 | Mantener animación de entrada/salida sin delay forzado | `Views/SplashView.swift` | 🔲 |

---

### 4.3 Estados de Error y Offline

**Objetivo:** La app no debe parecer rota cuando no hay internet.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 3.3.1 | Crear componente `OfflineBannerView.swift` | `Components/OfflineBannerView.swift` | ✅ |
| 3.3.2 | Integrar `NetworkMonitor` en vistas de Firestore | Varias vistas | ✅ |
| 3.3.3 | Mostrar banner cuando `!isConnected` | `HomeView.swift`, `ProfileView.swift` | ✅ |
| 3.3.4 | Leaderboard offline: mostrar datos cacheados + label "Offline" | `Views/LeaderboardView.swift` | ✅ |
| 3.3.5 | Perfil offline: mostrar stats locales + label "Sincronizando..." | `Views/ProfileView.swift` | ✅ |
| 3.3.6 | Implementar cola de sincronización offline | `Services/DataService.swift` | 🔲 |

---

### 4.4 Content Unavailable / Empty States

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 3.4.1 | `CharacterListView`: empty state con CTA | `Views/CharacterListView.swift` | ✅ |
| 3.4.2 | `GameHistoryView`: empty state con ilustración | `Views/GameHistoryView.swift` | ✅ |
| 3.4.3 | `LeaderboardView`: empty state "Sé el primero" | `Views/LeaderboardView.swift` | ✅ |
| 3.4.4 | `AchievementListView`: empty state "Juega para desbloquear" | `Views/AchievementListView.swift` | ✅ |

---

### 4.5 Correcciones Menores

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 3.5.1 | Versión dinámica en SettingsView | `Views/SettingsView.swift` | 🔲 |
| 3.5.2 | `FacebookDisplayName` corregir a "EduGuess" | `Info.plist` | ✅ |
| 3.5.3 | Agregar `CFBundleLocalizations` (es, en) | `Info.plist` | 🔲 |
| 3.5.4 | Revisar vistas en iPhone SE (pantalla pequeña) | Testing | 🔲 |
| 3.5.5 | Revisar Dark Mode en todas las pantallas | Testing | ✅ |

---

## 5. FASE 4: Accesibilidad

> **Tiempo estimado:** 8-10 horas  
> **Semana:** 3-4 (paralelo con Fase 3)  
> **Estado:** 🟡 Pendiente

### 5.1 VoiceOver

**Guideline 4.1:** Las apps deben ser accesibles para usuarios con discapacidad visual.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 4.1.1 | `AnswerButton`: label descriptivo para Sí | `Components/AnswerButton.swift` | 🔲 |
| 4.1.2 | `AnswerButton`: label descriptivo para No | `Components/AnswerButton.swift` | 🔲 |
| 4.1.3 | `ProgressBar`: value "Pregunta X de Y" | `Components/ProgressBar.swift` | 🔲 |
| 4.1.4 | `RobotAvatar`: label "Asistente de IA" | `Components/RobotAvatar.swift` | 🔲 |
| 4.1.5 | `AvatarView`: label "Avatar de [nombre]" | `Components/AvatarView.swift` | 🔲 |
| 4.1.6 | Todos los `NavigationLink`: hint "Doble tap para navegar" | Varias vistas | 🔲 |
| 4.1.7 | `ToastView`: anunciar con `AccessibilityNotification` | `Components/ToastView.swift` | 🔲 |

---

### 5.2 Dynamic Type

**Objetivo:** Soportar que el usuario cambie el tamaño de fuente en Configuración de iOS.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 4.2.1 | Reemplazar `.font(.system(size: X))` por estilos semánticos | Varias vistas | 🔲 |
| 4.2.2 | Usar `.largeTitle`, `.title`, `.headline`, `.body`, `.caption` | Varias vistas | 🔲 |
| 4.2.3 | Verificar que layouts no se rompan en tamaño AX5 | Testing | 🔲 |

---

### 5.3 Reduce Motion

**Objetivo:** Respetar la preferencia del usuario de reducir animaciones.

#### Tareas

| # | Tarea | Archivos | Estado |
|---|-------|----------|--------|
| 4.3.1 | `SplashView`: omitir animación si reduce motion | `Views/SplashView.swift` | 🔲 |
| 4.3.2 | `CorrectGuessView`: omitir confetti si reduce motion | `Views/CorrectGuessView.swift` | 🔲 |
| 4.3.3 | `HomeView`: usar transiciones simples si reduce motion | `Views/HomeView.swift` | 🔲 |

---

## 6. FASE 5: Testing y Pre-Launch

> **Tiempo estimado:** 10-12 horas  
> **Semana:** 4  
> **Estado:** 🟡 Pendiente

### 6.1 TestFlight Interno

#### Tareas

| # | Tarea | Plataforma | Estado |
|---|-------|------------|--------|
| 5.1.1 | Crear App ID en Apple Developer Portal | developer.apple.com | 🔲 |
| 5.1.2 | Configurar Bundle ID y Capabilities | Xcode + Portal | 🔲 |
| 5.1.3 | Crear Certificates (Distribution) | Xcode | 🔲 |
| 5.1.4 | Crear Provisioning Profile (App Store) | Xcode | 🔲 |
| 5.1.5 | Archive y Upload a App Store Connect | Xcode | 🔲 |
| 5.1.6 | Crear grupo de testers internos (2-5 personas) | App Store Connect | 🔲 |
| 5.1.7 | Enviar invitaciones TestFlight | App Store Connect | 🔲 |
| 5.1.8 | Recopilar feedback y crashes | TestFlight | 🔲 |

---

### 6.2 Escenarios Críticos a Probar

| # | Escenario | Resultado Esperado | Estado |
|---|-----------|-------------------|--------|
| 5.2.1 | Instalar app fresca → jugar offline → recuperar red → verificar sync | Sesiones sincronizadas | 🔲 |
| 5.2.2 | Crear cuenta → jugar 10 partidas → eliminar cuenta → re-registrarse | Datos anteriores no visibles | 🔲 |
| 5.2.3 | Sign in with Apple → logout → Sign in with Google (mismo email) | Cuentas separadas o merge | 🔲 |
| 5.2.4 | iPhone SE → juego completo → no UI truncation | Todo visible | 🔲 |
| 5.2.5 | Modo avión durante adivinanza → responder → recuperar red | Respuesta guardada | 🔲 |
| 5.2.6 | 1000+ personajes en BD → scroll en CharacterListView | 60 FPS | 🔲 |
| 5.2.7 | Daily Challenge → cambiar fecha del sistema → verificar estabilidad | Mismo personaje por día | 🔲 |
| 5.2.8 | VoiceOver completo → navegar todo el flujo | Todos los elementos anunciados | 🔲 |
| 5.2.9 | Dynamic Type AX5 → todas las pantallas | Layouts no rotos | 🔲 |
| 5.2.10 | 100 usuarios simultáneos en leaderboard | Sin crashes, datos consistentes | 🔲 |

---

### 6.3 Preparar Metadata de App Store

| # | Tarea | Formato | Estado |
|---|-------|---------|--------|
| 5.3.1 | Screenshots 6.5" (iPhone 15 Pro Max): 5 capturas | PNG/JPG (1242 x 2688) | 🔲 |
| 5.3.2 | Screenshots 5.5" (iPhone 8 Plus): 5 capturas | PNG/JPG (1242 x 2208) | 🔲 |
| 5.3.3 | Screenshots iPad Pro: 5 capturas | PNG/JPG (2048 x 2732) | 🔲 |
| 5.3.4 | App Preview Video (opcional pero recomendado) | MP4, 15-30 seg, H264 | 🔲 |
| 5.3.5 | Icono de app en todos los tamaños | `Assets.xcassets` | 🔲 |
| 5.3.6 | Descripción de app (español) | Texto, máx 4000 chars | 🔲 |
| 5.3.7 | Descripción de app (inglés) | Texto, máx 4000 chars | 🔲 |
| 5.3.8 | Keywords | Texto, máx 100 chars | 🔲 |
| 5.3.9 | Promotional Text | Texto, máx 170 chars | 🔲 |
| 5.3.10 | Support URL | Página web | 🔲 |
| 5.3.11 | Marketing URL (opcional) | Página web | 🔲 |

#### Sugerencia de Keywords

```
educational, trivia, guess, characters, AI, game, quiz, brain, puzzle, fun, learning, kids, family, multiplayer, leaderboard
```

#### Sugerencia de Descripción (Español)

```
EduGuess es el juego educativo donde la IA adivina cualquier personaje que estés pensando.

¿Cómo jugar?
1. Piensa en un personaje real o ficticio
2. Responde las preguntas de Sí o No
3. ¡La IA intentará adivinarlo!

Características:
• Más de 30 personajes peruanos y latinoamericanos
• Modo desafío diario con ranking global
• Sistema de logros y rachas
• Crea tus propios personajes
• Compite en el leaderboard mundial

Perfecto para aprender mientras te diviertes. ¿Podrás vencer a la IA?
```

---

## 7. FASE 6: Submit y Post-Launch

> **Tiempo estimado:** 4-6 horas  
> **Semana:** 4-5  
> **Estado:** 🟡 Pendiente

### 7.1 Submit a App Store

| # | Tarea | Plataforma | Estado |
|---|-------|------------|--------|
| 6.1.1 | Crear app en App Store Connect | App Store Connect | 🔲 |
| 6.1.2 | Ingresar toda la metadata | App Store Connect | 🔲 |
| 6.1.3 | Subir build (desde Xcode Organizer) | Xcode | 🔲 |
| 6.1.4 | Seleccionar build en App Store Connect | App Store Connect | 🔲 |
| 6.1.5 | Responder cuestionario de privacidad (Privacy Nutrition Labels) | App Store Connect | 🔲 |
| 6.1.6 | Seleccionar categorías (Games/Trivia, Education) | App Store Connect | 🔲 |
| 6.1.7 | Ingresar URL de privacidad | App Store Connect | 🔲 |
| 6.1.8 | Submit for Review | App Store Connect | 🔲 |

### 7.2 Post-Launch

| # | Tarea | Frecuencia | Estado |
|---|-------|------------|--------|
| 6.2.1 | Monitorear Crashlytics | Diariamente | 🔲 |
| 6.2.2 | Responder reviews (especialmente 1-2 estrellas) | Diariamente | 🔲 |
| 6.2.3 | Monitorear uso de Firestore (costos) | Semanalmente | 🔲 |
| 6.2.4 | Planear update 1.1 con features solicitadas | Mensualmente | 🔲 |

---

## 8. Calendario de Ejecución

### Semana 1: Bloqueantes de Apple

| Día | Tareas | Horas |
|-----|--------|-------|
| Lunes | 1.1 Sign in with Apple (1.1.1 - 1.1.4) | 4h |
| Martes | 1.1 Sign in with Apple (1.1.5 - 1.1.8) | 4h |
| Miércoles | 1.2 Account Deletion (1.2.1 - 1.2.5) | 4h |
| Jueves | 1.2 Account Deletion (1.2.6 - 1.2.10) | 4h |
| Viernes | 1.3 ATT + 1.4 Privacy Policy (1.4.1 - 1.4.8) | 4h |

### Semana 2: Seguridad y Backend

| Día | Tareas | Horas |
|-----|--------|-------|
| Lunes | 2.1 Cloud Function para Gemini (2.1.1 - 2.1.4) | 4h |
| Martes | 2.1 Cloud Function deploy + 2.2 Keychain (2.2.1 - 2.2.3) | 4h |
| Miércoles | 2.2 Keychain (2.2.4 - 2.2.6) | 4h |
| Jueves | 2.3 App Check + 2.4 Firestore Rules | 4h |
| Viernes | Testing de seguridad + fixes | 4h |

### Semana 3: UX/UI y Accesibilidad

| Día | Tareas | Horas |
|-----|--------|-------|
| Lunes | 3.1 Onboarding + 3.2 Splash Screen | 4h |
| Martes | 3.3 Estados Offline + 3.4 Empty States | 4h |
| Miércoles | 3.5 Correcciones menores + 4.1 VoiceOver | 4h |
| Jueves | 4.2 Dynamic Type + 4.3 Reduce Motion | 4h |
| Viernes | Testing de accesibilidad + fixes | 4h |

### Semana 4: Testing y Submit

| Día | Tareas | Horas |
|-----|--------|-------|
| Lunes | 5.1 TestFlight setup + upload | 4h |
| Martes | 5.2 Testing de escenarios críticos | 4h |
| Miércoles | 5.3 Screenshots + metadata | 4h |
| Jueves | Fixes de testing + re-upload | 4h |
| Viernes | 6.1 Submit a App Store | 2h |

---

## 9. Checklist Final Pre-Submit

### Apple Guidelines

- [ ] Sign in with Apple implementado
- [ ] Account Deletion implementado
- [ ] App Tracking Transparency implementado
- [ ] Privacy Policy URL configurada
- [ ] Terms of Service URL configurada
- [ ] App no crashea en launch
- [ ] App funciona en modo avión (offline)
- [ ] App soporta Dynamic Type
- [ ] App soporta VoiceOver
- [ ] App respeta Reduce Motion
- [ ] No hay referencias a "beta", "test", "debug" en UI
- [ ] No hay placeholders ("lorem ipsum", "TODO", etc.)
- [ ] App funciona en iPhone SE (pantalla pequeña)
- [ ] App funciona en iPhone 15 Pro Max (pantalla grande)
- [ ] App funciona en iPad (si se declara soporte)

### Firebase

- [ ] Firestore rules están en modo producción
- [ ] App Check habilitado
- [ ] Cloud Functions deployadas
- [ ] API keys no expuestas en cliente
- [ ] Crashlytics configurado
- [ ] Analytics configurado (opcional)

### App Store Connect

- [ ] App creada en App Store Connect
- [ ] Bundle ID registrado
- [ ] Certificates y Provisioning Profiles creados
- [ ] Build subida y procesada
- [ ] Metadata completa (nombre, descripción, keywords)
- [ ] Screenshots para todos los tamaños requeridos
- [ ] Privacy Policy URL ingresada
- [ ] Cuestionario de privacidad respondido
- [ ] Categorías seleccionadas
- [ ] Precio configurado (gratuito o con IAP)

### Legal

- [ ] Privacy Policy publicada
- [ ] Terms of Service publicadas
- [ ] COPPA compliance (si aplica)
- [ ] GDPR compliance (si aplica)

---

## Notas y Referencias

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Sign in with Apple Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [Accessibility Guidelines](https://developer.apple.com/accessibility/)

---

**Última actualización:** 20 de junio de 2026  
**Próxima revisión:** Al completar Fase 1
