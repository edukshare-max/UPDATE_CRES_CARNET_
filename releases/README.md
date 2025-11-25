# CRES Carnets - Generación de Releases

Este proyecto incluye scripts automatizados para generar releases de Windows y Android sin conflictos.

## 📁 Estructura de Releases

```
releases/
├── windows/                    # Releases de Windows
│   ├── CRES_Carnets_Windows_YYYY-MM-DD_HH-mm-ss/
│   │   ├── cres_carnets_ibmcloud.exe
│   │   ├── flutter_windows.dll
│   │   ├── data/
│   │   └── README.txt
│   └── Instaladores/
│       └── CRES_Carnets_Setup_v2.4.20.exe (13.22 MB)
├── android/                    # ✨ Nuevo: Releases de Android
│   ├── CRES_Carnets_v2.4.20_arm64-v8a.apk (21.18 MB) ⭐ Recomendado
│   ├── CRES_Carnets_v2.4.20_armeabi-v7a.apk (19.09 MB)
│   ├── CRES_Carnets_v2.4.20_universal.apk (60.39 MB)
│   ├── CRES_Carnets_v2.4.20_x86_64.apk (22.36 MB)
│   ├── README_ANDROID.md (instrucciones detalladas)
│   └── DESCARGAS_RAPIDAS.md (enlaces directos)
```

## 📱 Android v2.4.20 (Nuevo)

### APKs disponibles:
- **arm64-v8a** (21 MB): Para dispositivos modernos 2017+ (⭐ Recomendado)
- **armeabi-v7a** (19 MB): Para dispositivos antiguos pre-2017
- **universal** (60 MB): Compatible con TODOS los dispositivos
- **x86_64** (22 MB): Para emuladores y tablets x86

Ver [android/README_ANDROID.md](android/README_ANDROID.md) para instrucciones de instalación.

## 🚀 Cómo usar los scripts

### Opción 1: Script principal (recomendado)
```powershell
.\build_releases.ps1
```
Te permite seleccionar qué plataforma compilar.

### Opción 2: Scripts individuales
```powershell
# Solo Windows
.\build_windows_release.ps1

# Solo Android
.\build_android_release.ps1
```

## 📋 Requisitos previos

### Para Windows:
- Flutter SDK instalado
- Visual Studio 2022 con Desktop development with C++
- Windows 10 SDK

### Para Android:
- Flutter SDK instalado
- Android Studio con Android SDK
- Java Development Kit (JDK)

## 🔧 Verificar requisitos

Ejecuta estos comandos para verificar que todo esté configurado:

```powershell
flutter doctor
flutter doctor -v
```

## 📱 Tipos de build de Android

### APK (Android Package)
- Para distribución directa e instalación manual
- Archivo: `.apk`
- Uso: Enviar por WhatsApp, email, USB, etc.

### AAB (Android App Bundle)
- Para publicación en Google Play Store
- Archivo: `.aab`
- Uso: Subir a Google Play Console

## 🎯 Características de los scripts

### ✅ Ventajas:
- **Sin conflictos**: Cada build se guarda en carpetas separadas con timestamp
- **Automático**: Limpia, compila y organiza automáticamente
- **Documentado**: Genera archivos README con cada release
- **Flexible**: Elige Windows, Android o ambos
- **Informativo**: Muestra progreso y abre carpetas al completar

### 📋 Lo que hacen automáticamente:
1. `flutter clean` - Limpia builds previos
2. `flutter pub get` - Actualiza dependencias
3. `flutter build` - Compila la aplicación
4. Organiza archivos en carpetas con timestamp
5. Genera documentación de la release
6. Abre las carpetas correspondientes

## 🔍 Solución de problemas

### Error: "No se puede ejecutar scripts"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error de compilación Android
1. Verifica que Android Studio esté instalado
2. Ejecuta `flutter doctor` y soluciona problemas
3. Asegúrate de tener las licencias de Android aceptadas:
   ```powershell
   flutter doctor --android-licenses
   ```

### Error de compilación Windows
1. Verifica Visual Studio 2022 con C++ workload
2. Instala Windows 10 SDK
3. Ejecuta `flutter doctor` para verificar

## 📞 Soporte

Si encuentras problemas:
1. Ejecuta `flutter doctor -v` y revisa los errores
2. Verifica que tengas las dependencias instaladas
3. Consulta la documentación oficial de Flutter

## 🎉 ¡Listo!

Cada vez que ejecutes los scripts, tendrás releases organizados y listos para distribuir sin que se sobrescriban entre plataformas.