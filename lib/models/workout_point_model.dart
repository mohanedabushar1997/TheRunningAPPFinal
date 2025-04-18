import 'package:flutter/foundation.dart';

/// Model representing a single GPS point during a workout tracking session
class WorkoutPointModel {
  final int? id; // Database ID (null for new points)
  final int workoutId; // Foreign key to the parent workout
  final double latitude; // GPS latitude
  final double longitude; // GPS longitude
  final double? elevation; // Elevation in meters (optional)
  final DateTime timestamp; // Time when this point was recorded
  final double? speed; // Instantaneous speed at this point (m/s)
  final double? heartRate; // Heart rate at this point (if available)
  
  const WorkoutPointModel({
    this.id,
    required this.workoutId,
    required this.latitude,
    required this.longitude,
    this.elevation,
    required this.timestamp,
    this.speed,
    this.heartRate,
  });
  
  /// Create a workout point from a database map
  factory WorkoutPointModel.fromMap(Map<String, dynamic> map) {
    return WorkoutPointModel(
      id: map['id'] as int?,
      workoutId: map['workout_id'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      elevation: map['elevation'] != null 
          ? (map['elevation'] as num).toDouble() 
          : null,
      timestamp: DateTime.parse(map['timestamp'] as String),
      speed: map['speed'] != null 
          ? (map['speed'] as num).toDouble() 
          : null,
      heartRate: map['heart_rate'] != null 
          ? (map['heart_rate'] as num).toDouble() 
          : null,
    );
  }
  
  /// Convert workout point to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'workout_id': workoutId,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heart_rate': heartRate,
    };
  }
  
  /// Create a copy of this workout point with modified fields
  WorkoutPointModel copyWith({
    int? id,
    int? workoutId,
    double? latitude,
    double? longitude,
    double? elevation,
    DateTime? timestamp,
    double? speed,
    double? heartRate,
  }) {
    return WorkoutPointModel(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      heartRate: heartRate ?? this.heartRate,
    );
  }
  
  @override
  String toString() {
    return 'WorkoutPointModel(id: $id, workoutId: $workoutId, lat: $latitude, lng: $longitude, time: $timestamp)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutPointModel &&
        other.id == id &&
        other.workoutId == workoutId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.elevation == elevation &&
        other.timestamp == timestamp &&
        other.speed == speed &&
        other.heartRate == heartRate;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        workoutId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        elevation.hashCode ^
        timestamp.hashCode ^
        speed.hashCode ^
        heartRate.hashCode;
  }
}
