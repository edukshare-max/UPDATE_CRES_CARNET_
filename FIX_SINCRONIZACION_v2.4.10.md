# Fix Sincronización 59 Notas - v2.4.10

**Fecha:** 13 de octubre de 2025  
**Problema:** Las 59 notas locales NO se están sincronizando al servidor  
**Versiones:** v2.4.10 (fix) vs v2.4.9 (con problema)

---

## 🔍 Diagnóstico del Problema

### Usuario reporta:
> "Veo que agregaste funciones de limpieza dice que si las borra pero cuando entro e ver un carnet tiene notas locales que no se borran"

### Análisis:
1. **Limpiador funciona correctamente** - solo elimina notas con `synced=true`
2. **Las 59 notas tienen `synced=false`** - nunca han sido sincronizadas
3. **El limpiador las protege** - diseñado para no borrar datos pendientes

### Usuario aclara:
> "El problema es que tengo 59 notas y no las sincroniza, solo sube las notas actuales pero las pasadas no las sube a la nube"

**PROBLEMA REAL:** La sincronización automática y manual NO está subiendo las notas antiguas.

---

## 🐛 Problemas Identificados en v2.4.9

### 1. **Falta de Timeout en `pushSingleNote()`**
```dart
// ❌ ANTES (v2.4.9):
final resp = await http.post(url, headers: {...}, body: {...});
// Si el servidor tarda más de 60s, la app se congela o falla silenciosamente
```

### 2. **Logs Insuficientes**
```dart
// ❌ ANTES (v2.4.9):
print('POST $url');
print('Status: ${resp.statusCode}');
// No muestra matrícula, ID de nota, ni detalles de error
```

### 3. **Sin Token JWT**
```dart
// ❌ ANTES (v2.4.9):
headers: {'Content-Type': 'application/json'}
// Aunque /notas no lo requiere, es buena práctica incluirlo
```

### 4. **Limpiador No Advierte**
- Usuario intenta limpiar notas
- No ve advertencia de que tiene 59 pendientes
- Piensa que el limpiador no funciona

---

## ✅ Soluciones Implementadas en v2.4.10

### 1. **Timeout de 30 Segundos** (`lib/data/api_service.dart`)
```dart
final resp = await http.post(
  url,
  headers: headers,
  body: jsonEncode(payload),
).timeout(
  const Duration(seconds: 30),
  onTimeout: () {
    throw Exception('Timeout: El servidor no respondió en 30 segundos');
  },
);
```

**Beneficio:** Si el servidor está lento o hay problemas de red, la app no se congela indefinidamente.

### 2. **Logs Detallados** (`lib/data/api_service.dart`)
```dart
print('[SYNC] 📤 Enviando nota a servidor...');
print('[SYNC]   - Matrícula: $matricula');
print('[SYNC]   - ID override: $idOverride');
print('[SYNC] 📥 Respuesta del servidor: ${resp.statusCode}');

if (resp.statusCode == 200 || resp.statusCode == 201) {
  print('[SYNC] ✅ Nota sincronizada exitosamente');
} else {
  print('[SYNC] ❌ Error del servidor: ${resp.statusCode} - ${resp.body}');
}
```

**Beneficio:** Ahora puedes ver EXACTAMENTE qué está pasando con cada nota:
- ¿Se está intentando sincronizar?
- ¿Qué matrícula tiene?
- ¿Qué responde el servidor?
- ¿Por qué falla si falla?

### 3. **Token JWT Incluido** (`lib/data/api_service.dart`)
```dart
final token = await auth.AuthService.getToken();

final headers = {
  'Content-Type': 'application/json',
  if (token != null && !token.startsWith('offline_')) 
    'Authorization': 'Bearer $token',
};
```

**Beneficio:** Aunque el endpoint `/notas` no requiere autenticación actualmente, esto asegura compatibilidad futura y mejor auditoría.

### 4. **Advertencias en Limpiador** (`lib/screens/database_cleaner_screen.dart`)

#### Al limpiar notas antiguas:
```dart
if (pendientes > 0) {
  mensaje += '\n\n⚠️ ADVERTENCIA: Tienes $pendientes notas SIN SINCRONIZAR.\n'
             'Estas NO se eliminarán. Usa el botón 🔄 del dashboard para sincronizarlas primero.';
}
```

#### Al limpiar todas las notas sincronizadas:
```dart
String mensaje = 'Esto eliminará TODAS las notas que ya están sincronizadas con el servidor.\n\n'
                 '📊 Notas sincronizadas: $sincronizadas\n'
                 '⏳ Notas pendientes: $pendientes (SE MANTENDRÁN)\n\n';

if (pendientes > 0) {
  mensaje += '⚠️ Si quieres eliminar TODAS las notas, primero sincroniza con el botón 🔄\n\n';
}
```

**Beneficio:** El usuario ahora entiende claramente:
- Cuántas notas están sincronizadas
- Cuántas están pendientes
- Que debe sincronizar primero antes de limpiar

---

## 🧪 Cómo Probar v2.4.10

### Paso 1: Instalar
```powershell
.\releases\installers\CRES_Carnets_Setup_v2.4.10.exe
```

### Paso 2: Ejecutar con Logs Visibles
```powershell
cd "$env:LOCALAPPDATA\CRES Carnets"
.\cres_carnets_ibmcloud.exe
```

### Paso 3: Iniciar Sesión con Internet
Usa tus credenciales normales.

### Paso 4: Observar Logs de Sincronización

#### ✅ Si funciona correctamente:
```
📝 SyncService: 59 notas pendientes para sincronizar
[SYNC] 📤 Enviando nota a servidor...
[SYNC]   - Matrícula: 2024123456
[SYNC]   - ID override: nota_local_1
[SYNC] 📥 Respuesta del servidor: 200
[SYNC] ✅ Nota sincronizada exitosamente
[SYNC] 📤 Enviando nota a servidor...
[SYNC]   - Matrícula: 2024123456
[SYNC]   - ID override: nota_local_2
[SYNC] 📥 Respuesta del servidor: 200
[SYNC] ✅ Nota sincronizada exitosamente
...
(repetir 59 veces)
[SYNC] ✅ Sincronización completada: 59 items
```

#### ❌ Si falla por timeout:
```
[SYNC] 📤 Enviando nota a servidor...
[SYNC]   - Matrícula: 2024123456
[SYNC]   - ID override: nota_local_1
[SYNC] ❌ Error en pushSingleNote: Timeout: El servidor no respondió en 30 segundos
```

**Solución:** El backend está dormido (cold start en Render). Espera 1 minuto y vuelve a intentar.

#### ❌ Si falla por error del servidor:
```
[SYNC] 📤 Enviando nota a servidor...
[SYNC]   - Matrícula: 2024123456
[SYNC]   - ID override: nota_local_1
[SYNC] 📥 Respuesta del servidor: 500
[SYNC] ❌ Error del servidor: 500 - Internal Server Error
```

**Solución:** Problema en el backend. Revisar logs del servidor.

#### ❌ Si falla por falta de internet:
```
[SYNC] 📤 Enviando nota a servidor...
[SYNC]   - Matrícula: 2024123456
[SYNC] ❌ Error en pushSingleNote: SocketException: Failed host lookup
```

**Solución:** Verifica la conexión a internet.

### Paso 5: Verificar Resultado
```powershell
sqlite3 "$env:USERPROFILE\Documents\cres_carnets.sqlite" "SELECT COUNT(*) FROM notes WHERE synced = 0;"
```

**Resultado esperado:** `0` (todas las notas sincronizadas)

---

## 🔄 Sincronización Manual (Alternativa)

Si la sincronización automática al login falla, puedes usar el botón manual:

1. **Click en el botón 🔄** en la barra superior del dashboard
2. **Espera el diálogo de progreso**
3. **Ve los resultados:**
   - Total items procesados
   - Notas sincronizadas: X✓ Y✗
   - Citas sincronizadas: X✓ Y✗
   - Vacunaciones sincronizadas: X✓ Y✗

---

## 🧹 Uso del Limpiador con Advertencias

### Antes de Limpiar:
1. **Sincroniza primero** con el botón 🔄
2. **Verifica que `synced=0` sea 0** con el comando SQLite
3. **Luego usa el limpiador** 🧹

### Al Usar el Limpiador:
- **Verás advertencia clara:** "⚠️ Tienes X notas SIN SINCRONIZAR"
- **Solo se eliminan sincronizadas:** Las pendientes se protegen
- **Opción de limpieza:**
  - Notas antiguas (30/60/90 días) + sincronizadas
  - Todas las notas sincronizadas

---

## 📊 Diferencias v2.4.9 vs v2.4.10

| Aspecto | v2.4.9 | v2.4.10 |
|---------|--------|---------|
| **Timeout sync** | ❌ Sin timeout (congela) | ✅ 30 segundos |
| **Logs sync** | ⚠️ Mínimos (POST, Status) | ✅ Detallados (Matrícula, ID, Error) |
| **Token JWT** | ❌ No incluido | ✅ Incluido en headers |
| **Advertencias limpiador** | ❌ Sin advertencias | ✅ Muestra pendientes |
| **Manejo errores** | ⚠️ Genérico | ✅ Específico por tipo |

---

## 🚀 Próximos Pasos

1. **Instalar v2.4.10**
2. **Ejecutar con logs visibles** desde PowerShell
3. **Iniciar sesión con internet**
4. **Capturar logs** si las 59 notas NO se sincronizan
5. **Reportar:**
   - ¿Cuántas notas se sincronizaron?
   - ¿Qué errores aparecen en consola?
   - ¿Timeout, error del servidor, o falta de internet?

---

## 📝 Notas Técnicas

### Backend No Requiere Autenticación en `/notas`
El endpoint `POST /notas` en `temp_backend/main.py` (línea 226) NO requiere JWT actualmente:

```python
@app.post("/notas/")
@app.post("/notas")
def create_nota(nota: NotaModel = Body(...)):
    # Sin Depends(get_current_user)
```

Esto significa que las notas DEBERÍAN subirse sin token. Sin embargo, agregamos el token en v2.4.10 para:
- Mejor auditoría
- Compatibilidad futura
- Debugging más claro

### ¿Por Qué No Se Sincronizaban Antes?
Hipótesis más probable:
1. **Timeout implícito de http.post()** (60s default en Dart)
2. **Backend en cold start** (Render tarda 30-60s en despertar)
3. **Red lenta o intermitente**
4. **Sincronización se aborta** antes de completar las 59 notas

Con v2.4.10, los logs detallados revelarán el problema exacto.

---

## 📞 Soporte

Si después de instalar v2.4.10 las notas siguen sin sincronizarse, envía:

1. **Captura de logs completa** desde el inicio de sesión
2. **Resultado de:** `SELECT COUNT(*) FROM notes WHERE synced = 0;`
3. **Resultado de:** `SELECT COUNT(*) FROM notes WHERE synced = 1;`
4. **Conexión a internet:** Estable / Intermitente / Lenta

---

**Instalador:** `releases\installers\CRES_Carnets_Setup_v2.4.10.exe`  
**Tamaño:** 13.14 MB  
**Compilado:** 13 de octubre de 2025, 21:03
