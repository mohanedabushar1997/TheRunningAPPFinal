import 'package:flutter/foundation.dart';

/// Model representing a training session within a training plan
class TrainingSessionModel {
  final int? id; // Database ID (null for new sessions)
  final int planId; // Foreign key to the parent training plan
  final int dayNumber; // Day number within the plan (1-based)
  final String description; // Description of the training session
  final String? intervals; // Interval structure (if applicable)
  final double? targetDistance; // Target distance in kilometers (if applicable)
  final Duration? targetDuration; // Target duration (if applicable)
  final bool isCompleted; // Whether this session has been completed
  final DateTime? completedDate; // When this session was completed (if applicable)
  
  const TrainingSessionModel({
    this.id,
    required this.planId,
    required this.dayNumber,
    required this.description,
    this.intervals,
    this.targetDistance,
    this.targetDuration,
    this.isCompleted = false,
    this.completedDate,
  });
  
  /// Create a training session from a database map
  factory TrainingSessionModel.fromMap(Map<String, dynamic> map) {
    return TrainingSessionModel(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      dayNumber: map['day_number'] as int,
      description: map['description'] as String? ?? '',
      intervals: map['intervals'] as String?,
      targetDistance: map['target_distance'] != null 
          ? (map['target_distance'] as num).toDouble() 
          : null,
      targetDuration: map['target_duration'] != null 
          ? Duration(seconds: map['target_duration'] as int) 
          : null,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedDate: map['completed_date'] != null 
          ? DateTime.parse(map['completed_date'] as String) 
          : null,
    );
  }
  
  /// Convert training session to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'day_number': dayNumber,
      'description': description,
      'intervals': intervals,
      'target_distance': targetDistance,
      'target_duration': targetDuration?.inSeconds,
      'is_completed': isCompleted ? 1 : 0,
      'completed_date': completedDate?.toIso8601String(),
    };
  }
  
  /// Create a copy of this training session with modified fields
  TrainingSessionModel copyWith({
    int? id,
    int? planId,
    int? dayNumber,
    String? description,
    String? intervals,
    double? targetDistance,
    Duration? targetDuration,
    bool? isCompleted,
    DateTime? completedDate,
    bool clearCompletedDate = false,
  }) {
    return TrainingSessionModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      description: description ?? this.description,
      intervals: intervals ?? this.intervals,
      targetDistance: targetDistance ?? this.targetDistance,
      targetDuration: targetDuration ?? this.targetDuration,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: clearCompletedDate ? null : (completedDate ?? this.completedDate),
    );
  }
  
  /// Mark this session as completed
  TrainingSessionModel markCompleted({DateTime? completedDate}) {
    return copyWith(
      isCompleted: true,
      completedDate: completedDate ?? DateTime.now(),
    );
  }
  
  /// Mark this session as not completed
  TrainingSessionModel markNotCompleted() {
    return copyWith(
      isCompleted: false,
      clearCompletedDate: true,
    );
  }
  
  /// Get the week number of this session within the plan
  int get weekNumber {
    return ((dayNumber - 1) / 7).floor() + 1;
  }
  
  /// Get the day of week (1-7, where 1 is Monday) for this session
  int get dayOfWeek {
    return ((dayNumber - 1) % 7) + 1;
  }
  
  @override
  String toString() {
    return 'TrainingSessionModel(id: $id, planId: $planId, day: $dayNumber, completed: $isCompleted)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingSessionModel &&
        other.id == id &&
        other.planId == planId &&
        other.dayNumber == dayNumber &&
        other.description == description &&
        other.intervals == intervals &&
        other.targetDistance == targetDistance &&
        other.targetDuration == targetDuration &&
        other.isCompleted == isCompleted &&
        other.completedDate == completedDate;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        planId.hashCode ^
        dayNumber.hashCode ^
        description.hashCode ^
        intervals.hashCode ^
        targetDistance.hashCode ^
        targetDuration.hashCode ^
        isCompleted.hashCode ^
        completedDate.hashCode;
  }
}
