import 'package:flutter/material.dart';

class UAGroColors {
  static const Color azulMarino = Color(0xFF0F2A5A);
  static const Color rojoEscudo = Color(0xFFB1262B);
  static const Color grisClaro = Color(0xFFF2F4F7);
}

ThemeData buildUAGroTheme() {
  const primary = UAGroColors.azulMarino;
  const secondary = UAGroColors.rojoEscudo;

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    secondary: secondary,
    surface: Colors.white,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // En 3.35 usa esta propiedad (no 'background')
    scaffoldBackgroundColor: UAGroColors.grisClaro,

    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.2),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(height: 1.25),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // Puedes dejar withOpacity por ahora (es solo warning), o luego cambiar a withValues(alpha: .04)
      fillColor: scheme.primary.withOpacity(.04),
      labelStyle: TextStyle(color: scheme.primary.withOpacity(.9)),
      hintStyle: TextStyle(color: scheme.onSurface.withOpacity(.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary.withOpacity(.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary.withOpacity(.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        side: BorderSide(color: scheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    // 👇 En Flutter 3.35 debe ser CardThemeData
    cardTheme: CardThemeData(
      elevation: 1.5,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    dividerTheme: DividerThemeData(
      color: scheme.primary.withOpacity(.12),
      thickness: 1,
    ),
  );
}
