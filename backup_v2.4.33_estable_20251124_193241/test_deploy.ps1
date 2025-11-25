<#
.SYNOPSIS
    Script de prueba para verificar el sistema de deployment
    
.DESCRIPTION
    Versión simplificada de deploy.ps1 para testing sin hacer cambios reales
#>

param(
    [switch]$Patch
)

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  🧪 TEST DE DEPLOYMENT - FASE 5" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

# Paso 1: Verificar herramientas
Write-Host "`n[1/7] Verificando herramientas..." -ForegroundColor Yellow

$checks = @()

# Flutter
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ Flutter instalado" -ForegroundColor Green
    $checks += $true
} else {
    Write-Host "  ✗ Flutter NO encontrado" -ForegroundColor Red
    $checks += $false
}

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ Git instalado" -ForegroundColor Green
    $checks += $true
} else {
    Write-Host "  ✗ Git NO encontrado" -ForegroundColor Red
    $checks += $false
}

# Inno Setup
$innoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path $innoSetupPath) {
    Write-Host "  ✓ Inno Setup encontrado" -ForegroundColor Green
    $checks += $true
} else {
    Write-Host "  ✗ Inno Setup NO encontrado" -ForegroundColor Red
    Write-Host "    Ruta esperada: $innoSetupPath" -ForegroundColor Gray
    $checks += $false
}

# GitHub CLI (opcional)
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ GitHub CLI (gh) instalado" -ForegroundColor Green
} else {
    Write-Host "  ⚠ GitHub CLI (gh) NO instalado (opcional)" -ForegroundColor Yellow
    Write-Host "    Instalar con: winget install GitHub.cli" -ForegroundColor Gray
}

# Paso 2: Verificar archivos necesarios
Write-Host "`n[2/7] Verificando archivos..." -ForegroundColor Yellow

if (Test-Path "pubspec.yaml") {
    Write-Host "  ✓ pubspec.yaml" -ForegroundColor Green
} else {
    Write-Host "  ✗ pubspec.yaml NO encontrado" -ForegroundColor Red
    $checks += $false
}

if (Test-Path "assets\version.json") {
    Write-Host "  ✓ assets\version.json" -ForegroundColor Green
    
    # Leer versión actual
    $versionJson = Get-Content "assets\version.json" -Raw | ConvertFrom-Json
    Write-Host "    Versión actual: $($versionJson.version) (Build $($versionJson.build_number))" -ForegroundColor Gray
} else {
    Write-Host "  ✗ assets\version.json NO encontrado" -ForegroundColor Red
    $checks += $false
}

if (Test-Path "installer_config.iss") {
    Write-Host "  ✓ installer_config.iss" -ForegroundColor Green
} else {
    Write-Host "  ✗ installer_config.iss NO encontrado" -ForegroundColor Red
    $checks += $false
}

if (Test-Path "update_version.ps1") {
    Write-Host "  ✓ update_version.ps1" -ForegroundColor Green
} else {
    Write-Host "  ✗ update_version.ps1 NO encontrado" -ForegroundColor Red
    $checks += $false
}

if (Test-Path "temp_backend\update_routes.py") {
    Write-Host "  ✓ temp_backend\update_routes.py" -ForegroundColor Green
} else {
    Write-Host "  ✗ temp_backend\update_routes.py NO encontrado" -ForegroundColor Red
    $checks += $false
}

# Paso 3: Verificar estado de Git
Write-Host "`n[3/7] Verificando Git..." -ForegroundColor Yellow

try {
    $gitStatus = git status --porcelain 2>&1
    if ($LASTEXITCODE -eq 0) {
        if ($gitStatus) {
            Write-Host "  ⚠ Hay cambios sin commitear:" -ForegroundColor Yellow
            Write-Host $gitStatus -ForegroundColor Gray
        } else {
            Write-Host "  ✓ No hay cambios pendientes" -ForegroundColor Green
        }
        
        $branch = git branch --show-current
        Write-Host "  Branch actual: $branch" -ForegroundColor Gray
        
        $lastCommit = git log -1 --oneline
        Write-Host "  Último commit: $lastCommit" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Error al verificar Git" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ Error: $_" -ForegroundColor Red
}

# Paso 4: Simular incremento de versión
Write-Host "`n[4/7] Simulando incremento de versión..." -ForegroundColor Yellow
Write-Host "  • Se ejecutaría: .\update_version.ps1 -Patch -Message 'Test'" -ForegroundColor Gray
Write-Host "  • Nueva versión: 2.3.3 (Build 2)" -ForegroundColor Gray
Write-Host "  ✓ Simulación exitosa" -ForegroundColor Green

# Paso 5: Simular build
Write-Host "`n[5/7] Simulando build..." -ForegroundColor Yellow
Write-Host "  • Se ejecutaría: flutter clean" -ForegroundColor Gray
Write-Host "  • Se ejecutaría: flutter pub get" -ForegroundColor Gray
Write-Host "  • Se ejecutaría: flutter build windows --release" -ForegroundColor Gray
Write-Host "  ✓ Simulación exitosa (no se compiló realmente)" -ForegroundColor Green

# Paso 6: Simular generación de instalador
Write-Host "`n[6/7] Simulando generación de instalador..." -ForegroundColor Yellow
Write-Host "  • Se ejecutaría: ISCC.exe installer_config.iss" -ForegroundColor Gray
Write-Host "  • Instalador: CRES_Carnets_Setup_v2.3.3.exe" -ForegroundColor Gray
Write-Host "  • Checksum: abc123..." -ForegroundColor Gray
Write-Host "  ✓ Simulación exitosa" -ForegroundColor Green

# Paso 7: Simular actualización de backend
Write-Host "`n[7/7] Simulando actualización de backend..." -ForegroundColor Yellow
Write-Host "  • Se actualizaría: temp_backend\update_routes.py" -ForegroundColor Gray
Write-Host "  • Nueva versión: 2.3.3" -ForegroundColor Gray
Write-Host "  • Checksum: abc123..." -ForegroundColor Gray
Write-Host "  ✓ Simulación exitosa" -ForegroundColor Green

# Resumen final
Write-Host "`n============================================" -ForegroundColor Cyan
if ($checks -contains $false) {
    Write-Host "  ⚠ VERIFICACIÓN CON ERRORES" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "`n  Algunos componentes no están disponibles." -ForegroundColor Yellow
    Write-Host "  Revisa los errores arriba antes de usar deploy.ps1" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ VERIFICACIÓN EXITOSA" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "`n  Todas las herramientas y archivos están listos." -ForegroundColor Green
    Write-Host "  El sistema de deployment está listo para usarse." -ForegroundColor Green
    Write-Host "`n  Para hacer un deployment real:" -ForegroundColor Cyan
    Write-Host "    .\deploy.ps1 -Patch -SkipUpload -SkipBackend" -ForegroundColor White
    Write-Host "    (esto generará el instalador sin subirlo)" -ForegroundColor Gray
}

Write-Host "`n============================================`n" -ForegroundColor Cyan
