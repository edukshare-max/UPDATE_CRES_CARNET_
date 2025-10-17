# 🔧 VERSIÓN 2.4.2 - CORRECCIÓN DE PERMISOS

## ✅ PROBLEMA SOLUCIONADO

**Versión anterior (2.4.1):**
- ❌ Instalador requería permisos de administrador
- ❌ Se instalaba en `C:\Program Files\CRES Carnets\`
- ❌ No permitía guardar ni editar carnets
- ❌ Problemas de escritura en base de datos

**Versión nueva (2.4.2):**
- ✅ NO requiere permisos de administrador
- ✅ Se instala en `C:\Users\[usuario]\AppData\Local\CRES Carnets\`
- ✅ Permite guardar y editar carnets sin problemas
- ✅ Base de datos funciona correctamente

---

## 📦 ARCHIVOS DISPONIBLES

### Windows:
**Instalador:** `CRES_Carnets_Setup_v2.4.2.exe` (13.18 MB)
- 📍 Ubicación: `C:\CRES_Carnets_UAGROPRO\releases\installers\`
- 🔓 NO requiere permisos de administrador
- 💾 Instala en carpeta del usuario (sin restricciones)

### Android:
**APK optimizados por arquitectura:**
- `CRES_Carnets_v2.4.2_arm64-v8a.apk` (21 MB) ← **Recomendado** (90% dispositivos)
- `CRES_Carnets_v2.4.2_armeabi-v7a.apk` (18.92 MB) - Dispositivos antiguos
- `CRES_Carnets_v2.4.2_x86_64.apk` (22.23 MB) - Emuladores/Intel

📍 Ubicación: `C:\CRES_Carnets_UAGROPRO\releases\android\`

---

## 🚀 INSTRUCCIONES DE INSTALACIÓN

### Para Windows:

1. **Desinstalar versión anterior** (si tienes la 2.4.1):
   - Panel de Control → Programas → Desinstalar CRES Carnets
   - O simplemente instala la nueva versión (actualizará automáticamente)

2. **Instalar v2.4.2:**
   - Ejecuta `CRES_Carnets_Setup_v2.4.2.exe`
   - NO te pedirá permisos de administrador
   - Sigue el asistente de instalación
   - ¡Listo!

3. **Verificar que funciona:**
   - Abre CRES Carnets
   - Inicia sesión
   - Crea o edita un carnet
   - Guarda los cambios
   - ✅ Debería guardar sin problemas

### Para Android:

1. **Compartir el APK** a tu dispositivo:
   - Envía `CRES_Carnets_v2.4.2_arm64-v8a.apk` por WhatsApp, Bluetooth, etc.

2. **Instalar:**
   - Toca el archivo APK descargado
   - Habilita "Instalar desde fuentes desconocidas" si lo pide
   - Instala la app

3. **Verificar que funciona:**
   - Abre CRES Carnets
   - Inicia sesión (ahora SÍ se conectará a internet)
   - Crea o edita un carnet
   - ✅ Todo debería funcionar correctamente

---

## 🔍 CAMBIOS TÉCNICOS

### Windows (Inno Setup):
```diff
- DefaultDirName={autopf}\{#MyAppName}
+ DefaultDirName={localappdata}\{#MyAppName}

- PrivilegesRequired=admin
+ PrivilegesRequired=lowest
+ PrivilegesRequiredOverridesAllowed=dialog
```

### Android (AndroidManifest.xml):
```xml
<!-- Permisos de red agregados -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<!-- Permisos de almacenamiento -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />

<!-- Permitir tráfico HTTP si es necesario -->
<application android:usesCleartextTraffic="true" ... >
```

---

## 📊 UBICACIONES DE ARCHIVOS

### Windows:
- **Instalación:** `C:\Users\[usuario]\AppData\Local\CRES Carnets\`
- **Base de datos:** `C:\Users\[usuario]\Documents\cres_carnets.sqlite`
- **Configuración:** En la carpeta de AppData del usuario
- **Sin restricciones de escritura** ✅

### Android:
- **Instalación:** `/data/app/com.example.cres_carnets/`
- **Base de datos:** `/data/data/com.example.cres_carnets/app_flutter/`
- **Con permisos de red completos** ✅

---

## ⚠️ NOTAS IMPORTANTES

1. **Windows:** Si tenías la versión 2.4.1, la nueva instalación actualizará automáticamente y conservará tus datos (la base de datos está en Documents, no en Program Files).

2. **Android:** Si tenías una versión anterior instalada desde otra fuente, desinstálala primero antes de instalar la v2.4.2.

3. **Internet:** Ambas versiones requieren conexión a internet para:
   - Iniciar sesión
   - Sincronizar con el servidor
   - Actualizar datos en línea
   - La base de datos local funciona offline

---

## 🎯 VERIFICACIÓN POST-INSTALACIÓN

### Windows:
```
1. Abre CRES Carnets
2. Inicia sesión (usuario: admin, contraseña: tu_contraseña)
3. Ve a "Carnets" → "Nuevo Carnet"
4. Crea un carnet de prueba
5. Haz clic en "Guardar"
6. Si NO aparece error → ✅ Funcionando correctamente
```

### Android:
```
1. Abre CRES Carnets
2. Verifica que el ícono de WiFi esté activo (arriba a la derecha)
3. Inicia sesión
4. Si entra sin error de "Sin conexión" → ✅ Permisos correctos
5. Crea un carnet de prueba y guarda
6. Si guarda correctamente → ✅ Todo funcionando
```

---

## 📞 SOPORTE

Si después de instalar v2.4.2 sigues teniendo problemas:

**Windows:**
- Verifica que NO estés ejecutando la app como administrador
- Comprueba que la carpeta `C:\Users\[tu_usuario]\Documents\` existe
- Revisa que tengas espacio en disco

**Android:**
- Verifica que WiFi o datos móviles estén activados
- Comprueba que la app tenga permisos de red (Configuración → Apps → CRES Carnets → Permisos)
- Reinicia el dispositivo e intenta de nuevo

---

## ✅ RESUMEN

**Versión:** 2.4.2
**Fecha:** 2025-10-13
**Build Windows:** 13.18 MB
**Build Android:** 18.92-22.23 MB (según arquitectura)

**Cambios principales:**
- ✅ Permisos de escritura corregidos en Windows
- ✅ Permisos de red corregidos en Android
- ✅ APKs optimizados por arquitectura
- ✅ Instalación sin permisos de administrador

**Estado:** ✅ Listo para distribución
