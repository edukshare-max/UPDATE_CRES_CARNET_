# Script de Diagnóstico - Login Offline v2.4.5

**IMPORTANTE:** Esta versión incluye logs detallados para diagnosticar el problema de login offline.

## 🔍 Cómo usar esta versión de diagnóstico

### Paso 1: Instalar v2.4.5
```
CRES_Carnets_Setup_v2.4.5.exe
```

### Paso 2: Primer login CON internet
1. Asegúrate de tener conexión a internet
2. Abre la aplicación
3. Ingresa tus credenciales
4. **FÍJATE QUÉ CAMPUS SELECCIONASTE** (importante)
5. Inicia sesión

### Paso 3: Revisar logs del primer login
La consola mostrará algo como:
```
🔐 Iniciando login para: usuario_prueba, campus: cres-llano-largo
💾 Cache disponible: false
🌐 Conexión detectada: true
🌍 Intentando login online...
✅ Login online exitoso
💾 [CACHE] Guardando hash para usuario: usuario_prueba, campus: cres-llano-largo
✅ [CACHE] Hash guardado exitosamente
```

**ANOTA EL VALOR DEL CAMPUS QUE APARECE EN EL LOG**

### Paso 4: Segundo login SIN internet
1. **IMPORTANTE:** Cierra completamente la aplicación
2. Desconecta WiFi/Ethernet
3. Abre la aplicación nuevamente
4. Ingresa las MISMAS credenciales
5. **USA EL MISMO CAMPUS que en el paso 2**

### Paso 5: Revisar logs del segundo login
La consola debería mostrar:
```
🔐 Iniciando login para: usuario_prueba, campus: cres-llano-largo
🔎 [CACHE] Verificando si existe cache para: usuario_prueba, campus: cres-llano-largo
📦 [CACHE] Cache existe - Usuario: usuario_prueba, Campus: cres-llano-largo
✅ [CACHE] Cache coincide
💾 Cache disponible: true
🌐 Conexión detectada: false
📴 Sin conexión pero hay cache - intentando login offline directo
🔍 [CACHE] Validando credenciales offline para: usuario_prueba, campus: cres-llano-largo
📦 [CACHE] Cache encontrado - Usuario: usuario_prueba, Campus: cres-llano-largo
⏰ [CACHE] Cache válido (0 días desde último login)
✅ [CACHE] Hash válido - credenciales correctas
✅ Login offline exitoso para: usuario_prueba
```

## ❓ Posibles Problemas y Soluciones

### Problema 1: Campus no coincide
**Síntoma:**
```
❌ [CACHE] Campus no coincide: "cres-llano-largo" vs "llano-largo"
```

**Causa:** El backend devuelve un formato de campus diferente al que se envió

**Solución:** El código debe normalizar el campus o usar el valor del backend

### Problema 2: Usuario no coincide
**Síntoma:**
```
❌ [CACHE] Usuario no coincide: "usuario1" vs "usuario2"
```

**Causa:** Estás usando un usuario diferente

**Solución:** Usa EXACTAMENTE el mismo usuario

### Problema 3: No existe cache
**Síntoma:**
```
❌ [CACHE] No existe cache
```

**Causa:** El primer login no guardó el cache correctamente

**Solución:** 
1. Verifica que el primer login fue exitoso
2. Verifica los permisos de la app
3. Reinstala la app

### Problema 4: Cache expirado
**Síntoma:**
```
❌ [CACHE] Cache expirado: 8 días sin conexión (máximo: 7)
```

**Causa:** Han pasado más de 7 días desde el último login con internet

**Solución:** Conéctate a internet y vuelve a iniciar sesión

## 📋 Checklist de Verificación

- [ ] ¿El primer login muestra "✅ [CACHE] Hash guardado exitosamente"?
- [ ] ¿El segundo login muestra "📦 [CACHE] Cache existe"?
- [ ] ¿El campus es EXACTAMENTE el mismo en ambos intentos?
- [ ] ¿El usuario es EXACTAMENTE el mismo en ambos intentos?
- [ ] ¿La contraseña es la misma?
- [ ] ¿Cerraste completamente la app entre el primer y segundo login?

## 🐛 Si Aún No Funciona

Por favor proporciona:

1. **Logs completos del primer login** (con conexión)
2. **Logs completos del segundo login** (sin conexión)
3. **Qué campus seleccionaste**
4. **Qué mensaje de error aparece**
5. **Versión de Windows**

## 💡 Diferencias entre v2.4.4 y v2.4.5

v2.4.5 agrega:
- ✅ Logs detallados en cada paso del proceso de cache
- ✅ Muestra exactamente qué valores se comparan
- ✅ Indica si el problema es usuario, campus, contraseña o cache expirado
- ✅ Facilita diagnóstico del problema

## 🔧 Compilación

Esta versión se compiló con:
```powershell
flutter clean
flutter pub get
flutter build windows --release
```

Archivos modificados:
- `lib/data/offline_manager.dart` - Agregados logs detallados
- `pubspec.yaml` - Versión 2.4.5+5
