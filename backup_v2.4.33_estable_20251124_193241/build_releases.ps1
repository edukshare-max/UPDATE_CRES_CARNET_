# ================================
# CRES CARNETS - BUILD MANAGER
# ================================

Clear-Host
Write-Host "🏥 CRES CARNETS - GENERADOR DE RELEASES" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Plataformas disponibles:" -ForegroundColor Cyan
Write-Host "1. 🪟 Windows (Ejecutable .exe)"
Write-Host "2. 🤖 Android (APK/AAB)"
Write-Host "3. 🚀 Ambas plataformas"
Write-Host "4. ❌ Salir"
Write-Host ""

$choice = Read-Host "Selecciona una opción (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🪟 Construyendo release para Windows..." -ForegroundColor Yellow
        & ".\build_windows_release.ps1"
    }
    "2" {
        Write-Host ""
        Write-Host "🤖 Construyendo release para Android..." -ForegroundColor Yellow
        & ".\build_android_release.ps1"
    }
    "3" {
        Write-Host ""
        Write-Host "🚀 Construyendo releases para ambas plataformas..." -ForegroundColor Yellow
        Write-Host "Iniciando con Windows..." -ForegroundColor Cyan
        & ".\build_windows_release.ps1"
        
        Write-Host ""
        Write-Host "Continuando con Android..." -ForegroundColor Cyan
        & ".\build_android_release.ps1"
    }
    "4" {
        Write-Host "¡Hasta luego!" -ForegroundColor Green
        exit
    }
    default {
        Write-Host "❌ Opción inválida. Ejecuta el script nuevamente." -ForegroundColor Red
        pause
    }
}