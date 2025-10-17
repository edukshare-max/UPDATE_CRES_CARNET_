# test_sync_v2.4.9.ps1
# Script para probar sincronización de v2.4.9

Write-Host "
=== PRUEBA DE SINCRONIZACIÓN v2.4.9 ===" -ForegroundColor Cyan

# Verificar notas pendientes ANTES
Write-Host "
1️⃣  Verificando notas pendientes ANTES del login..." -ForegroundColor Yellow
$dbPath = "$env:USERPROFILE\Documents\cres_carnets.sqlite"

if (Test-Path $dbPath) {
    try {
        $pendientes = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 0;"
        Write-Host "   📊 Notas pendientes: $pendientes" -ForegroundColor White
    } catch {
        Write-Host "   ⚠️  SQLite3 no disponible, ejecutando app..." -ForegroundColor Yellow
    }
} else {
    Write-Host "   ℹ  Base de datos no existe aún" -ForegroundColor Gray
}

# Ejecutar app
Write-Host "
2  Ejecutando app (OBSERVA LOS LOGS)..." -ForegroundColor Yellow
Write-Host "   Busca en consola: [SYNC]  Iniciando sincronización..." -ForegroundColor Gray
Write-Host "
" -ForegroundColor White

cd "$env:LOCALAPPDATA\CRES Carnets"
.\cres_carnets_ibmcloud.exe

Write-Host "
3  App cerrada. Verificando notas pendientes DESPUÉS..." -ForegroundColor Yellow
if (Test-Path $dbPath) {
    try {
        $pendientes = sqlite3 $dbPath "SELECT COUNT(*) FROM notes WHERE synced = 0;"
        Write-Host "    Notas pendientes: $pendientes" -ForegroundColor White
        
        if ($pendientes -eq 0) {
            Write-Host "
    ÉXITO: Todas las notas fueron sincronizadas!" -ForegroundColor Green
        } else {
            Write-Host "
     Aún hay $pendientes notas sin sincronizar" -ForegroundColor Yellow
            Write-Host "   Posibles causas:" -ForegroundColor Gray
            Write-Host "     - Sin conexión a internet" -ForegroundColor Gray
            Write-Host "     - Servidor backend no responde" -ForegroundColor Gray
            Write-Host "     - Error en el token JWT" -ForegroundColor Gray
        }
    } catch {
        Write-Host "     No se pudo verificar (SQLite3 no disponible)" -ForegroundColor Yellow
    }
}

Write-Host "
"
