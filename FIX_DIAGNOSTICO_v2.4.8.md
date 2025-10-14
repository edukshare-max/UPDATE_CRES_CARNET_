# 🔬 v2.4.8 - DIAGNÓSTICO EXHAUSTIVO + FIX FLUSH

## 🎯 Objetivo

Esta versión agrega **diagnóstico exhaustivo** y **delay de flush** para resolver el problema persistente donde los datos de usuario no están disponibles para login offline.

## 🔍 Problema Analizado

**Síntoma reportado por usuario:**
> "Aun sin exito para iniciar en la segunda ocasion sin internet"

**Hipótesis del problema:**
1. Los datos SÍ se guardan durante el login exitoso
2. Pero NO están disponibles cuando se intenta login offline
3. Posibles causas:
   - FlutterSecureStorage no completa el flush a disco antes de cerrar la app
   - Datos se escriben pero se corrompen
   - Problema de permisos de escritura en Windows
   - Datos se borran por algún otro proceso

## ✅ Soluciones Implementadas

### 1. Verificación Inmediata Después de Guardar

**Ubicación:** `lib/data/auth_service.dart` líneas 135-159

```dart
// Guardar datos
await _storage.write(key: _tokenKey, value: data['access_token']);
await _storage.write(key: _userKey, value: jsonEncode(data['user']));

// ✅ NUEVO: Verificar INMEDIATAMENTE que se guardaron
final verifyToken = await _storage.read(key: _tokenKey);
final verifyUser = await _storage.read(key: _userKey);

if (verifyToken != null) {
  print('✅ Token verificado');
} else {
  print('❌ ERROR CRÍTICO: Token NO se guardó');
}

if (verifyUser != null) {
  print('✅ Datos de usuario verificados');
} else {
  print('❌ ERROR CRÍTICO: Datos de usuario NO se guardaron');
}
```

**Beneficio:** Detecta inmediatamente si hay problema de escritura.

### 2. Delay para Flush a Disco

**Ubicación:** `lib/data/auth_service.dart` líneas 170-174

```dart
// ✅ NUEVO: Esperar 500ms para que FlutterSecureStorage
// complete el flush de datos al disco (problema conocido en Windows)
print('⏳ Esperando flush de datos al disco...');
await Future.delayed(const Duration(milliseconds: 500));
print('✅ Flush completado');
```

**Razón:** FlutterSecureStorage en Windows puede necesitar tiempo para completar la escritura al registro/disco. Si la app se cierra inmediatamente después de `write()`, los datos pueden perderse.

### 3. Diagnóstico Detallado en Login Offline

**Ubicación:** `lib/data/auth_service.dart` líneas 236-247

```dart
// ✅ NUEVO: Diagnóstico completo al intentar offline
print('🔍 DIAGNÓSTICO: Verificando contenido de FlutterSecureStorage...');
final tokenInStorage = await _storage.read(key: _tokenKey);
final userInStorage = await _storage.read(key: _userKey);

print('   🔑 Token: ${tokenInStorage != null ? "SÍ existe" : "NO existe"}');
print('   👤 User: ${userInStorage != null ? "SÍ existe" : "NO existe"}');
```

**Beneficio:** Permite ver EXACTAMENTE qué hay en el storage cuando se intenta login offline.

### 4. Logs Detallados de Datos

```dart
print('💾 Guardando datos de usuario...');
final userDataJson = jsonEncode(data['user']);
print('📦 Datos a guardar: ${userDataJson.substring(0, 100)}...');
```

**Beneficio:** Permite verificar que los datos del backend son correctos antes de guardar.

## 📋 Cómo Interpretar los Logs

### Login Exitoso con Internet:
```
✅ Login online exitoso
💾 Guardando token...
💾 Guardando datos de usuario...
📦 Datos a guardar: {"id":123,"username":"juan",...}
🔍 Verificando datos guardados...
✅ Token verificado: eyJhbGciOiJIUzI1NiIs...
✅ Datos de usuario verificados: {"id":123,"username":"juan"...
💾 Guardando cache con campus: llano-largo
⏳ Esperando flush de datos al disco...
✅ Flush completado
```

### Login Offline Exitoso:
```
🔄 Intentando login offline...
🔍 DIAGNÓSTICO: Verificando contenido de FlutterSecureStorage...
   🔑 Token: SÍ existe (offline_1728835200000...)
   👤 User: SÍ existe ({"id":123,"username":"juan"...)
✅ Datos de usuario encontrados en cache
✅ Login offline exitoso
```

### Login Offline FALLIDO (si el problema persiste):
```
🔄 Intentando login offline...
🔍 DIAGNÓSTICO: Verificando contenido de FlutterSecureStorage...
   🔑 Token: NO existe  ← PROBLEMA
   👤 User: NO existe   ← PROBLEMA
❌ No hay datos de usuario guardados
```

## 🧪 Instrucciones de Prueba

1. **Desinstalar versión anterior completamente**
   ```
   - Configuración → Apps → CRES Carnets → Desinstalar
   - Eliminar carpeta: %LOCALAPPDATA%\CRES Carnets
   ```

2. **Instalar v2.4.8**
   ```
   - Ejecutar: CRES_Carnets_Setup_v2.4.8.exe
   ```

3. **PRUEBA CRÍTICA CON CAPTURA DE LOGS:**
   ```powershell
   # Ejecutar app desde PowerShell para ver logs
   cd "$env:LOCALAPPDATA\CRES Carnets"
   .\cres_carnets_ibmcloud.exe
   
   # Observar los logs mientras:
   a) Conectar internet
   b) Hacer login
   c) BUSCAR EN LOGS: "✅ Datos de usuario verificados"
   d) Cerrar app completamente
   e) Desconectar internet
   f) Volver a ejecutar app
   g) Intentar login
   h) BUSCAR EN LOGS: "👤 User: SÍ existe" o "NO existe"
   ```

4. **Reportar resultados:**
   - Si dice "✅ Datos de usuario verificados" pero luego dice "NO existe" → Problema de persistencia de FlutterSecureStorage
   - Si dice "❌ ERROR CRÍTICO: Datos de usuario NO se guardaron" → Problema de permisos o FlutterSecureStorage
   - Si ambos dicen SÍ → El problema está en otro lado

## 🔬 Posibles Resultados y Siguientes Pasos

### Caso A: Verificación exitosa pero offline falla
**Logs:**
```
✅ Datos de usuario verificados  (login online)
...
👤 User: NO existe  (login offline)
```
**Significa:** FlutterSecureStorage no persiste datos entre sesiones en Windows  
**Solución:** Usar SharedPreferences o Drift como storage alternativo

### Caso B: Verificación falla inmediatamente
**Logs:**
```
❌ ERROR CRÍTICO: Datos de usuario NO se guardaron
```
**Significa:** Problema de permisos o FlutterSecureStorage corrupto  
**Solución:** Reinstalar app con permisos elevados o cambiar storage

### Caso C: Todo funciona con el delay
**Logs:**
```
✅ Datos de usuario verificados
...
👤 User: SÍ existe
✅ Login offline exitoso
```
**Significa:** El delay de 500ms resolvió el problema  
**Solución:** ÉXITO - esta versión funciona

## 📦 Archivos Modificados

1. **`lib/data/auth_service.dart`**
   - Líneas 135-159: Verificación inmediata post-guardado
   - Líneas 170-174: Delay de flush (500ms)
   - Líneas 236-250: Diagnóstico detallado en offline

2. **`pubspec.yaml`**
   - Versión: `2.4.7+7` → `2.4.8+8`

## 📊 Información del Instalador

**Archivo:** `CRES_Carnets_Setup_v2.4.8.exe`  
**Ubicación:** `releases\installers\`  
**Tamaño:** 13.19 MB  
**Fecha:** 13/10/2025 14:56  

---

**Estado:** 🔬 DIAGNÓSTICO + POSIBLE FIX  
**Compilado:** 13/10/2025 14:56  
**Prioridad:** CRÍTICA  
**Requiere:** Captura de logs del usuario para diagnóstico definitivo
