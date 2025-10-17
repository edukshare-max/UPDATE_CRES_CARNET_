# ========================================
# LIMPIADOR DE NOTAS LOCALES - CRES CARNETS
# ========================================

$dbPath = "C:\Users\$env:USERNAME\Documents\cres_carnets.sqlite"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  LIMPIADOR DE DATOS LOCALES - CRES CARNETS        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar que existe la base de datos
if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Base de datos no encontrada en:" -ForegroundColor Red
    Write-Host "   $dbPath" -ForegroundColor White
    Write-Host ""
    Read-Host "Presiona ENTER para salir"
    exit
}

# Verificar que la app está cerrada
Write-Host "Verificando que la app este cerrada..." -ForegroundColor Cyan
$appRunning = Get-Process | Where-Object { $_.ProcessName -like "*cres_carnets*" }
if ($appRunning) {
    Write-Host "⚠️  La app debe estar cerrada para limpiar la base de datos" -ForegroundColor Yellow
    Write-Host ""
    $cerrar = Read-Host "¿Cerrar la app automaticamente? (S/N)"
    if ($cerrar -eq "S" -or $cerrar -eq "s") {
        Stop-Process -Name "*cres_carnets*" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "✅ App cerrada" -ForegroundColor Green
    } else {
        Write-Host "Por favor cierra la app y vuelve a ejecutar este script" -ForegroundColor Yellow
        Read-Host "Presiona ENTER para salir"
        exit
    }
}
Write-Host ""

# Mostrar estadísticas
Write-Host "📊 ESTADISTICAS DE LA BASE DE DATOS:" -ForegroundColor Yellow
Write-Host ""

try {
    # Cargar SQLite (requiere módulo SQLite o usar sqlite3.exe)
    $fileInfo = Get-Item $dbPath
    Write-Host "  Tamaño del archivo: $([math]::Round($fileInfo.Length/1KB,2)) KB" -ForegroundColor White
    Write-Host "  Última modificación: $($fileInfo.LastWriteTime)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "  No se pudo obtener información detallada" -ForegroundColor Yellow
    Write-Host ""
}

# Menú de opciones
Write-Host "OPCIONES DE LIMPIEZA:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Crear respaldo de la base de datos" -ForegroundColor White
Write-Host "  2. Limpiar base de datos (vaciar y regenerar)" -ForegroundColor White
Write-Host "  3. Ver ubicación del archivo" -ForegroundColor White
Write-Host "  4. Abrir carpeta en explorador" -ForegroundColor White
Write-Host "  5. Salir" -ForegroundColor White
Write-Host ""

$opcion = Read-Host "Selecciona una opcion (1-5)"

switch ($opcion) {
    "1" {
        # Crear respaldo
        Write-Host ""
        Write-Host "Creando respaldo..." -ForegroundColor Cyan
        
        $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
        $respaldo = "$env:USERPROFILE\Desktop\cres_carnets_backup_$fecha.sqlite"
        
        try {
            Copy-Item $dbPath $respaldo -Force
            Write-Host "✅ Respaldo creado exitosamente" -ForegroundColor Green
            Write-Host "   Ubicación: $respaldo" -ForegroundColor White
            Write-Host "   Tamaño: $([math]::Round((Get-Item $respaldo).Length/1KB,2)) KB" -ForegroundColor White
            Write-Host ""
            
            $abrir = Read-Host "¿Abrir carpeta? (S/N)"
            if ($abrir -eq "S" -or $abrir -eq "s") {
                explorer.exe /select,"$respaldo"
            }
        } catch {
            Write-Host "❌ Error creando respaldo: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "2" {
        # Limpiar base de datos
        Write-Host ""
        Write-Host "⚠️  ADVERTENCIA:" -ForegroundColor Red
        Write-Host "   Esto eliminará el archivo y se creará uno nuevo vacío" -ForegroundColor Yellow
        Write-Host "   al abrir la app." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   SE PERDERAN:" -ForegroundColor Red
        Write-Host "   - Todas las notas NO sincronizadas" -ForegroundColor White
        Write-Host "   - Expedientes locales" -ForegroundColor White
        Write-Host "   - Historial completo" -ForegroundColor White
        Write-Host ""
        Write-Host "   NO SE PERDERAN:" -ForegroundColor Green
        Write-Host "   - Datos de autenticación" -ForegroundColor White
        Write-Host "   - Notas ya sincronizadas (se pueden re-descargar)" -ForegroundColor White
        Write-Host ""
        
        $confirmar = Read-Host "¿Crear respaldo y eliminar? (S/N)"
        
        if ($confirmar -eq "S" -or $confirmar -eq "s") {
            Write-Host ""
            Write-Host "Paso 1: Creando respaldo automático..." -ForegroundColor Cyan
            
            $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
            $respaldo = "$env:USERPROFILE\Desktop\cres_carnets_backup_antes_limpiar_$fecha.sqlite"
            
            try {
                Copy-Item $dbPath $respaldo -Force
                Write-Host "✅ Respaldo creado: $respaldo" -ForegroundColor Green
                
                Write-Host ""
                Write-Host "Paso 2: Eliminando base de datos..." -ForegroundColor Cyan
                Remove-Item $dbPath -Force
                Write-Host "✅ Base de datos eliminada" -ForegroundColor Green
                
                Write-Host ""
                Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
                Write-Host "║  LIMPIEZA COMPLETADA                           ║" -ForegroundColor Green
                Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
                Write-Host ""
                Write-Host "Al abrir la app:" -ForegroundColor Yellow
                Write-Host "  1. Se creará archivo nuevo vacío" -ForegroundColor White
                Write-Host "  2. Conéctate a internet" -ForegroundColor White
                Write-Host "  3. Los datos sincronizados se descargarán" -ForegroundColor White
                Write-Host ""
                Write-Host "Respaldo guardado en:" -ForegroundColor Cyan
                Write-Host "  $respaldo" -ForegroundColor White
                Write-Host ""
                
                $abrir = Read-Host "¿Abrir carpeta del respaldo? (S/N)"
                if ($abrir -eq "S" -or $abrir -eq "s") {
                    explorer.exe /select,"$respaldo"
                }
            } catch {
                Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host ""
            Write-Host "Operación cancelada" -ForegroundColor Yellow
        }
    }
    
    "3" {
        # Ver ubicación
        Write-Host ""
        Write-Host "UBICACION DEL ARCHIVO:" -ForegroundColor Cyan
        Write-Host "  $dbPath" -ForegroundColor White
        Write-Host ""
        Write-Host "Ruta copiada al portapapeles" -ForegroundColor Green
        Set-Clipboard -Value $dbPath
    }
    
    "4" {
        # Abrir explorador
        Write-Host ""
        Write-Host "Abriendo explorador..." -ForegroundColor Cyan
        explorer.exe /select,"$dbPath"
    }
    
    "5" {
        Write-Host ""
        Write-Host "Saliendo..." -ForegroundColor Gray
    }
    
    default {
        Write-Host ""
        Write-Host "Opción no válida" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Presiona ENTER para salir"
