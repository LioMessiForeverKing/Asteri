class MatchCandidate {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String starColor;
  final List<String> interests;
  final List<String> sharedInterests; // up to 3
  final int scorePercent; // 10..100 range per plan
  final int stars; // 1..5

  const MatchCandidate({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.starColor,
    required this.interests,
    required this.sharedInterests,
    required this.scorePercent,
    required this.stars,
  });

  factory MatchCandidate.fromMap(Map<String, dynamic> map) {
    return MatchCandidate(
      userId: (map['user_id'] ?? map['id']).toString(),
      fullName: (map['full_name'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] as String?)?.isEmpty == true
          ? null
          : map['avatar_url'] as String?,
      starColor: (map['star_color'] ?? '#FFFFFF').toString(),
      interests: (map['interests'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      sharedInterests: (map['shared_interests'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      scorePercent: (map['scorePercent'] is num)
          ? (map['scorePercent'] as num).round()
          : 0,
      stars: (map['stars'] is num) ? (map['stars'] as num).round() : 1,
    );
  }
}


