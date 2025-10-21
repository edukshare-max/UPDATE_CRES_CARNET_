import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:drift/drift.dart' show Value, OrderingMode, OrderingTerm;
import 'cita_form_screen.dart';

import '../data/db.dart' as DB;
import '../data/api_service.dart';

import 'form_screen.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_widgets.dart' hide SectionCard;
import 'psychology/test_selection_screen.dart';
import 'odontology/odontogram_screen.dart';

// Imports para diseño institucional UAGro
import '../ui/brand.dart';
import '../ui/app_theme.dart';
import '../ui/uagro_theme.dart' as theme;
import '../ui/widgets/brand_sidebar.dart';
import '../ui/widgets/section_card.dart';

const String kSupervisorKey = 'UAGROcres2025';

class NuevaNotaScreen extends StatefulWidget {
  final DB.AppDatabase db;
  final String? matriculaInicial;
  const NuevaNotaScreen({super.key, required this.db, this.matriculaInicial});

  @override
  State<NuevaNotaScreen> createState() => _NuevaNotaScreenState();
}

class _NuevaNotaScreenState extends State<NuevaNotaScreen> with WidgetsBindingObserver {
  final _id = TextEditingController();
  final _mat = TextEditingController();
  final _depto = TextEditingController();
  final _tratante = TextEditingController();
  final _cuerpo = TextEditingController();
  final _diagnostico = TextEditingController();

  final _peso = TextEditingController();
  final _talla = TextEditingController();
  final _cintura = TextEditingController();
  final _cadera = TextEditingController();

  String? _tipoConsulta;
  final List<PlatformFile> _adjuntos = [];

  bool _cargando = false;
  String? _error;
  
  // Flag para detectar si volvemos del background
  bool _isInBackground = false;
  
  // Control de guardado para prevenir duplicados
  bool _guardandoNota = false;
  DateTime? _ultimoGuardado;

  bool _showAllCloud = false;
  bool _showAllLocal = false;
  static const int _limit = 5;

  Map<String, dynamic>? _expedienteCloud;
  List<Map<String, dynamic>> _notasCloud = const [];

  DB.HealthRecord? _expedienteLocal;
  List<DB.Note> _notasLocal = const [];

  bool _atencionIntegral = false;

  // Estado aislado para citas del cloud
  List<Map<String, dynamic>> _citasCloud = [];
  bool _cargandoCitas = false;
  String? _errorCitas;

  // Alias mínimo para compatibilidad con código legado
  // Prioriza expediente local sobre nube para consistencia con lógica existente
  DB.HealthRecord? get _carnetActual => _expedienteLocal;

  String? _deptChoice;
  final List<String> _deptOpciones = const [
    'Departamento psicopedagógico',
    'Consultorio médico',
    'Consultorio de Nutrición',
    'Consultorio de Odontología',
    'Atención estudiantil',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    
    // Registrar observer para detectar cambios de lifecycle
    WidgetsBinding.instance.addObserver(this);
    
    // 🔥 Wake up backend en background
    _wakeUpBackend();
    
    if (widget.matriculaInicial != null &&
        widget.matriculaInicial!.trim().isNotEmpty) {
      _mat.text = widget.matriculaInicial!.trim();
      _buscarNotasMatricula();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Detectar cuando la app vuelve al foreground
    if (state == AppLifecycleState.resumed && _isInBackground) {
      _isInBackground = false;
      // Refrescar si hay una matrícula cargada
      if (_mat.text.trim().isNotEmpty) {
        print('[REFRESH] 🔄 App volvió al foreground, refrescando notas...');
        _buscarNotasMatricula();
      }
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive) {
      _isInBackground = true;
    }
  }
  
  /// Despierta el backend en background para reducir cold start
  Future<void> _wakeUpBackend() async {
    try {
      await ApiService.wakeUpBackend();
    } catch (e) {
      print('⚠️ Error al despertar backend: $e');
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    // Remover observer antes de limpiar
    WidgetsBinding.instance.removeObserver(this);
    
    // Limpiar controladores
    _id.dispose();
    _mat.dispose();
    _depto.dispose();
    _tratante.dispose();
    _cuerpo.dispose();
    _diagnostico.dispose();
    _peso.dispose();
    _talla.dispose();
    _cintura.dispose();
    _cadera.dispose();
    
    super.dispose();
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  String _show(dynamic v) {
    if (v == null) return 'N/A';
    if (v is String && v.trim().isEmpty) return 'N/A';
    return '$v';
  }

  Widget _line(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label: ${_show(value)}'),
    );
  }

  // ================= BUSCAR CARNET Y NOTAS =================

  Future<void> _buscarCarnetId() async {
    final id = _id.text.trim();
    if (id.isEmpty) {
      setState(() {
        _expedienteCloud = null;
        _error = 'Escribe un ID (QR) para buscar el carnet.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final pac = await ApiService.getExpedienteById(id);
      if (!mounted) return;
      print('[DEBUG] Expediente recibido de la nube: $pac');
      print('[DEBUG] ID del expediente: ${pac?['id']}');
      setState(() {
        _expedienteCloud = pac;
      });

      final mFromCarnet = (pac?['matricula'] ?? '').toString().trim();
      if (_mat.text.trim().isEmpty && mFromCarnet.isNotEmpty) {
        _mat.text = mFromCarnet;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Nube (carnet): $e');
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _buscarNotasMatricula() async {
    final m = _mat.text.trim();
    if (m.isEmpty) {
      setState(() {
        _notasCloud = const [];
        _expedienteLocal = null;
        _notasLocal = const [];
        _atencionIntegral = false;
        _error = 'Escribe una matrícula para buscar notas.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> notasNube = const [];
      try {
        notasNube = await ApiService.getNotasForMatricula(m);
      } catch (e) {
        _error = (_error == null) ? 'Nube (notas): $e' : '${_error!}\nNube (notas): $e';
      }

      DB.HealthRecord? expLocal;
      List<DB.Note> notasLocal = const [];
      final qExp = widget.db.select(widget.db.healthRecords)
        ..where((t) => t.matricula.equals(m))
        ..orderBy([
          (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
        ])
        ..limit(1);
      final expList = await qExp.get();
      if (expList.isNotEmpty) expLocal = expList.first;

      final qNotas = widget.db.select(widget.db.notes)
        ..where((t) => t.matricula.equals(m))
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]);
      notasLocal = await qNotas.get();

      final servicios = <String>{};
      for (final n in notasNube) {
        final d = (n['departamento'] ?? '').toString().trim();
        if (d.isNotEmpty) servicios.add(d);
      }
      for (final n in notasLocal) {
        final d = n.departamento.trim();
        if (d.isNotEmpty) servicios.add(d);
      }
      final integral = servicios.length >= 2;

      if (!mounted) return;
      setState(() {
        _notasCloud = notasNube;
        _expedienteLocal = expLocal;
        _notasLocal = notasLocal;
        _atencionIntegral = integral;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ================== ADJUNTOS Y CAMPOS NUTRICIÓN ==================

  Future<void> _pickAdjuntos() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (res == null) return;
      setState(() {
        _adjuntos.addAll(res.files);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron seleccionar archivos: $e')),
      );
    }
  }

  Future<List<String>> _guardarAdjuntosLocal(String matricula) async {
    final List<String> rutas = [];
    if (_adjuntos.isEmpty) return rutas;

    try {
      final baseDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(baseDir.path, 'adjuntos', matricula));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      for (final f in _adjuntos) {
        try {
          if (f.path == null) continue;
          final safeName = f.name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
          final dstName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
          final dst = File(p.join(dir.path, dstName));
          await File(f.path!).copy(dst.path);
          rutas.add(dst.path);
        } catch (e) {
          print('No se pudo copiar adjunto ${f.name}: $e');
        }
      }
    } catch (e) {
      print('Error creando carpeta de adjuntos: $e');
      return [];
    }
    return rutas;
  }

  /// Obtener matrícula: primero del carnet, luego del input, si no hay ninguna retorna null
  String? _obtenerMatricula() {
    // Preferir carnet cargado
    if (_carnetActual != null) {
      return _carnetActual!.matricula;
    }
    // Si no hay carnet, usar texto del input
    final textoMatricula = _mat.text.trim();
    if (textoMatricula.isNotEmpty) {
      return textoMatricula;
    }
    return null;
  }

  /// Navegar a pantalla de agendar cita
  Future<void> _agendarCita() async {
    final matricula = _obtenerMatricula();
    if (matricula == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Busca un carnet primero para agendar una cita.')),
      );
      return;
    }

    // Navegar al formulario de citas
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CitaFormScreen(matricula: matricula, db: widget.db),
      ),
    );

    // Si se guardó una cita, mostrar confirmación
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita agendada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Obtener matrícula desde controlador o carnet cargado  
  String _currentMatricula() {
    // 1. Controlador del campo de matrícula de búsqueda/notas
    final matField = _mat.text.trim();
    if (matField.isNotEmpty) return matField;
    
    // 2. Matrícula del carnet cargado (local preferido)
    if (_carnetActual != null) {
      final carnetMat = _carnetActual!.matricula.trim();
      if (carnetMat.isNotEmpty) return carnetMat;
    }
    
    // 3. Matrícula del expediente cloud
    if (_expedienteCloud != null) {
      final cloudMat = (_expedienteCloud!['matricula'] ?? '').toString().trim();
      if (cloudMat.isNotEmpty) return cloudMat;
    }
    
    return '';
  }

  /// Mostrar citas del cloud para la matrícula actual
  Future<void> _mostrarCitas() async {
    final m = _currentMatricula();
    if (m.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa matrícula para buscar citas')),
      );
      return;
    }

    await _mostrarCitasImpl(m);
  }

  /// Implementación de mostrar citas con matrícula específica
  Future<void> _mostrarCitasImpl(String m) async {
    setState(() { 
      _cargandoCitas = true; 
      _errorCitas = null; 
    });
    
    try {
      final list = await ApiService.getCitasByMatricula(m);
      print('[CITAS_FETCH] m=$m len=${list.length}');
      
      setState(() {
        _citasCloud = list;
        _cargandoCitas = false;
      });
    } catch (e) {
      setState(() {
        _errorCitas = 'Error: $e';
        _cargandoCitas = false;
      });
    }
  }

  double? get _pesoVal {
    final v = double.tryParse(_peso.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _tallaVal {
    final v = double.tryParse(_talla.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _imcVal {
    final p = _pesoVal, t = _tallaVal;
    if (p == null || t == null || t == 0) return null;
    return p / (t * t);
  }

  double? get _cinturaVal {
    final v = double.tryParse(_cintura.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _caderaVal {
    final v = double.tryParse(_cadera.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _iccVal {
    final c = _cinturaVal, ca = _caderaVal;
    if (c == null || ca == null || ca == 0) return null;
    return c / ca;
  }

  // ================ GUARDAR NOTA (FASTAPI) ================

  Future<void> _guardarNota() async {
    // ========== PROTECCIÓN CONTRA GUARDADOS DUPLICADOS ==========
    // Prevenir múltiples clics mientras se está guardando
    if (_guardandoNota) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Ya se está guardando la nota, espera...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // Prevenir guardados muy seguidos (menos de 2 segundos)
    if (_ultimoGuardado != null) {
      final diferencia = DateTime.now().difference(_ultimoGuardado!);
      if (diferencia.inSeconds < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Espera un momento antes de guardar otra nota'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }
    }

    // ========== VALIDACIÓN DE CAMPOS OBLIGATORIOS ==========
    final m = _mat.text.trim();
    final dep = (_deptChoice == 'Otra' ? _depto.text.trim() : (_deptChoice ?? '')).trim();
    final t = _tratante.text.trim();
    final dx = _diagnostico.text.trim();
    final tc = _tipoConsulta?.trim() ?? '';
    final c = _cuerpo.text.trim();

    final missing = <String>[];
    if (m.isEmpty) missing.add('Matrícula');
    if (dep.isEmpty) missing.add('Departamento / área');
    if (t.isEmpty) missing.add('Tratante');
    final requiereDx = !(dep == 'Atención estudiantil' || _deptChoice == 'Otra');
    if (requiereDx && dx.isEmpty) missing.add('Diagnóstico');
    if (tc.isEmpty) missing.add('Consulta (Primera/Subsecuente)');
    if (c.isEmpty) missing.add('Cuerpo de la nota');

    if (missing.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Completa los campos obligatorios'),
          content: Text('Faltan: ${missing.join(', ')}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    // ========== INICIAR GUARDADO ==========
    setState(() => _guardandoNota = true);

    // Mostrar indicador de progreso inmediatamente
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('💾 Guardando nota...'),
            ],
          ),
          duration: Duration(seconds: 30), // Duración larga, se cerrará manualmente
        ),
      );
    }

    try {
      // ========== PASO 1: GUARDAR ADJUNTOS ==========
      final rutasAdj = await _guardarAdjuntosLocal(m);

      // ========== PASO 2: CONSTRUIR CUERPO DE LA NOTA ==========
      final buffer = StringBuffer();
      if (requiereDx) buffer.writeln('Diagnóstico: $dx');
      buffer.writeln('Consulta: $tc');

      if (dep == 'Consultorio de Nutrición') {
        final imcStr = _imcVal == null ? 'N/A' : _imcVal!.toStringAsFixed(2);
        final iccStr = _iccVal == null ? 'N/A' : _iccVal!.toStringAsFixed(2);
        buffer.writeln('NUTRICIÓN:');
        buffer.writeln('• Peso (kg): ${_peso.text.trim().isEmpty ? 'N/A' : _peso.text.trim()}');
        buffer.writeln('• Talla (m): ${_talla.text.trim().isEmpty ? 'N/A' : _talla.text.trim()}');
        buffer.writeln('• IMC: $imcStr');
        buffer.writeln('• Cintura (cm): ${_cintura.text.trim().isEmpty ? 'N/A' : _cintura.text.trim()}');
        buffer.writeln('• Cadera (cm): ${_cadera.text.trim().isEmpty ? 'N/A' : _cadera.text.trim()}');
        buffer.writeln('• Índice Cintura/Cadera: $iccStr');
      }

      buffer.writeln();
      buffer.writeln(c);

      if (rutasAdj.isNotEmpty) {
        buffer.writeln('\nAdjuntos:');
        for (final r in rutasAdj) {
          buffer.writeln('- $r');
        }
      }
      final cuerpoFinal = buffer.toString();

      // ========== PASO 3: GUARDAR EN BASE DE DATOS LOCAL ==========
      final comp = DB.NotesCompanion.insert(
        matricula: m,
        departamento: dep.isEmpty ? 'Nota' : dep,
        cuerpo: cuerpoFinal,
        tratante: Value(t),
        createdAt: Value(DateTime.now()),
        synced: const Value(false),
      );

      final rowId = await widget.db.insertNote(comp);
      print('✅ [GUARDADO LOCAL] Nota insertada rowId=$rowId para matrícula=$m depto=$dep');

      // ========== PASO 4: INTENTAR SUBIR A LA NUBE ==========
      bool subioNube = false;
      String? errorNube;
      
      try {
        final ok = await ApiService.pushSingleNote(
          matricula: m,
          departamento: dep,
          cuerpo: cuerpoFinal,
          tratante: t,
        );
        subioNube = ok;
        
        if (ok) {
          // Marcar como sincronizado si fue exitoso
          await widget.db.markNoteAsSynced(rowId);
          print('✅ [SINCRONIZACIÓN] Nota $rowId subida y marcada como sincronizada');
        } else {
          print('⚠️ [SINCRONIZACIÓN] Nota $rowId guardada local, respuesta false de la nube');
        }
      } catch (e) {
        errorNube = e.toString();
        print('❌ [SINCRONIZACIÓN] Error al sincronizar nota $rowId: $e');
      }

      // ========== PASO 5: CERRAR INDICADOR Y MOSTRAR RESULTADO ==========
      if (!mounted) return;
      
      // Cerrar el SnackBar de "Guardando..."
      ScaffoldMessenger.of(context).clearSnackBars();

      // Mostrar resultado con emoji y color según el estado
      final SnackBar resultSnackBar;
      if (subioNube) {
        resultSnackBar = SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✅ Nota guardada localmente y sincronizada con la nube',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        );
      } else {
        resultSnackBar = SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '💾 Nota guardada localmente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                errorNube != null 
                  ? '⚠️ Error al subir: ${errorNube.length > 50 ? '${errorNube.substring(0, 50)}...' : errorNube}'
                  : '⚠️ Se sincronizará automáticamente cuando haya conexión',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 4),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(resultSnackBar);

      // ========== PASO 6: LIMPIAR FORMULARIO ==========
      if (_deptChoice == 'Otra') _depto.clear();
      _tratante.clear();
      _cuerpo.clear();
      _diagnostico.clear();
      _tipoConsulta = null;
      _adjuntos.clear();

      _peso.clear();
      _talla.clear();
      _cintura.clear();
      _cadera.clear();

      // Registrar tiempo del último guardado
      _ultimoGuardado = DateTime.now();

      // ========== PASO 7: ACTUALIZAR UI ==========
      setState(() {});
      await _buscarNotasMatricula();

    } catch (e, st) {
      print('❌ [ERROR CRÍTICO] Error al guardar nota: $e\n$st');
      
      if (!mounted) return;
      
      // Cerrar indicador de progreso
      ScaffoldMessenger.of(context).clearSnackBars();
      
      // Mostrar error detallado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    '❌ Error al guardar nota',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                e.toString().length > 100 
                  ? '${e.toString().substring(0, 100)}...' 
                  : e.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Detalles',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Error detallado'),
                  content: SingleChildScrollView(
                    child: Text('$e\n\nStack trace:\n$st'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } finally {
      // ========== SIEMPRE LIBERAR EL FLAG DE GUARDADO ==========
      if (mounted) {
        setState(() => _guardandoNota = false);
      }
    }
  }

  // =============== SINCRONIZACIÓN DE NOTAS PENDIENTES =================

  Future<void> _sincronizarNotasPendientes() async {
    try {
      setState(() => _cargando = true);
      
      // Mostrar indicador de progreso inmediato
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('🔄 Verificando notas pendientes...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }
      
      final pendingNotes = await widget.db.getPendingNotes();
      
      if (pendingNotes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ No hay notas pendientes de sincronizar'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Actualizar mensaje con cantidad encontrada
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('🔄 Sincronizando ${pendingNotes.length} notas...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      int sincronizadas = 0;
      int errores = 0;
      final List<String> erroresDetalle = [];

      for (final nota in pendingNotes) {
        try {
          final ok = await ApiService.pushSingleNote(
            matricula: nota.matricula,
            departamento: nota.departamento,
            cuerpo: nota.cuerpo,
            tratante: nota.tratante ?? '',
            idOverride: 'nota_local_${nota.id}',
          );
          
          if (ok) {
            await widget.db.markNoteAsSynced(nota.id);
            sincronizadas++;
            print('✅ [SYNC] Nota ${nota.id} sincronizada exitosamente');
          } else {
            errores++;
            erroresDetalle.add('Nota ${nota.id}: Respuesta negativa');
            print('⚠️ [SYNC] Error al sincronizar nota ${nota.id}: respuesta false');
          }
        } catch (e) {
          errores++;
          erroresDetalle.add('Nota ${nota.id}: $e');
          print('❌ [SYNC] Error sincronizando nota ${nota.id}: $e');
        }
      }

      if (mounted) {
        // Cerrar indicador de progreso
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Mostrar resultado detallado
        if (errores == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ $sincronizadas ${sincronizadas == 1 ? 'nota sincronizada' : 'notas sincronizadas'} correctamente',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (sincronizadas > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '⚠️ Sincronización parcial: $sincronizadas OK, $errores errores',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (erroresDetalle.isNotEmpty && erroresDetalle.length <= 3) ...[
                    const SizedBox(height: 4),
                    ...erroresDetalle.take(3).map((e) => Text(
                      '• ${e.length > 60 ? '${e.substring(0, 60)}...' : e}',
                      style: const TextStyle(fontSize: 11),
                    )),
                  ],
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
              action: erroresDetalle.length > 3 ? SnackBarAction(
                label: 'Ver todos',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Errores de sincronización ($errores)'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: erroresDetalle.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $e', style: const TextStyle(fontSize: 12)),
                          )).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ) : null,
            ),
          );
        } else {
          // Solo errores
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '❌ Error: No se pudo sincronizar ninguna nota',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verifica tu conexión a internet y el token de autenticación',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Detalles',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Errores de sincronización'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: erroresDetalle.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $e', style: const TextStyle(fontSize: 12)),
                          )).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
        
        await _buscarNotasMatricula(); // Refrescar la vista
      }
    } catch (e, st) {
      print('❌ [ERROR CRÍTICO] Error al sincronizar notas pendientes: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      '❌ Error al sincronizar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e.toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

    // =============== AUTORIZACIÓN SUPERVISOR =================

  Future<bool> _askSupervisorPass() async {
    final ctrl = TextEditingController();
    bool ok = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Autorización de supervisor'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Clave',
            helperText: 'Ingrese la clave de supervisor para editar',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim() == kSupervisorKey) {
                ok = true;
              }
              Navigator.of(context).pop();
            },
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    return ok;
  }

  // ================== EDITAR NOTA LOCAL ===================

  Future<void> _editLocalNote(DB.Note n) async {
    final allowed = await _askSupervisorPass();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clave incorrecta o cancelado.')),
      );
      return;
    }

    final depCtrl = TextEditingController(text: n.departamento);
    final tratCtrl = TextEditingController(text: n.tratante ?? '');
    final cuerpoCtrl = TextEditingController(text: n.cuerpo);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar nota (LOCAL)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: depCtrl, decoration: const InputDecoration(labelText: 'Departamento')),
            const SizedBox(height: 8),
            TextField(controller: tratCtrl, decoration: const InputDecoration(labelText: 'Tratante')),
            const SizedBox(height: 8),
            TextField(controller: cuerpoCtrl, minLines: 6, maxLines: 12, decoration: const InputDecoration(labelText: 'Cuerpo')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: ()=>Navigator.of(ctx).pop(), child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: () async {
                    await (widget.db.update(widget.db.notes)
                      ..where((t) => t.id.equals(n.id)))
                      .write(DB.NotesCompanion(
                        departamento: Value(depCtrl.text.trim()),
                        tratante: Value(tratCtrl.text.trim()),
                        cuerpo: Value(cuerpoCtrl.text),
                      ));
                    if (mounted) Navigator.of(ctx).pop();
                    await _buscarNotasMatricula();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota local actualizada.')),
                    );
                  },
                  child: const Text('Guardar cambios'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

    // ================== GENERAR PDF Y EXPORTAR ===================

  Future<Uint8List> _buildNotePdf({
    required String title,
    required String matricula,
    required String? tratante,
    required String createdAtStr,
    required String cuerpo,
    String? diagnostico,
    String? tipoConsulta,
    List<String>? adjuntos,
  }) async {
    final doc = pw.Document();

    pw.Widget rowKV(String k, String v) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 120,
          child: pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(child: pw.Text(v)),
      ],
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(
          marginLeft: 36, marginRight: 36, marginTop: 36, marginBottom: 36,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CRES Carnets – Nota clínica',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(title),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          rowKV('Matrícula', matricula),
          rowKV('Tratante', tratante ?? 'N/A'),
          rowKV('Fecha', createdAtStr),
          if (diagnostico != null && diagnostico.trim().isNotEmpty)
            rowKV('Diagnóstico', diagnostico.trim()),
          if (tipoConsulta != null && tipoConsulta.trim().isNotEmpty)
            rowKV('Consulta', tipoConsulta.trim()),
          pw.SizedBox(height: 12),
          pw.Text('Cuerpo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(cuerpo),
          if (adjuntos != null && adjuntos.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Adjuntos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: adjuntos.map<pw.Widget>((a) => pw.Bullet(text: a)).toList(),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text('Generado por CRES Carnets',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );

    return doc.save();
  }

  Map<String, String?> _extractDxConsulta(String cuerpo) {
    String? dx;
    String? tc;
    final lines = cuerpo.split('\n');
    if (lines.isNotEmpty && lines[0].toLowerCase().startsWith('diagnóstico:')) {
      dx = lines[0].substring('diagnóstico:'.length).trim();
    }
    if (lines.length > 1 && lines[1].toLowerCase().startsWith('consulta:')) {
      tc = lines[1].substring('consulta:'.length).trim();
    }
    return {'dx': dx, 'tc': tc};
  }

  List<String> _extractAdjuntos(String cuerpo) {
    final out = <String>[];
    final idx = cuerpo.indexOf('\nAdjuntos:');
    if (idx == -1) return out;
    final tail = cuerpo.substring(idx).split('\n');
    for (final line in tail) {
      if (line.trim().startsWith('- ')) {
        out.add(line.trim().substring(2));
      }
    }
    return out;
  }

  Future<void> _printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> _exportCloudNote(Map<String, dynamic> n) async {
    final dep = (n['departamento'] ?? '-') as String;
    final cuerpo = (n['cuerpo'] ?? '') as String;
    final trat = (n['tratante'] ?? '') as String?;
    final fecha = (n['createdAt'] ?? '') as String;
    final mat = _mat.text.trim();

    final ex = _extractDxConsulta(cuerpo);
    final atts = _extractAdjuntos(cuerpo);

    final pdfBytes = await _buildNotePdf(
      title: dep,
      matricula: mat,
      tratante: trat,
      createdAtStr: fecha,
      cuerpo: cuerpo,
      diagnostico: ex['dx'],
      tipoConsulta: ex['tc'],
      adjuntos: atts,
    );

    await _showPdfActions(pdfBytes, 'nota_${mat}_$dep.pdf');
  }

  Future<void> _exportLocalNote(DB.Note n) async {
    final dep = n.departamento;
    final cuerpo = n.cuerpo;
    final trat = n.tratante;
    final fecha = _fmtDate(n.createdAt);
    final mat = _mat.text.trim();

    final ex = _extractDxConsulta(cuerpo);
    final atts = _extractAdjuntos(cuerpo);

    final pdfBytes = await _buildNotePdf(
      title: dep,
      matricula: mat,
      tratante: trat,
      createdAtStr: fecha,
      cuerpo: cuerpo,
      diagnostico: ex['dx'],
      tipoConsulta: ex['tc'],
      adjuntos: atts,
    );

    await _showPdfActions(pdfBytes, 'nota_${mat}_$dep.pdf');
  }

  Future<void> _showPdfActions(Uint8List pdfBytes, String fileName) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Exportar / Imprimir', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _printPdf(pdfBytes);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _sharePdf(pdfBytes, fileName);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

    // ================ UI: NOTAS CLOUD, LOCAL, NUEVA NOTA ================

  Widget _buildCloudNotesAccordion() {
    final cs = Theme.of(context).colorScheme;

    if (_notasCloud.isEmpty) {
      return Text(
        'Sin notas en nube para esta matrícula.',
        style: TextStyle(color: cs.onSurface.withOpacity(.75)),
      );
    }

    final total = _notasCloud.length;
    final slice = _showAllCloud ? _notasCloud : _notasCloud.take(_limit).toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showAllCloud = !_showAllCloud),
            icon: Icon(_showAllCloud ? Icons.filter_alt_off : Icons.expand_more),
            label: Text(_showAllCloud ? 'Ver últimas $_limit' : 'Ver todas ($total)'),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slice.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = slice[i];
            final dep = (n['departamento'] ?? '-').toString();
            final cuerpo = (n['cuerpo'] ?? '').toString();
            final trat = (n['tratante'] ?? '').toString();
            final fecha = (n['createdAt'] ?? '').toString();

            return ExpansionTile(
              leading: const Icon(Icons.cloud_done),
              title: Text(dep, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  if (trat.isNotEmpty) Text(trat),
                  if (trat.isNotEmpty && fecha.isNotEmpty) const SizedBox(width: 8),
                  if (fecha.isNotEmpty)
                    Text(
                      fecha,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: SelectableText(cuerpo),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportCloudNote(n),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar / Imprimir'),
                      ),
                      FilledButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edición en nube deshabilitada. Solo edición local.'))
                          ),
                        icon: const Icon(Icons.edit),
                        label: const Text('No editable'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocalNotesAccordion() {
    final cs = Theme.of(context).colorScheme;

    if (_notasLocal.isEmpty) {
      return Text(
        'Sin notas locales para esta matrícula.',
        style: TextStyle(color: cs.onSurface.withOpacity(.75)),
      );
    }

    final total = _notasLocal.length;
    final slice = _showAllLocal ? _notasLocal : _notasLocal.take(_limit).toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showAllLocal = !_showAllLocal),
            icon: Icon(_showAllLocal ? Icons.filter_alt_off : Icons.expand_more),
            label: Text(_showAllLocal ? 'Ver últimas $_limit' : 'Ver todas ($total)'),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slice.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = slice[i];
            final dep = n.departamento;
            final cuerpo = n.cuerpo;
            final trat = n.tratante ?? '';
            final fecha = _fmtDate(n.createdAt);

            return ExpansionTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(dep, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  if (trat.isNotEmpty) Text(trat),
                  if (trat.isNotEmpty && fecha.isNotEmpty) const SizedBox(width: 8),
                  if (fecha.isNotEmpty)
                    Text(
                      fecha,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: SelectableText(cuerpo),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportLocalNote(n),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar / Imprimir'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _editLocalNote(n),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _cardNube(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      icon: Icons.cloud_outlined,
      title: 'Expediente y notas (NUBE)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_atencionIntegral)
            Align(
              alignment: Alignment.topRight,
              child: Tooltip(
                message: 'Atención integral: 2 o más servicios activos',
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(.4), blurRadius: 6)],
                  ),
                ),
              ),
            ),
          if (_expedienteCloud == null)
            Text('No hay carnet en la nube para este ID.',
                style: TextStyle(color: cs.onSurface.withOpacity(.75)))
          else ...[
            _line('Nombre', _expedienteCloud!['nombreCompleto']),
            _line('Correo', _expedienteCloud!['correo']),
            _line('Edad', _expedienteCloud!['edad']),
            _line('Sexo', _expedienteCloud!['sexo']),
            _line('Programa', _expedienteCloud!['programa']),
            _line('Categoría', _expedienteCloud!['categoria']),
            _line('Alergias', _expedienteCloud!['alergias']),
            _line('Tipo de sangre', _expedienteCloud!['tipoSangre']),
            _line('Enfermedad', _expedienteCloud!['enfermedadCronica']),
            _line('Discapacidad', _expedienteCloud!['discapacidad']),
            _line('Tipo de discapacidad', _expedienteCloud!['tipoDiscapacidad']),
            _line('Unidad médica', _expedienteCloud!['unidadMedica']),
            _line('Núm. de afiliación', _expedienteCloud!['numeroAfiliacion']),
            _line('Uso Seguro Universitario', _expedienteCloud!['usoSeguroUniversitario']),
            _line('Donante', _expedienteCloud!['donante']),
            _line('Teléfono de emergencia', _expedienteCloud!['emergenciaTelefono']),
            _line('Contacto de emergencia', _expedienteCloud!['emergenciaContacto']),
            const SizedBox(height: 6),
            _line('Actualizado', _expedienteCloud!['timestamp']),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 18),
              const SizedBox(width: 6),
              Text('Notas en nube · ${_notasCloud.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          _buildCloudNotesAccordion(),
        ],
      ),
    );
  }

  Widget _cardLocal(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      icon: Icons.storage_outlined,
      title: 'Respaldo LOCAL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_atencionIntegral)
            Align(
              alignment: Alignment.topRight,
              child: Tooltip(
                message: 'Atención integral: 2 o más servicios activos',
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
              ),
            ),
          if (_expedienteLocal == null) ...[
            Text('No hay carnet local para esta matrícula.',
                style: TextStyle(color: cs.onSurface.withOpacity(.75))),
          ] else ...[
            Text('Nombre: ${_expedienteLocal!.nombreCompleto}'),
            Text('Correo: ${_expedienteLocal!.correo}'),
            Text('Edad: ${_expedienteLocal!.edad ?? '-'}'),
            Text('Sexo: ${_expedienteLocal!.sexo ?? '-'}'),
            Text('Programa: ${_expedienteLocal!.programa ?? '-'}'),
            Text('Categoría: ${_expedienteLocal!.categoria ?? '-'}'),
            Text('Alergias: ${_expedienteLocal!.alergias ?? '-'}'),
            Text('Tipo de sangre: ${_expedienteLocal!.tipoSangre ?? '-'}'),
            Text('Enfermedad: ${_expedienteLocal!.enfermedadCronica ?? '-'}'),
            const SizedBox(height: 6),
            Text('Actualizado: ${_fmtDate(_expedienteLocal!.timestamp)}'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 18),
              const SizedBox(width: 6),
              Text('Notas locales · ${_notasLocal.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          _buildLocalNotesAccordion(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Listeners para Nutrición (IMC/ICC)
    _peso.removeListener(_refresh);
    _talla.removeListener(_refresh);
    _cintura.removeListener(_refresh);
    _cadera.removeListener(_refresh);
    _peso.addListener(_refresh);
    _talla.addListener(_refresh);
    _cintura.addListener(_refresh);
    _cadera.addListener(_refresh);

    return Scaffold(
      appBar: uagroAppBar(
        'CRES Carnets', 
        'Agregar nota clínica',
        [
          IconButton(
            tooltip: 'Refrescar notas desde servidor',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              if (_mat.text.trim().isNotEmpty) {
                await _buscarNotasMatricula();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Notas actualizadas')),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Ver citas',
            icon: const Icon(Icons.event_rounded, color: Colors.white),
            onPressed: _mostrarCitas,
          ),
        ],
        context,
        widget.db,
      ),
      body: Row(
        children: [
          // Barra lateral institucional UAGro
          const BrandSidebar(),
          // Contenido principal (sin cambios de lógica)
          Expanded(
            child: SingleChildScrollView(
              padding: AppTheme.contentPadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NO CAMBIAR LÓGICA: mantener callbacks/estados intactos
                    // Encabezado + indicador integral
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'CRES Carnets - Nueva Nota Clínica',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (_atencionIntegral)
                          Tooltip(
                            message: 'Atención integral detectada (=2 servicios)',
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: UAGroColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: UAGroColors.success.withOpacity(.35), blurRadius: 6)],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing),

            // Buscar carnet por ID (QR)
            SectionCard(
              icon: Icons.qr_code_scanner,
              title: 'Buscar carnet por ID (QR)',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _id,
                          decoration: const InputDecoration(labelText: 'ID del carnet (QR)'),
                          onSubmitted: (_) => _buscarCarnetId(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: _cargando ? null : _buscarCarnetId,
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar carnet'),
                      ),
                    ],
                  ),
                  if (_cargando) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: cs.error)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Buscar NOTAS por matrícula
            SectionCard(
              icon: Icons.search,
              title: 'Buscar notas por matrícula',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mat,
                          decoration: const InputDecoration(labelText: 'Matrícula'),
                          onSubmitted: (_) => _buscarNotasMatricula(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: _cargando ? null : _buscarNotasMatricula,
                        icon: const Icon(Icons.notes),
                        label: const Text('Buscar notas'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (_mat.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Escribe una matrícula')),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FormScreen(
                                db: widget.db,
                                matriculaInicial: _mat.text.trim(),
                                lockMatricula: true,
                                carnetExistente: _expedienteCloud,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text('Editar carnet'),
                      ),
                    ],
                  ),
                  if (_cargando) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: cs.error)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),
            _cardNube(context),
            const SizedBox(height: 12),

            // NUEVA NOTA – resaltada
            _highlightedNoteComposer(cs),

            const SizedBox(height: 12),
            _cardLocal(context),
            const SizedBox(height: 12),
            _buildCitasCloud(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============== NUEVA NOTA UI DESTACADA ================

  Widget _highlightedNoteComposer(ColorScheme cs) {
    final isNutricion = _deptChoice == 'Consultorio de Nutrición';
    final isPsicologia = _deptChoice == 'Departamento psicopedagógico';
    final isOtra = _deptChoice == 'Otra';
    final requiereDx = !((_deptChoice == 'Otra') || (_deptChoice == 'Atención estudiantil'));

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(.18),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.primary.withOpacity(.15), blurRadius: 12, offset: const Offset(0, 6))],
        border: Border.all(color: cs.primary.withOpacity(.45), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Nueva nota (se guarda local y nube)',
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: const Text('Obligatoria*', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Departamento / área
                DropdownButtonFormField<String>(
                  value: _deptChoice,
                  items: _deptOpciones.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
                  decoration: const InputDecoration(labelText: 'Departamento / área *', border: OutlineInputBorder()),
                  onChanged: (v) => setState(() { _deptChoice = v; }),
                ),
                if (isOtra) ...[
                  const SizedBox(height: 8),
                  TextField(controller: _depto, decoration: const InputDecoration(labelText: 'Especifica otra área *')),
                ],
                const SizedBox(height: 8),

                // Tratante
                TextField(controller: _tratante, decoration: const InputDecoration(labelText: 'Tratante *')),
                const SizedBox(height: 8),

                // Diagnóstico (condicional)
                if (requiereDx) ...[
                  TextField(controller: _diagnostico, decoration: const InputDecoration(labelText: 'Diagnóstico *')),
                  const SizedBox(height: 8),
                ],

                // Tipo de consulta
                DropdownButtonFormField<String>(
                  value: _tipoConsulta,
                  items: const [
                    DropdownMenuItem(value: 'Primera vez', child: Text('Primera vez')),
                    DropdownMenuItem(value: 'Subsecuente', child: Text('Subsecuente')),
                  ],
                  decoration: const InputDecoration(labelText: 'Consulta *', border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => _tipoConsulta = v),
                ),
                const SizedBox(height: 8),

                // Nutrición: bloque extra
                if (isNutricion) ...[
                  const Divider(height: 24),
                  Text('Datos antropométricos (Nutrición)',
                      style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(.9))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _peso,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Peso (kg)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _talla,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Talla (m)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cintura,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cintura abdominal (cm)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cadera,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cadera (cm)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final imc = _imcVal == null ? 'N/A' : _imcVal!.toStringAsFixed(2);
                      final icc = _iccVal == null ? 'N/A' : _iccVal!.toStringAsFixed(2);
                      return Text('IMC: $imc    ·    Índice Cintura/Cadera: $icc',
                          style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(.9)));
                    },
                  ),
                  const Divider(height: 24),
                ],

                // Psicología: tests psicológicos disponibles
                if (isPsicologia) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.psychology, color: theme.UAGroColors.azulMarino, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tests Psicológicos',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: theme.UAGroColors.azulMarino.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Instrumentos de evaluación disponibles:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withOpacity(.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Verificar que haya una matrícula para asociar el test
                              final matricula = _mat.text.trim();
                              if (matricula.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingresa una matrícula para aplicar el test'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              // Obtener nombre del paciente si existe
                              String nombrePaciente = 'Paciente';
                              if (_expedienteLocal != null) {
                                nombrePaciente = _expedienteLocal!.nombreCompleto;
                              } else if (_expedienteCloud != null && _expedienteCloud!['nombreCompleto'] != null) {
                                nombrePaciente = _expedienteCloud!['nombreCompleto'];
                              }
                              
                              // Navegar a la pantalla de selección de tests
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TestSelectionScreen(
                                    matricula: matricula,
                                    nombrePaciente: nombrePaciente,
                                    db: widget.db,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.assignment),
                            label: const Text('Aplicar Tests Psicológicos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.UAGroColors.azulMarino,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Test de Hamilton (Depresión)\n'
                            '• Test de Beck (Ansiedad)\n'
                            '• Test DASS-21 (Depresión, Ansiedad, Estrés)',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(.6),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ],

                // Sección específica de Odontología: Odontograma - Versión discreta
                if (_deptChoice == 'Consultorio de Odontología') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.UAGroColors.azulMarino.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.UAGroColors.azulMarino.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.UAGroColors.azulMarino.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.medical_information_outlined, 
                            color: theme.UAGroColors.azulMarino, 
                            size: 24
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Odontograma Profesional',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.UAGroColors.azulMarino,
                                ),
                              ),
                              Text(
                                '32 dientes • FDI • Diagnóstico por superficie • PDF',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Verificar que haya una matrícula
                            final matricula = _mat.text.trim();
                            if (matricula.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ingresa una matrícula para crear el odontograma'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            // Obtener nombre del paciente
                            String nombrePaciente = 'Paciente';
                            if (_expedienteLocal != null) {
                              nombrePaciente = _expedienteLocal!.nombreCompleto;
                            } else if (_expedienteCloud != null && _expedienteCloud!['nombreCompleto'] != null) {
                              nombrePaciente = _expedienteCloud!['nombreCompleto'];
                            }
                            
                            // Navegar a la pantalla del odontograma
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OdontogramScreen(
                                  matricula: matricula,
                                  nombrePaciente: nombrePaciente,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.create, size: 18),
                          label: const Text('Crear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.UAGroColors.azulMarino,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Cuerpo de la nota
                TextField(
                  controller: _cuerpo,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Cuerpo de la nota *'),
                ),
                const SizedBox(height: 12),

                // Adjuntar (OPCIONAL) + Agendar cita + Mostrar citas
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: _pickAdjuntos,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Adjuntar archivo(s) (opcional)'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _agendarCita,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Agendar cita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade100,
                        foregroundColor: Colors.teal.shade700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _mostrarCitas,
                      icon: const Icon(Icons.list),
                      label: const Text('Mostrar citas'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                if (_adjuntos.isNotEmpty) 
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${_adjuntos.length} adjunto(s) seleccionado(s)'),
                  ),

                if (_adjuntos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _adjuntos.map((f) {
                      return Chip(
                        label: Text(f.name, overflow: TextOverflow.ellipsis),
                        onDeleted: () {
                          setState(() {
                            _adjuntos.remove(f);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _guardandoNota ? null : _guardarNota,
                  icon: _guardandoNota 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                  label: Text(_guardandoNota ? 'Guardando...' : 'Guardar nota'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: (_cargando || _guardandoNota) ? null : _sincronizarNotasPendientes,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar notas pendientes'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Campos obligatorios marcados con *. Los adjuntos son opcionales.',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar las citas del cloud
  Widget _buildCitasCloud() {
    if (_cargandoCitas) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas del Cloud',
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Cargando citas del cloud...'),
          ],
        ),
      );
    }

    if (_errorCitas != null) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas del Cloud',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No fue posible cargar las citas.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_citasCloud.isEmpty) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas del Cloud (0)',
        child: Text(
          'No hay citas para esta matrícula.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      );
    }

    // Debug temporal para confirmar claves
    if (_citasCloud.isNotEmpty) {
      print('[CITAS_KEYS] ${_citasCloud.first.keys.toList()}');
    }

    // Ordenar por inicio descendente
    final list = [..._citasCloud];
    list.sort((a, b) {
      final da = _parseIso(_str(a, 'inicio'));
      final db = _parseIso(_str(b, 'inicio'));
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return SectionCard(
      icon: Icons.event,
      title: 'Citas del Cloud (${list.length})',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = list[index];
          final motivo = _str(item, 'motivo');
          final dtIni = _parseIso(_str(item, 'inicio'));
          final (fecha, hora) = _fmtFechaHora(dtIni);
          final dep = _str(item, 'departamento');
          final est = _str(item, 'estado');

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icono izquierdo
                Icon(
                  Icons.event,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                // Contenido principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        motivo.isEmpty ? 'Sin asunto' : motivo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: $fecha',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Hora: $hora',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (dep.isNotEmpty)
                        Text(
                          'Departamento: $dep',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                // Chip de estado a la derecha
                if (est.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _estadoColor(est),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      est,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _estadoTextColor(est),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helpers locales para citas
  String _str(Map m, String k) {
    final v = m[k];
    return (v == null) ? '' : v.toString().trim();
  }

  DateTime? _parseIso(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';

  (String, String) _fmtFechaHora(DateTime? dt) {
    if (dt == null) return ('No especificada', 'No especificada');
    final f = '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
    final h = '${_two(dt.hour)}:${_two(dt.minute)}';
    return (f, h);
  }

  Color _estadoColor(String estado) {
    final est = estado.toLowerCase();
    if (est.contains('programada')) return Colors.blue.shade100;
    if (est.contains('cancelada')) return Colors.red.shade100;
    if (est.contains('realizada') || est.contains('completada')) return Colors.green.shade100;
    return Colors.grey.shade100;
  }

  Color _estadoTextColor(String estado) {
    final est = estado.toLowerCase();
    if (est.contains('programada')) return Colors.blue.shade700;
    if (est.contains('cancelada')) return Colors.red.shade700;
    if (est.contains('realizada') || est.contains('completada')) return Colors.green.shade700;
    return Colors.grey.shade700;
  }
}