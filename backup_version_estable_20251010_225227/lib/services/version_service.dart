import 'dart:convert';
import 'package:flutter/services.dart';

/// Modelo de datos para una entrada del changelog
class ChangelogEntry {
  final String version;
  final String date;
  final List<String> changes;

  ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
  });

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: json['version'] as String,
      date: json['date'] as String,
      changes: (json['changes'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }
}

/// Información de versión de la aplicación
class AppVersionInfo {
  final String version;
  final int buildNumber;
  final String releaseDate;
  final String channel;
  final String minimumVersion;
  final List<ChangelogEntry> changelog;

  AppVersionInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.channel,
    required this.minimumVersion,
    required this.changelog,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      releaseDate: json['releaseDate'] as String,
      channel: json['channel'] as String,
      minimumVersion: json['minimumVersion'] as String,
      changelog: (json['changelog'] as List<dynamic>)
          .map((e) => ChangelogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Obtiene el changelog de la versión actual
  ChangelogEntry? get currentChangelog {
    try {
      return changelog.firstWhere((entry) => entry.version == version);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un string formateado con versión y build
  String get fullVersion => '$version (Build $buildNumber)';
}

/// Servicio singleton para gestionar información de versión de la app
class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  AppVersionInfo? _versionInfo;
  bool _isLoaded = false;

  /// Obtiene la información de versión actual
  AppVersionInfo? get versionInfo => _versionInfo;

  /// Verifica si la información ya fue cargada
  bool get isLoaded => _isLoaded;

  /// Carga la información de versión desde el archivo assets/version.json
  Future<void> loadVersion() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/version.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _versionInfo = AppVersionInfo.fromJson(jsonData);
      _isLoaded = true;
      print('✅ Versión cargada: ${_versionInfo!.fullVersion}');
    } catch (e) {
      print('❌ Error cargando versión: $e');
      _isLoaded = false;
      _versionInfo = null;
    }
  }

  /// Recarga la información de versión (útil después de una actualización)
  Future<void> reloadVersion() async {
    _isLoaded = false;
    _versionInfo = null;
    await loadVersion();
  }

  /// Compara la versión actual con otra versión (formato semántico: X.Y.Z)
  /// Retorna:
  ///   > 0 si la versión actual es mayor
  ///   = 0 si son iguales
  ///   < 0 si la versión actual es menor
  int compareVersion(String otherVersion) {
    if (_versionInfo == null) return -1;

    final current = _versionInfo!.version.split('.').map(int.parse).toList();
    final other = otherVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final currentPart = i < current.length ? current[i] : 0;
      final otherPart = i < other.length ? other[i] : 0;
      
      if (currentPart != otherPart) {
        return currentPart.compareTo(otherPart);
      }
    }
    
    return 0;
  }

  /// Verifica si hay una actualización disponible
  /// (Será usado en FASE 4 cuando implementemos el auto-updater)
  bool isUpdateAvailable(String serverVersion) {
    return compareVersion(serverVersion) < 0;
  }

  /// Obtiene un resumen de la versión para mostrar en UI
  String getVersionSummary() {
    if (_versionInfo == null) return 'Versión no disponible';
    
    return '''
Versión: ${_versionInfo!.fullVersion}
Fecha: ${_versionInfo!.releaseDate}
Canal: ${_versionInfo!.channel}
''';
  }

  /// Obtiene el changelog formateado para mostrar en UI
  String getChangelogFormatted({int? maxVersions}) {
    if (_versionInfo == null) return 'Changelog no disponible';
    
    final entries = maxVersions != null
        ? _versionInfo!.changelog.take(maxVersions)
        : _versionInfo!.changelog;
    
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln('${entry.version} - ${entry.date}');
      for (final change in entry.changes) {
        buffer.writeln('  • $change');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}
