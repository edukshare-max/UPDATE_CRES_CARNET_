# ========================================
# SCRIPT PARA CAPTURAR LOGS DE DIAGNÓSTICO
# ========================================
# Este script ejecuta la app y captura los logs
# para diagnosticar el problema de login offline

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "logs_diagnostico_$timestamp.txt"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DIAGNÓSTICO CRES CARNETS v2.4.8" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script te ayudará a diagnosticar por qué" -ForegroundColor White
Write-Host "el login offline no funciona después del primer login." -ForegroundColor White
Write-Host ""
Write-Host "INSTRUCCIONES:" -ForegroundColor Yellow
Write-Host "1. Asegúrate de tener INTERNET CONECTADO" -ForegroundColor White
Write-Host "2. La app se abrirá en un momento" -ForegroundColor White
Write-Host "3. Haz login NORMALMENTE" -ForegroundColor White
Write-Host "4. Una vez dentro, CIERRA LA APP" -ForegroundColor White
Write-Host "5. El script continuará automáticamente" -ForegroundColor White
Write-Host ""
Read-Host "Presiona ENTER cuando estés listo para comenzar"

Write-Host ""
Write-Host "PASO 1: PRUEBA CON INTERNET" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host "Ejecutando app con internet..." -ForegroundColor Cyan
Write-Host "Logs guardándose en: $logFile" -ForegroundColor Gray
Write-Host ""
Write-Host "*** HAZ LOGIN Y LUEGO CIERRA LA APP ***" -ForegroundColor Yellow
Write-Host ""

# Ejecutar app y capturar logs
$appPath = "$env:LOCALAPPDATA\CRES Carnets\cres_carnets_ibmcloud.exe"

if (-not (Test-Path $appPath)) {
    Write-Host "ERROR: No se encuentra la app en: $appPath" -ForegroundColor Red
    Write-Host "¿Ya instalaste CRES_Carnets_Setup_v2.4.8.exe?" -ForegroundColor Yellow
    Read-Host "Presiona ENTER para salir"
    exit 1
}

# Capturar logs del primer login
$output1 = & $appPath 2>&1 | Out-String
$output1 | Out-File -FilePath $logFile -Encoding UTF8

Write-Host ""
Write-Host "✅ App cerrada. Logs del primer login capturados." -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Ahora vas a DESCONECTAR INTERNET" -ForegroundColor Yellow
Write-Host ""
Write-Host "PASO 2: PRUEBA SIN INTERNET" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""
Write-Host "Acciones necesarias:" -ForegroundColor White
Write-Host "1. DESCONECTA INTERNET (WiFi o cable)" -ForegroundColor Yellow
Write-Host "2. Presiona ENTER para continuar" -ForegroundColor White
Write-Host ""
Read-Host "¿Ya desconectaste internet? Presiona ENTER"

Write-Host ""
Write-Host "Ejecutando app SIN internet..." -ForegroundColor Cyan
Write-Host ""
Write-Host "*** INTENTA HACER LOGIN OFFLINE ***" -ForegroundColor Yellow
Write-Host "*** LUEGO CIERRA LA APP ***" -ForegroundColor Yellow
Write-Host ""

# Capturar logs del login offline
$output2 = & $appPath 2>&1 | Out-String
$output2 | Out-File -FilePath $logFile -Append -Encoding UTF8

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DIAGNÓSTICO COMPLETADO" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Logs guardados en: $logFile" -ForegroundColor Green
Write-Host ""
Write-Host "ANÁLISIS AUTOMÁTICO:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

# Analizar logs
$logsContent = Get-Content $logFile -Raw

Write-Host ""
Write-Host "Buscando mensajes clave..." -ForegroundColor Cyan
Write-Host ""

# Verificar si se guardaron datos en el primer login
if ($logsContent -match "✅ Datos de usuario verificados") {
    Write-Host "✅ PRIMER LOGIN: Datos se guardaron correctamente" -ForegroundColor Green
} elseif ($logsContent -match "❌ ERROR CRÍTICO: Datos de usuario NO se guardaron") {
    Write-Host "❌ PRIMER LOGIN: ERROR - Datos NO se guardaron" -ForegroundColor Red
    Write-Host "   Problema: FlutterSecureStorage no puede escribir datos" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  PRIMER LOGIN: No se encontró mensaje de verificación" -ForegroundColor Yellow
}

# Verificar diagnóstico del login offline
if ($logsContent -match "👤 User: SÍ existe") {
    Write-Host "✅ SEGUNDO LOGIN: Datos de usuario EXISTEN en storage" -ForegroundColor Green
    Write-Host "   → Login offline debería funcionar" -ForegroundColor Green
} elseif ($logsContent -match "👤 User: NO existe") {
    Write-Host "❌ SEGUNDO LOGIN: Datos de usuario NO EXISTEN en storage" -ForegroundColor Red
    Write-Host "   → Problema: Datos no persisten entre sesiones" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  SEGUNDO LOGIN: No se encontró diagnóstico de storage" -ForegroundColor Yellow
}

# Verificar resultado final
if ($logsContent -match "✅ Login offline exitoso") {
    Write-Host "✅ RESULTADO FINAL: Login offline FUNCIONÓ" -ForegroundColor Green
    Write-Host "   🎉 ¡PROBLEMA RESUELTO!" -ForegroundColor Green
} elseif ($logsContent -match "❌ No hay datos de usuario guardados") {
    Write-Host "❌ RESULTADO FINAL: Login offline FALLÓ" -ForegroundColor Red
    Write-Host "   Datos de usuario no disponibles" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  RESULTADO FINAL: Estado desconocido" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Por favor, envía el archivo '$logFile'" -ForegroundColor White
Write-Host "al desarrollador para análisis detallado." -ForegroundColor White
Write-Host ""
Write-Host "Ubicación del archivo:" -ForegroundColor Gray
Write-Host "$(Get-Location)\$logFile" -ForegroundColor Gray
Write-Host ""

# Abrir el archivo de logs
Write-Host "¿Deseas abrir el archivo de logs ahora? (S/N): " -ForegroundColor Yellow -NoNewline
$respuesta = Read-Host

if ($respuesta -eq "S" -or $respuesta -eq "s") {
    notepad.exe $logFile
}

Write-Host ""
Write-Host "Presiona ENTER para salir..." -ForegroundColor Gray
Read-Host
