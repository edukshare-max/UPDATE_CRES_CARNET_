# =======================================
# CRES CARNETS - WINDOWS RELEASE BUILDER
# =======================================

param(
    [string]$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
)

$releaseFolder = "releases\windows\cres_carnets_windows_$timestamp"
$buildPath = "build\windows\x64\runner\Release"

Write-Host "Construyendo release para Windows..." -ForegroundColor Yellow
Write-Host "Carpeta de destino: $releaseFolder" -ForegroundColor Gray
Write-Host ""

# Crear estructura de directorios
Write-Host "Creando estructura de directorios..." -ForegroundColor Cyan
New-Item -Path $releaseFolder -ItemType Directory -Force | Out-Null
New-Item -Path "$releaseFolder\data" -ItemType Directory -Force | Out-Null

# Ejecutar flutter build
Write-Host "Ejecutando flutter build windows --release..." -ForegroundColor Cyan
$buildResult = flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al compilar la aplicación" -ForegroundColor Red
    exit 1
}

# Verificar que los archivos existan
if (-not (Test-Path $buildPath)) {
    Write-Host "Error: No se encontraron los archivos compilados en $buildPath" -ForegroundColor Red
    exit 1
}

# Copiar archivos
Write-Host "Copiando archivos de release..." -ForegroundColor Cyan
Copy-Item -Path "$buildPath\*" -Destination $releaseFolder -Recurse -Force

# Crear archivo README
$readmeContent = @"
CRES CARNETS - RELEASE WINDOWS
==============================

Version: $timestamp
Plataforma: Windows x64
Tipo: Release

INSTRUCCIONES DE USO:
1. Ejecutar cres_carnets_ibmcloud.exe
2. Asegurar conexion a internet para sincronizacion

CONTENIDO DEL PAQUETE:
- cres_carnets_ibmcloud.exe (Aplicacion principal)
- flutter_windows.dll
- Plugins de Windows
- Datos de la aplicacion

Para soporte tecnico, contactar al equipo de desarrollo.
"@

$readmeContent | Out-File -FilePath "$releaseFolder\README.txt" -Encoding UTF8

# Mostrar resumen
Write-Host ""
Write-Host "Release de Windows completado exitosamente!" -ForegroundColor Green
Write-Host "Ubicacion: $releaseFolder" -ForegroundColor Green
Write-Host "Archivo principal: cres_carnets_ibmcloud.exe" -ForegroundColor Green

# Obtener tamaño del directorio
$size = (Get-ChildItem $releaseFolder -Recurse | Measure-Object -Property Length -Sum).Sum
$sizeMB = [Math]::Round($size / 1MB, 2)
Write-Host "Tamaño total: $sizeMB MB" -ForegroundColor Gray
Write-Host ""