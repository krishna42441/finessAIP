import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Material 3 Dark Theme Colors
  static const Color backgroundColor = Color(0xFF121212); // Dark black
  static const Color surfaceColor = Color(0xFF1E1E1E);    // Light black
  static const Color cardColor = Color(0xFF242424);       // Slightly lighter black
  static const Color darkBackgroundColor = Color(0xFF0F0F0F); // Darker black
  
  // Keep existing color references for backward compatibility
  static const Color primaryColor = Color(0xFFFF8800);    // Orange primary
  static const Color secondaryColor = Color(0xFFFFB266);  // Light Orange secondary
  static const Color textPrimary = Colors.white;          // Primary text
  static const Color textSecondary = Color(0xFFE6E1E5);   // Secondary text
  
  // Accent colors
  static const Color successColor = Color(0xFF7ACB7A);    // Success green
  static const Color errorColor = Color(0xFFF2B8B5);      // Error red
  
  // Chart colors
  static const Color chartPositiveColor = Color(0xFF4285F4); // Blue
  static const Color chartNegativeColor = Color(0xFF3F3F3F); // Dark gray for inactive elements
  
  // Surface colors for cards
  static const Color surface1 = Color(0xFF24242F);
  static const Color surface2 = Color(0xFF2C2C3B);
  static const Color surface3 = Color(0xFF333346);
  
  // Text colors
  static const Color textDisabled = Color(0xFF606060);
  
  static const Color dividerColor = Color(0xFF383842);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.black,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary),
        displayMedium: TextStyle(color: textPrimary),
        displaySmall: TextStyle(color: textPrimary),
        headlineLarge: TextStyle(color: textPrimary),
        headlineMedium: TextStyle(color: textPrimary),
        headlineSmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(color: textSecondary, fontSize: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: cardColor,
      ),
    );
  }
  
  // Common card decoration
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
    );
  }
  
  // Glassmorphism effect decoration
  static BoxDecoration glassDecoration({double opacity = 0.1}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  // Gradient background
  static BoxDecoration gradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          backgroundColor,
          backgroundColor.withOpacity(0.8),
        ],
      ),
    );
  }
} 