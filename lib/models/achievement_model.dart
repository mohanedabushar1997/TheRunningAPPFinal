import 'package:flutter/foundation.dart';

/// Model representing an achievement in the FitStride app
class AchievementModel {
  final int? id; // Database ID (null for new achievements)
  final String name; // Unique name of the achievement
  final String description; // Description of what the achievement represents
  final String icon; // Icon asset path for the achievement
  final DateTime? achievedDate; // Date when achievement was unlocked (null if not achieved)
  final double progressValue; // Current progress towards achievement (0.0 to 1.0)
  final String category; // Category of achievement (distance, workout, streak, etc.)
  
  const AchievementModel({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.achievedDate,
    this.progressValue = 0.0,
    required this.category,
  });
  
  /// Create an achievement from a database map
  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      achievedDate: map['achieved_date'] != null 
          ? DateTime.parse(map['achieved_date'] as String) 
          : null,
      progressValue: map['progress_value'] != null 
          ? (map['progress_value'] as num).toDouble() 
          : 0.0,
      category: map['category'] as String? ?? 'general',
    );
  }
  
  /// Convert achievement to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'achieved_date': achievedDate?.toIso8601String(),
      'progress_value': progressValue,
      'category': category,
    };
  }
  
  /// Create a copy of this achievement with modified fields
  AchievementModel copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    DateTime? achievedDate,
    double? progressValue,
    String? category,
    bool clearAchievedDate = false,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      achievedDate: clearAchievedDate ? null : (achievedDate ?? this.achievedDate),
      progressValue: progressValue ?? this.progressValue,
      category: category ?? this.category,
    );
  }
  
  /// Update achievement progress and unlock if 100% complete
  AchievementModel updateProgress(double newProgress) {
    final clampedProgress = newProgress.clamp(0.0, 1.0);
    final DateTime? newAchievedDate = 
        (clampedProgress >= 1.0 && achievedDate == null) 
            ? DateTime.now() 
            : achievedDate;
            
    return copyWith(
      progressValue: clampedProgress,
      achievedDate: newAchievedDate,
    );
  }
  
  @override
  String toString() {
    return 'AchievementModel(id: $id, name: $name, achieved: ${achievedDate != null}, progress: $progressValue)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.icon == icon &&
        other.achievedDate == achievedDate &&
        other.progressValue == progressValue &&
        other.category == category;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        icon.hashCode ^
        achievedDate.hashCode ^
        progressValue.hashCode ^
        category.hashCode;
  }
}
