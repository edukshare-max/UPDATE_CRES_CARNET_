# 🧪 Guía Rápida de Pruebas - Modo Híbrido Offline

## 🎯 Objetivo
Probar el sistema híbrido online/offline para asegurar que funciona correctamente con/sin internet.

---

## ✅ PRUEBA 1: Login Online Normal (2 minutos)

### Estado Inicial
- ✅ Computadora CON internet
- ✅ Primera vez o después de logout

### Pasos
1. Abrir la aplicación
2. Ingresar credenciales:
   - Usuario: `DireccionInnovaSalud`
   - Contraseña: `Admin2025`
   - Campus: `Llano Largo`
3. Presionar "INICIAR SESIÓN"

### Resultado Esperado
- ✅ Login exitoso (modo online)
- ✅ Navegación a Dashboard
- ✅ AppBar muestra: "Administrador - Llano Largo"
- ✅ Nombre visible: "DireccionInnovaSalud"
- ✅ **NO** aparece badge "OFFLINE" (está online)
- ✅ **NO** aparece ConnectionIndicator (sin pendientes)

---

## 🔌 PRUEBA 2: Simular Pérdida de Conexión (3 minutos)

### Estado Inicial
- ✅ Usuario ya hizo login online al menos una vez
- ✅ Sesión cerrada (logout)

### Pasos
1. **DESCONECTAR INTERNET**:
   - Windows: Clic derecho en WiFi → Desconectar
   - O: Modo avión
   - O: Desconectar cable Ethernet

2. Abrir la aplicación (si estaba cerrada)

3. Intentar login con mismas credenciales:
   - Usuario: `DireccionInnovaSalud`
   - Contraseña: `Admin2025`
   - Campus: `Llano Largo`

4. Presionar "INICIAR SESIÓN"

### Resultado Esperado
- ✅ Loading spinner durante 2-3 segundos
- ✅ SnackBar naranja aparece:
  ```
  🌥️ Modo sin conexión: Los datos se sincronizarán 
  cuando tengas internet
  ```
- ✅ Login exitoso (modo offline)
- ✅ Navegación a Dashboard
- ✅ AppBar muestra badge **"🌥️ OFFLINE"** (naranja)
- ✅ ConnectionIndicator visible:
  ```
  🌥️ Modo Sin Conexión
  Los cambios se sincronizarán cuando tengas internet
  ```

### ⚠️ Si Falla
- **Error**: "Sin conexión. No se puede validar usuario. Conéctate a internet para iniciar sesión por primera vez."
- **Causa**: No hay cache guardado (nunca hizo login online antes)
- **Solución**: Volver a PRUEBA 1 primero con internet

---

## 🔄 PRUEBA 3: Reconexión Automática (2 minutos)

### Estado Inicial
- ✅ Modo offline activo (badge naranja visible)
- ✅ Dashboard abierto

### Pasos
1. **RECONECTAR INTERNET**:
   - Windows: Clic en WiFi → Conectar
   - O: Desactivar modo avión
   - O: Conectar cable Ethernet

2. **ESPERAR 5-10 SEGUNDOS** (no hacer nada)

3. Observar cambios automáticos

### Resultado Esperado
- ✅ ConnectionIndicator detecta conexión
- ✅ Inicia sincronización automática
- ✅ SnackBar verde aparece:
  ```
  ✅ Sincronización completada
  ```
- ✅ Badge "OFFLINE" desaparece del AppBar
- ✅ ConnectionIndicator se oculta (si no hay pendientes)

---

## 🔐 PRUEBA 4: Credenciales Incorrectas Offline (1 minuto)

### Estado Inicial
- ✅ Internet DESCONECTADO
- ✅ Sesión cerrada

### Pasos
1. Intentar login con contraseña INCORRECTA:
   - Usuario: `DireccionInnovaSalud`
   - Contraseña: `PasswordIncorrecto123`
   - Campus: `Llano Largo`

2. Presionar "INICIAR SESIÓN"

### Resultado Esperado
- ✅ Mensaje de error:
  ```
  Sin conexión. No se puede validar usuario.
  Conéctate a internet para iniciar sesión por primera vez.
  ```
- ✅ **NO** debe permitir acceso
- ✅ Permanece en LoginScreen

### 📝 Nota
El sistema solo valida offline si:
- La contraseña coincide con el hash guardado
- El cache no ha expirado (<7 días)

---

## ⏰ PRUEBA 5: Persistencia de Sesión Offline (2 minutos)

### Estado Inicial
- ✅ Login offline exitoso
- ✅ Dashboard abierto con badge "OFFLINE"

### Pasos
1. En terminal de Flutter, presionar **`R`** (hot restart)
2. Esperar que app reinicie

### Resultado Esperado
- ✅ App inicia directamente en Dashboard (no pide login)
- ✅ Badge "OFFLINE" sigue visible
- ✅ Información de usuario cargada correctamente
- ✅ ConnectionIndicator sigue mostrando modo offline

---

## 🚫 PRUEBA 6: Primer Login SIN Internet (DEBE FALLAR)

### Estado Inicial
- ✅ Borrar datos de app (simular instalación fresca)
  - Método 1: Desinstalar y reinstalar
  - Método 2: Eliminar cache de FlutterSecureStorage manualmente
- ✅ Internet DESCONECTADO

### Pasos
1. Abrir app (fresh install)
2. Intentar login:
   - Usuario: `DireccionInnovaSalud`
   - Contraseña: `Admin2025`
   - Campus: `Llano Largo`

3. Presionar "INICIAR SESIÓN"

### Resultado Esperado
- ✅ Error visible:
  ```
  ❌ Sin conexión. No se puede validar usuario.
  Conéctate a internet para iniciar sesión por primera vez.
  ```
- ✅ **NO** debe permitir acceso
- ✅ Permanece en LoginScreen

### 📝 Conclusión
El sistema **REQUIERE** primer login con internet para guardar el cache.

---

## 📊 Checklist de Validación

Marca cada prueba después de completarla:

- [ ] **PRUEBA 1**: Login online normal ✅
- [ ] **PRUEBA 2**: Login offline con cache ✅
- [ ] **PRUEBA 3**: Reconexión automática ✅
- [ ] **PRUEBA 4**: Credenciales incorrectas offline ✅
- [ ] **PRUEBA 5**: Persistencia de sesión offline ✅
- [ ] **PRUEBA 6**: Primer login sin internet (falla esperado) ✅

---

## 🐛 Troubleshooting

### ❌ Error: "No se puede validar usuario" (con internet)
**Causa**: Backend no responde o timeout
**Solución**: 
1. Verificar que backend está activo: https://fastapi-backend-o7ks.onrender.com/docs
2. Esperar si está en cold start (15-30 segundos)
3. Verificar conexión a internet

### ❌ Error: Login offline no funciona
**Causa**: No hay cache guardado
**Solución**:
1. Conectar internet
2. Hacer login online primero (PRUEBA 1)
3. Logout
4. Desconectar internet
5. Intentar login offline (PRUEBA 2)

### ❌ Badge "OFFLINE" no desaparece después de reconectar
**Causa**: Sincronización no detectada
**Solución**:
1. Presionar botón sync manualmente en ConnectionIndicator
2. O hacer hot restart (tecla `R`)
3. Verificar logs: `flutter logs`

### ❌ ConnectionIndicator no aparece
**Causa**: Está en modo online sin datos pendientes (comportamiento normal)
**Solución**: NO es error, el indicador se oculta cuando todo está normal

---

## 📱 Comandos Útiles Durante Pruebas

### En Terminal de Flutter:
- **`r`** - Hot reload (recarga código sin reiniciar)
- **`R`** - Hot restart (reinicia app completamente)
- **`c`** - Limpia consola
- **`q`** - Cierra app

### En PowerShell (Administrador):
```powershell
# Listar interfaces de red
netsh interface show interface

# Deshabilitar WiFi
netsh interface set interface "Wi-Fi" disabled

# Habilitar WiFi
netsh interface set interface "Wi-Fi" enabled

# Alternativamente, usar modo avión en Windows:
# Windows + A → Clic en "Modo avión"
```

---

## 🎯 Resultados Esperados - Resumen

| Escenario | Internet | Cache | Resultado |
|-----------|----------|-------|-----------|
| Primer login | ✅ SÍ | ❌ NO | ✅ Login exitoso online |
| Primer login | ❌ NO | ❌ NO | ❌ Error: "Conéctate a internet" |
| Login subsecuente | ✅ SÍ | ✅ SÍ | ✅ Login online + actualiza cache |
| Login subsecuente | ❌ NO | ✅ SÍ | ✅ Login offline exitoso |
| Login subsecuente | ❌ NO | ⚠️ EXPIRADO | ❌ Error: "Cache expirado" |
| Password incorrecta | ✅ SÍ | ✅ SÍ | ❌ Error: "Credenciales incorrectas" |
| Password incorrecta | ❌ NO | ✅ SÍ | ❌ Error: "No se puede validar" |

---

## 📝 Registro de Pruebas

**Fecha**: _______________  
**Probado por**: _______________  
**Versión**: 2.0 - Modo Híbrido

| Prueba | Estado | Notas/Observaciones |
|--------|--------|---------------------|
| 1. Login online | ⏳ | |
| 2. Login offline | ⏳ | |
| 3. Reconexión auto | ⏳ | |
| 4. Credenciales incorrectas | ⏳ | |
| 5. Persistencia sesión | ⏳ | |
| 6. Primer login sin internet | ⏳ | |

**Leyenda**: ✅ Exitoso | ❌ Fallido | ⏳ Pendiente | ⚠️ Parcial

---

## ✨ Características Adicionales Implementadas

- ✅ Detección automática de conexión en tiempo real
- ✅ Stream de cambios de conectividad
- ✅ Hash seguro SHA-256 con 10,000 iteraciones
- ✅ Cache con expiración de 7 días
- ✅ Cola de sincronización para datos pendientes
- ✅ Sincronización automática al reconectar
- ✅ Sincronización manual disponible
- ✅ Indicadores visuales claros (badge + indicator)
- ✅ SnackBars informativos de estado
- ✅ Tokens offline temporales
- ✅ Modo completamente transparente para el usuario

---

**Sistema listo para usar en ambientes con conectividad intermitente** 🎉

---

**Documentación completa**: Ver `MODO_HIBRIDO_OFFLINE.md`
