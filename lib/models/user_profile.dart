class UserProfile {
  final int? id; // null before insert, assigned by sqlite
  final String mobile;
  final String countryCode;
  final String name;
  final String? email;
  final String? avatarPath;
  final String? city;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    required this.mobile,
    required this.countryCode,
    required this.name,
    this.email,
    this.avatarPath,
    this.city,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    int? id,
    String? mobile,
    String? countryCode,
    String? name,
    String? email,
    String? avatarPath,
    String? city,
    DateTime? updatedAt,
    bool clearEmail = false,
    bool clearAvatar = false,
    bool clearCity = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      mobile: mobile ?? this.mobile,
      countryCode: countryCode ?? this.countryCode,
      name: name ?? this.name,
      email: clearEmail ? null : (email ?? this.email),
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      city: clearCity ? null : (city ?? this.city),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'mobile': mobile,
        'countryCode': countryCode,
        'name': name,
        'email': email,
        'avatarPath': avatarPath,
        'city': city,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as int?,
        mobile: m['mobile'] as String,
        countryCode: m['countryCode'] as String,
        name: m['name'] as String,
        email: m['email'] as String?,
        avatarPath: m['avatarPath'] as String?,
        city: m['city'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  String get fullPhone => '$countryCode$mobile';

  /// Stable identifier for prefs lookups: "+91 9876543210".
  String get accountKey => '$countryCode|$mobile';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
