import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
// TODO: Import models (WorkoutPoint, etc.) and services (LocationService, CalculationService)

enum TrackingState { idle, tracking, paused }

class TrackingProvider with ChangeNotifier {
  // TODO: Inject LocationService and CalculationService

  TrackingState _state = TrackingState.idle;
  TrackingState get state => _state;

  // Real-time data
  Position? _currentPosition;
  double _currentDistance = 0.0;
  Duration _currentDuration = Duration.zero;
  double _currentPace = 0.0; // seconds per km or mile
  int _currentCalories = 0;
  // List<WorkoutPoint> _routePoints = [];

  Position? get currentPosition => _currentPosition;
  double get currentDistance => _currentDistance;
  Duration get currentDuration => _currentDuration;
  double get currentPace => _currentPace;
  int get currentCalories => _currentCalories;
  // List<WorkoutPoint> get routePoints => _routePoints;

  Timer? _timer;

  // TODO: Implement methods to start, pause, resume, stop tracking
  // void startTracking() {
  //   _state = TrackingState.tracking;
  //   _resetTrackingData();
  //   _startTimer();
  //   // Start location service stream
  //   // Listen to location updates and update metrics
  //   notifyListeners();
  // }

  // void pauseTracking() {
  //   _state = TrackingState.paused;
  //   _stopTimer();
  //   // Pause location service stream
  //   notifyListeners();
  // }

  // void resumeTracking() {
  //   _state = TrackingState.tracking;
  //   _startTimer();
  //   // Resume location service stream
  //   notifyListeners();
  // }

  // void stopTracking() {
  //   _state = TrackingState.idle;
  //   _stopTimer();
  //   // Stop location service stream
  //   // Prepare data for saving (e.g., pass to WorkoutProvider)
  //   notifyListeners();
  // }

  // void _resetTrackingData() {
  //   _currentPosition = null;
  //   _currentDistance = 0.0;
  //   _currentDuration = Duration.zero;
  //   _currentPace = 0.0;
  //   _currentCalories = 0;
  //   // _routePoints = [];
  // }

  // void _startTimer() {
  //   _timer?.cancel();
  //   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     _currentDuration += const Duration(seconds: 1);
  //     notifyListeners();
  //   });
  // }

  // void _stopTimer() {
  //   _timer?.cancel();
  // }

  // TODO: Implement method to update metrics based on new position/data
  // void _updateMetrics(Position newPosition) {
  //   // Calculate distance, pace, calories using services
  //   // Add point to _routePoints
  //   notifyListeners();
  // }

  // @override
  // void dispose() {
  //   _timer?.cancel();
  //   // Dispose location stream subscription
  //   super.dispose();
  // }
}
