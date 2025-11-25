# Script para publicar la actualización v2.4.31
# Ejecutar después de subir el ZIP a GitHub Releases

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Publicación de CRES Carnets v2.4.31  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Verificar que el archivo existe
$zipFile = "CRES_Carnets_Windows_v2.4.31.zip"
if (-not (Test-Path $zipFile)) {
    Write-Host "ERROR: No se encuentra el archivo $zipFile" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item $zipFile).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
Write-Host "✓ Archivo encontrado: $zipFile ($fileSizeMB MB)" -ForegroundColor Green
Write-Host ""

# Paso 2: Calcular checksum SHA256
Write-Host "Calculando checksum SHA256..." -ForegroundColor Yellow
$hash = (Get-FileHash $zipFile -Algorithm SHA256).Hash
Write-Host "✓ Checksum: $hash" -ForegroundColor Green
Write-Host ""

# Paso 3: Actualizar el JSON con el checksum
Write-Host "Actualizando version_2.4.31.json con checksum..." -ForegroundColor Yellow
$jsonContent = Get-Content "version_2.4.31.json" -Raw | ConvertFrom-Json
$jsonContent | Add-Member -MemberType NoteProperty -Name "checksum" -Value $hash -Force
$jsonContent | ConvertTo-Json -Depth 10 | Set-Content "version_2.4.31.json"
Write-Host "✓ JSON actualizado" -ForegroundColor Green
Write-Host ""

# Paso 4: Instrucciones para GitHub
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PASO 1: Subir a GitHub Releases      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Ve a: https://github.com/edukshare-max/UPDATE_CRES_CARNET_/releases/new" -ForegroundColor White
Write-Host "2. Tag: v2.4.31" -ForegroundColor White
Write-Host "3. Release title: CRES Carnets v2.4.31 - Búsqueda en Administrar Expedientes" -ForegroundColor White
Write-Host "4. Descripción:" -ForegroundColor White
Write-Host ""
Write-Host "   Nueva funcionalidad de búsqueda en 'Administrar Expedientes':" -ForegroundColor Gray
Write-Host "   - ✅ Búsqueda por matrícula o nombre" -ForegroundColor Gray
Write-Host "   - ✅ Filtrado en tiempo real" -ForegroundColor Gray
Write-Host "   - ✅ Búsqueda parcial case-insensitive" -ForegroundColor Gray
Write-Host "   - 🔧 Backend actualizado con endpoint /carnet/search" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Adjunta el archivo: $zipFile" -ForegroundColor White
Write-Host "6. Presiona 'Publish release'" -ForegroundColor White
Write-Host ""

# Esperar confirmación
Write-Host "¿Ya subiste el release a GitHub? (S/N): " -ForegroundColor Yellow -NoNewline
$response = Read-Host
if ($response -ne "S" -and $response -ne "s") {
    Write-Host "Publicación cancelada. Ejecuta este script nuevamente después de subir a GitHub." -ForegroundColor Yellow
    exit 0
}

# Paso 5: Publicar al backend
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PASO 2: Publicar al Backend          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backendUrl = "https://fastapi-backend-o7ks.onrender.com/updates/publish"
$jsonData = Get-Content "version_2.4.31.json" -Raw

Write-Host "Publicando actualización al backend..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $backendUrl -Method POST `
        -ContentType "application/json" `
        -Body $jsonData `
        -TimeoutSec 30
    
    Write-Host "✓ ¡Actualización publicada exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Respuesta del servidor:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10 | Write-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ¡ACTUALIZACIÓN LISTA!                 " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Todas las computadoras con v2.4.30 o anterior recibirán" -ForegroundColor White
    Write-Host "una notificación de actualización disponible." -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "ERROR al publicar al backend:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Respuesta completa:" -ForegroundColor Yellow
    Write-Host $_ -ForegroundColor Yellow
    exit 1
}
