import 'package:flutter/material.dart';
import '../ui/uagro_theme.dart';
import '../ui/widgets/promocion_salud_section.dart';
import 'dashboard_screen.dart';

/// Pantalla independiente para gestión de Promoción de Salud
/// Separada del formulario de carnets para mayor claridad
class PromocionSaludScreen extends StatelessWidget {
  final dynamic db;
  const PromocionSaludScreen({Key? key, this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Promoción de Salud'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón de inicio sutil
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 22),
            tooltip: 'Ir al inicio',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => DashboardScreen(db: db)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[700]!,
              Colors.green[700]!.withValues(alpha: 0.8),
              UAGroColors.grisClaro,
            ],
            stops: const [0.0, 0.1, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado informativo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.campaign,
                              size: 32,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gestión de Promociones',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Envío de información de salud a estudiantes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      // Información adicional
                      _buildInfoItem(
                        Icons.person,
                        'Envío Individual',
                        'Promociones dirigidas a estudiantes específicos por matrícula',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        Icons.groups,
                        'Envío General',
                        'Promociones masivas que requieren autorización de supervisor',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        Icons.category,
                        'Categorías',
                        'Prevención, Promoción, Tratamiento, Psicología, Nutrición, y más',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Widget de Promoción de Salud (funcionalidad existente)
                const PromocionSaludSection(),

                const SizedBox(height: 24),

                // Notas al pie
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Notas Importantes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildNoteItem('• Los envíos a alumnos específicos no requieren autorización'),
                      _buildNoteItem('• Los envíos generales requieren clave de supervisor'),
                      _buildNoteItem('• Todos los envíos quedan registrados en el sistema'),
                      _buildNoteItem('• Asegúrese de verificar los links antes de enviar'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Center(
                  child: Text(
                    'SASU - Sistema de Atención en Salud Universitaria',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[900],
        ),
      ),
    );
  }
}
