class UserModel {
  final int? id; // Database ID (optional, useful after retrieval)
  final String deviceId; // Mandatory unique identifier
  final String? name;
  final String? gender;
  final double? height; // Consider units (cm? inches?)
  final double? weight; // Consider units (kg? lbs?)
  final DateTime? birthDate;

  UserModel({
    this.id,
    required this.deviceId,
    this.name,
    this.gender,
    this.height,
    this.weight,
    this.birthDate,
  });

  // Convert a UserModel into a Map. Keys must correspond to DB column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id, // May be null if not yet inserted
      'device_id': deviceId,
      'name': name,
      'gender': gender,
      'height': height,
      'weight': weight,
      // Store dates as ISO 8601 strings in the database for consistency
      'birth_date': birthDate?.toIso8601String(),
    };
  }

  // Create a UserModel from a Map retrieved from the database.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      deviceId: map['device_id'] as String,
      name: map['name'] as String?,
      gender: map['gender'] as String?,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      birthDate:
          map['birth_date'] != null
              ? DateTime.tryParse(map['birth_date'] as String)
              : null,
    );
  }

  // Optional: CopyWith method for easier updates
  UserModel copyWith({
    int? id,
    String? deviceId,
    String? name,
    String? gender,
    double? height,
    double? weight,
    DateTime? birthDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, deviceId: $deviceId, name: $name, gender: $gender, height: $height, weight: $weight, birthDate: $birthDate)';
  }
}
