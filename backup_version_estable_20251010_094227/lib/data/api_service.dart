import 'dart:convert';
import 'package:http/http.dart' as http;

/// URL del backend, configurable via environment o fallback
const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://fastapi-backend-o7ks.onrender.com');

class ApiService {
  // Consulta un expediente por ID (QR)
  static Future<Map<String, dynamic>?> getExpedienteById(String id) async {
    try {
      // DRY-RUN: Intento A → GET /carnet/{id}
      final urlA = Uri.parse('$baseUrl/carnet/$id');
      print('[DRY-RUN] Intento A: $urlA');
      final respA = await http.get(urlA);
      print('[DRY-RUN] Status A: ${respA.statusCode}');
      print('[DRY-RUN] Body A: ${respA.body}');
      
      if (respA.statusCode == 200) {
        final data = jsonDecode(respA.body);
        if (data != null && data is Map && data.isNotEmpty) {
          final normalized = _normalizeCarnetData(Map<String, dynamic>.from(data));
          print('[DRY-RUN] Llaves nivel 1: ${normalized.keys.toList()}');
          print('[DRY-RUN] ID encontrado: ${normalized['id']}');
          _logDataTypes(normalized);
          return normalized;
        }
      }
      
      // DRY-RUN: Intento B → GET /carnet/carnet:{id} (si id no empieza con carnet:)
      if (!id.startsWith('carnet:')) {
        final urlB = Uri.parse('$baseUrl/carnet/carnet:$id');
        print('[DRY-RUN] Intento B: $urlB');
        final respB = await http.get(urlB);
        print('[DRY-RUN] Status B: ${respB.statusCode}');
        print('[DRY-RUN] Body B: ${respB.body}');
        
        if (respB.statusCode == 200) {
          final data = jsonDecode(respB.body);
          if (data != null && data is Map && data.isNotEmpty) {
            final normalized = _normalizeCarnetData(Map<String, dynamic>.from(data));
            print('[DRY-RUN] Llaves nivel 1: ${normalized.keys.toList()}');
            print('[DRY-RUN] ID encontrado: ${normalized['id']}');
            _logDataTypes(normalized);
            return normalized;
          }
        }
      }
      
      print('[DRY-RUN] No se encontró carnet válido');
      return null;
    } catch (e) {
      print('Error en getExpedienteById: $e');
      return null;
    }
  }

  // Sube una nota para una matrícula
  static Future<bool> pushSingleNote({
    required String matricula,
    required String departamento,
    required String cuerpo,
    required String tratante,
    String? idOverride,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/notas');
      final payload = {
        'matricula': matricula,
        'departamento': departamento,
        'cuerpo': cuerpo,
        'tratante': tratante,
        if (idOverride != null) 'id': idOverride,
      };
      print('POST $url');
      print('Payload: $payload');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('Status: ${resp.statusCode}');
      print('Body: ${resp.body}');
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      print('Error en pushSingleNote: $e');
      return false;
    }
  }

  // Crea un carnet desde el formulario y lo guarda en la nube
  static Future<bool> pushSingleCarnet(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/carnet');
      print('=== SYNC CARNET DEBUG ===');
      print('POST $url');
      print('Payload: $data');
      print('Tiene ID: ${data.containsKey('id') ? data['id'] : 'NO'}');
      
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      print('Status: ${resp.statusCode}');
      print('Response Body: ${resp.body}');
      print('Response Headers: ${resp.headers}');
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final responseData = jsonDecode(resp.body);
          print('[CARNET] Guardado exitoso - Respuesta parseada: $responseData');
          if (responseData.containsKey('id')) {
            print('[CARNET] ID del carnet en respuesta: ${responseData['id']}');
          }
          return true;
        } catch (e) {
          print('[CARNET] Warning: respuesta no JSON pero status OK - Error: $e');
          return true; // Status 2xx = éxito aunque no sea JSON válido
        }
      } else {
        print('[CARNET] ERROR - Status code no exitoso: ${resp.statusCode}');
        print('[CARNET] ERROR - Body: ${resp.body}');
        return false;
      }
    } catch (e) {
      print('ERROR CRÍTICO en pushSingleCarnet: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

// Consulta un expediente por matrícula
static Future<Map<String, dynamic>?> getExpedienteByMatricula(String matricula) async {
  try {
    // DRY-RUN: Intento A → GET /carnet/{matricula}
    final urlA = Uri.parse('$baseUrl/carnet/$matricula');
    print('[DRY-RUN] Intento A (matrícula): $urlA');
    final respA = await http.get(urlA);
    print('[DRY-RUN] Status A: ${respA.statusCode}');
    print('[DRY-RUN] Body A: ${respA.body}');
    
    if (respA.statusCode == 200) {
      final data = jsonDecode(respA.body);
      if (data != null && data is Map && data.isNotEmpty) {
        final normalized = _normalizeCarnetData(Map<String, dynamic>.from(data));
        print('[DRY-RUN] Llaves nivel 1: ${normalized.keys.toList()}');
        print('[DRY-RUN] ID encontrado: ${normalized['id']}');
        _logDataTypes(normalized);
        return normalized;
      }
      // Si es una lista, filtrar carnets y tomar el más reciente
      if (data is List && data.isNotEmpty) {
        final carnets = data.where((item) => 
          item is Map && 
          item['id'] != null && 
          item['id'].toString().startsWith('carnet:') &&
          !item.containsKey('inicio') && // excluir citas
          !item.containsKey('fin')
        ).toList();
        
        if (carnets.isNotEmpty) {
          // Tomar el más reciente por _ts
          carnets.sort((a, b) {
            final tsA = a['_ts'] ?? 0;
            final tsB = b['_ts'] ?? 0;
            return tsB.compareTo(tsA);
          });
          final normalized = _normalizeCarnetData(Map<String, dynamic>.from(carnets.first));
          print('[DRY-RUN] Carnet filtrado - Llaves nivel 1: ${normalized.keys.toList()}');
          print('[DRY-RUN] ID encontrado: ${normalized['id']}');
          _logDataTypes(normalized);
          return normalized;
        }
      }
    }
    
    // DRY-RUN: Intento B → GET /carnet/carnet:{matricula} (si matricula no empieza con carnet:)
    if (!matricula.startsWith('carnet:')) {
      final urlB = Uri.parse('$baseUrl/carnet/carnet:$matricula');
      print('[DRY-RUN] Intento B (matrícula): $urlB');
      final respB = await http.get(urlB);
      print('[DRY-RUN] Status B: ${respB.statusCode}');
      print('[DRY-RUN] Body B: ${respB.body}');
      
      if (respB.statusCode == 200) {
        final data = jsonDecode(respB.body);
        if (data != null && data is Map && data.isNotEmpty) {
          final normalized = _normalizeCarnetData(Map<String, dynamic>.from(data));
          print('[DRY-RUN] Llaves nivel 1: ${normalized.keys.toList()}');
          print('[DRY-RUN] ID encontrado: ${normalized['id']}');
          _logDataTypes(normalized);
          return normalized;
        }
      }
    }
    
    print('[DRY-RUN] No se encontró carnet válido para matrícula');
    return null;
  } catch (e) {
    print('Error en getExpedienteByMatricula: $e');
    return null;
  }
}

// Consulta todas las notas para una matrícula
static Future<List<Map<String, dynamic>>> getNotasForMatricula(String matricula) async {
  try {
    final url = Uri.parse('$baseUrl/notas/$matricula');
    print('Consultando notas en: $url');
    final resp = await http.get(url);
    print('Status: ${resp.statusCode}');
    print('Body: ${resp.body}');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        print('Notas decodificadas: $data');
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('La respuesta de la API no es una lista');
      }
    } else {
      print('Error al consultar notas: Status ${resp.statusCode}');
    }
    return [];
  } catch (e) {
    print('Error en getNotasForMatricula: $e');
    return [];
  }
}

// Sube una cita para una matrícula
static Future<bool> pushSingleCita({
  required String matricula,
  required String inicio,
  required String fin,
  required String motivo,
  String? departamento,
  String? idOverride,
}) async {
  try {
    final url = Uri.parse('$baseUrl/citas');
    final payload = {
      'matricula': matricula,
      'inicio': inicio,
      'fin': fin,
      'motivo': motivo,
      if (departamento != null && departamento.isNotEmpty) 'departamento': departamento,
      if (idOverride != null) 'id': idOverride,
    };
    
    // DRY-RUN logs
    print('[DRY-RUN Flutter] API_BASE_URL: $baseUrl');
    print('[DRY-RUN Flutter] POST /citas, Headers: Content-Type: application/json');
    print('[DRY-RUN Flutter] Payload - matricula: ${payload['matricula']}, inicio: ${payload['inicio']}, fin: ${payload['fin']}, motivo: ${payload['motivo']}');
    print('[DRY-RUN Flutter] Payload keys: ${payload.keys.toList()} (no requiere id ni cita - backend genera automáticamente)');
    
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    
    print('[DRY-RUN Flutter] Status: ${resp.statusCode}');
    print('[DRY-RUN Flutter] Body keys: ${jsonDecode(resp.body).keys.toList()}');

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      try {
        final response = jsonDecode(resp.body);
        // Log new_cita_id si está presente
        final newId = response['id'] ?? response['data']?['id'];
        if (newId != null) {
          print('[DRY-RUN Flutter] new_cita_id=$newId');
        }
        // Convertir éxito basado en status 200/201 o presencia de id/_etag
        final hasId = response['id'] != null || response['data']?['id'] != null;
        final hasEtag = response['_etag'] != null || response['data']?['_etag'] != null;
        final success = response['status'] == 'created' || hasId || hasEtag;
        print('[DRY-RUN Flutter] Success conversion: $success (hasId: $hasId, hasEtag: $hasEtag)');
        return success;
      } catch (e) {
        // Si no es JSON válido pero status es 2xx, considerar éxito
        return true;
      }
    }
    return false;
  } catch (e) {
    print('Error en pushSingleCita: $e');
    return false;
  }
}

// Consulta todas las citas para una matrícula
static Future<List<Map<String, dynamic>>> getCitasForMatricula(String matricula) async {
  try {
    final url = Uri.parse('$baseUrl/citas/por-matricula/$matricula');
    print('[DRY-RUN Flutter] GET /citas/por-matricula/$matricula');
    final resp = await http.get(url);
    print('[DRY-RUN Flutter] Status: ${resp.statusCode}');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        print('[DRY-RUN Flutter] Cantidad de citas: ${data.length}');
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('La respuesta de la API no es una lista');
      }
    } else {
      print('Error al consultar citas: Status ${resp.statusCode}');
    }
    return [];
  } catch (e) {
    print('Error en getCitasForMatricula: $e');
    return [];
  }
}

// (Opcional) Consulta una cita específica por ID
static Future<Map<String, dynamic>?> getCitaById(String citaId) async {
  try {
    final url = Uri.parse('$baseUrl/citas/$citaId');
    print('[DRY-RUN Flutter] GET /citas/$citaId');
    final resp = await http.get(url);
    print('[DRY-RUN Flutter] Status: ${resp.statusCode}');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map) {
        print('[DRY-RUN Flutter] Cita encontrada: ${data['id']}');
        return Map<String, dynamic>.from(data);
      }
    } else if (resp.statusCode == 404) {
      print('[DRY-RUN Flutter] Cita no encontrada');
    }
    return null;
  } catch (e) {
    print('Error en getCitaById: $e');
    return null;
  }
}

  // Normaliza los datos del carnet con alias de claves y tipos mixtos
  static Map<String, dynamic> _normalizeCarnetData(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};
    
    // Copiar datos tal como vienen
    normalized.addAll(data);
    
    // Alias de claves (usar la primera disponible)
    normalized['nombreCompleto'] ??= data['nombre_completo'];
    normalized['tipoSangre'] ??= data['tipo_sangre'];
    normalized['enfermedadCronica'] ??= data['enfermedad_cronica'];
    normalized['numeroAfiliacion'] ??= data['numero_afiliacion'];
    normalized['usoSeguroUniversitario'] ??= data['uso_seguro_universitario'];
    normalized['emergenciaTelefono'] ??= data['emergencia_telefono'];
    
    // Normalizar edad: aceptar int/double/String → int?
    if (normalized['edad'] != null) {
      if (normalized['edad'] is String) {
        normalized['edad'] = int.tryParse(normalized['edad'].toString());
      } else if (normalized['edad'] is double) {
        normalized['edad'] = (normalized['edad'] as double).round();
      }
    }
    
    // Normalizar expedienteAdjuntos: String "[]" → List
    if (normalized['expedienteAdjuntos'] != null) {
      if (normalized['expedienteAdjuntos'] is String) {
        final str = normalized['expedienteAdjuntos'].toString().trim();
        if (str.isEmpty || str == '[]') {
          normalized['expedienteAdjuntos'] = <dynamic>[];
        } else {
          try {
            normalized['expedienteAdjuntos'] = jsonDecode(str);
          } catch (e) {
            normalized['expedienteAdjuntos'] = <dynamic>[];
          }
        }
      } else if (normalized['expedienteAdjuntos'] is! List) {
        normalized['expedienteAdjuntos'] = <dynamic>[];
      }
    }
    
    // Aceptar id con prefijo carnet: sin modificarlo
    // (ya está en los datos originales)
    
    return normalized;
  }
  
  // Log de tipos de datos para DRY-RUN
  static void _logDataTypes(Map<String, dynamic> data) {
    if (data['edad'] != null) {
      print('[DRY-RUN] Tipo edad: ${data['edad'].runtimeType} = ${data['edad']}');
    }
    if (data['expedienteAdjuntos'] != null) {
      print('[DRY-RUN] Tipo expedienteAdjuntos: ${data['expedienteAdjuntos'].runtimeType} = ${data['expedienteAdjuntos']}');
    }
  }

  // === MÉTODOS DE CITAS ===
  
  /// Crear una nueva cita
  /// POST $API/citas (Content-Type: application/json)
  /// No requiere id; el backend lo genera automáticamente
  /// Éxito por status 200/201 y/o presencia de id/_etag
  static Future<Map<String, dynamic>?> createCita(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/citas');
      print('[CITAS] POST $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      
      print('[CITAS] Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          // Verificar éxito por presencia de id/_etag o status created
          final hasId = data['id'] != null || data['data']?['id'] != null;
          final hasEtag = data['_etag'] != null || data['data']?['_etag'] != null;
          final isCreated = data['status'] == 'created';
          
          if (hasId || hasEtag || isCreated) {
            print('[CITAS] ✅ Cita creada exitosamente');
            return Map<String, dynamic>.from(data);
          }
        } catch (e) {
          print('[CITAS] ⚠️ Respuesta no JSON pero status OK');
          return {'status': 'created'}; // Status 2xx = éxito
        }
      } else {
        print('[CITAS] ❌ Error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('[CITAS] ❌ Error en createCita: $e');
      return null;
    }
  }

  /// Consultar citas por matrícula  
  /// GET $API/citas/por-matricula/$m
  static Future<List<Map<String, dynamic>>> getCitasByMatricula(String matricula) async {
    try {
      final url = Uri.parse('$baseUrl/citas/por-matricula/$matricula').toString();
      print('[CITAS_FETCH] GET $url');
      
      final response = await http.get(Uri.parse(url));
      print('[CITAS_FETCH] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> list = [];
        
        if (data is List) {
          // Respuesta directa como array
          list = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
        } else if (data is Map && data['data'] is List) {
          // Respuesta envuelta en { data: [...] }
          list = (data['data'] as List).map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        print('[CITAS_FETCH] m=$matricula len=${list.length}');
        return list;
      } else {
        print('[CITAS_FETCH][ERROR] status=${response.statusCode} url=$url');
        return [];
      }
    } catch (e) {
      print('[CITAS_FETCH][ERROR] Exception: $e');
      return [];
    }
  }

  // Métodos para promociones de salud
  static Future<Map<String, dynamic>?> createPromocionSalud(Map<String, dynamic> promocionData) async {
    try {
      final url = '$baseUrl/promociones-salud/';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(promocionData),
      );
      
      print('[PROMOCION_SALUD_CREATE] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        print('[PROMOCION_SALUD_CREATE][ERROR] status=${response.statusCode} body=${response.body}');
        return null;
      }
    } catch (e) {
      print('[PROMOCION_SALUD_CREATE][ERROR] Exception: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPromocionesSalud() async {
    try {
      final url = '$baseUrl/promociones-salud/';
      final response = await http.get(Uri.parse(url));
      
      print('[PROMOCIONES_SALUD_FETCH] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> list = [];
        
        if (data is List) {
          list = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        print('[PROMOCIONES_SALUD_FETCH] len=${list.length}');
        return list;
      } else {
        print('[PROMOCIONES_SALUD_FETCH][ERROR] status=${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[PROMOCIONES_SALUD_FETCH][ERROR] Exception: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> validateSupervisorKey(String key) async {
    try {
      final url = '$baseUrl/promociones-salud/validate-supervisor';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key}),
      );
      
      print('[SUPERVISOR_VALIDATE] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        print('[SUPERVISOR_VALIDATE][ERROR] status=${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[SUPERVISOR_VALIDATE][ERROR] Exception: $e');
      return null;
    }
  }
// CIERRA la clase
}