# ====================================================
# VERIFICACIÓN LÓGICA - FLUJO DE LOGIN OFFLINE
# ====================================================
# Este script simula el flujo de autenticación para
# verificar si la lógica permite login offline

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  VERIFICACIÓN DE LÓGICA - LOGIN OFFLINE v2.4.8" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# ====================================================
# SIMULACIÓN: PRIMER LOGIN CON INTERNET
# ====================================================
Write-Host "ESCENARIO 1: PRIMER LOGIN CON INTERNET" -ForegroundColor Green
Write-Host "-" * 60 -ForegroundColor Gray

$usuario = "juan.perez"
$password = "MiPassword123"
$campus = "cres-llano-largo"

Write-Host "Usuario: $usuario" -ForegroundColor White
Write-Host "Campus: $campus" -ForegroundColor White
Write-Host ""

# Paso 1: Verificar cache
Write-Host "Paso 1: Verificar si existe cache" -ForegroundColor Cyan
$hasCache = $false  # Primera vez, no hay cache
Write-Host "   hasCache = $hasCache" -ForegroundColor Gray
if (!$hasCache) {
    Write-Host "   ⚠️  Sin cache - se requiere conexión" -ForegroundColor Yellow
}

# Paso 2: Verificar conectividad
Write-Host ""
Write-Host "Paso 2: Verificar conectividad" -ForegroundColor Cyan
$hasConnection = $true  # Usuario tiene internet
Write-Host "   hasConnection = $hasConnection" -ForegroundColor Gray

# Paso 3: Evaluar qué hacer
Write-Host ""
Write-Host "Paso 3: Determinar acción" -ForegroundColor Cyan
if ($hasCache -and -not $hasConnection) {
    Write-Host "   → Ir directo a offline" -ForegroundColor Yellow
} elseif (-not $hasConnection -and -not $hasCache) {
    Write-Host "   → ERROR: Sin red y sin cache" -ForegroundColor Red
} elseif ($hasConnection) {
    Write-Host "   → Intentar login online" -ForegroundColor Green
}

# Paso 4: Login online exitoso
Write-Host ""
Write-Host "Paso 4: Login online (simulado)" -ForegroundColor Cyan
Write-Host "   POST https://fastapi-backend-o7ks.onrender.com/auth/login" -ForegroundColor Gray
Write-Host "   Respuesta: 200 OK" -ForegroundColor Green
Write-Host "   Datos recibidos:" -ForegroundColor Gray
Write-Host "      - access_token: eyJhbGciOiJIUzI1NiIs..." -ForegroundColor Gray
Write-Host "      - user: {id:123, username:'$usuario', campus:'llano-largo'}" -ForegroundColor Gray

# Paso 5: Guardar datos
Write-Host ""
Write-Host "Paso 5: Guardar datos en FlutterSecureStorage" -ForegroundColor Cyan
Write-Host "   💾 Guardando auth_token..." -ForegroundColor Gray
$token_guardado = $true
Write-Host "   💾 Guardando auth_user..." -ForegroundColor Gray
$user_guardado = $true

# Verificación inmediata
Write-Host ""
Write-Host "Paso 6: Verificación inmediata" -ForegroundColor Cyan
if ($token_guardado) {
    Write-Host "   ✅ Token verificado" -ForegroundColor Green
} else {
    Write-Host "   ❌ ERROR: Token NO se guardó" -ForegroundColor Red
}

if ($user_guardado) {
    Write-Host "   ✅ Datos de usuario verificados" -ForegroundColor Green
} else {
    Write-Host "   ❌ ERROR: Datos de usuario NO se guardaron" -ForegroundColor Red
}

# Paso 7: Guardar password hash
Write-Host ""
Write-Host "Paso 7: Guardar password hash para offline" -ForegroundColor Cyan
Write-Host "   Campus del backend: 'llano-largo'" -ForegroundColor Gray
Write-Host "   Normalizando a: 'llano-largo'" -ForegroundColor Gray
Write-Host "   💾 Guardando offline_password_hash..." -ForegroundColor Gray
$hash_guardado = $true
Write-Host "   ✅ Hash guardado" -ForegroundColor Green

# Paso 8: Delay de flush
Write-Host ""
Write-Host "Paso 8: Esperar flush a disco" -ForegroundColor Cyan
Write-Host "   ⏳ Esperando 500ms..." -ForegroundColor Gray
Start-Sleep -Milliseconds 500
Write-Host "   ✅ Flush completado" -ForegroundColor Green

# Resultado
Write-Host ""
Write-Host "RESULTADO:" -ForegroundColor Yellow
Write-Host "   ✅ Login exitoso" -ForegroundColor Green
Write-Host "   ✅ Usuario entra a la app" -ForegroundColor Green
Write-Host ""
Write-Host "DATOS GUARDADOS EN STORAGE:" -ForegroundColor Yellow
Write-Host "   - auth_token: eyJhbGciOiJIUzI1NiIs..." -ForegroundColor White
Write-Host "   - auth_user: {id:123, username:'$usuario'...}" -ForegroundColor White
Write-Host "   - offline_password_hash: {username:'$usuario', campus:'llano-largo', hash:'...', timestamp:'2025-10-13'}" -ForegroundColor White

Read-Host "`nPresiona ENTER para continuar con ESCENARIO 2"

# ====================================================
# SIMULACIÓN: SEGUNDO LOGIN SIN INTERNET
# ====================================================
Write-Host ""
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "ESCENARIO 2: SEGUNDO LOGIN SIN INTERNET" -ForegroundColor Green
Write-Host "-" * 60 -ForegroundColor Gray
Write-Host ""
Write-Host "Usuario cierra sesión y desconecta internet" -ForegroundColor Yellow
Write-Host "Ahora intenta hacer login de nuevo..." -ForegroundColor Yellow
Write-Host ""

# Paso 1: Verificar cache
Write-Host "Paso 1: Verificar si existe cache" -ForegroundColor Cyan
$hasCache = $true  # Ahora SÍ hay cache
Write-Host "   hasCache = $hasCache" -ForegroundColor Gray
Write-Host "   ✅ Cache disponible" -ForegroundColor Green

# Paso 2: Verificar conectividad
Write-Host ""
Write-Host "Paso 2: Verificar conectividad" -ForegroundColor Cyan
$hasConnection = $false  # Usuario NO tiene internet
Write-Host "   hasConnection = $hasConnection" -ForegroundColor Gray
Write-Host "   ⚠️  Sin conexión de red" -ForegroundColor Yellow

# Paso 3: Evaluar qué hacer
Write-Host ""
Write-Host "Paso 3: Determinar acción" -ForegroundColor Cyan
if ($hasCache -and -not $hasConnection) {
    Write-Host "   → Ir directo a offline (línea 99-102)" -ForegroundColor Green
    $accion = "offline"
} elseif (-not $hasConnection -and -not $hasCache) {
    Write-Host "   → ERROR: Sin red y sin cache" -ForegroundColor Red
    $accion = "error"
} elseif ($hasConnection) {
    Write-Host "   → Intentar login online" -ForegroundColor Green
    $accion = "online"
}

# Paso 4: Ejecutar _tryOfflineLogin
Write-Host ""
Write-Host "Paso 4: Ejecutar _tryOfflineLogin()" -ForegroundColor Cyan

# Diagnóstico del storage
Write-Host ""
Write-Host "   🔍 DIAGNÓSTICO: Verificando FlutterSecureStorage..." -ForegroundColor Cyan
Write-Host "      🔑 Token: SÍ existe (offline_1728835200000...)" -ForegroundColor Gray
Write-Host "      👤 User: SÍ existe ({id:123, username:'$usuario'...)" -ForegroundColor Gray

# Verificar datos de usuario
Write-Host ""
Write-Host "   Verificando datos de usuario en storage..." -ForegroundColor Cyan
$userJson = $true  # Datos SÍ existen
if ($userJson) {
    Write-Host "      ✅ Datos de usuario encontrados en cache" -ForegroundColor Green
} else {
    Write-Host "      ❌ No hay datos de usuario - login imposible" -ForegroundColor Red
}

# Validar password hash
Write-Host ""
Write-Host "   Validando password contra hash..." -ForegroundColor Cyan
Write-Host "      - Usuario: $usuario" -ForegroundColor Gray
Write-Host "      - Campus: llano-largo" -ForegroundColor Gray
Write-Host "      - Password: $password" -ForegroundColor Gray

Write-Host "      🔍 Leyendo offline_password_hash..." -ForegroundColor Gray
$cacheJson = @{
    username = $usuario
    campus = "llano-largo"
    hash = "ABC123..." # Hash simulado
    timestamp = "2025-10-13T14:00:00"
}

Write-Host "      📦 Cache encontrado:" -ForegroundColor Gray
Write-Host "         Usuario: $($cacheJson.username)" -ForegroundColor Gray
Write-Host "         Campus: $($cacheJson.campus)" -ForegroundColor Gray

# Validar usuario
if ($cacheJson.username -eq $usuario) {
    Write-Host "      ✅ Usuario coincide" -ForegroundColor Green
} else {
    Write-Host "      ❌ Usuario NO coincide" -ForegroundColor Red
}

# Validar campus
if ($cacheJson.campus -eq "llano-largo") {
    Write-Host "      ✅ Campus coincide" -ForegroundColor Green
} else {
    Write-Host "      ❌ Campus NO coincide" -ForegroundColor Red
}

# Validar expiración
$lastLogin = [DateTime]::Parse($cacheJson.timestamp)
$daysSince = ([DateTime]::Now - $lastLogin).Days
Write-Host "      ⏰ Días desde último login: $daysSince (máximo: 7)" -ForegroundColor Gray
if ($daysSince -le 7) {
    Write-Host "      ✅ Cache NO expirado" -ForegroundColor Green
} else {
    Write-Host "      ❌ Cache EXPIRADO" -ForegroundColor Red
}

# Validar hash de password
Write-Host "      🔐 Validando hash de password..." -ForegroundColor Gray
$passwordValida = $true  # Simulamos que es correcta
if ($passwordValida) {
    Write-Host "      ✅ Hash válido - credenciales correctas" -ForegroundColor Green
} else {
    Write-Host "      ❌ Hash inválido - contraseña incorrecta" -ForegroundColor Red
}

# Paso 5: Generar token offline
Write-Host ""
Write-Host "Paso 5: Generar token offline temporal" -ForegroundColor Cyan
$offlineToken = "offline_1728835200123"
Write-Host "   Token generado: $offlineToken" -ForegroundColor Gray
Write-Host "   💾 Guardando en storage..." -ForegroundColor Gray
Write-Host "   ✅ Token offline guardado" -ForegroundColor Green

# Resultado final
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "RESULTADO FINAL:" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

if ($userJson -and $passwordValida -and $daysSince -le 7) {
    Write-Host "✅ LOGIN OFFLINE EXITOSO" -ForegroundColor Green
    Write-Host ""
    Write-Host "El usuario puede entrar a la app sin internet" -ForegroundColor White
    Write-Host ""
    Write-Host "Datos retornados:" -ForegroundColor Yellow
    Write-Host "   - success: true" -ForegroundColor White
    Write-Host "   - user: {id:123, username:'$usuario'...}" -ForegroundColor White
    Write-Host "   - token: $offlineToken" -ForegroundColor White
    Write-Host "   - mode: 'offline'" -ForegroundColor White
    Write-Host "   - warning: 'Modo sin conexión. Los datos se sincronizarán...'" -ForegroundColor White
    Write-Host ""
    Write-Host "🎉 LA LÓGICA ES CORRECTA - DEBERÍA FUNCIONAR" -ForegroundColor Green
} else {
    Write-Host "❌ LOGIN OFFLINE FALLÓ" -ForegroundColor Red
    Write-Host ""
    if (-not $userJson) {
        Write-Host "Motivo: Datos de usuario no encontrados en storage" -ForegroundColor Yellow
        Write-Host "Causa posible: FlutterSecureStorage no persiste entre sesiones" -ForegroundColor Yellow
    } elseif (-not $passwordValida) {
        Write-Host "Motivo: Contraseña incorrecta" -ForegroundColor Yellow
    } elseif ($daysSince -gt 7) {
        Write-Host "Motivo: Cache expirado (más de 7 días sin conexión)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "ANÁLISIS DE CÓDIGO:" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ FLUJO CORRECTO:" -ForegroundColor Green
Write-Host "   1. Primera vez: Requiere internet → Guarda todo" -ForegroundColor White
Write-Host "   2. Segunda vez sin internet: Detecta cache → Va a offline" -ForegroundColor White
Write-Host "   3. Offline: Valida password → Lee datos usuario → Login exitoso" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  POSIBLES PROBLEMAS:" -ForegroundColor Yellow
Write-Host "   1. FlutterSecureStorage en Windows no persiste datos entre sesiones" -ForegroundColor White
Write-Host "      → Datos se guardan OK pero se pierden al cerrar app" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Permisos insuficientes para escribir en registro de Windows" -ForegroundColor White
Write-Host "      → Write() retorna OK pero no escribe realmente" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. logout() borra datos antes del fix v2.4.7" -ForegroundColor White
Write-Host "      → Ya corregido en v2.4.7+" -ForegroundColor Gray
Write-Host ""

Write-Host "🔬 SIGUIENTE PASO:" -ForegroundColor Cyan
Write-Host "   Ejecutar la app con el script 'capturar_logs_diagnostico.ps1'" -ForegroundColor White
Write-Host "   para ver EXACTAMENTE qué pasa con FlutterSecureStorage" -ForegroundColor White
Write-Host ""

Read-Host "Presiona ENTER para salir"
