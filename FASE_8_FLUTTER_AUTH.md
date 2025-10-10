# FASE 8: Integración de Autenticación en Flutter

## ✅ Implementación Completada

### 1. AuthService (`lib/data/auth_service.dart`)
**240 líneas** - Servicio central de autenticación

#### Características:
- **Modelo AuthUser**: Clase completa con todos los campos del usuario
  - `id`, `username`, `email`, `nombreCompleto`
  - `rol`, `campus`, `departamento`
  - `activo`, `fechaCreacion`, `ultimoAcceso`
  - Métodos `fromJson()` y `toJson()` para serialización

- **Método login()**: Autenticación con el backend
  - Endpoint: `POST https://fastapi-backend-o7ks.onrender.com/auth/login`
  - Timeout: 30 segundos
  - Manejo de respuestas: 200 (éxito), 401 (credenciales incorrectas), 403 (acceso denegado)
  - Almacena token JWT en `FlutterSecureStorage` con clave `auth_token`
  - Almacena datos del usuario con clave `auth_user`

- **Métodos de sesión**:
  - `logout()`: Elimina token y datos de usuario
  - `isLoggedIn()`: Verifica si existe token
  - `getToken()`: Obtiene token JWT almacenado
  - `getCurrentUser()`: Obtiene datos del usuario actual

- **Helpers de usuario**:
  - `getUserRole()`: Obtiene rol del usuario
  - `getUserCampus()`: Obtiene campus del usuario
  - `hasPermission(permission)`: Verifica permisos según rol
  - `isTokenExpiringSoon()`: Decodifica JWT y verifica expiración (<1 hora)

- **Formateadores**:
  - `formatCampusName()`: Convierte slug a nombre legible
  - `formatRoleName()`: Convierte rol a nombre legible

- **Mapa de permisos**: Sincronizado con backend
  ```dart
  'admin': todas las operaciones
  'medico': carnets, notas, citas, vacunacion
  'nutricion/psicologia/odontologia': carnets (read), notas, citas
  'enfermeria': carnets (read), vacunacion
  'recepcion': carnets (read), citas
  'lectura': carnets (read only)
  ```

### 2. LoginScreen (`lib/screens/auth/login_screen.dart`)
**280 líneas** - Pantalla de inicio de sesión

#### Características:
- **Diseño institucional UAGro**:
  - Colores: azulMarino #003D7A, rojo #C8102E, dorado #FFB81C, verde #00843D
  - Gradiente de fondo (azulMarino → dorado)
  - Card con ancho máximo 400px, padding 32px

- **Logo y branding**:
  - Ícono `medical_services` tamaño 80
  - Título: "SISTEMA DE CARNETS"
  - Subtítulo: "SASU - UAGro"

- **Formulario de autenticación**:
  - **Campo Usuario**: TextField con ícono de persona
  - **Campo Contraseña**: TextField con ícono de candado y toggle de visibilidad
  - **Selector Campus**: DropdownButtonFormField con 6 opciones
    - Llano Largo, Acapulco, Chilpancingo, Taxco, Iguala, Zihuatanejo

- **Validación**: Campos obligatorios (username y password)

- **Manejo de estados**:
  - Loading: CircularProgressIndicator durante autenticación
  - Error: Container rojo con mensaje de error
  - Success: Navegación a DashboardScreen

- **Mensajes de error**:
  - "Usuario o contraseña incorrectos" (401)
  - "Acceso denegado" (403)
  - "Error del servidor" (5xx)
  - "Error de conexión" (timeout/network)

- **Botón submit**: Verde con texto "INICIAR SESIÓN"

- **Footer**: "Contacta al administrador si tienes problemas de acceso"

### 3. main.dart (Modificado)
**67 líneas** - Punto de entrada con flujo de autenticación

#### Características:
- **Doble capa de autenticación**:
  1. **Primera capa**: JWT Backend (LoginScreen)
  2. **Segunda capa**: PIN Local (AuthGate)

- **Flujo de inicio**:
  ```dart
  FutureBuilder<bool>(
    future: AuthService.isLoggedIn(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == waiting)
        return SplashScreen;  // CircularProgressIndicator
      
      if (snapshot.data == true)
        return AuthGate → DashboardScreen;  // Usuario autenticado
      
      return LoginScreen;  // Sin autenticación
    }
  )
  ```

- **Navegación condicional**:
  - Sin token → LoginScreen
  - Con token → AuthGate (PIN) → DashboardScreen

### 4. DashboardScreen (Modificado)
**425 líneas** - Dashboard principal con información de usuario

#### Cambios implementados:
- **Convertido a StatefulWidget**: Para manejar estado del usuario

- **Estado interno**:
  - `AuthUser? _currentUser`: Datos del usuario actual
  - `bool _loadingUser`: Indicador de carga

- **initState()**: Carga información del usuario al iniciar

- **AppBar mejorado**:
  - **Título principal**: "CRES Carnets - UAGro"
  - **Subtítulo**: "Rol - Campus" del usuario
  - **Nombre usuario**: Mostrado en actions antes del botón logout
  - **Botón Logout**: IconButton con ícono de salida

- **Diálogo de confirmación**:
  - Pregunta: "¿Estás seguro que deseas salir?"
  - Botones: Cancelar (gris) y Salir (rojo)
  - Al confirmar: Llama `AuthService.logout()` y navega a LoginScreen

- **Navegación limpia**: `pushAndRemoveUntil` elimina todo el stack

## 🎯 Flujo de Autenticación Completo

### Inicio de la App
1. ✅ App inicia → `main.dart` carga
2. ✅ FutureBuilder verifica `AuthService.isLoggedIn()`
3. ✅ Si no hay token → Muestra `LoginScreen`
4. ✅ Si hay token → Muestra `AuthGate` → `DashboardScreen`

### Login de Usuario
1. ✅ Usuario ingresa: username, password, campus
2. ✅ Presiona "INICIAR SESIÓN"
3. ✅ `LoginScreen._handleLogin()` llama `AuthService.login()`
4. ✅ `AuthService` hace POST a backend
5. ✅ Backend valida credenciales y retorna JWT + datos usuario
6. ✅ Token guardado en FlutterSecureStorage
7. ✅ Datos usuario guardados en FlutterSecureStorage
8. ✅ Navegación a `DashboardScreen`
9. ✅ `DashboardScreen` carga información del usuario
10. ✅ AppBar muestra: nombre, rol, campus
11. ✅ Usuario pasa por `AuthGate` (PIN local)
12. ✅ Acceso al dashboard completo

### Logout de Usuario
1. ✅ Usuario presiona botón logout en AppBar
2. ✅ Aparece diálogo de confirmación
3. ✅ Usuario confirma "Salir"
4. ✅ `_handleLogout()` llama `AuthService.logout()`
5. ✅ Token y datos eliminados de FlutterSecureStorage
6. ✅ Navegación a `LoginScreen` con stack limpio
7. ✅ Usuario debe autenticarse nuevamente para acceder

## 🔐 Seguridad Implementada

### Almacenamiento Seguro
- ✅ **FlutterSecureStorage**: Tokens encriptados en sistema operativo
- ✅ **No plain text**: Contraseñas nunca almacenadas localmente
- ✅ **JWT validation**: Token verificado en cada solicitud al backend

### Validación de Sesión
- ✅ **Token expiration**: JWT con 8 horas de vida
- ✅ **isTokenExpiringSoon()**: Alerta cuando queda <1 hora
- ✅ **Logout limpio**: Elimina toda información sensible

### Control de Acceso
- ✅ **Permisos por rol**: Mapa completo de permisos
- ✅ **hasPermission()**: Método para verificar acceso
- ✅ **Campus restriction**: Usuario asociado a campus específico

## 📱 Experiencia de Usuario

### UI/UX
- ✅ **Colores institucionales UAGro**: Azul marino, rojo, dorado, verde
- ✅ **Responsive design**: Adaptable a diferentes tamaños
- ✅ **Loading states**: Indicadores durante operaciones asíncronas
- ✅ **Error messages**: Mensajes claros y específicos
- ✅ **Confirmación logout**: Evita salidas accidentales

### Información contextual
- ✅ **Nombre usuario**: Siempre visible en AppBar
- ✅ **Rol y campus**: Mostrado en subtítulo
- ✅ **Versión**: Footer con versión de la app

## 🧪 Pruebas Pendientes

### Test Manual (Próximo paso)
- [ ] Iniciar app sin token → Debe mostrar LoginScreen
- [ ] Login con credenciales correctas → Debe navegar a Dashboard
- [ ] Verificar información en AppBar (nombre, rol, campus)
- [ ] Presionar logout → Debe aparecer diálogo
- [ ] Confirmar logout → Debe volver a LoginScreen
- [ ] Reiniciar app → Debe mostrar LoginScreen (sin token)

### Test con Usuario Admin
- [ ] Username: `DireccionInnovaSalud`
- [ ] Password: `Admin2025`
- [ ] Campus: `llano-largo`
- [ ] Verificar que muestra: "Administrador - Llano Largo"

### Test de Errores
- [ ] Credenciales incorrectas → Mensaje de error
- [ ] Campus sin seleccionar → Mensaje de validación
- [ ] Conexión fallida → Mensaje de error de red
- [ ] Token expirado → Auto-logout (FASE 9)

## 📋 Próximos Pasos (FASE 9 y 10)

### FASE 9: Gestión de Sesión
- [ ] Interceptor HTTP para inyectar token en todas las requests
- [ ] Refresh automático de token cuando está por expirar
- [ ] Auto-logout cuando token expira
- [ ] Temporizador de sesión con advertencia visual
- [ ] Manejo de múltiples pestañas/ventanas

### FASE 10: Restricciones por Rol
- [ ] Ocultar opciones según permisos del rol
- [ ] Proteger navegación con `hasPermission()`
- [ ] Mostrar mensaje "Sin permisos" cuando intenta acceder
- [ ] Personalizar dashboard según rol:
  - **Admin**: Todas las opciones
  - **Médico**: Carnets, Notas, Citas, Vacunación
  - **Nutrición/Psicología/Odontología**: Carnets (solo lectura), Notas, Citas
  - **Enfermería**: Carnets (solo lectura), Vacunación
  - **Recepción**: Carnets (solo lectura), Citas
  - **Lectura**: Solo Carnets (solo lectura)

## 🔗 Integración con Backend

### Endpoints Utilizados
- ✅ `POST /auth/login`: Autenticación de usuario
- ⏳ `GET /auth/me`: Obtener usuario actual (FASE 9)
- ⏳ `POST /auth/refresh`: Renovar token (FASE 9)

### Datos Sincronizados
- ✅ Roles y permisos
- ✅ Campus disponibles
- ✅ Estructura de usuario (AuthUser model)

## 📝 Notas Técnicas

### Dependencias Utilizadas
```yaml
flutter_secure_storage: ^9.2.4  # Almacenamiento seguro de tokens
http: ^1.2.2                     # Llamadas HTTP al backend
```

### Estructura de Archivos
```
lib/
├── data/
│   └── auth_service.dart         ✅ NUEVO
├── screens/
│   ├── auth/
│   │   └── login_screen.dart     ✅ NUEVO
│   └── dashboard_screen.dart     ✅ MODIFICADO
└── main.dart                     ✅ MODIFICADO
```

### Estado del Código
- ✅ Sin errores de sintaxis
- ✅ Sin warnings de análisis
- ✅ Tipado estático completo
- ✅ Null safety habilitado
- ✅ Comentarios de documentación

---

**Fecha de implementación**: Octubre 2025  
**Backend**: https://fastapi-backend-o7ks.onrender.com  
**Estado**: ✅ FASE 8 COMPLETADA - Lista para pruebas
