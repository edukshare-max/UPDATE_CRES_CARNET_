# Test del backend FastAPI
$testCarnet = @{
    id = "test123"
    matricula = "2025"
    nombreCompleto = "Test User"
    correo = "test@test.com"
    edad = "20"
    sexo = "Masculino"
    categoria = "Alumno"
    programa = "Test"
    tipoSangre = "O+"
    enfermedadCronica = "Ninguna"
    unidadMedica = "IMSS"
    numeroAfiliacion = "123"
    usoSeguroUniversitario = "Si"
    donante = "Si"
    emergenciaContacto = "Test Contact"
} | ConvertTo-Json

Write-Host "Testing POST carnet..."
try {
    $response = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/carnet/' -Method POST -Body $testCarnet -ContentType 'application/json'
    Write-Host "SUCCESS: $response"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)"
}

$testNota = @{
    id = "nota_test_123"
    matricula = "2025"
    departamento = "Test Depto"
    cuerpo = "Test body"
    tratante = "Test Doctor"
    createdAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json

Write-Host "`nTesting POST nota..."
try {
    $response = Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/notas/' -Method POST -Body $testNota -ContentType 'application/json'
    Write-Host "SUCCESS: $response"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)"
}