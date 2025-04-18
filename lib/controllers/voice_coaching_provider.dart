import 'package:flutter/foundation.dart';
// TODO: Import AudioService

class VoiceCoachingProvider with ChangeNotifier {
  // TODO: Inject AudioService

  bool _isEnabled = true; // Default to enabled
  bool get isEnabled => _isEnabled;

  // TODO: Define state for voice selection, cue frequency, etc.

  VoiceCoachingProvider() {
    // TODO: Load settings (e.g., isEnabled)
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    // TODO: Persist this setting (e.g., using SettingsProvider or SharedPreferences)
    notifyListeners();
  }

  // TODO: Implement method to trigger voice cues based on events/metrics
  // void playCue(String cueType, {Map<String, dynamic>? data}) {
  //   if (!_isEnabled) return;
  //   // Logic to select appropriate audio file based on cueType and data
  //   // String audioPath = _selectAudioFile(cueType, data);
  //   // audioService.play(audioPath);
  // }

  // TODO: Implement method to manage audio queue if multiple cues trigger
}
