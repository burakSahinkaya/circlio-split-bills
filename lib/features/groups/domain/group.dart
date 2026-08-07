import 'dart:math';
import '../../auth/domain/app_user.dart';

class Group {
  final String id;
  final String name;
  final String type; // e.g., 'trip', 'home', etc., mapped to icons
  final String currency;
  final List<String> memberIds;
  final List<String> pendingMemberIds;
  final List<String> leftMemberIds;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final int expenseRights;

  // We can keep `members` hydrated on the client if needed, or just fetch them separately.
  // For the domain logic, we will keep AppUser objects fully populated by the Service.
  final List<AppUser> members;

  /// Dummy members stored as a map {dummyId -> AppUser}. These are group-scoped
  /// guest members that don't have a Firebase Auth account.
  final Map<String, AppUser> dummyMembers;

  const Group({
    required this.id,
    required this.name,
    required this.type,
    this.currency = 'AUD',
    required this.memberIds,
    this.pendingMemberIds = const [],
    this.leftMemberIds = const [],
    this.photoUrl,
    required this.createdAt,
    this.lastActivityAt,
    this.expenseRights = 5,
    this.members = const [],
    this.dummyMembers = const {},
  });

  factory Group.fromJson(
    Map<String, dynamic> json, {
    required String id,
    List<AppUser> members = const [],
  }) {
    // Deserialise dummy members from Firestore and construct AppUser objects.
    final rawDummyMembers = json['dummyMembers'] as Map<String, dynamic>? ?? {};
    final dummyMemberMap = <String, AppUser>{};
    for (final entry in rawDummyMembers.entries) {
      final dummyData = Map<String, dynamic>.from(entry.value as Map);
      dummyData['id'] = entry.key;
      dummyData['email'] = '';
      dummyData['isDummy'] = true;
      dummyData['createdInGroupId'] = id;
      dummyMemberMap[entry.key] = AppUser.fromJson(dummyData);
    }

    // Merge real members with dummy members so the full members list is always complete.
    final allMembers = [...members, ...dummyMemberMap.values];

    return Group(
      id: id,
      name: json['name'] as String? ?? 'Unnamed Group',
      type: json['type'] as String? ?? 'default',
      currency: json['currency'] as String? ?? 'AUD',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      pendingMemberIds: List<String>.from(json['pendingMemberIds'] ?? []),
      leftMemberIds: List<String>.from(json['leftMemberIds'] ?? []),
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      lastActivityAt: json['lastActivityAt'] != null
          ? (json['lastActivityAt'] as dynamic).toDate()
          : null,
      expenseRights: max(0, json['expenseRights'] as int? ?? 5),
      members: allMembers,
      dummyMembers: dummyMemberMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'currency': currency,
      'memberIds': memberIds,
      'pendingMemberIds': pendingMemberIds,
      'leftMemberIds': leftMemberIds,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'lastActivityAt': lastActivityAt,
      'expenseRights': expenseRights,
      // dummyMembers is NOT written here — managed via FieldValue updates in GroupService.
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? type,
    String? currency,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
    List<String>? leftMemberIds,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    int? expenseRights,
    List<AppUser>? members,
    Map<String, AppUser>? dummyMembers,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      memberIds: memberIds ?? this.memberIds,
      pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
      leftMemberIds: leftMemberIds ?? this.leftMemberIds,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      expenseRights: expenseRights ?? this.expenseRights,
      members: members ?? this.members,
      dummyMembers: dummyMembers ?? this.dummyMembers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Group &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.currency == currency &&
      other.photoUrl == photoUrl &&
      other.lastActivityAt == lastActivityAt &&
      other.expenseRights == expenseRights;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      currency.hashCode ^
      photoUrl.hashCode ^
      lastActivityAt.hashCode ^
      expenseRights.hashCode;
  }
}
