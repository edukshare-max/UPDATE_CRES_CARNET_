# 🧪 Guía de Pruebas - Sistema de Autenticación Flutter

## 📱 Estado Actual
- ✅ **App corriendo**: `cres_carnets_ibmcloud.exe` en modo debug
- ✅ **Backend**: https://fastapi-backend-o7ks.onrender.com
- ✅ **Usuario admin**: DireccionInnovaSalud / Admin2025 / llano-largo

---

## 🎯 PRUEBA 1: Primera Carga de la App (Sin Token)

### Objetivo
Verificar que la app detecta que no hay sesión y muestra el LoginScreen.

### Pasos
1. ✅ La app ya está corriendo
2. **OBSERVAR**: ¿Qué pantalla se muestra?
   - ✅ **Esperado**: LoginScreen con formulario de login
   - ❌ **Incorrecto**: Si muestra Dashboard directamente

### Resultado Esperado
- Pantalla de login con:
  - Logo médico (ícono medical_services)
  - Título: "SISTEMA DE CARNETS"
  - Subtítulo: "SASU - UAGro"
  - Tres campos: Usuario, Contraseña, Campus
  - Botón verde: "INICIAR SESIÓN"
  - Fondo con gradiente azul marino → dorado

---

## 🔐 PRUEBA 2: Login Exitoso con Credenciales Correctas

### Objetivo
Verificar que el usuario puede autenticarse correctamente con el backend.

### Pasos
1. **Ingresar credenciales**:
   - Usuario: `DireccionInnovaSalud`
   - Contraseña: `Admin2025`
   - Campus: Seleccionar **"Llano Largo"** del dropdown

2. **Presionar** botón "INICIAR SESIÓN"

3. **OBSERVAR**:
   - ¿Aparece CircularProgressIndicator (spinner)?
   - ¿La app hace la petición al backend?
   - ¿Navega a una nueva pantalla?

### Resultado Esperado
- ✅ Loading spinner visible durante 1-3 segundos
- ✅ Navegación automática a pantalla de Dashboard
- ✅ **IMPORTANTE**: Si hay AuthGate (PIN), debe solicitarlo
- ✅ Token JWT guardado en FlutterSecureStorage

### Si hay error
- Verificar conectividad a internet
- Revisar consola de Flutter para mensajes de error
- Verificar que el backend esté activo: https://fastapi-backend-o7ks.onrender.com/docs

---

## 📊 PRUEBA 3: Dashboard - Visualización de Información del Usuario

### Objetivo
Verificar que el Dashboard muestra correctamente la información del usuario autenticado.

### Pasos
1. **Una vez en el Dashboard**, revisar el AppBar (barra superior azul marino)

2. **VERIFICAR**:
   - ¿Se muestra el nombre completo del usuario?
   - ¿Se muestra el rol y campus?
   - ¿Hay un botón de logout visible?

### Resultado Esperado

**AppBar debe mostrar**:
- **Título**: "CRES Carnets - UAGro"
- **Subtítulo**: "Administrador - Llano Largo"
- **Lado derecho**: "DireccionInnovaSalud" (o nombre completo si está en BD)
- **Botón logout**: Ícono de salida (exit_to_app)

### Ejemplo Visual
```
┌──────────────────────────────────────────────────┐
│ CRES Carnets - UAGro    DireccionInnovaSalud [⎋] │
│ Administrador - Llano Largo                       │
└──────────────────────────────────────────────────┘
```

---

## 🚪 PRUEBA 4: Logout con Confirmación

### Objetivo
Verificar que el logout funciona correctamente y limpia la sesión.

### Pasos
1. **En el Dashboard**, hacer clic en el **botón de logout** (ícono de salida)

2. **VERIFICAR**: ¿Aparece un diálogo de confirmación?

3. **En el diálogo**:
   - Título: "Cerrar Sesión"
   - Mensaje: "¿Estás seguro que deseas salir?"
   - Botones: "Cancelar" y "Salir" (rojo)

4. **Hacer clic en "Salir"**

5. **OBSERVAR**:
   - ¿La app navega de vuelta al LoginScreen?
   - ¿Se limpia toda la información del usuario?

### Resultado Esperado
- ✅ Diálogo de confirmación aparece
- ✅ Al confirmar, regresa a LoginScreen
- ✅ Token eliminado de FlutterSecureStorage
- ✅ Datos de usuario eliminados

---

## 🔄 PRUEBA 5: Persistencia de Sesión (Hot Reload)

### Objetivo
Verificar que la sesión se mantiene después de un hot reload.

### Pasos
1. **Hacer login** con las credenciales correctas
2. **Llegar al Dashboard**
3. **En la terminal de Flutter**, presionar tecla **`r`** (hot reload)
4. **OBSERVAR**: ¿La app mantiene la sesión?

### Resultado Esperado
- ✅ Después del hot reload, la app debe mantenerse en Dashboard
- ✅ Información del usuario debe seguir visible
- ✅ Token debe persistir en FlutterSecureStorage

---

## 🔄 PRUEBA 6: Persistencia de Sesión (Restart Completo)

### Objetivo
Verificar que la sesión se mantiene después de reiniciar la app completamente.

### Pasos
1. **Hacer login** con las credenciales correctas
2. **Llegar al Dashboard**
3. **En la terminal de Flutter**, presionar tecla **`R`** (hot restart - mayúscula)
4. **OBSERVAR**: ¿La app detecta el token y salta directamente al Dashboard?

### Resultado Esperado
- ✅ App inicia y verifica token existente
- ✅ Salta directamente al Dashboard (sin mostrar LoginScreen)
- ✅ Información del usuario cargada correctamente
- ✅ AuthGate (PIN) puede solicitar nuevamente el código

---

## ❌ PRUEBA 7: Login con Credenciales Incorrectas

### Objetivo
Verificar el manejo de errores cuando las credenciales son incorrectas.

### Pasos
1. **Hacer logout** si estás autenticado
2. **En LoginScreen**, ingresar:
   - Usuario: `usuarioIncorrecto`
   - Contraseña: `passwordIncorrecto`
   - Campus: Cualquier opción

3. **Presionar** "INICIAR SESIÓN"

4. **OBSERVAR**: ¿Aparece mensaje de error?

### Resultado Esperado
- ✅ Loading spinner durante la petición
- ✅ Mensaje de error aparece: "Usuario o contraseña incorrectos"
- ✅ Container rojo con el mensaje de error
- ✅ Permanece en LoginScreen
- ✅ **NO** navega al Dashboard

---

## ❌ PRUEBA 8: Validación de Campos Obligatorios

### Objetivo
Verificar que el formulario valida campos requeridos.

### Pasos
1. **En LoginScreen**, dejar campos vacíos
2. **Presionar** "INICIAR SESIÓN" sin ingresar nada

3. **OBSERVAR**: ¿Aparecen mensajes de validación?

### Resultado Esperado
- ✅ Campos requeridos muestran error
- ✅ **NO** hace petición al backend
- ✅ Formulario previene submit hasta que campos sean válidos

---

## 🔒 PRUEBA 9: AuthGate (PIN) - Segunda Capa de Seguridad

### Objetivo
Verificar que el AuthGate (PIN local) funciona correctamente después del login.

### Pasos
1. **Hacer login** exitosamente
2. **OBSERVAR**: ¿Aparece una pantalla solicitando PIN?

### Resultado Esperado
- ✅ Después del login, aparece AuthGate solicitando PIN
- ✅ Usuario debe ingresar PIN configurado previamente
- ✅ Solo después del PIN correcto, accede al Dashboard
- ✅ **Doble autenticación**: Backend JWT + PIN local

---

## 📱 PRUEBA 10: Navegación del Dashboard

### Objetivo
Verificar que todas las opciones del Dashboard son accesibles.

### Pasos
1. **Estando en Dashboard autenticado**
2. **Verificar las 4 opciones**:
   - Nuevo Carnet Estudiantil
   - Administrar Expedientes
   - Promoción de Salud
   - Vacunación

3. **Hacer clic en cada una** y verificar que navega correctamente

### Resultado Esperado
- ✅ Todas las opciones visibles para rol "admin"
- ✅ Navegación funciona correctamente
- ✅ Botón "Atrás" regresa al Dashboard
- ✅ Información del usuario sigue visible en AppBar

---

## 🐛 Troubleshooting - Problemas Comunes

### ❌ No aparece LoginScreen al iniciar
**Posible causa**: Token anterior guardado
**Solución**: 
1. Hacer logout manualmente
2. O ejecutar en terminal: `r` (hot reload)

### ❌ Error de conexión al hacer login
**Posible causa**: Backend inaccesible o internet
**Solución**:
1. Verificar internet
2. Abrir en navegador: https://fastapi-backend-o7ks.onrender.com/docs
3. Esperar si backend está en cold start

### ❌ Spinner infinito durante login
**Posible causa**: Timeout o error no manejado
**Solución**:
1. Ver consola de Flutter: `flutter logs`
2. Verificar respuesta del backend
3. Hot reload: tecla `r`

### ❌ No se muestra información del usuario en Dashboard
**Posible causa**: Datos del usuario no guardados correctamente
**Solución**:
1. Hacer logout y volver a login
2. Verificar consola para errores de deserialización
3. Hot restart: tecla `R`

---

## ✅ Checklist de Validación Final

Marca cada item después de probarlo:

- [ ] **PRUEBA 1**: App inicia en LoginScreen (sin token previo)
- [ ] **PRUEBA 2**: Login exitoso con credenciales correctas
- [ ] **PRUEBA 3**: Dashboard muestra nombre, rol y campus correctamente
- [ ] **PRUEBA 4**: Logout con confirmación funciona
- [ ] **PRUEBA 5**: Sesión persiste después de hot reload (r)
- [ ] **PRUEBA 6**: Sesión persiste después de hot restart (R)
- [ ] **PRUEBA 7**: Error visible con credenciales incorrectas
- [ ] **PRUEBA 8**: Validación de campos obligatorios
- [ ] **PRUEBA 9**: AuthGate (PIN) solicita código correctamente
- [ ] **PRUEBA 10**: Navegación del Dashboard funciona

---

## 📊 Comandos Útiles de Flutter

Durante las pruebas, puedes usar estos comandos en la terminal:

- **`r`** - Hot reload (recarga código sin reiniciar)
- **`R`** - Hot restart (reinicia app completa)
- **`h`** - Lista todos los comandos disponibles
- **`c`** - Limpia la consola
- **`q`** - Cierra la app y sale de Flutter

---

## 📝 Registro de Pruebas

### Sesión de Prueba: [FECHA Y HORA]

| Prueba | Estado | Notas |
|--------|--------|-------|
| 1. Primera carga sin token | ⏳ | |
| 2. Login exitoso | ⏳ | |
| 3. Info usuario en Dashboard | ⏳ | |
| 4. Logout con confirmación | ⏳ | |
| 5. Persistencia hot reload | ⏳ | |
| 6. Persistencia hot restart | ⏳ | |
| 7. Credenciales incorrectas | ⏳ | |
| 8. Validación de campos | ⏳ | |
| 9. AuthGate PIN | ⏳ | |
| 10. Navegación Dashboard | ⏳ | |

**Leyenda**: ✅ Exitoso | ❌ Fallido | ⏳ Pendiente | ⚠️ Parcial

---

## 🎯 Próximos Pasos Después de las Pruebas

Una vez completadas todas las pruebas:

1. **Si todo funciona**: Proceder a FASE 9 (Gestión de Sesión avanzada)
2. **Si hay errores**: Documentar y corregir antes de continuar
3. **Crear usuarios de prueba**: Usar panel web para crear médico, nutrición, recepción
4. **Probar con diferentes roles**: Verificar permisos (FASE 10)

---

**Versión**: 1.0  
**Fecha**: Octubre 2025  
**Sistema**: CRES Carnets - SASU UAGro
