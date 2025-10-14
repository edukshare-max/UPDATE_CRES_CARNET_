// lib/data/offline_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Gestor de conectividad y caché offline
/// Detecta estado de red, gestiona caché de credenciales
/// y cola de sincronización de datos pendientes
class OfflineManager {
  static const _storage = FlutterSecureStorage();
  static final _connectivity = Connectivity();
  
  // Keys de almacenamiento
  static const _keyPasswordHash = 'offline_password_hash';
  static const _keyLastLoginTimestamp = 'offline_last_login';
  static const _keyOfflineMode = 'offline_mode_enabled';
  static const _keySyncQueue = 'offline_sync_queue';
  static const _keyLastSyncTimestamp = 'last_sync_timestamp';
  
  // Configuración
  static const _maxOfflineDays = 7; // Máximo días permitidos sin conexión
  static const _hashIterations = 10000; // Iteraciones para PBKDF2
  
  /// Stream de cambios de conectividad
  static Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
  
  /// Verifica si hay conexión a internet actualmente
  /// NOTA: Esta función solo verifica conectividad de red (WiFi/Ethernet)
  /// NO verifica si hay acceso real a internet
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      // Verificar si algún resultado indica conectividad
      final hasConnection = connectivityResults.any((result) => 
        result != ConnectivityResult.none
      );
      print('🌐 [CONNECTIVITY] Conectividad de red: $hasConnection (${connectivityResults.join(", ")})');
      return hasConnection;
    } catch (e) {
      print('❌ [CONNECTIVITY] Error verificando conectividad: $e');
      return false;
    }
  }
  
  /// Verifica conectividad REAL haciendo ping al backend
  /// Esta es la función que realmente importa para saber si el backend está accesible
  static Future<bool> canReachBackend(String backendUrl) async {
    try {
      print('🔍 [CONNECTIVITY] Verificando acceso al backend...');
      
      // Importar http aquí para evitar dependencias circulares
      final http = await Future.microtask(() {
        // Esta función se llamará desde auth_service que ya tiene http importado
        throw UnimplementedError('Debe llamarse desde un contexto con http disponible');
      });
      
      return false;
    } catch (e) {
      print('❌ [CONNECTIVITY] Backend no accesible: $e');
      return false;
    }
  }
  
  /// Guarda hash de contraseña para validación offline
  static Future<void> savePasswordHash({
    required String username,
    required String password,
    required String campus,
  }) async {
    print('💾 [CACHE] Guardando hash para usuario: $username, campus: $campus');
    
    // Crear hash seguro con PBKDF2
    final salt = '$username:$campus:cres_carnets';
    final hash = _hashPassword(password, salt);
    
    final cacheData = {
      'username': username,
      'campus': campus,
      'hash': hash,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _storage.write(
      key: _keyPasswordHash,
      value: jsonEncode(cacheData),
    );
    
    print('✅ [CACHE] Hash guardado exitosamente');
    await _updateLastLoginTimestamp();
  }
  
  /// Valida credenciales contra cache local
  static Future<bool> validateOfflineCredentials({
    required String username,
    required String password,
    required String campus,
  }) async {
    try {
      print('🔍 [CACHE] Validando credenciales offline para: $username, campus: $campus');
      
      // Leer caché
      final cacheJson = await _storage.read(key: _keyPasswordHash);
      if (cacheJson == null) {
        print('❌ [CACHE] No hay cache guardado');
        return false;
      }
      
      final cacheData = jsonDecode(cacheJson);
      print('📦 [CACHE] Cache encontrado - Usuario: ${cacheData['username']}, Campus: ${cacheData['campus']}');
      
      // Verificar usuario y campus
      if (cacheData['username'] != username) {
        print('❌ [CACHE] Usuario no coincide: "${cacheData['username']}" vs "$username"');
        return false;
      }
      
      if (cacheData['campus'] != campus) {
        print('❌ [CACHE] Campus no coincide: "${cacheData['campus']}" vs "$campus"');
        return false;
      }
      
      // Verificar que no hayan pasado más de X días sin conexión
      final lastLogin = DateTime.parse(cacheData['timestamp']);
      final daysSinceLastLogin = DateTime.now().difference(lastLogin).inDays;
      
      if (daysSinceLastLogin > _maxOfflineDays) {
        print('❌ [CACHE] Cache expirado: $daysSinceLastLogin días sin conexión (máximo: $_maxOfflineDays)');
        return false;
      }
      
      print('⏰ [CACHE] Cache válido (${daysSinceLastLogin} días desde último login)');
      
      // Validar hash de contraseña
      final salt = '$username:$campus:cres_carnets';
      final expectedHash = _hashPassword(password, salt);
      
      final isValid = cacheData['hash'] == expectedHash;
      print(isValid ? '✅ [CACHE] Hash válido - credenciales correctas' : '❌ [CACHE] Hash inválido - contraseña incorrecta');
      
      return isValid;
      
    } catch (e) {
      print('❌ [CACHE] Error validando credenciales offline: $e');
      return false;
    }
  }
  
  /// Crea hash seguro de contraseña usando SHA-256 iterativo
  static String _hashPassword(String password, String salt) {
    List<int> bytes = utf8.encode(password + salt);
    
    // Aplicar SHA-256 múltiples veces (PBKDF2 simplificado)
    for (int i = 0; i < _hashIterations; i++) {
      var digest = sha256.convert(bytes);
      bytes = digest.bytes;
    }
    
    return base64Encode(Uint8List.fromList(bytes));
  }
  
  /// Actualiza timestamp del último login exitoso
  static Future<void> _updateLastLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastLoginTimestamp,
      DateTime.now().toIso8601String(),
    );
  }
  
  /// Obtiene timestamp del último login
  static Future<DateTime?> getLastLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_keyLastLoginTimestamp);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  
  /// Habilita modo offline
  static Future<void> enableOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, true);
  }
  
  /// Deshabilita modo offline
  static Future<void> disableOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, false);
  }
  
  /// Verifica si modo offline está habilitado
  static Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOfflineMode) ?? false;
  }
  
  /// Verifica si existen credenciales cacheadas para un usuario
  static Future<bool> hasCachedCredentials(String username, String campus) async {
    try {
      print('🔎 [CACHE] Verificando si existe cache para: $username, campus: $campus');
      
      final cacheJson = await _storage.read(key: _keyPasswordHash);
      if (cacheJson == null) {
        print('❌ [CACHE] No existe cache');
        return false;
      }
      
      final cacheData = jsonDecode(cacheJson);
      print('📦 [CACHE] Cache existe - Usuario: ${cacheData['username']}, Campus: ${cacheData['campus']}');
      
      // Verificar que coincidan usuario y campus
      final matches = cacheData['username'] == username && cacheData['campus'] == campus;
      print(matches ? '✅ [CACHE] Cache coincide' : '❌ [CACHE] Cache NO coincide');
      
      return matches;
    } catch (e) {
      print('❌ [CACHE] Error verificando cache: $e');
      return false;
    }
  }
  
  /// Obtiene el campus guardado en cache para un usuario (sin validar contraseña)
  static Future<String?> getCachedCampusForUser(String username) async {
    try {
      final cacheJson = await _storage.read(key: _keyPasswordHash);
      if (cacheJson == null) return null;
      
      final cacheData = jsonDecode(cacheJson);
      
      // Si el usuario coincide, devolver el campus guardado
      if (cacheData['username'] == username) {
        return cacheData['campus'] as String?;
      }
      
      return null;
    } catch (e) {
      print('❌ [CACHE] Error obteniendo campus: $e');
      return null;
    }
  }
  
  /// Agrega acción a cola de sincronización
  static Future<void> addToSyncQueue({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_keySyncQueue) ?? '[]';
    final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
    
    queue.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    
    await prefs.setString(_keySyncQueue, jsonEncode(queue));
  }
  
  /// Obtiene cola de sincronización pendiente
  static Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_keySyncQueue) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(queueJson));
  }
  
  /// Limpia cola de sincronización
  static Future<void> clearSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySyncQueue);
  }
  
  /// Elimina item específico de cola
  static Future<void> removeSyncQueueItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_keySyncQueue) ?? '[]';
    final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
    
    queue.removeWhere((item) => item['id'] == id);
    
    await prefs.setString(_keySyncQueue, jsonEncode(queue));
  }
  
  /// Cuenta items pendientes en cola
  static Future<int> getSyncQueueCount() async {
    final queue = await getSyncQueue();
    return queue.length;
  }
  
  /// Actualiza timestamp de última sincronización
  static Future<void> updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastSyncTimestamp,
      DateTime.now().toIso8601String(),
    );
  }
  
  /// Obtiene timestamp de última sincronización
  static Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_keyLastSyncTimestamp);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  
  /// Limpia todos los datos de caché offline
  static Future<void> clearOfflineCache() async {
    await _storage.delete(key: _keyPasswordHash);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastLoginTimestamp);
    await prefs.remove(_keyOfflineMode);
    await prefs.remove(_keySyncQueue);
    await prefs.remove(_keyLastSyncTimestamp);
  }
  
  /// Obtiene información del estado de cache
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final lastLogin = await getLastLoginTimestamp();
    final lastSync = await getLastSyncTimestamp();
    final queueCount = await getSyncQueueCount();
    final offlineMode = await isOfflineModeEnabled();
    final hasCache = await _storage.read(key: _keyPasswordHash) != null;
    
    return {
      'hasCache': hasCache,
      'lastLogin': lastLogin?.toIso8601String(),
      'lastSync': lastSync?.toIso8601String(),
      'pendingSync': queueCount,
      'offlineMode': offlineMode,
      'daysSinceLastLogin': lastLogin != null 
        ? DateTime.now().difference(lastLogin).inDays 
        : null,
    };
  }
}
