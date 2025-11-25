# ================================
# BUILD WINDOWS RELEASE - CRES Carnets
# ================================

Write-Host "🚀 Iniciando build de Windows Release..." -ForegroundColor Green

# Limpiar builds previos
Write-Host "🧹 Limpiando builds previos..." -ForegroundColor Yellow
flutter clean

# Obtener dependencias
Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

# Crear build de Windows
Write-Host "🔨 Compilando para Windows..." -ForegroundColor Yellow
flutter build windows --release

# Verificar que el build existe
$buildPath = "build\windows\x64\runner\Release\cres_carnets_ibmcloud.exe"
if (Test-Path $buildPath) {
    Write-Host "✅ Build de Windows completado exitosamente!" -ForegroundColor Green
    
    # Crear carpeta con timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $releaseFolder = "releases\windows\CRES_Carnets_Windows_$timestamp"
    
    Write-Host "📁 Creando release en: $releaseFolder" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $releaseFolder -Force | Out-Null
    
    # Copiar ejecutable y dependencias
    Copy-Item "build\windows\x64\runner\Release\*" -Destination $releaseFolder -Recurse -Force
    
    # Crear archivo de información
    $infoContent = @"
CRES Carnets - Windows Release
==============================
Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Versión: Windows x64
Build: Release

Instrucciones:
1. Ejecutar cres_carnets_ibmcloud.exe
2. Asegurar conexión a internet para sincronización

Dependencias incluidas:
- flutter_windows.dll
- Plugins de Windows
- Datos de la aplicación
"@
    
    $infoContent | Out-File -FilePath "$releaseFolder\README.txt" -Encoding UTF8
    
    # Mostrar resumen
    Write-Host ""
    Write-Host "✨ RELEASE WINDOWS COMPLETADO ✨" -ForegroundColor Green
    Write-Host "📂 Ubicación: $releaseFolder" -ForegroundColor Cyan
    Write-Host "📦 Ejecutable: cres_carnets_ibmcloud.exe" -ForegroundColor Cyan
    Write-Host "📄 Info: README.txt" -ForegroundColor Cyan
    
    # Abrir carpeta
    Write-Host "🔍 Abriendo carpeta de release..." -ForegroundColor Yellow
    Start-Process "explorer.exe" -ArgumentList (Resolve-Path $releaseFolder)
    
} else {
    Write-Host "❌ Error: No se pudo completar el build de Windows" -ForegroundColor Red
    Write-Host "Revisa los errores anteriores" -ForegroundColor Red
}

Write-Host ""
Write-Host "Presiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")