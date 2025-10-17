# ================================
# CRES CARNETS - BUILD MANAGER
# ================================

Clear-Host
Write-Host "CRES CARNETS - GENERADOR DE RELEASES" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""

Write-Host "Plataformas disponibles:" -ForegroundColor Cyan
Write-Host "1. Windows (.exe)" -ForegroundColor Yellow
Write-Host "2. Android (APK + AAB)" -ForegroundColor Yellow
Write-Host "3. Ambas plataformas" -ForegroundColor Yellow
Write-Host ""

$opcion = Read-Host "Selecciona una opcion (1-3)"

# Validar la entrada
if ($opcion -notin @("1", "2", "3")) {
    Write-Host "Opcion invalida. Saliendo..." -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

try {
    Write-Host ""
    Write-Host "Iniciando proceso de build automatizado para CRES Carnets" -ForegroundColor Cyan
    Write-Host "Timestamp: $timestamp" -ForegroundColor Gray
    Write-Host ""
    
    switch ($opcion) {
        "1" {
            Write-Host "Construyendo release para Windows..." -ForegroundColor Yellow
            & .\build_windows_release_fixed.ps1 $timestamp
        }
        "2" {
            Write-Host "Construyendo releases para Android..." -ForegroundColor Yellow
            & .\build_android_release_fixed.ps1 $timestamp
        }
        "3" {
            Write-Host "Construyendo releases para todas las plataformas..." -ForegroundColor Yellow
            Write-Host ">> Iniciando build de Windows..." -ForegroundColor Cyan
            & .\build_windows_release_fixed.ps1 $timestamp
            Write-Host ""
            Write-Host ">> Iniciando build de Android..." -ForegroundColor Cyan
            & .\build_android_release_fixed.ps1 $timestamp
        }
    }
    
    Write-Host ""
    Write-Host "Process de build completado exitosamente!" -ForegroundColor Green
    Write-Host "Revisa la carpeta 'releases/' para tus archivos." -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Error durante el proceso de build:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
} finally {
    Write-Host ""
    Write-Host "Hasta luego!" -ForegroundColor Green
}