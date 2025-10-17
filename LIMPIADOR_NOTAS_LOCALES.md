# 🧹 LIMPIADOR DE NOTAS LOCALES - CRES CARNETS

## 📋 Descripción

Sistema completo de limpieza y mantenimiento de la base de datos local SQLite. Permite eliminar datos antiguos y liberar espacio de forma segura.

---

## 🎯 Características

### 🔹 Pantalla Integrada en la App (DatabaseCleanerScreen)

Funcionalidades:
- ✅ **Estadísticas en tiempo real** de la base de datos
- ✅ **Eliminar notas antiguas** (30, 60, 90 días)
- ✅ **Limpiar cola de sincronización** (registros completados)
- ✅ **Vaciar toda la base de datos** (con doble confirmación)
- ✅ **Protección automática**: Solo elimina datos YA sincronizados
- ✅ **Interfaz visual** intuitiva con confirmaciones

### 🔹 Script PowerShell Externo (limpiador_notas_locales.ps1)

Funcionalidades:
- ✅ **Crear respaldos** antes de cualquier operación
- ✅ **Limpiar base de datos completa** (eliminar y regenerar)
- ✅ **Ver estadísticas** del archivo
- ✅ **Navegación rápida** a la ubicación del archivo
- ✅ **Verificación de seguridad**: Cierra la app automáticamente

---

## 🚀 Uso de la Pantalla Integrada

### 1. Acceso desde la App

```dart
// Agregar en el menú de configuración o administración
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DatabaseCleanerScreen(),
  ),
);
```

### 2. Opciones Disponibles

#### 📅 Eliminar Notas Antiguas
- **Más de 30 días**: Elimina notas con más de 1 mes
- **Más de 60 días**: Elimina notas con más de 2 meses
- **Más de 90 días**: Elimina notas con más de 3 meses

**Protección:** Solo elimina notas con `sync_status = 'synced'`

#### 🔄 Limpiar Cola de Sincronización
- Elimina registros con `status = 'completed'`
- No afecta datos reales, solo metadatos
- Libera espacio en la tabla `sync_queue`

#### 🗑️ Vaciar Toda la Base de Datos
- **Doble confirmación** requerida
- Elimina TODOS los datos sincronizados
- Preserva datos pendientes de sincronización
- Recuperable reconectándose al servidor

### 3. Estadísticas Mostradas

```
Expedientes: 45
Notas: 234
Vacunas: 67
Pendientes de Sync: 3  ⚠️ (naranja si > 0)
```

---

## 🖥️ Uso del Script PowerShell

### 1. Ejecución

```powershell
cd C:\CRES_Carnets_UAGROPRO
.\limpiador_notas_locales.ps1
```

### 2. Menú de Opciones

```
OPCIONES DE LIMPIEZA:

  1. Crear respaldo de la base de datos
  2. Limpiar base de datos (vaciar y regenerar)
  3. Ver ubicación del archivo
  4. Abrir carpeta en explorador
  5. Salir
```

### 3. Opción 1: Crear Respaldo

- Crea copia en el Escritorio
- Formato: `cres_carnets_backup_YYYYMMDD_HHMMSS.sqlite`
- Muestra tamaño y ubicación
- Opción de abrir carpeta

### 4. Opción 2: Limpiar Base de Datos

**Proceso automático:**
1. Crea respaldo automático
2. Elimina el archivo original
3. Al abrir la app se regenera vacío
4. Reconectar a internet para re-sincronizar

**Advertencias claras:**
- Se pierden notas NO sincronizadas
- Se pierden expedientes locales
- Recuperable desde servidor (si ya sincronizados)

---

## 🛡️ Seguridad y Protección

### ✅ Protecciones Implementadas

#### En la App:
```dart
// Solo elimina datos sincronizados
WHERE sync_status = 'synced'

// Doble confirmación para operaciones peligrosas
final confirmado1 = await _showConfirmDialog(...);
final confirmado2 = await _showConfirmDialog(...);
```

#### En el Script:
```powershell
# Respaldo automático antes de eliminar
Copy-Item $dbPath $respaldo -Force

# Verificar que app esté cerrada
$appRunning = Get-Process | Where-Object { ... }
```

### ⚠️ Datos que SE Eliminan

- ✅ Notas con `sync_status = 'synced'`
- ✅ Expedientes con `sync_status = 'synced'`
- ✅ Vacunas con `sync_status = 'synced'`
- ✅ Registros de cola con `status = 'completed'`

### 🔒 Datos que NO SE Eliminan

- ❌ Notas con `sync_status = 'pending'` o `'error'`
- ❌ Datos de autenticación (están en FlutterSecureStorage)
- ❌ Configuración de la app

---

## 📊 Casos de Uso

### Caso 1: Liberar Espacio

**Problema:** Base de datos crece mucho con el tiempo

**Solución:**
1. Abrir DatabaseCleanerScreen
2. Eliminar notas de más de 90 días
3. Limpiar cola de sincronización
4. Libera ~50-70% del espacio típicamente

### Caso 2: Empezar de Cero

**Problema:** Quiero datos limpios desde servidor

**Solución:**
1. Ejecutar `limpiador_notas_locales.ps1`
2. Opción 2: Limpiar base de datos
3. Abrir app → archivo regenerado vacío
4. Conectar internet → datos se descargan frescos

### Caso 3: Base de Datos Corrupta

**Problema:** Errores al abrir la app o datos inconsistentes

**Solución:**
1. Crear respaldo (por si acaso)
2. Limpiar base de datos completamente
3. Regenerar desde servidor

### Caso 4: Testing o Desarrollo

**Problema:** Necesito probar con datos limpios

**Solución:**
1. Respaldo de datos actuales
2. Limpiar base de datos
3. Probar funcionalidad
4. Restaurar respaldo si es necesario

---

## 🔧 Integración en la App

### 1. Agregar Ruta en el Router

```dart
// En tu archivo de rutas o main.dart
'/database-cleaner': (context) => DatabaseCleanerScreen(),
```

### 2. Agregar Botón en Configuración

```dart
ListTile(
  leading: Icon(Icons.cleaning_services, color: Colors.orange),
  title: Text('Limpieza de Datos'),
  subtitle: Text('Administrar y limpiar base de datos local'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatabaseCleanerScreen(),
      ),
    );
  },
),
```

### 3. Agregar en Menú de Administrador

```dart
if (user.role == 'admin') {
  ListTile(
    leading: Icon(Icons.admin_panel_settings),
    title: Text('Mantenimiento de Base de Datos'),
    onTap: () => Navigator.pushNamed(context, '/database-cleaner'),
  ),
}
```

---

## 📁 Estructura de Archivos

```
lib/
  screens/
    database_cleaner_screen.dart  ← Pantalla integrada
    
scripts/
  limpiador_notas_locales.ps1     ← Script PowerShell externo
  eliminar_base_datos_seguro.ps1  ← Script de eliminación total
  abrir_datos_locales.ps1          ← Script de acceso rápido
  
docs/
  LIMPIADOR_NOTAS_LOCALES.md      ← Esta documentación
  FAQ_ELIMINAR_BASE_DATOS.md      ← FAQ sobre eliminación
  UBICACION_DATOS_LOCALES.md      ← Ubicación de archivos
```

---

## 🧪 Testing

### Pruebas Recomendadas

1. **Test de Eliminación de Notas Antiguas:**
   - Crear notas con fechas antiguas
   - Marcar como sincronizadas
   - Ejecutar limpieza
   - Verificar que solo se eliminaron las antiguas

2. **Test de Protección:**
   - Crear notas NO sincronizadas
   - Intentar limpiar todo
   - Verificar que NO se eliminaron

3. **Test de Respaldo:**
   - Ejecutar script PowerShell
   - Crear respaldo
   - Verificar que se puede restaurar

4. **Test de Regeneración:**
   - Eliminar base de datos
   - Abrir app
   - Verificar que se crea nuevo archivo vacío

---

## 🐛 Solución de Problemas

### Problema: "No se puede eliminar, archivo en uso"

**Causa:** La app está abierta

**Solución:**
```powershell
# El script lo detecta automáticamente y ofrece cerrarla
# O cerrar manualmente y reintentar
```

### Problema: "Datos se perdieron después de limpiar"

**Causa:** Notas no estaban sincronizadas

**Solución:**
- Siempre verificar contador "Pendientes de Sync" antes de limpiar
- Si hay pendientes, sincronizar primero
- O hacer respaldo antes de limpiar

### Problema: "Base de datos no se regenera"

**Causa:** Error en la app al crear archivo

**Solución:**
1. Verificar permisos en carpeta Documents
2. Ejecutar app como administrador
3. Revisar logs de la app

---

## 📈 Mejoras Futuras

### Posibles Extensiones:

1. **Limpieza Automática:**
   ```dart
   // Ejecutar limpieza cada 30 días automáticamente
   if (daysSinceLastClean > 30) {
     await _autoCleanOldNotes(90);
   }
   ```

2. **Estadísticas Avanzadas:**
   - Tamaño por tipo de nota
   - Gráficos de crecimiento
   - Predicción de espacio

3. **Exportación antes de Limpiar:**
   ```dart
   // Exportar a JSON antes de eliminar
   final export = await _exportDataToJson();
   await _saveToFile(export);
   ```

4. **Limpieza Selectiva:**
   - Por campus
   - Por tipo de nota
   - Por usuario/estudiante

---

## 📞 Soporte

Para problemas o sugerencias:
- Revisar logs de la app
- Ejecutar script de diagnóstico
- Verificar sincronización antes de limpiar

---

**Creado:** 13/10/2025  
**Versión:** 2.4.8+  
**Plataforma:** Windows, Android (pantalla), iOS (pantalla)  
**Autor:** CRES Carnets Development Team
