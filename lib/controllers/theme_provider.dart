import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    textTheme: const TextTheme(
      // TODO: Define proper typography (Task 4.1.5)
      bodyLarge: TextStyle(color: AppColors.lightTextDark),
      bodyMedium: TextStyle(color: AppColors.lightTextDark),
      titleMedium: TextStyle(color: AppColors.lightTextDark),
      titleLarge: TextStyle(
        color: AppColors.lightTextDark,
        fontWeight: FontWeight.bold,
      ),
      labelLarge: TextStyle(color: Colors.white), // Button text
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.black,
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
    textTheme: const TextTheme(
      // TODO: Define proper typography (Task 4.1.5)
      bodyLarge: TextStyle(color: AppColors.darkTextLight),
      bodyMedium: TextStyle(color: AppColors.darkTextLight),
      titleMedium: TextStyle(color: AppColors.darkTextLight),
      titleLarge: TextStyle(
        color: AppColors.darkTextLight,
        fontWeight: FontWeight.bold,
      ),
      labelLarge: TextStyle(color: Colors.black), // Button text
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary, // Text color might need adjustment
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // Text on primary button
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.black,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}
