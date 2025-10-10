import 'package:flutter/material.dart';
import 'package:cres_carnets_ibmcloud/screens/form_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/nueva_nota_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/vaccination_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/promocion_salud_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/auth/login_screen.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_theme.dart';
import 'package:cres_carnets_ibmcloud/ui/connection_indicator.dart';
import 'package:cres_carnets_ibmcloud/data/db.dart' as DB;
import 'package:cres_carnets_ibmcloud/data/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPermissions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: _loadingUser
            ? const Text('CRES Carnets - UAGro')
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
        actions: [
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
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
        ],
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
                                    builder: (_) => const PromocionSaludScreen(),
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
