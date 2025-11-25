import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_service.dart';
import 'update_downloader.dart';
import '../ui/update_dialog.dart';

/// Coordinador principal del sistema de actualizaciones
class UpdateManager {
  static const String _lastCheckKey = 'last_update_check';
  static const String _skippedVersionKey = 'skipped_version';
  static const Duration _checkInterval = Duration(hours: 24);

  final String currentVersion;
  final int currentBuild;
  final UpdateDownloader _downloader = UpdateDownloader();

  UpdateManager({
    required this.currentVersion,
    required this.currentBuild,
  });

  /// Verifica actualizaciones automáticamente
  /// 
  /// Se ejecuta al iniciar la app si:
  /// - Ha pasado más de 24 horas desde la última verificación
  /// - El usuario no omitió esta versión previamente
  /// 
  /// [context] - BuildContext para mostrar diálogos
  /// [force] - Forzar verificación ignorando intervalos (default: false)
  Future<void> checkForUpdatesAutomatic(
    BuildContext context, {
    bool force = false,
  }) async {
    try {
      // Verificar si debe hacer la comprobación
      if (!force && !await _shouldCheckNow()) {
        debugPrint('⏭️ Omitiendo verificación automática (muy reciente)');
        return;
      }

      debugPrint('🔍 Verificación automática de actualizaciones...');

      // Verificar conectividad del servicio
      final serviceOk = await UpdateService.checkServiceHealth();
      if (!serviceOk) {
        debugPrint('⚠️ Servicio de actualizaciones no disponible');
        return;
      }

      // Verificar si hay actualizaciones
      final response = await UpdateService.checkForUpdates(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );

      // Guardar timestamp de última verificación
      await _saveLastCheckTime();

      if (!response.updateAvailable || response.latestVersion == null) {
        debugPrint('✅ No hay actualizaciones disponibles');
        return;
      }

      final latestVersion = response.latestVersion!;

      // Verificar si el usuario omitió esta versión
      if (!latestVersion.isMandatory && await _isVersionSkipped(latestVersion.version)) {
        debugPrint('⏭️ Versión ${latestVersion.version} omitida por el usuario');
        return;
      }

      // Mostrar diálogo de actualización
      if (context.mounted) {
        await _showUpdateDialog(context, latestVersion);
      }
    } catch (e) {
      debugPrint('❌ Error en verificación automática: $e');
      // Fallar silenciosamente en verificaciones automáticas
    }
  }

  /// Verifica actualizaciones manualmente (desde botón en UI)
  /// 
  /// [context] - BuildContext para mostrar diálogos
  /// [showNoUpdateMessage] - Mostrar mensaje si no hay actualizaciones (default: true)
  Future<void> checkForUpdatesManual(
    BuildContext context, {
    bool showNoUpdateMessage = true,
  }) async {
    try {
      debugPrint('🔍 Verificación manual de actualizaciones...');

      // Mostrar indicador de carga
      if (context.mounted) {
        _showLoadingDialog(context);
      }

      // Verificar actualizaciones
      final response = await UpdateService.checkForUpdates(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!response.updateAvailable || response.latestVersion == null) {
        if (showNoUpdateMessage && context.mounted) {
          _showNoUpdateDialog(context);
        }
        return;
      }

      // Mostrar diálogo de actualización
      if (context.mounted) {
        await _showUpdateDialog(context, response.latestVersion!);
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('❌ Error en verificación manual: $e');

      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  /// Muestra el diálogo de actualización y maneja la respuesta
  Future<void> _showUpdateDialog(BuildContext context, VersionInfo versionInfo) async {
    final result = await UpdateDialog.show(
      context,
      versionInfo: versionInfo,
      currentVersion: currentVersion,
      onUpdate: () {
        // Iniciar descarga
        _startUpdate(context, versionInfo);
      },
      onLater: !versionInfo.isMandatory
          ? () {
              // Guardar versión omitida
              _skipVersion(versionInfo.version);
            }
          : null,
    );

    debugPrint('🎯 Usuario respondió al diálogo: $result');
  }

  /// Inicia el proceso de actualización
  Future<void> _startUpdate(BuildContext context, VersionInfo versionInfo) async {
    try {
      debugPrint('🚀 Iniciando proceso de actualización...');

      // Crear diálogo de progreso
      double currentProgress = 0.0;
      
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return DownloadProgressDialog(
                progress: currentProgress,
                status: currentProgress < 1.0
                    ? 'Descargando...'
                    : 'Preparando instalación...',
              );
            },
          ),
        );
      }

      // Descargar instalador
      final installerPath = await _downloader.downloadUpdate(
        downloadUrl: versionInfo.downloadUrl,
        onProgress: (received, total) {
          currentProgress = received / total;
          // Actualizar UI del diálogo
          if (context.mounted) {
            // Navigator.of(context).pop();
            // Mostrar diálogo actualizado
          }
        },
      );

      debugPrint('✅ Descarga completada: $installerPath');

      // Verificar checksum si está disponible
      if (versionInfo.checksum != null && versionInfo.checksum!.isNotEmpty) {
        debugPrint('🔐 Verificando integridad del archivo...');
        final isValid = await _downloader.verifyChecksum(
          installerPath,
          versionInfo.checksum!,
        );

        if (!isValid) {
          throw Exception('El archivo descargado está corrupto');
        }
      }

      // Cerrar diálogo de progreso
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar confirmación final
      if (context.mounted) {
        await _showInstallConfirmation(context, installerPath);
      }
    } catch (e) {
      debugPrint('❌ Error en actualización: $e');
      
      // Cerrar diálogo de progreso si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        _showErrorDialog(context, 'Error al descargar: $e');
      }
    }
  }

  /// Muestra confirmación final antes de instalar
  Future<void> _showInstallConfirmation(
    BuildContext context,
    String installerPath,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Descarga completada'),
          ],
        ),
        content: const Text(
          'El instalador se descargó correctamente.\n\n'
          'La aplicación se cerrará para iniciar la instalación.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Instalar ahora'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Ejecutar instalador y cerrar app
      await _downloader.executeInstaller(installerPath);
    }
  }

  /// Verifica si debe realizar la comprobación ahora
  Future<bool> _shouldCheckNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_lastCheckKey);

      if (lastCheckStr == null) {
        return true; // Primera vez
      }

      final lastCheck = DateTime.parse(lastCheckStr);
      final now = DateTime.now();
      final difference = now.difference(lastCheck);

      return difference >= _checkInterval;
    } catch (e) {
      return true; // Si hay error, mejor verificar
    }
  }

  /// Guarda el timestamp de la última verificación
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Error al guardar timestamp: $e');
    }
  }

  /// Marca una versión como omitida por el usuario
  Future<void> _skipVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_skippedVersionKey, version);
      debugPrint('⏭️ Versión $version marcada como omitida');
    } catch (e) {
      debugPrint('⚠️ Error al guardar versión omitida: $e');
    }
  }

  /// Verifica si una versión fue omitida
  Future<bool> _isVersionSkipped(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skippedVersion = prefs.getString(_skippedVersionKey);
      return skippedVersion == version;
    } catch (e) {
      return false;
    }
  }

  /// Muestra diálogo de carga
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verificando actualizaciones...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra diálogo cuando no hay actualizaciones
  void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Estás actualizado'),
          ],
        ),
        content: Text(
          'Ya tienes la última versión instalada.\n\n'
          'Versión actual: $currentVersion (Build $currentBuild)',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo de error
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Limpia recursos
  void dispose() {
    _downloader.dispose();
  }
}
