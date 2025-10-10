// lib/data/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de caché local para reducir llamadas al backend
/// y mejorar velocidad de búsquedas repetidas
class CacheService {
  static const String _carnetPrefix = 'cache_carnet_';
  static const String _notasPrefix = 'cache_notas_';
  static const String _citasPrefix = 'cache_citas_';
  static const Duration _cacheDuration = Duration(minutes: 15);

  /// Guarda un carnet en caché con timestamp
  static Future<void> saveCarnet(String matricula, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_carnetPrefix + matricula, jsonEncode(cacheData));
      print('✅ Carnet cacheado para $matricula');
    } catch (e) {
      print('⚠️ Error al guardar carnet en caché: $e');
    }
  }

  /// Obtiene un carnet del caché si existe y no ha expirado
  static Future<Map<String, dynamic>?> getCarnet(String matricula) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_carnetPrefix + matricula);
      if (cached == null) return null;

      final cacheData = jsonDecode(cached);
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Verificar si el caché expiró
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        print('⏰ Caché expirado para $matricula');
        await prefs.remove(_carnetPrefix + matricula);
        return null;
      }

      print('⚡ Carnet obtenido del caché para $matricula');
      return Map<String, dynamic>.from(cacheData['data']);
    } catch (e) {
      print('⚠️ Error al leer carnet del caché: $e');
      return null;
    }
  }

  /// Guarda notas en caché
  static Future<void> saveNotas(String matricula, List<Map<String, dynamic>> notas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': notas,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_notasPrefix + matricula, jsonEncode(cacheData));
      print('✅ Notas cacheadas para $matricula');
    } catch (e) {
      print('⚠️ Error al guardar notas en caché: $e');
    }
  }

  /// Obtiene notas del caché si existen y no han expirado
  static Future<List<Map<String, dynamic>>?> getNotas(String matricula) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_notasPrefix + matricula);
      if (cached == null) return null;

      final cacheData = jsonDecode(cached);
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        print('⏰ Caché de notas expirado para $matricula');
        await prefs.remove(_notasPrefix + matricula);
        return null;
      }

      print('⚡ Notas obtenidas del caché para $matricula');
      final data = cacheData['data'] as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('⚠️ Error al leer notas del caché: $e');
      return null;
    }
  }

  /// Guarda citas en caché
  static Future<void> saveCitas(String matricula, List<Map<String, dynamic>> citas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': citas,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_citasPrefix + matricula, jsonEncode(cacheData));
      print('✅ Citas cacheadas para $matricula');
    } catch (e) {
      print('⚠️ Error al guardar citas en caché: $e');
    }
  }

  /// Obtiene citas del caché si existen y no han expirado
  static Future<List<Map<String, dynamic>>?> getCitas(String matricula) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_citasPrefix + matricula);
      if (cached == null) return null;

      final cacheData = jsonDecode(cached);
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        print('⏰ Caché de citas expirado para $matricula');
        await prefs.remove(_citasPrefix + matricula);
        return null;
      }

      print('⚡ Citas obtenidas del caché para $matricula');
      final data = cacheData['data'] as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('⚠️ Error al leer citas del caché: $e');
      return null;
    }
  }

  /// Invalida el caché de una matrícula específica
  static Future<void> invalidateCarnet(String matricula) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_carnetPrefix + matricula);
      await prefs.remove(_notasPrefix + matricula);
      await prefs.remove(_citasPrefix + matricula);
      print('🗑️ Caché invalidado para $matricula');
    } catch (e) {
      print('⚠️ Error al invalidar caché: $e');
    }
  }

  /// Limpia todo el caché (útil para logout o reseteo)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_carnetPrefix) || 
            key.startsWith(_notasPrefix) || 
            key.startsWith(_citasPrefix)) {
          await prefs.remove(key);
        }
      }
      print('🗑️ Todo el caché limpiado');
    } catch (e) {
      print('⚠️ Error al limpiar caché: $e');
    }
  }
}
