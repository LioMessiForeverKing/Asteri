class Profile {
  final String id;
  final String fullName;
  final String?
  avatarUrl; // Storage object path, e.g. profiles/<uid>/avatar.jpg
  final String starColor; // HEX like #RRGGBB
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.starColor,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      starColor.trim().isNotEmpty &&
      avatarUrl != null &&
      avatarUrl!.trim().isNotEmpty;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? '') as String,
      avatarUrl: map['avatar_url'] as String?,
      starColor: (map['star_color'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'star_color': starColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
