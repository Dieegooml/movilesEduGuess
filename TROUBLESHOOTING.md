// TROUBLESHOOTING & ERROR FIXES DOCUMENT
// EduGuess Project - Error Analysis & Solutions
// Updated: June 12, 2026

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
