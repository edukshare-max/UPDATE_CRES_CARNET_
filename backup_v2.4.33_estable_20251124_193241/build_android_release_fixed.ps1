# =======================================
# CRES CARNETS - ANDROID RELEASE BUILDER
# =======================================

param(
    [string]$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
)

$apkFolder = "releases\android\apk\cres_carnets_android_apk_$timestamp"
$aabFolder = "releases\android\bundle\cres_carnets_android_aab_$timestamp"

Write-Host "Construyendo releases para Android..." -ForegroundColor Yellow
Write-Host "APK en: $apkFolder" -ForegroundColor Gray
Write-Host "AAB en: $aabFolder" -ForegroundColor Gray
Write-Host ""

# Crear estructura de directorios
Write-Host "Creando estructura de directorios..." -ForegroundColor Cyan
New-Item -Path $apkFolder -ItemType Directory -Force | Out-Null
New-Item -Path $aabFolder -ItemType Directory -Force | Out-Null

# Limpiar builds anteriores
Write-Host "Limpiando builds anteriores..." -ForegroundColor Cyan
flutter clean | Out-Null

# Construir APK
Write-Host "Construyendo APK..." -ForegroundColor Cyan
$apkResult = flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al compilar APK" -ForegroundColor Red
    exit 1
}

# Construir AAB
Write-Host "Construyendo App Bundle (AAB)..." -ForegroundColor Cyan
$aabResult = flutter build appbundle --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al compilar App Bundle" -ForegroundColor Red
    exit 1
}

# Copiar APK
if (Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
    Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "$apkFolder\cres_carnets_$timestamp.apk"
    Write-Host "APK copiado exitosamente" -ForegroundColor Green
} else {
    Write-Host "Error: No se encontro el APK compilado" -ForegroundColor Red
    exit 1
}

# Copiar AAB
if (Test-Path "build\app\outputs\bundle\release\app-release.aab") {
    Copy-Item -Path "build\app\outputs\bundle\release\app-release.aab" -Destination "$aabFolder\cres_carnets_$timestamp.aab"
    Write-Host "App Bundle copiado exitosamente" -ForegroundColor Green
} else {
    Write-Host "Error: No se encontro el App Bundle compilado" -ForegroundColor Red
    exit 1
}

# Crear README para APK
$apkReadme = @"
CRES CARNETS - RELEASE ANDROID APK
===================================

Version: $timestamp
Plataforma: Android
Formato: APK (Android Package)
Tipo: Release

INSTRUCCIONES DE INSTALACION:
1. Habilitar "Instalacion de fuentes desconocidas" en Android
2. Transferir el archivo APK al dispositivo
3. Instalar desde el explorador de archivos
4. Asegurar conexion a internet para sincronizacion

CONTENIDO:
- cres_carnets_$timestamp.apk

COMPATIBILIDAD:
- Android 5.0+ (API 21+)
- Arquitecturas: arm64-v8a, armeabi-v7a, x86_64

Para soporte tecnico, contactar al equipo de desarrollo.
"@

$apkReadme | Out-File -FilePath "$apkFolder\README.txt" -Encoding UTF8

# Crear README para AAB
$aabReadme = @"
CRES CARNETS - RELEASE ANDROID AAB
===================================

Version: $timestamp
Plataforma: Android
Formato: AAB (Android App Bundle)
Tipo: Release

INSTRUCCIONES DE DISTRIBUCION:
1. Subir a Google Play Console
2. Google Play genera APKs optimizados automaticamente
3. Distribucion via Google Play Store

CONTENIDO:
- cres_carnets_$timestamp.aab

VENTAJAS DEL AAB:
- Tamaño de descarga reducido
- Optimizacion por dispositivo
- Entrega dinamica de funciones

Para soporte tecnico, contactar al equipo de desarrollo.
"@

$aabReadme | Out-File -FilePath "$aabFolder\README.txt" -Encoding UTF8

# Mostrar resumen
Write-Host ""
Write-Host "Releases de Android completados exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "APK Release:" -ForegroundColor Cyan
Write-Host "  Ubicacion: $apkFolder" -ForegroundColor Green
Write-Host "  Archivo: cres_carnets_$timestamp.apk" -ForegroundColor Green

Write-Host ""
Write-Host "AAB Release:" -ForegroundColor Cyan
Write-Host "  Ubicacion: $aabFolder" -ForegroundColor Green
Write-Host "  Archivo: cres_carnets_$timestamp.aab" -ForegroundColor Green

# Obtener tamaños
if (Test-Path "$apkFolder\cres_carnets_$timestamp.apk") {
    $apkSize = (Get-Item "$apkFolder\cres_carnets_$timestamp.apk").Length
    $apkSizeMB = [Math]::Round($apkSize / 1MB, 2)
    Write-Host "  Tamaño APK: $apkSizeMB MB" -ForegroundColor Gray
}

if (Test-Path "$aabFolder\cres_carnets_$timestamp.aab") {
    $aabSize = (Get-Item "$aabFolder\cres_carnets_$timestamp.aab").Length
    $aabSizeMB = [Math]::Round($aabSize / 1MB, 2)
    Write-Host "  Tamaño AAB: $aabSizeMB MB" -ForegroundColor Gray
}

Write-Host ""