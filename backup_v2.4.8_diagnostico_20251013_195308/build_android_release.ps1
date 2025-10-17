# ================================
# BUILD ANDROID RELEASE - CRES Carnets
# ================================

Write-Host "🤖 Iniciando build de Android Release..." -ForegroundColor Green

# Limpiar builds previos
Write-Host "🧹 Limpiando builds previos..." -ForegroundColor Yellow
flutter clean

# Obtener dependencias
Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

# Crear timestamp para nombrar archivos
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host ""
Write-Host "📱 Selecciona el tipo de build de Android:" -ForegroundColor Cyan
Write-Host "1. APK (para instalación directa)"
Write-Host "2. AAB (para Google Play Store)"
Write-Host "3. Ambos"
Write-Host ""
$choice = Read-Host "Ingresa tu opción (1, 2, o 3)"

$buildApk = $false
$buildAab = $false

switch ($choice) {
    "1" { $buildApk = $true }
    "2" { $buildAab = $true }
    "3" { $buildApk = $true; $buildAab = $true }
    default { $buildApk = $true; Write-Host "Opción inválida, construyendo APK por defecto" -ForegroundColor Yellow }
}

# Build APK
if ($buildApk) {
    Write-Host "🔨 Compilando APK para Android..." -ForegroundColor Yellow
    flutter build apk --release
    
    if (Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
        $apkDest = "releases\android\apk\CRES_Carnets_$timestamp.apk"
        Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination $apkDest
        Write-Host "✅ APK copiado a: $apkDest" -ForegroundColor Green
    } else {
        Write-Host "❌ Error al crear APK" -ForegroundColor Red
    }
}

# Build AAB
if ($buildAab) {
    Write-Host "🔨 Compilando AAB para Android..." -ForegroundColor Yellow
    flutter build appbundle --release
    
    if (Test-Path "build\app\outputs\bundle\release\app-release.aab") {
        $aabDest = "releases\android\bundle\CRES_Carnets_$timestamp.aab"
        Copy-Item "build\app\outputs\bundle\release\app-release.aab" -Destination $aabDest
        Write-Host "✅ AAB copiado a: $aabDest" -ForegroundColor Green
    } else {
        Write-Host "❌ Error al crear AAB" -ForegroundColor Red
    }
}

# Crear archivo de información
$infoContent = @"
CRES Carnets - Android Release
==============================
Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Versión: Android
Build: Release

Archivos generados:
"@

if ($buildApk -and (Test-Path "releases\android\apk\CRES_Carnets_$timestamp.apk")) {
    $infoContent += "`n- APK: CRES_Carnets_$timestamp.apk (para instalación directa)"
}

if ($buildAab -and (Test-Path "releases\android\bundle\CRES_Carnets_$timestamp.aab")) {
    $infoContent += "`n- AAB: CRES_Carnets_$timestamp.aab (para Google Play Store)"
}

$infoContent += @"

Instrucciones APK:
1. Transferir archivo APK al dispositivo Android
2. Habilitar "Fuentes desconocidas" en configuración
3. Instalar APK
4. Asegurar conexión a internet para sincronización

Instrucciones AAB:
1. Subir archivo AAB a Google Play Console
2. Seguir proceso de publicación de Google Play

Requisitos del dispositivo:
- Android 5.0 (API level 21) o superior
- Conexión a internet para sincronización con la nube
"@

$infoContent | Out-File -FilePath "releases\android\CRES_Carnets_Android_$timestamp.txt" -Encoding UTF8

# Mostrar resumen
Write-Host ""
Write-Host "✨ RELEASE ANDROID COMPLETADO ✨" -ForegroundColor Green
Write-Host "📂 Ubicación: releases\android\" -ForegroundColor Cyan

if ($buildApk) {
    Write-Host "📱 APK: releases\android\apk\CRES_Carnets_$timestamp.apk" -ForegroundColor Cyan
}

if ($buildAab) {
    Write-Host "📦 AAB: releases\android\bundle\CRES_Carnets_$timestamp.aab" -ForegroundColor Cyan
}

Write-Host "📄 Info: releases\android\CRES_Carnets_Android_$timestamp.txt" -ForegroundColor Cyan

# Abrir carpeta
Write-Host "🔍 Abriendo carpeta de releases..." -ForegroundColor Yellow
Start-Process "explorer.exe" -ArgumentList (Resolve-Path "releases\android")

Write-Host ""
Write-Host "Presiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")