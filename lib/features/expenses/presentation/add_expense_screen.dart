import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/utils/currency_utils.dart';
import '../../auth/data/auth_provider.dart';
import '../../groups/data/group_provider.dart';
import '../data/expenses_provider.dart';
import '../domain/expense.dart';
import '../../../core/utils/l10n_extension.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  String? _paidById;
  final Set<String> _selectedMemberIds = {};
  String? _selectedCategory;
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Map<String, Map<String, dynamic>> _getCategories(BuildContext context) => {
    'food': {'icon': Icons.restaurant_rounded, 'label': context.l10n.foodCategory},
    'travel': {'icon': Icons.flight_rounded, 'label': context.l10n.travelCategory},
    'accommodation': {'icon': Icons.hotel_rounded, 'label': context.l10n.stayCategory},
    'transport': {'icon': Icons.directions_car_rounded, 'label': context.l10n.transportCategory},
    'rent': {'icon': Icons.home_rounded, 'label': context.l10n.rentCategory},
    'groceries': {'icon': Icons.shopping_cart_rounded, 'label': context.l10n.groceriesCategory},
    'entertainment': {'icon': Icons.movie_rounded, 'label': context.l10n.funCategory},
    'other': {'icon': Icons.receipt_rounded, 'label': context.l10n.otherCategory},
  };

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider).value;
      final group = ref.read(groupByIdProvider(widget.groupId));
      if (group != null && currentUser != null) {
        setState(() {
          _paidById = currentUser.id;
          // Select all members by default
          _selectedMemberIds.addAll(group.members.map((m) => m.id));
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _addExpense() async {
    if (_isLoading) return;
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (description.isEmpty || amount == null || amount <= 0) return;
    if (_paidById == null || _selectedMemberIds.isEmpty) return;

    setState(() => _isLoading = true);

    final splitAmount = amount / _selectedMemberIds.length;
    final splits = _selectedMemberIds
        .map(
          (id) => ExpenseSplit(
            userId: id,
            amount: double.parse(splitAmount.toStringAsFixed(2)),
          ),
        )
        .toList();

    try {
      final group = ref.read(groupByIdProvider(widget.groupId));
      final currentRights = group?.expenseRights ?? 5;
      final newRightsCount = currentRights > 0 ? currentRights - 1 : 0;

      await addExpenseToFirestore(
        groupId: widget.groupId,
        description: description,
        amount: amount,
        paidById: _paidById!,
        splits: splits,
        date: _selectedDate,
        category: _selectedCategory,
        newRightsCount: newRightsCount,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add expense: $e')));
      }
    }
  }

  bool get _isValid {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    return description.isNotEmpty &&
        amount != null &&
        amount > 0 &&
        _paidById != null &&
        _selectedMemberIds.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupByIdProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider).value;
    if (group == null) return Scaffold();

    final splitPreview = _selectedMemberIds.isNotEmpty
        ? (double.tryParse(_amountController.text.trim()) ?? 0) /
              _selectedMemberIds.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.addExpense),
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount input (big and prominent)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF112240), context.colors.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      context.l10n.amount,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.textTertiary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            CurrencyUtils.getSymbol(group.currency),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            textAlign: TextAlign.center,
                            showCursor: false,
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: context.colors.textTertiary,
                                fontWeight: FontWeight.w300,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedMemberIds.isNotEmpty && splitPreview > 0) ...[
                      SizedBox(height: 8),
                      Text(
                        '${CurrencyUtils.formatAmount(splitPreview, group.currency)} per person',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Description
              _SectionLabel(context.l10n.descriptionLabel),
              SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: context.l10n.whatWasItFor,
                  prefixIcon: Icon(
                    Icons.edit_rounded,
                    color: context.colors.textTertiary,
                  ),
                ),
                style: TextStyle(color: context.colors.textPrimary),
                onChanged: (_) => setState(() {}),
              ),

              SizedBox(height: 24),

              // Category
              _SectionLabel(context.l10n.categoryLabel),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getCategories(context).entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = _selectedCategory == entry.key
                          ? null
                          : entry.key;
                    }),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.accent.withValues(alpha: 0.15)
                            : context.colors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.accent
                              : context.colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.value['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? context.colors.accent
                                : context.colors.textTertiary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            entry.value['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? context.colors.accent
                                  : context.colors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 24),

              // Paid by
              _SectionLabel(context.l10n.paidByLabel),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.members.map((member) {
                  final isSelected = _paidById == member.id;
                  final isMe = currentUser?.id == member.id;

                  return GestureDetector(
                    onTap: () => setState(() => _paidById = member.id),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.primary.withValues(alpha: 0.15)
                            : context.colors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AvatarCircle(name: member.name, size: 22),
                          SizedBox(width: 8),
                          Text(
                            isMe ? context.l10n.you : member.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 24),

              // Split between
              Row(
                children: [
                  _SectionLabel(context.l10n.splitBetweenLabel),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMemberIds.length == group.members.length) {
                          _selectedMemberIds.clear();
                        } else {
                          _selectedMemberIds.addAll(
                            group.members.map((m) => m.id),
                          );
                        }
                      });
                    },
                    child: Text(
                      _selectedMemberIds.length == group.members.length
                          ? context.l10n.deselectAll
                          : context.l10n.selectAll,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ...group.members.map((member) {
                final isSelected = _selectedMemberIds.contains(member.id);
                final isMe = currentUser?.id == member.id;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMemberIds.remove(member.id);
                          } else {
                            _selectedMemberIds.add(member.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colors.primary.withValues(alpha: 0.08)
                              : context.colors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: isSelected
                                    ? context.colors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? context.colors.primary
                                      : context.colors.textTertiary,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12),
                            AvatarCircle(name: member.name, size: 32),
                            SizedBox(width: 12),
                            Text(
                              member.name,
                              style: TextStyle(
                                color: isSelected
                                    ? context.colors.textPrimary
                                    : context.colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isMe) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            if (member.isDummy) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            Spacer(),
                            if (isSelected && splitPreview > 0)
                              Text(
                                CurrencyUtils.formatAmount(
                                  splitPreview,
                                  group.currency,
                                ),
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              SizedBox(height: 32),

              // Add expense button
              GradientButton(
                label: _isLoading ? 'Adding...' : context.l10n.addExpense,
                icon: _isLoading ? Icons.hourglass_empty : Icons.check_rounded,
                width: double.infinity,
                onPressed: (_isValid && !_isLoading) ? _addExpense : null,
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _amountFocusNode.hasFocus
          ? Container(
              color: Color(0xFF1E2A3A),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _amountFocusNode.unfocus(),
                    child: Text(
                      context.l10n.done,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
      ),
    );
  }
}
