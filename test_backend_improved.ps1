# Test mejorado del backend FastAPI con los nuevos cambios
Write-Host "=== Probando backend con cambios aplicados ===" -ForegroundColor Green

# Test 1: Health check
Write-Host "`n1. Testing health check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/health' -Method GET
    Write-Host "Health Status: $($health.status)" -ForegroundColor Green
    Write-Host "Cosmos Connected: $($health.cosmos_connected)" -ForegroundColor Green
} catch {
    Write-Host "Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: POST nota SIN slash final (como envía Flutter)
Write-Host "`n2. Testing POST nota (sin slash final)..." -ForegroundColor Yellow
$testNota = @{
    matricula = "2025"
    departamento = "Consultorio médico"
    cuerpo = "Nota de prueba desde PowerShell - sin slash"
    tratante = "Dr. Test PowerShell"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/notas' -Method POST -Body $testNota -ContentType 'application/json'
    Write-Host "SUCCESS:" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Green
    Write-Host "ID: $($response.id)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}

# Test 3: POST carnet SIN slash final (como envía Flutter)
Write-Host "`n3. Testing POST carnet (sin slash final)..." -ForegroundColor Yellow
$testCarnet = @{
    matricula = "2025"
    nombreCompleto = "Usuario Test PowerShell"
    correo = "test@powershell.com"
    edad = "25"
    sexo = "Masculino"
    categoria = "Alumno"
    programa = "Test Program"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/carnet' -Method POST -Body $testCarnet -ContentType 'application/json'
    Write-Host "SUCCESS:" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Green
    Write-Host "ID: $($response.id)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}

# Test 4: POST nota CON slash final
Write-Host "`n4. Testing POST nota (con slash final)..." -ForegroundColor Yellow
$testNota2 = @{
    matricula = "2025"
    departamento = "Test Depto"
    cuerpo = "Nota con slash final"
    tratante = "Dr. Slash"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/notas/' -Method POST -Body $testNota2 -ContentType 'application/json'
    Write-Host "SUCCESS: Alias con slash funciona!" -ForegroundColor Green
    Write-Host "ID: $($response.id)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Pruebas completadas ===" -ForegroundColor Green