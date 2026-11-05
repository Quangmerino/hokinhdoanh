class UserModel {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String passwordHash;
  final String storeName;
  final String recoveryChannel; // 'sms', 'email', 'whatsapp', 'facebook'
  final String createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.passwordHash,
    required this.storeName,
    this.recoveryChannel = 'sms',
    required this.createdAt,
  });

  UserModel copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? passwordHash,
    String? storeName,
    String? recoveryChannel,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      storeName: storeName ?? this.storeName,
      recoveryChannel: recoveryChannel ?? this.recoveryChannel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'password_hash': passwordHash,
      'store_name': storeName,
      'recovery_channel': recoveryChannel,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int? ?? 0,
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      storeName: map['store_name'] as String? ?? '',
      recoveryChannel: map['recovery_channel'] as String? ?? 'sms',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
