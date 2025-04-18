import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';

class VoiceCoachingProvider with ChangeNotifier {
  // Inject AudioService
  final AudioService _audioService;
  SharedPreferences? _prefs;

  bool _isEnabled = true; // Default to enabled
  bool get isEnabled => _isEnabled;

  // Define state for voice selection, cue frequency, etc.
  String _voiceType = 'default'; // default, male, female
  int _cueFrequency = 1; // 0: minimal, 1: moderate, 2: detailed
  bool _distanceAnnouncementsEnabled = true;
  bool _paceAnnouncementsEnabled = true;
  bool _timeAnnouncementsEnabled = true;
  double _distanceInterval = 1.0; // km or miles
  int _timeInterval = 5; // minutes
  bool _announceMotivationalPhrases = true;

  // Getters
  String get voiceType => _voiceType;
  int get cueFrequency => _cueFrequency;
  bool get distanceAnnouncementsEnabled => _distanceAnnouncementsEnabled;
  bool get paceAnnouncementsEnabled => _paceAnnouncementsEnabled;
  bool get timeAnnouncementsEnabled => _timeAnnouncementsEnabled;
  double get distanceInterval => _distanceInterval;
  int get timeInterval => _timeInterval;
  bool get announceMotivationalPhrases => _announceMotivationalPhrases;

  VoiceCoachingProvider({required AudioService audioService}) 
      : _audioService = audioService {
    _loadSettings();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    await _initPrefs();
    
    _isEnabled = _prefs?.getBool('voice_coaching_enabled') ?? true;
    _voiceType = _prefs?.getString('voice_type') ?? 'default';
    _cueFrequency = _prefs?.getInt('cue_frequency') ?? 1;
    _distanceAnnouncementsEnabled = _prefs?.getBool('distance_announcements_enabled') ?? true;
    _paceAnnouncementsEnabled = _prefs?.getBool('pace_announcements_enabled') ?? true;
    _timeAnnouncementsEnabled = _prefs?.getBool('time_announcements_enabled') ?? true;
    _distanceInterval = _prefs?.getDouble('distance_interval') ?? 1.0;
    _timeInterval = _prefs?.getInt('time_interval') ?? 5;
    _announceMotivationalPhrases = _prefs?.getBool('announce_motivational_phrases') ?? true;
    
    // Initialize audio service
    await _audioService.initialize();
    
    notifyListeners();
  }

  // Enable/disable voice coaching
  Future<void> setEnabled(bool enabled) async {
    await _initPrefs();
    _isEnabled = enabled;
    await _prefs?.setBool('voice_coaching_enabled', enabled);
    notifyListeners();
  }
  
  // Set voice type
  Future<void> setVoiceType(String voiceType) async {
    if (['default', 'male', 'female'].contains(voiceType)) {
      await _initPrefs();
      _voiceType = voiceType;
      await _prefs?.setString('voice_type', voiceType);
      notifyListeners();
    }
  }
  
  // Set cue frequency
  Future<void> setCueFrequency(int frequency) async {
    if (frequency >= 0 && frequency <= 2) {
      await _initPrefs();
      _cueFrequency = frequency;
      await _prefs?.setInt('cue_frequency', frequency);
      notifyListeners();
    }
  }
  
  // Enable/disable distance announcements
  Future<void> setDistanceAnnouncementsEnabled(bool enabled) async {
    await _initPrefs();
    _distanceAnnouncementsEnabled = enabled;
    await _prefs?.setBool('distance_announcements_enabled', enabled);
    notifyListeners();
  }
  
  // Enable/disable pace announcements
  Future<void> setPaceAnnouncementsEnabled(bool enabled) async {
    await _initPrefs();
    _paceAnnouncementsEnabled = enabled;
    await _prefs?.setBool('pace_announcements_enabled', enabled);
    notifyListeners();
  }
  
  // Enable/disable time announcements
  Future<void> setTimeAnnouncementsEnabled(bool enabled) async {
    await _initPrefs();
    _timeAnnouncementsEnabled = enabled;
    await _prefs?.setBool('time_announcements_enabled', enabled);
    notifyListeners();
  }
  
  // Set distance interval
  Future<void> setDistanceInterval(double interval) async {
    if (interval > 0) {
      await _initPrefs();
      _distanceInterval = interval;
      await _prefs?.setDouble('distance_interval', interval);
      notifyListeners();
    }
  }
  
  // Set time interval
  Future<void> setTimeInterval(int interval) async {
    if (interval > 0) {
      await _initPrefs();
      _timeInterval = interval;
      await _prefs?.setInt('time_interval', interval);
      notifyListeners();
    }
  }
  
  // Enable/disable motivational phrases
  Future<void> setAnnounceMotivationalPhrases(bool enabled) async {
    await _initPrefs();
    _announceMotivationalPhrases = enabled;
    await _prefs?.setBool('announce_motivational_phrases', enabled);
    notifyListeners();
  }

  // Play voice cue based on event type and data
  Future<void> playCue(String cueType, {Map<String, dynamic>? data}) async {
    if (!_isEnabled) return;
    
    // Check if this cue type is enabled based on frequency settings
    if (!_shouldPlayCueType(cueType)) return;
    
    // Play the cue using AudioService
    await _audioService.playVoiceCue(cueType, data: data);
  }
  
  // Determine if a cue type should be played based on frequency settings
  bool _shouldPlayCueType(String cueType) {
    // Always play start, pause, resume, stop cues
    if (['start', 'pause', 'resume', 'stop', 'achievement'].contains(cueType)) {
      return true;
    }
    
    // Check frequency settings for other cue types
    switch (cueType) {
      case 'distance':
        return _distanceAnnouncementsEnabled && _cueFrequency > 0;
      case 'pace':
        return _paceAnnouncementsEnabled && _cueFrequency > 0;
      case 'time':
        return _timeAnnouncementsEnabled && _cueFrequency > 0;
      case 'motivational':
        return _announceMotivationalPhrases && _cueFrequency > 1;
      case 'interval_start':
      case 'interval_end':
      case 'cooldown':
      case 'warmup':
        return _cueFrequency > 0;
      default:
        return _cueFrequency > 1; // Only play detailed cues at highest frequency
    }
  }
  
  // Check if distance announcement should be made
  bool shouldAnnounceDistance(double currentDistance, double lastAnnouncedDistance) {
    if (!_isEnabled || !_distanceAnnouncementsEnabled) return false;
    
    // Calculate the next announcement distance
    final nextAnnouncement = lastAnnouncedDistance + _distanceInterval;
    
    // Check if we've reached or passed the next announcement point
    return currentDistance >= nextAnnouncement;
  }
  
  // Check if time announcement should be made
  bool shouldAnnounceTime(Duration currentDuration, Duration lastAnnouncedDuration) {
    if (!_isEnabled || !_timeAnnouncementsEnabled) return false;
    
    // Calculate the next announcement time
    final nextAnnouncementMinutes = 
        (lastAnnouncedDuration.inMinutes / _timeInterval).ceil() * _timeInterval;
    final nextAnnouncement = Duration(minutes: nextAnnouncementMinutes);
    
    // Check if we've reached or passed the next announcement point
    return currentDuration >= nextAnnouncement;
  }
  
  // Clear any pending voice cues
  void clearPendingCues() {
    _audioService.clearQueue();
  }
  
  // Stop current playback
  Future<void> stopPlayback() async {
    await _audioService.stop();
  }
  
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
