# 🔐 PUNTO DE RESTAURACIÓN v2.4.33
**Fecha**: 24 noviembre 2025 - 19:32 CST
**Commit**: 8a478bb
**Estado**: ✅ ESTABLE Y FUNCIONAL

---

## 📦 Respaldo Creado
**Ubicación**: `backup_v2.4.33_estable_20251124_193241/`
**Tamaño**: 330.52 MB
**Archivos**: Código fuente completo (sin build, releases, node_modules)

---

## ✅ Funcionalidades Verificadas en Esta Versión

### 1. **Búsqueda por Nombre** (v2.4.30-32)
- ✅ Backend: `/carnet/search` con query CONTAINS
- ✅ Cliente: Detección automática matricula vs nombre
- ✅ Ambas pantallas: nueva_nota_screen.dart + list_screen.dart

### 2. **Fix Guardado Offline** (v2.4.33) ⭐ CRÍTICO
- ✅ Timeout reducido: 3 segundos (antes 60 segundos)
- ✅ Método `hasInternetConnection()` en ApiService
- ✅ Detección rápida de conexión antes de validar duplicados
- ✅ Guardado fluido de múltiples carnets sin internet

### 3. **Versión Visible** (v2.4.33)
- ✅ Dashboard muestra versión instalada: `v2.4.33 (33)`
- ✅ Ubicación: Debajo del logo SASU
- ✅ Actualización automática al instalar nueva versión

### 4. **Auto-Actualización**
- ✅ Sistema funcional con UpdateManager
- ✅ Backend: `/updates/check` y `/updates/publish`
- ✅ GitHub Releases como fuente de distribución
- ✅ Detección automática cada 1-5 minutos

---

## 🔧 Archivos Clave Modificados

### Backend (temp_backend/)
```
main.py
├── Línea 223-250: Endpoint /carnet/search
└── Debug logs con sys.stderr (commit abe567d)

update_routes.py
└── Línea 263-329: Endpoint /updates/publish
```

### Cliente (lib/)
```
data/api_service.dart
├── Línea 14: _quickCheckTimeout = 3 segundos
├── Línea 17-27: hasInternetConnection() NUEVO
└── Línea 345-425: getExpedienteByMatricula()

screens/form_screen.dart
├── Línea 1096-1220: Método _save()
└── Línea 1133-1163: Verificación de conexión antes de validar duplicados

screens/dashboard_screen.dart
├── Línea 113-128: _getVersionString() NUEVO
└── Línea 570-595: FutureBuilder mostrando versión

screens/nueva_nota_screen.dart
└── Línea 263-362: Búsqueda por nombre/matricula

screens/list_screen.dart
└── Línea 6-83: Búsqueda en tiempo real
```

---

## 📊 Performance

**Guardado de 5 carnets sin internet:**
- ⏱️ **Antes (v2.4.32)**: 5 minutos (60s × 5 carnets)
- ⚡ **Ahora (v2.4.33)**: 15 segundos (3s × 5 carnets)
- 📈 **Mejora**: 95% más rápido (20x)

---

## 🔄 Cómo Restaurar Este Punto

### Opción 1: Desde Respaldo Local
```powershell
# Eliminar código actual
Remove-Item lib, pubspec.yaml, android, windows -Recurse -Force

# Restaurar desde respaldo
Copy-Item backup_v2.4.33_estable_20251124_193241\* -Destination . -Recurse -Force

# Recompilar
flutter clean
flutter pub get
flutter build windows --release
```

### Opción 2: Desde Git
```powershell
# Volver al commit estable
git checkout 8a478bb

# O crear branch desde este punto
git checkout -b restore-v2.4.33-stable 8a478bb

# Recompilar
flutter clean
flutter pub get
flutter build windows --release
```

### Opción 3: Desde GitHub Release
1. Descargar: https://github.com/edukshare-max/UPDATE_CRES_CARNET_/releases/tag/v2.4.33
2. Extraer ZIP
3. Ejecutar `cres_carnets_ibmcloud.exe`

---

## 🚀 Versiones Publicadas

| Versión | Estado | Descripción |
|---------|--------|-------------|
| v2.4.30 | ✅ | Búsqueda por nombre (inicial) |
| v2.4.31 | ✅ | Búsqueda en list_screen |
| v2.4.32 | ✅ | Búsqueda con fallback local + UX mejorado |
| v2.4.33 | ⭐ **ACTUAL** | Fix guardado offline + versión visible |

---

## 🔗 URLs Importantes

- **Backend**: https://fastapi-backend-o7ks.onrender.com
- **GitHub Releases**: https://github.com/edukshare-max/UPDATE_CRES_CARNET_/releases
- **Repository**: https://github.com/edukshare-max/UPDATE_CRES_CARNET_

---

## 📝 Notas Técnicas

### Problema Resuelto en v2.4.33
**Síntoma**: Al guardar carnets sin internet, solo se guardaba el primero. Los siguientes parecían "colgarse" sin hacer nada.

**Causa Raíz**: `getExpedienteByMatricula()` usaba timeout de 60 segundos. Sin internet, cada carnet esperaba 60 segundos antes de lanzar timeout.

**Solución**: 
1. Nuevo método `hasInternetConnection()` con timeout de 3 segundos
2. Verificar conexión ANTES de consultar duplicados
3. Si no hay internet, guardar directo sin verificación en nube

### Lecciones Aprendidas
- ✅ Gunicorn buffers stdout → usar `sys.stderr.write()` para debug logs
- ✅ Timeouts largos bloquean UX → separar timeout de verificación vs operación
- ✅ Detección rápida de conexión mejora experiencia offline dramáticamente

---

## ⚠️ IMPORTANTE

**Este es un punto de restauración ESTABLE y FUNCIONAL.**

Antes de modificar código crítico:
1. ✅ Verificar que este respaldo existe
2. ✅ Probar cambios en branch separado
3. ✅ Hacer commit antes de modificaciones grandes
4. ✅ Documentar qué estás cambiando y por qué

**Si algo sale mal, siempre puedes volver aquí.**

---

**Respaldo creado**: 2025-11-24 19:32:41 CST
**Último commit**: 8a478bb - "feat: v2.4.33 - Fix guardado offline rapido + version visible"
