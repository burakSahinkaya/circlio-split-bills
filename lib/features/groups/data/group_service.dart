import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import '../../expenses/data/expenses_provider.dart';
import '../../expenses/domain/activity.dart';

import '../../auth/domain/app_user.dart';
import '../domain/group.dart';

/// Base URL for invite links hosted on Firebase Hosting.
const String _inviteLinkBase = 'https://splitcircle-7e06e.web.app/invite';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache to prevent blocking reactive streams with repeated user fetches
  final Map<String, AppUser> _userCache = {};

  String? get currentUserId => _auth.currentUser?.uid;

  /// Searches the `users` collection for users whose `username` starts with [query].
  Future<List<AppUser>> searchUsersByNickname(String query) async {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return [];

    // Prefix search in Firestore
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // ensure ID is passed
          return AppUser.fromJson(data);
        })
        .where((user) => user.id != currentUserId)
        .toList();
  }

  /// Creates a new group.
  Future<Group> createGroup({
    required String name,
    required String type,
    String currency = 'USD', // Default to USD
    File? groupPhoto,
    required List<String> invitedUserIds,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final groupId = const Uuid().v4();
    String? photoUrl;

    if (groupPhoto != null) {
      final ref = _storage.ref().child('group_photos').child('$groupId.jpg');
      await ref.putFile(groupPhoto);
      photoUrl = await ref.getDownloadURL();
    }

    final group = Group(
      id: groupId,
      name: name,
      type: type,
      currency: currency,
      memberIds: [uid],
      pendingMemberIds: invitedUserIds,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      expenseRights: 5,
    );

    await _firestore.collection('groups').doc(groupId).set(group.toJson());

    return group;
  }

  /// Streams groups where the current user is a member.
  Stream<List<Group>> streamUserGroups() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final groups = <Group>[];
          
          // 1. Identify all unique users needed across all groups
          final missingUserIds = <String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final memberIds = List<String>.from(data['memberIds'] ?? []);
            for (final mId in memberIds) {
              if (!_userCache.containsKey(mId)) {
                missingUserIds.add(mId);
              }
            }
          }

          // 2. Fetch missing users concurrently if any
          if (missingUserIds.isNotEmpty) {
            await Future.wait(missingUserIds.map((mId) async {
              try {
                // Try cache first, fallback to server automatically
                final userDoc = await _firestore.collection('users').doc(mId).get(const GetOptions(source: Source.serverAndCache));
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  userData['id'] = userDoc.id;
                  _userCache[mId] = AppUser.fromJson(userData);
                }
              } catch (e) {
                print('Failed to cache user $mId: $e');
              }
            }));
          }

          // 3. Build group objects synchronously instantly
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final memberIds = List<String>.from(data['memberIds'] ?? []);
            final members = memberIds
                .where((id) => _userCache.containsKey(id))
                .map((id) => _userCache[id]!)
                .toList();
            
            groups.add(Group.fromJson(data, id: doc.id, members: members));
          }

          // Sort locally by activity
          groups.sort((a, b) {
            final aTime = a.lastActivityAt ?? a.createdAt;
            final bTime = b.lastActivityAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });

          return groups;
        });
  }

  /// Streams groups where the current user is invited.
  Stream<List<Group>> streamPendingInvites() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('groups')
        .where('pendingMemberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map((doc) => Group.fromJson(doc.data(), id: doc.id))
              .toList();
          groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return groups;
        });
  }

  /// Streams groups where the current user has left.
  Stream<List<Group>> streamLeftGroups() {
    final uid = currentUserId;
    print('streamLeftGroups called for user: $uid');
    if (uid == null) {
      print('No current user, returning empty stream');
      return Stream.value([]);
    }

    print('Querying left groups for user: $uid');
    return _firestore
        .collection('groups')
        .where('leftMemberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          print('Left groups snapshot received: ${snapshot.docs.length} docs');
          final groups = snapshot.docs
              .map((doc) => Group.fromJson(doc.data(), id: doc.id))
              .toList();
          groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          print('Left groups processed: ${groups.length} groups');
          return groups;
        });
  }

  /// Accepts an invite to a group.
  Future<void> acceptInvite(String groupId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    await _firestore.collection('groups').doc(groupId).update({
      'pendingMemberIds': FieldValue.arrayRemove([uid]),
      'memberIds': FieldValue.arrayUnion([uid]),
    });
  }

  /// Declines an invite to a group.
  Future<void> declineInvite(String groupId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    await _firestore.collection('groups').doc(groupId).update({
      'pendingMemberIds': FieldValue.arrayRemove([uid]),
    });
  }

  /// Leaves a group.
  Future<void> leaveGroup(String groupId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    // Get user info before leaving
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userName = userDoc.exists
        ? (userDoc.data()!['name'] as String? ?? 'Someone')
        : 'Someone';

    // Update group first (this is the critical part)
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'leftMemberIds': FieldValue.arrayUnion([uid]),
    });

    // Add activity separately (don't let this fail the main operation)
    try {
      await addMemberLeftActivity(
        groupId: groupId,
        userId: uid,
        userName: userName,
      );
    } catch (e) {
      // Log the error but don't rethrow - the user has already left the group
      print('Failed to add activity: $e');
    }
  }

  /// Deletes a group for a user who has left it.
  Future<void> deleteLeftGroup(String groupId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    // Remove the group from the user's left groups
    await _firestore.collection('groups').doc(groupId).update({
      'leftMemberIds': FieldValue.arrayRemove([uid]),
    });
  }

  /// Invites a user to a group.
  Future<void> inviteUserToGroup(String groupId, String userId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    await _firestore.collection('groups').doc(groupId).update({
      'pendingMemberIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Resets the unread count for a specific group for the current user.
  Future<void> resetGroupUnreadCount(String groupId) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});
      final countToReset = unreadCounts[groupId] ?? 0;

      if (countToReset == 0) return; // Nothing to reset

      // Update map and total count
      unreadCounts[groupId] = 0;
      final newTotal = (data['totalUnreadCount'] as int? ?? 0) - countToReset;
      final safeTotal = newTotal > 0 ? newTotal : 0;

      await userRef.update({
        'unreadCounts': unreadCounts,
        'totalUnreadCount': safeTotal,
      });

      // Update OS badge natively
      try {
        if (safeTotal == 0) {
          FlutterAppBadger.removeBadge();
        } else {
          FlutterAppBadger.updateBadgeCount(safeTotal);
        }
      } catch (e) {
        print('Failed to update app badger: $e');
      }
    } catch (e) {
      print('Failed to reset group unread count: $e');
    }
  }

  // ─── Invite Link Methods ──────────────────────────────────────────

  /// Generates a short 8-character alphanumeric invite code.
  String _generateShortCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I/1/O/0 to avoid confusion
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Generates (or retrieves an existing) invite link for a group.
  /// Returns the full shareable URL.
  Future<String> generateInviteLink(String groupId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    // Check if an active invite already exists for this group
    final existing = await _firestore
        .collection('group_invites')
        .where('groupId', isEqualTo: groupId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final code = existing.docs.first.id;
      return '$_inviteLinkBase/$code';
    }

    // Generate a new unique invite code
    String code;
    bool codeExists;
    do {
      code = _generateShortCode();
      final doc = await _firestore.collection('group_invites').doc(code).get();
      codeExists = doc.exists;
    } while (codeExists);

    // Store the invite
    await _firestore.collection('group_invites').doc(code).set({
      'groupId': groupId,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    return '$_inviteLinkBase/$code';
  }

  /// Fetches group info for a given invite code.
  /// Returns null if the code is invalid or inactive.
  Future<Group?> getGroupByInviteCode(String code) async {
    final doc = await _firestore.collection('group_invites').doc(code.toUpperCase()).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    if (data['isActive'] != true) return null;

    final groupId = data['groupId'] as String;
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return null;

    return Group.fromJson(groupDoc.data()!, id: groupDoc.id);
  }

  /// Joins a group using an invite code.
  /// Returns the group ID on success.
  Future<String> joinGroupByInviteCode(String code) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final doc = await _firestore.collection('group_invites').doc(code.toUpperCase()).get();
    if (!doc.exists) throw Exception('Invalid invite code');

    final data = doc.data()!;
    if (data['isActive'] != true) throw Exception('This invite link is no longer active');

    final groupId = data['groupId'] as String;

    // Check if the user is already a member
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw Exception('Group no longer exists');

    final memberIds = List<String>.from(groupDoc.data()!['memberIds'] ?? []);
    if (memberIds.contains(uid)) throw Exception('You are already a member of this group');

    // Add user to group, remove from pending/left if present
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'pendingMemberIds': FieldValue.arrayRemove([uid]),
      'leftMemberIds': FieldValue.arrayRemove([uid]),
    });

    // Add "member joined" activity
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userName = userDoc.exists
          ? (userDoc.data()!['displayName'] as String? ??
              userDoc.data()!['name'] as String? ??
              'Someone')
          : 'Someone';

      await addActivityToFirestore(
        groupId: groupId,
        type: ActivityType.memberJoined,
        description: '$userName joined the group via invite link',
        userId: uid,
        userName: userName,
      );
    } catch (e) {
      print('Failed to add join activity: $e');
    }

    return groupId;
  }

  // ─── Dummy Member Methods ─────────────────────────────────────────

  /// Creates a dummy (guest) member in a group.
  /// The dummy member is stored in the group document's `dummyMembers` map
  /// and their ID is also added to `memberIds` so they appear in all expense/balance logic.
  Future<AppUser> createDummyMember({
    required String groupId,
    required String name,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final dummyId = 'dummy_${const Uuid().v4()}';
    final now = FieldValue.serverTimestamp();

    // Write the dummy member data into the group doc.
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([dummyId]),
      'dummyMembers.$dummyId': {
        'name': name,
        'createdBy': uid,
        'createdAt': now,
        'isDummy': true,
      },
    });

    return AppUser(
      id: dummyId,
      name: name,
      email: '',
      isDummy: true,
      createdInGroupId: groupId,
    );
  }

  /// Removes a dummy member from a group.
  /// Removes them from `dummyMembers` map and from `memberIds`.
  Future<void> deleteDummyMember({
    required String groupId,
    required String dummyId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([dummyId]),
      'dummyMembers.$dummyId': FieldValue.delete(),
    });
  }
}
