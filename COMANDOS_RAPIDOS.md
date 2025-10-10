# 🚀 Comandos Rápidos - CRES Carnets UAGro

## 📦 Gestión de Respaldos

### Crear nuevo respaldo
```powershell
# Respaldo automático con timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "backup_$timestamp"
New-Item -ItemType Directory -Path $backupName
Copy-Item -Path "lib" -Destination "$backupName\lib" -Recurse
Copy-Item -Path "pubspec.yaml" -Destination "$backupName\" -Force
Copy-Item -Path "temp_backend" -Destination "$backupName\temp_backend" -Recurse
Compress-Archive -Path $backupName -DestinationPath "$backupName.zip"
```

### Restaurar desde respaldo
```powershell
# Usando script automático
.\backup_version_estable_20251010_094227\RESTORE.ps1

# O manualmente
Copy-Item -Path "backup_version_estable_20251010_094227\lib" -Destination "lib" -Recurse -Force
Copy-Item -Path "backup_version_estable_20251010_094227\pubspec.yaml" -Destination "." -Force
```

---

## 🔧 Desarrollo Flutter

### Comandos esenciales
```powershell
# Limpiar y reinstalar
flutter clean
flutter pub get

# Analizar código
flutter analyze

# Ejecutar aplicación
flutter run -d windows    # Windows
flutter run -d android    # Android
flutter run -d edge       # Web (Edge)

# Build para producción
flutter build windows --release
flutter build apk --release
flutter build appbundle --release
```

### Solución de problemas
```powershell
# Limpiar caché completo
flutter clean
rm -r build/
flutter pub get

# Ver dispositivos disponibles
flutter devices

# Ver logs en tiempo real
flutter logs
```

---

## 🌐 Backend (Render)

### URLs importantes
```
Dashboard: https://dashboard.render.com/web/srv-fastapi-backend-o7ks
Logs: https://dashboard.render.com/web/srv-fastapi-backend-o7ks/logs
API: https://fastapi-backend-o7ks.onrender.com
API Docs: https://fastapi-backend-o7ks.onrender.com/docs
Health: https://fastapi-backend-o7ks.onrender.com/health
```

### Deployment
```bash
cd temp_backend

# Ver estado
git status

# Commit y push (activa auto-deploy)
git add .
git commit -m "Descripción del cambio"
git push origin main

# Crear tag de versión
git tag -a "v1.1" -m "Descripción de la versión"
git push origin v1.1
```

### Probar endpoints
```powershell
# Health check
Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/health"

# Validar supervisor
$body = '{"key": "UAGROcres2025"}'
Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/promociones-salud/validate-supervisor" -Method POST -ContentType "application/json" -Body $body

# Listar promociones
Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/promociones-salud/" -Method GET
```

---

## 🗃️ Base de Datos (Azure Cosmos DB)

### Verificar conectividad
```powershell
# Desde health endpoint
Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/health"
# Debe devolver: {"status":"healthy","cosmos_connected":true}
```

### Contenedores
- **carnets** - Información de carnets (PK: /id)
- **notas** - Notas médicas (PK: /matricula)
- **promociones_salud** - Promociones de salud (PK: /id)

---

## 🔍 Análisis de Código

### Búsqueda de errores
```powershell
# Solo errores
flutter analyze | findstr "error -"

# Solo warnings
flutter analyze | findstr "warning -"

# Análisis completo
flutter analyze
```

### Linting
```powershell
# Aplicar fixes automáticos
dart fix --apply

# Formatear código
dart format lib/
dart format lib/ --set-exit-if-changed
```

---

## 📊 Testing

### Ejecutar tests
```powershell
# Todos los tests
flutter test

# Test específico
flutter test test/promocion_salud_section_test.dart

# Con coverage
flutter test --coverage
```

---

## 📱 Builds de Producción

### Windows
```powershell
flutter build windows --release
# Output: build\windows\x64\runner\Release\
```

### Android APK
```powershell
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

### Android App Bundle (Google Play)
```powershell
flutter build appbundle --release
# Output: build\app\outputs\bundle\release\app-release.aab
```

---

## 🔐 Seguridad

### Clave de supervisor actual
```
UAGROcres2025
```

### Archivo de credenciales
```
cres_pwd.json (modo organizacional)
```

---

## 📝 Git Tags

### Ver tags disponibles
```bash
cd temp_backend
git tag -l
```

### Volver a una versión específica
```bash
git checkout v1.0-promociones-salud-stable
```

### Crear nueva versión
```bash
git tag -a "v1.1-nueva-funcionalidad" -m "Descripción"
git push origin v1.1-nueva-funcionalidad
```

---

## 🆘 Comandos de Emergencia

### Si todo falla - Restaurar respaldo
```powershell
.\backup_version_estable_20251010_094227\RESTORE.ps1
flutter clean
flutter pub get
flutter run -d windows
```

### Si backend falla - Redeployment manual
1. Ve a: https://dashboard.render.com/web/srv-fastapi-backend-o7ks
2. Click en "Manual Deploy" → "Deploy latest commit"
3. Espera ~2-3 minutos
4. Verifica: https://fastapi-backend-o7ks.onrender.com/health

---

## 📞 URLs de Referencia

- **Proyecto GitHub**: https://github.com/edukshare-max/fastapi-backend
- **Render Dashboard**: https://dashboard.render.com/
- **API Docs**: https://fastapi-backend-o7ks.onrender.com/docs
- **Azure Portal**: https://portal.azure.com/

---

_Última actualización: 10 de Octubre, 2025_
