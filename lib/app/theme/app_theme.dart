import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF0329E9);
  static const Color canvasColor = Color(0xFFF4F6F7);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _fieldColor = Color(0xFFF8FAFB);
  static const Color _outlineColor = Color(0xFFDCE3E6);
  static const Color _secondaryColor = Color(0xFF24665F);
  static const Color _secondaryContainer = Color(0xFFDDEFEA);
  static const BorderRadius _fieldRadius = BorderRadius.all(
    Radius.circular(12),
  );
  static const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(16));

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvasColor,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor).copyWith(
      primary: primaryColor,
      onPrimary: _surfaceColor,
      primaryContainer: const Color(0xFFE8ECFF),
      onPrimaryContainer: const Color(0xFF172A72),
      secondary: _secondaryColor,
      onSecondary: _surfaceColor,
      secondaryContainer: _secondaryContainer,
      onSecondaryContainer: const Color(0xFF153D38),
      surface: _surfaceColor,
      outline: const Color(0xFF718087),
      outlineVariant: _outlineColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvasColor,
      foregroundColor: Color(0xFF192A30),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF192A30),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(4),
      shape: const RoundedRectangleBorder(
        borderRadius: _cardRadius,
        side: BorderSide(color: _outlineColor),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _outlineColor,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      indicatorColor: _secondaryContainer,
      elevation: 0,
      shadowColor: Colors.transparent,
      height: 72,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _fieldColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: _secondaryColor,
        side: const BorderSide(color: _outlineColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: primaryColor,
      selectionColor: Color(0x332469FF),
      selectionHandleColor: primaryColor,
    ),
  );
}
