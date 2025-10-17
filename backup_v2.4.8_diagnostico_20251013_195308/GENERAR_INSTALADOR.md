# 🚀 Cómo Generar el Instalador de Producción

## Método 1: Usando Inno Setup (Recomendado)

### Paso 1: Instalar Inno Setup
1. Descarga Inno Setup 6: https://jrsoftware.org/isdl.php
2. Ejecuta el instalador descargado
3. Instala en la ubicación por defecto: `C:\Program Files (x86)\Inno Setup 6\`
4. Completa la instalación

### Paso 2: Generar el Instalador
```powershell
# Opción A: Usar el script automático (recomendado)
.\build_installer.ps1

# Opción B: Manual desde PowerShell
cd C:\CRES_Carnets_UAGROPRO
flutter clean
flutter pub get
flutter build windows --release
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" .\installer\setup_script.iss
```

### Resultado:
- **Archivo generado**: `releases\installers\CRES_Carnets_Setup_v2.3.2.exe`
- **Tamaño aproximado**: ~80-120 MB
- **Listo para distribuir**: ✅

---

## Método 2: Usando Script PowerShell Manual (Sin Inno Setup)

Si no quieres instalar Inno Setup, puedes crear un instalador simple con PowerShell:

```powershell
.\create_simple_installer.ps1
```

Este script:
- Copia los archivos compilados a una carpeta
- Crea un ZIP con todo lo necesario
- Genera un script de instalación básico

---

## ¿Dónde está el instalador?

Después de generar, busca el archivo aquí:
- **Con Inno Setup**: `C:\CRES_Carnets_UAGROPRO\releases\installers\CRES_Carnets_Setup_v2.3.2.exe`
- **ZIP manual**: `C:\CRES_Carnets_UAGROPRO\releases\CRES_Carnets_v2.3.2.zip`

---

## Compartir con Usuarios

### 1. Sube el instalador a:
- **OneDrive**: Crea link compartido
- **Google Drive**: Compartir como "Cualquiera con el enlace"
- **Servidor web**: Sube por FTP/SFTP

### 2. Envía las instrucciones a usuarios:
Ver archivo: `INSTRUCCIONES_INSTALACION_USUARIOS.md`

---

## Verificar el Instalador

Antes de distribuir, prueba en una máquina limpia:
1. Ejecuta el instalador
2. Completa la instalación
3. Abre la aplicación
4. Inicia sesión con usuario de prueba
5. Verifica todas las funciones principales

---

## Solución de Problemas

### "No se encuentra ISCC.exe"
- Verifica que Inno Setup está instalado
- Busca manualmente: `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`
- Si está en otra ubicación, edita `deploy.ps1` línea 16

### "Flutter build failed"
```powershell
flutter clean
flutter pub get
flutter doctor -v
```

### "Faltan archivos DLL en el instalador"
- Verifica que se compiló en modo `--release`
- Las DLLs están en: `build\windows\x64\runner\Release\`

---

## Estado Actual

✅ Aplicación compilada: `build\windows\x64\runner\Release\cres_carnets_ibmcloud.exe`  
✅ Script de Inno Setup listo: `installer\setup_script.iss`  
⏳ **Siguiente paso**: Instalar Inno Setup o crear instalador manual
