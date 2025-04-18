import 'package:flutter/foundation.dart';
import 'workout_point_model.dart';

/// Enum representing different types of workouts
enum WorkoutType {
  run,
  walk,
  hike,
  cycle,
  treadmill,
  other
}

/// Extension to convert WorkoutType to/from string
extension WorkoutTypeExtension on WorkoutType {
  String toShortString() {
    return toString().split('.').last;
  }
  
  static WorkoutType fromString(String typeStr) {
    return WorkoutType.values.firstWhere(
      (e) => e.toShortString() == typeStr.toLowerCase(),
      orElse: () => WorkoutType.other,
    );
  }
}

/// Model representing a workout in the FitStride app
class WorkoutModel {
  final int? id; // Database ID (null for new workouts)
  final DateTime date; // Date and time when workout started
  final WorkoutType type; // Type of workout (run, walk, etc.)
  final Duration duration; // Total duration of workout
  final double? distance; // Total distance in kilometers
  final int? calories; // Estimated calories burned
  final double? avgPace; // Average pace in seconds per kilometer
  final double? avgSpeed; // Average speed in km/h
  final double? maxSpeed; // Maximum speed in km/h
  final double? elevationGain; // Total elevation gain in meters
  final double? elevationLoss; // Total elevation loss in meters
  final List<WorkoutPointModel> routePoints; // GPS points of the workout route
  final String? notes; // User notes about the workout
  final bool isManualEntry; // Whether this workout was manually entered
  
  const WorkoutModel({
    this.id,
    required this.date,
    required this.type,
    required this.duration,
    this.distance,
    this.calories,
    this.avgPace,
    this.avgSpeed,
    this.maxSpeed,
    this.elevationGain,
    this.elevationLoss,
    this.routePoints = const [],
    this.notes,
    this.isManualEntry = false,
  });
  
  /// Create a workout from a database map
  factory WorkoutModel.fromMap(Map<String, dynamic> map, {List<WorkoutPointModel>? points}) {
    return WorkoutModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      type: WorkoutTypeExtension.fromString(map['type'] as String),
      duration: Duration(seconds: map['duration'] as int),
      distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
      calories: map['calories'] as int?,
      avgPace: map['avg_pace'] != null ? (map['avg_pace'] as num).toDouble() : null,
      avgSpeed: map['avg_speed'] != null ? (map['avg_speed'] as num).toDouble() : null,
      maxSpeed: map['max_speed'] != null ? (map['max_speed'] as num).toDouble() : null,
      elevationGain: map['elevation_gain'] != null ? (map['elevation_gain'] as num).toDouble() : null,
      elevationLoss: map['elevation_loss'] != null ? (map['elevation_loss'] as num).toDouble() : null,
      routePoints: points ?? [],
      notes: map['notes'] as String?,
      isManualEntry: (map['is_manual_entry'] as int? ?? 0) == 1,
    );
  }
  
  /// Convert workout to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'type': type.toShortString(),
      'duration': duration.inSeconds,
      'distance': distance,
      'calories': calories,
      'avg_pace': avgPace,
      'avg_speed': avgSpeed,
      'max_speed': maxSpeed,
      'elevation_gain': elevationGain,
      'elevation_loss': elevationLoss,
      'notes': notes,
      'is_manual_entry': isManualEntry ? 1 : 0,
    };
  }
  
  /// Create a copy of this workout with modified fields
  WorkoutModel copyWith({
    int? id,
    DateTime? date,
    WorkoutType? type,
    Duration? duration,
    double? distance,
    int? calories,
    double? avgPace,
    double? avgSpeed,
    double? maxSpeed,
    double? elevationGain,
    double? elevationLoss,
    List<WorkoutPointModel>? routePoints,
    String? notes,
    bool? isManualEntry,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      avgPace: avgPace ?? this.avgPace,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      routePoints: routePoints ?? this.routePoints,
      notes: notes ?? this.notes,
      isManualEntry: isManualEntry ?? this.isManualEntry,
    );
  }
  
  /// Calculate metrics based on route points
  /// Returns a new WorkoutModel with calculated metrics
  WorkoutModel calculateMetrics() {
    if (routePoints.isEmpty) return this;
    
    // Sort points by timestamp
    final sortedPoints = List<WorkoutPointModel>.from(routePoints)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Calculate metrics
    double totalDistance = 0.0;
    double totalElevationGain = 0.0;
    double totalElevationLoss = 0.0;
    double? maxSpeedValue;
    
    for (int i = 1; i < sortedPoints.length; i++) {
      final prev = sortedPoints[i - 1];
      final curr = sortedPoints[i];
      
      // Update max speed
      if (curr.speed != null) {
        maxSpeedValue = maxSpeedValue == null 
            ? curr.speed 
            : (curr.speed! > maxSpeedValue ? curr.speed : maxSpeedValue);
      }
      
      // Calculate elevation changes
      if (prev.elevation != null && curr.elevation != null) {
        final elevDiff = curr.elevation! - prev.elevation!;
        if (elevDiff > 0) {
          totalElevationGain += elevDiff;
        } else {
          totalElevationLoss += elevDiff.abs();
        }
      }
      
      // Calculate distance between points using Haversine formula
      // This would typically be done by a dedicated service
      // For now, we'll assume the points already have calculated distances
      // and just use the speed and time difference as an approximation
      if (curr.speed != null) {
        final timeDiffSeconds = curr.timestamp.difference(prev.timestamp).inSeconds;
        totalDistance += (curr.speed! * timeDiffSeconds) / 1000; // Convert m/s to km
      }
    }
    
    // Calculate average speed and pace
    final durationHours = duration.inSeconds / 3600;
    final avgSpeedValue = distance != null && durationHours > 0 
        ? distance! / durationHours 
        : null;
    
    final avgPaceValue = distance != null && distance! > 0 
        ? duration.inSeconds / distance! 
        : null;
    
    // Calculate calories (simplified formula)
    // A more accurate calculation would be done by a dedicated service
    final caloriesValue = distance != null 
        ? (distance! * 60).round() // Very rough estimate: ~60 calories per km
        : null;
    
    return copyWith(
      distance: distance ?? totalDistance,
      elevationGain: totalElevationGain > 0 ? totalElevationGain : null,
      elevationLoss: totalElevationLoss > 0 ? totalElevationLoss : null,
      avgSpeed: avgSpeedValue,
      maxSpeed: maxSpeedValue,
      avgPace: avgPaceValue,
      calories: caloriesValue,
    );
  }
  
  @override
  String toString() {
    return 'WorkoutModel(id: $id, date: $date, type: $type, duration: $duration, distance: $distance)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutModel &&
        other.id == id &&
        other.date == date &&
        other.type == type &&
        other.duration == duration &&
        other.distance == distance &&
        other.calories == calories &&
        other.avgPace == avgPace &&
        other.avgSpeed == avgSpeed &&
        other.maxSpeed == maxSpeed &&
        other.elevationGain == elevationGain &&
        other.elevationLoss == elevationLoss &&
        listEquals(other.routePoints, routePoints) &&
        other.notes == notes &&
        other.isManualEntry == isManualEntry;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        type.hashCode ^
        duration.hashCode ^
        distance.hashCode ^
        calories.hashCode ^
        avgPace.hashCode ^
        avgSpeed.hashCode ^
        maxSpeed.hashCode ^
        elevationGain.hashCode ^
        elevationLoss.hashCode ^
        routePoints.hashCode ^
        notes.hashCode ^
        isManualEntry.hashCode;
  }
}
