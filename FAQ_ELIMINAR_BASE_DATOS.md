# ❓ ¿Qué pasa si elimino cres_carnets.sqlite?

## ✅ RESPUESTA CORTA:
**SÍ, el archivo se regenerará automáticamente** cuando abras la app de nuevo.

---

## 🔄 ¿QUÉ SUCEDE EXACTAMENTE?

### Cuando eliminas el archivo:
1. ❌ Se pierden **TODAS las notas locales** guardadas
2. ❌ Se pierden expedientes de estudiantes
3. ❌ Se pierde el historial completo
4. ⚠️ **NO se pierden** los datos de autenticación (están en otro lugar)

### Cuando abres la app después de eliminarlo:
1. ✅ La app detecta que no existe el archivo
2. ✅ Crea automáticamente un nuevo `cres_carnets.sqlite` vacío
3. ✅ Inicializa la estructura de tablas (expedientes, notas, vacunas, etc.)
4. ✅ La app funciona normalmente
5. 📝 Empiezas con una base de datos **completamente limpia**

---

## 💻 CÓDIGO QUE LO HACE POSIBLE:

```dart
// lib/data/db.dart línea 197-201
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cres_carnets.sqlite'));
    return NativeDatabase.createInBackground(file);
    // ↑ Si el archivo no existe, se crea automáticamente
  });
}
```

**`NativeDatabase.createInBackground(file)`** hace dos cosas:
1. Si el archivo existe → lo abre
2. Si NO existe → **lo crea automáticamente**

---

## 🧪 PRUEBA PRÁCTICA:

### Experimento seguro:

```powershell
# 1. Hacer respaldo primero (por seguridad)
$fecha = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item "C:\Users\gilbe\Documents\cres_carnets.sqlite" `
          "C:\Users\gilbe\Desktop\respaldo_$fecha.sqlite"

# 2. Cerrar la app completamente

# 3. Eliminar el archivo
Remove-Item "C:\Users\gilbe\Documents\cres_carnets.sqlite"

# 4. Verificar que fue eliminado
Test-Path "C:\Users\gilbe\Documents\cres_carnets.sqlite"
# Resultado: False

# 5. Abrir la app de nuevo

# 6. Verificar que se regeneró
Test-Path "C:\Users\gilbe\Documents\cres_carnets.sqlite"
# Resultado: True (archivo nuevo creado)

# 7. Si quieres recuperar los datos, restaura el respaldo
Copy-Item "C:\Users\gilbe\Desktop\respaldo_$fecha.sqlite" `
          "C:\Users\gilbe\Documents\cres_carnets.sqlite" -Force
```

---

## ⚠️ IMPORTANTE - ANTES DE ELIMINAR:

### ¿Qué SE PIERDE si eliminas sin respaldo?
- ❌ **Todas las notas locales** (médicas, psicológicas, odontológicas)
- ❌ **Expedientes de estudiantes**
- ❌ **Registros de vacunación**
- ❌ **Resultados de tests psicológicos**
- ❌ **Historial completo**
- ❌ **Notas que NO se han sincronizado** con el servidor

### ¿Qué NO se pierde?
- ✅ **Datos de autenticación** (usuario, password hash, token)
  - Están en el Registro de Windows, no en este archivo
- ✅ **Datos sincronizados en el servidor**
  - Si ya se sincronizaron, se pueden volver a descargar
- ✅ **Configuración de la app**

---

## 🔄 SINCRONIZACIÓN CON EL SERVIDOR:

### Si las notas YA se sincronizaron:
1. Eliminas el archivo local
2. Abres la app
3. Se crea nuevo archivo vacío
4. Te conectas a internet
5. **Las notas se vuelven a descargar del servidor**
6. Base de datos se recupera

### Si las notas NO se han sincronizado:
1. Eliminas el archivo local
2. ❌ **Las notas se pierden para siempre**
3. No hay forma de recuperarlas

---

## 📋 CASOS DE USO PARA ELIMINAR EL ARCHIVO:

### ✅ Cuándo SÍ es seguro eliminarlo:
1. **Empezar de cero** con datos limpios
2. **Problema de corrupción** de base de datos
3. **Testing** o desarrollo
4. **Ya hiciste respaldo** y quieres limpiar
5. **Todas las notas están sincronizadas** en el servidor

### ❌ Cuándo NO debes eliminarlo:
1. Tienes **notas sin sincronizar**
2. Trabajaste **sin internet** recientemente
3. No estás seguro si hay datos importantes
4. No tienes respaldo

---

## 🛠️ SCRIPT PARA ELIMINAR SEGURO:

```powershell
# ========================================
# ELIMINAR SEGURO - CON RESPALDO AUTOMÁTICO
# ========================================

$dbPath = "C:\Users\gilbe\Documents\cres_carnets.sqlite"
$fecha = Get-Date -Format "yyyyMMdd_HHmmss"
$respaldo = "$env:USERPROFILE\Desktop\cres_carnets_respaldo_$fecha.sqlite"

Write-Host "`n=== ELIMINACION SEGURA ===" -ForegroundColor Yellow
Write-Host ""

# Verificar que existe
if (-not (Test-Path $dbPath)) {
    Write-Host "El archivo no existe, no hay nada que eliminar." -ForegroundColor Green
    exit
}

# Mostrar info
$file = Get-Item $dbPath
Write-Host "Archivo a eliminar:" -ForegroundColor Cyan
Write-Host "  Ruta: $dbPath" -ForegroundColor White
Write-Host "  Tamano: $([math]::Round($file.Length/1KB,2)) KB" -ForegroundColor White
Write-Host "  Modificado: $($file.LastWriteTime)" -ForegroundColor White
Write-Host ""

# Confirmar
Write-Host "ADVERTENCIA: Se perderan las notas NO sincronizadas" -ForegroundColor Red
Write-Host ""
$confirmar = Read-Host "¿Hacer respaldo y eliminar? (S/N)"

if ($confirmar -eq "S" -or $confirmar -eq "s") {
    # Hacer respaldo
    Write-Host "`nCreando respaldo..." -ForegroundColor Cyan
    Copy-Item $dbPath $respaldo
    Write-Host "Respaldo creado: $respaldo" -ForegroundColor Green
    
    # Eliminar
    Write-Host "`nEliminando archivo original..." -ForegroundColor Cyan
    Remove-Item $dbPath -Force
    Write-Host "Archivo eliminado" -ForegroundColor Green
    
    Write-Host "`n✅ COMPLETADO" -ForegroundColor Green
    Write-Host "Al abrir la app se creara un archivo nuevo y vacio" -ForegroundColor White
    Write-Host ""
    Write-Host "Para restaurar, ejecuta:" -ForegroundColor Yellow
    Write-Host "Copy-Item '$respaldo' '$dbPath' -Force" -ForegroundColor Gray
} else {
    Write-Host "`nOperacion cancelada" -ForegroundColor Yellow
}

Write-Host ""
```

---

## 📊 RESUMEN:

| Pregunta | Respuesta |
|----------|-----------|
| ¿Se regenera automáticamente? | ✅ Sí |
| ¿Se pierden los datos? | ⚠️ Sí, si no hay respaldo |
| ¿Se pueden recuperar del servidor? | ✅ Sí, si ya se sincronizaron |
| ¿Afecta la autenticación? | ❌ No, está en otro lugar |
| ¿Es reversible sin respaldo? | ❌ No |
| ¿Es seguro si hice respaldo? | ✅ Totalmente seguro |

---

## 🎯 RECOMENDACIÓN:

**Si quieres limpiar la base de datos:**

1. ✅ **Hacer respaldo primero** (usa el script de arriba)
2. ✅ Asegúrate de que todo esté sincronizado con el servidor
3. ✅ Cierra la app completamente
4. ✅ Elimina el archivo
5. ✅ Abre la app → se regenerará vacío
6. ✅ Conéctate a internet → se descargarán datos del servidor

**Si algo sale mal, restaura el respaldo.**

---

**Fecha:** 13/10/2025  
**Versión:** 2.4.8  
**Archivo actual:** C:\Users\gilbe\Documents\cres_carnets.sqlite (36 KB)
