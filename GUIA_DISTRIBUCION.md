# 🚀 Guía de Distribución - Para Administradores

## 📦 Instalador Creado

✅ **Archivo**: `CRES_Carnets_UAGro_v2.3.2_Instalador.zip`  
✅ **Ubicación**: `C:\CRES_Carnets_UAGROPRO\releases\installers\`  
✅ **Tamaño**: ~15.56 MB  
✅ **Versión**: 2.3.2 (Build 1)  
✅ **Backend**: https://fastapi-backend-o7ks.onrender.com

---

## 📤 OPCIÓN 1: Compartir por OneDrive (Recomendado)

### Pasos:
1. **Subir el archivo**:
   - Abre OneDrive en tu navegador
   - Crea una carpeta "CRES_Carnets_Instaladores" (opcional)
   - Arrastra el archivo ZIP a OneDrive
   - Espera a que termine la subida

2. **Crear link de compartir**:
   - Click derecho en el archivo
   - Selecciona "Compartir" → "Copiar vínculo"
   - Asegúrate que esté en modo "Cualquiera con el vínculo puede ver"

3. **Enviar a usuarios**:
   ```
   Hola,

   Descarga el instalador de CRES Carnets UAGro aquí:
   [LINK DE ONEDRIVE]

   Instrucciones:
   1. Descarga el ZIP
   2. Descomprime
   3. Click derecho en INSTALAR.bat → Ejecutar como Administrador

   Credenciales de prueba:
   Usuario: DireccionInnovaSalud
   Password: Admin2025

   Cualquier duda, contáctame.
   ```

---

## 📤 OPCIÓN 2: Compartir por Google Drive

### Pasos:
1. Ve a drive.google.com
2. Click en "Nuevo" → "Subir archivo"
3. Selecciona el ZIP
4. Click derecho → "Compartir" → "Copiar enlace"
5. Cambia permisos a "Cualquiera con el enlace"

---

## 📤 OPCIÓN 3: Compartir por Dropbox

### Pasos:
1. Ve a dropbox.com
2. Sube el archivo ZIP
3. Click en "Compartir"
4. Crea enlace compartido
5. Copia el link

---

## 📤 OPCIÓN 4: Servidor Web/FTP

Si tienes acceso a un servidor web:

```bash
# Ejemplo con SCP
scp CRES_Carnets_UAGro_v2.3.2_Instalador.zip user@servidor:/var/www/html/descargas/

# URL resultante:
# https://tuservidor.com/descargas/CRES_Carnets_UAGro_v2.3.2_Instalador.zip
```

---

## 📤 OPCIÓN 5: GitHub Releases (Profesional)

Si configuraste GitHub:

```powershell
# Crear release y subir
gh release create v2.3.2 `
  --title "CRES Carnets v2.3.2" `
  --notes "Release de producción inicial" `
  releases\installers\CRES_Carnets_UAGro_v2.3.2_Instalador.zip
```

---

## 📧 Email de Distribución - Plantilla

```
Asunto: Disponible - CRES Carnets UAGro v2.3.2

Estimados colegas,

Me complace informarles que está disponible la nueva versión del Sistema CRES Carnets UAGro.

🔗 DESCARGA:
[Insertar link aquí]

📋 INSTRUCCIONES DE INSTALACIÓN:
1. Descargar el archivo ZIP
2. Descomprimir en una carpeta
3. Click derecho en INSTALAR.bat
4. Seleccionar "Ejecutar como Administrador"
5. Seguir las instrucciones en pantalla

💡 CARACTERÍSTICAS:
- Sistema de carnets de vacunación completo
- Modo online/offline automático
- 88 campus UAGro disponibles
- Actualizaciones automáticas
- Sincronización con la nube

🔐 CREDENCIALES DE PRUEBA:
Usuario: DireccionInnovaSalud
Password: Admin2025
Campus: (seleccionar de la lista)

📱 REQUISITOS:
- Windows 10 o superior (64-bit)
- 2 GB RAM mínimo
- 500 MB espacio en disco
- Internet (opcional, modo híbrido)

📞 SOPORTE:
Para dudas o problemas, contactar a:
[Tu información de contacto]

Saludos,
[Tu nombre]
Universidad Autónoma de Guerrero
```

---

## 🎯 Checklist de Distribución

Antes de compartir, verifica:

- [ ] Archivo ZIP creado correctamente
- [ ] Tamaño del archivo es razonable (~15-16 MB)
- [ ] Probaste el instalador en tu máquina
- [ ] Backend está funcionando (https://fastapi-backend-o7ks.onrender.com/updates/health)
- [ ] Tienes las credenciales de usuarios listos
- [ ] Guía de usuario disponible (`GUIA_USUARIOS.md`)
- [ ] Link de descarga es público y accesible
- [ ] Email/mensaje de distribución preparado

---

## 🧪 Testing Recomendado

### Antes de distribuir masivamente:

1. **Prueba en máquina limpia**:
   - VM de Windows 10/11
   - Sin Flutter ni desarrollo instalado
   - Usuario sin permisos especiales

2. **Verifica flujo completo**:
   - Descarga del ZIP
   - Descompresión
   - Instalación como Admin
   - Apertura de la app
   - Login con credenciales
   - Sincronización con backend
   - Funciones principales

3. **Grupo piloto**:
   - Selecciona 3-5 usuarios de confianza
   - Pídeles que prueben primero
   - Recopila feedback
   - Ajusta si es necesario

---

## 📊 Monitoreo Post-Distribución

### Backend (Render):
- Revisa logs en https://dashboard.render.com
- Verifica uso de API en `/updates/check`
- Monitorea errores o crashes

### Usuarios:
- Crea un canal de soporte (email, WhatsApp, Teams)
- Documenta problemas comunes
- Prepara respuestas rápidas FAQ

---

## 🔄 Actualizaciones Futuras

Cuando tengas una nueva versión:

1. **Incrementar versión**:
   ```powershell
   .\update_version.ps1 -Patch -Message "Descripción de cambios"
   ```

2. **Generar nuevo instalador**:
   ```powershell
   flutter build windows --release
   # Repetir proceso de creación de ZIP
   ```

3. **Actualizar backend**:
   - Modificar `temp_backend/update_routes.py`
   - Cambiar `LATEST_VERSION` con nueva información
   - Push a GitHub → Render auto-deploy

4. **Los usuarios recibirán notificación automática**
   - El sistema verifica cada 24 horas
   - Descarga e instala automáticamente
   - No necesitas redistribuir manualmente

---

## 📁 Estructura de Archivos de Distribución

```
releases/
└── installers/
    ├── CRES_Carnets_UAGro_v2.3.2_Instalador.zip  ← Distribuir este
    └── release_info_v2.3.2.txt                   ← Información interna
```

**Dentro del ZIP**:
```
CRES_Carnets_UAGro_v2.3.2_Instalador/
├── cres_carnets_ibmcloud.exe      ← Ejecutable principal
├── data/                           ← Assets y datos
├── flutter_windows.dll             ← DLLs de Flutter
├── [otros archivos DLL]
├── INSTALAR.bat                    ← Script de instalación ⭐
├── LEEME.txt                       ← Instrucciones para usuarios
└── version.json                    ← Metadatos de versión
```

---

## 💡 Tips y Mejores Prácticas

### Para OneDrive/Google Drive:
- ✅ Crea una carpeta dedicada "CRES_Carnets_Instaladores"
- ✅ Mantén versiones anteriores por 30 días
- ✅ Usa nombres descriptivos: `CRES_Carnets_v2.3.2_2025-10-10.zip`
- ✅ Verifica que el link no expire

### Para Email:
- ✅ No adjuntes el ZIP (15 MB puede ser grande)
- ✅ Usa link de descarga en su lugar
- ✅ Marca como "Importante" si es actualización crítica
- ✅ Incluye fecha límite si es obligatorio actualizar

### Para Soporte:
- ✅ Documenta todos los problemas reportados
- ✅ Crea una FAQ interna
- ✅ Prepara respuestas rápidas copy-paste
- ✅ Ten a mano el link de descarga siempre

---

## 🎉 ¡Listo para Compartir!

Tu instalador está listo y profesional. Los usuarios podrán:

1. ✅ Descargar fácilmente
2. ✅ Instalar con un par de clicks
3. ✅ Usar inmediatamente
4. ✅ Recibir actualizaciones automáticas en el futuro

**¡Excelente trabajo completando el sistema!** 🚀

---

**Última actualización**: 10 de Octubre, 2025  
**Versión del instalador**: 2.3.2  
**Sistema**: CRES Carnets UAGro  
**Universidad Autónoma de Guerrero**
