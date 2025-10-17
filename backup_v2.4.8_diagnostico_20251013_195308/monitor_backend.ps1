# Monitor del backend - verifica si ya se desplegaron los cambios
$maxAttempts = 30
$attempt = 1
$deployed = $false

Write-Host "🔍 Monitoreando despliegue del backend..." -ForegroundColor Yellow
Write-Host "⏰ Verificando cada 30 segundos (máximo $maxAttempts intentos)" -ForegroundColor Gray

while ($attempt -le $maxAttempts -and -not $deployed) {
    Write-Host "`n[$attempt/$maxAttempts] Verificando backend..." -ForegroundColor Cyan
    
    try {
        # Probar endpoint de salud (nuevo)
        $health = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/health' -Method GET -TimeoutSec 10
        if ($health.status -eq "healthy") {
            Write-Host "✅ ¡Backend actualizado! Health check responde correctamente" -ForegroundColor Green
            Write-Host "Cosmos Connected: $($health.cosmos_connected)" -ForegroundColor Green
            $deployed = $true
            break
        }
    } catch {
        # Si health no existe, probar con una nota simple (debería aceptar campos opcionales)
        try {
            $testNota = @{
                matricula = "TEST"
                departamento = "Monitor Test"
                cuerpo = "Test desde monitor"
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/notas' -Method POST -Body $testNota -ContentType 'application/json' -TimeoutSec 10
            
            if ($response.status -eq "created" -or $response.id) {
                Write-Host "✅ ¡Backend actualizado! POST notas funciona correctamente" -ForegroundColor Green
                Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Green
                $deployed = $true
                break
            }
        } catch {
            $statusCode = $_.Exception.Response.StatusCode
            if ($statusCode -eq 422) {
                Write-Host "⚠️ Backend aún no actualizado (422 - campos requeridos)" -ForegroundColor Yellow
            } elseif ($statusCode -eq 400) {
                Write-Host "⚠️ Backend aún no actualizado (400 - bad request)" -ForegroundColor Yellow
            } else {
                Write-Host "⚠️ Backend no responde correctamente: $statusCode" -ForegroundColor Yellow
            }
        }
    }
    
    if (-not $deployed) {
        $attempt++
        if ($attempt -le $maxAttempts) {
            Write-Host "⏳ Esperando 30 segundos antes del siguiente intento..." -ForegroundColor Gray
            Start-Sleep -Seconds 30
        }
    }
}

if ($deployed) {
    Write-Host "`n🎉 ¡BACKEND LISTO! Ya puedes probar la sincronización completa" -ForegroundColor Green
    
    # Mostrar resumen de pruebas disponibles
    Write-Host "`n📋 Pruebas recomendadas:" -ForegroundColor Cyan
    Write-Host "1. Crear un carnet en la app" -ForegroundColor White
    Write-Host "2. Crear una nota en la app" -ForegroundColor White
    Write-Host "3. Verificar que aparecen como 'pendientes' localmente" -ForegroundColor White
    Write-Host "4. Usar el botón de sincronización en la app" -ForegroundColor White
    Write-Host "5. Verificar que el contador cambia a 'sincronizadas'" -ForegroundColor White
} else {
    Write-Host "`n⏰ Tiempo agotado. El backend puede tardar más en desplegarse." -ForegroundColor Yellow
    Write-Host "💡 Puedes seguir probando la funcionalidad local mientras tanto." -ForegroundColor Gray
}

Write-Host "`n🔚 Monitor finalizado." -ForegroundColor Gray