class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? username;
  final List<String>? fcmTokens;
  final int totalUnreadCount;
  final Map<String, int> unreadCounts;
  /// True for guest/dummy members that exist only within a group.
  /// They have no Firebase Auth account and cannot log in.
  final bool isDummy;
  /// The group this dummy member was created in (only set when isDummy == true).
  final String? createdInGroupId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.username,
    this.fcmTokens,
    this.totalUnreadCount = 0,
    this.unreadCounts = const {},
    this.isDummy = false,
    this.createdInGroupId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      name: json['displayName'] as String? ?? json['name'] as String? ?? 'Unknown User',
      email: json['email'] as String? ?? '',
      avatarUrl: json['photoUrl'] as String? ?? json['avatarUrl'] as String?,
      username: json['username'] as String?,
      fcmTokens: (json['fcmTokens'] as List<dynamic>?)?.map((e) => e as String).toList(),
      totalUnreadCount: json['totalUnreadCount'] as int? ?? 0,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      isDummy: json['isDummy'] as bool? ?? false,
      createdInGroupId: json['createdInGroupId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'username': username,
      'fcmTokens': fcmTokens,
      'totalUnreadCount': totalUnreadCount,
      'unreadCounts': unreadCounts,
      'isDummy': isDummy,
      'createdInGroupId': createdInGroupId,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? username,
    List<String>? fcmTokens,
    int? totalUnreadCount,
    Map<String, int>? unreadCounts,
    bool? isDummy,
    String? createdInGroupId,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isDummy: isDummy ?? this.isDummy,
      createdInGroupId: createdInGroupId ?? this.createdInGroupId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppUser && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
