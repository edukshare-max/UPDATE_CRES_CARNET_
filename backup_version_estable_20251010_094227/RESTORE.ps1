# Script de Restauración Rápida
# Fecha de respaldo: 10 de Octubre, 2025 - 09:42:27
# Versión: v1.0-promociones-salud-stable

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESTAURACIÓN DE RESPALDO" -ForegroundColor Cyan
Write-Host "  Versión: Estable con Promociones de Salud" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
$currentDir = Get-Location
Write-Host "📂 Directorio actual: $currentDir" -ForegroundColor Yellow

# Preguntar confirmación
Write-Host "`n⚠️  ADVERTENCIA: Esta operación sobrescribirá los archivos actuales.`n" -ForegroundColor Red
$confirm = Read-Host "¿Desea continuar con la restauración? (S/N)"

if ($confirm -ne "S" -and $confirm -ne "s") {
    Write-Host "`n❌ Restauración cancelada.`n" -ForegroundColor Red
    exit
}

Write-Host "`n🔄 Iniciando restauración...`n" -ForegroundColor Green

# Definir rutas
$backupDir = "backup_version_estable_20251010_094227"
$projectRoot = "C:\CRES_Carnets_UAGROPRO"

# Crear respaldo de archivos actuales antes de restaurar
$preRestoreBackup = "pre_restore_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "📦 Creando respaldo preventivo: $preRestoreBackup" -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$projectRoot\$preRestoreBackup" -Force | Out-Null
Copy-Item -Path "$projectRoot\lib" -Destination "$projectRoot\$preRestoreBackup\lib" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$projectRoot\pubspec.yaml" -Destination "$projectRoot\$preRestoreBackup\" -Force -ErrorAction SilentlyContinue

# Restaurar archivos desde el respaldo
Write-Host "📥 Restaurando código Flutter..." -ForegroundColor Cyan
Copy-Item -Path "$projectRoot\$backupDir\lib" -Destination "$projectRoot\lib" -Recurse -Force
Copy-Item -Path "$projectRoot\$backupDir\pubspec.yaml" -Destination "$projectRoot\" -Force
Copy-Item -Path "$projectRoot\$backupDir\pubspec.lock" -Destination "$projectRoot\" -Force
Copy-Item -Path "$projectRoot\$backupDir\analysis_options.yaml" -Destination "$projectRoot\" -Force

Write-Host "📥 Restaurando backend..." -ForegroundColor Cyan
Copy-Item -Path "$projectRoot\$backupDir\temp_backend\*" -Destination "$projectRoot\temp_backend" -Recurse -Force

Write-Host "📥 Restaurando configuraciones de plataforma..." -ForegroundColor Cyan
Copy-Item -Path "$projectRoot\$backupDir\android" -Destination "$projectRoot\android" -Recurse -Force
Copy-Item -Path "$projectRoot\$backupDir\windows" -Destination "$projectRoot\windows" -Recurse -Force

Write-Host "`n✅ Restauración completada exitosamente!`n" -ForegroundColor Green

Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
Write-Host "   1. Ejecutar: flutter pub get" -ForegroundColor White
Write-Host "   2. Ejecutar: flutter clean (opcional)" -ForegroundColor White
Write-Host "   3. Ejecutar: flutter run -d windows`n" -ForegroundColor White

Write-Host "📚 Documentación: $projectRoot\$backupDir\VERSION_INFO.md`n" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
