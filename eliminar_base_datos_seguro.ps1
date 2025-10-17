# ========================================
# ELIMINAR BASE DE DATOS DE FORMA SEGURA
# Crea respaldo automático antes de eliminar
# ========================================

$dbPath = "C:\Users\gilbe\Documents\cres_carnets.sqlite"
$fecha = Get-Date -Format "yyyyMMdd_HHmmss"
$respaldo = "$env:USERPROFILE\Desktop\cres_carnets_respaldo_$fecha.sqlite"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  ELIMINACION SEGURA - BASE DE DATOS CRES CARNETS  ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

# Verificar que existe
if (-not (Test-Path $dbPath)) {
    Write-Host "✅ El archivo no existe, no hay nada que eliminar." -ForegroundColor Green
    Write-Host ""
    Write-Host "Ubicacion esperada:" -ForegroundColor Gray
    Write-Host "  $dbPath" -ForegroundColor White
    Write-Host ""
    Read-Host "Presiona ENTER para salir"
    exit
}

# Mostrar información del archivo
$file = Get-Item $dbPath
Write-Host "📁 ARCHIVO A ELIMINAR:" -ForegroundColor Cyan
Write-Host "   Ruta: $dbPath" -ForegroundColor White
Write-Host "   Tamano: $([math]::Round($file.Length/1KB,2)) KB" -ForegroundColor White
Write-Host "   Creado: $($file.CreationTime)" -ForegroundColor White
Write-Host "   Modificado: $($file.LastWriteTime)" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  ADVERTENCIA:" -ForegroundColor Red
Write-Host "   - Se perderan TODAS las notas NO sincronizadas" -ForegroundColor Yellow
Write-Host "   - Se perderan expedientes locales" -ForegroundColor Yellow
Write-Host "   - Se perderan datos guardados sin conexion" -ForegroundColor Yellow
Write-Host ""

Write-Host "✅ PROTECCION:" -ForegroundColor Green
Write-Host "   - Se creara respaldo automatico antes de eliminar" -ForegroundColor White
Write-Host "   - Respaldo se guardara en el Escritorio" -ForegroundColor White
Write-Host "   - Podras restaurarlo si es necesario" -ForegroundColor White
Write-Host ""

# Confirmar operación
$confirmar = Read-Host "¿Continuar con respaldo + eliminacion? (S/N)"

if ($confirmar -ne "S" -and $confirmar -ne "s") {
    Write-Host ""
    Write-Host "❌ Operacion cancelada" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona ENTER para salir"
    exit
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan

# PASO 1: Crear respaldo
Write-Host ""
Write-Host "PASO 1: Creando respaldo..." -ForegroundColor Cyan
try {
    Copy-Item $dbPath $respaldo -Force
    Write-Host "✅ Respaldo creado exitosamente" -ForegroundColor Green
    Write-Host "   Ubicacion: $respaldo" -ForegroundColor White
    Write-Host "   Tamano: $([math]::Round((Get-Item $respaldo).Length/1KB,2)) KB" -ForegroundColor White
} catch {
    Write-Host "❌ ERROR: No se pudo crear el respaldo" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Operacion abortada por seguridad" -ForegroundColor Yellow
    Read-Host "Presiona ENTER para salir"
    exit
}

# PASO 2: Verificar que la app está cerrada
Write-Host ""
Write-Host "PASO 2: Verificando que la app este cerrada..." -ForegroundColor Cyan
$appRunning = Get-Process | Where-Object { $_.ProcessName -like "*cres_carnets*" }
if ($appRunning) {
    Write-Host "⚠️  ADVERTENCIA: La app parece estar ejecutandose" -ForegroundColor Yellow
    Write-Host "   Es necesario cerrarla completamente primero" -ForegroundColor White
    Write-Host ""
    $forzar = Read-Host "¿Cerrar la app automaticamente? (S/N)"
    if ($forzar -eq "S" -or $forzar -eq "s") {
        Stop-Process -Name "*cres_carnets*" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "✅ App cerrada" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Por favor cierra la app manualmente y vuelve a ejecutar este script" -ForegroundColor Yellow
        Read-Host "Presiona ENTER para salir"
        exit
    }
} else {
    Write-Host "✅ App no esta ejecutandose" -ForegroundColor Green
}

# PASO 3: Eliminar archivo
Write-Host ""
Write-Host "PASO 3: Eliminando archivo original..." -ForegroundColor Cyan
try {
    Remove-Item $dbPath -Force
    Write-Host "✅ Archivo eliminado exitosamente" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: No se pudo eliminar el archivo" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "El respaldo sigue disponible en:" -ForegroundColor Yellow
    Write-Host "   $respaldo" -ForegroundColor White
    Read-Host "Presiona ENTER para salir"
    exit
}

# PASO 4: Verificar eliminación
Write-Host ""
Write-Host "PASO 4: Verificando eliminacion..." -ForegroundColor Cyan
if (-not (Test-Path $dbPath)) {
    Write-Host "✅ Archivo eliminado correctamente" -ForegroundColor Green
} else {
    Write-Host "⚠️  El archivo aun existe (posible problema de permisos)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 OPERACION COMPLETADA EXITOSAMENTE" -ForegroundColor Green
Write-Host ""
Write-Host "¿QUE PASO?" -ForegroundColor Yellow
Write-Host "  ✅ Se creo respaldo en el Escritorio" -ForegroundColor White
Write-Host "  ✅ Se elimino el archivo original" -ForegroundColor White
Write-Host "  ✅ Al abrir la app se creara un archivo nuevo y vacio" -ForegroundColor White
Write-Host ""
Write-Host "¿QUE SIGUE?" -ForegroundColor Yellow
Write-Host "  1. Abre la app - se creara nuevo cres_carnets.sqlite vacio" -ForegroundColor White
Write-Host "  2. Conectate a internet para sincronizar datos del servidor" -ForegroundColor White
Write-Host "  3. Si algo sale mal, restaura el respaldo (ver abajo)" -ForegroundColor White
Write-Host ""
Write-Host "PARA RESTAURAR EL RESPALDO:" -ForegroundColor Cyan
Write-Host "  1. Cierra la app completamente" -ForegroundColor White
Write-Host "  2. Ejecuta este comando en PowerShell:" -ForegroundColor White
Write-Host "     Copy-Item '$respaldo' '$dbPath' -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "UBICACION DEL RESPALDO:" -ForegroundColor Cyan
Write-Host "  $respaldo" -ForegroundColor White
Write-Host ""

$abrir = Read-Host "¿Abrir carpeta del respaldo? (S/N)"
if ($abrir -eq "S" -or $abrir -eq "s") {
    explorer.exe /select,"$respaldo"
}

Write-Host ""
Write-Host "Presiona ENTER para salir..." -ForegroundColor Gray
Read-Host
