// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'screens/form_screen.dart';
import 'data/db.dart' as DB;
// Tema institucional UAGro
import 'ui/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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

      // 🔐 ENVOLVEMOS LA APP CON AuthGate (pide la clave corporativa)
      // NO CAMBIAR LÓGICA: mantener callbacks/estados intactos
      home: AuthGate(
        autoLock: const Duration(minutes: 10),
        child: Scaffold(
          appBar: AppBar(title: const Text('CENTRO REGIONAL DE EDUCACION SUPERIOR LLANO LARGO')),
          // 👇 Ajusta esta pantalla si tu inicio es otro (ListScreen, etc.)
          body: FormScreen(db: db),
        ),
      ),
    );
  }
}


