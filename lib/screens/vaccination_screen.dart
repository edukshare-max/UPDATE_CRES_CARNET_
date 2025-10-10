import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../ui/uagro_theme.dart';
import '../utils/vaccination_pdf_generator.dart';

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

  // Variables de estado
  String? _vacunaSeleccionada;
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
    _cargarCampanas();
  }

  @override
  void dispose() {
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

  /// Cargar campañas desde el backend
  Future<void> _cargarCampanas() async {
    setState(() => _isLoadingCampaigns = true);
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/vaccination-campaigns/'),
      );

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
      } else {
        _mostrarError('Error al cargar campañas: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
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
    if (_vacunaSeleccionada == null) {
      _mostrarError('Selecciona una vacuna');
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
          'vacuna': _vacunaSeleccionada!,
          'fechaInicio': _fechaInicio.toIso8601String(),
          'activa': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _mostrarExito('Campaña creada exitosamente');
        _nombreCampanaCtrl.clear();
        _descripcionCtrl.clear();
        setState(() => _vacunaSeleccionada = null);
        await _cargarCampanas();
      } else {
        _mostrarError('Error al crear campaña: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => _isCreatingCampaign = false);
    }
  }

  /// Registrar aplicación de vacuna
  Future<void> _registrarVacunacion() async {
    if (_campanaActivaId == null) {
      _mostrarError('Selecciona una campaña activa');
      return;
    }
    if (_matriculaCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa la matrícula del estudiante');
      return;
    }

    setState(() => _isCreatingRecord = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/vaccination-records/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'campanaId': _campanaActivaId!,
          'campanaNombre': _campanaActivaNombre ?? '',
          'matricula': _matriculaCtrl.text.trim(),
          'nombreEstudiante': _nombreEstudianteCtrl.text.trim(),
          'vacuna': _vacunaSeleccionada ?? _campanaActivaNombre ?? '',
          'dosis': _dosisSeleccionada,
          'lote': _loteCtrl.text.trim(),
          'aplicadoPor': _aplicadoPorCtrl.text.trim(),
          'observaciones': _observacionesCtrl.text.trim(),
          'fechaAplicacion': _fechaAplicacion.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _mostrarExito('Vacunación registrada exitosamente');
        _matriculaCtrl.clear();
        _nombreEstudianteCtrl.clear();
        _loteCtrl.clear();
        _observacionesCtrl.clear();
        setState(() => _dosisSeleccionada = 1);
        await _cargarRegistrosCampana(_campanaActivaId!);
      } else {
        _mostrarError('Error al registrar vacunación: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
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
              
              DropdownButtonFormField<String>(
                value: _vacunaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Vacuna',
                  prefixIcon: Icon(Icons.vaccines),
                ),
                items: _vacunasDisponibles.map((vacuna) {
                  return DropdownMenuItem(
                    value: vacuna,
                    child: Text(vacuna),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _vacunaSeleccionada = value),
                validator: (v) => v == null ? 'Selecciona una vacuna' : null,
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No hay campañas creadas'),
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
                    subtitle: Text(
                      '${campana['vacuna'] ?? ''} • ${campana['totalAplicadas'] ?? 0} aplicadas',
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
