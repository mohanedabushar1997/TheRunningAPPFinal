import 'dart:math';
import 'package:geolocator/geolocator.dart';
// TODO: Import User model or access UserProvider for user data (weight, height, etc.)

class CalculationService {
  // Calculate distance between two points using Haversine formula
  double calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    const R = 6371e3; // Earth radius in meters
    final phi1 = startLat * pi / 180; // φ, λ in radians
    final phi2 = endLat * pi / 180;
    final deltaPhi = (endLat - startLat) * pi / 180;
    final deltaLambda = (endLon - startLon) * pi / 180;

    final a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = R * c; // in meters
    return distance;
  }

  // Calculate total distance for a list of points
  double calculateTotalDistance(List<Position> points) {
    double totalDistance = 0;
    if (points.length < 2) {
      return 0;
    }
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return totalDistance; // in meters
  }

  // Calculate current pace (e.g., in seconds per kilometer)
  // Requires distance in meters and duration in seconds
  double calculatePace(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0 || durationSeconds <= 0) {
      return 0.0; // Avoid division by zero or nonsensical pace
    }
    double distanceKm = distanceMeters / 1000.0;
    double paceSecondsPerKm = durationSeconds / distanceKm;
    return paceSecondsPerKm;
  }

  // Calculate average speed (e.g., in kilometers per hour)
  // Requires distance in meters and duration in seconds
  double calculateAverageSpeed(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0 || durationSeconds <= 0) {
      return 0.0;
    }
    double distanceKm = distanceMeters / 1000.0;
    double durationHours = durationSeconds / 3600.0;
    double speedKph = distanceKm / durationHours;
    return speedKph;
  }

  // Calculate calories burned (Example using METs - Metabolic Equivalent of Task)
  // This is a simplified example and needs refinement based on Task 5.2.4
  // Requires user weight (kg), duration (hours), and MET value for the activity
  // TODO: Get user weight from UserProvider/UserModel
  // TODO: Determine MET value based on activity type and intensity (speed/pace)
  int calculateCaloriesBurned({
    required double userWeightKg,
    required double durationHours,
    required double metValue, // e.g., Running ~ 7.0-12.0 depending on speed
  }) {
    if (userWeightKg <= 0 || durationHours <= 0 || metValue <= 0) {
      return 0;
    }
    // Formula: Calories = MET * weight (kg) * duration (hours)
    double calories = metValue * userWeightKg * durationHours;
    return calories.round();
  }

  // TODO: Implement elevation gain/loss calculation (Task 5.2.5)
  // double calculateElevationGain(List<Position> points) { ... }

  // TODO: Implement smoothing algorithms for GPS jitter if needed (Task 5.2.2)
}
