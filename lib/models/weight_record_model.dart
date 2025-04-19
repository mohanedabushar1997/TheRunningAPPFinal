import 'package:flutter/foundation.dart';

class WeightRecordModel {
  final int? id;
  final DateTime date;
  final double weight; // Assuming weight is stored in kg
  final String? notes;

  const WeightRecordModel({
    this.id,
    required this.date,
    required this.weight,
    this.notes,
  });

  // Convert a WeightRecordModel into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(), // Store date as ISO8601 string
      'weight': weight,
      'notes': notes,
    };
  }

  // Implement fromMap factory method
  factory WeightRecordModel.fromMap(Map<String, dynamic> map) {
    return WeightRecordModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      weight: (map['weight'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  // Implement copyWith
  WeightRecordModel copyWith({
    int? id,
    DateTime? date,
    double? weight,
    String? notes,
  }) {
    return WeightRecordModel(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'WeightRecordModel{id: $id, date: $date, weight: $weight, notes: $notes}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeightRecordModel &&
        other.id == id &&
        other.date == date &&
        other.weight == weight &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^ date.hashCode ^ weight.hashCode ^ notes.hashCode;
  }
}
