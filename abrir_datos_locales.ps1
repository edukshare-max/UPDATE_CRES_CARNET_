# ========================================
# ACCESO DIRECTO A DATOS LOCALES
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DATOS LOCALES - CRES CARNETS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$dbPath = "C:\Users\gilbe\Documents\cres_carnets.sqlite"

# Verificar si existe
if (Test-Path $dbPath) {
    $file = Get-Item $dbPath -Force
    
    Write-Host "ARCHIVO ENCONTRADO" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nombre: cres_carnets.sqlite" -ForegroundColor White
    Write-Host "Ruta:   $($file.FullName)" -ForegroundColor White
    Write-Host "Tamano: $([math]::Round($file.Length/1KB,2)) KB" -ForegroundColor White
    Write-Host "Creado: $($file.CreationTime)" -ForegroundColor White
    Write-Host "Modificado: $($file.LastWriteTime)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "QUE CONTIENE:" -ForegroundColor Yellow
    Write-Host "- Expedientes de estudiantes" -ForegroundColor White
    Write-Host "- Notas medicas, psicologicas, odontologicas" -ForegroundColor White
    Write-Host "- Vacunas y tests" -ForegroundColor White
    Write-Host "- Historial completo" -ForegroundColor White
    Write-Host ""
    
    Write-Host "ACCIONES DISPONIBLES:" -ForegroundColor Cyan
    Write-Host "1. Abrir carpeta contenedora" -ForegroundColor White
    Write-Host "2. Copiar archivo al Escritorio (respaldo)" -ForegroundColor White
    Write-Host "3. Abrir con DB Browser (si esta instalado)" -ForegroundColor White
    Write-Host "4. Mostrar ruta completa" -ForegroundColor White
    Write-Host "5. Salir" -ForegroundColor White
    Write-Host ""
    
    $opcion = Read-Host "Selecciona una opcion (1-5)"
    
    switch ($opcion) {
        "1" {
            Write-Host "`nAbriendo carpeta..." -ForegroundColor Cyan
            explorer.exe /select,"$dbPath"
        }
        "2" {
            $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
            $destino = "$env:USERPROFILE\Desktop\cres_carnets_backup_$fecha.sqlite"
            Copy-Item $dbPath $destino
            Write-Host "`nRespaldo creado en:" -ForegroundColor Green
            Write-Host "$destino" -ForegroundColor White
            explorer.exe /select,"$destino"
        }
        "3" {
            Write-Host "`nIntentando abrir con DB Browser..." -ForegroundColor Cyan
            $dbBrowserPath = "C:\Program Files\DB Browser for SQLite\DB Browser for SQLite.exe"
            if (Test-Path $dbBrowserPath) {
                & $dbBrowserPath $dbPath
            } else {
                Write-Host "DB Browser no encontrado." -ForegroundColor Yellow
                Write-Host "Descargalo de: https://sqlitebrowser.org/" -ForegroundColor Gray
                Write-Host "`nAbriendo carpeta..." -ForegroundColor Cyan
                explorer.exe /select,"$dbPath"
            }
        }
        "4" {
            Write-Host "`nRUTA COMPLETA:" -ForegroundColor Yellow
            Write-Host "$dbPath" -ForegroundColor White
            Write-Host "`nCopiada al portapapeles" -ForegroundColor Green
            Set-Clipboard -Value $dbPath
        }
        "5" {
            Write-Host "`nSaliendo..." -ForegroundColor Gray
        }
        default {
            Write-Host "`nOpcion no valida" -ForegroundColor Red
        }
    }
    
} else {
    Write-Host "ARCHIVO NO ENCONTRADO" -ForegroundColor Red
    Write-Host "=====================" -ForegroundColor Red
    Write-Host ""
    Write-Host "El archivo no existe en:" -ForegroundColor White
    Write-Host "$dbPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Posibles razones:" -ForegroundColor Yellow
    Write-Host "1. La app nunca se ha ejecutado" -ForegroundColor White
    Write-Host "2. Los datos estan en otra ubicacion" -ForegroundColor White
    Write-Host "3. El archivo fue eliminado" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Buscando en otras ubicaciones..." -ForegroundColor Cyan
    $found = Get-ChildItem -Path "C:\Users\$env:USERNAME" -Filter "cres_carnets.sqlite" -Recurse -ErrorAction SilentlyContinue
    
    if ($found) {
        Write-Host "`nEncontrado en:" -ForegroundColor Green
        foreach ($f in $found) {
            Write-Host "  $($f.FullName)" -ForegroundColor White
        }
    } else {
        Write-Host "`nNo se encontro en ninguna ubicacion" -ForegroundColor Yellow
    }
}

Write-Host ""
Read-Host "Presiona ENTER para salir"
