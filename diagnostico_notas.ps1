# diagnostico_notas.ps1
# Script para diagnosticar el estado de sincronización de notas

Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔍 DIAGNÓSTICO DE NOTAS - v2.4.10" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Cyan

$dbPath = "$env:USERPROFILE\Documents\cres_carnets.sqlite"

if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Base de datos no encontrada en:" -ForegroundColor Red
    Write-Host "   $dbPath`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "📊 ESTADÍSTICAS DE NOTAS`n" -ForegroundColor Green

# Total de notas
$total = sqlite3 $dbPath "SELECT COUNT(*) FROM notes;"
Write-Host "  Total de notas: $total" -ForegroundColor White

# Notas sincronizadas
$sincronizadas = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 1;"
Write-Host "  ✅ Sincronizadas: $sincronizadas" -ForegroundColor Green

# Notas pendientes
$pendientes = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 0;"
Write-Host "  ⏳ Pendientes: $pendientes" -ForegroundColor Yellow

Write-Host "`n📝 DETALLES DE NOTAS PENDIENTES`n" -ForegroundColor Cyan

if ($pendientes -gt 0) {
    Write-Host "  Las siguientes notas AÚN NO han sido sincronizadas:`n" -ForegroundColor Yellow
    
    $query = @"
SELECT 
    id,
    matricula,
    departamento,
    SUBSTR(cuerpo, 1, 30) || '...' as preview,
    datetime(createdAt) as fecha,
    synced
FROM notes 
WHERE synced = 0
ORDER BY createdAt DESC
LIMIT 10;
"@
    
    sqlite3 -header -column $dbPath $query
    
    if ($pendientes -gt 10) {
        Write-Host "`n  ... y $($pendientes - 10) notas más`n" -ForegroundColor Gray
    }
    
    Write-Host "`n⚠️  IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "  Las notas pendientes NO desaparecen automáticamente" -ForegroundColor White
    Write-Host "  Solo se marcan como 'sincronizadas' después de subirse" -ForegroundColor White
    Write-Host "  Para eliminarlas, usa el botón 🧹 DESPUÉS de sincronizar`n" -ForegroundColor White
    
} else {
    Write-Host "  ✅ Todas las notas están sincronizadas!`n" -ForegroundColor Green
}

Write-Host "📋 ÚLTIMAS 5 NOTAS (TODAS)`n" -ForegroundColor Cyan

$query2 = @"
SELECT 
    id,
    matricula,
    departamento,
    SUBSTR(cuerpo, 1, 40) || '...' as contenido,
    datetime(createdAt) as fecha,
    CASE WHEN synced = 1 THEN '✅' ELSE '⏳' END as estado
FROM notes 
ORDER BY createdAt DESC
LIMIT 5;
"@

sqlite3 -header -column $dbPath $query2

Write-Host "`n🔍 VERIFICAR EN LA NUBE`n" -ForegroundColor Cyan
Write-Host "  Para verificar si las notas están en el servidor:" -ForegroundColor White
Write-Host "  1. Abre la app y ve a 'Nueva Nota'" -ForegroundColor Gray
Write-Host "  2. Busca una matrícula que tenga notas pendientes" -ForegroundColor Gray
Write-Host "  3. Observa la sección 'Notas en nube'" -ForegroundColor Gray
Write-Host "  4. Si aparecen allí, la sincronización funcionó" -ForegroundColor Gray
Write-Host "  5. Si NO aparecen, hay un problema`n" -ForegroundColor Gray

Write-Host "🧪 PROBAR SINCRONIZACIÓN MANUAL`n" -ForegroundColor Yellow
Write-Host "  Si las notas siguen pendientes:" -ForegroundColor White
Write-Host "  1. Abre la app desde PowerShell (para ver logs):" -ForegroundColor Gray
Write-Host "     cd '`$env:LOCALAPPDATA\CRES Carnets'" -ForegroundColor Gray
Write-Host "     .\cres_carnets_ibmcloud.exe" -ForegroundColor Gray
Write-Host "  2. Inicia sesión con INTERNET" -ForegroundColor Gray
Write-Host "  3. Click en botón 🔄 (sincronizar)" -ForegroundColor Gray
Write-Host "  4. Observa los logs:" -ForegroundColor Gray
Write-Host "     [SYNC] 📤 Enviando nota a servidor..." -ForegroundColor Gray
Write-Host "     [SYNC] ✅ Nota sincronizada exitosamente" -ForegroundColor Gray
Write-Host "  5. Vuelve a ejecutar este script para verificar`n" -ForegroundColor Gray

Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Cyan
