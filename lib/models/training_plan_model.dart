import 'package:flutter/foundation.dart';
import 'training_session_model.dart';

/// Enum representing different difficulty levels for training plans
enum TrainingPlanLevel {
  beginner,
  intermediate,
  advanced,
  expert
}

/// Extension to convert TrainingPlanLevel to/from string
extension TrainingPlanLevelExtension on TrainingPlanLevel {
  String toShortString() {
    return toString().split('.').last;
  }
  
  static TrainingPlanLevel fromString(String levelStr) {
    return TrainingPlanLevel.values.firstWhere(
      (e) => e.toShortString().toLowerCase() == levelStr.toLowerCase(),
      orElse: () => TrainingPlanLevel.beginner,
    );
  }
}

/// Model representing a training plan in the FitStride app
class TrainingPlanModel {
  final int? id; // Database ID (null for new plans)
  final String name; // Name of the training plan
  final TrainingPlanLevel level; // Difficulty level
  final String description; // Detailed description of the plan
  final int durationWeeks; // Duration in weeks
  final String? goalType; // Type of goal (e.g., "5K", "10K", "Half Marathon")
  final List<TrainingSessionModel> sessions; // Training sessions in this plan
  final bool isActive; // Whether this plan is currently active for the user
  final DateTime? startDate; // When the user started this plan (if active)
  
  const TrainingPlanModel({
    this.id,
    required this.name,
    required this.level,
    required this.description,
    required this.durationWeeks,
    this.goalType,
    this.sessions = const [],
    this.isActive = false,
    this.startDate,
  });
  
  /// Create a training plan from a database map
  factory TrainingPlanModel.fromMap(Map<String, dynamic> map, {List<TrainingSessionModel>? sessions}) {
    return TrainingPlanModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      level: TrainingPlanLevelExtension.fromString(map['level'] as String),
      description: map['description'] as String? ?? '',
      durationWeeks: map['duration_weeks'] as int,
      goalType: map['goal_type'] as String?,
      sessions: sessions ?? [],
      isActive: (map['is_active'] as int? ?? 0) == 1,
      startDate: map['start_date'] != null 
          ? DateTime.parse(map['start_date'] as String) 
          : null,
    );
  }
  
  /// Convert training plan to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'level': level.toShortString(),
      'description': description,
      'duration_weeks': durationWeeks,
      'goal_type': goalType,
      'is_active': isActive ? 1 : 0,
      'start_date': startDate?.toIso8601String(),
    };
  }
  
  /// Create a copy of this training plan with modified fields
  TrainingPlanModel copyWith({
    int? id,
    String? name,
    TrainingPlanLevel? level,
    String? description,
    int? durationWeeks,
    String? goalType,
    List<TrainingSessionModel>? sessions,
    bool? isActive,
    DateTime? startDate,
    bool clearStartDate = false,
  }) {
    return TrainingPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      description: description ?? this.description,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      goalType: goalType ?? this.goalType,
      sessions: sessions ?? this.sessions,
      isActive: isActive ?? this.isActive,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
    );
  }
  
  /// Activate this training plan with the given start date
  TrainingPlanModel activate({DateTime? startDate}) {
    return copyWith(
      isActive: true,
      startDate: startDate ?? DateTime.now(),
    );
  }
  
  /// Deactivate this training plan
  TrainingPlanModel deactivate() {
    return copyWith(
      isActive: false,
      clearStartDate: true,
    );
  }
  
  /// Get the end date of this training plan (if active)
  DateTime? get endDate {
    if (startDate == null) return null;
    return startDate!.add(Duration(days: durationWeeks * 7));
  }
  
  /// Get the current week number of this training plan (if active)
  int? get currentWeek {
    if (startDate == null) return null;
    final daysSinceStart = DateTime.now().difference(startDate!).inDays;
    final weekNumber = (daysSinceStart / 7).floor() + 1;
    return weekNumber > durationWeeks ? durationWeeks : weekNumber;
  }
  
  /// Get the completion percentage of this training plan (if active)
  double? get completionPercentage {
    if (startDate == null) return null;
    final totalDays = durationWeeks * 7;
    final daysSinceStart = DateTime.now().difference(startDate!).inDays;
    return (daysSinceStart / totalDays).clamp(0.0, 1.0);
  }
  
  /// Get sessions for a specific week
  List<TrainingSessionModel> getSessionsForWeek(int weekNumber) {
    if (weekNumber < 1 || weekNumber > durationWeeks) return [];
    
    return sessions.where((session) {
      final sessionWeek = ((session.dayNumber - 1) / 7).floor() + 1;
      return sessionWeek == weekNumber;
    }).toList();
  }
  
  @override
  String toString() {
    return 'TrainingPlanModel(id: $id, name: $name, level: $level, weeks: $durationWeeks, active: $isActive)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingPlanModel &&
        other.id == id &&
        other.name == name &&
        other.level == level &&
        other.description == description &&
        other.durationWeeks == durationWeeks &&
        other.goalType == goalType &&
        listEquals(other.sessions, sessions) &&
        other.isActive == isActive &&
        other.startDate == startDate;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        level.hashCode ^
        description.hashCode ^
        durationWeeks.hashCode ^
        goalType.hashCode ^
        sessions.hashCode ^
        isActive.hashCode ^
        startDate.hashCode;
  }
}
