import 'package:flutter/material.dart';
import '../data/db.dart';
import 'package:intl/intl.dart';

/// Pantalla de limpieza y mantenimiento de base de datos local
class DatabaseCleanerScreen extends StatefulWidget {
  final AppDatabase db;
  
  const DatabaseCleanerScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<DatabaseCleanerScreen> createState() => _DatabaseCleanerScreenState();
}

class _DatabaseCleanerScreenState extends State<DatabaseCleanerScreen> {
  bool _isLoading = false;
  Map<String, int> _stats = {};
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  /// Helper: Contar notas pendientes de sincronización
  Future<int> _getPendingNotesCount() async {
    final pendientes = await widget.db.getPendingNotes();
    return pendientes.length;
  }
  
  /// Cargar estadísticas de la base de datos
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final db = widget.db;
      
      // Contar registros usando la API de Drift
      final expedientesCount = await db.select(db.healthRecords).get().then((list) => list.length);
      final notasCount = await db.select(db.notes).get().then((list) => list.length);
      final citasCount = await db.select(db.citas).get().then((list) => list.length);
      final vacunasCount = await db.select(db.vacunacionesPendientes).get().then((list) => list.length);
      
      // Contar pendientes de sync
      final notasPendientes = await db.getPendingNotes();
      final citasPendientes = await db.getPendingCitas();
      final vacunasPendientes = await db.getPendingVacunaciones();
      final expedientesPendientes = await db.getPendingRecords();
      
      final totalPendientes = notasPendientes.length + 
                             citasPendientes.length + 
                             vacunasPendientes.length + 
                             expedientesPendientes.length;
      
      setState(() {
        _stats = {
          'expedientes': expedientesCount,
          'notas': notasCount,
          'citas': citasCount,
          'vacunas': vacunasCount,
          'pendientes_sync': totalPendientes,
        };
      });
    } catch (e) {
      print('❌ Error cargando estadísticas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Limpiar notas antiguas (más de X días)
  Future<void> _cleanOldNotes(int days) async {
    // Verificar pendientes
    final pendientes = await _getPendingNotesCount();
    
    String mensaje = '¿Eliminar todas las notas con más de $days días?\n\n'
                     'Solo se eliminarán notas YA SINCRONIZADAS con el servidor.';
    
    if (pendientes > 0) {
      mensaje += '\n\n⚠️ ADVERTENCIA: Tienes $pendientes notas SIN SINCRONIZAR.\n'
                 'Estas NO se eliminarán. Usa el botón 🔄 del dashboard para sincronizarlas primero.';
    }
    
    final confirmado = await _showConfirmDialog(
      title: 'Eliminar Notas Antiguas',
      message: mensaje,
    );
    
    if (!confirmado) return;
    
    setState(() => _isLoading = true);
    
    try {
      final db = widget.db;
      final fechaLimite = DateTime.now().subtract(Duration(days: days));
      
      // Obtener todas las notas y filtrar en memoria
      final todasLasNotas = await db.select(db.notes).get();
      final notasAntiguas = todasLasNotas.where((nota) {
        if (nota.createdAt == null) return false;
        return nota.createdAt!.isBefore(fechaLimite) && nota.synced;
      }).toList();
      
      // Eliminarlas
      int deleted = 0;
      for (final nota in notasAntiguas) {
        await (db.delete(db.notes)..where((tbl) => tbl.id.equals(nota.id))).go();
        deleted++;
      }
      
      await _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eliminadas $deleted notas antiguas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error limpiando notas antiguas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Eliminar TODAS las notas sincronizadas
  Future<void> _clearAllSyncedNotes() async {
    // Contar sincronizadas y pendientes
    final todas = await widget.db.select(widget.db.notes).get();
    final sincronizadas = todas.where((n) => n.synced).length;
    final pendientes = todas.where((n) => !n.synced).length;
    
    String mensaje = 'Esto eliminará TODAS las notas que ya están sincronizadas con el servidor.\n\n'
                     '📊 Notas sincronizadas: $sincronizadas\n'
                     '⏳ Notas pendientes: $pendientes (SE MANTENDRÁN)\n\n';
    
    if (pendientes > 0) {
      mensaje += '⚠️ Si quieres eliminar TODAS las notas, primero sincroniza con el botón 🔄\n\n';
    }
    
    mensaje += '¿Estás seguro de eliminar las $sincronizadas notas sincronizadas?';
    
    final confirmado = await _showConfirmDialog(
      title: '⚠️ ELIMINAR NOTAS SINCRONIZADAS',
      message: mensaje,
      isDangerous: true,
    );
    
    if (!confirmado) return;
    
    setState(() => _isLoading = true);
    
    try {
      final db = widget.db;
      
      // Obtener notas sincronizadas
      final notasSincronizadas = await (db.select(db.notes)
        ..where((tbl) => tbl.synced.equals(true))
      ).get();
      
      // Eliminarlas
      int deleted = 0;
      for (final nota in notasSincronizadas) {
        await (db.delete(db.notes)..where((tbl) => tbl.id.equals(nota.id))).go();
        deleted++;
      }
      
      await _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eliminadas $deleted notas sincronizadas'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Error limpiando base de datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Mostrar diálogo de confirmación
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDangerous ? Icons.warning_amber : Icons.help_outline,
              color: isDangerous ? Colors.red : Colors.orange,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? Colors.red : Colors.blue,
            ),
            child: Text(isDangerous ? 'Eliminar' : 'Confirmar'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Limpieza de Datos Locales'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas
                  _buildStatsCard(),
                  SizedBox(height: 24),
                  
                  // Opciones de limpieza
                  Text(
                    'Opciones de Limpieza',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Limpiar notas antiguas
                  _buildCleanOption(
                    icon: Icons.calendar_today,
                    title: 'Eliminar Notas Antiguas',
                    subtitle: 'Eliminar notas sincronizadas con más de X días',
                    color: Colors.blue,
                    children: [
                      _buildCleanButton(
                        label: 'Más de 30 días',
                        onPressed: () => _cleanOldNotes(30),
                      ),
                      _buildCleanButton(
                        label: 'Más de 60 días',
                        onPressed: () => _cleanOldNotes(60),
                      ),
                      _buildCleanButton(
                        label: 'Más de 90 días',
                        onPressed: () => _cleanOldNotes(90),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Limpiar cola de sincronización
                  _buildCleanOption(
                    icon: Icons.sync,
                    title: 'Limpiar Cola de Sincronización',
                    subtitle: 'Eliminar registros ya sincronizados',
                    color: Colors.green,
                    onTap: () => _cleanOldNotes(90),
                  ),
                  SizedBox(height: 16),
                  
                  // Vaciar todo
                  _buildCleanOption(
                    icon: Icons.delete_sweep,
                    title: '⚠️ Vaciar Toda la Base de Datos',
                    subtitle: 'Eliminar TODOS los datos sincronizados (reversible)',
                    color: Colors.red,
                    onTap: _clearAllSyncedNotes,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Información importante
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            _buildStatRow('Expedientes', _stats['expedientes'] ?? 0),
            _buildStatRow('Notas', _stats['notas'] ?? 0),
            _buildStatRow('Vacunas', _stats['vacunas'] ?? 0),
            _buildStatRow('Pendientes de Sync', _stats['pendientes_sync'] ?? 0, isWarning: true),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, int value, {bool isWarning = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWarning && value > 0 ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCleanOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    List<Widget>? children,
  }) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: color, size: 32),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: onTap != null ? Icon(Icons.chevron_right) : null,
            onTap: onTap,
          ),
          if (children != null)
            Padding(
              padding: EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCleanButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Información Importante',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '• Solo se eliminan datos YA SINCRONIZADOS\n'
              '• Las notas sin sincronizar NO se tocan\n'
              '• Los datos se pueden recuperar del servidor\n'
              '• Conéctate a internet después de limpiar',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
