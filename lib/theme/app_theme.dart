import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary Colors - Modern Indigo
  static const Color primaryColor = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo 600
  
  // Secondary Colors - Modern Teal
  static const Color secondaryColor = Color(0xFF14B8A6); // Teal 500
  static const Color secondaryLight = Color(0xFF2DD4BF); // Teal 400
  static const Color secondaryDark = Color(0xFF0D9488); // Teal 600
  
  // Accent Colors
  static const Color accentColor = Color(0xFFF43F5E); // Rose 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color successColor = Color(0xFF10B981); // Emerald 500
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  
  // Neutral Colors - Modern Slate
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E293B); // Slate 800
  static const Color onSurfaceLight = Color(0xFF64748B); // Slate 500
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  
  // Category Colors (Modern Pastel)
  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFFB7185), // Rose
    'transport': Color(0xFF60A5FA), // Blue
    'shopping': Color(0xFFA78BFA), // Violet
    'entertainment': Color(0xFFF472B6), // Pink
    'bills': Color(0xFF34D399), // Emerald
    'health': Color(0xFFFB923C), // Orange
    'education': Color(0xFF818CF8), // Indigo
    'travel': Color(0xFF22D3EE), // Cyan
    'groceries': Color(0xFFA3E635), // Lime
    'others': Color(0xFF94A3B8), // Slate
  };

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        background: background,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
        onBackground: onSurface,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: background, // Match scaffold for cleaner look
        foregroundColor: onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
          fontFamily: 'Poppins',
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Increased radius
          side: BorderSide(color: Colors.transparent), // No border by default
        ),
        color: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.all(20),
        hintStyle: const TextStyle(
          fontSize: 15,
          color: onSurfaceLight,
          fontFamily: 'Poppins',
        ),
        labelStyle: const TextStyle(
          color: onSurfaceLight,
          fontFamily: 'Poppins',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceLight,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: onSurface,
          fontFamily: 'Poppins',
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: onSurface,
          fontFamily: 'Poppins',
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
          fontFamily: 'Poppins',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontFamily: 'Poppins',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: onSurface,
          fontFamily: 'Poppins',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: onSurface,
          fontFamily: 'Poppins',
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: onSurfaceLight,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // Dark Theme
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Darker neutral background
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: secondaryColor,
        surface: Color(0xFF2C2C2C), // Dark surface
        background: Color(0xFF1E1E1E),
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE0E0E0), // Light grey text
        onBackground: Color(0xFFE0E0E0),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF2C2C2C),
        foregroundColor: Color(0xFFE0E0E0),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
          fontFamily: 'Poppins',
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        color: const Color(0xFF2C2C2C),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF383838), // Slightly lighter than surface
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryLight.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
          fontFamily: 'Poppins',
        ),
        prefixIconColor: Colors.grey[400],
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        selectedItemColor: primaryLight,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        displayMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        displaySmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        headlineLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        headlineMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        headlineSmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        titleLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        titleMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        titleSmall: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        bodyLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        bodyMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        bodySmall: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        labelLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE0E0E0)),
        labelMedium: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        labelSmall: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
      ),
    );
  }

  // Get color for category
  static Color getCategoryColor(String category) {
    return categoryColors[category.toLowerCase()] ?? categoryColors['others']!;
  }
}
