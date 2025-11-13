# 📦 Sistema de Distribución e Instalación
## CRES Carnets UAGro - Instalador Profesional

---

## 🎯 Visión General

Este sistema permite crear instaladores profesionales (`.exe`) para distribuir la aplicación CRES Carnets a los usuarios finales sin necesidad de que tengan conocimientos técnicos.

---

## 📋 Requisitos Previos

### Para CREAR el instalador (solo tú):

1. **Inno Setup 6.x** (Gratuito)
   - Descarga: https://jrsoftware.org/isdl.php
   - Instala con las opciones por defecto
   - No requiere configuración adicional

2. **Flutter SDK** (ya instalado)

3. **PowerShell** (incluido en Windows)

### Para INSTALAR la app (usuarios finales):

- Windows 10 o superior (64-bit)
- Permisos de administrador
- 500 MB de espacio libre
- ¡Eso es todo! No necesitan Flutter ni otras herramientas

---

## 🚀 Cómo Generar el Instalador

### Opción 1: Script Automático (Recomendado)

```powershell
# Desde la raíz del proyecto:
.\build_installer.ps1
```

Esto hará:
1. Compilar la app en modo Release
2. Verificar todos los archivos
3. Generar el instalador `.exe`
4. Guardar en `releases/installers/`

### Opción 2: Omitir Compilación (si ya compilaste antes)

```powershell
.\build_installer.ps1 -SkipBuild
```

### Opción 3: Abrir carpeta al terminar

```powershell
.\build_installer.ps1 -OpenFolder
```

---

## 📦 Qué Incluye el Instalador

El instalador generado (`CRES_Carnets_Setup_v2.3.2.exe`) incluye:

✅ **Aplicación completa**
   - Ejecutable principal
   - DLLs necesarias
   - Recursos y assets
   - Archivo de versión

✅ **Wizard de instalación**
   - Interfaz gráfica moderna
   - Información del sistema
   - Selección de ubicación
   - Creación de accesos directos

✅ **Configuración automática**
   - Icono en escritorio
   - Entrada en menú inicio
   - Desinstalador en Windows
   - Variables de entorno

✅ **Documentación**
   - Manual de usuario
   - Información de licencia
   - Guía de solución de problemas

---

## 👥 Distribución a Usuarios

### Paso 1: Generar el instalador
```powershell
.\build_installer.ps1
```

### Paso 2: Ubicar el archivo
El instalador estará en:
```
releases/installers/CRES_Carnets_Setup_v2.3.2.exe
```

### Paso 3: Distribuir
Puedes compartir el archivo por:
- Correo electrónico
- USB
- Red local compartida
- OneDrive / Google Drive
- Servidor web institucional

### Paso 4: Instrucciones para usuarios

Envía estas instrucciones a los usuarios:

```
INSTALACIÓN DE CRES CARNETS:

1. Descarga el archivo CRES_Carnets_Setup_v2.3.2.exe
2. Haz doble clic en el archivo
3. Windows puede mostrar un aviso de seguridad:
   - Click en "Más información"
   - Click en "Ejecutar de todos modos"
4. Sigue el asistente de instalación:
   - Click en "Siguiente"
   - Acepta los términos
   - Click en "Instalar"
5. Al finalizar, marca "Ejecutar CRES Carnets"
6. ¡Listo! La app se abrirá automáticamente

PRIMER USO:
- Ingresa tu usuario y contraseña
- Selecciona tu campus/institución
- Haz clic en "Iniciar Sesión"

¿Problemas? Contacta: innova.salud@uagro.mx
```

---

## 🔧 Estructura de Archivos

```
CRES_Carnets_UAGROPRO/
├── installer/
│   ├── setup_script.iss         # Script de Inno Setup
│   ├── info_before.txt          # Información pre-instalación
│   ├── README_USUARIO.txt       # Manual de usuario
│   ├── wizard_image.bmp         # Imagen grande del wizard (opcional)
│   └── wizard_small.bmp         # Imagen pequeña del wizard (opcional)
├── version.json                 # Información de versión
├── LICENSE.txt                  # Licencia de uso
├── build_installer.ps1          # Script generador
└── releases/
    └── installers/              # Aquí se generan los instaladores
        └── CRES_Carnets_Setup_v2.3.2.exe
```

---

## 🎨 Personalización

### Cambiar Versión

Edita `version.json`:
```json
{
  "version": "2.3.3",
  "buildNumber": 2,
  ...
}
```

### Modificar Información del Instalador

Edita `installer/setup_script.iss`:
- Línea 5-9: Información básica
- Línea 50-51: Imágenes del wizard
- Línea 58-60: Tareas adicionales

### Agregar/Quitar Archivos

En `setup_script.iss`, sección `[Files]`:
```iss
Source: "tu_archivo.txt"; DestDir: "{app}"; Flags: ignoreversion
```

---

## 🐛 Solución de Problemas

### "No se encontró Inno Setup"

**Solución:**
1. Descarga desde https://jrsoftware.org/isdl.php
2. Instala en la ubicación por defecto
3. Reinicia PowerShell
4. Intenta de nuevo

### "Error en la compilación de Flutter"

**Solución:**
```powershell
flutter clean
flutter pub get
flutter build windows --release
```

### "El ejecutable no se encuentra"

**Solución:**
Verifica que existe:
```
build/windows/x64/runner/Release/cres_carnets_ibmcloud.exe
```

Si no existe, compila primero:
```powershell
flutter build windows --release
```

### "El instalador es muy grande"

**Normal:** El instalador incluye:
- Aplicación Flutter (~80-150 MB)
- Runtime de Visual C++ 
- Assets y recursos

Tamaño típico: 150-250 MB

---

## 📊 Estadísticas

- **Tiempo de generación:** 2-5 minutos
- **Tamaño del instalador:** ~200 MB
- **Tiempo de instalación:** 30-60 segundos
- **Espacio requerido:** 500 MB

---

## 🔐 Seguridad

### Firma Digital (Opcional)

Para evitar advertencias de Windows SmartScreen:

1. Obtén un certificado de firma de código
2. Firma el instalador:
```powershell
signtool sign /f certificado.pfx /p contraseña /t http://timestamp.digicert.com CRES_Carnets_Setup_v2.3.2.exe
```

### Checksum

Genera un checksum para verificar integridad:
```powershell
Get-FileHash releases/installers/CRES_Carnets_Setup_v2.3.2.exe -Algorithm SHA256
```

Comparte el checksum con los usuarios para que verifiquen.

---

## 📝 Notas Adicionales

- El instalador requiere permisos de administrador
- Se detecta y desinstala versiones anteriores automáticamente
- Los datos de usuario NO se eliminan al actualizar
- El instalador es silencioso si se ejecuta con `/SILENT`

---

## 🆘 Soporte

Si tienes problemas:

1. Revisa esta documentación
2. Verifica los logs en `releases/installers/`
3. Contacta: innova.salud@uagro.mx

---

**Creado por:** Dirección de Innovación en Salud UAGro  
**Última actualización:** Octubre 2025  
**Versión:** 2.3.2
