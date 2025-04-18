import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/workout_point_model.dart';
import '../models/workout_model.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/calculation_service.dart';

enum TrackingState { idle, tracking, paused }

class TrackingProvider with ChangeNotifier {
  // Inject LocationService and CalculationService
  final LocationService _locationService;
  final CalculationService _calculationService;
  final UserModel? _user;

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

  Position? get currentPosition => _currentPosition;
  double get currentDistance => _currentDistance;
  Duration get currentDuration => _currentDuration;
  double get currentPace => _currentPace;
  int get currentCalories => _currentCalories;
  List<WorkoutPointModel> get routePoints => _routePoints;
  double get maxSpeed => _maxSpeed;
  double get elevationGain => _elevationGain;
  double get elevationLoss => _elevationLoss;
  WorkoutType get workoutType => _workoutType;

  // Stream subscription for location updates
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _timer;

  // Constructor with dependency injection
  TrackingProvider({
    required LocationService locationService,
    required CalculationService calculationService,
    UserModel? user,
  }) : _locationService = locationService,
       _calculationService = calculationService,
       _user = user;

  // Set workout type before starting tracking
  void setWorkoutType(WorkoutType type) {
    _workoutType = type;
    notifyListeners();
  }

  // Start tracking a new workout
  Future<void> startTracking() async {
    if (_state != TrackingState.idle) return;
    
    _state = TrackingState.tracking;
    _resetTrackingData();
    _startTimer();
    
    // Initialize location service
    try {
      await _locationService.initialize();
      await _locationService.startTracking();
      
      // Listen to location updates
      _positionStreamSubscription = _locationService.locationStream?.listen(
        _updateMetrics,
        onError: (error) {
          print('Error from location stream: $error');
        },
      );
      
      notifyListeners();
    } catch (e) {
      print('Error starting tracking: $e');
      stopTracking();
    }
  }

  // Pause the current tracking session
  void pauseTracking() {
    if (_state != TrackingState.tracking) return;
    
    _state = TrackingState.paused;
    _stopTimer();
    
    // Pause location updates (but don't dispose)
    _positionStreamSubscription?.pause();
    
    notifyListeners();
  }

  // Resume a paused tracking session
  void resumeTracking() {
    if (_state != TrackingState.paused) return;
    
    _state = TrackingState.tracking;
    _startTimer();
    
    // Resume location updates
    _positionStreamSubscription?.resume();
    
    notifyListeners();
  }

  // Stop tracking and prepare data for saving
  Future<WorkoutModel?> stopTracking() async {
    if (_state == TrackingState.idle) return null;
    
    final previousState = _state;
    _state = TrackingState.idle;
    _stopTimer();
    
    // Stop location service
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationService.stopTracking();
    
    // Only create a workout if we were actually tracking (not just paused)
    if (previousState == TrackingState.tracking || 
        (previousState == TrackingState.paused && _currentDuration.inSeconds > 10)) {
      
      // Create workout model from tracking data
      final workout = WorkoutModel(
        date: DateTime.now(),
        type: _workoutType,
        duration: _currentDuration,
        distance: _currentDistance,
        calories: _currentCalories,
        avgPace: _currentPace,
        avgSpeed: _calculationService.calculateSpeedFromPace(_currentPace),
        maxSpeed: _maxSpeed,
        elevationGain: _elevationGain,
        elevationLoss: _elevationLoss,
        routePoints: List.from(_routePoints),
        isManualEntry: false,
      );
      
      notifyListeners();
      return workout;
    }
    
    notifyListeners();
    return null;
  }

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
  }

  // Start the duration timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDuration += const Duration(seconds: 1);
      
      // Update calories every second based on duration
      _updateCalories();
      
      notifyListeners();
    });
  }

  // Stop the duration timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Update metrics based on new position data
  void _updateMetrics(Position newPosition) {
    _currentPosition = newPosition;
    
    // If this is the first position, just store it
    if (_lastPosition == null) {
      _lastPosition = newPosition;
      
      // Create first route point
      final point = _locationService.positionToWorkoutPoint(
        newPosition,
        workoutId: 0, // Temporary ID, will be updated when saved
      );
      _routePoints.add(point);
      
      notifyListeners();
      return;
    }
    
    // Calculate distance increment
    final distanceIncrement = _locationService.calculateDistance(
      _lastPosition!,
      newPosition,
    ) / 1000; // Convert meters to kilometers
    
    // Update total distance
    _currentDistance += distanceIncrement;
    
    // Update pace (seconds per kilometer)
    if (_currentDistance > 0) {
      _currentPace = _currentDuration.inSeconds / _currentDistance;
    }
    
    // Update max speed
    if (newPosition.speed > _maxSpeed) {
      _maxSpeed = newPosition.speed;
    }
    
    // Update elevation data
    if (_lastPosition!.altitude != 0 && newPosition.altitude != 0) {
      final elevationDiff = newPosition.altitude - _lastPosition!.altitude;
      if (elevationDiff > 0) {
        _elevationGain += elevationDiff;
      } else {
        _elevationLoss += elevationDiff.abs();
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
    
    notifyListeners();
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
    );
  }

  // Add a manual location point (for testing or manual entry)
  void addManualPoint(double latitude, double longitude, {double? elevation, double? speed}) {
    final position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: elevation ?? 0,
      heading: 0,
      speed: speed ?? 0,
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
