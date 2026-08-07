import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_provider.dart';
import '../data/group_provider.dart';
import '../../expenses/data/expenses_provider.dart';
import '../domain/group.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../core/utils/currency_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);
    final invitesAsync = ref.watch(pendingInvitesProvider);
    final leftGroupsAsync = ref.watch(leftGroupsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    // Debug logging
    print(
      'HomeScreen - leftGroupsAsync: ${leftGroupsAsync.value?.length ?? 0} left groups',
    );

    final currentUser = currentUserAsync.value;
    final userName = currentUser?.name ?? 'there';
    final userId = currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) =>
              context.colors.primaryGradient.createShader(bounds),
          child: Text(
            context.l10n.splitCircle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.link_rounded),
            tooltip: 'Join with invite code',
            onPressed: () => _showJoinByCodeDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          SizedBox(width: 8),
        ],
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $userName 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                groupsAsync.when(
                  data: (groups) => Text(
                    '${groups.length} ${groups.length != 1 ? context.l10n.activeGroups : context.l10n.activeGroup}',
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  loading: () => Text(
                    context.l10n.loadingGroups,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  error: (_, _) => Text(
                    context.l10n.errorLoadingGroups,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                // Pending Invites Section
                invitesAsync.when(
                  data: (invites) {
                    if (invites.isEmpty)
                      return SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.pendingInvitesCapitalized,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 12),
                            ...invites.map(
                              (group) => _InviteCard(group: group),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, _) => SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Group list
                groupsAsync.when(
                  data: (groups) {
                    final hasNoInvites = invitesAsync.value?.isEmpty ?? true;
                    if (groups.isEmpty && hasNoInvites) {
                      return SliverFillRemaining(
                        child: _EmptyState(
                          onCreateGroup: () => context.go('/groups/create'),
                        ),
                      );
                    } else if (groups.isEmpty) {
                      return SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverPadding(
                      padding: EdgeInsets.only(bottom: 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final group = groups[index];
                          // Net balances might need migration to real Firestore IDs later
                          final netBalances = ref.watch(
                            groupNetBalancesProvider(group.id),
                          );
                          final totalSpending = ref.watch(
                            groupTotalSpendingProvider(group.id),
                          );
                          final userBalance = netBalances[userId] ?? 0;
                          final unreadCount = currentUser?.unreadCounts[group.id] ?? 0;

                          return _GroupCard(
                            group: group,
                            totalSpending: totalSpending,
                            userBalance: userBalance,
                            unreadCount: unreadCount,
                            onTap: () => context.go('/groups/${group.id}'),
                          );
                        }, childCount: groups.length),
                      ),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, trace) => SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: $e',
                        style: TextStyle(color: context.colors.danger),
                      ),
                    ),
                  ),
                ),
                // Left Groups Section
                leftGroupsAsync.when(
                  data: (leftGroups) {
                    if (leftGroups.isEmpty)
                      return SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverPadding(
                      padding: EdgeInsets.only(bottom: 80),
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.leftGroups,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              ...leftGroups.map(
                                (group) => _LeftGroupCard(group: group),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, _) => SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/groups/create'),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.background,
        child: Icon(Icons.add_rounded),
      ),
    );
  }
}

void _showJoinByCodeDialog(BuildContext context) {
  final codeController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? Color(0xFF1C2333)
        : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Icon(
              Icons.link_rounded,
              size: 40,
              color: context.colors.primary,
            ),
            SizedBox(height: 16),
            Text(
              context.l10n.joinWithInviteCode,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              context.l10n.pasteInviteCode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: context.colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. AB12CD34',
                hintStyle: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 18,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: context.colors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final code = codeController.text.trim();
                  if (code.isEmpty) return;
                  Navigator.pop(ctx);
                  context.go('/invite/$code');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.background,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.l10n.joinGroup,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InviteCard extends ConsumerWidget {
  final Group group;

  const _InviteCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          AvatarCircle(name: group.name, imageUrl: group.photoUrl, size: 48),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  context.l10n.invitedYouToJoin,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(groupServiceProvider).declineInvite(group.id),
            icon: Icon(Icons.close_rounded, color: context.colors.danger),
            style: IconButton.styleFrom(
              backgroundColor: context.colors.danger.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: () =>
                ref.read(groupServiceProvider).acceptInvite(group.id),
            icon: Icon(Icons.check_rounded, color: context.colors.success),
            style: IconButton.styleFrom(
              backgroundColor: context.colors.success.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final double totalSpending;
  final double userBalance;
  final int unreadCount;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.totalSpending,
    required this.userBalance,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.groupTypeEmojis[group.type] ?? '📌';
    final memberNames = group.members.map((m) => m.name).toList();

    return GlassCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colors.border),
                      image: group.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(group.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: group.photoUrl == null
                        ? Center(child: Text(emoji, style: TextStyle(fontSize: 24)))
                        : null,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.colors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.surfaceElevated,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${group.memberIds.length} ${group.memberIds.length != 1 ? context.l10n.members : context.l10n.member}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (userBalance == 0 && totalSpending == 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Text(
                    context.l10n.settled,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          if (totalSpending > 0 || userBalance != 0) ...[
            SizedBox(height: 16),
            Row(
              children: [
                if (memberNames.isNotEmpty)
                  AvatarStack(names: memberNames, size: 28, maxDisplay: 4),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (userBalance != 0) ...[
                      Row(
                        children: [
                          Text(
                            userBalance > 0 ? context.l10n.youAreOwed : context.l10n.youOwe,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyUtils.formatAmount(userBalance.abs(), group.currency),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: userBalance > 0
                                  ? context.colors.success
                                  : context.colors.danger,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Text(
                          '${context.l10n.total}: ${CurrencyUtils.formatAmount(totalSpending, group.currency)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textTertiary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: context.colors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const _EmptyState({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.groups_outlined,
            size: 40,
            color: context.colors.primary,
          ),
        ),
        SizedBox(height: 24),
        Text(
          context.l10n.noGroupsYet,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            context.l10n.createFirstGroup,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: onCreateGroup,
          icon: Icon(Icons.add_rounded),
          label: Text(context.l10n.createGroup),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.background,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeftGroupCard extends ConsumerWidget {
  final Group group;

  const _LeftGroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoji = AppConstants.groupTypeEmojis[group.type] ?? '📌';

    return Dismissible(
      key: Key(group.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.colors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: context.colors.surface,
            title: Text(
              context.l10n.deleteGroup,
              style: TextStyle(color: context.colors.textPrimary),
            ),
            content: Text(
              context.l10n.deleteGroupPermanent,
              style: TextStyle(color: context.colors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  context.l10n.cancel,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  context.l10n.delete,
                  style: TextStyle(color: context.colors.danger),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await ref.read(groupServiceProvider).deleteLeftGroup(group.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.groupDeletedList),
                backgroundColor: context.colors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete group: $e'),
                backgroundColor: context.colors.danger,
              ),
            );
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 24,
                    color: context.colors.textTertiary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textTertiary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${context.l10n.leftGroupText} • ${group.memberIds.length} ${group.memberIds.length != 1 ? context.l10n.members : context.l10n.member}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
