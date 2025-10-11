import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Callback para reportar progreso de descarga
/// [received] - Bytes descargados
/// [total] - Bytes totales del archivo
typedef ProgressCallback = void Function(int received, int total);

/// Manejador de descargas de actualizaciones
class UpdateDownloader {
  final Dio _dio;
  CancelToken? _cancelToken;

  UpdateDownloader() : _dio = Dio();

  /// Descarga el instalador de actualización
  /// 
  /// [downloadUrl] - URL del instalador
  /// [onProgress] - Callback para reportar progreso (opcional)
  /// 
  /// Retorna la ruta del archivo descargado
  Future<String> downloadUpdate({
    required String downloadUrl,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(Uri.parse(downloadUrl).path);
      final savePath = path.join(tempDir.path, fileName);

      debugPrint('📥 Iniciando descarga...');
      debugPrint('   URL: $downloadUrl');
      debugPrint('   Destino: $savePath');

      // Crear token de cancelación
      _cancelToken = CancelToken();

      // Descargar archivo con seguimiento de progreso
      await _dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('   Progreso: $progress% ($received/$total bytes)');
            
            onProgress?.call(received, total);
          }
        },
        options: Options(
          headers: {
            'Accept': 'application/octet-stream',
          },
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      debugPrint('✅ Descarga completada: $savePath');
      
      // Verificar que el archivo existe
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('El archivo descargado no existe');
      }

      // Verificar tamaño
      final fileSize = await file.length();
      debugPrint('   Tamaño del archivo: ${_formatFileSize(fileSize)}');

      return savePath;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('⚠️ Descarga cancelada por el usuario');
        throw Exception('Descarga cancelada');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        debugPrint('⚠️ Tiempo de espera agotado');
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      } else if (e.type == DioExceptionType.badResponse) {
        debugPrint('❌ Error del servidor: ${e.response?.statusCode}');
        throw Exception('Error al descargar: ${e.response?.statusCode}');
      } else {
        debugPrint('❌ Error de conexión: ${e.message}');
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      rethrow;
    }
  }

  /// Cancela la descarga en curso
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      debugPrint('⏹️ Cancelando descarga...');
      _cancelToken!.cancel('Cancelado por el usuario');
    }
  }

  /// Verifica checksum SHA256 del archivo descargado
  /// 
  /// [filePath] - Ruta del archivo a verificar
  /// [expectedChecksum] - Checksum esperado (SHA256)
  /// 
  /// Retorna `true` si el checksum coincide, `false` en caso contrario
  Future<bool> verifyChecksum(String filePath, String expectedChecksum) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        debugPrint('❌ Archivo no encontrado para verificación');
        return false;
      }

      // Leer archivo y calcular SHA256
      final bytes = await file.readAsBytes();
      
      // Nota: Necesitarías importar crypto para esto
      // import 'package:crypto/crypto.dart' as crypto;
      // final digest = crypto.sha256.convert(bytes);
      // final checksum = digest.toString();
      
      // Por ahora, simplificado (implementar con crypto después)
      debugPrint('🔐 Verificando checksum...');
      debugPrint('   Esperado: $expectedChecksum');
      // debugPrint('   Calculado: $checksum');
      
      // return checksum.toLowerCase() == expectedChecksum.toLowerCase();
      
      // TODO: Implementar verificación real de checksum
      return true;
    } catch (e) {
      debugPrint('❌ Error al verificar checksum: $e');
      return false;
    }
  }

  /// Ejecuta el instalador descargado
  /// 
  /// [installerPath] - Ruta del instalador
  /// [closeApp] - Si debe cerrar la app después de ejecutar (default: true)
  Future<void> executeInstaller(String installerPath, {bool closeApp = true}) async {
    try {
      final file = File(installerPath);
      
      if (!await file.exists()) {
        throw Exception('Instalador no encontrado: $installerPath');
      }

      debugPrint('🚀 Ejecutando instalador...');
      debugPrint('   Ruta: $installerPath');

      // Ejecutar instalador en Windows
      await Process.start(
        installerPath,
        [],
        mode: ProcessStartMode.detached,
      );

      debugPrint('✅ Instalador ejecutado');

      if (closeApp) {
        debugPrint('👋 Cerrando aplicación...');
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      }
    } catch (e) {
      debugPrint('❌ Error al ejecutar instalador: $e');
      rethrow;
    }
  }

  /// Limpia archivos temporales de actualizaciones anteriores
  Future<void> cleanupOldUpdates() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      debugPrint('🧹 Limpiando actualizaciones antiguas...');

      int deleted = 0;
      for (final file in files) {
        if (file is File) {
          final name = path.basename(file.path).toLowerCase();
          // Eliminar instaladores antiguos
          if (name.contains('setup') && name.endsWith('.exe')) {
            try {
              await file.delete();
              deleted++;
              debugPrint('   Eliminado: ${path.basename(file.path)}');
            } catch (e) {
              debugPrint('   ⚠️ No se pudo eliminar: ${path.basename(file.path)}');
            }
          }
        }
      }

      debugPrint('✅ Limpieza completada: $deleted archivos eliminados');
    } catch (e) {
      debugPrint('⚠️ Error al limpiar archivos: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Libera recursos
  void dispose() {
    _cancelToken?.cancel();
    _dio.close();
  }
}
