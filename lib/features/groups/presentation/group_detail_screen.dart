import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/balance_chip.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_utils.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/domain/app_user.dart';
import '../data/group_provider.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../expenses/data/expenses_provider.dart';
import '../../expenses/domain/activity.dart';
import '../../expenses/domain/expense.dart';
import '../../payments/presentation/iap_panel.dart';
import 'package:share_plus/share_plus.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Reset unread count for this group automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupServiceProvider).resetGroupUnreadCount(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final group = ref.watch(groupByIdProvider(widget.groupId));
    if (group == null) {
      return Scaffold(body: Center(child: Text(l10n.groupNotFound)));
    }

    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;
    final totalSpending = ref.watch(groupTotalSpendingProvider(widget.groupId));
    final netBalances = ref.watch(groupNetBalancesProvider(widget.groupId));
    final userBalance = netBalances[currentUser?.id ?? ''] ?? 0;

    final emoji = AppConstants.groupTypeEmojis[group.type] ?? '📌';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 310,
              pinned: true,
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.background.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 20),
                ),
                onPressed: () => context.go('/groups'),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      size: 20,
                      color: context.colors.danger,
                    ),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: context.colors.surface,
                        title: Text(
                          l10n.leaveGroup,
                          style: TextStyle(color: context.colors.textPrimary),
                        ),
                        content: Text(
                          l10n.leaveGroupWarning,
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              l10n.leave,
                              style: TextStyle(color: context.colors.danger),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await ref
                            .read(groupServiceProvider)
                            .leaveGroup(widget.groupId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.youLeftGroup),
                              backgroundColor: context.colors.success,
                            ),
                          );
                          context.go('/groups');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to leave group: $e'),
                              backgroundColor: context.colors.danger,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF112240), context.colors.background],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 60, 20, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: context.colors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: TextStyle(fontSize: 28),
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${group.members.length} ${group.members.length != 1 ? l10n.members : l10n.member}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => IAPBottomSheet(group: group),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: group.expenseRights > 0 
                                              ? context.colors.success.withValues(alpha: 0.1) 
                                              : context.colors.danger.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: group.expenseRights > 0 
                                                ? context.colors.success.withValues(alpha: 0.3) 
                                                : context.colors.danger.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${group.expenseRights} ${l10n.expenseRightsLeft}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: group.expenseRights > 0 ? context.colors.success : context.colors.danger,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.add_circle_outline_rounded,
                                              size: 15,
                                              color: group.expenseRights > 0 ? context.colors.success : context.colors.danger,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Stats row
                          Row(
                            children: [
                              _StatChip(
                                label: l10n.total,
                                value: CurrencyUtils.formatAmount(
                                  totalSpending,
                                  group.currency,
                                ),
                                icon: Icons.receipt_rounded,
                              ),
                              SizedBox(width: 12),
                              _StatChip(
                                label: l10n.yourBalance,
                                value:
                                    '${userBalance >= 0 ? '+' : '-'}${CurrencyUtils.formatAmount(userBalance.abs(), group.currency)}',
                                icon: userBalance >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                valueColor: userBalance >= 0
                                    ? context.colors.success
                                    : context.colors.danger,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.activitiesTab),
                  Tab(text: l10n.balancesTab),
                  Tab(text: l10n.membersTab),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _ActivitiesTab(groupId: widget.groupId),
              _BalancesTab(groupId: widget.groupId),
              _MembersTab(groupId: widget.groupId),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        l10n.whatWouldYouLikeToAdd,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_rounded,
                          color: context.colors.accent,
                        ),
                      ),
                      title: Text(
                        l10n.addExpenseCapitalized,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        l10n.splitCostMembers,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (group.expenseRights > 0) {
                          context.go('/groups/${widget.groupId}/add-expense');
                        } else {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => IAPBottomSheet(group: group),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: context.colors.success,
                        ),
                      ),
                      title: Text(
                        l10n.recordPayment,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        l10n.someonePaidSomeoneBack,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/groups/${widget.groupId}/add-payment');
                      },
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.background,
          child: Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: valueColor ?? context.colors.textSecondary,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? context.colors.textPrimary,
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

// ─── Activities Tab ────────────────────────────────────────────────

class _ActivitiesTab extends ConsumerWidget {
  final String groupId;
  const _ActivitiesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(groupActivitiesProvider(groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final group = ref.watch(groupByIdProvider(groupId));
    final currentUser = ref.watch(currentUserProvider).value;

    // Combine activities and expenses for comprehensive view
    return activitiesAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error loading activities: $e',
          style: TextStyle(color: context.colors.danger),
        ),
      ),
      data: (activities) {
        // Also get expenses to show them as activities
        final expenses = expensesAsync.value ?? [];

        final List<dynamic> combinedList = [...activities, ...expenses];
        combinedList.sort((a, b) => (b.date as DateTime).compareTo(a.date as DateTime));
        
        if (combinedList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 56,
                  color: context.colors.textTertiary.withValues(alpha: 0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'No activities yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first expense to get started',
                  style: TextStyle(color: context.colors.textTertiary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 80),
          itemCount: combinedList.length,
          itemBuilder: (context, index) {
            final item = combinedList[index];
            if (item is Activity) {
              final activity = item;
              return _ActivityItem(
                activity: activity,
                currency: group?.currency ?? 'USD',
              );

            } else {
              final expense = item as Expense;
              final payer = group?.members.firstWhere(
                (m) => m.id == expense.paidById,
                orElse: () => group.members.first,
              );

              final payerName = payer != null
                  ? (payer.username?.isNotEmpty == true
                        ? payer.username!
                        : payer.name)
                  : 'Unknown';

              Widget expenseItem;
              if (expense.isPayment) {
                // Find recipient
                final recipientId = expense.splits.isNotEmpty
                    ? expense.splits.first.userId
                    : '';
                final recipient = group?.members
                    .where((m) => m.id == recipientId)
                    .firstOrNull;
                final recipientName = recipient != null
                    ? (recipient.username?.isNotEmpty == true
                          ? recipient.username!
                          : recipient.name)
                    : 'Unknown';

                expenseItem = _PaymentItem(
                  expense: expense,
                  members: group?.members ?? [],
                  groupId: groupId,
                  currency: group?.currency ?? 'USD',
                  onTap: () => _showExpenseDetail(context, expense, group?.members ?? [], group?.currency ?? 'USD'),
                );
              } else {
                expenseItem = _ExpenseItem(
                  expense: expense,
                  members: group?.members ?? [],
                  currency: group?.currency ?? 'USD',
                  onTap: () => _showExpenseDetail(context, expense, group?.members ?? [], group?.currency ?? 'USD'),
                );
              }

              final isCreator =
                  currentUser != null && expense.paidById == currentUser.id;

              if (isCreator) {
                return Dismissible(
                  key: Key(expense.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                          'Delete Expense',
                          style: TextStyle(color: context.colors.textPrimary),
                        ),
                        content: Text(
                          'Are you sure you want to delete this expense?',
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              context.l10n.cancelAction,
                              style: TextStyle(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: context.colors.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    try {
                      await deleteExpenseFromFirestore(
                        expenseId: expense.id,
                        groupId: groupId,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.expenseDeleted)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete expense: \$e'),
                          ),
                        );
                      }
                    }
                  },
                  child: expenseItem,
                );
              }

              return expenseItem;
            }
          },
        );
      },
    );
  }
}

// ─── Activity Detail Sheet ────────────────────────────────────────────────────

void _showExpenseDetail(
  BuildContext context,
  Expense expense,
  List<AppUser> members,
  String currency,
) {
  final l10n = context.l10n;
  final colors = context.colors;

  String _memberName(String id) {
    final m = members.where((m) => m.id == id).firstOrNull;
    if (m == null) return 'Unknown';
    return m.username?.isNotEmpty == true ? m.username! : m.name;
  }

  IconData _catIcon(String? cat) {
    switch (cat) {
      case 'food': return Icons.restaurant_rounded;
      case 'travel': return Icons.flight_rounded;
      case 'accommodation': return Icons.hotel_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'rent': return Icons.home_rounded;
      case 'groceries': return Icons.shopping_cart_rounded;
      case 'entertainment': return Icons.movie_rounded;
      default: return expense.isPayment ? Icons.payments_rounded : Icons.receipt_rounded;
    }
  }

  final payerName = _memberName(expense.paidById);
  final dateStr = DateFormatter.formatDate(expense.date, context);
  final timeStr = '${expense.date.hour.toString().padLeft(2, '0')}:${expense.date.minute.toString().padLeft(2, '0')}';
  final accentColor = expense.isPayment
      ? (expense.isConfirmed ? colors.success : colors.warning)
      : colors.accent;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Header icon + title
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_catIcon(expense.category), color: accentColor, size: 26),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.description,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary),
                            ),
                            SizedBox(height: 3),
                            Row(children: [
                              if (!expense.isPayment && expense.category != null) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(expense.category!, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
                                ),
                                SizedBox(width: 6),
                              ],
                              if (expense.isPayment)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (expense.isConfirmed ? colors.success : colors.warning).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    expense.isConfirmed ? l10n.confirmedStatus : l10n.pendingStatus,
                                    style: TextStyle(fontSize: 11, color: expense.isConfirmed ? colors.success : colors.warning, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatAmount(expense.amount, currency),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accentColor),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  Divider(color: colors.textTertiary.withValues(alpha: 0.15)),
                  SizedBox(height: 16),

                  // Date & time
                  _DetailRow(icon: Icons.calendar_today_rounded, label: l10n.expenseDate, value: '$dateStr  $timeStr'),
                  SizedBox(height: 12),

                  // Payer (or payment direction)
                  if (!expense.isPayment) ...[
                    _DetailRow(icon: Icons.person_rounded, label: l10n.paidByLabel, value: payerName),
                    SizedBox(height: 20),
                    // Split breakdown
                    Text(l10n.splitDetailsLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                    SizedBox(height: 10),
                    ...expense.splits.map((split) {
                      final name = _memberName(split.userId);
                      final isPayer = split.userId == expense.paidById;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            AvatarCircle(name: name, size: 32),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.textPrimary)),
                            ),
                            if (isPayer)
                              Container(
                                margin: EdgeInsets.only(right: 8),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(l10n.paidWord, style: TextStyle(fontSize: 10, color: context.colors.primary, fontWeight: FontWeight.w600)),
                              ),
                            Text(
                              CurrencyUtils.formatAmount(split.amount, currency),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    // Payment: from → to
                    _DetailRow(
                      icon: Icons.arrow_circle_right_rounded,
                      label: l10n.paidByLabel,
                      value: payerName,
                    ),
                    SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.arrow_circle_left_rounded,
                      label: l10n.paymentRecipientLabel,
                      value: expense.splits.isNotEmpty ? _memberName(expense.splits.first.userId) : 'Unknown',
                      valueColor: context.colors.success,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.textTertiary),
        SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
        Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? context.colors.textPrimary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseItem extends StatelessWidget {
  final Expense expense;
  final List<AppUser> members;
  final String currency;
  final VoidCallback? onTap;

  // Kept as convenience getters so existing build code doesn't change much
  String get description => expense.description;
  double get amount => expense.amount;
  DateTime get date => expense.date;
  int get splitCount => expense.splits.length;
  String? get category => expense.category;

  const _ExpenseItem({
    required this.expense,
    required this.members,
    required this.currency,
    this.onTap,
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
    final payer = members.where((m) => m.id == expense.paidById).firstOrNull;
    final paidByName = payer?.username?.isNotEmpty == true
        ? payer!.username!
        : payer?.name ?? 'Unknown';

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcon, color: context.colors.accent, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '$paidByName ${context.l10n.paidWord} · ${DateFormatter.formatDate(date, context)}',
                    style: TextStyle(
                      fontSize: 12,
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
                  CurrencyUtils.formatAmount(amount, currency),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  '${context.l10n.splitPrefix}$splitCount${context.l10n.splitSuffix}',
                  style: TextStyle(
                    fontSize: 11,
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

class _PaymentItem extends ConsumerWidget {
  final Expense expense;
  final List<AppUser> members;
  final String groupId;
  final String currency;
  final VoidCallback? onTap;

  String get fromName {
    final payer = members.where((m) => m.id == expense.paidById).firstOrNull;
    return payer?.username?.isNotEmpty == true ? payer!.username! : payer?.name ?? 'Unknown';
  }

  String get toName {
    final recipientId = expense.splits.isNotEmpty ? expense.splits.first.userId : '';
    final r = members.where((m) => m.id == recipientId).firstOrNull;
    return r?.username?.isNotEmpty == true ? r!.username! : r?.name ?? 'Unknown';
  }

  String? get recipientId => expense.splits.isNotEmpty ? expense.splits.first.userId : null;

  const _PaymentItem({
    required this.expense,
    required this.members,
    required this.groupId,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isRecipient = currentUser?.id == recipientId;
    final isConfirmed = expense.isConfirmed;
    final canConfirm = !isConfirmed && isRecipient;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? context.colors.success.withValues(alpha: 0.12)
                        : context.colors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: isConfirmed ? context.colors.success : context.colors.warning,
                    size: 22,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.l10n.paymentTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (!isConfirmed) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.l10n.pendingStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.colors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        '$fromName → $toName · ${DateFormatter.formatDate(expense.date, context)}',
                        style: TextStyle(fontSize: 12, color: context.colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyUtils.formatAmount(expense.amount, currency),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isConfirmed ? context.colors.success : context.colors.warning,
                  ),
                ),
              ],
            ),
            if (canConfirm) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          await confirmPaymentInFirestore(groupId: groupId, expenseId: expense.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.paymentConfirmed)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to confirm payment: $e')),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: context.colors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          context.l10n.confirmAction,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.success, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          await cancelPaymentInFirestore(groupId: groupId, expenseId: expense.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.paymentCancelled)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to cancel payment: $e')),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: context.colors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          context.l10n.cancelAction,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.danger, fontWeight: FontWeight.w600, fontSize: 14),
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

class _ActivityItem extends StatelessWidget {
  final Activity activity;
  final String currency;

  const _ActivityItem({
    required this.activity,
    required this.currency,
  });

  String _getLocalizedActivityDescription(BuildContext context, String description, ActivityType type) {
    if (type == ActivityType.memberJoined && description.endsWith(' joined the group via invite link')) {
      final name = description.replaceAll(' joined the group via invite link', '');
      return '$name ${context.l10n.joinedViaInviteLink}';
    }
    return description;
  }

  @override
  Widget build(BuildContext context) {
    IconData activityIcon = Icons.history_rounded;
    Color activityColor = context.colors.textSecondary;

    switch (activity.type) {
      case ActivityType.expense:
        activityIcon = Icons.receipt_rounded;
        activityColor = context.colors.accent;
        break;
      case ActivityType.payment:
        activityIcon = Icons.payments_rounded;
        activityColor = context.colors.success;
        break;
      case ActivityType.memberJoined:
        activityIcon = Icons.person_add_rounded;
        activityColor = context.colors.primary;
        break;
      case ActivityType.memberLeft:
        activityIcon = Icons.person_remove_rounded;
        activityColor = context.colors.danger;
        break;
    }

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activityIcon, color: activityColor, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedActivityDescription(context, activity.description, activity.type),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  DateFormatter.formatDate(activity.date, context),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (activity.amount != null)
            Text(
              CurrencyUtils.formatAmount(activity.amount!, currency),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: activity.type == ActivityType.memberLeft
                    ? context.colors.danger
                    : context.colors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Balances Tab ────────────────────────────────────────────────

class _BalancesTab extends ConsumerStatefulWidget {
  final String groupId;
  const _BalancesTab({required this.groupId});

  @override
  ConsumerState<_BalancesTab> createState() => _BalancesTabState();
}

class _BalancesTabState extends ConsumerState<_BalancesTab> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupByIdProvider(widget.groupId));
    final netBalances = ref.watch(groupNetBalancesProvider(widget.groupId));
    final individualDebts = ref.watch(groupIndividualDebtsProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider).value;

    if (group == null) return SizedBox();

    // Default to current user on first render
    final effectiveSelectedId = _selectedUserId ?? currentUser?.id ?? (group.members.isNotEmpty ? group.members.first.id : null);

    // Who does the selected user owe?
    final selectedOwes = effectiveSelectedId != null
        ? (individualDebts[effectiveSelectedId] ?? <String, double>{})
        : <String, double>{};

    // Who owes the selected user? (reverse lookup)
    final owedToSelected = <String, double>{};
    if (effectiveSelectedId != null) {
      for (final entry in individualDebts.entries) {
        final amount = entry.value[effectiveSelectedId] ?? 0.0;
        if (amount > 0.01) {
          owedToSelected[entry.key] = amount;
        }
      }
    }

    final selectedMember = effectiveSelectedId != null
        ? group.members.where((m) => m.id == effectiveSelectedId).firstOrNull
        : null;
    final selectedName = selectedMember?.username?.isNotEmpty == true
        ? selectedMember!.username!
        : selectedMember?.name ?? '';

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 80),
      children: [
        // ── Who owes whom? ────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 18,
                color: context.colors.primary,
              ),
              SizedBox(width: 8),
              Text(
                context.l10n.whoOwesWhom,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // User dropdown
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _UserDropdown(
            members: group.members,
            selectedId: effectiveSelectedId,
            currentUserId: currentUser?.id,
            onChanged: (val) => setState(() => _selectedUserId = val),
          ),
        ),

        SizedBox(height: 12),

        if (effectiveSelectedId != null) ...[
          // What the selected user owes to others
          if (selectedOwes.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                context.l10n.selectedUserOwes(selectedName),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.danger,
                ),
              ),
            ),
            ...selectedOwes.entries.map((entry) {
              final creditorId = entry.key;
              final amount = entry.value;
              final creditor = group.members.where((m) => m.id == creditorId).firstOrNull;
              final creditorName = creditor?.username?.isNotEmpty == true
                  ? creditor!.username!
                  : creditor?.name ?? creditorId;

              return _DebtRow(
                fromUserId: effectiveSelectedId,
                toUserId: creditorId,
                fromName: selectedName,
                toName: creditorName,
                toMember: creditor,
                amount: amount,
                currency: group.currency,
                groupId: widget.groupId,
                direction: _DebtDirection.owes,
              );
            }),
          ],

          // What others owe the selected user
          if (owedToSelected.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                context.l10n.selectedUserIsOwed(selectedName),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.success,
                ),
              ),
            ),
            ...owedToSelected.entries.map((entry) {
              final debtorId = entry.key;
              final amount = entry.value;
              final debtor = group.members.where((m) => m.id == debtorId).firstOrNull;
              final debtorName = debtor?.username?.isNotEmpty == true
                  ? debtor!.username!
                  : debtor?.name ?? debtorId;

              return _DebtRow(
                fromUserId: debtorId,
                toUserId: effectiveSelectedId,
                fromName: debtorName,
                toName: selectedName,
                toMember: selectedMember,
                amount: amount,
                currency: group.currency,
                groupId: widget.groupId,
                direction: _DebtDirection.isOwed,
              );
            }),
          ],

          // All settled up
          if (selectedOwes.isEmpty && owedToSelected.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: context.colors.success,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      context.l10n.allSettledUpState,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],

        // ── Individual Balances ───────────────────────────────────
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            context.l10n.individualBalances,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        ...group.members.map((member) {
          final balance = netBalances[member.id] ?? 0;
          final isPositive = balance > 0.01;
          final isNegative = balance < -0.01;
          final displayName = member.username?.isNotEmpty == true
              ? member.username!
              : member.name;

          return GlassCard(
            child: Row(
              children: [
                AvatarCircle(name: displayName, size: 40),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (member.isDummy) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.l10n.guestBadge,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: context.colors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        isPositive
                            ? context.l10n.getsBackMoney
                            : isNegative
                            ? context.l10n.owesMoney
                            : context.l10n.allSettledUpState,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPositive
                              ? context.colors.success
                              : isNegative
                              ? context.colors.danger
                              : context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                BalanceChip(amount: balance, compact: true),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Always-downward user dropdown ───────────────────────────────────────────

class _UserDropdown extends StatefulWidget {
  final List<AppUser> members;
  final String? selectedId;
  final String? currentUserId;
  final ValueChanged<String?> onChanged;

  const _UserDropdown({
    required this.members,
    required this.selectedId,
    required this.currentUserId,
    required this.onChanged,
  });

  @override
  State<_UserDropdown> createState() => _UserDropdownState();
}

class _UserDropdownState extends State<_UserDropdown> {
  final _key = GlobalKey();

  void _open() async {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    // Position the menu's top-left at the bottom-left of the button.
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height + 4, // 4 px gap below button
      offset.dx + size.width,
      offset.dy + size.height + 4,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: context.colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
      items: widget.members.map((m) {
        final name = m.username?.isNotEmpty == true ? m.username! : m.name;
        final isMe = m.id == widget.currentUserId;
        final isSelected = m.id == widget.selectedId;

        return PopupMenuItem<String>(
          value: m.id,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              AvatarCircle(name: name, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMe ? '$name (${context.l10n.you})' : name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.textPrimary,
                  ),
                ),
              ),
              if (m.isDummy)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    context.l10n.guestBadge,
                    style: TextStyle(
                      fontSize: 9,
                      color: context.colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isSelected) ...[
                SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 18, color: context.colors.primary),
              ],
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.members
        .where((m) => m.id == widget.selectedId)
        .firstOrNull;
    final name = selected?.username?.isNotEmpty == true
        ? selected!.username!
        : selected?.name ?? '';
    final isMe = selected?.id == widget.currentUserId;

    return GestureDetector(
      key: _key,
      onTap: _open,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.primary.withValues(alpha: 0.4)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (selected != null) ...[
              AvatarCircle(name: name, size: 28),
              SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                selected == null
                    ? ''
                    : isMe
                        ? '$name (${context.l10n.you})'
                        : name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            if (selected?.isDummy == true) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.l10n.guestBadge,
                  style: TextStyle(
                    fontSize: 9,
                    color: context.colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8),
            ],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

enum _DebtDirection { owes, isOwed }

class _DebtRow extends ConsumerWidget {
  final String fromUserId;
  final String toUserId;
  final String fromName;
  final String toName;
  final dynamic toMember; // AppUser?
  final double amount;
  final String currency;
  final String groupId;
  final _DebtDirection direction;

  const _DebtRow({
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
    required this.toName,
    required this.toMember,
    required this.amount,
    required this.currency,
    required this.groupId,
    required this.direction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwes = direction == _DebtDirection.owes;
    // fromName owes toName (for owes direction)
    // fromName owes toName (for isOwed direction: debtorName owes selectedName)

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOwes
                  ? context.colors.danger.withValues(alpha: 0.1)
                  : context.colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOwes ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isOwes ? context.colors.danger : context.colors.success,
              size: 20,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14),
                    children: [
                      TextSpan(
                        text: fromName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' ${context.l10n.owesWord} ',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      TextSpan(
                        text: toName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  CurrencyUtils.formatAmount(amount, currency),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isOwes ? context.colors.danger : context.colors.success,
                  ),
                ),
              ],
            ),
          ),
          // Record Payment shortcut button
          GestureDetector(
            onTap: () => context.go(
              '/groups/$groupId/add-payment',
              extra: {
                'fromUserId': fromUserId,
                'toUserId': toUserId,
                'prefillAmount': amount,
              },
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: context.colors.primary,
                    size: 18,
                  ),
                  SizedBox(height: 2),
                  Text(
                    context.l10n.recordPayment,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Members Tab ─────────────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  final String groupId;
  const _MembersTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupByIdProvider(groupId));
    final netBalances = ref.watch(groupNetBalancesProvider(groupId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;

    if (group == null) return SizedBox();

    return Column(
      children: [
        // Action buttons row
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => AddMemberBottomSheet(groupId: groupId),
                        );
                      },
                      icon: Icon(Icons.person_add_rounded, size: 18),
                      label: Text(context.l10n.addMember),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.background,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _ShareInviteLinkButton(groupId: groupId),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddGuestMemberBottomSheet(groupId: groupId),
                    );
                  },
                  icon: Icon(Icons.person_outline_rounded, size: 18),
                  label: Text(context.l10n.addGuestMember),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.accent.withValues(alpha: 0.15),
                    foregroundColor: context.colors.accent,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    side: BorderSide(color: context.colors.accent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Members List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 80),
            itemCount: group.members.length,
            itemBuilder: (context, index) {
              final member = group.members[index];
              final balance = netBalances[member.id] ?? 0;
              final isCurrentUser = member.id == (currentUser?.id ?? '');

              return GlassCard(
                child: Row(
                  children: [
                    AvatarCircle(
                      name: member.username?.isNotEmpty == true
                          ? member.username!
                          : member.name,
                      size: 44,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member.username?.isNotEmpty == true
                                    ? member.username!
                                    : member.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.l10n.you,
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              if (member.isDummy) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.accent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.l10n.guestBadge,
                                    style: TextStyle(
                                      color: context.colors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BalanceChip(amount: balance, compact: true),
                    if (member.isDummy) ...[
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: context.colors.surface,
                              title: Text(
                                context.l10n.removeGuestMember,
                                style: TextStyle(color: context.colors.textPrimary),
                              ),
                              content: Text(
                                context.l10n.removeGuestMemberConfirm(member.name),
                                style: TextStyle(color: context.colors.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(context.l10n.cancel,
                                      style: TextStyle(color: context.colors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(context.l10n.delete,
                                      style: TextStyle(color: context.colors.danger)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            try {
                              await ref.read(groupServiceProvider).deleteDummyMember(
                                groupId: groupId,
                                dummyId: member.id,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.failedToRemoveGuest),
                                    backgroundColor: context.colors.danger,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.colors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: context.colors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AddMemberBottomSheet extends ConsumerStatefulWidget {
  final String groupId;

  const AddMemberBottomSheet({super.key, required this.groupId});

  @override
  ConsumerState<AddMemberBottomSheet> createState() =>
      _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends ConsumerState<AddMemberBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Debounce search
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted && _searchController.text.isNotEmpty) {
        _searchUsers(_searchController.text.trim());
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    try {
      final groupService = ref.read(groupServiceProvider);
      final results = await groupService.searchUsersByNickname(query);

      final group = ref.read(groupByIdProvider(widget.groupId));
      final currentMemberIds = group?.memberIds ?? [];

      // Filter out users who are already in the group
      final filteredResults = results
          .where((user) => !currentMemberIds.contains(user.id))
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _inviteUser(AppUser user) async {
    try {
      final groupService = ref.read(groupServiceProvider);
      await groupService.inviteUserToGroup(widget.groupId, user.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} invited to group'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite user: $e'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Add Member',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded),
                    color: context.colors.textSecondary,
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name or username...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colors.textTertiary,
                  ),
                  filled: true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.colors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Search results
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? _searchController.text.trim().isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 48,
                                  color: context.colors.textTertiary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Search for users to add to this group',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_off_rounded,
                                  size: 48,
                                  color: context.colors.textTertiary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No users found',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            child: Row(
                              children: [
                                AvatarCircle(
                                  name: user.username?.isNotEmpty == true
                                      ? user.username!
                                      : user.name,
                                  size: 40,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.username?.isNotEmpty == true
                                            ? user.username!
                                            : user.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        user.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.colors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _inviteUser(user),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colors.primary,
                                    foregroundColor: context.colors.background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(context.l10n.invite),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareInviteLinkButton extends ConsumerStatefulWidget {
  final String groupId;
  const _ShareInviteLinkButton({required this.groupId});

  @override
  ConsumerState<_ShareInviteLinkButton> createState() =>
      _ShareInviteLinkButtonState();
}

class _ShareInviteLinkButtonState
    extends ConsumerState<_ShareInviteLinkButton> {
  bool _isGenerating = false;

  Future<void> _shareInviteLink() async {
    setState(() => _isGenerating = true);
    try {
      final service = ref.read(groupServiceProvider);
      final link = await service.generateInviteLink(widget.groupId);
      final group = ref.read(groupByIdProvider(widget.groupId));
      final groupName = group?.name ?? 'our group';

      await SharePlus.instance.share(
        ShareParams(
          text: 'Join "$groupName" on Circlio!\n$link',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate link: $e'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isGenerating ? null : _shareInviteLink,
      icon: _isGenerating
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(context.colors.background),
              ),
            )
          : Icon(Icons.link_rounded, size: 18),
      label: Text(_isGenerating ? context.l10n.generatingLink : context.l10n.inviteLinkBtn),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.accent,
        foregroundColor: context.colors.background,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ─── Add Guest Member Bottom Sheet ───────────────────────────────

class AddGuestMemberBottomSheet extends ConsumerStatefulWidget {
  final String groupId;
  const AddGuestMemberBottomSheet({super.key, required this.groupId});

  @override
  ConsumerState<AddGuestMemberBottomSheet> createState() =>
      _AddGuestMemberBottomSheetState();
}

class _AddGuestMemberBottomSheetState
    extends ConsumerState<AddGuestMemberBottomSheet> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addGuest() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(groupServiceProvider).createDummyMember(
        groupId: widget.groupId,
        name: name,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.guestMemberAdded(name)),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToAddGuest),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: context.colors.accent,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.addGuestMember,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      context.l10n.guestMemberSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded),
                color: context.colors.textSecondary,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Name field
          Text(
            context.l10n.guestMemberName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: context.l10n.guestMemberNameHint,
              prefixIcon: Icon(
                Icons.badge_outlined,
                color: context.colors.textTertiary,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.accent, width: 2),
              ),
            ),
            style: TextStyle(color: context.colors.textPrimary),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _addGuest(),
          ),

          SizedBox(height: 20),

          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_nameController.text.trim().isNotEmpty && !_isLoading)
                  ? _addGuest
                  : null,
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.person_add_rounded, size: 18),
              label: Text(context.l10n.addGuestMember),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

