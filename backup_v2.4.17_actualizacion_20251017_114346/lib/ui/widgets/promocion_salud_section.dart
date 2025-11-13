import 'package:flutter/material.dart';
import '../brand.dart';
import '../feedback.dart';
import '../../data/api_service.dart';
import 'section_card.dart';

class PromocionSaludSection extends StatefulWidget {
  const PromocionSaludSection({Key? key}) : super(key: key);

  @override
  State<PromocionSaludSection> createState() => _PromocionSaludSectionState();
}

class _PromocionSaludSectionState extends State<PromocionSaludSection> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _supervisorKeyController = TextEditingController();
  
  String? _categoria;
  String? _programa;
  String? _destinatario = 'alumno';
  bool _requiereAutorizacion = false;
  bool _autorizado = false;
  bool _enviando = false;
  bool _validandoClave = false;

  // Opciones para los dropdowns
  final List<String> _categorias = [
    'Prevención',
    'Promoción',
    'Tratamiento',
    'Rehabilitación',
    'Psicología',
    'Nutrición',
    'Medicina General',
    'Especialidades',
  ];

  final List<String> _programas = [
    'Licenciatura',
    'Maestría',
    'Doctorado',
    'Diplomado',
    'Curso',
    'Taller',
    'Conferencia',
    'Todos',
  ];

  final List<String> _destinatarios = [
    'alumno',
    'general',
  ];

  @override
  void dispose() {
    _linkController.dispose();
    _departamentoController.dispose();
    _matriculaController.dispose();
    _supervisorKeyController.dispose();
    super.dispose();
  }

  void _onDestinatarioChanged(String? value) {
    setState(() {
      _destinatario = value;
      _requiereAutorizacion = value == 'general';
      _autorizado = value == 'alumno'; // Los alumnos no requieren autorización
    });
  }

  Future<void> _validarClaveSupervisor() async {
    if (_supervisorKeyController.text.trim().isEmpty) {
      showErr(context, 'Ingrese la clave de supervisor');
      return;
    }

    setState(() => _validandoClave = true);

    try {
      final result = await ApiService.validateSupervisorKey(_supervisorKeyController.text.trim());
      
      if (result != null && result['valid'] == true) {
        setState(() {
          _autorizado = true;
          _validandoClave = false;
        });
        if (mounted) {
          showOk(context, 'Clave válida - Autorización concedida');
        }
      } else {
        setState(() {
          _autorizado = false;
          _validandoClave = false;
        });
        if (mounted) {
          showErr(context, result?['message'] ?? 'Clave incorrecta');
        }
      }
    } catch (e) {
      setState(() {
        _autorizado = false;
        _validandoClave = false;
      });
      if (mounted) {
        showErr(context, 'Error al validar clave: $e');
      }
    }
  }

  Future<void> _enviarPromocion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiereAutorizacion && !_autorizado) {
      showErr(context, 'Requiere autorización de supervisor para envíos generales');
      return;
    }

    setState(() => _enviando = true);

    try {
      final promocionData = {
        'link': _linkController.text.trim(),
        'departamento': _departamentoController.text.trim(),
        'categoria': _categoria!,
        'programa': _programa!,
        'matricula': _destinatario == 'alumno' ? _matriculaController.text.trim() : '',
        'destinatario': _destinatario!,
        'autorizado': _autorizado,
      };

      final result = await ApiService.createPromocionSalud(promocionData);

      if (result != null) {
        if (mounted) {
          showOk(context, 'Promoción de salud enviada exitosamente');
          _limpiarFormulario();
        }
      } else {
        if (mounted) {
          showErr(context, 'Error al enviar promoción de salud');
        }
      }
    } catch (e) {
      if (mounted) {
        showErr(context, 'Error: $e');
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    setState(() {
      _linkController.clear();
      _departamentoController.clear();
      _matriculaController.clear();
      _supervisorKeyController.clear();
      _categoria = null;
      _programa = null;
      _destinatario = 'alumno';
      _requiereAutorizacion = false;
      _autorizado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.health_and_safety,
      title: 'Promoción de Salud',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Link de promoción
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link de promoción *',
                border: OutlineInputBorder(),
                hintText: 'https://...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El link es obligatorio';
                }
                // Validación básica de URL
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme) {
                  return 'Ingrese un link válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Departamento
            TextFormField(
              controller: _departamentoController,
              decoration: const InputDecoration(
                labelText: 'Departamento *',
                border: OutlineInputBorder(),
                hintText: 'Ej: SASU, Psicología, etc.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El departamento es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Row con Categoría y Programa
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                    ),
                    items: _categorias.map((categoria) => 
                      DropdownMenuItem(value: categoria, child: Text(categoria))
                    ).toList(),
                    onChanged: (value) => setState(() => _categoria = value),
                    validator: (value) => value == null ? 'Seleccione una categoría' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _programa,
                    decoration: const InputDecoration(
                      labelText: 'Programa *',
                      border: OutlineInputBorder(),
                    ),
                    items: _programas.map((programa) => 
                      DropdownMenuItem(value: programa, child: Text(programa))
                    ).toList(),
                    onChanged: (value) => setState(() => _programa = value),
                    validator: (value) => value == null ? 'Seleccione un programa' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Destinatario
            DropdownButtonFormField<String>(
              value: _destinatario,
              decoration: const InputDecoration(
                labelText: 'Destinatario *',
                border: OutlineInputBorder(),
              ),
              items: _destinatarios.map((dest) => 
                DropdownMenuItem(
                  value: dest, 
                  child: Text(dest == 'alumno' ? 'Alumno específico' : 'Envío general')
                )
              ).toList(),
              onChanged: _onDestinatarioChanged,
            ),
            const SizedBox(height: 16),

            // Campo de matrícula (solo si es para alumno)
            if (_destinatario == 'alumno') ...[
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula del alumno *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 2021030123',
                ),
                validator: (value) {
                  if (_destinatario == 'alumno' && (value == null || value.trim().isEmpty)) {
                    return 'La matrícula es obligatoria para envíos a alumnos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Autorización de supervisor (solo para envíos generales)
            if (_requiereAutorizacion) ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Autorización de Supervisor Requerida',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _supervisorKeyController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Clave de supervisor',
                              border: OutlineInputBorder(),
                              hintText: 'Ingrese la clave',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _validandoClave ? null : _validarClaveSupervisor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _autorizado ? Colors.green : UAGroColors.blue,
                          ),
                          child: _validandoClave 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_autorizado ? Icons.check : Icons.vpn_key),
                        ),
                      ],
                    ),
                    if (_autorizado) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Autorización concedida',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviarPromocion,
                    icon: _enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                    label: Text(_enviando ? 'Enviando...' : 'Enviar Promoción'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UAGroColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _enviando ? null : _limpiarFormulario,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}