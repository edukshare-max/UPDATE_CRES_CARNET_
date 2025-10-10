# 📦 Guía Rápida de Respaldos

## ✅ Respaldo Actual Creado

**Fecha**: 10 de Octubre, 2025 - 09:42:27  
**Nombre**: `backup_version_estable_20251010_094227`  
**Tamaño**: 223 MB comprimido  
**Estado**: ✅ Completo y verificado

---

## 🎯 ¿Qué incluye este respaldo?

### 📱 Frontend Flutter
- ✅ Todo el código fuente (`lib/`)
- ✅ Configuración de dependencias (`pubspec.yaml`, `pubspec.lock`)
- ✅ Configuración de análisis (`analysis_options.yaml`)
- ✅ Configuración Android completa
- ✅ Configuración Windows completa

### ⚙️ Backend FastAPI
- ✅ Código principal (`main.py`)
- ✅ Helper de Cosmos DB (`cosmos_helper.py`)
- ✅ Dependencias Python (`requirements.txt`)
- ✅ Configuración de Render (`render.yaml`, `Procfile`)

### 📚 Documentación
- ✅ Documentación completa del sistema (`VERSION_INFO.md`)
- ✅ Script de restauración automática (`RESTORE.ps1`)
- ✅ Este archivo guía

---

## 🔄 Cómo Restaurar (Método Rápido)

### Opción 1: Usar el Script Automático
```powershell
cd C:\CRES_Carnets_UAGROPRO\backup_version_estable_20251010_094227
.\RESTORE.ps1
```

### Opción 2: Restauración Manual
```powershell
# 1. Descomprimir el ZIP (si lo usas)
Expand-Archive -Path "backup_version_estable_20251010_094227.zip" -DestinationPath "."

# 2. Copiar código Flutter
Copy-Item -Path "backup_version_estable_20251010_094227\lib" -Destination ".\lib" -Recurse -Force
Copy-Item -Path "backup_version_estable_20251010_094227\pubspec.yaml" -Destination ".\" -Force

# 3. Copiar backend
Copy-Item -Path "backup_version_estable_20251010_094227\temp_backend\*" -Destination ".\temp_backend" -Recurse -Force

# 4. Reinstalar dependencias
flutter pub get

# 5. Ejecutar aplicación
flutter run -d windows
```

---

## 🏷️ Versión Git

Este respaldo corresponde al tag: **`v1.0-promociones-salud-stable`**

Para volver a esta versión en el backend:
```bash
cd temp_backend
git checkout v1.0-promociones-salud-stable
```

---

## 📋 Verificación Post-Restauración

Después de restaurar, verifica que:

1. ✅ **Compilación limpia**:
   ```powershell
   flutter analyze
   ```
   Debe mostrar 0 errores críticos

2. ✅ **Backend funcionando**:
   ```
   https://fastapi-backend-o7ks.onrender.com/health
   ```
   Debe devolver status 200

3. ✅ **Endpoints de promociones**:
   - `/promociones-salud/` - Listar promociones
   - `/promociones-salud/validate-supervisor` - Validar supervisor

4. ✅ **Aplicación ejecutándose**:
   ```powershell
   flutter run -d windows
   ```

---

## 🆘 Resolución de Problemas

### Problema: Errores de compilación
**Solución**:
```powershell
flutter clean
flutter pub get
flutter run -d windows
```

### Problema: Backend no responde
**Solución**:
1. Verificar en Render: https://dashboard.render.com/
2. Revisar logs del deployment
3. Verificar variables de entorno

### Problema: Base de datos no conecta
**Solución**:
1. Verificar credenciales en Render
2. Revisar `COSMOS_ENDPOINT` y `COSMOS_KEY`
3. Validar contenedores en Azure Cosmos DB

---

## 📞 Información del Sistema

### Backend Deployment
- **URL**: https://fastapi-backend-o7ks.onrender.com
- **Plataforma**: Render
- **Repositorio**: https://github.com/edukshare-max/fastapi-backend
- **Branch**: main

### Base de Datos
- **Tipo**: Azure Cosmos DB (NoSQL)
- **Contenedores**:
  - `carnets` - Información de carnets
  - `notas` - Notas médicas
  - `promociones_salud` - Sistema de promociones

### Credenciales
- **Clave Supervisor**: `UAGROcres2025`
- **Archivo credenciales**: `cres_pwd.json` (modo organizacional)

---

## ✨ Características de Esta Versión

- ✅ Sistema completo de Promociones de Salud
- ✅ Validación de supervisor integrada
- ✅ CRUD completo de promociones
- ✅ Integración frontend-backend verificada
- ✅ Diseño responsivo con tema UAGro
- ✅ Compilación sin errores críticos
- ✅ Backend desplegado y operativo

---

## 📝 Notas Importantes

- **Siempre** crea un respaldo preventivo antes de restaurar
- El script `RESTORE.ps1` hace esto automáticamente
- Guarda este respaldo en un lugar seguro (nube, disco externo)
- El archivo ZIP es autónomo y portable

---

**¡Este respaldo garantiza que siempre puedas volver a una versión estable y funcional!**

_Última actualización: 10 de Octubre, 2025 - 09:42:27_
