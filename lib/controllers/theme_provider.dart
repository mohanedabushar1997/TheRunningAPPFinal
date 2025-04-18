import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Define Colors (Task 4.1.2)
class AppColors {
  static const Color primary = Color(0xFFFF3366); // Vibrant Pink
  static const Color secondary = Color(0xFF33CC99); // Mint Green
  static const Color accent = Color(0xFFFFCC00); // Bright Yellow

  // Light Theme Specific
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightTextDark = Color(0xFF333333);
  static const Color lightTextMedium = Color(0xFF999999);
  static const Color lightError = Colors.red; // Standard error color

  // Dark Theme Specific
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextLight = Color(0xFFE0E0E0);
  static const Color darkTextMedium = Color(0xFFB0B0B0);
  static const Color darkError = Colors.redAccent; // Standard error color
}

class ThemeProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadThemeMode() async {
    await _initPrefs();
    String? savedTheme = _prefs?.getString('themeMode');
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _initPrefs();
    _themeMode = mode;
    String themeString;
    if (mode == ThemeMode.light) {
      themeString = 'light';
    } else if (mode == ThemeMode.dark) {
      themeString = 'dark';
    } else {
      themeString = 'system';
    }
    await _prefs?.setString('themeMode', themeString);
    notifyListeners();
  }

  // Define ThemeData objects (Task 4.1.3, 4.1.4)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    hintColor: AppColors.accent, // Often used for accent elements
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightSurface,
    dividerColor: Colors.grey[300],
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      onPrimary: Colors.white, // Text on primary color
      onSecondary: Colors.black, // Text on secondary color
      onTertiary: Colors.black, // Text on accent color
      onBackground: AppColors.lightTextDark,
      onSurface: AppColors.lightTextDark,
      error: AppColors.lightError,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      color: AppColors.primary,
      foregroundColor: Colors.white, // Title/icon color
      elevation: 1.0,
    ),
    // Define proper typography (Task 4.1.5)
    textTheme: TextTheme(
      // Display styles for large headers
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.lightTextDark,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.lightTextDark,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextDark,
        letterSpacing: -0.25,
      ),
      
      // Headline styles for section headers
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextDark,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextDark,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextDark,
      ),
      
      // Title styles for UI components
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextDark,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextDark,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextDark,
      ),
      
      // Body styles for main content
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.lightTextDark,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.lightTextDark,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.lightTextMedium,
      ),
      
      // Label styles for buttons and inputs
      labelLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white, // For buttons
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextDark,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextMedium,
        letterSpacing: 0.5,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    hintColor: AppColors.accent,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkSurface,
    dividerColor: Colors.grey[700],
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onBackground: AppColors.darkTextLight,
      onSurface: AppColors.darkTextLight,
      error: AppColors.darkError,
      onError: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      color: AppColors.darkSurface, // Darker app bar
      foregroundColor: AppColors.darkTextLight, // Title/icon color
      elevation: 1.0,
    ),
    // Define proper typography (Task 4.1.5)
    textTheme: TextTheme(
      // Display styles for large headers
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkTextLight,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkTextLight,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextLight,
        letterSpacing: -0.25,
      ),
      
      // Headline styles for section headers
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextLight,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextLight,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextLight,
      ),
      
      // Title styles for UI components
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextLight,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextLight,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextLight,
      ),
      
      // Body styles for main content
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.darkTextLight,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.darkTextLight,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.darkTextMedium,
      ),
      
      // Label styles for buttons and inputs
      labelLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black, // For buttons
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextLight,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextMedium,
        letterSpacing: 0.5,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}
