# GUÍA DETALLADA: Configurar Firebase para EduGuess

---

## Índice

1. [Crear proyecto Firebase](#1-crear-proyecto-firebase)
2. [Registrar la app iOS](#2-registrar-la-app-ios)
3. [Agregar GoogleService-Info.plist a Xcode](#3-agregar-googleservice-infoplist-a-xcode)
4. [Agregar Firebase SDK con Swift Package Manager](#4-agregar-firebase-sdk-con-swift-package-manager)
5. [Configurar Authentication (Email/Password)](#5-configurar-authentication)
6. [Configurar Firestore Database](#6-configurar-firestore-database)
7. [Reglas de seguridad de Firestore](#7-reglas-de-seguridad)
8. [Verificar que todo funciona](#8-verificar)
9. [Solución de problemas comunes](#9-solucion-de-problemas)

---

## 1. Crear proyecto Firebase

### Paso 1: Ir a Firebase Console

Abrir navegador y entrar a:
```
https://console.firebase.google.com
```

### Paso 2: Iniciar sesión

Usar una cuenta de Google (la misma que usas para el desarrollo).

### Paso 3: Crear proyecto

1. Click botón **"Crear un proyecto"** (azul, en el centro de la pantalla)

   > Si ya tienes proyectos, puede aparecer como **"Agregar proyecto"**

2. **Nombre del proyecto:** escribir `EduGuess`

   ![Paso 1: Nombre del proyecto]

3. Click **"Continuar"**

4. **Google Analytics:** Desactivar el toggle **"Habilitar Google Analytics"**

   > No lo necesitamos, solo usarás Authentication y Firestore

5. Click **"Crear proyecto"**

6. Esperar ~10-20 segundos mientras Firebase crea los recursos

7. Click **"Continuar"** cuando aparezca

✅ Proyecto creado. Estás en la consola principal de Firebase.

---

## 2. Registrar la app iOS

### Paso 1: Agregar app

Desde la pantalla principal del proyecto:

1. Click el icono **`+`** (Agregar app) / o click **"iOS"** si aparece directo

   > Si no ves los iconos, busca el texto "Agrega Firebase a tu aplicación" con iconos de Android, iOS, Web, Unity

2. Click el icono de **iOS** (con la manzana)

### Paso 2: Llenar datos de registro

```
iOS bundle ID:   com.tecsup.EduGuess
Nombre de la app: EduGuess
App Store ID:    (dejar vacío)
```

**IMPORTANTE:** El Bundle ID debe coincidir exactamente con el de Xcode.

Para verificarlo en Xcode:
- Abrir `EduGuess.xcodeproj`
- Click en el proyecto (raíz) → Target `EduGuess` → **General** → **Bundle Identifier**

Debe decir `com.tecsup.EduGuess`.

### Paso 3: Registrar

Click **"Registrar app"**

### Paso 4: Descargar GoogleService-Info.plist

Aparece una pantalla con instrucciones. En la sección **"Descargar el archivo de configuración de Firebase"**:

1. Click **"Descargar GoogleService-Info.plist"**

   > Se descargará un archivo llamado `GoogleService-Info.plist`

2. **No cierres esta pestaña** todavía (la necesitas para los siguientes pasos)

✅ Archivo descargado. Debes colocarlo en la ubicación: `~/Downloads/GoogleService-Info.plist`

---

## 3. Agregar GoogleService-Info.plist a Xcode

### Paso 1: Abrir Xcode

```bash
open /Users/dieegooml/Downloads/EduGuess/EduGuess.xcodeproj
```

### Paso 2: Ubicar el archivo descargado

Usar Finder para localizar `GoogleService-Info.plist` (normalmente en `~/Downloads/`)

### Paso 3: Arrastrar a Xcode

1. En Xcode, en el **Project Navigator** (panel izquierdo), seleccionar la carpeta `EduGuess` (la amarilla, la principal)

2. Arrastrar `GoogleService-Info.plist` desde Finder hacia la carpeta `EduGuess` en Xcode

3. Aparece un diálogo **"Choose options for adding these files"**:

   ```
   ✅ [x] Copy items if needed
   ✅ [x] Create groups
   ✅ [x] Add to targets: [x] EduGuess
   ```

4. Verificar que **"Add to targets: EduGuess"** esté marcado

5. Click **"Finish"**

### Paso 4: Verificar

El archivo debe aparecer en el Project Navigator dentro de la carpeta `EduGuess` junto a los `.swift` files.

✅ GoogleService-Info.plist agregado al proyecto.

---

## 4. Agregar Firebase SDK con Swift Package Manager

### Paso 1: Abrir el administrador de paquetes

En Xcode:

```
File → Add Package Dependencies...
```

> También disponible desde: File → Add Packages...
> O desde el ícono del proyecto → Package Dependencies → +

### Paso 2: Ingresar URL del repositorio

En el campo de búsqueda, pegar:

```
https://github.com/firebase/firebase-ios-sdk
```

### Paso 3: Configurar versión

Xcode busca el paquete automáticamente. Cuando aparezca:

1. **Dependency Rule:** seleccionar `Up to Next Major Version`
2. En el campo numérico: `11.0.0` (o la versión más reciente estable)

   > Puedes verificar la última versión en: https://github.com/firebase/firebase-ios-sdk/releases

### Paso 4: Seleccionar paquetes específicos

Xcode muestra una lista de todos los paquetes disponibles. **NO** marcar "Add All".

Seleccionar **solo** estos dos:

```
[x] FirebaseAuth
[x] FirebaseFirestore
```

> NO selecciones FirebaseAnalytics, FirebaseCrashlytics ni ningún otro

### Paso 5: Agregar

Click **"Add Package"** (esquina inferior derecha)

### Paso 6: Esperar descarga

Xcode descarga Firebase (~100-200 MB). Esto puede tomar **2-5 minutos** dependiendo del internet.

Verás una barra de progreso en la parte superior de Xcode.

### Paso 7: Agregar Google Sign-In SDK

1. Click **File → Add Package Dependencies...** (o el botón + en Package Dependencies)
2. Pegar:
   ```
   https://github.com/google/GoogleSignIn-iOS
   ```
3. Dependency Rule: `Up to Next Major Version` → `7.1.0`
4. Seleccionar producto: `[x] GoogleSignIn`
5. Click **"Add Package"**

### Paso 8: Agregar Facebook SDK

1. Click **File → Add Package Dependencies...**
2. Pegar:
   ```
   https://github.com/facebook/facebook-ios-sdk
   ```
3. Dependency Rule: `Up to Next Major Version` → `17.4.0`
4. Seleccionar productos:
   ```
   [x] FacebookLogin
   [x] FacebookCore
   ```
5. Click **"Add Package"**

### Paso 9: Verificar

Cuando termine:
1. En el Project Navigator, debe aparecer una sección **"Package Dependencies"**
2. Dentro debe estar:
   - `firebase-ios-sdk` con `FirebaseAuth` y `FirebaseFirestore`
   - `GoogleSignIn-iOS` con `GoogleSignIn`
   - `facebook-ios-sdk` con `FacebookLogin` y `FacebookCore`

### Paso 10: Resetear cache (si es necesario)

Si después de agregarlo todo compila con errores de módulos no encontrados:

```
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
Product → Clean Build Folder
```

✅ SDKs instalados.

---

## 5. Configurar Authentication

### Paso 1: Ir a Authentication en Firebase Console

En el navegador, en la consola de Firebase:

1. En el menú izquierdo, click **"Authentication"** (icono de persona)

   > Si no lo ves, click en **"Build"** para expandir

### Paso 2: Configurar método de inicio de sesión

1. Click la pestaña **"Sign-in method"** (arriba, segunda opción)

2. Click **"Email/Password"**

   > Aparece una fila con los proveedores disponibles

### Paso 3: Habilitar Email/Password

1. Activar el **toggle** (switch) a la posición ON

2. Click **"Save"** (botón azul arriba)

### Paso 4: Verificar

El proveedor `Email/Password` debe aparecer como **"Enabled"**

### Paso 5: Habilitar Google Sign-In

1. Click **"Add new provider"** o **"Add new sign-in method"** (dependiendo de la UI)
2. Seleccionar **"Google"**
3. Activar el toggle **"Enable"**
4. En **"Project public-facing name"** escribir `EduGuess`
5. En **"Support email for the project"** seleccionar tu email
6. Click **"Save"**

### Paso 6: Habilitar Facebook Sign-In

1. Click **"Add new provider"** → **"Facebook"**
2. Activar el toggle **"Enable"**
3. En **"App ID"** ingresar el ID de tu app de Facebook (desde https://developers.facebook.com)
4. En **"App Secret"** ingresar el App Secret de tu app de Facebook
5. Click **"Save"**

### Paso 7: Crear un usuario de prueba (opcional pero recomendado)

1. Click pestaña **"Users"**
2. Click **"Add user"**
3. Ingresar:
   ```
   Email:    prueba@eduguess.com
   Password: contraseña123
   ```
4. Click **"Add user"**

✅ Authentication configurado.

---

## 6. Configurar Firestore Database

### Paso 1: Ir a Firestore

En el menú izquierdo de Firebase Console:

1. Click **"Firestore Database"** (icono de hoja/database)

   > Si no lo ves, expandir **"Build"**

### Paso 2: Crear base de datos

Click el botón **"Crear base de datos"** (azul)

### Paso 3: Elegir modo de seguridad

Aparece un diálogo con dos opciones:

```
○ Modo de prueba
   → Recomendado para desarrollo
   → Cualquiera con tu clave de API puede leer y sobrescribir tus datos

○ Modo bloqueado
   → Rechaza todas las lecturas y escrituras
```

Seleccionar **"Comenzar en modo de prueba"**

> Esto permite que la app funcione sin autenticación. Más adelante puedes cambiarlo a producción.

### Paso 4: Elegir ubicación

```
○ nam5 (United States)     ← recomendado
○ (seleccionar la más cercana geográficamente)
```

Seleccionar **`nam5`** (US Central) o la más cercana a Perú (`southamerica-east1` si aparece).

### Paso 5: Confirmar creación

Click **"Crear"**

### Paso 6: Esperar aprovisionamiento

Firebase tarda ~10-20 segundos en crear la base de datos. Verás un indicador de carga.

Cuando termine, aparecerá la consola de Firestore vacía:

```
(empty)  ← aún sin colecciones ni documentos
  ↓
[Start collection]  ← botón azul
```

✅ Firestore creado y listo.

---

## 7. Reglas de seguridad

Para desarrollo, el modo de prueba es suficiente. Pero para producción, reemplázalas:

### Paso 1: Ir a Rules

En Firebase Console → **Firestore Database** → pestaña **"Rules"** (arriba)

### Paso 2: Reemplazar contenido

Borrar todo el contenido y pegar:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuarios: solo lectura/escritura del propio usuario
    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    // Sesiones de juego
    match /game_sessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }

    // Leaderboard (reservado)
    match /leaderboard/{entryId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### Paso 3: Publicar

Click **"Publicar"** (botón azul arriba)

✅ Reglas actualizadas.

---

## 8. Verificar que todo funciona

### Paso 1: Compilar en Xcode

```bash
# Limpiar build anterior (opcional)
Cmd + Shift + K

# Compilar y ejecutar
Cmd + R
```

### Paso 2: Login

Deberías ver la pantalla de inicio de sesión (fondo naranja/rojo con `EduGuess` arriba).

1. Click **"¿No tienes cuenta? Regístrate"**

2. Ingresar:
   ```
   Nombre:     Diego
   Email:      diego@test.com
   Contraseña: test123456
   ```

3. Click **"Registrarse"**

### Paso 3: Jugar una partida

1. Click **"Comenzar"**

2. Jugar respondiendo preguntas

3. Al final, verás los puntos ganados

### Paso 4: Verificar datos en Firebase Console

Volver al navegador, en Firebase Console:

1. **Authentication → Users**
   → Debe aparecer tu usuario (`diego@test.com`)

2. **Firestore → Data**
   → Debe haber 2 colecciones:
   ```
   users/
     └── {uid}/
           ├── name: "Diego"
           ├── email: "diego@test.com"
           └── stats: { totalGames: 1, wins: 1, ... }

   game_sessions/
     └── {auto-id}/
           ├── characterName: "Goku"
           ├── won: true
           ├── score: 150
           └── timestamp: ...
   ```

### Paso 5: Perfil y Ranking

1. En la app, click **"Mi Perfil"**
   → Debe mostrar estadísticas (partidas, victorias, puntaje total)

2. Click **"Ranking"**
   → Debe mostrar tu posición

✅ Todo configurado y funcionando.

---

## 9. Solución de problemas

### Error: "The GoogleService-Info.plist file cannot be found"

**Causa:** El archivo no se agregó correctamente a Xcode.

**Solución:**
1. Cerrar Xcode
2. Arrastrar `GoogleService-Info.plist` a la carpeta `EduGuess/` en Finder
3. Reabrir Xcode
4. En el Project Navigator, click derecho en el archivo → **"Add Files to 'EduGuess'..."**
5. Seleccionar `GoogleService-Info.plist`
6. Marcar: `[x] Copy items if needed` y `[x] EduGuess`

### Error: "Module 'FirebaseAuth' not found"

**Causa:** SPM no se descargó o hubo un error de resolución.

**Solución:**
```
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
Product → Clean Build Folder
```

Si sigue fallando:
1. En Project Navigator → **Package Dependencies** → eliminar `firebase-ios-sdk`
2. File → Add Package Dependencies → volver a agregar

### Error: "Network error" al iniciar sesión

**Causa:** Firestore en modo bloqueado o reglas restrictivas.

**Solución:**
1. Ir a Firebase Console → **Firestore → Rules**
2. Asegurar que las reglas permitan:
   ```
   allow read, write: if request.auth != null;
   ```
   O temporalmente poner modo prueba:
   ```
   allow read, write: if true;
   ```

### Error: "Missing or insufficient permissions"

**Causa:** Las reglas de Firestore no coinciden con la estructura de datos.

**Solución:** Verificar que el campo `userId` existe en el documento `game_sessions` y que coincide con `request.auth.uid`.

### Error de compilación: "No such module 'FirebaseCore'"

**Causa:** La importación en `EduGuessApp.swift` busca el módulo pero no está disponible.

**Solución:** Verificar que agregaste `FirebaseAuth` y `FirebaseFirestore` (no hace falta agregar `FirebaseCore` directamente, viene incluido como dependencia).

### No aparecen datos en Firestore

**Causa:** El usuario no está autenticado o las reglas bloquean la escritura.

**Solución:**
1. Verificar Firebase Console → **Authentication → Users** → el usuario existe
2. Hacer logout en la app y volver a login
3. Jugar otra partida
4. Verificar Firestore → **Data** → refrescar la página

### Error: "FIRESTORE INTERNAL ASSERTION FAILED"

**Causa:** Incompatibilidad de versiones de Firebase SDK.

**Solución:**
1. File → Packages → Update to Latest Package Versions
2. Clean Build Folder (Cmd+Shift+K)
3. Recompilar

### Error: Google Sign-In crash "The operation couldn't be completed"

**Causa:** Falta el URL scheme de Google en Info.plist.

**Solución:**
1. Abrir `Info.plist`
2. Verificar que existe `CFBundleURLTypes` con un scheme como:
   ```
   com.googleusercontent.apps.TU_GOOGLE_CLIENT_ID
   ```
3. El CLIENT_ID debe coincidir con el de `GoogleService-Info.plist`
4. Clean Build Folder y recompilar

### Error: "Sign in with Facebook is not supported via generic IDP"

**Causa:** Se usó `OAuthProvider(providerID: .facebook)` en vez del SDK nativo de Facebook.

**Solución:**
1. NO usar `OAuthProvider` para Facebook (Firebase lo bloquea por TOS)
2. Usar el SDK nativo: `LoginManager` de `facebook-ios-sdk`
3. El código correcto ya está en `FirebaseAuthService.signInWithFacebook()`
4. Verificar que `facebook-ios-sdk` está agregado como dependencia SPM

### Error: "Missing package product 'FacebookLogin'"

**Causa:** Los paquetes SPM no se resolvieron correctamente.

**Solución:**
```bash
# Desde terminal
xcodebuild -resolvePackageDependencies -project EduGuess.xcodeproj
```
O desde Xcode: File → Packages → Resolve Package Versions

### Error: Facebook Login no abre ni muestra error

**Causa:** El SDK de Facebook no se inicializó en AppDelegate.

**Solución:**
1. Verificar que `AppDelegate.swift` llama a:
   ```swift
   ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
   ```
2. Verificar que `Info.plist` tiene `FacebookAppID` y `FacebookClientToken`
3. Verificar que `CFBundleURLSchemes` incluye `fb{APP-ID}` (ej: `fbTU_FACEBOOK_APP_ID`)

---

## 10. Configurar App de Facebook

Además de Firebase, necesitas una app de Facebook para el login.

### Paso 1: Ir a Meta Developer Portal

```
https://developers.facebook.com
```

### Paso 2: Crear o seleccionar app

1. Click **"My Apps"** → **"Create App"**
2. Seleccionar **"Consumer"** como tipo de app
3. Nombre: `EduGuess`
4. Email de contacto: tu email
5. Click **"Create App ID"**

### Paso 3: Configurar iOS

1. En el dashboard de la app, buscar **"Add Products"** → **"Facebook Login"** → **"Set Up"**
2. En la sección **"Settings"**, agregar:
   ```
   Bundle ID: com.tecsup.EduGuess
   ```
3. Click **"Save"**

### Paso 4: Obtener App ID y Client Token

1. En el dashboard, ve a **"Settings"** → **"Basic"**
2. Anota el **"App ID"** (ej: `TU_FACEBOOK_APP_ID`)
3. Ve a **"Settings"** → **"Advanced"** → **"Security"**
4. Copia el **"Client Token"** (es un string de ~32 caracteres hexadecimales)

### Paso 5: Configurar Info.plist

El proyecto ya tiene `Info.plist` con estas claves. Si necesitas cambiarlas:

| Key | Value |
|-----|-------|
| `FacebookAppID` | `TU_FACEBOOK_APP_ID` |
| `FacebookClientToken` | `{tu-client-token}` |
| `FacebookDisplayName` | `EduGuess` |
| `CFBundleURLTypes` → item 2 → `CFBundleURLSchemes` | `fbTU_FACEBOOK_APP_ID` |

### Paso 6: Configurar URL Scheme en AppDelegate

El proyecto ya tiene `AppDelegate.swift` manejando las URLs de Facebook y Google:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    let handledByFB = ApplicationDelegate.shared.application(app, open: url, options: options)
    let handledByGoogle = GIDSignIn.sharedInstance.handle(url)
    return handledByFB || handledByGoogle
}
```

---

## Resumen rápido (checklist)

- [ ] Crear proyecto Firebase (console.firebase.google.com)
- [ ] Registrar app iOS con bundle ID `com.tecsup.EduGuess`
- [ ] Descargar `GoogleService-Info.plist` y agregar a Xcode
- [ ] Agregar Firebase SDK via SPM (FirebaseAuth + FirebaseFirestore)
- [ ] Agregar GoogleSignIn-iOS via SPM
- [ ] Agregar facebook-ios-sdk via SPM (FacebookLogin + FacebookCore)
- [ ] Habilitar Authentication → Email/Password
- [ ] Habilitar Authentication → Google Sign-In
- [ ] Habilitar Authentication → Facebook Sign-In
- [ ] Crear Firestore Database en modo prueba
- [ ] Crear app de Facebook (developers.facebook.com)
- [ ] Configurar FacebookAppID, FacebookClientToken y URL scheme en Info.plist
- [ ] Compilar y probar (Cmd+R)
- [ ] Verificar datos en Firebase Console

---

## Arquitectura final

```
                    ┌──────────────────────────┐
                    │      EduGuess App        │
                    │  (SwiftUI + SwiftData)    │
                    └──────┬─────────┬─────────┘
                           │         │
              ┌────────────┼─────────┼──────────────┐
              │            │         │              │
              ▼            ▼         ▼              ▼
     ┌────────────┐ ┌──────────┐ ┌──────┐ ┌──────────────┐
     │Firebase Auth│ │ Firestore│ │GIDSI-│ │ Facebook SDK │
     │email/Google │ │ (online) │ │gnIn  │ │ LoginManager │
     │   /Facebook │ │          │ │      │ │              │
     └────────────┘ └──────────┘ └──────┘ └──────────────┘
                           │
                           ▼
                 ┌──────────────────────┐
                 │     Firestore DB      │
                 │  - users/{uid}        │
                 │  - game_sessions/{id} │
                 │  - leaderboard (vista)│
                 └──────────────────────┘

Flujo Auth:
  Email:      FirebaseAuth.signIn(withEmail:password:)
  Google:     GIDSignIn.signIn() → GoogleAuthProvider → FirebaseAuth
  Facebook:   LoginManager.logIn() → FacebookAuthProvider → FirebaseAuth
```
