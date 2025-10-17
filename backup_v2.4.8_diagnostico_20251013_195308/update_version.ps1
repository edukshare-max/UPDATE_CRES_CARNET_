<#
.SYNOPSIS
    Script para incrementar la versión de CRES Carnets UAGro

.DESCRIPTION
    Actualiza automáticamente el número de versión en version.json y pubspec.yaml
    Permite incrementar versión Major, Minor o Patch según versionamiento semántico
    Actualiza buildNumber, releaseDate y permite agregar entrada al changelog

.PARAMETER Major
    Incrementa el número MAJOR (1.0.0 -> 2.0.0)
    Resetea MINOR y PATCH a 0

.PARAMETER Minor
    Incrementa el número MINOR (1.0.0 -> 1.1.0)
    Resetea PATCH a 0

.PARAMETER Patch
    Incrementa el número PATCH (1.0.0 -> 1.0.1)
    Default si no se especifica ningún parámetro

.PARAMETER Message
    Mensaje para agregar al changelog
    Opcional: si no se proporciona, se pedirá interactivamente

.PARAMETER SkipChangelog
    Omite la actualización del changelog
    Útil para builds de prueba

.EXAMPLE
    .\update_version.ps1 -Patch
    Incrementa versión patch: 2.3.2 -> 2.3.3

.EXAMPLE
    .\update_version.ps1 -Minor -Message "Nueva función de exportación"
    Incrementa versión minor con mensaje: 2.3.2 -> 2.4.0

.EXAMPLE
    .\update_version.ps1 -Major -Message "Refactorización completa del sistema"
    Incrementa versión major: 2.3.2 -> 3.0.0
#>

param(
    [switch]$Major,
    [switch]$Minor,
    [switch]$Patch,
    [string]$Message = "",
    [switch]$SkipChangelog
)

# Colores para output
function Write-Success { param($text) Write-Host $text -ForegroundColor Green }
function Write-Info { param($text) Write-Host $text -ForegroundColor Cyan }
function Write-Warning { param($text) Write-Host $text -ForegroundColor Yellow }
function Write-Error { param($text) Write-Host $text -ForegroundColor Red }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " UPDATE VERSION - CRES Carnets UAGro" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Determinar tipo de incremento (default: Patch)
if (-not $Major -and -not $Minor -and -not $Patch) {
    Write-Info "ℹ️  No se especificó tipo de versión, usando -Patch por defecto"
    $Patch = $true
}

# Validar que solo se seleccionó un tipo
$selectedCount = @($Major, $Minor, $Patch).Where({$_}).Count
if ($selectedCount -gt 1) {
    Write-Error "❌ Error: Solo se puede seleccionar un tipo de versión (Major, Minor o Patch)"
    exit 1
}

# Paths
$versionJsonPath = "version.json"
$pubspecPath = "pubspec.yaml"
$assetVersionPath = "assets\version.json"

# Verificar que existen los archivos
if (-not (Test-Path $versionJsonPath)) {
    Write-Error "❌ No se encontró $versionJsonPath"
    exit 1
}

if (-not (Test-Path $pubspecPath)) {
    Write-Error "❌ No se encontró $pubspecPath"
    exit 1
}

# Leer version.json
Write-Info "📄 Leyendo $versionJsonPath..."
$versionData = Get-Content $versionJsonPath -Raw | ConvertFrom-Json

# Parsear versión actual
$currentVersion = $versionData.version
$versionParts = $currentVersion.Split('.')
$majorNum = [int]$versionParts[0]
$minorNum = [int]$versionParts[1]
$patchNum = [int]$versionParts[2]

Write-Info "📌 Versión actual: $currentVersion (Build $($versionData.buildNumber))"

# Calcular nueva versión
if ($Major) {
    $majorNum++
    $minorNum = 0
    $patchNum = 0
    $changeType = "MAJOR"
} elseif ($Minor) {
    $minorNum++
    $patchNum = 0
    $changeType = "MINOR"
} else {
    $patchNum++
    $changeType = "PATCH"
}

$newVersion = "$majorNum.$minorNum.$patchNum"
$newBuildNumber = $versionData.buildNumber + 1
$newReleaseDate = Get-Date -Format "yyyy-MM-dd"

Write-Success "`n✅ Nueva versión: $newVersion (Build $newBuildNumber)"
Write-Info "📅 Fecha de release: $newReleaseDate"
Write-Info "🔧 Tipo de cambio: $changeType`n"

# Confirmar cambios
$confirmation = Read-Host "¿Continuar con la actualización? (S/n)"
if ($confirmation -and $confirmation -ne "S" -and $confirmation -ne "s" -and $confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-Warning "⚠️  Operación cancelada por el usuario"
    exit 0
}

# Actualizar changelog
$changelogEntry = @{
    version = $newVersion
    date = $newReleaseDate
    changes = @()
}

if (-not $SkipChangelog) {
    Write-Host "`n" -NoNewline
    Write-Info "📝 Entrada de changelog para v$newVersion"
    Write-Host "   Escribe los cambios (uno por línea, línea vacía para terminar):`n" -ForegroundColor Gray
    
    $changes = @()
    if ($Message) {
        $changes += $Message
        Write-Host "   • $Message" -ForegroundColor Gray
    } else {
        $lineNum = 1
        while ($true) {
            $change = Read-Host "   Cambio $lineNum"
            if ([string]::IsNullOrWhiteSpace($change)) {
                break
            }
            $changes += $change
            $lineNum++
        }
    }
    
    if ($changes.Count -eq 0) {
        Write-Warning "⚠️  No se agregaron cambios al changelog"
        $changes = @("Actualización de versión $changeType")
    }
    
    $changelogEntry.changes = $changes
}

# Actualizar version.json
Write-Info "`n🔄 Actualizando $versionJsonPath..."
$versionData.version = $newVersion
$versionData.buildNumber = $newBuildNumber
$versionData.releaseDate = $newReleaseDate

# Agregar nueva entrada al inicio del changelog
if (-not $SkipChangelog) {
    $versionData.changelog = @($changelogEntry) + $versionData.changelog
}

# Guardar version.json
$versionData | ConvertTo-Json -Depth 10 | Set-Content $versionJsonPath -Encoding UTF8
Write-Success "✅ $versionJsonPath actualizado"

# Copiar a assets
Write-Info "🔄 Copiando a $assetVersionPath..."
if (-not (Test-Path "assets")) {
    New-Item -ItemType Directory -Path "assets" | Out-Null
}
Copy-Item $versionJsonPath -Destination $assetVersionPath -Force
Write-Success "✅ $assetVersionPath actualizado"

# Actualizar pubspec.yaml
Write-Info "🔄 Actualizando $pubspecPath..."
$pubspecContent = Get-Content $pubspecPath -Raw

# Buscar línea de version en pubspec.yaml (puede no existir)
if ($pubspecContent -match "version:\s*[\d\.]+\+\d+") {
    # Reemplazar versión existente
    $pubspecContent = $pubspecContent -replace "version:\s*[\d\.]+\+\d+", "version: $newVersion+$newBuildNumber"
    Write-Success "✅ Versión actualizada en $pubspecPath"
} else {
    # Agregar línea de versión después de 'publish_to:'
    if ($pubspecContent -match "(publish_to:.*\n)") {
        $pubspecContent = $pubspecContent -replace "(publish_to:.*\n)", "`$1version: $newVersion+$newBuildNumber`n"
        Write-Success "✅ Versión agregada a $pubspecPath"
    } else {
        Write-Warning "⚠️  No se pudo actualizar automáticamente $pubspecPath"
        Write-Warning "   Agrega manualmente: version: $newVersion+$newBuildNumber"
    }
}

Set-Content $pubspecPath -Value $pubspecContent -Encoding UTF8 -NoNewline

# Resumen final
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " ✅ ACTUALIZACIÓN COMPLETADA" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Versión anterior: " -NoNewline -ForegroundColor Gray
Write-Host "$currentVersion (Build $($versionData.buildNumber - 1))" -ForegroundColor White
Write-Host "  Versión nueva:    " -NoNewline -ForegroundColor Gray
Write-Host "$newVersion (Build $newBuildNumber)" -ForegroundColor Green
Write-Host "  Fecha de release: " -NoNewline -ForegroundColor Gray
Write-Host "$newReleaseDate" -ForegroundColor Cyan
Write-Host "  Tipo de cambio:   " -NoNewline -ForegroundColor Gray
Write-Host "$changeType" -ForegroundColor Yellow
Write-Host ""

if (-not $SkipChangelog -and $changelogEntry.changes.Count -gt 0) {
    Write-Host "  Cambios registrados:" -ForegroundColor Gray
    foreach ($change in $changelogEntry.changes) {
        Write-Host "    • $change" -ForegroundColor White
    }
    Write-Host ""
}

Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Revisa los cambios en version.json y pubspec.yaml" -ForegroundColor Gray
Write-Host "  2. Ejecuta: flutter pub get" -ForegroundColor White
Write-Host "  3. Ejecuta: .\build_installer.ps1" -ForegroundColor White
Write-Host "  4. Commit: git add -A && git commit -m `"v$newVersion`"" -ForegroundColor White
Write-Host "  5. Tag: git tag -a v$newVersion -m `"Release $newVersion`"" -ForegroundColor White
Write-Host ""
