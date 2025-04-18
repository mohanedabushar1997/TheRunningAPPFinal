// This is a basic Flutter widget test.

import 'dart:async'; // Import async
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator for Position and LocationAccuracy

import 'package:fitstride_app/main.dart';
import 'package:fitstride_app/services/location_service.dart'; // Import service interface
import 'package:fitstride_app/services/calculation_service.dart'; // Import service interface
import 'package:fitstride_app/services/audio_service.dart'; // Import service interface
import 'package:fitstride_app/views/splash_screen.dart'; // Import screen for verification
import 'package:fitstride_app/models/workout_point_model.dart'; // Import model
import 'package:fitstride_app/models/workout_model.dart'; // Import model for WorkoutType

// --- Dummy/Mock Service Implementations for testing ---

// Mock LocationService
class MockLocationService implements LocationService {
  @override
  Stream<Position>? get locationStream => Stream.empty(); // Return empty stream

  @override
  bool get isTracking => false; // Default value

  @override
  Position? get lastPosition => null; // Default value

  @override
  Future<void> initialize() async {}

  @override
  Future<void> startTracking() async {}

  @override
  void stopTracking() {}

  // Correct signature: returns non-nullable Future<Position>
  @override
  Future<Position> getCurrentPosition() async {
    // Return a dummy Position
    return Position(
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      isMocked: true,
    );
  }

  // Correct signature: includes heartRate parameter
  @override
  WorkoutPointModel positionToWorkoutPoint(
    Position position, {
    required int workoutId,
    double? heartRate,
  }) {
    // Return a dummy WorkoutPointModel
    return WorkoutPointModel(
      workoutId: workoutId,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp ?? DateTime.now(),
      elevation: position.altitude,
      speed: position.speed,
      heartRate: heartRate,
    );
  }

  @override
  double calculateDistance(Position start, Position end) => 0.0;

  // Correct signature: uses LocationAccuracy enum
  @override
  void setAccuracy(LocationAccuracy accuracy) {}

  @override
  void setUpdateInterval(int intervalMs) {}

  @override
  void dispose() {}
}

// Mock CalculationService
class MockCalculationService implements CalculationService {
  @override
  int calculateCaloriesBurned({
    required WorkoutType workoutType,
    required Duration duration,
    required double weightInKg,
    double? distanceInKm,
    // Add missing avgSpeedKmh parameter if it exists in the real interface
    // double? avgSpeedKmh,
  }) => 0; // Return 0 calories

  // Correct signature: returns non-nullable double
  @override
  double calculateSpeedFromPace(double paceSecondsPerKm) =>
      paceSecondsPerKm > 0 ? 3600 / paceSecondsPerKm : 0.0;

  // Correct signature: returns non-nullable double
  @override
  double calculatePaceFromSpeed(double speedKmh) =>
      speedKmh > 0 ? 3600 / speedKmh : 0.0;

  // Correct signature: uses named parameters
  @override
  double calculateAveragePace({
    required double distanceInKm,
    required Duration duration,
  }) => distanceInKm > 0 ? duration.inSeconds / distanceInKm : 0.0;

  // Correct signature: uses named parameters
  @override
  double calculateAverageSpeed({
    required double distanceInKm,
    required Duration duration,
  }) =>
      distanceInKm > 0 && duration.inSeconds > 0
          ? (distanceInKm / duration.inSeconds) * 3600
          : 0.0;

  // Correct signature: uses useImperial named parameter
  @override
  String formatDistance(double distanceInKm, {bool useImperial = false}) =>
      '${distanceInKm.toStringAsFixed(2)} ${useImperial ? "mi" : "km"}';

  @override
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  // Correct signature: uses useImperial named parameter
  @override
  String formatPace(double paceSecondsPerKm, {bool useImperial = false}) {
    if (paceSecondsPerKm.isNaN ||
        paceSecondsPerKm.isInfinite ||
        paceSecondsPerKm <= 0) {
      return useImperial ? '-:-- /mi' : '-:-- /km';
    }
    double pace = useImperial ? paceSecondsPerKm * 1.60934 : paceSecondsPerKm;
    final int minutes = pace ~/ 60;
    final int seconds = (pace % 60).round();
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')} ${useImperial ? "/mi" : "/km"}';
  }

  @override
  String formatSpeed(double speedKmh) => '${speedKmh.toStringAsFixed(1)} km/h';

  @override
  Map<String, dynamic> calculateWorkoutStats(
    List<WorkoutPointModel> points,
    Duration duration,
  ) => {}; // Return empty map

  // Add missing conversion methods
  @override
  double kilometersToMiles(double kilometers) => kilometers / 1.60934;

  @override
  double milesToKilometers(double miles) => miles * 1.60934;
}

// Mock AudioService
class MockAudioService implements AudioService {
  @override
  bool get isPlaying => false; // Default value

  @override
  Future<void> initialize() async {}

  @override
  Future<void> playVoiceCue(
    String cueType, {
    Map<String, dynamic>? data,
  }) async {}

  @override
  Future<void> play(String audioPath) async {} // Add missing method

  @override
  void clearQueue() {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

void main() {
  // Ensure bindings are initialized for async operations if needed before pumpWidget
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts and shows SplashScreen', (WidgetTester tester) async {
    // Create mock service instances
    final mockLocationService = MockLocationService();
    final mockCalculationService = MockCalculationService();
    final mockAudioService = MockAudioService();

    // Build our app and trigger a frame.
    // Provide the mock services to the FitStrideApp widget.
    await tester.pumpWidget(
      FitStrideApp(
        locationService: mockLocationService,
        calculationService: mockCalculationService,
        audioService: mockAudioService,
      ),
    );

    // Allow time for async operations in initState (like loading providers)
    // pumpAndSettle might be too long if there are timers, use pump for a short duration
    await tester.pump(const Duration(seconds: 1));

    // Verify that the SplashScreen is initially displayed.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
