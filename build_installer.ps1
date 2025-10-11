# ====================================================================
# Script para generar instalador de CRES Carnets
# ====================================================================

param(
    [switch]$SkipBuild,
    [switch]$OpenFolder
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "🚀 GENERADOR DE INSTALADOR - CRES Carnets UAGro" -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: Debe ejecutar este script desde la raíz del proyecto" -ForegroundColor Red
    exit 1
}

# Leer versión actual
$versionFile = Get-Content "version.json" | ConvertFrom-Json
$version = $versionFile.version
Write-Host "📌 Versión actual: $version" -ForegroundColor Cyan

# Paso 1: Build de la aplicación Flutter
if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "📦 Paso 1/4: Compilando aplicación Flutter (Release)..." -ForegroundColor Yellow
    Write-Host "   Esto puede tomar varios minutos..." -ForegroundColor Gray
    
    flutter clean | Out-Null
    flutter pub get | Out-Null
    
    $buildOutput = flutter build windows --release 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error en la compilación de Flutter" -ForegroundColor Red
        Write-Host $buildOutput -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "   ✅ Compilación exitosa" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⏭️  Paso 1/4: Omitiendo compilación (usando build existente)" -ForegroundColor Yellow
}

# Paso 2: Verificar que existe el build
Write-Host ""
Write-Host "🔍 Paso 2/4: Verificando archivos..." -ForegroundColor Yellow

$exePath = "build\windows\x64\runner\Release\cres_carnets_ibmcloud.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "❌ Error: No se encontró el ejecutable compilado" -ForegroundColor Red
    Write-Host "   Ruta esperada: $exePath" -ForegroundColor Gray
    exit 1
}

$exeSize = (Get-Item $exePath).Length / 1MB
Write-Host "   ✅ Ejecutable encontrado ($([math]::Round($exeSize, 2)) MB)" -ForegroundColor Green

# Verificar Inno Setup
$innoPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $innoPath)) {
    Write-Host ""
    Write-Host "❌ Error: Inno Setup no está instalado" -ForegroundColor Red
    Write-Host ""
    Write-Host "📥 Descarga e instala Inno Setup 6:" -ForegroundColor Yellow
    Write-Host "   https://jrsoftware.org/isdl.php" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Después de instalar, vuelve a ejecutar este script." -ForegroundColor Gray
    exit 1
}

Write-Host "   ✅ Inno Setup encontrado" -ForegroundColor Green

# Paso 3: Crear directorio de salida
Write-Host ""
Write-Host "📁 Paso 3/4: Preparando directorio de salida..." -ForegroundColor Yellow

$outputDir = "releases\installers"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "   ✅ Directorio listo: $outputDir" -ForegroundColor Green

# Paso 4: Generar instalador con Inno Setup
Write-Host ""
Write-Host "🔨 Paso 4/4: Generando instalador..." -ForegroundColor Yellow
Write-Host "   Esto puede tomar 1-2 minutos..." -ForegroundColor Gray

$scriptPath = "installer\setup_script.iss"
$innoOutput = & $innoPath $scriptPath 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al generar el instalador" -ForegroundColor Red
    Write-Host $innoOutput -ForegroundColor Gray
    exit 1
}

Write-Host "   ✅ Instalador generado exitosamente" -ForegroundColor Green

# Verificar el instalador generado
$installerName = "CRES_Carnets_Setup_v$version.exe"
$installerPath = Join-Path $outputDir $installerName

if (Test-Path $installerPath) {
    $installerSize = (Get-Item $installerPath).Length / 1MB
    
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "✅ INSTALADOR CREADO EXITOSAMENTE" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Archivo: $installerName" -ForegroundColor Cyan
    Write-Host "📏 Tamaño: $([math]::Round($installerSize, 2)) MB" -ForegroundColor Cyan
    Write-Host "📁 Ubicación: $(Resolve-Path $installerPath)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎯 Próximos pasos:" -ForegroundColor Yellow
    Write-Host "   1. Prueba el instalador en otra computadora" -ForegroundColor Gray
    Write-Host "   2. Distribuye el archivo .exe a tus compañeros" -ForegroundColor Gray
    Write-Host "   3. Los usuarios solo necesitan ejecutar el instalador" -ForegroundColor Gray
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Green
    
    # Abrir carpeta si se solicitó
    if ($OpenFolder) {
        Write-Host ""
        Write-Host "📂 Abriendo carpeta de salida..." -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList (Resolve-Path $outputDir)
    }
    
} else {
    Write-Host ""
    Write-Host "❌ Error: El instalador no se generó correctamente" -ForegroundColor Red
    exit 1
}

Write-Host ""
