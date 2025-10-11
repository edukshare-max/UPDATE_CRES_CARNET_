// lib/data/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'offline_manager.dart';

/// Modelo de datos del usuario autenticado
class AuthUser {
  final String id;
  final String username;
  final String email;
  final String nombreCompleto;
  final String rol;
  final String campus;
  final String departamento;
  final bool activo;
  final String? fechaCreacion;
  final String? ultimoAcceso;

  AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    required this.campus,
    required this.departamento,
    required this.activo,
    this.fechaCreacion,
    this.ultimoAcceso,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      rol: json['rol'] ?? '',
      campus: json['campus'] ?? '',
      departamento: json['departamento'] ?? '',
      activo: json['activo'] ?? true,
      fechaCreacion: json['fecha_creacion'],
      ultimoAcceso: json['ultimo_acceso'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nombre_completo': nombreCompleto,
      'rol': rol,
      'campus': campus,
      'departamento': departamento,
      'activo': activo,
      'fecha_creacion': fechaCreacion,
      'ultimo_acceso': ultimoAcceso,
    };
  }
}

/// Servicio de autenticación centralizado
class AuthService {
  static const String _baseUrl = 'https://fastapi-backend-o7ks.onrender.com';
  static const _storage = FlutterSecureStorage();
  
  // Keys para almacenamiento seguro
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Iniciar sesión con username, password y campus
  /// Modo híbrido: intenta online primero, fallback a offline si falla
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? campus,
  }) async {
    // PASO 1: Verificar conectividad
    final hasConnection = await OfflineManager.hasInternetConnection();
    
    if (hasConnection) {
      // MODO ONLINE: Intentar autenticación con backend
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            if (campus != null) 'campus': campus,
          }),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Tiempo de espera agotado'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Guardar token y datos de usuario
          await _storage.write(key: _tokenKey, value: data['access_token']);
          await _storage.write(key: _userKey, value: jsonEncode(data['user']));
          
          // IMPORTANTE: Guardar hash de contraseña para acceso offline futuro
          await OfflineManager.savePasswordHash(
            username: username,
            password: password,
            campus: campus ?? data['user']['campus'],
          );
          
          // Deshabilitar modo offline
          await OfflineManager.disableOfflineMode();
          
          // Intentar sincronizar datos pendientes
          await _syncPendingData();
          
          return {
            'success': true,
            'user': AuthUser.fromJson(data['user']),
            'token': data['access_token'],
            'mode': 'online',
          };
        } else if (response.statusCode == 401) {
          // Credenciales incorrectas - NO intentar offline
          return {
            'success': false,
            'error': 'Usuario o contraseña incorrectos',
          };
        } else if (response.statusCode == 403) {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['detail'] ?? 'Acceso denegado',
          };
        } else {
          // Error del servidor - intentar offline como fallback
          return await _tryOfflineLogin(username, password, campus);
        }
      } catch (e) {
        print('Error en login online: $e');
        // Error de conexión - intentar offline como fallback
        return await _tryOfflineLogin(username, password, campus);
      }
    } else {
      // MODO OFFLINE: Sin conexión detectada
      return await _tryOfflineLogin(username, password, campus);
    }
  }
  
  /// Intenta login offline validando contra cache local
  static Future<Map<String, dynamic>> _tryOfflineLogin(
    String username,
    String password,
    String? campus,
  ) async {
    print('Intentando login offline...');
    
    // Validar contra cache local
    final isValid = await OfflineManager.validateOfflineCredentials(
      username: username,
      password: password,
      campus: campus ?? 'llano-largo',
    );
    
    if (!isValid) {
      return {
        'success': false,
        'error': 'Sin conexión. No se puede validar usuario.\nConéctate a internet para iniciar sesión por primera vez.',
      };
    }
    
    // Login offline exitoso - cargar datos de usuario guardados
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) {
      return {
        'success': false,
        'error': 'Datos de usuario no disponibles offline',
      };
    }
    
    final userData = jsonDecode(userJson);
    
    // Generar token temporal offline (no válido para backend)
    final offlineToken = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: _tokenKey, value: offlineToken);
    
    // Habilitar modo offline
    await OfflineManager.enableOfflineMode();
    
    return {
      'success': true,
      'user': AuthUser.fromJson(userData),
      'token': offlineToken,
      'mode': 'offline',
      'warning': 'Modo sin conexión. Los datos se sincronizarán cuando tengas internet.',
    };
  }
  
  /// Sincroniza datos pendientes cuando hay conexión
  static Future<void> _syncPendingData() async {
    try {
      final queue = await OfflineManager.getSyncQueue();
      if (queue.isEmpty) return;
      
      print('Sincronizando ${queue.length} acciones pendientes...');
      
      for (final item in queue) {
        try {
          // Aquí iría la lógica de sincronización según el tipo de acción
          // Por ahora solo registramos en log
          await OfflineManager.addToSyncQueue(
            action: 'audit_log',
            data: {
              'action': item['action'],
              'synced_at': DateTime.now().toIso8601String(),
            },
          );
          
          // Remover item de la cola
          await OfflineManager.removeSyncQueueItem(item['id']);
        } catch (e) {
          print('Error sincronizando item ${item['id']}: $e');
        }
      }
      
      await OfflineManager.updateLastSyncTimestamp();
      print('Sincronización completada');
    } catch (e) {
      print('Error en sincronización: $e');
    }
  }

  /// Cerrar sesión (eliminar token y datos)
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Verificar si hay una sesión activa
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Obtener el token JWT actual
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Obtener el usuario actual
  static Future<AuthUser?> getCurrentUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    
    try {
      final userData = jsonDecode(userJson);
      return AuthUser.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  /// Obtener el rol del usuario actual
  static Future<String?> getUserRole() async {
    final user = await getCurrentUser();
    return user?.rol;
  }

  /// Obtener el campus del usuario actual
  static Future<String?> getUserCampus() async {
    final user = await getCurrentUser();
    return user?.campus;
  }

  /// Verificar si el usuario tiene un permiso específico
  static Future<bool> hasPermission(String permission) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    // Mapa de permisos por rol (sincronizado con backend)
    final Map<String, List<String>> rolePermissions = {
      'admin': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write', 
                'citas:read', 'citas:write', 'users:manage', 'audit:read',
                'promociones:read', 'promociones:write', 'vacunacion:read', 'vacunacion:write'],
      'medico': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write',
                 'citas:read', 'citas:write', 'vacunacion:read', 'vacunacion:write'],
      'nutricion': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write', 
                    'citas:read', 'citas:write', 'vacunacion:read', 'vacunacion:write'],
      'psicologia': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write', 
                     'citas:read', 'citas:write', 'vacunacion:read', 'vacunacion:write'],
      'odontologia': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write', 
                      'citas:read', 'citas:write', 'vacunacion:read', 'vacunacion:write'],
      'enfermeria': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write',
                     'citas:read', 'citas:write', 'vacunacion:read', 'vacunacion:write'],
      'recepcion': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write',
                    'citas:read', 'citas:write', 'vacunacion:read', 'vacunacion:write'],
      'servicios_estudiantiles': ['carnets:read', 'carnets:write', 'notas:read', 'notas:write',
                                  'citas:read', 'citas:write', 'promociones:read', 'promociones:write',
                                  'vacunacion:read', 'vacunacion:write'],
      'lectura': ['carnets:read'],
    };

    final userPermissions = rolePermissions[user.rol] ?? [];
    return userPermissions.contains(permission);
  }

  /// Verificar si el token está próximo a expirar (menos de 1 hora)
  static Future<bool> isTokenExpiringSoon() async {
    final token = await getToken();
    if (token == null) return true;

    try {
      // Decodificar el JWT para obtener el tiempo de expiración
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = jsonDecode(payload);
      
      if (payloadMap['exp'] != null) {
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(
          payloadMap['exp'] * 1000,
        );
        final now = DateTime.now();
        final difference = expirationDate.difference(now);
        
        // Retorna true si expira en menos de 1 hora
        return difference.inHours < 1;
      }
    } catch (e) {
      // Si hay error al decodificar, asumir que está expirado
      return true;
    }
    
    return false;
  }

  /// Obtener el nombre formateado del campus (88 instituciones UAGro)
  static String formatCampusName(String campus) {
    final Map<String, String> campusNames = {
      // CRES - Centros Regionales de Educación Superior (6)
      'cres-cruz-grande': 'CRES Cruz Grande',
      'cres-zumpango': 'CRES Zumpango del Río',
      'cres-taxco-viejo': 'CRES Taxco el Viejo',
      'cres-huamuxtitlan': 'CRES Huamuxtitlán',
      'cres-llano-largo': 'CRES Llano Largo',
      'cres-tecpan': 'CRES Tecpan de Galeana',
      
      // Clínicas Universitarias (4)
      'clinica-chilpancingo': 'Clínica Universitaria Chilpancingo',
      'clinica-acapulco': 'Clínica Universitaria Acapulco',
      'clinica-iguala': 'Clínica Universitaria Iguala',
      'clinica-ometepec': 'Clínica Universitaria Ometepec',
      
      // Facultades (20)
      'fac-gobierno': 'Facultad de Ciencias Políticas y Gobierno',
      'fac-arquitectura': 'Facultad de Arquitectura y Urbanismo',
      'fac-quimico': 'Facultad de Ciencias Químico Biológicas',
      'fac-comunicacion': 'Facultad de Ciencias de la Comunicación',
      'fac-derecho-chil': 'Facultad de Derecho (Chilpancingo)',
      'fac-filosofia': 'Facultad de Filosofía y Letras',
      'fac-ingenieria': 'Facultad de Ingeniería',
      'fac-matematicas-centro': 'Facultad de Matemáticas (Centro)',
      'fac-contaduria': 'Facultad de Contaduría y Administración',
      'fac-derecho-aca': 'Facultad de Derecho (Acapulco)',
      'fac-ecologia': 'Facultad de Ecología Marina',
      'fac-economia': 'Facultad de Economía',
      'fac-enfermeria2': 'Facultad de Enfermería 2',
      'fac-matematicas-sur': 'Facultad de Matemáticas (Sur)',
      'fac-lenguas': 'Facultad de Lenguas Extranjeras',
      'fac-medicina': 'Facultad de Medicina',
      'fac-odontologia': 'Facultad de Odontología',
      'fac-turismo': 'Facultad de Turismo',
      'fac-agropecuarias': 'Facultad de Ciencias Agropecuarias',
      'fac-matematicas-norte': 'Facultad de Matemáticas (Norte)',
      
      // Preparatorias (50)
      'prep-1': 'Preparatoria 1',
      'prep-2': 'Preparatoria 2',
      'prep-3': 'Preparatoria 3',
      'prep-4': 'Preparatoria 4',
      'prep-5': 'Preparatoria 5',
      'prep-6': 'Preparatoria 6',
      'prep-7': 'Preparatoria 7',
      'prep-8': 'Preparatoria 8',
      'prep-9': 'Preparatoria 9',
      'prep-10': 'Preparatoria 10',
      'prep-11': 'Preparatoria 11',
      'prep-12': 'Preparatoria 12',
      'prep-13': 'Preparatoria 13',
      'prep-14': 'Preparatoria 14',
      'prep-15': 'Preparatoria 15',
      'prep-16': 'Preparatoria 16',
      'prep-17': 'Preparatoria 17',
      'prep-18': 'Preparatoria 18',
      'prep-19': 'Preparatoria 19',
      'prep-20': 'Preparatoria 20',
      'prep-21': 'Preparatoria 21',
      'prep-22': 'Preparatoria 22',
      'prep-23': 'Preparatoria 23',
      'prep-24': 'Preparatoria 24',
      'prep-25': 'Preparatoria 25',
      'prep-26': 'Preparatoria 26',
      'prep-27': 'Preparatoria 27',
      'prep-28': 'Preparatoria 28',
      'prep-29': 'Preparatoria 29',
      'prep-30': 'Preparatoria 30',
      'prep-31': 'Preparatoria 31',
      'prep-32': 'Preparatoria 32',
      'prep-33': 'Preparatoria 33',
      'prep-34': 'Preparatoria 34',
      'prep-35': 'Preparatoria 35',
      'prep-36': 'Preparatoria 36',
      'prep-37': 'Preparatoria 37',
      'prep-38': 'Preparatoria 38',
      'prep-39': 'Preparatoria 39',
      'prep-40': 'Preparatoria 40',
      'prep-41': 'Preparatoria 41',
      'prep-42': 'Preparatoria 42',
      'prep-43': 'Preparatoria 43',
      'prep-44': 'Preparatoria 44',
      'prep-45': 'Preparatoria 45',
      'prep-46': 'Preparatoria 46',
      'prep-47': 'Preparatoria 47',
      'prep-48': 'Preparatoria 48',
      'prep-49': 'Preparatoria 49',
      'prep-50': 'Preparatoria 50',
      
      // Rectoría y Coordinaciones Regionales (8)
      'rectoria': 'Rectoría',
      'coord-sur': 'Coordinación Regional Sur',
      'coord-centro': 'Coordinación Regional Centro',
      'coord-norte': 'Coordinación Regional Norte',
      'coord-costa-chica': 'Coordinación Regional Costa Chica',
      'coord-costa-grande': 'Coordinación Regional Costa Grande',
      'coord-montana': 'Coordinación Regional Montaña',
      'coord-tierra-caliente': 'Coordinación Regional Tierra Caliente',
      
      // Retrocompatibilidad con valores antiguos (por si acaso)
      'llano-largo': 'CRES Llano Largo',
      'acapulco': 'Acapulco',
      'chilpancingo': 'Chilpancingo',
      'taxco': 'Taxco',
      'iguala': 'Iguala',
      'zihuatanejo': 'Zihuatanejo',
    };
    return campusNames[campus] ?? campus;
  }

  /// Obtener el nombre formateado del rol
  static String formatRoleName(String rol) {
    final Map<String, String> rolNames = {
      'admin': 'Administrador',
      'medico': 'Médico',
      'nutricion': 'Nutrición',
      'psicologia': 'Psicología',
      'odontologia': 'Odontología',
      'enfermeria': 'Enfermería',
      'recepcion': 'Recepción',
      'servicios_estudiantiles': 'Servicios Estudiantiles',
      'lectura': 'Solo Lectura',
    };
    return rolNames[rol] ?? rol;
  }
  
  /// Verifica si está en modo offline
  static Future<bool> isOfflineMode() async {
    return await OfflineManager.isOfflineModeEnabled();
  }
  
  /// Obtiene información del estado de conexión y cache
  static Future<Map<String, dynamic>> getConnectionInfo() async {
    final hasInternet = await OfflineManager.hasInternetConnection();
    final isOffline = await OfflineManager.isOfflineModeEnabled();
    final cacheInfo = await OfflineManager.getCacheInfo();
    
    return {
      'hasInternet': hasInternet,
      'isOfflineMode': isOffline,
      'cacheInfo': cacheInfo,
    };
  }
  
  /// Forzar sincronización manual
  static Future<bool> forceSyncNow() async {
    try {
      final hasConnection = await OfflineManager.hasInternetConnection();
      if (!hasConnection) {
        return false;
      }
      
      await _syncPendingData();
      return true;
    } catch (e) {
      print('Error en sincronización forzada: $e');
      return false;
    }
  }
}
