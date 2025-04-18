import 'package:flutter/foundation.dart';
import '../models/workout_model.dart';

/// Service for calculating various fitness metrics
class CalculationService {
  // Constants for calculations
  static const double _metToKcalRunning = 1.0; // MET value for running per minute per kg
  static const double _metToKcalWalking = 0.7; // MET value for walking per minute per kg
  
  /// Calculate pace in seconds per kilometer from speed in m/s
  double calculatePaceFromSpeed(double speedInMetersPerSecond) {
    if (speedInMetersPerSecond <= 0) return 0;
    // Convert m/s to seconds per kilometer
    return 1000 / speedInMetersPerSecond;
  }
  
  /// Calculate speed in m/s from pace in seconds per kilometer
  double calculateSpeedFromPace(double paceInSecondsPerKm) {
    if (paceInSecondsPerKm <= 0) return 0;
    // Convert seconds per kilometer to m/s
    return 1000 / paceInSecondsPerKm;
  }
  
  /// Format pace as a string (e.g., "5:30 /km")
  String formatPace(double paceInSecondsPerKm, {bool useImperial = false}) {
    if (paceInSecondsPerKm <= 0) return "--:-- /km";
    
    // Convert to minutes and seconds
    int totalSeconds = paceInSecondsPerKm.round();
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    
    // If using imperial (miles), convert
    if (useImperial) {
      // 1 mile = 1.60934 km
      totalSeconds = (paceInSecondsPerKm * 1.60934).round();
      minutes = totalSeconds ~/ 60;
      seconds = totalSeconds % 60;
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} /mi";
    }
    
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} /km";
  }
  
  /// Calculate calories burned based on workout data and user weight
  int calculateCaloriesBurned({
    required WorkoutType workoutType,
    required Duration duration,
    required double weightInKg,
    double? distanceInKm,
  }) {
    // Basic calculation based on MET values
    // MET = Metabolic Equivalent of Task
    // Calories = MET * weight in kg * duration in hours
    
    final durationInMinutes = duration.inSeconds / 60;
    if (durationInMinutes <= 0 || weightInKg <= 0) return 0;
    
    double metValue;
    
    switch (workoutType) {
      case WorkoutType.run:
        metValue = _metToKcalRunning;
        // Adjust based on pace if distance is available
        if (distanceInKm != null && distanceInKm > 0) {
          final paceMinPerKm = (duration.inSeconds / 60) / distanceInKm;
          // Adjust MET based on pace
          if (paceMinPerKm < 4) { // Very fast running
            metValue = 1.2;
          } else if (paceMinPerKm < 5) { // Fast running
            metValue = 1.1;
          } else if (paceMinPerKm < 6) { // Moderate running
            metValue = 1.0;
          } else if (paceMinPerKm < 7) { // Slow running
            metValue = 0.9;
          } else { // Very slow running / jogging
            metValue = 0.8;
          }
        }
        break;
      case WorkoutType.walk:
        metValue = _metToKcalWalking;
        break;
      case WorkoutType.hike:
        metValue = 0.85; // Hiking has higher MET than walking
        break;
      case WorkoutType.cycle:
        metValue = 0.75; // Cycling MET
        break;
      case WorkoutType.treadmill:
        metValue = 0.95; // Slightly less than outdoor running
        break;
      case WorkoutType.other:
      default:
        metValue = 0.8; // Default moderate activity
        break;
    }
    
    // Calculate calories
    final calories = metValue * weightInKg * (durationInMinutes / 60);
    return calories.round();
  }
  
  /// Convert kilometers to miles
  double kilometersToMiles(double kilometers) {
    return kilometers / 1.60934;
  }
  
  /// Convert miles to kilometers
  double milesToKilometers(double miles) {
    return miles * 1.60934;
  }
  
  /// Format distance with appropriate unit
  String formatDistance(double distanceInKm, {bool useImperial = false}) {
    if (distanceInKm <= 0) return "0.00 km";
    
    if (useImperial) {
      final miles = kilometersToMiles(distanceInKm);
      return "${miles.toStringAsFixed(2)} mi";
    }
    
    return "${distanceInKm.toStringAsFixed(2)} km";
  }
  
  /// Format duration as a string (e.g., "1:23:45")
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }
  
  /// Calculate average pace for a workout
  double calculateAveragePace({
    required double distanceInKm,
    required Duration duration,
  }) {
    if (distanceInKm <= 0) return 0;
    return duration.inSeconds / distanceInKm;
  }
  
  /// Calculate average speed for a workout in km/h
  double calculateAverageSpeed({
    required double distanceInKm,
    required Duration duration,
  }) {
    if (duration.inSeconds <= 0) return 0;
    return (distanceInKm / duration.inSeconds) * 3600;
  }
}
