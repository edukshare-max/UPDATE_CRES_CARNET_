import 'package:flutter/material.dart';
import 'package:cres_carnets_ibmcloud/screens/form_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/nueva_nota_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/vaccination_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/promocion_salud_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/auth/login_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/about_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/database_cleaner_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/pending_sync_screen.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_theme.dart';
import 'package:cres_carnets_ibmcloud/ui/connection_indicator.dart';
import 'package:cres_carnets_ibmcloud/ui/mobile_adaptive.dart'; // Para detectar móvil
import 'package:cres_carnets_ibmcloud/data/db.dart' as DB;
import 'package:cres_carnets_ibmcloud/data/auth_service.dart';
import 'package:cres_carnets_ibmcloud/data/sync_service.dart';
import 'package:cres_carnets_ibmcloud/services/version_service.dart';
import 'package:cres_carnets_ibmcloud/services/update_manager.dart';

/// Dashboard principal después del login
/// Muestra las 4 opciones principales del sistema
class DashboardScreen extends StatefulWidget {
  final DB.AppDatabase db;
  const DashboardScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AuthUser? _currentUser;
  bool _loadingUser = true;
  
  // Permisos del usuario actual
  bool _canCreateCarnet = false;
  bool _canManageExpedientes = false;
  bool _canViewPromocion = false;
  bool _canViewVacunacion = false;

  // Manejador de actualizaciones
  UpdateManager? _updateManager;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPermissions();
    _initUpdateManager();
  }

  /// Inicializar el sistema de actualizaciones
  Future<void> _initUpdateManager() async {
    try {
      // Obtener versión del servicio singleton
      final versionService = VersionService();
      if (!versionService.isLoaded) {
        await versionService.loadVersion();
      }
      
      final versionInfo = versionService.versionInfo;
      if (versionInfo == null) {
        debugPrint('⚠️ No se pudo cargar información de versión');
        return;
      }

      _updateManager = UpdateManager(
        currentVersion: versionInfo.version,
        currentBuild: versionInfo.buildNumber,
      );
      
      // Verificar actualizaciones automáticamente después de cargar el dashboard
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _updateManager != null) {
          _updateManager!.checkForUpdatesAutomatic(context);
        }
      });
    } catch (e) {
      debugPrint('⚠️ Error al inicializar UpdateManager: $e');
    }
  }

  @override
  void dispose() {
    _updateManager?.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _loadingUser = false;
      });
    }
  }

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

  /// Obtener string de versión actual
  Future<String> _getVersionString() async {
    try {
      final versionService = VersionService();
      if (!versionService.isLoaded) {
        await versionService.loadVersion();
      }
      final info = versionService.versionInfo;
      if (info != null) {
        return '${info.version} (${info.buildNumber})';
      }
    } catch (e) {
      debugPrint('Error al obtener versión: $e');
    }
    return '2.4.33';
  }

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

  Future<void> _handleSyncPendingData() async {
    // Mostrar indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Sincronizando datos pendientes...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final syncService = SyncService(widget.db);
      final result = await syncService.syncAll();

      // Cerrar indicador de progreso
      if (mounted) Navigator.pop(context);

      // Mostrar resultado
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result.hasErrors ? Icons.warning : Icons.check_circle,
                  color: result.hasErrors ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text('Sincronización Completada'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.totalPending == 0)
                    const Text('✅ No había datos pendientes para sincronizar')
                  else ...[
                    Text('📊 Total items procesados: ${result.totalPending}'),
                    const SizedBox(height: 8),
                    Text('✅ Sincronizados: ${result.totalSynced}', 
                      style: const TextStyle(color: Colors.green)),
                    if (result.totalErrors > 0)
                      Text('❌ Con errores: ${result.totalErrors}', 
                        style: const TextStyle(color: Colors.red)),
                    const Divider(),
                    if (result.recordsSynced > 0 || result.recordsErrors > 0)
                      Text('Expedientes: ${result.recordsSynced}✓ ${result.recordsErrors}✗'),
                    if (result.notesSynced > 0 || result.notesErrors > 0)
                      Text('Notas: ${result.notesSynced}✓ ${result.notesErrors}✗'),
                    if (result.citasSynced > 0 || result.citasErrors > 0)
                      Text('Citas: ${result.citasSynced}✓ ${result.citasErrors}✗'),
                    if (result.vacunacionesSynced > 0 || result.vacunacionesErrors > 0)
                      Text('Vacunaciones: ${result.vacunacionesSynced}✓ ${result.vacunacionesErrors}✗'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de progreso
      if (mounted) Navigator.pop(context);

      // Mostrar error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Error al sincronizar datos:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: UAGroColors.rojoEscudo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen(db: widget.db)),
          (route) => false,
        );
      }
    }
  }

  /// Acciones compactas para móvil (solo iconos esenciales + menú)
  List<Widget> _buildMobileActions(BuildContext context) {
    return [
      const ConnectionBadge(),
      // Solo sync rápido y menú desplegable en móvil
      IconButton(
        icon: const Icon(Icons.sync),
        tooltip: 'Sincronizar',
        iconSize: 20, // Icono más pequeño
        onPressed: _handleSyncPendingData,
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'pending':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PendingSyncScreen(db: widget.db),
                ),
              );
              break;
            case 'clean':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DatabaseCleanerScreen(db: widget.db),
                ),
              );
              break;
            case 'update':
              if (_updateManager != null) {
                _updateManager!.checkForUpdatesManual(context);
              }
              break;
            case 'about':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutScreen(db: widget.db),
                ),
              );
              break;
            case 'logout':
              _handleLogout();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'pending',
            child: Row(
              children: [
                Icon(Icons.cloud_sync, size: 18),
                SizedBox(width: 8),
                Text('Datos pendientes', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'clean',
            child: Row(
              children: [
                Icon(Icons.cleaning_services, size: 18),
                SizedBox(width: 8),
                Text('Gestión datos', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'update',
            child: Row(
              children: [
                Icon(Icons.system_update, size: 18),
                SizedBox(width: 8),
                Text('Actualizaciones', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'about',
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text('Acerca de', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Cerrar sesión', style: TextStyle(fontSize: 13, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Acciones completas para desktop (todos los iconos visibles)
  List<Widget> _buildDesktopActions(BuildContext context) {
    return [
      const ConnectionBadge(),
      if (_currentUser != null)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: Text(
              _currentUser!.nombreCompleto,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.cloud_sync),
        tooltip: 'Ver y sincronizar datos pendientes',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PendingSyncScreen(db: widget.db),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.sync),
        tooltip: 'Sincronizar datos pendientes (rápido)',
        onPressed: _handleSyncPendingData,
      ),
      IconButton(
        icon: const Icon(Icons.cleaning_services),
        tooltip: 'Gestión de datos locales',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DatabaseCleanerScreen(db: widget.db),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.system_update),
        tooltip: 'Buscar actualizaciones',
        onPressed: () {
          if (_updateManager != null) {
            _updateManager!.checkForUpdatesManual(context);
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: 'Acerca de',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AboutScreen(db: widget.db),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Cerrar Sesión',
        onPressed: _handleLogout,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si es móvil para AppBar compacto
    final isMobile = MobileAdaptive.isMobilePlatform && MobileAdaptive.isPhone(context);
    
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: _loadingUser
            ? Text(isMobile ? 'CRES' : 'CRES Carnets - UAGro')
            : isMobile
                ? const Text('CRES') // Solo nombre corto en móvil
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CRES Carnets - UAGro',
                        style: TextStyle(fontSize: 16),
                      ),
                      if (_currentUser != null)
                        Text(
                          '${AuthService.formatRoleName(_currentUser!.rol)} - ${AuthService.formatCampusName(_currentUser!.campus)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                        ),
                    ],
                  ),
        backgroundColor: UAGroColors.azulMarino,
        elevation: 0,
        centerTitle: false,
        actions: isMobile
            ? _buildMobileActions(context) // Acciones compactas para móvil
            : _buildDesktopActions(context), // Todas las acciones para desktop
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              UAGroColors.azulMarino,
              UAGroColors.azulMarino.withValues(alpha: 0.8),
              UAGroColors.grisClaro,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Indicador de conexión
                  const ConnectionIndicator(),
                  
                  // Logo o título
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 60,
                          color: UAGroColors.azulMarino,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SASU',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: UAGroColors.azulMarino,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sistema de Atención en Salud Universitaria',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: UAGroColors.azulMarino,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CRES Llano Largo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Versión instalada
                        FutureBuilder<String>(
                          future: _getVersionString(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: UAGroColors.azulMarino.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'v${snapshot.data}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: UAGroColors.azulMarino,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Título de secciones
                  Text(
                    'Selecciona una opción',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Grid de opciones
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive: 2 columnas en pantallas grandes, 1 en pequeñas
                      final isWide = constraints.maxWidth > 600;
                      
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

                      // Opción 2: Administrar Expedientes (solo si puede crear notas)
                      if (_canManageExpedientes) {
                        visibleOptions.add(
                          _DashboardCard(
                            icon: Icons.folder_open,
                            title: 'Administrar Expedientes',
                            description: 'Gestión de notas y expedientes médicos',
                            color: UAGroColors.rojoEscudo,
                            onTap: () async {
                              if (await _checkPermission('notas:write', 'Administrar Expedientes')) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => NuevaNotaScreen(db: widget.db),
                                  ),
                                );
                              }
                            },
                            width: isWide ? 280 : constraints.maxWidth - 48,
                          ),
                        );
                      }

                      // Opción 3: Promoción de Salud
                      if (_canViewPromocion) {
                        visibleOptions.add(
                          _DashboardCard(
                            icon: Icons.campaign,
                            title: 'Promoción de Salud',
                            description: 'Crear y gestionar promociones de salud',
                            color: Colors.green[700]!,
                            onTap: () async {
                              if (await _checkPermission('promociones:read', 'Promoción de Salud')) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PromocionSaludScreen(db: widget.db),
                                  ),
                                );
                              }
                            },
                            width: isWide ? 280 : constraints.maxWidth - 48,
                          ),
                        );
                      }

                      // Opción 4: Vacunación (nueva)
                      if (_canViewVacunacion) {
                        visibleOptions.add(
                          _DashboardCard(
                            icon: Icons.vaccines,
                            title: 'Vacunación',
                            description: 'Campañas y registro de vacunación',
                            color: Colors.purple[700]!,
                            onTap: () async {
                              if (await _checkPermission('vacunacion:read', 'Vacunación')) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const VaccinationScreen(),
                                  ),
                                );
                              }
                            },
                            width: isWide ? 280 : constraints.maxWidth - 48,
                            badge: 'NUEVO',
                          ),
                        );
                      }
                      
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
                      
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: visibleOptions,
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  Text(
                    'Versión 1.0 - CRES UAGro 2025',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de tarjeta para cada opción del dashboard
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final double width;
  final String? badge;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    required this.width,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: color,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Título
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Descripción
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón/Indicador
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: color,
                    ),
                  ],
                ),

                // Badge (si existe)
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
