# 📂 UBICACIÓN DE DATOS LOCALES - CRES Carnets

## 📍 Carpeta Principal de Datos

### En Windows:
```
%USERPROFILE%\Documents\
```

**Ruta completa típica:**
```
C:\Users\[NombreUsuario]\Documents\cres_carnets.sqlite
```

**Ejemplo:**
```
C:\Users\JuanPerez\Documents\cres_carnets.sqlite
```

---

## 🗄️ Base de Datos SQLite

**Archivo:** `cres_carnets.sqlite`

Este archivo contiene **TODAS** las notas y datos locales:
- ✅ Expedientes de estudiantes
- ✅ Notas médicas
- ✅ Notas psicológicas
- ✅ Notas odontológicas
- ✅ Registros de vacunación
- ✅ Resultados de tests psicológicos
- ✅ Historial completo

### Código fuente de referencia:
```dart
// lib/data/db.dart línea 198
final dir = await getApplicationDocumentsDirectory();
final file = File(p.join(dir.path, 'cres_carnets.sqlite'));
```

---

## 🔒 Datos de Autenticación (FlutterSecureStorage)

### En Windows:
Los datos de autenticación se guardan en el **Registro de Windows** usando FlutterSecureStorage:

**Ubicación en el Registro:**
```
HKEY_CURRENT_USER\Software\[AppName]\flutter_secure_storage
```

**Datos guardados:**
- `auth_token` - Token de sesión
- `auth_user` - Datos del usuario (JSON)
- `offline_password_hash` - Hash de contraseña para login offline

---

## 📋 Cómo Acceder a los Datos Locales

### Opción 1: Explorador de Windows
1. Presiona `Windows + R`
2. Escribe: `%USERPROFILE%\Documents`
3. Presiona Enter
4. Busca el archivo: `cres_carnets.sqlite`

### Opción 2: Desde PowerShell
```powershell
# Ver si existe el archivo
Test-Path "$env:USERPROFILE\Documents\cres_carnets.sqlite"

# Abrir la carpeta
explorer.exe "$env:USERPROFILE\Documents"

# Ver información del archivo
Get-ChildItem "$env:USERPROFILE\Documents\cres_carnets.sqlite" | Format-List
```

### Opción 3: Desde CMD
```cmd
dir "%USERPROFILE%\Documents\cres_carnets.sqlite"
```

---

## 🔍 Inspeccionar Base de Datos

### Herramientas recomendadas:

1. **DB Browser for SQLite** (Gratuito)
   - Descarga: https://sqlitebrowser.org/
   - Permite ver/editar el archivo .sqlite
   - Interfaz gráfica fácil de usar

2. **SQLite Command Line**
   ```bash
   sqlite3 "C:\Users\[Usuario]\Documents\cres_carnets.sqlite"
   .tables  # Ver tablas
   .schema  # Ver estructura
   ```

---

## 📊 Estructura de Datos

### Tablas principales en `cres_carnets.sqlite`:

1. **expedientes** - Datos básicos de estudiantes
2. **notas** - Notas médicas/psicológicas/odontológicas
3. **vacunas** - Registros de vacunación
4. **tests_psicologicos** - Resultados de tests
5. **odontogramas** - Información dental
6. **sync_queue** - Cola de sincronización con servidor

---

## 💾 Respaldo de Datos

### Cómo hacer respaldo manual:

```powershell
# Copiar base de datos a carpeta de respaldo
$fecha = Get-Date -Format "yyyyMMdd_HHmmss"
$origen = "$env:USERPROFILE\Documents\cres_carnets.sqlite"
$destino = "$env:USERPROFILE\Desktop\Respaldo_CRES_$fecha.sqlite"
Copy-Item $origen $destino
Write-Host "Respaldo creado: $destino" -ForegroundColor Green
```

### Restaurar desde respaldo:

```powershell
# Reemplazar base de datos actual con respaldo
$respaldo = "$env:USERPROFILE\Desktop\Respaldo_CRES_20251013.sqlite"
$destino = "$env:USERPROFILE\Documents\cres_carnets.sqlite"

# Cerrar la app primero, luego:
Copy-Item $respaldo $destino -Force
Write-Host "Base de datos restaurada" -ForegroundColor Green
```

---

## 🗑️ Borrar Datos Locales

### Para eliminar TODOS los datos locales:

1. **Cerrar la aplicación completamente**

2. **Borrar base de datos:**
   ```powershell
   Remove-Item "$env:USERPROFILE\Documents\cres_carnets.sqlite"
   ```

3. **Borrar caché de autenticación (Registro de Windows):**
   - Se borra automáticamente al desinstalar la app
   - O usar la función "Cerrar sesión" en la app

---

## 📝 Notas Importantes

1. ⚠️ **NO modificar manualmente** el archivo `.sqlite` mientras la app está abierta
   - Puede causar corrupción de datos
   - Siempre cerrar la app primero

2. ✅ **Respaldo automático:** La app NO hace respaldos automáticos
   - Considerar hacer respaldos manuales periódicos
   - Especialmente antes de actualizaciones

3. 🔄 **Sincronización:** Los datos se sincronizan con el servidor cuando hay internet
   - Las notas locales se marcan para sincronización
   - Se sincronizan automáticamente al conectarse

4. 💡 **Múltiples instalaciones:** Cada instalación de Windows tiene su propia base de datos
   - NO se comparten datos entre diferentes PCs
   - Usar la sincronización con servidor para compartir

---

## 🛠️ Solución de Problemas

### Base de datos corrupta:
```powershell
# Verificar integridad
sqlite3 cres_carnets.sqlite "PRAGMA integrity_check;"

# Si está corrupta, restaurar desde respaldo
```

### No se encuentran los datos:
```powershell
# Buscar el archivo en todo el sistema
Get-ChildItem -Path C:\ -Filter "cres_carnets.sqlite" -Recurse -ErrorAction SilentlyContinue
```

### Limpiar datos de autenticación:
La app tiene opción "Cerrar sesión" que limpia los datos de autenticación pero preserva las notas locales.

---

**Fecha de actualización:** 13/10/2025  
**Versión de la app:** 2.4.8+  
**Plataforma:** Windows
