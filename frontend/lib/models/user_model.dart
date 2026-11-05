class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String currency;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.currency,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      currency: json['currency'] ?? 'INR',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'currency': currency,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? currency,
    String? email,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      currency: currency ?? this.currency,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

