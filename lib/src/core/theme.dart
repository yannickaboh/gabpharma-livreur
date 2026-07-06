import 'package:flutter/material.dart';

abstract final class GabColors {
  static const primary = Color(0xFF006A35);
  static const secondary = Color(0xFF206B3D);
  static const background = Color(0xFFEDFDF4);
  static const softGreen = Color(0xFFE7F7EE);
  static const ink = Color(0xFF111E19);
  static const muted = Color(0xFF3F4940);
  static const routeBlue = Color(0xFF1769AA);
  static const warning = Color(0xFF9A6700);
  static const danger = Color(0xFFBA1A1A);
}

ThemeData buildCourierTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: GabColors.primary,
    surface: Colors.white,
    error: GabColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GabColors.background,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: GabColors.background,
      foregroundColor: GabColors.ink,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
