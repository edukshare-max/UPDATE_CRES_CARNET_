# ✅ VERIFICACIÓN RÁPIDA v2.4.17

## 📦 Respaldo Creado
- **Carpeta:** `backup_v2.4.17_actualizacion_20251017_114346`
- **Contenido:** lib, assets, temp_backend, installer, pubspec.yaml, version.json

## 🔍 Verificar que Render terminó despliegue

```powershell
# Verificar versión en backend
curl.exe -s "https://fastapi-backend-o7ks.onrender.com/updates/latest" | ConvertFrom-Json | Format-List version, build_number, download_url
```

**Resultado esperado:**
```
version      : 2.4.17
build_number : 17
download_url : https://github.com/edukshare-max/UPDATE_CRES_CARNET_/raw/master/releases/installers/CRES_Carnets_Setup_v2.4.17.exe
```

**Si aún dice 2.4.1:** Esperar 2-3 minutos más, Render está desplegando.

## 🎯 Probar actualización desde app

1. Abrir app de usuario con versión anterior (ej: 2.4.12)
2. Ir a "Acerca de" → "Buscar actualizaciones"
3. Debería mostrar v2.4.17 disponible
4. Presionar "Actualizar"
5. Esperar descarga e instalación

## 📄 URLS Importantes

- **Instalador directo:** https://github.com/edukshare-max/UPDATE_CRES_CARNET_/raw/master/releases/installers/CRES_Carnets_Setup_v2.4.17.exe
- **Backend health:** https://fastapi-backend-o7ks.onrender.com/health
- **Backend version:** https://fastapi-backend-o7ks.onrender.com/updates/latest

## 📝 Documentación completa
Ver: `RESUMEN_v2.4.17_ACTUALIZACION.md`
