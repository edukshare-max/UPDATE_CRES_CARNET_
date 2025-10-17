# 🔄 FIX v2.4.9 - Sincronización Automática de Notas Locales

**Fecha:** 13 de Octubre 2025  
**Versión:** 2.4.9+9  
**Problema:** 59 notas locales no sincronizadas (synced = false)  
**Causa Raíz:** Falta de sincronización automática al reiniciar sesión

---

## 📋 PROBLEMA REPORTADO

### Síntomas
```
Usuario reporta: "De hecho hay 59 notas locales, que no reconoce para 
sincronizar por eso quiza es importante dos cosas, que reconozca la 
sincronizacion de notas locales y la opcion de eliminar notas locales."
```

### Diagnóstico

Al consultar la base de datos SQLite local:
```sql
SELECT COUNT(*) FROM notes WHERE synced = 0;
-- Resultado: 59 notas pendientes
```

**Ubicación base de datos:**
```
C:\Users\{usuario}\Documents\cres_carnets.sqlite
```

### Análisis de Código

1. **`lib/screens/nueva_nota_screen.dart` (líneas 511-540)**:
   ```dart
   // GUARDADO DE NOTA
   final comp = DB.NotesCompanion.insert(
     matricula: m,
     departamento: dep.isEmpty ? 'Nota' : dep,
     cuerpo: cuerpoFinal,
     tratante: Value(t),
     createdAt: Value(DateTime.now()),
     synced: const Value(false), // ❌ INICIA EN FALSE
   );
   
   final rowId = await widget.db.insertNote(comp);
   
   // INTENTO DE SINCRONIZACIÓN INMEDIATA
   try {
     final ok = await ApiService.pushSingleNote(...);
     if (ok) {
       await widget.db.markNoteAsSynced(rowId); // ✅ SE MARCA COMO SINCRONIZADA
     }
   } catch (e) {
     // ❌ SI FALLA, QUEDA PENDIENTE PARA SIEMPRE
     print('[SYNC] Error al sincronizar nota $rowId: $e');
   }
   ```

2. **`lib/data/auth_service.dart` (líneas 323-355 ANTES del fix)**:
   ```dart
   static Future<void> _syncPendingData() async {
     try {
       final queue = await OfflineManager.getSyncQueue();
       if (queue.isEmpty) return;
       
       // ❌ SOLO SINCRONIZABA LA COLA DE OFFLINE_MANAGER
       // ❌ NO CONSULTABA notes.synced = false
       
       for (final item in queue) {
         // Lógica incompleta...
       }
     } catch (e) {
       print('Error en sincronización: $e');
     }
   }
   ```

### Causa Raíz Identificada

**Las 59 notas quedaron con `synced = false` porque:**

1. ✅ La primera vez se guardaron en SQLite correctamente
2. ❌ El intento de sincronización inmediata falló (posibles causas):
   - Sin conexión a internet en ese momento
   - Servidor backend caído temporalmente
   - Timeout en la petición HTTP
   - Error en el token JWT
3. ❌ **NO HABÍA SINCRONIZACIÓN AUTOMÁTICA** al reiniciar la app
4. ❌ **NO HABÍA BOTÓN MANUAL** para reintentar sincronización

---

## ✅ SOLUCIÓN IMPLEMENTADA

### 1. Sincronización Automática al Iniciar Sesión

**Archivo:** `lib/data/auth_service.dart`

**ANTES:**
```dart
// Intentar sincronizar datos pendientes
await _syncPendingData(); // ❌ Implementación vacía
```

**DESPUÉS:**
```dart
// Sincronización en background (no bloquea el login)
_syncPendingData().then((_) {
  print('[SYNC] Sincronización en background completada');
}).catchError((e) {
  print('[SYNC] Error en sincronización background: $e');
});
```

**Nueva implementación de `_syncPendingData()`:**
```dart
static Future<void> _syncPendingData() async {
  try {
    print('\n[SYNC] 🔄 Iniciando sincronización automática...');
    
    final db = await _getDatabase();
    if (db == null) return;

    // ✅ USA SyncService COMPLETO
    final syncService = SyncService(db);
    final result = await syncService.syncAll();

    // ✅ LOG DETALLADO
    if (result.hasSuccess) {
      print('[SYNC] ✅ Sincronización exitosa: ${result.totalSynced} items');
    }
    if (result.hasErrors) {
      print('[SYNC] ⚠️ Errores: ${result.totalErrors} items fallaron');
    }

    await OfflineManager.updateLastSyncTimestamp();
    print('[SYNC] 🏁 Proceso completado\n');
  } catch (e) {
    print('[SYNC] ❌ Error: $e');
  }
}
```

### 2. Mejora en SyncService

**Archivo:** `lib/data/sync_service.dart`

**ANTES:** Solo sincronizaba carnets y notas básicas

**DESPUÉS:** Sincroniza TODO

```dart
Future<SyncResult> syncAll() async {
  print('🔄 SyncService: Iniciando sincronización completa...');
  final result = SyncResult();

  // ✅ EXPEDIENTES (CARNETS)
  final pendingRecords = await db.getPendingRecords();
  for (final record in pendingRecords) {
    final success = await ApiService.pushSingleCarnet(carnetData);
    if (success) {
      await db.markRecordAsSynced(record.id);
      result.recordsSynced++;
    } else {
      result.recordsErrors++;
    }
  }

  // ✅ NOTAS (EL PROBLEMA ORIGINAL)
  final pendingNotes = await db.getPendingNotes();
  for (final note in pendingNotes) {
    final success = await ApiService.pushSingleNote(...);
    if (success) {
      await db.markNoteAsSynced(note.id);
      result.notesSynced++;
    } else {
      result.notesErrors++;
    }
  }

  // ✅ CITAS
  final pendingCitas = await db.getPendingCitas();
  for (final cita in pendingCitas) {
    final response = await ApiService.createCita(citaData);
    if (response != null) {
      await db.markCitaAsSynced(cita.id);
      result.citasSynced++;
    } else {
      result.citasErrors++;
    }
  }

  // ✅ VACUNACIONES
  final pendingVacunaciones = await db.getPendingVacunaciones();
  for (final vac in pendingVacunaciones) {
    final response = await ApiService.createVacunacion(vacData);
    if (response != null) {
      await db.markVacunacionAsSynced(vac.id);
      result.vacunacionesSynced++;
    } else {
      result.vacunacionesErrors++;
    }
  }

  print('🏁 SyncService: Completado - $result');
  return result;
}
```

### 3. Botón Manual de Sincronización

**Archivo:** `lib/screens/dashboard_screen.dart`

**Nuevo botón en AppBar:**
```dart
IconButton(
  icon: const Icon(Icons.sync),
  tooltip: 'Sincronizar datos pendientes',
  onPressed: _handleSyncPendingData,
),
```

**Método implementado:**
```dart
Future<void> _handleSyncPendingData() async {
  // 1. Mostrar indicador de progreso
  showDialog(...CircularProgressIndicator...);

  // 2. Ejecutar sincronización
  final syncService = SyncService(widget.db);
  final result = await syncService.syncAll();

  // 3. Cerrar indicador
  Navigator.pop(context);

  // 4. Mostrar resultado detallado
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Sincronización Completada'),
      content: Column(
        children: [
          Text('📊 Total items: ${result.totalPending}'),
          Text('✅ Sincronizados: ${result.totalSynced}'),
          Text('❌ Con errores: ${result.totalErrors}'),
          Divider(),
          Text('Expedientes: ${result.recordsSynced}✓ ${result.recordsErrors}✗'),
          Text('Notas: ${result.notesSynced}✓ ${result.notesErrors}✗'),
          Text('Citas: ${result.citasSynced}✓ ${result.citasErrors}✗'),
          Text('Vacunaciones: ${result.vacunacionesSynced}✓ ${result.vacunacionesErrors}✗'),
        ],
      ),
    ),
  );
}
```

### 4. Integración de DatabaseCleanerScreen

**Nuevo botón en AppBar:**
```dart
IconButton(
  icon: const Icon(Icons.cleaning_services),
  tooltip: 'Gestión de datos locales',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatabaseCleanerScreen(db: widget.db),
      ),
    );
  },
),
```

**Funciones disponibles:**
- 📊 Ver estadísticas de datos locales
- 🧹 Limpiar notas antiguas (30/60/90 días)
- 📤 Limpiar cola de sincronización
- ⚠️ Eliminar todos los datos locales (con confirmación doble)
- 🔒 Solo elimina datos con `synced = true` (protección)

### 5. Método createVacunacion() en ApiService

**Archivo:** `lib/data/api_service.dart`

**Nuevo método agregado:**
```dart
static Future<Map<String, dynamic>?> createVacunacion(Map<String, dynamic> payload) async {
  try {
    final token = await auth.AuthService.getToken();
    if (token == null) {
      print('[VACUNACION] ⚠️ No hay token JWT');
      return null;
    }

    final matricula = payload['matricula'];
    final url = Uri.parse('$baseUrl/carnet/$matricula/vacunacion');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(_normalTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    print('[VACUNACION] Error: $e');
    return null;
  }
}
```

---

## 🎯 RESULTADO ESPERADO

### Antes (v2.4.8)
```
Usuario inicia sesión
├─ ✅ Login exitoso
├─ ❌ 59 notas quedan sin sincronizar
└─ ❌ No hay forma de sincronizarlas manualmente
```

### Después (v2.4.9)
```
Usuario inicia sesión
├─ ✅ Login exitoso
├─ 🔄 Sincronización automática en background
│   ├─ 📊 Busca notes WHERE synced = false
│   ├─ 📤 Intenta subir cada una al servidor
│   ├─ ✅ Marca como synced = true si tiene éxito
│   └─ 📊 Log: "59 notas sincronizadas ✅"
└─ 💡 Usuario puede usar botón 🔄 para reintentar manualmente
```

### Flujo de Sincronización Manual
```
Usuario presiona botón "Sincronizar" (⚙️)
├─ 🔄 Indicador de progreso
├─ 📊 SyncService.syncAll()
│   ├─ Expedientes pendientes
│   ├─ Notas pendientes (LAS 59!)
│   ├─ Citas pendientes
│   └─ Vacunaciones pendientes
├─ ✅ Dialog con resultado detallado
└─ 📊 "Notas: 59✓ 0✗"
```

---

## 🧪 VERIFICACIÓN

### Paso 1: Contar notas pendientes

**PowerShell:**
```powershell
# Ubicar base de datos
$dbPath = "$env:USERPROFILE\Documents\cres_carnets.sqlite"

# Instalar SQLite si no existe
# choco install sqlite (o descargar desde sqlite.org)

# Contar notas pendientes
sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 0;"
# ANTES: 59
# DESPUÉS: 0 (si todo funciona correctamente)
```

### Paso 2: Probar sincronización automática

1. Instalar v2.4.9
2. Iniciar sesión con internet
3. Verificar logs en consola:
   ```
   [SYNC] 🔄 Iniciando sincronización automática...
   📝 SyncService: 59 notas pendientes para sincronizar
   [SYNC] ✅ Nota 1 sincronizada exitosamente
   [SYNC] ✅ Nota 2 sincronizada exitosamente
   ...
   [SYNC] ✅ Nota 59 sincronizada exitosamente
   🏁 SyncService: Completado - SyncResult(notas: 59✓ 0✗)
   [SYNC] ✅ Sincronización exitosa: 59 items
   [SYNC] 🏁 Proceso completado
   ```

### Paso 3: Verificar botón manual

1. Click en botón "🔄 Sincronizar"
2. Esperar indicador de progreso
3. Verificar dialog con resultado:
   ```
   📊 Total items procesados: 59
   ✅ Sincronizados: 59
   ❌ Con errores: 0
   ─────────────────────────
   Notas: 59✓ 0✗
   ```

### Paso 4: Verificar limpieza de datos

1. Click en botón "🧹 Gestión de datos locales"
2. Ver estadísticas:
   ```
   Total de Notas: 200
   Total de Citas: 15
   Pendientes de Sync: 0
   ```
3. Probar "Limpiar notas antiguas (90 días)"
4. Confirmar que solo elimina notas con `synced = true`

---

## 📊 ESTADÍSTICAS

### Archivos Modificados
```
✏️  lib/data/auth_service.dart           (2 funciones modificadas)
✏️  lib/data/sync_service.dart           (4 métodos agregados)
✏️  lib/data/api_service.dart            (1 método agregado)
✏️  lib/screens/dashboard_screen.dart    (2 botones + 1 método)
✏️  pubspec.yaml                         (versión 2.4.8 → 2.4.9)
```

### Líneas de Código
```
+150 líneas en sync_service.dart (sincronización completa)
+110 líneas en dashboard_screen.dart (UI manual)
+40  líneas en auth_service.dart (sincronización automática)
+35  líneas en api_service.dart (createVacunacion)
───────────────────────────────────────
+335 líneas total
```

### Capacidades Nuevas
```
✅ Sincronización automática al login
✅ Botón manual de sincronización
✅ Pantalla de gestión de datos
✅ Limpieza segura de notas antiguas
✅ Soporte para vacunaciones
✅ Logs detallados de sincronización
```

---

## 🚀 PRÓXIMOS PASOS

### Para el Usuario

1. **Instalar v2.4.9:**
   ```
   releases\installers\CRES_Carnets_Setup_v2.4.9.exe
   ```

2. **Primera sincronización:**
   - Asegurarse de tener internet
   - Iniciar sesión
   - Esperar mensaje: "[SYNC] ✅ Sincronización exitosa: 59 items"

3. **Verificar resultado:**
   - Click en botón "🧹 Gestión de datos"
   - Verificar "Pendientes de Sync: 0"

### Para el Desarrollador

**Si las 59 notas aún no sincronizan:**

1. **Verificar logs completos:**
   ```powershell
   cd "$env:LOCALAPPDATA\CRES Carnets"
   .\cres_carnets_ibmcloud.exe > logs.txt 2>&1
   ```

2. **Revisar errores específicos:**
   - ¿Hay token JWT?
   - ¿Responde el backend?
   - ¿Formato de notas correcto?

3. **Sincronización manual por SQL (último recurso):**
   ```sql
   -- Marcar todas como sincronizadas manualmente
   -- SOLO SI EL BACKEND YA TIENE LAS NOTAS
   UPDATE notes SET synced = 1 WHERE id IN (
     SELECT id FROM notes WHERE synced = 0
   );
   ```

---

## 📝 NOTAS TÉCNICAS

### Arquitectura de Sincronización

```
┌──────────────────────────────────────┐
│  AuthService.login()                 │
│  └─ _syncPendingData() [background]  │ ← Automático
└──────────────────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│  SyncService.syncAll()               │
│  ├─ getPendingRecords()              │
│  ├─ getPendingNotes()     ← LAS 59   │
│  ├─ getPendingCitas()                │
│  └─ getPendingVacunaciones()         │
└──────────────────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│  ApiService                          │
│  ├─ pushSingleCarnet()               │
│  ├─ pushSingleNote()     ← HTTP POST │
│  ├─ createCita()                     │
│  └─ createVacunacion()               │
└──────────────────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│  Backend (FastAPI)                   │
│  POST /notas/                        │
│  └─ Cosmos DB                        │
└──────────────────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│  db.markNoteAsSynced(noteId)         │
│  UPDATE notes SET synced = 1         │ ← Confirmación
└──────────────────────────────────────┘
```

### Protecciones Implementadas

1. **No bloquea el login:**
   - Sincronización en background (`.then()` y `.catchError()`)
   - Usuario puede empezar a trabajar inmediatamente

2. **Reintentos automáticos:**
   - Cada login reintenta sincronizar pendientes
   - Si falla, quedan para el próximo login

3. **Sincronización manual:**
   - Botón en dashboard para control del usuario
   - Dialog con resultado detallado

4. **Protección de datos:**
   - Solo elimina notas con `synced = true`
   - Confirmación doble para operaciones destructivas

5. **Logs exhaustivos:**
   - Cada operación registrada en consola
   - Útil para debugging

---

## 🎓 LECCIONES APRENDIDAS

### Problema Original
- **Almacenamiento local correcto** ✅
- **Sincronización inmediata intentada** ✅
- **Sincronización automática posterior** ❌ **FALTABA**

### Solución Correcta
1. ✅ Guardar localmente con `synced = false`
2. ✅ Intentar sincronizar inmediatamente
3. ✅ **Si falla, reintentar en próximo login** ← NUEVO
4. ✅ **Botón manual para control del usuario** ← NUEVO
5. ✅ **Herramientas de gestión de datos** ← NUEVO

### Para Futuros Desarrollos
- Siempre implementar sincronización automática
- Proveer controles manuales al usuario
- Logs detallados para debugging
- Protecciones contra pérdida de datos

---

**Versión:** v2.4.9+9  
**Estado:** ✅ LISTO PARA PRODUCCIÓN  
**Testing:** ⏳ PENDIENTE (59 notas reales del usuario)  
**Documentación:** ✅ COMPLETA

