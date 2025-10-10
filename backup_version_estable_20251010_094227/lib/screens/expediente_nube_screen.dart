import 'package:flutter/material.dart';// lib/screens/expediente_nube_screen.dart

import '../data/api_service.dart';import 'package:flutter/material.dart';

import '../ui/brand.dart';import '../data/api_service.dart';

import '../ui/widgets/section_card.dart';import '../ui/brand.dart';

import '../ui/widgets/section_card.dart';

class ExpedienteNubeScreen extends StatefulWidget {

  final String? idInicial;

  final String? matriculaInicial;class ExpedienteNubeScreen extends StatefulWidget {

  const ExpedienteNubeScreen({super.key, this.idInicial, this.matriculaInicial});  final String? idInicial;

  final String? matriculaInicial;

  @override  const ExpedienteNubeScreen({super.key, this.idInicial, this.matriculaInicial});

  State<ExpedienteNubeScreen> createState() => _ExpedienteNubeScreenState();

}  @override

  State<ExpedienteNubeScreen> createState() => _ExpedienteNubeScreenState();

class _ExpedienteNubeScreenState extends State<ExpedienteNubeScreen> {}

  final _idCtrl = TextEditingController();

  final _matCtrl = TextEditingController();class _ExpedienteNubeScreenState extends State<ExpedienteNubeScreen> {

  final _idCtrl = TextEditingController();

  Map<String, dynamic>? _carnet;  final _matCtrl = TextEditingController();

  List<Map<String, dynamic>> _notas = [];

  List<Map<String, dynamic>> _citas = [];  Map<String, dynamic>? _carnet;

  bool _loadingCarnet = false;  List<Map<String, dynamic>> _notas = [];

  bool _loadingNotas = false;  List<Map<String, dynamic>> _citas = [];

  bool _loadingCitas = false;  bool _loadingCarnet = false;

  String? _errCarnet;  bool _loadingNotas = false;

  String? _errNotas;  bool _loadingCitas = false;

  String? _errCitas;  String? _errCarnet;

  String? _errNotas;

  @override  String? _errCitas;

  void initState() {

    super.initState();  @override

    if (widget.idInicial != null) _idCtrl.text = widget.idInicial!;  void initState() {

    if (widget.matriculaInicial != null) _matCtrl.text = widget.matriculaInicial!;    super.initState();

  }    if (widget.idInicial != null) _idCtrl.text = widget.idInicial!;

    if (widget.matriculaInicial != null) _matCtrl.text = widget.matriculaInicial!;

  @override  }

  void dispose() {

    _idCtrl.dispose();  @override

    _matCtrl.dispose();  void dispose() {

    super.dispose();    _idCtrl.dispose();

  }    _matCtrl.dispose();

    super.dispose();

  Future<void> _buscarCarnet() async {  }

    final id = _idCtrl.text.trim();

    if (id.isEmpty) {  Future<void> _buscar() async {

      ScaffoldMessenger.of(context).showSnackBar(    final m = _mat.text.trim();

        const SnackBar(content: Text('Escribe el ID (QR) para buscar el carnet.')),    if (m.isEmpty) {

      );      setState(() {

      return;        _patient = null;

    }        _notes = [];

    setState(() { _loadingCarnet = true; _errCarnet = null; _carnet = null; });        _error = 'Escribe una matrícula para buscar.';

    try {      });

      final doc = await ApiService.getExpedienteById(id);      return;

      if (doc == null) {    }

        setState(() => _errCarnet = 'No se encontró carnet con ese ID.');

      } else {    setState(() {

        setState(() => _carnet = doc);      _loading = true;

      }      _error = null;

    } catch (e) {    });

      setState(() => _errCarnet = 'Error: $e');

    } finally {    try {

      setState(() => _loadingCarnet = false);      final p = await _api.fetchLatestPatient(m);

    }      final n = await _api.fetchNotes(m);

  }      if (!mounted) return;

      setState(() {

  Future<void> _buscarPorMatricula() async {        _patient = p;

    final matricula = _matCtrl.text.trim();        _notes = n;

    if (matricula.isEmpty) {      });

      ScaffoldMessenger.of(context).showSnackBar(    } catch (e) {

        const SnackBar(content: Text('Escribe la matrícula para buscar.')),      if (!mounted) return;

      );      setState(() => _error = '$e');

      return;    } finally {

    }      if (!mounted) return;

    setState(() { _loadingCarnet = true; _errCarnet = null; _carnet = null; });      setState(() => _loading = false);

    try {    }

      final doc = await ApiService.getExpedienteByMatricula(matricula);  }

      if (doc == null) {

        setState(() => _errCarnet = 'No se encontró carnet con esa matrícula.');  // Helper visual para pares llave:valor

      } else {  Widget _kv(String k, dynamic v) {

        setState(() => _carnet = doc);    final String val = (v == null || (v is String && v.trim().isEmpty)) ? '—' : '$v';

        await _buscarNotas();    return Padding(

        await _buscarCitas();      padding: const EdgeInsets.symmetric(vertical: 3),

      }      child: Row(

    } catch (e) {        crossAxisAlignment: CrossAxisAlignment.start,

      setState(() => _errCarnet = 'Error: $e');        children: [

    } finally {          SizedBox(

      setState(() => _loadingCarnet = false);            width: 200,

    }            child: Text(k, style: TextStyle(color: Colors.black.withOpacity(.6))),

  }          ),

          const SizedBox(width: 8),

  Future<void> _buscarNotas() async {          Expanded(child: Text(val)),

    final matricula = _carnet?['matricula']?.toString() ?? _matCtrl.text.trim();        ],

    if (matricula.isEmpty) return;      ),

        );

    setState(() { _loadingNotas = true; _errNotas = null; });  }

    try {

      final notas = await ApiService.getNotasByMatricula(matricula);  @override

      setState(() => _notas = notas);  Widget build(BuildContext context) {

    } catch (e) {    final cs = Theme.of(context).colorScheme;

      setState(() => _errNotas = 'Error: $e');

    } finally {    return Scaffold(

      setState(() => _loadingNotas = false);      appBar: uagroAppBar('CRES Carnets', 'Expediente desde la nube'),

    }      body: SingleChildScrollView(

  }        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),

        child: Column(

  Future<void> _buscarCitas() async {          crossAxisAlignment: CrossAxisAlignment.stretch,

    final matricula = _carnet?['matricula']?.toString() ?? _matCtrl.text.trim();          children: [

    if (matricula.isEmpty) return;            const BrandHeader(

                  title: 'CRES Carnets',

    setState(() { _loadingCitas = true; _errCitas = null; });              subtitle: 'Expediente de salud universitario',

    try {            ),

      final citas = await ApiService.getCitasForMatricula(matricula);            const SizedBox(height: 16),

      setState(() => _citas = citas);

    } catch (e) {            // ===== Búsqueda =====

      setState(() => _errCitas = 'Error: $e');            SectionCard(

    } finally {              icon: Icons.search,

      setState(() => _loadingCitas = false);              title: 'Buscar por matrícula',

    }              child: Column(

  }                children: [

                  Row(

  Widget _infoRow(String label, String value) {                    children: [

    return Padding(                      Expanded(

      padding: const EdgeInsets.symmetric(vertical: 2),                        child: TextField(

      child: Row(                          controller: _mat,

        crossAxisAlignment: CrossAxisAlignment.start,                          decoration: const InputDecoration(

        children: [                            labelText: 'Matrícula',

          SizedBox(                            // sin OutlineInputBorder para usar el tema UAGro

            width: 140,                          ),

            child: Text(                          onSubmitted: (_) => _buscar(),

              '$label:',                        ),

              style: const TextStyle(fontWeight: FontWeight.w500),                      ),

            ),                      const SizedBox(width: 8),

          ),                      FilledButton.icon(

          Expanded(                        onPressed: _loading ? null : _buscar,

            child: Text(value.isEmpty ? '-' : value),                        icon: const Icon(Icons.search),

          ),                        label: const Text('Buscar'),

        ],                      ),

      ),                    ],

    );                  ),

  }                  if (_loading) ...[

                    const SizedBox(height: 12),

  Widget _buildCarnet() {                    const LinearProgressIndicator(),

    if (_loadingCarnet) {                  ],

      return const SectionCard(                  if (_error != null) ...[

        icon: Icons.card_membership,                    const SizedBox(height: 8),

        title: 'Carnet Universitario',                    Text(_error!, style: TextStyle(color: cs.error)),

        child: Center(child: CircularProgressIndicator()),                  ],

      );                ],

    }              ),

    if (_errCarnet != null) {            ),

      return SectionCard(

        icon: Icons.card_membership,            const SizedBox(height: 12),

        title: 'Carnet Universitario',

        child: Text(_errCarnet!, style: TextStyle(color: UAGroColors.error)),            // ===== Paciente (NUBE) =====

      );            SectionCard(

    }              icon: Icons.cloud_outlined,

    if (_carnet == null) return const SizedBox.shrink();              title: 'Carnet (último) — NUBE',

              child: (_patient == null)

    final id = (_carnet!['_id'] ?? _carnet!['id'] ?? '').toString();                  ? Text(

    final matricula = (_carnet!['matricula'] ?? '').toString();                      'No se encontró carnet para esta matrícula en la nube.',

    final nombre = (_carnet!['nombre'] ?? _carnet!['nombreCompleto'] ?? '').toString();                      style: TextStyle(color: cs.onSurface.withOpacity(.75)),

                    )

    return SectionCard(                  : Column(

      icon: Icons.card_membership,                      crossAxisAlignment: CrossAxisAlignment.stretch,

      title: 'Carnet Universitario',                      children: [

      child: Column(                        // Resumen arriba con estado y etiqueta de sangre si existe

        crossAxisAlignment: CrossAxisAlignment.start,                         Row(

        children: [                          children: [

          _infoRow('ID', id),                            CircleAvatar(

          const SizedBox(height: 8),                              radius: 22,

          _infoRow('Matrícula', matricula),                              backgroundColor: cs.primary.withOpacity(.10),

          const SizedBox(height: 8),                              child: const Icon(Icons.badge_outlined),

          _infoRow('Nombre', nombre),                            ),

          const SizedBox(height: 8),                            const SizedBox(width: 12),

          _infoRow('Correo', (_carnet!['correo'] ?? '').toString()),                            Expanded(

          _infoRow('Edad', (_carnet!['edad'] ?? '').toString()),                              child: Column(

          _infoRow('Sexo', (_carnet!['sexo'] ?? '').toString()),                                crossAxisAlignment: CrossAxisAlignment.start,

          _infoRow('Categoría', (_carnet!['categoria'] ?? '').toString()),                                children: [

          _infoRow('Programa', (_carnet!['programa'] ?? '').toString()),                                  Text(

          _infoRow('Tipo de sangre', (_carnet!['tipoSangre'] ?? '').toString()),                                    (_patient!['nombreCompleto'] ?? '—').toString(),

          _infoRow('Alergias', (_carnet!['alergias'] ?? '').toString()),                                    style: const TextStyle(

        ],                                        fontSize: 18, fontWeight: FontWeight.bold),

      ),                                  ),

    );                                  const SizedBox(height: 2),

  }                                  Text(

                                    'Matrícula: ${_patient!['matricula'] ?? '—'} · ${_patient!['programa'] ?? '—'}',

  Widget _buildNotas() {                                    style: TextStyle(color: cs.onSurface.withOpacity(.7)),

    if (_loadingNotas) {                                  ),

      return const SectionCard(                                ],

        icon: Icons.notes,                              ),

        title: 'Notas Médicas',                            ),

        child: Center(child: CircularProgressIndicator()),                            if ((_patient!['tipoSangre'] ?? '').toString().isNotEmpty)

      );                              Container(

    }                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

    if (_errNotas != null) {                                decoration: BoxDecoration(

      return SectionCard(                                  borderRadius: BorderRadius.circular(999),

        icon: Icons.notes,                                  color: cs.primary.withOpacity(.08),

        title: 'Notas Médicas',                                  border: Border.all(color: cs.primary.withOpacity(.22)),

        child: Text(_errNotas!, style: TextStyle(color: UAGroColors.error)),                                ),

      );                                child: Text(

    }                                  _patient!['tipoSangre'].toString(),

                                      style: TextStyle(

    return SectionCard(                                    fontSize: 12,

      icon: Icons.notes,                                    fontWeight: FontWeight.w700,

      title: 'Notas Médicas (${_notas.length})',                                    color: cs.primary,

      child: _notas.isEmpty                                  ),

        ? const Text('No hay notas disponibles')                                ),

        : ListView.separated(                              ),

            shrinkWrap: true,                          ],

            physics: const NeverScrollableScrollPhysics(),                        ),

            itemCount: _notas.length,                        const SizedBox(height: 12),

            separatorBuilder: (_, __) => const Divider(),                        _kv('Correo', _patient!['correo']),

            itemBuilder: (_, index) {                        _kv('Edad', _patient!['edad']),

              final nota = _notas[index];                        _kv('Sexo', _patient!['sexo']),

              return ListTile(                        _kv('Programa', _patient!['programa']),

                leading: const Icon(Icons.note),                        _kv('Categoría', _patient!['categoria']),

                title: Text(nota['departamento'] ?? 'Sin departamento'),                        _kv('Alergias', _patient!['alergias']),

                subtitle: Text(nota['cuerpo'] ?? 'Sin contenido'),                        _kv('Tipo de sangre', _patient!['tipoSangre']),

                trailing: Text(                        _kv('Enfermedad', _patient!['enfermedadCronica']),

                  nota['createdAt'] ?? '',                        _kv('Discapacidad', _patient!['discapacidad']),

                  style: Theme.of(context).textTheme.bodySmall,                        _kv('Tipo de discapacidad', _patient!['tipoDiscapacidad']),

                ),                        _kv('Unidad médica', _patient!['unidadMedica']),

              );                        _kv('Núm. de afiliación', _patient!['numeroAfiliacion']),

            },                        _kv('Uso Seguro Universitario', _patient!['usoSeguroUniversitario']),

          ),                        _kv('Donante', _patient!['donante']),

    );                        _kv('Teléfono de emergencia', _patient!['emergenciaTelefono']),

  }                        _kv('Contacto de emergencia', _patient!['emergenciaContacto']),

                        const SizedBox(height: 6),

  Widget _buildCitas() {                        _kv('Actualizado', _patient!['timestamp']),

    if (_loadingCitas) {                      ],

      return const SectionCard(                    ),

        icon: Icons.event,            ),

        title: 'Citas',

        child: Center(child: CircularProgressIndicator()),            const SizedBox(height: 12),

      );

    }            // ===== Notas (NUBE) =====

    if (_errCitas != null) {            SectionCard(

      return SectionCard(              icon: Icons.notes_outlined,

        icon: Icons.event,              title: 'Notas — NUBE',

        title: 'Citas',              child: (_notes.isEmpty)

        child: Text(_errCitas!, style: TextStyle(color: UAGroColors.error)),                  ? Text('Sin notas en la nube para esta matrícula.',

      );                      style: TextStyle(color: cs.onSurface.withOpacity(.75)))

    }                  : ListView.separated(

                          shrinkWrap: true,

    return SectionCard(                      physics: const NeverScrollableScrollPhysics(),

      icon: Icons.event,                      itemCount: _notes.length,

      title: 'Citas (${_citas.length})',                      separatorBuilder: (_, __) => const Divider(height: 1),

      child: _citas.isEmpty                      itemBuilder: (_, i) {

        ? const Text('No hay citas programadas')                        final n = _notes[i];

        : ListView.separated(                        return ListTile(

            shrinkWrap: true,                          leading: const Icon(Icons.cloud_done),

            physics: const NeverScrollableScrollPhysics(),                          title: Text(n['departamento'] ?? '-'),

            itemCount: _citas.length,                          subtitle: Text(n['cuerpo'] ?? ''),

            separatorBuilder: (_, __) => const Divider(),                          trailing: Column(

            itemBuilder: (_, index) {                            crossAxisAlignment: CrossAxisAlignment.end,

              final cita = _citas[index];                            children: [

              return ListTile(                              Text(n['tratante'] ?? '', style: const TextStyle(fontSize: 12)),

                leading: const Icon(Icons.event),                              Text(n['createdAt'] ?? '',

                title: Text(cita['motivo'] ?? 'Sin motivo'),                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),

                subtitle: Text(cita['fecha'] ?? 'Sin fecha'),                            ],

                trailing: Text(                          ),

                  cita['estado'] ?? 'Programada',                        );

                  style: TextStyle(                      },

                    color: (cita['estado'] ?? '').toString().toLowerCase().contains('cancelada')                     ),

                      ? Colors.red             ),

                      : Colors.green,          ],

                    fontWeight: FontWeight.bold,        ),

                  ),      ),

                ),    );

              );  }

            },}

          ),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expediente en la Nube'),
        backgroundColor: UAGroColors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                icon: Icons.qr_code_scanner,
                title: 'Buscar por ID (QR)',
                child: Column(
                  children: [
                    TextField(
                      controller: _idCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID (QR)', 
                        border: OutlineInputBorder()
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _buscarCarnet,
                        child: const Text('Buscar Carnet por ID'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildCarnet(),
              const SizedBox(height: 16),
              
              SectionCard(
                icon: Icons.search,
                title: 'Buscar por Matrícula',
                child: Column(
                  children: [
                    TextField(
                      controller: _matCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Matrícula', 
                        border: OutlineInputBorder()
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _buscarPorMatricula,
                        child: const Text('Buscar'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildNotas(),
              const SizedBox(height: 16),
              
              _buildCitas(),
            ],
          ),
        ),
      ),
    );
  }
}