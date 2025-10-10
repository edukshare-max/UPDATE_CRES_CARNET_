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
├── android/                    # Releases de Android
│   ├── apk/                    # Archivos APK
│   │   └── CRES_Carnets_YYYY-MM-DD_HH-mm-ss.apk
│   ├── bundle/                 # Archivos AAB
│   │   └── CRES_Carnets_YYYY-MM-DD_HH-mm-ss.aab
│   └── CRES_Carnets_Android_YYYY-MM-DD_HH-mm-ss.txt
```

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