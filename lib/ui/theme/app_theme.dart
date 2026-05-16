import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF00D4FF);
  static const backgroundColor = Color(0xFF0A0A0F);
  static const surfaceColor = Color(0xFF141420);
  static const onSurfaceColor = Color(0xFFE0E0E0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        secondary: primaryColor.withOpacity(0.8),
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        bodyLarge: GoogleFonts.spaceGrotesk(color: onSurfaceColor),
        bodyMedium: GoogleFonts.spaceGrotesk(color: onSurfaceColor),
        labelLarge: GoogleFonts.spaceMono(color: primaryColor, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static TextStyle get monoStyle => GoogleFonts.spaceMono();
}
