# ================================
# CRES CARNETS - BUILD AUTOMATICO
# ================================

param(
    [string]$plataforma = "ambas"
)

Clear-Host
Write-Host "CRES CARNETS - GENERADOR DE RELEASES AUTOMATICO" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

try {
    Write-Host "Iniciando proceso de build automatizado para CRES Carnets" -ForegroundColor Cyan
    Write-Host "Timestamp: $timestamp" -ForegroundColor Gray
    Write-Host "Plataforma: $plataforma" -ForegroundColor Gray
    Write-Host ""
    
    if ($plataforma -eq "windows" -or $plataforma -eq "ambas") {
        Write-Host ">> Iniciando build de Windows..." -ForegroundColor Cyan
        & .\build_windows_release_fixed.ps1 $timestamp
        Write-Host ""
    }
    
    if ($plataforma -eq "android" -or $plataforma -eq "ambas") {
        Write-Host ">> Iniciando build de Android..." -ForegroundColor Cyan
        & .\build_android_release_fixed.ps1 $timestamp
        Write-Host ""
    }
    
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