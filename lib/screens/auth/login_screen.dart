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
  
  String _selectedCampus = 'llano-largo';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Colores institucionales UAGro
  static const Color _azulMarino = Color(0xFF003D7A);
  static const Color _rojo = Color(0xFFC8102E);
  static const Color _dorado = Color(0xFFFFB81C);
  static const Color _verde = Color(0xFF00843D);

  final List<Map<String, String>> _campusList = [
    {'value': 'llano-largo', 'label': 'Llano Largo'},
    {'value': 'acapulco', 'label': 'Acapulco'},
    {'value': 'chilpancingo', 'label': 'Chilpancingo'},
    {'value': 'taxco', 'label': 'Taxco'},
    {'value': 'iguala', 'label': 'Iguala'},
    {'value': 'zihuatanejo', 'label': 'Zihuatanejo'},
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
