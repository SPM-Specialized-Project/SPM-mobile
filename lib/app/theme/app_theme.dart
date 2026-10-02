import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF0329E9);
  static const Color canvasColor = Color(0xFFF5F7FC);
  static const Color _fieldColor = Color(0xFFF8F9FD);
  static const Color _outlineColor = Color(0xFFE2E7F0);
  static const BorderRadius _fieldRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvasColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
    ).copyWith(primary: primaryColor),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _fieldColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: BorderSide(color: _outlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: BorderSide(color: _outlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
