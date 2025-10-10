import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import '../ui/uagro_theme.dart';
import '../utils/vaccination_pdf_generator.dart';
import '../data/api_service.dart';
import '../data/db.dart' as DB;
import '../data/sync_vacunaciones.dart';

/// Pantalla de gestión de campañas de vacunación
class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCampanaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _nombreEstudianteCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  final _aplicadoPorCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  
  // Base de datos local para sincronización
  late DB.AppDatabase _db;

  // Variables de estado
  String? _vacunaSeleccionada; // Para registrar aplicación individual
  List<String> _vacunasSeleccionadasCampana = []; // Para crear campaña (múltiples)
  int _dosisSeleccionada = 1;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaAplicacion = DateTime.now();
  bool _isLoadingCampaigns = false;
  bool _isCreatingCampaign = false;
  bool _isCreatingRecord = false;
  
  // Datos
  List<dynamic> _campanas = [];
  String? _campanaActivaId;
  String? _campanaActivaNombre;
  List<dynamic> _registros = [];

  // Lista de vacunas comunes en México para universidades
  final List<String> _vacunasDisponibles = [
    'Influenza (Gripe)',
    'COVID-19',
    'Hepatitis B',
    'Tétanos y Difteria (Td)',
    'Triple Viral (SRP)',
    'Hepatitis A',
    'Varicela',
    'VPH (Papiloma Humano)',
    'Meningococo',
    'Neumococo',
    'BCG (Tuberculosis)',
    'Antirrábica',
  ];

  @override
  void initState() {
    super.initState();
    _db = DB.AppDatabase();
    _cargarCampanas();
    _sincronizarPendientes(); // Intentar sincronizar al inicio
  }

  @override
  void dispose() {
    _db.close();
    _nombreCampanaCtrl.dispose();
    _descripcionCtrl.dispose();
    _matriculaCtrl.dispose();
    _nombreEstudianteCtrl.dispose();
    _loteCtrl.dispose();
    _aplicadoPorCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  /// Obtener la URL base del backend
  String get _apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL',
        defaultValue: 'https://fastapi-backend-o7ks.onrender.com');
    return envUrl;
  }

  /// Sincronizar vacunaciones pendientes
  Future<void> _sincronizarPendientes() async {
    try {
      final pendientes = await _db.getPendingVacunaciones();
      if (pendientes.isNotEmpty) {
        print('🔄 Intentando sincronizar ${pendientes.length} vacunaciones pendientes...');
        await syncVacunacionesPendientes(_db);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${pendientes.length} vacunaciones sincronizadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('⚠️ No se pudieron sincronizar vacunaciones pendientes: $e');
    }
  }

  /// Cargar campañas desde el backend
  Future<void> _cargarCampanas() async {
    setState(() => _isLoadingCampaigns = true);
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/vaccination-campaigns/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _campanas = data;
          // Seleccionar la primera campaña activa si existe
          final activa = data.firstWhere(
            (c) => c['activa'] == true,
            orElse: () => data.isNotEmpty ? data.first : null,
          );
          if (activa != null) {
            _campanaActivaId = activa['id'];
            _campanaActivaNombre = activa['nombre'];
            _cargarRegistrosCampana(_campanaActivaId!);
          }
        });
      } else if (response.statusCode == 404) {
        // Endpoint no existe aún, usar datos locales
        print('⚠️ Endpoint de campañas no implementado, usando modo local');
        setState(() => _campanas = []);
      } else {
        _mostrarError('Error al cargar campañas: ${response.statusCode}');
      }
    } catch (e) {
      // Error de conexión o endpoint no existe, trabajar en modo local
      print('⚠️ No se pudo conectar al backend: $e');
      setState(() => _campanas = []);
    } finally {
      setState(() => _isLoadingCampaigns = false);
    }
  }

  /// Cargar registros de una campaña específica
  Future<void> _cargarRegistrosCampana(String campanaId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/vaccination-records/campaign/$campanaId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() => _registros = data);
      }
    } catch (e) {
      _mostrarError('Error al cargar registros: $e');
    }
  }

  /// Crear una nueva campaña de vacunación
  Future<void> _crearCampana() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vacunasSeleccionadasCampana.isEmpty) {
      _mostrarError('Selecciona al menos una vacuna para la campaña');
      return;
    }

    setState(() => _isCreatingCampaign = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/vaccination-campaigns/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nombreCampanaCtrl.text.trim(),
          'descripcion': _descripcionCtrl.text.trim(),
          'vacunas': _vacunasSeleccionadasCampana, // MÚLTIPLES VACUNAS
          'fechaInicio': _fechaInicio.toIso8601String(),
          'activa': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _mostrarExito('Campaña creada exitosamente');
        _nombreCampanaCtrl.clear();
        _descripcionCtrl.clear();
        setState(() => _vacunasSeleccionadasCampana = []);
        await _cargarCampanas();
      } else if (response.statusCode == 404 || response.statusCode == 422 || 
                 response.statusCode >= 500) {
        // Endpoint no existe, datos incompatibles o error del servidor → guardar localmente
        print('⚠️ Backend error ${response.statusCode}, usando modo local');
        final nuevaCampana = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'nombre': _nombreCampanaCtrl.text.trim(),
          'descripcion': _descripcionCtrl.text.trim(),
          'vacunas': _vacunasSeleccionadasCampana,
          'fechaInicio': _fechaInicio.toIso8601String(),
          'activa': true,
        };
        setState(() {
          _campanas.add(nuevaCampana);
          _campanaActivaId = nuevaCampana['id'] as String;
          _campanaActivaNombre = nuevaCampana['nombre'] as String;
        });
        _mostrarExito('Campaña creada localmente (backend no compatible)');
        _nombreCampanaCtrl.clear();
        _descripcionCtrl.clear();
        setState(() => _vacunasSeleccionadasCampana = []);
      } else {
        _mostrarError('Error al crear campaña: ${response.statusCode}');
      }
    } catch (e) {
      // Error de conexión, guardar localmente
      print('⚠️ Sin conexión, guardando campaña localmente: $e');
      final nuevaCampana = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'nombre': _nombreCampanaCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'vacunas': _vacunasSeleccionadasCampana,
        'fechaInicio': _fechaInicio.toIso8601String(),
        'activa': true,
      };
      setState(() {
        _campanas.add(nuevaCampana);
        _campanaActivaId = nuevaCampana['id'] as String;
        _campanaActivaNombre = nuevaCampana['nombre'] as String;
      });
      _mostrarExito('Campaña creada localmente (sin conexión al servidor)');
      _nombreCampanaCtrl.clear();
      _descripcionCtrl.clear();
      setState(() => _vacunasSeleccionadasCampana = []);
    } finally {
      setState(() => _isCreatingCampaign = false);
    }
  }

  /// Registrar aplicación de vacuna
  /// SIEMPRE guarda en el expediente del estudiante (Cosmos DB)
  /// Además guarda localmente para la lista de la campaña
  Future<void> _registrarVacunacion() async {
    if (_campanaActivaId == null) {
      _mostrarError('Selecciona una campaña activa');
      return;
    }
    if (_matriculaCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa la matrícula del estudiante');
      return;
    }
    if (_vacunaSeleccionada == null) {
      _mostrarError('Selecciona la vacuna a aplicar');
      return;
    }

    setState(() => _isCreatingRecord = true);
    
    final matricula = _matriculaCtrl.text.trim();
    final nombreEstudiante = _nombreEstudianteCtrl.text.trim();
    final vacuna = _vacunaSeleccionada!;
    final dosis = _dosisSeleccionada;
    final lote = _loteCtrl.text.trim();
    final aplicadoPor = _aplicadoPorCtrl.text.trim();
    final observaciones = _observacionesCtrl.text.trim();
    final fechaAplicacion = _fechaAplicacion.toIso8601String();
    
    try {
      // 🎯 PASO 1: Guardar en EXPEDIENTE del estudiante (Cosmos DB)
      print('💉 Guardando aplicación en expediente de matrícula: $matricula');
      final guardadoEnExpediente = await ApiService.guardarAplicacionVacuna(
        matricula: matricula,
        campana: _campanaActivaNombre ?? 'Campana',
        vacuna: vacuna,
        dosis: dosis,
        fechaAplicacion: fechaAplicacion,
        lote: lote,
        aplicadoPor: aplicadoPor,
        observaciones: observaciones,
        nombreEstudiante: nombreEstudiante,
      );
      
      if (guardadoEnExpediente) {
        print('✅ Aplicación guardada en expediente del estudiante');
      } else {
        // 💾 Si no se pudo guardar en Cosmos DB, guardar en SQLite para sincronizar después
        print('⚠️ Guardando en SQLite local para sincronización posterior...');
        await _db.insertVacunacionPendiente(
          DB.VacunacionesPendientesCompanion(
            matricula: drift.Value(matricula),
            nombreEstudiante: drift.Value(nombreEstudiante),
            campana: drift.Value(_campanaActivaNombre ?? 'Campana'),
            vacuna: drift.Value(vacuna),
            dosis: drift.Value(dosis),
            lote: drift.Value(lote),
            aplicadoPor: drift.Value(aplicadoPor),
            fechaAplicacion: drift.Value(fechaAplicacion),
            observaciones: drift.Value(observaciones),
            createdAt: drift.Value(DateTime.now()),
            synced: drift.Value(false),
          ),
        );
        print('💾 Guardado en SQLite local, se sincronizará cuando haya conexión');
      }
      
      // 🎯 PASO 2: Intentar guardar en lista de registros de campaña (opcional)
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/vaccination-records/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'campanaId': _campanaActivaId!,
            'campanaNombre': _campanaActivaNombre ?? '',
            'matricula': matricula,
            'nombreEstudiante': nombreEstudiante,
            'vacuna': vacuna,
            'dosis': dosis,
            'lote': lote,
            'aplicadoPor': aplicadoPor,
            'observaciones': observaciones,
            'fechaAplicacion': fechaAplicacion,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ También guardado en lista de campaña');
        }
      } catch (e) {
        print('⚠️ Lista de campaña no disponible: $e');
      }
      
      // 🎯 PASO 3: Guardar LOCALMENTE para la lista visual
      final nuevoRegistro = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'campanaId': _campanaActivaId!,
        'campanaNombre': _campanaActivaNombre ?? '',
        'matricula': matricula,
        'nombreEstudiante': nombreEstudiante,
        'vacuna': vacuna,
        'dosis': dosis,
        'lote': lote,
        'aplicadoPor': aplicadoPor,
        'observaciones': observaciones,
        'fechaAplicacion': fechaAplicacion,
      };
      setState(() => _registros.add(nuevoRegistro));
      
      // 🎉 Mostrar mensaje según resultado
      if (guardadoEnExpediente) {
        _mostrarExito('✅ Vacunación registrada en expediente del estudiante');
      } else {
        _mostrarExito('💾 Guardada localmente - se sincronizará cuando haya conexión');
      }
      
      // Limpiar formulario
      _matriculaCtrl.clear();
      _nombreEstudianteCtrl.clear();
      _loteCtrl.clear();
      _observacionesCtrl.clear();
      setState(() {
        _dosisSeleccionada = 1;
        _vacunaSeleccionada = null;
      });
      
    } catch (e) {
      print('❌ Error al registrar vacunación: $e');
      _mostrarError('Error al registrar: $e');
    } finally {
      setState(() => _isCreatingRecord = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  /// Generar y descargar PDF del reporte de vacunación
  Future<void> _generarPDF() async {
    if (_campanaActivaId == null || _registros.isEmpty) {
      _mostrarError('No hay registros para generar el reporte');
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Obtener datos de la campaña
      final campana = _campanas.firstWhere(
        (c) => c['id'] == _campanaActivaId,
        orElse: () => {'nombre': 'Campaña', 'vacuna': 'Vacuna'},
      );

      // Generar PDF
      final file = await VaccinationPdfGenerator.generateCampaignReport(
        campaignName: campana['nombre'] ?? 'Campaña de Vacunación',
        vaccine: campana['vacuna'] ?? 'Vacuna',
        records: _registros,
        description: campana['descripcion'],
        startDate: campana['fechaInicio'] != null
            ? DateTime.parse(campana['fechaInicio'])
            : null,
      );

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar diálogo de éxito con opciones
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('PDF Generado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('El reporte PDF ha sido generado exitosamente.'),
              const SizedBox(height: 12),
              Text(
                'Ubicación:\n${file.path}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // Abrir la carpeta de descargas
                if (Platform.isWindows) {
                  final dir = file.parent.path;
                  await Process.run('explorer', [dir]);
                }
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Abrir carpeta'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      Navigator.of(context, rootNavigator: true).pop();
      _mostrarError('Error al generar PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Sistema de Vacunación'),
        backgroundColor: Colors.purple[700],
        actions: [
          FutureBuilder<List<DB.VacunacionesPendiente>>(
            future: _db.getPendingVacunaciones(),
            builder: (context, snapshot) {
              final pendientes = snapshot.data?.length ?? 0;
              if (pendientes > 0) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: _sincronizarPendientes,
                      tooltip: 'Sincronizar pendientes',
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$pendientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCampanas,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoadingCampaigns
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección: Crear Campaña
                  _buildSeccionCrearCampana(),
                  
                  const SizedBox(height: 32),
                  
                  // Sección: Campañas Activas
                  _buildSeccionCampanasActivas(),
                  
                  const SizedBox(height: 32),
                  
                  // Sección: Registrar Vacunación
                  if (_campanaActivaId != null) ...[
                    _buildSeccionRegistrarVacunacion(),
                    
                    const SizedBox(height: 32),
                    
                    // Sección: Registros de la Campaña
                    _buildSeccionRegistros(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSeccionCrearCampana() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, color: Colors.purple[700], size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Crear Nueva Campaña',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nombreCampanaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Campaña',
                  hintText: 'Ej: Campaña Influenza Otoño 2025',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Requerido'
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Breve descripción de la campaña',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              // Selector de múltiples vacunas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vaccines, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Vacunas de la Campaña',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona una o más vacunas:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _vacunasDisponibles.map((vacuna) {
                          final seleccionada = _vacunasSeleccionadasCampana.contains(vacuna);
                          return FilterChip(
                            label: Text(vacuna),
                            selected: seleccionada,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _vacunasSeleccionadasCampana.add(vacuna);
                                } else {
                                  _vacunasSeleccionadasCampana.remove(vacuna);
                                }
                              });
                            },
                            avatar: seleccionada
                                ? const Icon(Icons.check_circle, size: 18)
                                : null,
                          );
                        }).toList(),
                      ),
                      if (_vacunasSeleccionadasCampana.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Selecciona al menos una vacuna',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (_vacunasSeleccionadasCampana.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_vacunasSeleccionadasCampana.length} vacuna(s) seleccionada(s)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de Inicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicio,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (fecha != null) {
                    setState(() => _fechaInicio = fecha);
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCreatingCampaign ? null : _crearCampana,
                  icon: _isCreatingCampaign
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isCreatingCampaign
                      ? 'Creando...'
                      : 'Crear Campaña'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionCampanasActivas() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: UAGroColors.azulMarino, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Campañas Disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: UAGroColors.azulMarino,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_campanas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.vaccines_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay campañas registradas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primera campaña de vacunación en la sección de arriba',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._campanas.map((campana) {
                final isSelected = campana['id'] == _campanaActivaId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected
                      ? Colors.purple[50]
                      : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      Icons.vaccines,
                      color: isSelected
                          ? Colors.purple[700]
                          : Colors.grey,
                    ),
                    title: Text(
                      campana['nombre'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (campana['vacunas'] != null && campana['vacunas'] is List)
                          Text('${(campana['vacunas'] as List).join(', ')}')
                        else if (campana['vacuna'] != null)
                          Text('${campana['vacuna']}'),
                        Text(
                          '${campana['totalAplicadas'] ?? 0} aplicadas',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: campana['activa'] == true
                        ? Chip(
                            label: const Text('Activa', style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.green[100],
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _campanaActivaId = campana['id'];
                        _campanaActivaNombre = campana['nombre'];
                      });
                      _cargarRegistrosCampana(campana['id']);
                    },
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionRegistrarVacunacion() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: UAGroColors.rojoEscudo, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registrar Aplicación de Vacuna',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: UAGroColors.rojoEscudo,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Campaña: $_campanaActivaNombre',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _matriculaCtrl,
              decoration: const InputDecoration(
                labelText: 'Matrícula del Estudiante',
                hintText: 'Ej: 202012345',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nombreEstudianteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Estudiante (opcional)',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selector de vacuna de la campaña
            if (_campanaActivaId != null)
              Builder(
                builder: (context) {
                  // Obtener vacunas de la campaña activa
                  final campanaActiva = _campanas.firstWhere(
                    (c) => c['id'] == _campanaActivaId,
                    orElse: () => {},
                  );
                  
                  List<String> vacunasCampana = [];
                  if (campanaActiva['vacunas'] != null && campanaActiva['vacunas'] is List) {
                    vacunasCampana = List<String>.from(campanaActiva['vacunas']);
                  } else if (campanaActiva['vacuna'] != null) {
                    vacunasCampana = [campanaActiva['vacuna'] as String];
                  }
                  
                  if (vacunasCampana.isEmpty) {
                    return const Text('Esta campaña no tiene vacunas asignadas');
                  }
                  
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _vacunaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Vacuna a Aplicar',
                          prefixIcon: Icon(Icons.vaccines),
                        ),
                        items: vacunasCampana.map((vacuna) {
                          return DropdownMenuItem(
                            value: vacuna,
                            child: Text(vacuna),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _vacunaSeleccionada = value),
                        validator: (v) => v == null ? 'Selecciona la vacuna' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _dosisSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Número de Dosis',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    items: [1, 2, 3, 4].map((dosis) {
                      return DropdownMenuItem(
                        value: dosis,
                        child: Text('Dosis $dosis'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _dosisSeleccionada = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _loteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lote (opcional)',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _aplicadoPorCtrl,
              decoration: const InputDecoration(
                labelText: 'Aplicado por (opcional)',
                hintText: 'Nombre del personal médico',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha de Aplicación'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaAplicacion)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaAplicacion,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (fecha != null) {
                  setState(() => _fechaAplicacion = fecha);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _observacionesCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCreatingRecord ? null : _registrarVacunacion,
                icon: _isCreatingRecord
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isCreatingRecord
                    ? 'Guardando...'
                    : 'Registrar Vacunación'),
                style: FilledButton.styleFrom(
                  backgroundColor: UAGroColors.rojoEscudo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionRegistros() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green[700], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Registros de Vacunación',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                if (_registros.isNotEmpty)
                  Chip(
                    label: Text('${_registros.length} registros'),
                    backgroundColor: Colors.green[100],
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_registros.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No hay registros en esta campaña'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Matrícula')),
                    DataColumn(label: Text('Estudiante')),
                    DataColumn(label: Text('Vacuna')),
                    DataColumn(label: Text('Dosis')),
                    DataColumn(label: Text('Fecha')),
                  ],
                  rows: _registros.map((registro) {
                    return DataRow(cells: [
                      DataCell(Text(registro['matricula'] ?? '')),
                      DataCell(Text(registro['nombreEstudiante'] ?? 'N/A')),
                      DataCell(Text(registro['vacuna'] ?? '')),
                      DataCell(Text(registro['dosis']?.toString() ?? '1')),
                      DataCell(Text(
                        registro['fechaAplicacion'] != null
                            ? DateFormat('dd/MM/yyyy').format(
                                DateTime.parse(registro['fechaAplicacion']))
                            : 'N/A',
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            
            if (_registros.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _generarPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar Reporte PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
