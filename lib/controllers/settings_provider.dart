import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';

// Define enum at the top level
enum LocationAccuracyLevel { low, medium, high, best }

class SettingsProvider with ChangeNotifier {
  // Using SharedPreferences for simple key-value settings (Task 1.1.17)
  SharedPreferences? _prefs;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Units (metric/imperial)
  String _units = 'metric'; // Default value
  String get units => _units;

  // Voice coaching settings
  bool _voiceCoachingEnabled = true;
  int _voiceCoachingFrequency = 1; // 0: minimal, 1: moderate, 2: detailed
  String _voiceCoachingVoice = 'default';
  bool get voiceCoachingEnabled => _voiceCoachingEnabled;
  int get voiceCoachingFrequency => _voiceCoachingFrequency;
  String get voiceCoachingVoice => _voiceCoachingVoice;

  // Map preferences
  String _mapType = 'standard'; // standard, satellite, terrain
  bool _showMileMarkers = true;
  bool _showElevationProfile = true;
  String get mapType => _mapType;
  bool get showMileMarkers => _showMileMarkers;
  bool get showElevationProfile => _showElevationProfile;

  // GPS settings
  LocationAccuracyLevel _gpsAccuracy = LocationAccuracyLevel.high;
  int _gpsUpdateInterval = 1000; // milliseconds
  // enum LocationAccuracyLevel { low, medium, high, best } // Moved outside class
  LocationAccuracyLevel get gpsAccuracy => _gpsAccuracy;
  int get gpsUpdateInterval => _gpsUpdateInterval;

  // Workout display settings
  List<String> _visibleMetrics = ['distance', 'duration', 'pace', 'calories'];
  bool _keepScreenOn = true;
  bool _showLiveMap = true;
  List<String> get visibleMetrics => _visibleMetrics;
  bool get keepScreenOn => _keepScreenOn;
  bool get showLiveMap => _showLiveMap;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _achievementNotifications = true;
  bool _workoutReminders = false;
  String _reminderTime = '18:00';
  List<bool> _reminderDays = [
    false,
    true,
    true,
    true,
    true,
    true,
    false,
  ]; // Sun-Sat
  bool get notificationsEnabled => _notificationsEnabled;
  bool get achievementNotifications => _achievementNotifications;
  bool get workoutReminders => _workoutReminders;
  String get reminderTime => _reminderTime;
  List<bool> get reminderDays => _reminderDays;

  // Onboarding status
  bool _isOnboardingComplete = false;
  bool get isOnboardingComplete => _isOnboardingComplete;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadSettings() async {
    await _initPrefs();

    // Load from SharedPreferences for quick access settings
    _units = _prefs?.getString('units') ?? 'metric';
    _voiceCoachingEnabled = _prefs?.getBool('voice_coaching_enabled') ?? true;
    _voiceCoachingFrequency = _prefs?.getInt('voice_coaching_frequency') ?? 1;
    _voiceCoachingVoice =
        _prefs?.getString('voice_coaching_voice') ?? 'default';
    _mapType = _prefs?.getString('map_type') ?? 'standard';
    _showMileMarkers = _prefs?.getBool('show_mile_markers') ?? true;
    _showElevationProfile = _prefs?.getBool('show_elevation_profile') ?? true;
    _gpsAccuracy =
        LocationAccuracyLevel.values[_prefs?.getInt('gps_accuracy') ??
            LocationAccuracyLevel.high.index]; // Use index
    _gpsUpdateInterval = _prefs?.getInt('gps_update_interval') ?? 1000;
    _keepScreenOn = _prefs?.getBool('keep_screen_on') ?? true;
    _showLiveMap = _prefs?.getBool('show_live_map') ?? true;
    _notificationsEnabled = _prefs?.getBool('notifications_enabled') ?? true;
    _achievementNotifications =
        _prefs?.getBool('achievement_notifications') ?? true;
    _workoutReminders = _prefs?.getBool('workout_reminders') ?? false;
    _reminderTime = _prefs?.getString('reminder_time') ?? '18:00';

    // Load visible metrics
    final visibleMetricsList = _prefs?.getStringList('visible_metrics');
    if (visibleMetricsList != null && visibleMetricsList.isNotEmpty) {
      _visibleMetrics = visibleMetricsList;
    }

    // Load reminder days
    final reminderDaysList = _prefs?.getStringList('reminder_days');
    if (reminderDaysList != null && reminderDaysList.length == 7) {
      _reminderDays = reminderDaysList.map((day) => day == 'true').toList();
    }

    // Load onboarding status
    _isOnboardingComplete = _prefs?.getBool('onboarding_complete') ?? false;

    // Also load from database for more complex settings
    await _loadSettingsFromDatabase();

    notifyListeners();
  }

  Future<void> _loadSettingsFromDatabase() async {
    try {
      final settingsData = await _dbHelper.getSettings();

      // Process any complex settings from the database
      // This could include settings that are too complex for SharedPreferences
      // or that need to be synchronized across devices

      for (var setting in settingsData) {
        final key = setting['key'] as String;
        final value = setting['value'] as String;

        // Process specific complex settings
        // Example: if (key == 'complex_setting') { ... }
      }
    } catch (e) {
      print('Error loading settings from database: $e');
    }
  }

  // Units settings
  Future<void> setUnits(String newUnits) async {
    if (newUnits == 'metric' || newUnits == 'imperial') {
      await _initPrefs();
      _units = newUnits;
      await _prefs?.setString('units', newUnits);
      notifyListeners();
    }
  }

  // Voice coaching settings
  Future<void> setVoiceCoachingEnabled(bool enabled) async {
    await _initPrefs();
    _voiceCoachingEnabled = enabled;
    await _prefs?.setBool('voice_coaching_enabled', enabled);
    notifyListeners();
  }

  Future<void> setVoiceCoachingFrequency(int frequency) async {
    if (frequency >= 0 && frequency <= 2) {
      await _initPrefs();
      _voiceCoachingFrequency = frequency;
      await _prefs?.setInt('voice_coaching_frequency', frequency);
      notifyListeners();
    }
  }

  Future<void> setVoiceCoachingVoice(String voice) async {
    await _initPrefs();
    _voiceCoachingVoice = voice;
    await _prefs?.setString('voice_coaching_voice', voice);
    notifyListeners();
  }

  // Map preferences
  Future<void> setMapType(String mapType) async {
    if (['standard', 'satellite', 'terrain'].contains(mapType)) {
      await _initPrefs();
      _mapType = mapType;
      await _prefs?.setString('map_type', mapType);
      notifyListeners();
    }
  }

  Future<void> setShowMileMarkers(bool show) async {
    await _initPrefs();
    _showMileMarkers = show;
    await _prefs?.setBool('show_mile_markers', show);
    notifyListeners();
  }

  Future<void> setShowElevationProfile(bool show) async {
    await _initPrefs();
    _showElevationProfile = show;
    await _prefs?.setBool('show_elevation_profile', show);
    notifyListeners();
  }

  // GPS settings
  Future<void> setGpsAccuracy(LocationAccuracyLevel accuracy) async {
    await _initPrefs();
    _gpsAccuracy = accuracy;
    await _prefs?.setInt('gps_accuracy', accuracy.index);
    notifyListeners();
  }

  Future<void> setGpsUpdateInterval(int intervalMs) async {
    if (intervalMs >= 500 && intervalMs <= 5000) {
      await _initPrefs();
      _gpsUpdateInterval = intervalMs;
      await _prefs?.setInt('gps_update_interval', intervalMs);
      notifyListeners();
    }
  }

  // Workout display settings
  Future<void> setVisibleMetrics(List<String> metrics) async {
    await _initPrefs();
    _visibleMetrics = metrics;
    await _prefs?.setStringList('visible_metrics', metrics);
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool keepOn) async {
    await _initPrefs();
    _keepScreenOn = keepOn;
    await _prefs?.setBool('keep_screen_on', keepOn);
    notifyListeners();
  }

  Future<void> setShowLiveMap(bool show) async {
    await _initPrefs();
    _showLiveMap = show;
    await _prefs?.setBool('show_live_map', show);
    notifyListeners();
  }

  // Notification settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _initPrefs();
    _notificationsEnabled = enabled;
    await _prefs?.setBool('notifications_enabled', enabled);
    notifyListeners();
  }

  Future<void> setAchievementNotifications(bool enabled) async {
    await _initPrefs();
    _achievementNotifications = enabled;
    await _prefs?.setBool('achievement_notifications', enabled);
    notifyListeners();
  }

  Future<void> setWorkoutReminders(bool enabled) async {
    await _initPrefs();
    _workoutReminders = enabled;
    await _prefs?.setBool('workout_reminders', enabled);
    notifyListeners();
  }

  Future<void> setReminderTime(String time) async {
    // Validate time format (HH:MM)
    final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (timeRegex.hasMatch(time)) {
      await _initPrefs();
      _reminderTime = time;
      await _prefs?.setString('reminder_time', time);
      notifyListeners();
    }
  }

  Future<void> setReminderDays(List<bool> days) async {
    if (days.length == 7) {
      await _initPrefs();
      _reminderDays = days;
      await _prefs?.setStringList(
        'reminder_days',
        days.map((day) => day.toString()).toList(),
      );
      notifyListeners();
    }
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _initPrefs();

    // Reset all settings to their default values
    _units = 'metric';
    _voiceCoachingEnabled = true;
    _voiceCoachingFrequency = 1;
    _voiceCoachingVoice = 'default';
    _mapType = 'standard';
    _showMileMarkers = true;
    _showElevationProfile = true;
    _gpsAccuracy = LocationAccuracyLevel.high;
    _gpsUpdateInterval = 1000;
    _visibleMetrics = ['distance', 'duration', 'pace', 'calories'];
    _keepScreenOn = true;
    _showLiveMap = true;
    _notificationsEnabled = true;
    _achievementNotifications = true;
    _workoutReminders = false;
    _reminderTime = '18:00';
    _reminderDays = [false, true, true, true, true, true, false];
    _isOnboardingComplete = false; // Reset onboarding status on reset

    // Save all defaults to SharedPreferences
    await _prefs?.setString('units', _units);
    await _prefs?.setBool('voice_coaching_enabled', _voiceCoachingEnabled);
    await _prefs?.setInt('voice_coaching_frequency', _voiceCoachingFrequency);
    await _prefs?.setString('voice_coaching_voice', _voiceCoachingVoice);
    await _prefs?.setString('map_type', _mapType);
    await _prefs?.setBool('show_mile_markers', _showMileMarkers);
    await _prefs?.setBool('show_elevation_profile', _showElevationProfile);
    await _prefs?.setInt('gps_accuracy', _gpsAccuracy.index);
    await _prefs?.setInt('gps_update_interval', _gpsUpdateInterval);
    await _prefs?.setStringList('visible_metrics', _visibleMetrics);
    await _prefs?.setBool('keep_screen_on', _keepScreenOn);
    await _prefs?.setBool('show_live_map', _showLiveMap);
    await _prefs?.setBool('notifications_enabled', _notificationsEnabled);
    await _prefs?.setBool(
      'achievement_notifications',
      _achievementNotifications,
    );
    await _prefs?.setBool('workout_reminders', _workoutReminders);
    await _prefs?.setString('reminder_time', _reminderTime);
    await _prefs?.setStringList(
      'reminder_days',
      _reminderDays.map((day) => day.toString()).toList(),
    );
    await _prefs?.setBool('onboarding_complete', _isOnboardingComplete);

    // Also reset database settings
    await _resetDatabaseSettings();

    notifyListeners();
  }

  Future<void> _resetDatabaseSettings() async {
    try {
      // Reset any complex settings in the database
      // This could involve deleting and recreating settings entries

      // Example: await _dbHelper.resetSettings();
    } catch (e) {
      print('Error resetting database settings: $e');
    }
  }
}
