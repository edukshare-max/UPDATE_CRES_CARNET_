# 👥 Usuarios de Prueba - FASE 10

Este documento detalla los usuarios de prueba que debes crear para validar las restricciones de permisos por rol.

## 🔑 Acceso al Panel de Administración

**URL**: https://fastapi-backend-o7ks.onrender.com/admin

**Credenciales de Admin**:
- Usuario: `DireccionInnovaSalud`
- Contraseña: `Admin2025`
- Campus: `llano-largo`

---

## 📋 Usuarios de Prueba a Crear

### 1. Dr. Juan García - Médico 👨‍⚕️

**Datos del Usuario**:
```
Username: dr.garcia
Password: Medico2025!
Email: dr.garcia@uagro.mx
Nombre Completo: Dr. Juan García Hernández
Rol: medico
Campus: acapulco
Departamento: Medicina General
```

**Permisos Esperados**:
- ✅ **Crear Carnet** (carnets:write)
- ✅ **Administrar Expedientes** (notas:write)
- ❌ Promoción de Salud (no tiene promociones:read)
- ✅ **Vacunación** (vacunacion:read)

**Dashboard Esperado**: 3 opciones (Carnet, Expedientes, Vacunación)

---

### 2. Lic. María Martínez - Nutrición 🥗

**Datos del Usuario**:
```
Username: lic.martinez
Password: Nutri2025!
Email: lic.martinez@uagro.mx
Nombre Completo: Lic. María Martínez López
Rol: nutricion
Campus: llano-largo
Departamento: Nutrición
```

**Permisos Esperados**:
- ❌ Crear Carnet (solo carnets:read, no write)
- ✅ **Administrar Expedientes** (notas:write)
- ❌ Promoción de Salud (no tiene promociones:read)
- ❌ Vacunación (no tiene vacunacion:read)

**Dashboard Esperado**: 1 opción (Solo Expedientes)

---

### 3. Psic. Carlos López - Psicología 🧠

**Datos del Usuario**:
```
Username: psic.lopez
Password: Psico2025!
Email: psic.lopez@uagro.mx
Nombre Completo: Psic. Carlos López Ramírez
Rol: psicologia
Campus: chilpancingo
Departamento: Psicología
```

**Permisos Esperados**:
- ❌ Crear Carnet (solo carnets:read)
- ✅ **Administrar Expedientes** (notas:write)
- ❌ Promoción de Salud
- ❌ Vacunación

**Dashboard Esperado**: 1 opción (Solo Expedientes)

---

### 4. Enf. Ana Rodríguez - Enfermería 💉

**Datos del Usuario**:
```
Username: enf.rodriguez
Password: Enferm2025!
Email: enf.rodriguez@uagro.mx
Nombre Completo: Enf. Ana Rodríguez Santos
Rol: enfermeria
Campus: taxco
Departamento: Enfermería
```

**Permisos Esperados**:
- ❌ Crear Carnet (solo carnets:read)
- ❌ Administrar Expedientes (no tiene notas:write)
- ❌ Promoción de Salud
- ✅ **Vacunación** (vacunacion:write)

**Dashboard Esperado**: 1 opción (Solo Vacunación)

---

### 5. Recep. Laura Sánchez - Recepción 📋

**Datos del Usuario**:
```
Username: recep.sanchez
Password: Recep2025!
Email: recep.sanchez@uagro.mx
Nombre Completo: Recep. Laura Sánchez Flores
Rol: recepcion
Campus: iguala
Departamento: Recepción
```

**Permisos Esperados**:
- ❌ Crear Carnet (solo carnets:read)
- ❌ Administrar Expedientes (no tiene notas:write)
- ❌ Promoción de Salud
- ❌ Vacunación

**Dashboard Esperado**: ⚠️ **Mensaje "Sin Permisos Asignados"**

---

### 6. Observador - Solo Lectura 👁️

**Datos del Usuario**:
```
Username: observador
Password: Lectura2025!
Email: observador@uagro.mx
Nombre Completo: Observador del Sistema
Rol: lectura
Campus: zihuatanejo
Departamento: Auditoría
```

**Permisos Esperados**:
- ❌ Crear Carnet (solo carnets:read)
- ❌ Administrar Expedientes
- ❌ Promoción de Salud
- ❌ Vacunación

**Dashboard Esperado**: ⚠️ **Mensaje "Sin Permisos Asignados"**

---

## 🧪 Pruebas a Realizar

### Test 1: Usuario Médico (Dr. García)

1. Login con `dr.garcia` / `Medico2025!` / `acapulco`
2. Verificar que el AppBar muestra:
   - "Médico - Acapulco"
   - "Dr. Juan García Hernández"
3. Verificar que el dashboard muestra **3 opciones**:
   - ✅ Crear Carnet
   - ✅ Administrar Expedientes
   - ✅ Vacunación
4. **NO debe mostrar**: Promoción de Salud
5. Intentar acceder a cada opción permitida (debe funcionar)

---

### Test 2: Usuario Nutrición (Lic. Martínez)

1. Login con `lic.martinez` / `Nutri2025!` / `llano-largo`
2. Verificar que el AppBar muestra:
   - "Nutrición - Llano Largo"
   - "Lic. María Martínez López"
3. Verificar que el dashboard muestra **1 opción**:
   - ✅ Administrar Expedientes
4. **NO debe mostrar**: Crear Carnet, Promoción de Salud, Vacunación
5. Acceder a Expedientes (debe funcionar)

---

### Test 3: Usuario Psicología (Psic. López)

1. Login con `psic.lopez` / `Psico2025!` / `chilpancingo`
2. Verificar que el AppBar muestra:
   - "Psicología - Chilpancingo"
   - "Psic. Carlos López Ramírez"
3. Verificar que el dashboard muestra **1 opción**:
   - ✅ Administrar Expedientes
4. **NO debe mostrar**: Crear Carnet, Promoción de Salud, Vacunación

---

### Test 4: Usuario Enfermería (Enf. Rodríguez)

1. Login con `enf.rodriguez` / `Enferm2025!` / `taxco`
2. Verificar que el AppBar muestra:
   - "Enfermería - Taxco"
   - "Enf. Ana Rodríguez Santos"
3. Verificar que el dashboard muestra **1 opción**:
   - ✅ Vacunación
4. **NO debe mostrar**: Crear Carnet, Administrar Expedientes, Promoción de Salud
5. Acceder a Vacunación (debe funcionar)

---

### Test 5: Usuario Recepción (Recep. Sánchez)

1. Login con `recep.sanchez` / `Recep2025!` / `iguala`
2. Verificar que el AppBar muestra:
   - "Recepción - Iguala"
   - "Recep. Laura Sánchez Flores"
3. Verificar que el dashboard muestra:
   - ⚠️ **Panel naranja con mensaje "Sin Permisos Asignados"**
   - Texto: "Tu cuenta no tiene permisos para acceder a ninguna funcionalidad. Contacta al administrador del sistema."
4. **NO debe mostrar** ninguna de las 4 opciones

---

### Test 6: Usuario Solo Lectura (Observador)

1. Login con `observador` / `Lectura2025!` / `zihuatanejo`
2. Verificar que el AppBar muestra:
   - "Lectura - Zihuatanejo"
   - "Observador del Sistema"
3. Verificar que el dashboard muestra:
   - ⚠️ **Panel naranja con mensaje "Sin Permisos Asignados"**
4. **NO debe mostrar** ninguna de las 4 opciones

---

## 📊 Resumen de Permisos por Rol

| Rol | Crear Carnet | Expedientes | Promoción | Vacunación |
|-----|-------------|-------------|-----------|------------|
| **admin** | ✅ | ✅ | ✅ | ✅ |
| **medico** | ✅ | ✅ | ❌ | ✅ |
| **nutricion** | ❌ | ✅ | ❌ | ❌ |
| **psicologia** | ❌ | ✅ | ❌ | ❌ |
| **odontologia** | ❌ | ✅ | ❌ | ❌ |
| **enfermeria** | ❌ | ❌ | ❌ | ✅ |
| **recepcion** | ❌ | ❌ | ❌ | ❌ |
| **lectura** | ❌ | ❌ | ❌ | ❌ |

---

## 🎯 Checklist de Validación

### Creación de Usuarios
- [ ] Dr. García (médico) creado exitosamente
- [ ] Lic. Martínez (nutrición) creado exitosamente
- [ ] Psic. López (psicología) creado exitosamente
- [ ] Enf. Rodríguez (enfermería) creado exitosamente
- [ ] Recep. Sánchez (recepción) creado exitosamente
- [ ] Observador (lectura) creado exitosamente

### Pruebas de Login
- [ ] Dr. García puede iniciar sesión
- [ ] Lic. Martínez puede iniciar sesión
- [ ] Psic. López puede iniciar sesión
- [ ] Enf. Rodríguez puede iniciar sesión
- [ ] Recep. Sánchez puede iniciar sesión
- [ ] Observador puede iniciar sesión

### Pruebas de Permisos
- [ ] Médico ve 3 opciones correctas
- [ ] Nutrición ve solo Expedientes
- [ ] Psicología ve solo Expedientes
- [ ] Enfermería ve solo Vacunación
- [ ] Recepción ve mensaje "Sin Permisos"
- [ ] Lectura ve mensaje "Sin Permisos"

### Pruebas de Navegación
- [ ] Médico puede acceder a todas sus opciones
- [ ] Nutrición puede acceder a Expedientes
- [ ] Enfermería puede acceder a Vacunación
- [ ] Recepción y Lectura no pueden acceder a nada

---

## 🛠️ Instrucciones de Creación en Panel Admin

1. Accede a: https://fastapi-backend-o7ks.onrender.com/admin
2. Login con: `DireccionInnovaSalud` / `Admin2025`
3. En la pestaña "Usuarios", haz clic en "➕ Crear Usuario"
4. Rellena el formulario con los datos de cada usuario
5. Asegúrate de marcar "Activo" ✅
6. Haz clic en "Crear Usuario"
7. Verifica que aparezca en la lista de usuarios
8. Repite para los 6 usuarios

---

## ⚠️ Notas Importantes

- **Contraseñas seguras**: Todas las contraseñas tienen 8+ caracteres, mayúsculas, minúsculas y números
- **Validación backend**: El backend valida la complejidad de contraseñas
- **Campus diferentes**: Cada usuario está en un campus diferente para probar la distribución
- **Roles específicos**: Cada rol tiene un conjunto diferente de permisos
- **Sin permisos**: Los roles `recepcion` y `lectura` no tienen permisos de escritura, por lo que verán el mensaje de advertencia

---

## 🎉 Resultado Esperado Final

Después de crear todos los usuarios y probar:

1. ✅ **FASE 10 completada**: Sistema de restricciones funcionando
2. ✅ **Dashboard dinámico**: Muestra solo opciones permitidas
3. ✅ **Guards de navegación**: Bloquea accesos no autorizados
4. ✅ **Mensajes claros**: Usuarios sin permisos ven indicación clara
5. ✅ **Seguridad multicapa**: Permisos en backend + frontend

---

**Fecha**: 10 de Octubre de 2025  
**Versión**: FASE 10 - Restricciones por Rol  
**Estado**: ⏳ Pendiente de Testing
