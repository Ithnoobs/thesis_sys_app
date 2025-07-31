class User {
  final int? id;
  final String name;
  final String email;
  final String? role;
  final String? department;
  final bool? forceLogout;
  final bool? allowAccess;
  final String? profilePicture;
  final DateTime? emailVerifiedAt;

  // Optional: only used for login/register
  String? password;

  User({
    this.id,
    required this.name,
    required this.email,
    this.role,
    this.department,
    this.forceLogout,
    this.allowAccess,
    this.profilePicture,
    this.emailVerifiedAt,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      department: json['department'],
      forceLogout: json['force_logout'],
      allowAccess: json['allow_access'],
      profilePicture: json['profile_picture'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includePassword = false}) {
    final data = {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'force_logout': forceLogout,
      'allow_access': allowAccess,
      'profile_picture': profilePicture,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
    };

    if (includePassword && password != null) {
      data['password'] = password;
    }

    return data;
  }
}
