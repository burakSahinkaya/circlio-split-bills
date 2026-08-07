import 'package:flutter/material.dart';
import '../../../core/utils/l10n_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_provider.dart';
import '../../groups/data/group_provider.dart';
import '../../groups/domain/group.dart';
import '../../expenses/data/expenses_provider.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/domain/activity.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  static const String _selectedGroupKey = 'selected_activity_group_id';
  int _displayedItemCount = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    setState(() {
      _displayedItemCount += 10;
    });
  }

  Future<void> _saveSelectedGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedGroupKey, groupId);
  }

  Future<String?> _getSelectedGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedGroupKey);
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return groupsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(context.l10n.activity)),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.activity)),
        body: Center(child: Text('Error loading groups: $e')),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.activity)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: context.colors.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    context.l10n.noGroupsYet,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.l10n.joinOrCreateGroup,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<String?>(
          future: _getSelectedGroup(),
          builder: (context, snapshot) {
            String selectedGroupId = snapshot.data ?? '';

            // If no selected group, pick the one with latest activity
            if (selectedGroupId.isEmpty) {
              selectedGroupId = groups.first.id; // Default to first group
              // TODO: Later we can implement logic to find group with latest activity
              _saveSelectedGroup(selectedGroupId);
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.activity),
                backgroundColor: context.colors.background,
                surfaceTintColor: Colors.transparent,
              ),
              body: Column(
                children: [
                  // Group Dropdown
                  Container(
                    padding: EdgeInsets.all(16),
                    child: _GroupDropdown(
                      groups: groups,
                      selectedGroupId: selectedGroupId,
                      onGroupSelected: (groupId) {
                        setState(() {
                          _displayedItemCount =
                              10; // Reset pagination when group changes
                        });
                        _saveSelectedGroup(groupId);
                      },
                    ),
                  ),

                  // Activity Feed
                  Expanded(
                    child: _ActivityFeed(
                      groupId: selectedGroupId,
                      itemCount: _displayedItemCount,
                      scrollController: _scrollController,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GroupDropdown extends ConsumerWidget {
  final List<Group> groups;
  final String selectedGroupId;
  final Function(String) onGroupSelected;

  const _GroupDropdown({
    required this.groups,
    required this.selectedGroupId,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = groups.firstWhere((g) => g.id == selectedGroupId);
    final emoji = AppConstants.groupTypeEmojis[selectedGroup.type] ?? '📌';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: GestureDetector(
        onTap: () => _showGroupSelector(context, selectedGroup),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(emoji, style: TextStyle(fontSize: 16))),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedGroup.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${selectedGroup.members.length} ${selectedGroup.members.length != 1 ? context.l10n.members : context.l10n.member}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupSelector(BuildContext context, Group currentGroup) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    context.l10n.selectGroupTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Group list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final emoji =
                      AppConstants.groupTypeEmojis[group.type] ?? '📌';
                  final isSelected = group.id == selectedGroupId;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onGroupSelected(group.id);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: 0.3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: TextStyle(fontSize: 20),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? context.colors.primary
                                        : context.colors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${group.members.length} ${group.members.length != 1 ? context.l10n.members : context.l10n.member}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              color: context.colors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ActivityFeed extends ConsumerWidget {
  final String groupId;
  final int itemCount;
  final ScrollController scrollController;

  const _ActivityFeed({
    required this.groupId,
    required this.itemCount,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final group = ref.watch(groupByIdProvider(groupId));
    final currentUser = ref.watch(currentUserProvider).value;

    return expensesAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading activity: $e')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: context.colors.textTertiary,
                ),
                SizedBox(height: 16),
                Text(
                  context.l10n.noActivityYet,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  context.l10n.activityWillAppearHere,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
            ),
          );
        }

        final displayedExpenses = expenses.take(itemCount).toList();
        final hasMore = expenses.length > itemCount;

        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: displayedExpenses.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayedExpenses.length && hasMore) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final expense = displayedExpenses[index];
            final payer = group?.members.firstWhere(
              (m) => m.id == expense.paidById,
              orElse: () => group?.members.first ?? group!.members.first,
            );

            final payerName = payer?.username?.isNotEmpty == true
                ? payer!.username!
                : payer?.name ?? 'Unknown';

            if (expense.isPayment) {
              final recipientId = expense.splits.isNotEmpty
                  ? expense.splits.first.userId
                  : '';
              final recipient = group?.members
                  .where((m) => m.id == recipientId)
                  .firstOrNull;
              final recipientName = recipient?.username?.isNotEmpty == true
                  ? recipient!.username!
                  : recipient?.name ?? 'Unknown';

              return _ActivityPaymentItem(
                fromName: payerName,
                toName: recipientName,
                amount: expense.amount,
                date: expense.date,
                expenseId: expense.id,
                groupId: groupId,
                recipientId: recipientId,
                isConfirmed: expense.isConfirmed,
              );
            } else {
              return _ActivityExpenseItem(
                description: expense.description,
                amount: expense.amount,
                paidByName: payerName,
                date: expense.date,
                splitCount: expense.splits.length,
                category: expense.category,
              );
            }
          },
        );
      },
    );
  }
}

class _ActivityExpenseItem extends StatelessWidget {
  final String description;
  final double amount;
  final String paidByName;
  final DateTime date;
  final int splitCount;
  final String? category;

  const _ActivityExpenseItem({
    required this.description,
    required this.amount,
    required this.paidByName,
    required this.date,
    required this.splitCount,
    this.category,
  });

  IconData get _categoryIcon {
    switch (category) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'rent':
        return Icons.home_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _categoryIcon,
                color: context.colors.accent,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '$paidByName ${context.l10n.paidWord} · ${DateFormatter.formatDate(date, context)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  '${context.l10n.splitPrefix}$splitCount${context.l10n.splitSuffix}',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPaymentItem extends ConsumerWidget {
  final String fromName;
  final String toName;
  final double amount;
  final DateTime date;
  final String expenseId;
  final String groupId;
  final String? recipientId;
  final bool isConfirmed;

  const _ActivityPaymentItem({
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.date,
    required this.expenseId,
    required this.groupId,
    this.recipientId,
    this.isConfirmed = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isRecipient = currentUser?.id == recipientId;
    final canConfirm = !isConfirmed && isRecipient;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? context.colors.success.withValues(alpha: 0.12)
                        : context.colors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: isConfirmed
                        ? context.colors.success
                        : context.colors.warning,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.l10n.paymentTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (!isConfirmed) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.warning.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                context.l10n.pendingStatus,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: context.colors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '$fromName $toName ${context.l10n.paidWord} · ${DateFormatter.formatDate(date, context)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isConfirmed
                        ? context.colors.success
                        : context.colors.warning,
                  ),
                ),
              ],
            ),
            if (canConfirm) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          await confirmPaymentInFirestore(
                            groupId: groupId,
                            expenseId: expenseId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.paymentConfirmed)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to confirm payment: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.colors.success.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          context.l10n.confirmAction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.colors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          await cancelPaymentInFirestore(
                            groupId: groupId,
                            expenseId: expenseId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.paymentCancelled)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to cancel payment: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.colors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          context.l10n.cancelAction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.colors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
