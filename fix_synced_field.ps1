# fix_synced_field.ps1
# Arregla notas antiguas que no tienen el campo synced configurado correctamente

Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 FIX: Campo SYNCED en Notas Antiguas" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Cyan

$dbPath = "$env:USERPROFILE\Documents\cres_carnets.sqlite"

if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Base de datos no encontrada`n" -ForegroundColor Red
    exit 1
}

Write-Host "⚠️  ADVERTENCIA:" -ForegroundColor Yellow
Write-Host "   Este script modificará la base de datos" -ForegroundColor White
Write-Host "   Se creará un respaldo antes de continuar`n" -ForegroundColor White

# Crear respaldo
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "$env:USERPROFILE\Documents\cres_carnets_backup_$timestamp.sqlite"

Write-Host "📦 Creando respaldo..." -ForegroundColor Cyan
Copy-Item $dbPath $backupPath
Write-Host "   ✅ Respaldo creado: cres_carnets_backup_$timestamp.sqlite`n" -ForegroundColor Green

# Verificar problema
$nullCount = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced IS NULL;"
$totalNotes = sqlite3 $dbPath "SELECT COUNT(*) FROM notes;"

Write-Host "📊 Estado actual:" -ForegroundColor Cyan
Write-Host "   Total de notas: $totalNotes" -ForegroundColor White
Write-Host "   Notas con synced = NULL: $nullCount`n" -ForegroundColor Yellow

if ($nullCount -eq 0) {
    Write-Host "✅ No hay notas con synced = NULL" -ForegroundColor Green
    Write-Host "   No se requiere ninguna corrección`n" -ForegroundColor White
    exit 0
}

Write-Host "🔧 Aplicando corrección..." -ForegroundColor Yellow
Write-Host "   Marcando $nullCount notas como 'pendientes de sincronización'`n" -ForegroundColor White

# Actualizar notas con synced NULL a synced = 0 (pendiente)
$updateQuery = "UPDATE notes SET synced = 0 WHERE synced IS NULL;"
sqlite3 $dbPath $updateQuery

# Verificar resultado
$nullCountAfter = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced IS NULL;"
$pendingCount = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 0;"

if ($nullCountAfter -eq 0) {
    Write-Host "✅ CORRECCIÓN EXITOSA!" -ForegroundColor Green
    Write-Host "   Notas con synced = NULL: $nullCountAfter" -ForegroundColor Green
    Write-Host "   Notas pendientes de sync: $pendingCount`n" -ForegroundColor Yellow
    
    Write-Host "📋 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "   1. Abre la app desde PowerShell (para ver logs)" -ForegroundColor White
    Write-Host "   2. Inicia sesión con INTERNET" -ForegroundColor White
    Write-Host "   3. La sincronización automática debe procesar $pendingCount notas" -ForegroundColor White
    Write-Host "   4. O usa el botón 🔄 para sincronización manual`n" -ForegroundColor White
    
} else {
    Write-Host "❌ ERROR: Aún hay $nullCountAfter notas con synced = NULL" -ForegroundColor Red
    Write-Host "   Restaurando desde respaldo..." -ForegroundColor Yellow
    Copy-Item $backupPath $dbPath -Force
    Write-Host "   Base de datos restaurada`n" -ForegroundColor Green
}

Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Cyan
