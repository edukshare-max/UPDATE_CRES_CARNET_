<#
.SYNOPSIS
    Script maestro de deployment - Automatiza todo el proceso de liberación

.DESCRIPTION
    Este script realiza TODOS los pasos necesarios para liberar una nueva versión:
    1. Incrementa la versión (Major, Minor o Patch)
    2. Build de release (Flutter)
    3. Genera instalador (Inno Setup)
    4. Calcula checksum SHA256
    5. Sube a GitHub Releases
    6. Actualiza backend (update_routes.py)
    7. Git commit + tag + push

.PARAMETER Major
    Incrementa versión major (1.0.0 -> 2.0.0)

.PARAMETER Minor
    Incrementa versión minor (1.0.0 -> 1.1.0)

.PARAMETER Patch
    Incrementa versión patch (1.0.0 -> 1.0.1)

.PARAMETER Message
    Mensaje de changelog para esta versión (opcional, se pedirá si no se proporciona)

.PARAMETER SkipUpload
    No sube a GitHub Releases (útil para testing)

.PARAMETER SkipBackend
    No actualiza el backend (útil para testing)

.EXAMPLE
    .\deploy.ps1 -Patch
    Incrementa versión patch y despliega todo automáticamente

.EXAMPLE
    .\deploy.ps1 -Minor -Message "Nueva funcionalidad de reportes"
    Incrementa versión minor con mensaje personalizado

.EXAMPLE
    .\deploy.ps1 -Patch -SkipUpload
    Solo genera instalador sin subirlo (para testing)
#>

param(
    [switch]$Major,
    [switch]$Minor,
    [switch]$Patch,
    [string]$Message,
    [switch]$SkipUpload,
    [switch]$SkipBackend
)

# Colores y símbolos
$symbols = @{
    Check = [char]0x2713
    Cross = [char]0x2717
    Arrow = [char]0x2192
    Bullet = [char]0x2022
}

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "`n$($symbols.Arrow) $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "  $($symbols.Check) $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "  $($symbols.Cross) $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $($symbols.Bullet) $Message" -ForegroundColor Gray
}

# Banner inicial
Write-Host "`n" -NoNewline
Write-Host "============================================================" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host "  🚀 DEPLOYMENT AUTOMATIZADO - CRES Carnets" -ForegroundColor Yellow -BackgroundColor DarkGreen
Write-Host "============================================================" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host ""

# Validar parámetros
if (-not ($Major -or $Minor -or $Patch)) {
    Write-Error-Custom "Debe especificar -Major, -Minor o -Patch"
    Write-Host "`nEjemplos:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1 -Patch" -ForegroundColor White
    Write-Host "  .\deploy.ps1 -Minor -Message `"Nueva funcionalidad`"" -ForegroundColor White
    Write-Host "  .\deploy.ps1 -Major" -ForegroundColor White
    exit 1
}

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error-Custom "No se encuentra pubspec.yaml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
}

# Verificar herramientas necesarias
Write-Step "Verificando herramientas..."

$tools_ok = $true

# Flutter
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Success "Flutter instalado"
} else {
    Write-Error-Custom "Flutter no encontrado"
    $tools_ok = $false
}

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Success "Git instalado"
} else {
    Write-Error-Custom "Git no encontrado"
    $tools_ok = $false
}

# Inno Setup
$innoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path $innoSetupPath) {
    Write-Success "Inno Setup encontrado"
} else {
    Write-Error-Custom "Inno Setup no encontrado en: $innoSetupPath"
    $tools_ok = $false
}

if (-not $tools_ok) {
    Write-Host "`n❌ Faltan herramientas necesarias. Instala las herramientas faltantes." -ForegroundColor Red
    exit 1
}

# Verificar estado de Git
Write-Step "Verificando estado de Git..."

$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "`n⚠️  Tienes cambios sin commitear:" -ForegroundColor Yellow
    Write-Host $gitStatus -ForegroundColor Gray
    
    $continue = Read-Host "`n¿Deseas continuar de todos modos? (s/N)"
    if ($continue -ne "s") {
        Write-Host "`nDeployment cancelado." -ForegroundColor Yellow
        exit 0
    }
}

# PASO 1: Incrementar versión
Write-Step "PASO 1/7: Incrementando versión..." "Yellow"

$versionArgs = @()
if ($Major) { $versionArgs += "-Major" }
if ($Minor) { $versionArgs += "-Minor" }
if ($Patch) { $versionArgs += "-Patch" }

# Solicitar mensaje si no se proporcionó
if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = Read-Host "`nIngresa el mensaje de changelog para esta versión"
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "Actualización de versión"
    }
}

$versionArgs += "-Message"
$versionArgs += $Message

Write-Info "Ejecutando: .\update_version.ps1 $versionArgs"

try {
    & .\update_version.ps1 @versionArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Error al actualizar versión"
    }
    Write-Success "Versión actualizada exitosamente"
} catch {
    Write-Error-Custom "Error: $_"
    exit 1
}

# Leer nueva versión
$versionJson = Get-Content "assets\version.json" -Raw | ConvertFrom-Json
$newVersion = $versionJson.version
$buildNumber = $versionJson.build_number
$releaseDate = $versionJson.release_date

Write-Host "`n  📦 Nueva versión: $newVersion (Build $buildNumber)" -ForegroundColor Cyan
Write-Host "  📅 Fecha: $releaseDate" -ForegroundColor Gray

# PASO 2: Build de release
Write-Step "PASO 2/7: Compilando versión de release..." "Yellow"

Write-Info "Limpiando build anterior..."
flutter clean | Out-Null

Write-Info "Obteniendo dependencias..."
flutter pub get | Out-Null

Write-Info "Compilando para Windows (esto puede tardar)..."
$buildOutput = flutter build windows --release 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Error al compilar:"
    Write-Host $buildOutput -ForegroundColor Red
    exit 1
}

Write-Success "Build de release completado"

# PASO 3: Generar instalador
Write-Step "PASO 3/7: Generando instalador con Inno Setup..." "Yellow"

if (-not (Test-Path "installer_config.iss")) {
    Write-Error-Custom "No se encuentra installer_config.iss"
    exit 1
}

Write-Info "Ejecutando Inno Setup..."

try {
    & $innoSetupPath "installer_config.iss" /Q
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup falló con código: $LASTEXITCODE"
    }
    Write-Success "Instalador generado"
} catch {
    Write-Error-Custom "Error: $_"
    exit 1
}

# Buscar el instalador generado
$installerPattern = "releases\CRES_Carnets_Setup_v$newVersion.exe"
$installerPath = Get-ChildItem -Path "releases" -Filter "CRES_Carnets_Setup_v*.exe" | 
                 Sort-Object LastWriteTime -Descending | 
                 Select-Object -First 1

if (-not $installerPath) {
    Write-Error-Custom "No se encontró el instalador generado"
    exit 1
}

Write-Info "Instalador: $($installerPath.Name)"
$installerSize = [math]::Round($installerPath.Length / 1MB, 2)
Write-Info "Tamaño: $installerSize MB"

# PASO 4: Calcular checksum SHA256
Write-Step "PASO 4/7: Calculando checksum SHA256..." "Yellow"

try {
    $hash = Get-FileHash -Path $installerPath.FullName -Algorithm SHA256
    $checksum = $hash.Hash.ToLower()
    Write-Success "Checksum: $checksum"
} catch {
    Write-Error-Custom "Error al calcular checksum: $_"
    exit 1
}

# PASO 5: Subir a GitHub Releases (opcional)
if (-not $SkipUpload) {
    Write-Step "PASO 5/7: Subiendo a GitHub Releases..." "Yellow"
    
    # Verificar gh CLI
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        Write-Info "Creando release v$newVersion..."
        
        $releaseNotes = @"
## 🎉 CRES Carnets v$newVersion

**Fecha de liberación:** $releaseDate
**Build:** $buildNumber

### 📋 Cambios en esta versión:
$Message

### 📥 Instalación:
1. Descarga el instalador
2. Ejecuta CRES_Carnets_Setup_v$newVersion.exe
3. Sigue el asistente de instalación

### 🔐 Verificación:
- **SHA256:** ``$checksum``
- **Tamaño:** $installerSize MB

### ℹ️ Información:
- **Backend:** https://fastapi-backend-o7ks.onrender.com
- **Documentación:** Ver README.md
"@

        try {
            # Crear release
            gh release create "v$newVersion" `
                --title "v$newVersion" `
                --notes $releaseNotes `
                $installerPath.FullName
            
            Write-Success "Release creado en GitHub"
            
            # Obtener URL de descarga
            $downloadUrl = "https://github.com/edukshare-max/fastapi-backend/releases/download/v$newVersion/$($installerPath.Name)"
            Write-Info "URL: $downloadUrl"
            
        } catch {
            Write-Error-Custom "Error al crear release: $_"
            Write-Host "`n⚠️  Continúa sin upload..." -ForegroundColor Yellow
            $downloadUrl = "https://github.com/edukshare-max/fastapi-backend/releases/download/v$newVersion/$($installerPath.Name)"
        }
    } else {
        Write-Host "  ⚠️  GitHub CLI (gh) no instalado. Saltando upload..." -ForegroundColor Yellow
        Write-Info "Instala con: winget install GitHub.cli"
        $downloadUrl = "https://github.com/edukshare-max/fastapi-backend/releases/download/v$newVersion/$($installerPath.Name)"
    }
} else {
    Write-Step "PASO 5/7: Upload omitido (-SkipUpload)" "Gray"
    $downloadUrl = "https://github.com/edukshare-max/fastapi-backend/releases/download/v$newVersion/$($installerPath.Name)"
}

# PASO 6: Actualizar backend
if (-not $SkipBackend) {
    Write-Step "PASO 6/7: Actualizando backend (update_routes.py)..." "Yellow"
    
    $updateRoutesPath = "temp_backend\update_routes.py"
    
    if (Test-Path $updateRoutesPath) {
        try {
            $content = Get-Content $updateRoutesPath -Raw
            
            # Actualizar LATEST_VERSION
            $newVersionBlock = @"
LATEST_VERSION = VersionInfo(
    version="$newVersion",
    build_number=$buildNumber,
    release_date="$releaseDate",
    download_url="$downloadUrl",
    file_size=$($installerPath.Length),
    checksum="$checksum",
    is_mandatory=False,
    changelog=[
        "$Message"
    ]
)
"@
            
            # Reemplazar el bloque LATEST_VERSION
            $pattern = 'LATEST_VERSION = VersionInfo\([^)]+\)'
            $content = $content -replace $pattern, $newVersionBlock
            
            # Guardar
            Set-Content $updateRoutesPath -Value $content -NoNewline
            
            Write-Success "Backend actualizado con nueva versión"
            Write-Info "Versión: $newVersion"
            Write-Info "Checksum: $checksum"
            Write-Info "URL: $downloadUrl"
            
        } catch {
            Write-Error-Custom "Error al actualizar backend: $_"
            Write-Host "`n⚠️  Continúa sin actualizar backend..." -ForegroundColor Yellow
        }
    } else {
        Write-Error-Custom "No se encuentra $updateRoutesPath"
    }
} else {
    Write-Step "PASO 6/7: Actualización de backend omitida (-SkipBackend)" "Gray"
}

# PASO 7: Git commit y tag
Write-Step "PASO 7/7: Git commit, tag y push..." "Yellow"

try {
    # Add
    git add assets/version.json
    git add pubspec.yaml
    git add temp_backend/update_routes.py -ErrorAction SilentlyContinue
    git add $installerPath.FullName -ErrorAction SilentlyContinue
    
    # Commit
    $commitMsg = "🚀 Release v$newVersion`n`n$Message`n`nBuild: $buildNumber`nFecha: $releaseDate`nChecksum: $checksum"
    git commit -m $commitMsg
    
    Write-Success "Commit creado"
    
    # Tag
    git tag -a "v$newVersion" -m "Versión $newVersion - $Message"
    Write-Success "Tag v$newVersion creado"
    
    # Push
    $push = Read-Host "`n¿Hacer push a GitHub? (S/n)"
    if ($push -ne "n") {
        git push origin main
        git push origin "v$newVersion"
        Write-Success "Push completado"
    } else {
        Write-Info "Push omitido (manual)"
    }
    
} catch {
    Write-Error-Custom "Error en git: $_"
    Write-Host "`n⚠️  Verifica git status manualmente" -ForegroundColor Yellow
}

# Resumen final
Write-Host "`n" -NoNewline
Write-Host "============================================================" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host "  ✅ DEPLOYMENT COMPLETADO EXITOSAMENTE" -ForegroundColor Yellow -BackgroundColor DarkGreen
Write-Host "============================================================" -ForegroundColor Green -BackgroundColor DarkGreen

Write-Host "`n📦 RESUMEN:" -ForegroundColor Cyan
Write-Host "  Versión:    $newVersion (Build $buildNumber)" -ForegroundColor White
Write-Host "  Fecha:      $releaseDate" -ForegroundColor White
Write-Host "  Instalador: $($installerPath.Name)" -ForegroundColor White
Write-Host "  Tamaño:     $installerSize MB" -ForegroundColor White
Write-Host "  Checksum:   $checksum" -ForegroundColor White

if (-not $SkipUpload) {
    Write-Host "`n🌐 DESCARGA:" -ForegroundColor Cyan
    Write-Host "  $downloadUrl" -ForegroundColor White
}

Write-Host "`n📋 PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host "  1. Verifica que el backend se actualizó en Render" -ForegroundColor White
Write-Host "  2. Prueba la actualización desde la app" -ForegroundColor White
Write-Host "  3. Distribuye el instalador a los usuarios" -ForegroundColor White

Write-Host "`n============================================================`n" -ForegroundColor Green
