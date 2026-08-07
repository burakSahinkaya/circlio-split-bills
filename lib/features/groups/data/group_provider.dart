import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/group.dart';
import 'group_service.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

final userGroupsProvider = StreamProvider<List<Group>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.streamUserGroups();
});

final pendingInvitesProvider = StreamProvider<List<Group>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.streamPendingInvites();
});

final leftGroupsProvider = StreamProvider<List<Group>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.streamLeftGroups();
});

final groupByIdProvider = Provider.family<Group?, String>((ref, id) {
  final groupsAsync = ref.watch(userGroupsProvider);
  return groupsAsync.value?.where((g) => g.id == id).firstOrNull;
});
