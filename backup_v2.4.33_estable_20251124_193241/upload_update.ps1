# Script para subir actualización al servidor
# v2.4.30 - Búsqueda por nombre

$VERSION = "2.4.30"
$BUILD = 30
$RELEASE_DATE = Get-Date -Format "yyyy-MM-dd"
$PLATFORM = "windows"

# Ruta del ZIP de la release
$RELEASE_FOLDER = "releases\windows\cres_carnets_windows_20251124_105012"
$ZIP_FILE = "CRES_Carnets_Windows_v${VERSION}.zip"

Write-Host "`n📦 Preparando actualización v$VERSION..." -ForegroundColor Cyan

# 1. Crear ZIP si no existe
if (!(Test-Path $ZIP_FILE)) {
    Write-Host "Comprimiendo release..." -ForegroundColor Yellow
    Compress-Archive -Path "$RELEASE_FOLDER\*" -DestinationPath $ZIP_FILE -Force
    Write-Host "✅ ZIP creado: $ZIP_FILE" -ForegroundColor Green
}

# 2. Obtener tamaño del archivo
$FILE_SIZE = (Get-Item $ZIP_FILE).Length
Write-Host "📏 Tamaño: $([math]::Round($FILE_SIZE / 1MB, 2)) MB" -ForegroundColor Gray

# 3. Calcular checksum SHA256
Write-Host "🔐 Calculando checksum..." -ForegroundColor Yellow
$CHECKSUM = (Get-FileHash -Path $ZIP_FILE -Algorithm SHA256).Hash
Write-Host "✅ Checksum: $CHECKSUM" -ForegroundColor Green

# 4. Crear archivo de metadata JSON
$METADATA = @{
    version = $VERSION
    build_number = $BUILD
    release_date = $RELEASE_DATE
    platform = $PLATFORM
    file_size = $FILE_SIZE
    checksum = $CHECKSUM
    is_mandatory = $false
    changelog = @(
        "🔍 NUEVA: Búsqueda de carnets por nombre (además de matrícula)",
        "🤖 Detección automática: números=matrícula, texto=nombre",
        "☁️ Búsqueda en base de datos local y nube",
        "📱 Optimización móvil: BrandSidebar oculto en Android/iOS",
        "🎨 Mejoras de UI en formularios móviles"
    )
    download_url = "https://github.com/tu-usuario/UPDATE_CRES_CARNET_/releases/download/v${VERSION}/${ZIP_FILE}"
} | ConvertTo-Json -Depth 10

$METADATA | Out-File -FilePath "version_${VERSION}.json" -Encoding UTF8

Write-Host "`n✅ Metadata creada: version_${VERSION}.json" -ForegroundColor Green
Write-Host "`n📋 CONTENIDO DEL JSON:" -ForegroundColor Cyan
Write-Host $METADATA

Write-Host "`nPASOS SIGUIENTES:" -ForegroundColor Yellow
Write-Host "1. Subir $ZIP_FILE a GitHub Releases o servidor de archivos" -ForegroundColor White
Write-Host "2. Actualizar download_url en version_${VERSION}.json con la URL real" -ForegroundColor White
Write-Host "3. Enviar version_${VERSION}.json al backend FastAPI:" -ForegroundColor White
Write-Host "   POST https://fastapi-backend-o7ks.onrender.com/updates/publish" -ForegroundColor Gray
Write-Host "   Body: contenido de version_${VERSION}.json" -ForegroundColor Gray
Write-Host "`nO puedes usar curl:" -ForegroundColor Cyan
Write-Host "   curl -X POST https://fastapi-backend-o7ks.onrender.com/updates/publish -H 'Content-Type: application/json' -d '@version_${VERSION}.json'" -ForegroundColor Gray

Write-Host "`nDespues de publicar, las apps verificaran automaticamente!" -ForegroundColor Green
