import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Or use DatabaseHelper if storing settings in DB (Task 2.1.10)
// import '../data/database_helper.dart';

class SettingsProvider with ChangeNotifier {
  // Using SharedPreferences for simple key-value settings (Task 1.1.17)
  SharedPreferences? _prefs;

  // Example setting: Units (metric/imperial)
  String _units = 'metric'; // Default value
  String get units => _units;

  // Example setting: Theme (light/dark/system) - See ThemeProvider
  // String _themeMode = 'system';
  // String get themeMode => _themeMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadSettings() async {
    await _initPrefs();
    _units = _prefs?.getString('units') ?? 'metric';
    // Load other settings...
    notifyListeners();
  }

  Future<void> setUnits(String newUnits) async {
    if (newUnits == 'metric' || newUnits == 'imperial') {
      await _initPrefs();
      _units = newUnits;
      await _prefs?.setString('units', newUnits);
      notifyListeners();
    }
  }

  // TODO: Add methods for other settings (audio, map preferences, etc.)
}
