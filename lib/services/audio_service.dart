import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart'; // Import audio_session

/// Service for handling voice coaching and audio playback
class AudioService {
  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Queue of pending audio cues
  final List<String> _audioQueue = [];

  // Status
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _queueProcessing = false;

  // Getters
  bool get isPlaying => _isPlaying;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure the audio session for speech (ducking other audio)
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory:
              AVAudioSessionCategory.playback, // Suitable for cues
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers, // Duck music
          avAudioSessionMode: AVAudioSessionMode.spokenAudio, // Indicate speech
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            flags: AndroidAudioFlags.none,
            usage:
                AndroidAudioUsage
                    .voiceCommunication, // Or assistanceAccessibility
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck, // Duck music
          androidWillPauseWhenDucked: true, // Pause if ducking isn't enough
        ),
      );
      print("AudioSession configured.");

      _isInitialized = true;
    } catch (e) {
      print('Error initializing AudioService: $e');
      rethrow;
    }
  }

  /// Play an audio file from assets
  Future<void> play(String assetPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Add to queue and process
    _audioQueue.add(assetPath);
    _processQueue();
  }

  /// Process the audio queue
  Future<void> _processQueue() async {
    // If already processing queue or nothing in queue, return
    if (_queueProcessing || _audioQueue.isEmpty) return;

    _queueProcessing = true;

    try {
      while (_audioQueue.isNotEmpty) {
        final assetPath = _audioQueue.first;
        AudioSession? session; // Declare session variable

        try {
          // Activate the audio session before playing
          session = await AudioSession.instance;
          if (!await session.setActive(true)) {
            print("AudioService: Failed to activate audio session.");
            // Optionally skip playback or wait? For now, continue but log.
          } else {
            print("AudioService: Audio session activated.");
          }

          // Stop any current playback (redundant if session handles interruptions?)
          await _audioPlayer.stop();

          // Set the asset source
          await _audioPlayer.setAsset(assetPath);

          // Start playback
          _isPlaying = true;
          await _audioPlayer.play();

          // Wait for completion
          await _audioPlayer.playerStateStream.firstWhere(
            (state) => state.processingState == ProcessingState.completed,
          );

          // Remove from queue
          _audioQueue.removeAt(0);
          _isPlaying = false;

          // Deactivate the audio session after playing
          await session?.setActive(false);
          print("AudioService: Audio session deactivated.");
        } catch (e) {
          print("Error during playback or session management: $e");
          // Ensure session is deactivated even on error
          await session?.setActive(false);
          _isPlaying = false; // Reset playing state
          // Consider clearing the queue or specific item on error?
        }
      }
    } catch (e) {
      print('Error processing audio queue: $e');
    } finally {
      _queueProcessing = false;
    }
  }

  /// Play a voice cue based on type and data
  Future<void> playVoiceCue(
    String cueType, {
    Map<String, dynamic>? data,
  }) async {
    // Select appropriate audio file based on cue type and data
    String assetPath = _selectAudioFile(cueType, data);
    await play(assetPath);
  }

  /// Select the appropriate audio file based on cue type and data
  String _selectAudioFile(String cueType, Map<String, dynamic>? data) {
    // Base path for voice assets
    const basePath = 'assets/audio/voice_cues/';

    switch (cueType) {
      case 'start':
        return '${basePath}workout_started.mp3';
      case 'pause':
        return '${basePath}workout_paused.mp3';
      case 'resume':
        return '${basePath}workout_resumed.mp3';
      case 'stop':
        return '${basePath}workout_completed.mp3';
      case 'distance':
        // Check if we have distance data
        if (data != null && data.containsKey('distance')) {
          final distance = data['distance'] as double;
          final isMetric = data['isMetric'] as bool? ?? true;

          // Select appropriate distance announcement
          if (isMetric) {
            if (distance == 1.0) {
              return '${basePath}distance_1km.mp3';
            } else if (distance == 5.0) {
              return '${basePath}distance_5km.mp3';
            } else if (distance == 10.0) {
              return '${basePath}distance_10km.mp3';
            } else {
              return '${basePath}distance_milestone.mp3';
            }
          } else {
            // Imperial distances
            if (distance == 1.0) {
              return '${basePath}distance_1mile.mp3';
            } else if (distance == 5.0) {
              return '${basePath}distance_5miles.mp3';
            } else if (distance == 10.0) {
              return '${basePath}distance_10miles.mp3';
            } else {
              return '${basePath}distance_milestone.mp3';
            }
          }
        }
        return '${basePath}distance_milestone.mp3';
      case 'pace':
        return '${basePath}current_pace.mp3';
      case 'time':
        return '${basePath}elapsed_time.mp3';
      case 'achievement':
        return '${basePath}achievement_unlocked.mp3';
      case 'interval_start':
        return '${basePath}interval_start.mp3';
      case 'interval_end':
        return '${basePath}interval_end.mp3';
      case 'cooldown':
        return '${basePath}cooldown.mp3';
      case 'warmup':
        return '${basePath}warmup.mp3';
      default:
        return '${basePath}notification.mp3';
    }
  }

  /// Clear the audio queue
  void clearQueue() {
    _audioQueue.clear();
  }

  /// Stop current playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  /// Dispose of resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
