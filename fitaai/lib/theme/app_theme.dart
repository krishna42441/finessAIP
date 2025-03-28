import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App theme following Material 3 design guidelines
/// https://m3.material.io/
class AppTheme {
  // Primary color seed
  static const Color seedColor = Color(0xFF6750A4); // M3 Baseline Purple
  
  // Custom color scheme
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );
  
  // For backwards compatibility with existing code
  static Color get primaryColor => lightColorScheme.primary;
  static Color get primaryLight => lightColorScheme.primaryContainer;
  static Color get primaryDark => lightColorScheme.onPrimaryContainer;
  static Color get secondaryColor => lightColorScheme.secondary;
  static Color get accentColor => lightColorScheme.tertiary;
  static Color get errorColor => lightColorScheme.error;
  static Color get successColor => const Color(0xFF2E7D32); // Green
  static Color get infoColor => const Color(0xFF0288D1); // Blue
  static Color get warningColor => const Color(0xFFF57C00); // Orange
  
  // Background & surface colors
  static Color get backgroundColor => lightColorScheme.background;
  static Color get surfaceColor => lightColorScheme.surface;
  static Color get cardColor => lightColorScheme.surfaceVariant;
  static Color get darkBackgroundColor => lightColorScheme.surfaceVariant;
  
  // Text colors
  static Color get textPrimary => lightColorScheme.onBackground;
  static Color get textSecondary => lightColorScheme.onSurfaceVariant;
  static Color get textHint => lightColorScheme.outline;
  static Color get textOnPrimary => lightColorScheme.onPrimary;
  
  // Common durations for animations
  static const Duration microDuration = Duration(milliseconds: 100);
  static const Duration shortDuration = Duration(milliseconds: 250);
  static const Duration mediumDuration = Duration(milliseconds: 350);
  static const Duration longDuration = Duration(milliseconds: 500);
  
  // Common animation curves
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
  static const Curve decelerateCurve = Curves.decelerate;
  
  // Material 3 Elevation levels
  static const List<double> elevations = [0, 1, 3, 6, 8, 12];
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      brightness: Brightness.light,
      
      scaffoldBackgroundColor: lightColorScheme.background,
      
      // Card theme
      cardTheme: CardTheme(
        color: lightColorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primary.withOpacity(0.05),
        foregroundColor: lightColorScheme.onSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        centerTitle: true,
        iconTheme: IconThemeData(color: lightColorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: lightColorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: lightColorScheme.primary.withOpacity(0.05),
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: lightColorScheme.primary.withOpacity(0.05),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      
      // Text theme using M3 typography guidelines
      textTheme: TextTheme(
        // Display styles
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: lightColorScheme.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        
        // Headline styles
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        
        // Title styles
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: lightColorScheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: lightColorScheme.onSurface,
        ),
        
        // Body styles
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
          color: lightColorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: lightColorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: lightColorScheme.onSurfaceVariant,
        ),
        
        // Label styles
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: lightColorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurfaceVariant,
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // M3 uses full rounded for buttons
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          animationDuration: shortDuration,
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          animationDuration: shortDuration,
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>((states) {
            if (states.contains(MaterialState.hovered)) return 3;
            if (states.contains(MaterialState.focused)) return 2;
            if (states.contains(MaterialState.pressed)) return 4;
            return 0;
          }),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          animationDuration: shortDuration,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          side: BorderSide(color: lightColorScheme.outline, width: 1),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          animationDuration: shortDuration,
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.outline.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: lightColorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: lightColorScheme.onSurfaceVariant.withOpacity(0.6)),
        prefixIconColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.focused)) {
            return lightColorScheme.primary;
          }
          if (states.contains(MaterialState.error)) {
            return lightColorScheme.error;
          }
          return lightColorScheme.onSurfaceVariant;
        }),
        suffixIconColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.focused)) {
            return lightColorScheme.primary;
          }
          if (states.contains(MaterialState.error)) {
            return lightColorScheme.error;
          }
          return lightColorScheme.onSurfaceVariant;
        }),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightColorScheme.surfaceVariant,
        elevation: 0,
        labelStyle: TextStyle(
          color: lightColorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        // Select and filter chip settings
        selectedColor: lightColorScheme.secondaryContainer,
        showCheckmark: true,
        checkmarkColor: lightColorScheme.onSecondaryContainer,
        deleteIconColor: lightColorScheme.onSurfaceVariant,
        side: BorderSide(color: lightColorScheme.outline, width: 1),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.primaryContainer,
        foregroundColor: lightColorScheme.onPrimaryContainer,
        extendedTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: lightColorScheme.onPrimaryContainer,
        ),
        elevation: 3,
        highlightElevation: 6,
        shape: const CircleBorder(),
      ),
      
      // Bottom navigation bar and navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColorScheme.primaryContainer,
        selectedItemColor: lightColorScheme.primary,
        unselectedItemColor: lightColorScheme.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightColorScheme.primaryContainer,
        indicatorColor: lightColorScheme.secondaryContainer,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
              color: lightColorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return TextStyle(
            color: lightColorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: lightColorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: lightColorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        elevation: 8,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: lightColorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightColorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: lightColorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: lightColorScheme.primary,
        linearTrackColor: lightColorScheme.surfaceVariant,
        circularTrackColor: lightColorScheme.surfaceVariant,
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 24,
        iconColor: lightColorScheme.onSurfaceVariant,
        tileColor: lightColorScheme.surface,
        textColor: lightColorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: lightColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      
      // Tab bar theme
      tabBarTheme: TabBarTheme(
        labelColor: lightColorScheme.primary,
        unselectedLabelColor: lightColorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        indicatorColor: lightColorScheme.primary,
        dividerColor: lightColorScheme.outlineVariant,
      ),
      
      // Switch, Checkbox, Radio themes
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightColorScheme.primaryContainer;
          }
          return lightColorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightColorScheme.primary;
          }
          return lightColorScheme.surfaceVariant;
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightColorScheme.primary;
          }
          return null;
        }),
        checkColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightColorScheme.onPrimary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return lightColorScheme.primary;
          }
          return lightColorScheme.outlineVariant;
        }),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: lightColorScheme.primary,
        inactiveTrackColor: lightColorScheme.surfaceVariant,
        thumbColor: lightColorScheme.primary,
        overlayColor: lightColorScheme.primary.withOpacity(0.1),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
    );
  }
  
  // For consistency, keep darkTheme reference
  static ThemeData get darkTheme {
    // Create dark color scheme from seed
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    
    // Create a dark theme similar to the light theme
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      brightness: Brightness.dark,
      // Add all the same theme parameters as the light theme...
    );
  }
  
  // Card decoration with M3 elevation
  static BoxDecoration cardDecoration({double elevation = 0}) {
    return BoxDecoration(
      color: lightColorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: elevation > 0
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: elevation * 2,
                spreadRadius: elevation * 0.2,
                offset: Offset(0, elevation * 0.5),
              ),
            ]
          : null,
    );
  }
  
  // Gradient card decoration
  static BoxDecoration gradientCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          lightColorScheme.primary,
          lightColorScheme.tertiary,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: lightColorScheme.primary.withOpacity(0.25),
          blurRadius: 15,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  // Chip decoration
  static BoxDecoration chipDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected ? lightColorScheme.secondaryContainer : lightColorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isSelected ? Colors.transparent : lightColorScheme.outline,
        width: 1,
      ),
    );
  }
  
  // Progress indicator container
  static BoxDecoration progressBarDecoration({Color? color}) {
    return BoxDecoration(
      color: (color ?? lightColorScheme.primary).withOpacity(0.8),
      borderRadius: BorderRadius.circular(100), // M3 uses full rounded for progress bars
    );
  }
  
  // Progress bar background
  static BoxDecoration progressBarBackgroundDecoration() {
    return BoxDecoration(
      color: lightColorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(100),
    );
  }
  
  // Surface container decoration (for slight elevation)
  static BoxDecoration surfaceContainer({ColorScheme? colorScheme}) {
    final scheme = colorScheme ?? lightColorScheme;
    return BoxDecoration(
      color: scheme.surfaceVariant.withOpacity(0.35),
      borderRadius: BorderRadius.circular(16),
    );
  }
  
  // Icon container decoration
  static BoxDecoration iconContainerDecoration({required Color color}) {
    return BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    );
  }
}