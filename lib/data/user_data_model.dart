class UserData {
  final String name;
<<<<<<< HEAD
  final String coreValue;
=======
  final String valueGoal;
>>>>>>> 7cf0a32 (1118 통합)
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserData({
    required this.name,
<<<<<<< HEAD
    required this.coreValue,
=======
    required this.valueGoal,
>>>>>>> 7cf0a32 (1118 통합)
    required this.createdAt,
    this.updatedAt,
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'name': name,
<<<<<<< HEAD
      'coreValue': coreValue,
=======
      'valueGoal': valueGoal,
>>>>>>> 7cf0a32 (1118 통합)
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // JSON 역직렬화
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
<<<<<<< HEAD
      coreValue: json['coreValue'] ?? '',
=======
      valueGoal: json['valueGoal'] ?? '',
>>>>>>> 7cf0a32 (1118 통합)
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // 데이터 복사 (업데이트용)
  UserData copyWith({
    String? name,
<<<<<<< HEAD
    String? coreValue,
=======
    String? valueGoal,
>>>>>>> 7cf0a32 (1118 통합)
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserData(
      name: name ?? this.name,
<<<<<<< HEAD
      coreValue: coreValue ?? this.coreValue,
=======
      valueGoal: valueGoal ?? this.valueGoal,
>>>>>>> 7cf0a32 (1118 통합)
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
<<<<<<< HEAD
    return 'UserData(name: $name, coreValue: $coreValue, createdAt: $createdAt, updatedAt: $updatedAt)';
=======
    return 'UserData(name: $name, valueGoal: $valueGoal, createdAt: $createdAt, updatedAt: $updatedAt)';
>>>>>>> 7cf0a32 (1118 통합)
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.name == name &&
<<<<<<< HEAD
        other.coreValue == coreValue &&
=======
        other.valueGoal == valueGoal &&
>>>>>>> 7cf0a32 (1118 통합)
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return name.hashCode ^
<<<<<<< HEAD
        coreValue.hashCode ^
=======
        valueGoal.hashCode ^
>>>>>>> 7cf0a32 (1118 통합)
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
