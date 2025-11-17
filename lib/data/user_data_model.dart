class UserData {
  final String name;
  final String valueGoal;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserData({
    required this.name,
    required this.valueGoal,
    required this.createdAt,
    this.updatedAt,
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'valueGoal': valueGoal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // JSON 역직렬화
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
      valueGoal: json['valueGoal'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // 데이터 복사 (업데이트용)
  UserData copyWith({
    String? name,
    String? valueGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserData(
      name: name ?? this.name,
      valueGoal: valueGoal ?? this.valueGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserData(name: $name, valueGoal: $valueGoal, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.name == name &&
        other.valueGoal == valueGoal &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        valueGoal.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
