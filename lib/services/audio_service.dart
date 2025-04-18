import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart'; // For rootBundle

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  // TODO: Potentially manage a queue for overlapping cues

  AudioService() {
    // Optional: Configure player settings if needed
    // _audioPlayer.setVolume(1.0);
    // _audioPlayer.setSpeed(1.0);
  }

  // Play an audio cue from the assets folder
  Future<void> playCue(String assetPath) async {
    // Example assetPath: 'assets/audio/cues/start_workout.mp3'
    print("Playing audio cue: $assetPath");
    try {
      // Check if player is already playing, decide whether to stop or queue
      if (_audioPlayer.playing) {
        // Option 1: Stop current playback
        await _audioPlayer.stop();
        // Option 2: Queue (requires more complex queue management)
        // print("Audio player busy, cue '$assetPath' skipped/queued.");
        // return;
      }

      // Set audio source from asset
      await _audioPlayer.setAsset(assetPath);

      // Play the audio
      await _audioPlayer.play();

      // Optional: Listen for playback completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          print("Audio cue '$assetPath' finished playing.");
          // You might want to stop/reset the player here if not looping
          // _audioPlayer.stop();
        }
      });
    } catch (e) {
      // Handle errors, e.g., file not found, decoding error
      print("Error playing audio cue '$assetPath': $e");
    }
  }

  // Stop any currently playing audio
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  // TODO: Implement volume control (maybe link to SettingsProvider)
  // Future<void> setVolume(double volume) async { ... }

  // TODO: Implement audio mixing/ducking if music playback is added (Task 7.1.3)

  // Dispose the player when the service is no longer needed
  void dispose() {
    _audioPlayer.dispose();
  }
}
