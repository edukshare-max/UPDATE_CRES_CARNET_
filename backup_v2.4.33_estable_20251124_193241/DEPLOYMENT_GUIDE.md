# 🚀 Sistema de Deployment Automatizado

## Descripción General

Sistema completo de deployment que automatiza todo el proceso de liberación de nuevas versiones de CRES Carnets, desde el incremento de versión hasta la distribución final.

## 📋 Fases Completadas

### ✅ FASE 1: Sistema de Distribución
- Instalador profesional con Inno Setup
- Scripts de build automatizados  
- Releases organizados por fecha

### ✅ FASE 2: Versionamiento Automático
- `VersionService` (Flutter) - Lee versión al iniciar
- `AboutScreen` - Pantalla "Acerca de" con changelog
- `update_version.ps1` - Script para incrementar versión
- `version.json` - Sincronizado con pubspec.yaml

### ✅ FASE 3: Backend de Actualizaciones
- **URL Backend:** https://fastapi-backend-o7ks.onrender.com
- **Endpoints REST:**
  - `POST /updates/check` - Verificar actualizaciones
  - `GET /updates/latest` - Obtener última versión
  - `GET /updates/changelog` - Historial de cambios
  - `GET /updates/health` - Estado del servicio

### ✅ FASE 4: Auto-updater Flutter
- **UpdateService** (231 líneas) - Cliente HTTP para backend
- **UpdateDownloader** (194 líneas) - Descarga con progreso (Dio)
- **UpdateManager** (360 líneas) - Coordinador del proceso
- **UpdateDialog** (297 líneas) - UI profesional

**Características:**
- ✅ Verificación automática cada 24 horas
- ✅ Botón manual en Dashboard (🔄)
- ✅ Descarga con barra de progreso
- ✅ Sistema de omitir versiones
- ✅ Verificación de checksum SHA256
- ✅ Ejecución automática del instalador

### ✅ FASE 5: Pipeline de Deployment

Script maestro **`deploy.ps1`** que automatiza:
1. ✅ Incrementar versión (Major/Minor/Patch)
2. ✅ Build de release (Flutter)
3. ✅ Generar instalador (Inno Setup)
4. ✅ Calcular checksum SHA256
5. ✅ Subir a GitHub Releases (con gh CLI)
6. ✅ Actualizar backend (`update_routes.py`)
7. ✅ Git commit + tag + push

---

## 🎯 Uso del Sistema

### Despliegue de Nueva Versión

#### Opción 1: Incremento Patch (1.0.0 → 1.0.1)
```powershell
.\deploy.ps1 -Patch
```
Se te pedirá un mensaje de changelog.

#### Opción 2: Incremento Minor (1.0.0 → 1.1.0)
```powershell
.\deploy.ps1 -Minor -Message "Nueva funcionalidad de reportes"
```

#### Opción 3: Incremento Major (1.0.0 → 2.0.0)
```powershell
.\deploy.ps1 -Major -Message "Rediseño completo de la interfaz"
```

### Opciones de Testing

#### Solo generar instalador (sin upload)
```powershell
.\deploy.ps1 -Patch -SkipUpload
```

#### Sin actualizar backend
```powershell
.\deploy.ps1 -Patch -SkipBackend
```

#### Testing completo local
```powershell
.\deploy.ps1 -Patch -SkipUpload -SkipBackend
```

---

## 📦 Proceso Completo de Deployment

### Paso a Paso (Automático)

1. **Verificación de Herramientas**
   - ✅ Flutter instalado
   - ✅ Git instalado
   - ✅ Inno Setup instalado
   - ✅ GitHub CLI (gh) instalado (opcional)

2. **Incremento de Versión**
   - Ejecuta `update_version.ps1`
   - Actualiza `version.json`
   - Actualiza `pubspec.yaml`
   - Agrega entrada al changelog

3. **Compilación**
   - `flutter clean`
   - `flutter pub get`
   - `flutter build windows --release`

4. **Generación de Instalador**
   - Ejecuta Inno Setup con `installer_config.iss`
   - Genera `CRES_Carnets_Setup_v{version}.exe`
   - Guarda en carpeta `releases/`

5. **Checksum SHA256**
   - Calcula hash del instalador
   - Se usará para verificar integridad

6. **Upload a GitHub Releases**
   - Crea release con tag `v{version}`
   - Sube instalador como asset
   - Genera notas de release automáticas
   - Incluye checksum y tamaño

7. **Actualización del Backend**
   - Modifica `temp_backend/update_routes.py`
   - Actualiza `LATEST_VERSION`:
     - Versión y build number
     - URL de descarga
     - Checksum
     - Changelog
     - Fecha de release

8. **Git Commit y Tag**
   - Commit con mensaje descriptivo
   - Crea tag `v{version}`
   - Push a GitHub (opcional)

---

## 🛠️ Requisitos Previos

### Software Necesario

#### Flutter SDK
```powershell
# Verificar instalación
flutter --version
```

#### Git
```powershell
# Verificar instalación
git --version
```

#### Inno Setup 6
- **Descargar:** https://jrsoftware.org/isdl.php
- **Ruta esperada:** `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`

#### GitHub CLI (Opcional)
```powershell
# Instalar con winget
winget install GitHub.cli

# Verificar
gh --version

# Autenticar
gh auth login
```

### Configuración Inicial

#### 1. Repositorio Git
```powershell
# Verificar remoto
git remote -v

# Debe mostrar:
# origin  https://github.com/edukshare-max/fastapi-backend.git
```

#### 2. Backend en Render
- URL: https://fastapi-backend-o7ks.onrender.com
- Auto-deploy desde GitHub main branch
- Verifica que `temp_backend/` esté en el repo

#### 3. Estructura de Carpetas
```
CRES_Carnets_UAGROPRO/
├── assets/
│   └── version.json          # Versión actual
├── releases/                 # Instaladores generados
├── temp_backend/
│   ├── main.py
│   ├── update_routes.py     # Se actualiza automáticamente
│   └── update_models.py
├── deploy.ps1               # Script maestro
├── update_version.ps1       # Incrementar versión
├── build_installer.ps1      # Generar instalador
└── installer_config.iss     # Config Inno Setup
```

---

## 📊 Flujo de Actualización (Usuario Final)

### 1. Detección Automática
- Usuario inicia CRES Carnets
- Después de 3 segundos, verifica updates
- Si han pasado 24h desde última verificación

### 2. Notificación
- Diálogo muestra:
  - Nueva versión disponible
  - Changelog completo
  - Tamaño del instalador
  - Opción de actualizar o postponer

### 3. Descarga
- Barra de progreso en tiempo real
- Descarga a carpeta temporal
- Verificación de checksum SHA256

### 4. Instalación
- Cierra app automáticamente
- Ejecuta instalador
- Instalador actualiza archivos
- Usuario reinicia app manualmente

### 5. Verificación Manual
- Botón **🔄** en Dashboard
- Verifica inmediatamente
- No espera 24 horas

---

## 🧪 Testing del Sistema

### Test 1: Deployment Local
```powershell
# Solo genera instalador, no sube ni actualiza backend
.\deploy.ps1 -Patch -SkipUpload -SkipBackend -Message "Test local"
```
✅ **Verifica:** Instalador generado en `releases/`

### Test 2: Con Upload
```powershell
# Genera y sube a GitHub, pero no actualiza backend
.\deploy.ps1 -Patch -SkipBackend -Message "Test upload"
```
✅ **Verifica:** Release en GitHub con instalador

### Test 3: Deployment Completo
```powershell
# Proceso completo
.\deploy.ps1 -Patch -Message "Test completo"
```
✅ **Verifica:**
- Instalador en `releases/`
- Release en GitHub
- `update_routes.py` actualizado
- Backend desplegado en Render
- App detecta nueva versión

### Test 4: Actualización desde App
1. Instala versión anterior
2. Inicia app
3. Presiona botón 🔄
4. Debe detectar nueva versión
5. Descarga e instala
6. Verifica nueva versión funcionando

---

## 📝 Solución de Problemas

### Error: "Flutter no encontrado"
```powershell
# Agregar Flutter al PATH
$env:Path += ";C:\src\flutter\bin"
```

### Error: "Inno Setup no encontrado"
- Instala desde: https://jrsoftware.org/isdl.php
- O modifica ruta en `deploy.ps1` línea 95

### Error: "gh no encontrado"
```powershell
# Instalar GitHub CLI
winget install GitHub.cli

# Autenticar
gh auth login
```

### Error: "Build falla"
```powershell
# Limpiar completamente
flutter clean
rd /s build
flutter pub get
flutter build windows --release
```

### Error: "Backend no se actualiza en Render"
1. Verifica que `temp_backend/` esté en el repo
2. Haz push manual:
   ```powershell
   cd temp_backend
   git add update_routes.py
   git commit -m "Update version"
   git push
   ```
3. Espera 2-3 minutos para auto-deploy

### App no detecta actualización
1. Verifica backend: https://fastapi-backend-o7ks.onrender.com/updates/health
2. Prueba endpoint: https://fastapi-backend-o7ks.onrender.com/updates/latest
3. Revisa logs de Flutter (F12 en debug)
4. Verifica `update_routes.py` tiene versión correcta

---

## 📈 Estadísticas del Sistema

### Líneas de Código
- **FASE 1-2:** ~800 líneas
- **FASE 3:** ~300 líneas (Backend)
- **FASE 4:** ~1,082 líneas (Flutter)
- **FASE 5:** ~450 líneas (Scripts)
- **Total:** ~2,632 líneas

### Archivos Creados
- **Flutter:** 4 archivos (services + UI)
- **Backend:** 3 archivos (routes + models)
- **Scripts:** 3 archivos (deploy, update, build)
- **Config:** 1 archivo (Inno Setup)
- **Total:** 11 archivos

### Dependencias Agregadas
- `dio: ^5.4.0` (Descargas con progreso)

---

## 🎓 Mejores Prácticas

### 1. Versionamiento Semántico
- **Major (X.0.0):** Cambios incompatibles
- **Minor (0.X.0):** Nuevas funcionalidades compatibles
- **Patch (0.0.X):** Correcciones de bugs

### 2. Mensajes de Changelog
```powershell
# ✅ Buenos mensajes
.\deploy.ps1 -Patch -Message "Fix: Error al guardar carnets offline"
.\deploy.ps1 -Minor -Message "Nuevo módulo de reportes PDF"
.\deploy.ps1 -Major -Message "Rediseño completo de la UI"

# ❌ Evitar
.\deploy.ps1 -Patch -Message "Cambios"
.\deploy.ps1 -Minor -Message "Update"
```

### 3. Testing Antes de Deploy
```powershell
# Siempre probar localmente primero
.\deploy.ps1 -Patch -SkipUpload -SkipBackend
# Probar instalador generado
# Si todo OK, deploy real
.\deploy.ps1 -Patch
```

### 4. Frecuencia de Releases
- **Patches:** Cuando sea necesario (bugs críticos)
- **Minor:** Cada 2-4 semanas (nuevas features)
- **Major:** Cuando haya cambios grandes (cada 3-6 meses)

---

## 🔗 Enlaces Útiles

- **Backend:** https://fastapi-backend-o7ks.onrender.com
- **GitHub Repo:** https://github.com/edukshare-max/fastapi-backend
- **Inno Setup Docs:** https://jrsoftware.org/ishelp/
- **Flutter Docs:** https://docs.flutter.dev/
- **GitHub CLI Docs:** https://cli.github.com/manual/

---

## 📧 Soporte

Si encuentras problemas con el sistema de deployment:
1. Revisa la sección de solución de problemas
2. Verifica logs de Flutter y backend
3. Consulta documentación de las herramientas

---

**Versión de este documento:** 1.0  
**Última actualización:** 2025-10-10  
**Sistema:** CRES Carnets - UAGro
