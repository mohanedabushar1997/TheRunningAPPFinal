import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/workout_point_model.dart';
import '../models/workout_model.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/calculation_service.dart';
import '../models/training_session_model.dart'; // Import TrainingSessionModel
import 'workout_provider.dart';
import 'settings_provider.dart'; // Import SettingsProvider

enum TrackingState { idle, tracking, paused }

class TrackingProvider with ChangeNotifier {
  // Inject LocationService and CalculationService
  final LocationService _locationService;
  final CalculationService _calculationService;
  final SettingsProvider _settingsProvider; // Add SettingsProvider
  final UserModel? _user;
  // Inject WorkoutProvider for saving
  WorkoutProvider? _workoutProvider;

  TrackingState _state = TrackingState.idle;
  TrackingState get state => _state;

  // Real-time data
  Position? _currentPosition;
  double _currentDistance = 0.0;
  Duration _currentDuration = Duration.zero;
  double _currentPace = 0.0; // seconds per km or mile
  int _currentCalories = 0;
  List<WorkoutPointModel> _routePoints = [];
  double _maxSpeed = 0.0;
  double _elevationGain = 0.0;
  double _elevationLoss = 0.0;
  Position? _lastPosition;
  WorkoutType _workoutType = WorkoutType.run;
  TrainingSessionModel? _currentTrainingSession; // Added
  String? _currentIntervalDescription; // Added
  Duration _remainingIntervalTime = Duration.zero; // Added

  // Goal data
  double? _targetDistance; // in km
  Duration? _targetDuration;

  // Split tracking data
  List<Duration> _splits = []; // Added
  double _distanceAtLastSplit = 0.0; // Added
  Duration _timeAtLastSplit = Duration.zero; // Added

  // --- Getters for UI ---
  Position? get currentPosition => _currentPosition;
  double get distance => _currentDistance; // Renamed for UI
  Duration get elapsedTime => _currentDuration; // Renamed for UI
  double get currentPace => _currentPace;
  int get caloriesBurned => _currentCalories; // Renamed for UI
  List<WorkoutPointModel> get routePoints => _routePoints;
  double get maxSpeed => _maxSpeed;
  double get elevationGain => _elevationGain;
  double get elevationLoss => _elevationLoss;
  WorkoutType get workoutType => _workoutType;
  double? get distanceGoal => _targetDistance; // Renamed for UI
  Duration? get durationGoal => _targetDuration; // Renamed for UI
  String? get currentIntervalDescription =>
      _currentIntervalDescription; // Added
  Duration get remainingIntervalTime => _remainingIntervalTime; // Added
  bool get isTrainingPlanWorkout =>
      _currentTrainingSession != null; // Added helper

  bool get isTracking => _state == TrackingState.tracking;
  bool get isPaused => _state == TrackingState.paused;
  bool get isIdle => _state == TrackingState.idle;
  List<Duration> get splits => _splits; // Added getter

  bool get hasGoal => _targetDistance != null || _targetDuration != null;
  bool get hasDistanceGoal => _targetDistance != null;

  double get goalProgress {
    if (_targetDistance != null && _targetDistance! > 0) {
      return (_currentDistance / _targetDistance!).clamp(0.0, 1.0);
    } else if (_targetDuration != null && _targetDuration!.inSeconds > 0) {
      return (_currentDuration.inSeconds / _targetDuration!.inSeconds).clamp(
        0.0,
        1.0,
      );
    }
    return 0.0;
  }
  // --- End Getters ---

  // Stream subscription for location updates
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _timer;

  // Constructor with dependency injection
  TrackingProvider({
    required LocationService locationService,
    required CalculationService calculationService,
    required SettingsProvider settingsProvider, // Require SettingsProvider
    UserModel? user,
    // WorkoutProvider is optional here, can be set later
  }) : _locationService = locationService,
       _calculationService = calculationService,
       _settingsProvider = settingsProvider, // Store SettingsProvider
       _user = user;

  // Method to set WorkoutProvider after initialization (if needed)
  void setWorkoutProvider(WorkoutProvider provider) {
    _workoutProvider = provider;
  }

  // Set workout type before starting tracking
  void setWorkoutType(WorkoutType type) {
    _workoutType = type;
    notifyListeners();
  }

  // --- Goal Setting Methods ---
  void setDistanceGoal(double distanceKm) {
    _targetDistance = distanceKm;
    _targetDuration = null; // Clear duration goal if setting distance goal
    print("Distance goal set: $distanceKm km");
    notifyListeners();
  }

  void setDurationGoal(int durationSeconds) {
    _targetDuration = Duration(seconds: durationSeconds);
    _targetDistance = null; // Clear distance goal if setting duration goal
    print("Duration goal set: ${Duration(seconds: durationSeconds)}");
    notifyListeners();
  }

  void clearGoals() {
    _targetDistance = null;
    _targetDuration = null;
    print("Goals cleared");
    notifyListeners();
  }
  // --- End Goal Setting Methods ---

  // Method called by ChangeNotifierProxyProvider when SettingsProvider updates
  void updateSettings(SettingsProvider newSettings) {
    // Check if accuracy setting changed and update LocationService if needed
    // Note: We might need to store the previous accuracy to compare,
    // or simply re-apply the setting every time. Re-applying is simpler.
    print("TrackingProvider received settings update. Applying GPS accuracy.");
    _locationService.setAccuracy(
      newSettings.gpsAccuracy.toGeolocatorAccuracy(),
    );
    // No need to notifyListeners here unless a UI element depends on this directly
  }

  // --- Renamed Tracking Control Methods for UI ---
  // Modify startWorkout to accept optional training session
  Future<void> startWorkout({TrainingSessionModel? trainingSession}) async {
    if (_state != TrackingState.idle) return;

    _state = TrackingState.tracking;
    _resetTrackingData();
    _currentTrainingSession = trainingSession; // Store the session

    // Initialize interval display if session provided
    if (_currentTrainingSession != null) {
      // For now, just show the first description and target duration as the 'interval'
      _currentIntervalDescription =
          _currentTrainingSession!.description ?? 'Training Session';
      _remainingIntervalTime =
          _currentTrainingSession!.targetDuration ?? Duration.zero;
      print(
        "Starting training session: ${_currentIntervalDescription}, Duration: $_remainingIntervalTime",
      );
    } else {
      _currentIntervalDescription = null;
      _remainingIntervalTime = Duration.zero;
    }

    _startTimer();

    // Initialize location service
    try {
      // Apply accuracy setting BEFORE starting tracking
      _locationService.setAccuracy(
        _settingsProvider.gpsAccuracy.toGeolocatorAccuracy(),
      );

      await _locationService.initialize();
      await _locationService.startTracking();

      // Listen to location updates
      _positionStreamSubscription = _locationService.locationStream?.listen(
        _updateMetrics,
        onError: (error) {
          print('Error from location stream: $error');
          // TODO: Handle location errors more gracefully (e.g., notify user)
        },
      );

      notifyListeners();
    } catch (e) {
      print('Error starting workout: $e');
      await stopWorkout(save: false); // Ensure cleanup if start fails
    }
  }

  void pauseWorkout() {
    // Renamed from pauseTracking
    if (_state != TrackingState.tracking) return;

    _state = TrackingState.paused;
    _stopTimer();

    // Pause location updates (but don't dispose)
    _positionStreamSubscription?.pause();

    notifyListeners();
  }

  void resumeWorkout() {
    // Renamed from resumeTracking
    if (_state != TrackingState.paused) return;

    _state = TrackingState.tracking;
    _startTimer();

    // Resume location updates
    _positionStreamSubscription?.resume();

    notifyListeners();
  }

  // Combined stop method
  Future<WorkoutModel?> stopWorkout({required bool save}) async {
    if (_state == TrackingState.idle) return null;

    final previousState = _state;
    _state = TrackingState.idle;
    _stopTimer();

    // Stop location service
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationService.stopTracking();

    WorkoutModel? workout;
    // Only create a workout if we were actually tracking or paused long enough
    if (previousState == TrackingState.tracking ||
        (previousState == TrackingState.paused &&
            _currentDuration.inSeconds > 10)) {
      // Create workout model from tracking data
      workout = WorkoutModel(
        date: DateTime.now().subtract(
          _currentDuration,
        ), // Use start time approx
        type: _workoutType,
        duration: _currentDuration,
        distance:
            _currentDistance > 0 ? _currentDistance : null, // Only set if > 0
        calories: _currentCalories > 0 ? _currentCalories : null,
        avgPace: _currentPace > 0 ? _currentPace : null,
        avgSpeed: _calculationService.calculateSpeedFromPace(_currentPace),
        maxSpeed: _maxSpeed > 0 ? _maxSpeed : null,
        elevationGain: _elevationGain > 0 ? _elevationGain : null,
        elevationLoss: _elevationLoss > 0 ? _elevationLoss : null,
        routePoints: List.from(_routePoints),
        isManualEntry: false,
        // TODO: Add goal met status?
      );

      if (save && workout != null) {
        if (_workoutProvider != null) {
          print("Saving workout...");
          await _workoutProvider!.saveWorkout(workout);
        } else {
          print("Error: WorkoutProvider not set, cannot save workout.");
          // Optionally return the workout anyway, or null to indicate save failure
          workout = null;
        }
      } else {
        print("Workout stopped, not saving.");
      }
    }

    // Reset data AFTER creating/saving the model
    _resetTrackingData();
    notifyListeners();
    return workout; // Return the workout (saved or not) or null
  }

  // Specific methods called by UI
  Future<WorkoutModel?> stopAndSaveWorkout() async {
    return await stopWorkout(save: true);
  }

  Future<void> discardWorkout() async {
    await stopWorkout(save: false);
  }
  // --- End Renamed Methods ---

  // Reset all tracking data for a new session
  void _resetTrackingData() {
    _currentPosition = null;
    _lastPosition = null;
    _currentDistance = 0.0;
    _currentDuration = Duration.zero;
    _currentPace = 0.0;
    _currentCalories = 0;
    _routePoints = [];
    _maxSpeed = 0.0;
    _elevationGain = 0.0;
    _elevationLoss = 0.0;
    _currentTrainingSession = null; // Reset training session
    _currentIntervalDescription = null; // Reset interval display
    _remainingIntervalTime = Duration.zero; // Reset interval time
    _splits = []; // Reset splits
    _distanceAtLastSplit = 0.0; // Reset split tracking
    _timeAtLastSplit = Duration.zero; // Reset split tracking
    // Do not reset _workoutType here, it's set before starting
    // Reset goals? Or keep them until explicitly cleared? Let's keep them for now.
    // _targetDistance = null;
    // _targetDuration = null;
  }

  // Start the duration timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == TrackingState.tracking) {
        // Only increment if tracking
        _currentDuration += const Duration(seconds: 1);

        // Update calories every second based on duration
        _updateCalories();

        // Decrement interval timer if applicable
        if (_currentTrainingSession != null &&
            _remainingIntervalTime > Duration.zero) {
          _remainingIntervalTime -= const Duration(seconds: 1);
          if (_remainingIntervalTime < Duration.zero) {
            _remainingIntervalTime = Duration.zero;
            // TODO: Implement logic to advance to the next interval step here
            print("Interval time reached zero.");
          }
        }

        // Check if duration goal met
        if (_targetDuration != null && _currentDuration >= _targetDuration!) {
          print("Duration goal met!");
          // TODO: Notify user, potentially auto-stop?
          // Maybe set a flag? _durationGoalMet = true;
        }

        notifyListeners();
      }
    });
  }

  // Stop the duration timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Update metrics based on new position data
  void _updateMetrics(Position newPosition) {
    // Filter out points with poor accuracy (e.g., > 50 meters)
    // TODO: Make this threshold configurable via SettingsProvider?
    if (newPosition.accuracy > 50.0) {
      print('Discarding inaccurate point. Accuracy: ${newPosition.accuracy}');
      return; // Ignore this point
    }

    _currentPosition = newPosition;

    // If this is the first valid position, just store it
    if (_lastPosition == null) {
      _lastPosition = newPosition;
      final point = _locationService.positionToWorkoutPoint(
        newPosition,
        workoutId: 0,
      );
      _routePoints.add(point);
      notifyListeners();
      return;
    }

    // Calculate distance increment
    final distanceIncrement = _locationService.calculateDistance(
      _lastPosition!,
      newPosition,
    ); // Distance in meters

    // Only update if movement is significant? (Avoid GPS jitter accumulation)
    // Use a smaller threshold for more responsive distance updates
    if (distanceIncrement > 0.5) {
      // Threshold in meters
      _currentDistance +=
          distanceIncrement / 1000; // Convert meters to kilometers

      // Update pace (seconds per kilometer)
      if (_currentDistance > 0) {
        _currentPace = _currentDuration.inSeconds / _currentDistance;
      }

      // Update max speed (convert m/s to km/h)
      final currentSpeedKmh = newPosition.speed * 3.6;
      if (currentSpeedKmh > _maxSpeed) {
        _maxSpeed = currentSpeedKmh;
      }

      // Update elevation data
      if (_lastPosition!.altitude != 0 && newPosition.altitude != 0) {
        final elevationDiff = newPosition.altitude - _lastPosition!.altitude;
        // Add smoothing or threshold?
        if (elevationDiff.abs() > 0.5) {
          // Threshold for elevation change
          if (elevationDiff > 0) {
            _elevationGain += elevationDiff;
          } else {
            _elevationLoss += elevationDiff.abs();
          }
        }
      }

      // Create route point
      final point = _locationService.positionToWorkoutPoint(
        newPosition,
        workoutId: 0, // Temporary ID, will be updated when saved
      );
      _routePoints.add(point);

      // Update last position
      _lastPosition = newPosition;

      // Update calories
      _updateCalories();

      // Check if distance goal met
      if (_targetDistance != null && _currentDistance >= _targetDistance!) {
        print("Distance goal met!");
        // TODO: Notify user, potentially auto-stop?
        // Maybe set a flag? _distanceGoalMet = true;
      }

      // Check for splits after updating distance/duration
      _checkAndRecordSplit();

      notifyListeners();
    } else {
      // Even if distance didn't change significantly, update position for map?
      // Or maybe only add points if distance > threshold?
      // For now, just update the current position state
      notifyListeners();
    }
  }

  // Update calorie calculation
  void _updateCalories() {
    // Get user weight or use default
    final userWeight = _user?.weight ?? 70.0; // Default to 70kg if no user data

    // Calculate calories
    _currentCalories = _calculationService.calculateCaloriesBurned(
      workoutType: _workoutType,
      duration: _currentDuration,
      weightInKg: userWeight,
      distanceInKm: _currentDistance,
      // Add avgSpeed if needed by calculation service
      // avgSpeedKmh: _calculationService.calculateSpeedFromPace(_currentPace),
    );
  }

  // --- Split Logic ---
  void _checkAndRecordSplit() {
    // Determine the unit distance based on settings (default to km)
    // TODO: Get unit preference from SettingsProvider
    final bool useImperial = _settingsProvider.units == 'imperial';
    final double unitDistance = useImperial ? 1.60934 : 1.0; // 1 mile or 1 km

    // Check if the current distance has crossed the next split threshold
    if (_currentDistance >= _distanceAtLastSplit + unitDistance) {
      // Calculate the time for this split
      final Duration splitTime = _currentDuration - _timeAtLastSplit;
      _splits.add(splitTime);

      // Update tracking variables for the next split
      // Find the exact distance marker (e.g., 1km, 2km, 3km...)
      _distanceAtLastSplit =
          (_currentDistance / unitDistance).floor() * unitDistance;
      _timeAtLastSplit = _currentDuration; // Record time at this split point

      print("Split ${_splits.length} recorded: ${splitTime.inSeconds}s");
      // Optionally trigger a voice cue for the split
      // voiceCoachingProvider.playCue('split', data: {'number': _splits.length, 'time': splitTime});
      notifyListeners(); // Notify UI about the new split
    }
  }
  // --- End Split Logic ---

  // Add a manual location point (for testing or manual entry)
  void addManualPoint(
    double latitude,
    double longitude, {
    double? elevation,
    double? speed,
  }) {
    final position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: elevation ?? 0,
      heading: 0,
      speed: speed ?? 0, // m/s
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    _updateMetrics(position);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}

// Helper extension to convert enum (if needed, depends on LocationService implementation)
// Assuming LocationService uses geolocator's LocationAccuracy directly now.
// If LocationService uses its own enum, this mapping is needed.
extension LocationAccuracyLevelMapping on LocationAccuracyLevel {
  LocationAccuracy toGeolocatorAccuracy() {
    switch (this) {
      case LocationAccuracyLevel.low:
        return LocationAccuracy.low;
      case LocationAccuracyLevel.medium:
        return LocationAccuracy.medium;
      case LocationAccuracyLevel.high:
        return LocationAccuracy.high;
      case LocationAccuracyLevel.best:
        return LocationAccuracy.best;
      default:
        return LocationAccuracy.high; // Default fallback
    }
  }
}
