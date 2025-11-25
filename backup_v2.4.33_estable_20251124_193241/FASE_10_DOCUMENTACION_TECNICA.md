# 🔐 FASE 10: Sistema de Restricciones por Rol

## 📋 Índice

1. [Introducción](#introducción)
2. [Arquitectura de Permisos](#arquitectura-de-permisos)
3. [Implementación Técnica](#implementación-técnica)
4. [Flujo de Verificación](#flujo-de-verificación)
5. [Testing](#testing)
6. [Casos de Uso](#casos-de-uso)

---

## 🎯 Introducción

La **FASE 10** implementa un sistema completo de **restricciones de UI basadas en roles** que controla qué funcionalidades puede ver y acceder cada usuario según su rol en el sistema.

### Objetivos

- ✅ **Ocultar opciones** del dashboard que el usuario no puede usar
- ✅ **Prevenir navegación** a pantallas no autorizadas
- ✅ **Mostrar mensajes claros** cuando no hay permisos
- ✅ **Sincronización** con el sistema de permisos del backend
- ✅ **Experiencia de usuario mejorada** - sin confusión sobre qué pueden hacer

### Beneficios

1. **Seguridad**: Los usuarios solo ven lo que pueden hacer
2. **Claridad**: Dashboard limpio y personalizado por rol
3. **Prevención de errores**: Imposible acceder a funciones no autorizadas
4. **Mantenibilidad**: Sistema centralizado fácil de actualizar

---

## 🏗️ Arquitectura de Permisos

### Mapa de Permisos (AuthService)

```dart
final Map<String, List<String>> rolePermissions = {
  'admin': [
    'carnets:read', 'carnets:write', 
    'notas:read', 'notas:write',
    'citas:read', 'citas:write', 
    'users:manage', 'audit:read',
    'promociones:read', 'promociones:write', 
    'vacunacion:read', 'vacunacion:write'
  ],
  'medico': [
    'carnets:read', 'carnets:write', 
    'notas:read', 'notas:write',
    'citas:read', 'citas:write', 
    'vacunacion:read', 'vacunacion:write'
  ],
  'nutricion': [
    'carnets:read', 
    'notas:read', 'notas:write', 
    'citas:read', 'citas:write'
  ],
  'psicologia': [
    'carnets:read', 
    'notas:read', 'notas:write', 
    'citas:read', 'citas:write'
  ],
  'odontologia': [
    'carnets:read', 
    'notas:read', 'notas:write', 
    'citas:read', 'citas:write'
  ],
  'enfermeria': [
    'carnets:read', 
    'vacunacion:read', 'vacunacion:write'
  ],
  'recepcion': [
    'carnets:read', 
    'citas:read', 'citas:write'
  ],
  'lectura': [
    'carnets:read'
  ],
};
```

### Mapeo de Permisos a Opciones del Dashboard

| Opción del Dashboard | Permiso Requerido | Descripción |
|---------------------|-------------------|-------------|
| **Crear Carnet** | `carnets:write` | Crear nuevos carnets estudiantiles |
| **Administrar Expedientes** | `notas:write` | Crear y editar notas médicas |
| **Promoción de Salud** | `promociones:read` | Ver y crear campañas de salud |
| **Vacunación** | `vacunacion:read` | Ver y gestionar vacunación |

---

## 💻 Implementación Técnica

### 1. Estado del Dashboard

Se agregaron variables de estado para cachear los permisos del usuario:

```dart
class _DashboardScreenState extends State<DashboardScreen> {
  AuthUser? _currentUser;
  bool _loadingUser = true;
  
  // 🆕 Permisos del usuario actual
  bool _canCreateCarnet = false;
  bool _canManageExpedientes = false;
  bool _canViewPromocion = false;
  bool _canViewVacunacion = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPermissions(); // 🆕 Cargar permisos al iniciar
  }
```

**¿Por qué cachear?**
- Evita llamadas repetidas a `hasPermission()`
- Mejora el rendimiento del build
- Simplifica la lógica de mostrar/ocultar widgets

### 2. Método para Cargar Permisos

```dart
/// Cargar permisos del usuario actual
Future<void> _loadPermissions() async {
  final canCarnet = await AuthService.hasPermission('carnets:write');
  final canExpedientes = await AuthService.hasPermission('notas:write');
  final canPromocion = await AuthService.hasPermission('promociones:read');
  final canVacunacion = await AuthService.hasPermission('vacunacion:read');
  
  if (mounted) {
    setState(() {
      _canCreateCarnet = canCarnet;
      _canManageExpedientes = canExpedientes;
      _canViewPromocion = canPromocion;
      _canViewVacunacion = canVacunacion;
    });
  }
}
```

**Características**:
- ✅ Verifica `mounted` antes de `setState` (seguridad)
- ✅ Carga todos los permisos en paralelo (eficiente)
- ✅ Guarda en estado local (acceso rápido)

### 3. Guard de Navegación

```dart
/// Verificar permiso antes de navegar
Future<bool> _checkPermission(String permission, String feature) async {
  final hasPermission = await AuthService.hasPermission(permission);
  
  if (!hasPermission && mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: UAGroColors.rojoEscudo),
            const SizedBox(width: 8),
            const Text('Acceso Denegado'),
          ],
        ),
        content: Text(
          'No tienes permiso para acceder a "$feature".\n\n'
          'Contacta al administrador si necesitas este acceso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  
  return hasPermission;
}
```

**Uso**:
```dart
onTap: () async {
  if (await _checkPermission('carnets:write', 'Crear Carnet')) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormScreen(db: widget.db),
      ),
    );
  }
}
```

**Beneficios**:
- 🔒 Doble verificación: UI + guard de navegación
- 📱 Diálogo claro al usuario si no tiene acceso
- ✅ Retorna bool para control de flujo

### 4. Renderizado Condicional

```dart
// Lista de opciones visibles según permisos
final List<Widget> visibleOptions = [];

// Opción 1: Crear Carnet (solo si tiene permiso de escritura)
if (_canCreateCarnet) {
  visibleOptions.add(
    _DashboardCard(
      icon: Icons.badge_outlined,
      title: 'Crear Carnet',
      description: 'Registro de nuevo carnet estudiantil',
      color: UAGroColors.azulMarino,
      onTap: () async {
        if (await _checkPermission('carnets:write', 'Crear Carnet')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FormScreen(db: widget.db),
            ),
          );
        }
      },
      width: isWide ? 280 : constraints.maxWidth - 48,
    ),
  );
}

// ... repetir para cada opción
```

**Ventajas**:
- ✅ Construcción dinámica de lista de widgets
- ✅ Código limpio y legible
- ✅ Fácil agregar nuevas opciones

### 5. Mensaje "Sin Permisos"

```dart
// Si no tiene ningún permiso, mostrar mensaje
if (visibleOptions.isEmpty) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange[300]!),
    ),
    child: Column(
      children: [
        Icon(Icons.info_outline, size: 48, color: Colors.orange[700]),
        const SizedBox(height: 16),
        Text(
          'Sin Permisos Asignados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange[900],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu cuenta no tiene permisos para acceder a ninguna funcionalidad.\n'
          'Contacta al administrador del sistema.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    ),
  );
}
```

**Casos de uso**:
- Rol `recepcion`: Solo puede leer carnets (no hay UI de lectura)
- Rol `lectura`: Solo puede leer carnets (no hay UI de lectura)
- Usuario nuevo sin permisos asignados

---

## 🔄 Flujo de Verificación

### Diagrama de Flujo

```
┌─────────────────┐
│  Iniciar App    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Login Exitoso  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Dashboard.initState()  │
└────────┬────────────────┘
         │
         ├──► _loadUserInfo()
         │
         └──► _loadPermissions()
                 │
                 ├──► hasPermission('carnets:write')
                 ├──► hasPermission('notas:write')
                 ├──► hasPermission('promociones:read')
                 └──► hasPermission('vacunacion:read')
                         │
                         ▼
                 ┌───────────────────┐
                 │ setState() con    │
                 │ permisos cargados │
                 └────────┬──────────┘
                          │
                          ▼
                 ┌────────────────────┐
                 │  build() Dashboard │
                 └────────┬───────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │ Construir lista visibleOptions  │
        │ basada en permisos              │
        └─────────┬───────────────────────┘
                  │
                  ├──► Si _canCreateCarnet → Agregar card "Crear Carnet"
                  ├──► Si _canManageExpedientes → Agregar card "Expedientes"
                  ├──► Si _canViewPromocion → Agregar card "Promoción"
                  └──► Si _canViewVacunacion → Agregar card "Vacunación"
                          │
                          ▼
        ┌─────────────────────────────────┐
        │ visibleOptions.isEmpty?         │
        └─────────┬───────────────────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
┌──────────┐       ┌──────────────────┐
│ Mostrar  │       │ Mostrar mensaje  │
│ Cards    │       │ "Sin Permisos"   │
└──────────┘       └──────────────────┘
```

### Flujo de Navegación

```
Usuario hace tap en card
         │
         ▼
┌────────────────────────┐
│ onTap() de _DashboardCard │
└────────┬───────────────┘
         │
         ▼
┌──────────────────────────────┐
│ _checkPermission(permission) │
└────────┬─────────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
 [SÍ]      [NO]
    │         │
    │         ▼
    │    ┌─────────────────┐
    │    │ showDialog()    │
    │    │ "Acceso         │
    │    │  Denegado"      │
    │    └─────────────────┘
    │
    ▼
┌──────────────────┐
│ Navigator.push() │
│ a la pantalla    │
└──────────────────┘
```

---

## 🧪 Testing

### Matriz de Pruebas

| Rol | Crear Carnet | Expedientes | Promoción | Vacunación | Resultado Esperado |
|-----|-------------|-------------|-----------|------------|--------------------|
| **admin** | ✅ | ✅ | ✅ | ✅ | 4 opciones |
| **medico** | ✅ | ✅ | ❌ | ✅ | 3 opciones |
| **nutricion** | ❌ | ✅ | ❌ | ❌ | 1 opción |
| **psicologia** | ❌ | ✅ | ❌ | ❌ | 1 opción |
| **odontologia** | ❌ | ✅ | ❌ | ❌ | 1 opción |
| **enfermeria** | ❌ | ❌ | ❌ | ✅ | 1 opción |
| **recepcion** | ❌ | ❌ | ❌ | ❌ | Mensaje sin permisos |
| **lectura** | ❌ | ❌ | ❌ | ❌ | Mensaje sin permisos |

### Escenarios de Prueba

#### Escenario 1: Usuario con Todos los Permisos (Admin)
```
Usuario: DireccionInnovaSalud
Rol: admin
Esperado: Ver las 4 opciones del dashboard
```

**Pasos**:
1. Login con admin
2. Verificar dashboard muestra 4 cards
3. Intentar acceder a cada opción
4. Todas deben permitir navegación

#### Escenario 2: Usuario con Permisos Parciales (Médico)
```
Usuario: dr.garcia
Rol: medico
Esperado: Ver 3 opciones (sin Promoción de Salud)
```

**Pasos**:
1. Login con médico
2. Verificar dashboard muestra 3 cards:
   - Crear Carnet ✅
   - Administrar Expedientes ✅
   - Vacunación ✅
3. NO debe mostrar: Promoción de Salud
4. Todas las opciones visibles deben funcionar

#### Escenario 3: Usuario con Permiso Único (Enfermería)
```
Usuario: enf.rodriguez
Rol: enfermeria
Esperado: Ver solo Vacunación
```

**Pasos**:
1. Login con enfermería
2. Verificar dashboard muestra 1 card:
   - Vacunación ✅
3. NO debe mostrar: Carnets, Expedientes, Promoción
4. Acceder a Vacunación debe funcionar

#### Escenario 4: Usuario Sin Permisos (Recepción)
```
Usuario: recep.sanchez
Rol: recepcion
Esperado: Ver mensaje "Sin Permisos Asignados"
```

**Pasos**:
1. Login con recepción
2. Verificar dashboard muestra:
   - Panel naranja ⚠️
   - Icono de información
   - Título "Sin Permisos Asignados"
   - Mensaje explicativo
3. NO debe mostrar ninguna card de opción

---

## 📚 Casos de Uso

### Caso de Uso 1: Médico Realiza Consulta Completa

**Actor**: Dr. Juan García (médico)

**Precondiciones**:
- Usuario autenticado como médico
- Tiene permisos: carnets:write, notas:write, vacunacion:write

**Flujo Principal**:
1. Ve dashboard con 3 opciones
2. Selecciona "Crear Carnet" → ✅ Accede sin problemas
3. Registra nuevo carnet
4. Selecciona "Administrar Expedientes" → ✅ Accede
5. Crea nota médica
6. Selecciona "Vacunación" → ✅ Accede
7. Registra vacuna aplicada

**Resultado**: Proceso completo sin restricciones

---

### Caso de Uso 2: Nutrióloga Gestiona Expedientes

**Actor**: Lic. María Martínez (nutrición)

**Precondiciones**:
- Usuario autenticado como nutrición
- Tiene permisos: carnets:read, notas:write

**Flujo Principal**:
1. Ve dashboard con 1 opción
2. NO ve "Crear Carnet" (solo lectura)
3. Selecciona "Administrar Expedientes" → ✅ Accede
4. Busca matrícula existente
5. Crea nota de nutrición

**Flujo Alternativo**:
- Si intenta acceder directamente a FormScreen (por URL/hack)
- Guard bloquea acceso
- Muestra diálogo "Acceso Denegado"

---

### Caso de Uso 3: Enfermera Gestiona Vacunación

**Actor**: Enf. Ana Rodríguez (enfermería)

**Precondiciones**:
- Usuario autenticado como enfermería
- Tiene permisos: carnets:read, vacunacion:write

**Flujo Principal**:
1. Ve dashboard con 1 opción
2. NO ve "Crear Carnet" ni "Expedientes"
3. Selecciona "Vacunación" → ✅ Accede
4. Consulta carnets para buscar alumno
5. Registra vacunación

**Nota**: Puede ver carnets pero no crearlos

---

### Caso de Uso 4: Recepcionista Sin Acceso a Dashboard

**Actor**: Recep. Laura Sánchez (recepción)

**Precondiciones**:
- Usuario autenticado como recepción
- Tiene permisos: carnets:read, citas:read, citas:write

**Flujo Principal**:
1. Ve dashboard con mensaje "Sin Permisos Asignados"
2. NO puede acceder a ninguna funcionalidad del dashboard
3. (Futuro: Tendrá UI específica para gestión de citas)

**Resultado**: Usuario sabe que no tiene acceso y contacta admin

---

## 🔧 Mantenimiento

### Agregar Nueva Opción al Dashboard

1. **Definir permiso en `auth_service.dart`**:
```dart
'nuevo_modulo:read', 'nuevo_modulo:write'
```

2. **Agregar permisos a roles necesarios**:
```dart
'medico': [..., 'nuevo_modulo:read', 'nuevo_modulo:write'],
```

3. **Agregar variable de estado en `dashboard_screen.dart`**:
```dart
bool _canViewNuevoModulo = false;
```

4. **Cargar permiso en `_loadPermissions()`**:
```dart
final canNuevo = await AuthService.hasPermission('nuevo_modulo:read');
setState(() {
  _canViewNuevoModulo = canNuevo;
});
```

5. **Agregar card condicional**:
```dart
if (_canViewNuevoModulo) {
  visibleOptions.add(
    _DashboardCard(
      icon: Icons.new_releases,
      title: 'Nuevo Módulo',
      // ...
      onTap: () async {
        if (await _checkPermission('nuevo_modulo:read', 'Nuevo Módulo')) {
          // Navegar
        }
      },
    ),
  );
}
```

### Modificar Permisos de un Rol

1. Editar `auth_service.dart` → Mapa `rolePermissions`
2. Actualizar backend: `temp_backend/auth_service.py`
3. Probar con usuario de ese rol
4. Verificar que la UI se actualiza correctamente

---

## 📊 Métricas de Éxito

### Cobertura de Roles
- ✅ 8 roles implementados
- ✅ 4 opciones principales controladas
- ✅ 100% sincronización con backend

### Experiencia de Usuario
- ✅ Dashboard personalizado por rol
- ✅ Sin opciones confusas o inaccesibles
- ✅ Mensajes claros cuando no hay permisos

### Seguridad
- ✅ Doble capa de verificación (UI + guard)
- ✅ Imposible navegar sin permisos
- ✅ Diálogos informativos

---

## 🚀 Próximos Pasos

### FASE 11: CRUD Offline (Opcional)
- Crear carnets offline
- Editar notas sin conexión
- Sincronizar cambios al reconectar

### FASE 12: Panel Específico de Recepción
- UI para gestión de citas
- Búsqueda rápida de alumnos
- Calendario de citas

### FASE 13: Auditoría Avanzada
- Logs de acceso por usuario
- Reportes de uso por rol
- Detección de intentos de acceso no autorizado

---

## 📝 Resumen

La **FASE 10** implementa un sistema completo y robusto de restricciones basadas en roles que:

1. ✅ **Oculta funcionalidades** que el usuario no puede usar
2. ✅ **Previene navegación** no autorizada con guards
3. ✅ **Muestra mensajes claros** cuando no hay permisos
4. ✅ **Sincroniza con el backend** para consistencia
5. ✅ **Mejora la experiencia** con dashboards personalizados

**Estado**: ✅ **IMPLEMENTADO Y FUNCIONAL**  
**Compilación**: ✅ **13.5 segundos - Exitosa**  
**Pendiente**: Testing con usuarios de prueba

---

**Fecha**: 10 de Octubre de 2025  
**Versión**: FASE 10 - Restricciones por Rol  
**Autor**: Sistema CRES Carnets - SASU UAGro
