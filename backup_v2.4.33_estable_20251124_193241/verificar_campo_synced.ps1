# verificar_campo_synced.ps1
# Verificar el estado del campo 'synced' en las notas antiguas

Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔍 VERIFICACIÓN DEL CAMPO SYNCED" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Cyan

$dbPath = "$env:USERPROFILE\Documents\cres_carnets.sqlite"

if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Base de datos no encontrada`n" -ForegroundColor Red
    exit 1
}

Write-Host "📊 ANÁLISIS DEL CAMPO SYNCED`n" -ForegroundColor Green

# Contar notas por valor de synced
Write-Host "Distribución de valores en campo 'synced':`n" -ForegroundColor White

$query1 = @"
SELECT 
    synced as 'Estado',
    COUNT(*) as 'Cantidad',
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM notes), 2) || '%' as 'Porcentaje'
FROM notes
GROUP BY synced
ORDER BY synced;
"@

sqlite3 -header -column $dbPath $query1

Write-Host "`n📝 PRIMERAS 10 NOTAS (ordenadas por fecha)`n" -ForegroundColor Cyan

$query2 = @"
SELECT 
    id,
    matricula,
    SUBSTR(departamento, 1, 15) as dept,
    SUBSTR(cuerpo, 1, 25) || '...' as nota,
    datetime(createdAt) as fecha,
    synced,
    CASE 
        WHEN synced IS NULL THEN '❌ NULL'
        WHEN synced = 0 THEN '⏳ Pendiente'
        WHEN synced = 1 THEN '✅ Sincronizada'
        ELSE '❓ Desconocido'
    END as estado_visual
FROM notes
ORDER BY createdAt ASC
LIMIT 10;
"@

sqlite3 -header -column $dbPath $query2

Write-Host "`n🔍 ANÁLISIS DETALLADO`n" -ForegroundColor Yellow

# Notas con synced NULL
$nullCount = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced IS NULL;"
if ($nullCount -gt 0) {
    Write-Host "  ❌ PROBLEMA CRÍTICO: Hay $nullCount notas con synced = NULL" -ForegroundColor Red
    Write-Host "     Estas notas NO serán detectadas por getPendingNotes()" -ForegroundColor Yellow
    Write-Host "     Solución: Ejecutar fix_synced_field.ps1`n" -ForegroundColor Green
} else {
    Write-Host "  ✅ No hay notas con synced = NULL`n" -ForegroundColor Green
}

# Notas con synced = 0
$pendingCount = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 0;"
if ($pendingCount -gt 0) {
    Write-Host "  ⏳ Hay $pendingCount notas pendientes de sincronización" -ForegroundColor Yellow
    Write-Host "     Estas DEBERÍAN sincronizarse automáticamente al login`n" -ForegroundColor White
}

# Notas con synced = 1
$syncedCount = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 1;"
if ($syncedCount -gt 0) {
    Write-Host "  ✅ Hay $syncedCount notas ya sincronizadas" -ForegroundColor Green
    Write-Host "     Estas pueden eliminarse con el limpiador 🧹`n" -ForegroundColor White
}

Write-Host "🧪 PRUEBA DE SINCRONIZACIÓN`n" -ForegroundColor Cyan

if ($pendingCount -gt 0) {
    Write-Host "Para probar si las notas pendientes se sincronizan:" -ForegroundColor White
    Write-Host "  1. Cierra la app si está abierta" -ForegroundColor Gray
    Write-Host "  2. Abre desde PowerShell:" -ForegroundColor Gray
    Write-Host "     cd '`$env:LOCALAPPDATA\CRES Carnets'" -ForegroundColor Gray
    Write-Host "     .\cres_carnets_ibmcloud.exe" -ForegroundColor Gray
    Write-Host "  3. Inicia sesión con INTERNET" -ForegroundColor Gray
    Write-Host "  4. Busca en consola:" -ForegroundColor Gray
    Write-Host "     📝 SyncService: $pendingCount notas pendientes para sincronizar" -ForegroundColor Gray
    Write-Host "     [SYNC] 📤 Enviando nota a servidor..." -ForegroundColor Gray
    Write-Host "  5. Si NO ves esos mensajes, el SyncService NO se ejecuta" -ForegroundColor Gray
    Write-Host "  6. Prueba el botón 🔄 manual en el dashboard`n" -ForegroundColor Gray
}

Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Cyan
