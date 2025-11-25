import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Script de diagnóstico para verificar el cache de credenciales
/// Ejecutar con: dart run tool/check_cache.dart

void main() async {
  const storage = FlutterSecureStorage();
  
  print('🔍 DIAGNÓSTICO DE CACHE OFFLINE\n');
  print('═══════════════════════════════════════\n');
  
  try {
    // Leer cache de contraseña
    final cacheJson = await storage.read(key: 'offline_password_hash');
    
    if (cacheJson == null) {
      print('❌ NO HAY CACHE GUARDADO');
      print('   El usuario debe iniciar sesión con internet primero.\n');
      return;
    }
    
    print('✅ CACHE ENCONTRADO\n');
    
    final cacheData = jsonDecode(cacheJson);
    
    print('📦 Datos del Cache:');
    print('   Usuario: ${cacheData['username']}');
    print('   Campus: ${cacheData['campus']}');
    print('   Timestamp: ${cacheData['timestamp']}');
    print('   Hash (primeros 20 caracteres): ${(cacheData['hash'] as String).substring(0, 20)}...\n');
    
    // Calcular días desde último login
    final timestamp = DateTime.parse(cacheData['timestamp']);
    final daysSince = DateTime.now().difference(timestamp).inDays;
    
    print('⏰ Tiempo desde último login: $daysSince días');
    
    if (daysSince > 7) {
      print('⚠️  ADVERTENCIA: Cache expirado (>7 días)\n');
    } else {
      print('✅ Cache válido (< 7 días)\n');
    }
    
    // Leer datos de usuario
    final userJson = await storage.read(key: 'auth_user');
    
    if (userJson == null) {
      print('⚠️  NO HAY DATOS DE USUARIO GUARDADOS');
      print('   Login offline fallará.\n');
      return;
    }
    
    print('✅ DATOS DE USUARIO ENCONTRADOS\n');
    
    final userData = jsonDecode(userJson);
    
    print('👤 Información del Usuario:');
    print('   Username: ${userData['username']}');
    print('   Nombre: ${userData['nombre_completo']}');
    print('   Email: ${userData['email']}');
    print('   Rol: ${userData['rol']}');
    print('   Campus: ${userData['campus']}');
    print('   Activo: ${userData['activo']}\n');
    
    // Verificar token
    final token = await storage.read(key: 'auth_token');
    
    if (token == null) {
      print('⚠️  NO HAY TOKEN GUARDADO\n');
    } else if (token.startsWith('offline_')) {
      print('🔓 Token offline detectado: $token\n');
    } else {
      print('🔑 Token online guardado (primeros 30 caracteres): ${token.substring(0, 30)}...\n');
    }
    
    // Verificar consistencia
    print('═══════════════════════════════════════');
    print('🔍 VERIFICACIÓN DE CONSISTENCIA:\n');
    
    bool consistent = true;
    
    if (cacheData['username'] != userData['username']) {
      print('❌ INCONSISTENCIA: Usuario en cache (${cacheData['username']}) ≠ usuario guardado (${userData['username']})');
      consistent = false;
    }
    
    if (cacheData['campus'] != userData['campus']) {
      print('⚠️  ADVERTENCIA: Campus en cache (${cacheData['campus']}) ≠ campus del usuario (${userData['campus']})');
      print('   Esto es NORMAL si el backend usa formato diferente.');
      print('   El fallback debería manejarlo.\n');
    }
    
    if (consistent && cacheData['campus'] == userData['campus']) {
      print('✅ Todos los datos son consistentes\n');
    }
    
    print('═══════════════════════════════════════');
    print('📋 RESUMEN:\n');
    
    print('Login offline DEBERÍA funcionar si:');
    print('  ✓ Hay cache guardado (${cacheJson != null ? "SÍ" : "NO"})');
    print('  ✓ Hay datos de usuario (${userJson != null ? "SÍ" : "NO"})');
    print('  ✓ Cache no expiró (${daysSince <= 7 ? "SÍ" : "NO"})');
    print('  ✓ Credenciales correctas (VERIFICAR AL INTENTAR LOGIN)\n');
    
    if (cacheJson != null && userJson != null && daysSince <= 7) {
      print('✅ TODO LISTO PARA LOGIN OFFLINE\n');
      print('Si aún no funciona, el problema puede ser:');
      print('  1. Contraseña incorrecta');
      print('  2. Campus no coincide (verificar en logs)');
      print('  3. Error en la detección de conectividad\n');
    } else {
      print('❌ FALTAN REQUISITOS PARA LOGIN OFFLINE\n');
    }
    
  } catch (e, stackTrace) {
    print('❌ ERROR AL LEER CACHE:');
    print('   $e\n');
    print('Stack trace:');
    print('$stackTrace\n');
  }
}
