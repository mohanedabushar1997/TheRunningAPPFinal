import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/workout_point_model.dart';

/// Service for handling location tracking and GPS functionality
class LocationService {
  // Stream controller for location updates
  StreamController<Position>? _locationController;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Settings
  LocationAccuracy _accuracy = LocationAccuracy.high;
  int _updateIntervalMs = 1000; // 1 second by default
  
  // Public stream getter
  Stream<Position>? get locationStream => _locationController?.stream;
  
  // Current position
  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;
  
  // Status
  bool _isTracking = false;
  bool get isTracking => _isTracking;
  
  /// Initialize the location service
  Future<void> initialize() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    
    // Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
  }
  
  /// Set the accuracy level for GPS tracking
  void setAccuracy(LocationAccuracy accuracy) {
    _accuracy = accuracy;
    // If currently tracking, restart with new accuracy
    if (_isTracking) {
      stopTracking();
      startTracking();
    }
  }
  
  /// Set the update interval for GPS tracking
  void setUpdateInterval(int milliseconds) {
    _updateIntervalMs = milliseconds;
    // If currently tracking, restart with new interval
    if (_isTracking) {
      stopTracking();
      startTracking();
    }
  }
  
  /// Start tracking location
  Future<void> startTracking() async {
    if (_isTracking) return;
    
    await initialize();
    
    _locationController = StreamController<Position>.broadcast();
    
    // Get initial position
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );
      _locationController?.add(_lastPosition!);
    } catch (e) {
      print('Error getting initial position: $e');
    }
    
    // Start listening to position updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _accuracy,
        distanceFilter: 5, // Minimum distance (meters) before updates
        timeLimit: Duration(milliseconds: _updateIntervalMs),
      ),
    ).listen(
      (Position position) {
        _lastPosition = position;
        _locationController?.add(position);
      },
      onError: (error) {
        print('Error from location stream: $error');
        _locationController?.addError(error);
      },
    );
    
    _isTracking = true;
  }
  
  /// Stop tracking location
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationController?.close();
    _locationController = null;
    _isTracking = false;
  }
  
  /// Get the current position once (without starting a stream)
  Future<Position> getCurrentPosition() async {
    await initialize();
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: _accuracy,
    );
    _lastPosition = position;
    return position;
  }
  
  /// Convert a Position to a WorkoutPointModel
  WorkoutPointModel positionToWorkoutPoint(
    Position position, {
    required int workoutId,
    double? heartRate,
  }) {
    return WorkoutPointModel(
      workoutId: workoutId,
      latitude: position.latitude,
      longitude: position.longitude,
      elevation: position.altitude,
      timestamp: DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch),
      speed: position.speed, // m/s
      heartRate: heartRate,
    );
  }
  
  /// Calculate distance between two positions in meters
  double calculateDistance(Position position1, Position position2) {
    return Geolocator.distanceBetween(
      position1.latitude,
      position1.longitude,
      position2.latitude,
      position2.longitude,
    );
  }
  
  /// Dispose of resources
  void dispose() {
    stopTracking();
  }
}
