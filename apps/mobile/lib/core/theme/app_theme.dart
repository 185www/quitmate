import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF2196F3);
  static const _errorColor = Color(0xFFF44336);

  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: _primaryColor,
    secondary: Color(0xFF7C4DFF),
    error: _errorColor,
    surface: Colors.white,
    background: Color(0xFFF5F5F5),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF212121),
    onBackground: Color(0xFF212121),
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF82B1FF),
    secondary: Color(0xFFB388FF),
    error: Color(0xFFFF5252),
    surface: Color(0xFF1E1E1E),
    background: Color(0xFF121212),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
  );

  ThemeData get lightTheme => _buildTheme(_lightColorScheme, Brightness.light);
  ThemeData get darkTheme => _buildTheme(_darkColorScheme, Brightness.dark);

  ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: brightness == Brightness.dark ? colorScheme.surface : Colors.grey[100],
      ),
    );
  }
}