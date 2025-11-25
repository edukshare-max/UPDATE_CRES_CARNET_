# Fix Crítico: Login Offline v2.4.5 - Análisis del Problema Real

**Fecha:** 13 de octubre de 2025  
**Versión:** 2.4.5 (Build 5)  
**Tipo:** Fix Crítico + Diagnóstico  

---

## 🐛 Problema Root Cause Identificado

### Síntoma Reportado
> "aun sin poder iniciar sesion sin internet a pesar de haber conectado la primera vez con internet."

### Root Cause #1: Inconsistencia en el Valor del Campus

**Problema:**
El código guardaba el cache con un valor de campus, pero validaba con otro diferente.

**Flujo Problemático (v2.4.4):**
```
1. Usuario selecciona campus en UI: "cres-llano-largo"
2. Login online exitoso
3. Backend devuelve user.campus: "llano-largo" (SIN prefijo "cres-")
4. Se guarda cache con: campus ?? data['user']['campus']
   - Si campus es null → guarda "llano-largo"
   - Si campus no es null → guarda "cres-llano-largo"
5. Usuario intenta login offline
6. Busca cache con: "cres-llano-largo"
7. Cache tiene: "llano-largo"
8. ❌ NO COINCIDEN → Login fallido
```

**Evidencia en Código:**
```dart
// auth_service.dart línea 127 (v2.4.4)
await OfflineManager.savePasswordHash(
  username: username,
  password: password,
  campus: campus ?? data['user']['campus'],  // ❌ PROBLEMA AQUÍ
);
```

### Root Cause #2: Sin Fallback Inteligente

Si el campus no coincidía exactamente, el login fallaba inmediatamente sin intentar buscar con el campus guardado.

---

## ✅ Soluciones Implementadas (v2.4.5)

### Fix #1: Normalización de Campus

**Antes (v2.4.4):**
```dart
final hasCache = await OfflineManager.hasCachedCredentials(username, campus ?? '');
```

**Después (v2.4.5):**
```dart
// Normalizar campus (asegurar que no sea null o vacío)
final normalizedCampus = campus ?? 'cres-llano-largo';
final hasCache = await OfflineManager.hasCachedCredentials(username, normalizedCampus);
```

### Fix #2: Usar Campus del Backend Consistentemente

**Antes (v2.4.4):**
```dart
campus: campus ?? data['user']['campus'],  // Inconsistente
```

**Después (v2.4.5):**
```dart
// Usar SIEMPRE el campus del backend para consistencia
final campusToCache = data['user']['campus'] ?? normalizedCampus;
print('💾 Guardando cache con campus: $campusToCache');

await OfflineManager.savePasswordHash(
  username: username,
  password: password,
  campus: campusToCache,  // ✅ Consistente
);
```

### Fix #3: Fallback Inteligente con Búsqueda de Campus

**Nueva Funcionalidad:**
```dart
// Intentar con campus proporcionado
bool isValid = await OfflineManager.validateOfflineCredentials(...);

// Si falla, buscar campus en cache y reintentar
if (!isValid) {
  final cachedCampus = await OfflineManager.getCachedCampusForUser(username);
  if (cachedCampus != null && cachedCampus != normalizedCampus) {
    print('🔄 Reintentando con campus del cache: $cachedCampus');
    isValid = await OfflineManager.validateOfflineCredentials(
      campus: cachedCampus,  // ✅ Usa el campus real del cache
    );
  }
}
```

**Nueva Función Helper:**
```dart
/// Obtiene el campus guardado en cache para un usuario
static Future<String?> getCachedCampusForUser(String username) async {
  final cacheJson = await _storage.read(key: _keyPasswordHash);
  if (cacheJson == null) return null;
  
  final cacheData = jsonDecode(cacheJson);
  if (cacheData['username'] == username) {
    return cacheData['campus'] as String?;
  }
  return null;
}
```

### Fix #4: Logs Detallados para Diagnóstico

**Agregados en toda la cadena:**
```dart
print('🔐 Iniciando login para: $username, campus: $normalizedCampus');
print('💾 Cache disponible: $hasCache');
print('🌐 Conexión detectada: $hasConnection');
print('💾 Guardando cache con campus: $campusToCache (backend: ${data['user']['campus']}, enviado: $normalizedCampus)');
print('💾 [CACHE] Guardando hash para usuario: $username, campus: $campus');
print('✅ [CACHE] Hash guardado exitosamente');
print('🔍 [CACHE] Validando credenciales offline para: $username, campus: $campus');
print('📦 [CACHE] Cache encontrado - Usuario: ${cacheData['username']}, Campus: ${cacheData['campus']}');
print('❌ [CACHE] Campus no coincide: "${cacheData['campus']}" vs "$campus"');
print('✅ [CACHE] Hash válido - credenciales correctas');
```

---

## 📊 Flujo Corregido (v2.4.5)

### Primer Login (CON Internet)
```
1. Usuario selecciona campus: "cres-llano-largo" (o cualquier otro)
2. Login online → Backend responde
3. Backend devuelve: user.campus = "llano-largo"
4. ✅ Se guarda cache con campus del BACKEND: "llano-largo"
5. Log: "💾 Guardando cache con campus: llano-largo"
6. ✅ Cache guardado correctamente
```

### Segundo Login (SIN Internet)
```
1. Usuario ingresa credenciales
2. Selecciona campus: "cres-llano-largo" (de la UI)
3. Normalización: normalizedCampus = "cres-llano-largo"
4. hasCache = buscar con "cres-llano-largo"
5. ❌ Cache tiene "llano-largo" → NO coincide
6. ✅ NUEVO: Fallback inteligente activado
7. getCachedCampusForUser(username) → "llano-largo"
8. Reintenta validación con "llano-largo"
9. ✅ Cache coincide → Login exitoso
10. Log: "🔄 Reintentando con campus del cache: llano-largo"
```

---

## 🧪 Casos de Prueba

### Caso 1: Campus Coincide Exactamente ✅
```
Login 1: campus = "cres-llano-largo", backend devuelve "cres-llano-largo"
Cache: "cres-llano-largo"
Login 2: campus = "cres-llano-largo"
Resultado: ✅ Login exitoso inmediato
```

### Caso 2: Campus Diferente (Problema Original) ✅
```
Login 1: campus = null, backend devuelve "llano-largo"
Cache: "llano-largo"
Login 2: campus = "cres-llano-largo" (del dropdown)
Resultado: ✅ Login exitoso con fallback (ANTES fallaba ❌)
```

### Caso 3: Backend Devuelve Campus Diferente ✅
```
Login 1: campus = "cres-llano-largo", backend devuelve "llano-largo"
Cache: "llano-largo" (usa backend)
Login 2: campus = "cres-llano-largo"
Resultado: ✅ Login exitoso con fallback
```

---

## 🔍 Cómo Diagnosticar con v2.4.5

### Logs del Primer Login (CON Internet)
```
🔐 Iniciando login para: usuario, campus: cres-llano-largo
💾 Cache disponible: false
🌐 Conexión detectada: true
🌍 Intentando login online...
✅ Login online exitoso
💾 Guardando cache con campus: llano-largo (backend: llano-largo, enviado: cres-llano-largo)
💾 [CACHE] Guardando hash para usuario: usuario, campus: llano-largo
✅ [CACHE] Hash guardado exitosamente
```

**Importante:** Anota el campus que se guardó (en este caso: "llano-largo")

### Logs del Segundo Login (SIN Internet)
```
🔐 Iniciando login para: usuario, campus: cres-llano-largo
🔎 [CACHE] Verificando si existe cache para: usuario, campus: cres-llano-largo
📦 [CACHE] Cache existe - Usuario: usuario, Campus: llano-largo
❌ [CACHE] Cache NO coincide
💾 Cache disponible: false
🌐 Conexión detectada: false
📴 Sin conexión - usando modo offline
🔄 Intentando login offline...
🔍 [CACHE] Validando credenciales offline para: usuario, campus: cres-llano-largo
📦 [CACHE] Cache encontrado - Usuario: usuario, Campus: llano-largo
❌ [CACHE] Campus no coincide: "llano-largo" vs "cres-llano-largo"
⚠️ [CACHE] Validación falló con campus: cres-llano-largo
🔄 [CACHE] Intentando obtener campus del cache guardado...
📦 [CACHE] Encontrado campus en cache: llano-largo, reintentando...
🔍 [CACHE] Validando credenciales offline para: usuario, campus: llano-largo
📦 [CACHE] Cache encontrado - Usuario: usuario, Campus: llano-largo
⏰ [CACHE] Cache válido (0 días desde último login)
✅ [CACHE] Hash válido - credenciales correctas
✅ Login offline exitoso para: usuario
```

---

## 📦 Archivos Modificados

### lib/data/auth_service.dart
- Normalización de campus (línea ~80)
- Uso consistente del campus del backend (línea ~127)
- Fallback inteligente en _tryOfflineLogin (línea ~186)
- Logs detallados

### lib/data/offline_manager.dart
- Nueva función: getCachedCampusForUser() (línea ~202)
- Logs detallados en savePasswordHash()
- Logs detallados en validateOfflineCredentials()
- Logs detallados en hasCachedCredentials()

### pubspec.yaml
- Versión: 2.4.4+4 → 2.4.5+5

---

## 🚀 Instrucciones de Prueba

### Paso 1: Desinstalar Versión Anterior
```
Control Panel → Uninstall CRES Carnets
```
Esto limpia el cache anterior que podría estar causando problemas.

### Paso 2: Instalar v2.4.5
```
CRES_Carnets_Setup_v2.4.5.exe
```

### Paso 3: Primer Login CON Internet
1. Conectar a WiFi/Internet
2. Abrir app
3. Ingresar credenciales
4. Seleccionar campus (cualquiera)
5. Login exitoso
6. **Revisar logs** (si están habilitados) para ver el campus guardado

### Paso 4: Segundo Login SIN Internet
1. **Cerrar app completamente**
2. Desconectar WiFi/Internet
3. Abrir app
4. Ingresar LAS MISMAS credenciales
5. Seleccionar EL MISMO campus (o cualquier otro, debería funcionar igual)
6. **Debería entrar exitosamente**
7. Revisar logs para ver el fallback en acción

---

## ✅ Resultados Esperados

- ✅ Login offline funciona después del primer login con internet
- ✅ Funciona incluso si el campus seleccionado es diferente
- ✅ Logs detallados muestran exactamente qué está pasando
- ✅ Fallback automático si el campus no coincide
- ✅ Mensaje claro si no hay cache (primera vez sin internet)

---

## 📄 Documentación Relacionada

- `DIAGNOSTIC_v2.4.5.md` - Guía de diagnóstico para el usuario
- `FIX_LOGIN_OFFLINE_v2.4.4.md` - Análisis técnico de v2.4.4
- `RELEASE_NOTES_v2.4.4.md` - Notas de versión anteriores

---

**Versión:** 2.4.5  
**Build:** 5  
**Fecha:** 13 de octubre de 2025  
**Compilado con:** Flutter 3.3.0+, Dart 3.3.0+
