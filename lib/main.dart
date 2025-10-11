// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'data/db.dart' as DB;
import 'data/auth_service.dart';
import 'services/version_service.dart';
// Tema institucional UAGro
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar información de versión
  await VersionService().loadVersion();
  
  // Diagnóstico de API_BASE_URL solo en debug
  if (kDebugMode) {
    const String apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://fastapi-backend-o7ks.onrender.com');
    print('API_BASE_URL=' + apiBase);
  }
  
  final db = DB.AppDatabase(); // Instancia de la base local (Drift)
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final DB.AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CENTRO REGIONAL DE EDUCACION SUPERIOR LLANO LARGO',
      debugShowCheckedModeBanner: false,
      // Aplicamos el tema institucional UAGro
      theme: AppTheme.light,

      // 🔐 DOBLE AUTENTICACIÓN:
      // 1. Primero verificamos login con backend (LoginScreen o Dashboard)
      // 2. Luego AuthGate aplica PIN local de seguridad
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          // Mostrando splash mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Si tiene sesión activa, ir directamente al Dashboard
          // NOTA: AuthGate (PIN) deshabilitado temporalmente para pruebas de FASE 10
          if (snapshot.data == true) {
            return DashboardScreen(db: db);
            // TODO: Restaurar AuthGate después de pruebas
            // return AuthGate(
            //   autoLock: const Duration(minutes: 10),
            //   child: DashboardScreen(db: db),
            // );
          }

          // Si no tiene sesión, mostrar LoginScreen
          return LoginScreen(db: db);
        },
      ),
    );
  }
}


