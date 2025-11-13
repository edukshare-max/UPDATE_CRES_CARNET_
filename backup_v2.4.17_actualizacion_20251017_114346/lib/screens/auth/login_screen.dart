// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../dashboard_screen.dart';
import '../../data/auth_service.dart';
import '../../data/db.dart' as DB;

class LoginScreen extends StatefulWidget {
  final DB.AppDatabase db;
  
  const LoginScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedCampus = 'cres-llano-largo'; // Actualizado al nuevo formato
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Colores institucionales UAGro
  static const Color _azulMarino = Color(0xFF003D7A);
  static const Color _rojo = Color(0xFFC8102E);
  static const Color _dorado = Color(0xFFFFB81C);
  static const Color _verde = Color(0xFF00843D);

  // 88 Instituciones UAGro - Sincronizado con backend
  final List<Map<String, String>> _campusList = [
    // CRES - Centros Regionales de Educación Superior (6)
    {'value': 'cres-cruz-grande', 'label': 'CRES Cruz Grande'},
    {'value': 'cres-zumpango', 'label': 'CRES Zumpango del Río'},
    {'value': 'cres-taxco-viejo', 'label': 'CRES Taxco el Viejo'},
    {'value': 'cres-huamuxtitlan', 'label': 'CRES Huamuxtitlán'},
    {'value': 'cres-llano-largo', 'label': 'CRES Llano Largo'},
    {'value': 'cres-tecpan', 'label': 'CRES Tecpan de Galeana'},
    
    // Clínicas Universitarias (4)
    {'value': 'clinica-chilpancingo', 'label': 'Clínica Universitaria Chilpancingo'},
    {'value': 'clinica-acapulco', 'label': 'Clínica Universitaria Acapulco'},
    {'value': 'clinica-iguala', 'label': 'Clínica Universitaria Iguala'},
    {'value': 'clinica-ometepec', 'label': 'Clínica Universitaria Ometepec'},
    
    // Facultades (20)
    {'value': 'fac-gobierno', 'label': 'Facultad de Ciencias Políticas y Gobierno'},
    {'value': 'fac-arquitectura', 'label': 'Facultad de Arquitectura y Urbanismo'},
    {'value': 'fac-quimico', 'label': 'Facultad de Ciencias Químico Biológicas'},
    {'value': 'fac-comunicacion', 'label': 'Facultad de Ciencias de la Comunicación'},
    {'value': 'fac-derecho-chil', 'label': 'Facultad de Derecho (Chilpancingo)'},
    {'value': 'fac-filosofia', 'label': 'Facultad de Filosofía y Letras'},
    {'value': 'fac-ingenieria', 'label': 'Facultad de Ingeniería'},
    {'value': 'fac-matematicas-centro', 'label': 'Facultad de Matemáticas (Centro)'},
    {'value': 'fac-contaduria', 'label': 'Facultad de Contaduría y Administración'},
    {'value': 'fac-derecho-aca', 'label': 'Facultad de Derecho (Acapulco)'},
    {'value': 'fac-ecologia', 'label': 'Facultad de Ecología Marina'},
    {'value': 'fac-economia', 'label': 'Facultad de Economía'},
    {'value': 'fac-enfermeria2', 'label': 'Facultad de Enfermería 2'},
    {'value': 'fac-matematicas-sur', 'label': 'Facultad de Matemáticas (Sur)'},
    {'value': 'fac-lenguas', 'label': 'Facultad de Lenguas Extranjeras'},
    {'value': 'fac-medicina', 'label': 'Facultad de Medicina'},
    {'value': 'fac-odontologia', 'label': 'Facultad de Odontología'},
    {'value': 'fac-turismo', 'label': 'Facultad de Turismo'},
    {'value': 'fac-agropecuarias', 'label': 'Facultad de Ciencias Agropecuarias'},
    {'value': 'fac-matematicas-norte', 'label': 'Facultad de Matemáticas (Norte)'},
    
    // Preparatorias (50)
    {'value': 'prep-1', 'label': 'Preparatoria 1'},
    {'value': 'prep-2', 'label': 'Preparatoria 2'},
    {'value': 'prep-3', 'label': 'Preparatoria 3'},
    {'value': 'prep-4', 'label': 'Preparatoria 4'},
    {'value': 'prep-5', 'label': 'Preparatoria 5'},
    {'value': 'prep-6', 'label': 'Preparatoria 6'},
    {'value': 'prep-7', 'label': 'Preparatoria 7'},
    {'value': 'prep-8', 'label': 'Preparatoria 8'},
    {'value': 'prep-9', 'label': 'Preparatoria 9'},
    {'value': 'prep-10', 'label': 'Preparatoria 10'},
    {'value': 'prep-11', 'label': 'Preparatoria 11'},
    {'value': 'prep-12', 'label': 'Preparatoria 12'},
    {'value': 'prep-13', 'label': 'Preparatoria 13'},
    {'value': 'prep-14', 'label': 'Preparatoria 14'},
    {'value': 'prep-15', 'label': 'Preparatoria 15'},
    {'value': 'prep-16', 'label': 'Preparatoria 16'},
    {'value': 'prep-17', 'label': 'Preparatoria 17'},
    {'value': 'prep-18', 'label': 'Preparatoria 18'},
    {'value': 'prep-19', 'label': 'Preparatoria 19'},
    {'value': 'prep-20', 'label': 'Preparatoria 20'},
    {'value': 'prep-21', 'label': 'Preparatoria 21'},
    {'value': 'prep-22', 'label': 'Preparatoria 22'},
    {'value': 'prep-23', 'label': 'Preparatoria 23'},
    {'value': 'prep-24', 'label': 'Preparatoria 24'},
    {'value': 'prep-25', 'label': 'Preparatoria 25'},
    {'value': 'prep-26', 'label': 'Preparatoria 26'},
    {'value': 'prep-27', 'label': 'Preparatoria 27'},
    {'value': 'prep-28', 'label': 'Preparatoria 28'},
    {'value': 'prep-29', 'label': 'Preparatoria 29'},
    {'value': 'prep-30', 'label': 'Preparatoria 30'},
    {'value': 'prep-31', 'label': 'Preparatoria 31'},
    {'value': 'prep-32', 'label': 'Preparatoria 32'},
    {'value': 'prep-33', 'label': 'Preparatoria 33'},
    {'value': 'prep-34', 'label': 'Preparatoria 34'},
    {'value': 'prep-35', 'label': 'Preparatoria 35'},
    {'value': 'prep-36', 'label': 'Preparatoria 36'},
    {'value': 'prep-37', 'label': 'Preparatoria 37'},
    {'value': 'prep-38', 'label': 'Preparatoria 38'},
    {'value': 'prep-39', 'label': 'Preparatoria 39'},
    {'value': 'prep-40', 'label': 'Preparatoria 40'},
    {'value': 'prep-41', 'label': 'Preparatoria 41'},
    {'value': 'prep-42', 'label': 'Preparatoria 42'},
    {'value': 'prep-43', 'label': 'Preparatoria 43'},
    {'value': 'prep-44', 'label': 'Preparatoria 44'},
    {'value': 'prep-45', 'label': 'Preparatoria 45'},
    {'value': 'prep-46', 'label': 'Preparatoria 46'},
    {'value': 'prep-47', 'label': 'Preparatoria 47'},
    {'value': 'prep-48', 'label': 'Preparatoria 48'},
    {'value': 'prep-49', 'label': 'Preparatoria 49'},
    {'value': 'prep-50', 'label': 'Preparatoria 50'},
    
    // Rectoría y Coordinaciones Regionales (8)
    {'value': 'rectoria', 'label': 'Rectoría'},
    {'value': 'coord-sur', 'label': 'Coordinación Regional Sur'},
    {'value': 'coord-centro', 'label': 'Coordinación Regional Centro'},
    {'value': 'coord-norte', 'label': 'Coordinación Regional Norte'},
    {'value': 'coord-costa-chica', 'label': 'Coordinación Regional Costa Chica'},
    {'value': 'coord-costa-grande', 'label': 'Coordinación Regional Costa Grande'},
    {'value': 'coord-montana', 'label': 'Coordinación Regional Montaña'},
    {'value': 'coord-tierra-caliente', 'label': 'Coordinación Regional Tierra Caliente'},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        campus: _selectedCampus,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Mostrar mensaje si es modo offline
        if (result['mode'] == 'offline' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Modo sin conexión: Los datos se sincronizarán cuando tengas internet'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        // Login exitoso - navegar al dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(db: widget.db),
            ),
          );
        }
      } else {
        // Login fallido - mostrar error
        setState(() {
          _errorMessage = result['error'] ?? 'Error desconocido';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _azulMarino,
              _azulMarino.withOpacity(0.8),
              _dorado.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo UAGro
                        Icon(
                          Icons.local_hospital_rounded,
                          size: 80,
                          color: _azulMarino,
                        ),
                        const SizedBox(height: 16),
                        
                        // Título
                        Text(
                          'SISTEMA DE CARNETS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _azulMarino,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'SASU - UAGro',
                          style: TextStyle(
                            fontSize: 16,
                            color: _rojo,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Campo Usuario
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person, color: _azulMarino),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _azulMarino, width: 2),
                            ),
                          ),
                          enabled: !_isLoading,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu usuario';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Contraseña
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock, color: _azulMarino),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: _azulMarino,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _azulMarino, width: 2),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          enabled: !_isLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Campus
                        DropdownButtonFormField<String>(
                          value: _selectedCampus,
                          decoration: InputDecoration(
                            labelText: 'Campus',
                            prefixIcon: Icon(Icons.school, color: _azulMarino),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _azulMarino, width: 2),
                            ),
                          ),
                          items: _campusList.map((campus) {
                            return DropdownMenuItem<String>(
                              value: campus['value'],
                              child: Text(campus['label']!),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedCampus = value!;
                                  });
                                },
                        ),
                        const SizedBox(height: 24),

                        // Mensaje de error
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _rojo.withOpacity(0.1),
                              border: Border.all(color: _rojo),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: _rojo, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: _rojo),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Botón Iniciar Sesión
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _verde,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'INICIAR SESIÓN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nota informativa
                        Text(
                          'Contacta al administrador si tienes problemas de acceso',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
