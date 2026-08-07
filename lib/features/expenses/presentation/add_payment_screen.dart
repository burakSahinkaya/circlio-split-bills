import 'package:flutter/material.dart';
import '../../../core/utils/l10n_extension.dart';
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
import '../../balances/domain/balance.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialFromUserId;
  final String? initialToUserId;
  final double? prefillAmount;

  const AddPaymentScreen({
    super.key,
    required this.groupId,
    this.initialFromUserId,
    this.initialToUserId,
    this.prefillAmount,
  });

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  String? _fromUserId;
  String? _toUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider).value;
      setState(() {
        // Use pre-filled values if provided (from Balances tab shortcut),
        // otherwise default to current user as payer.
        _fromUserId = widget.initialFromUserId ?? currentUser?.id;
        _toUserId = widget.initialToUserId;
        if (widget.prefillAmount != null) {
          _amountController.text = widget.prefillAmount!.toStringAsFixed(2);
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null &&
        amount > 0 &&
        _fromUserId != null &&
        _toUserId != null &&
        _fromUserId != _toUserId;
  }

  void _addPayment() async {
    if (_isLoading) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (!_isValid || amount == null) return;

    setState(() => _isLoading = true);

    try {
      // Auto-confirm if either the payer or recipient is a dummy member.
      // There is no real user who can confirm on behalf of a dummy account.
      final group = ref.read(groupByIdProvider(widget.groupId));
      final fromUser = group?.members.where((m) => m.id == _fromUserId).firstOrNull;
      final toUser = group?.members.where((m) => m.id == _toUserId).firstOrNull;
      final autoConfirm = (fromUser?.isDummy ?? false) || (toUser?.isDummy ?? false);

      await addPaymentToFirestore(
        groupId: widget.groupId,
        fromUserId: _fromUserId!,
        toUserId: _toUserId!,
        amount: amount,
        autoConfirm: autoConfirm,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.failedToRecordPayment)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupByIdProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider).value;
    final individualDebts = ref.watch(
      groupIndividualDebtsProvider(widget.groupId),
    );

    if (group == null) return Scaffold();

    // Calculate debts for the selected payer using INDIVIDUAL debt relationships (CORRECT)
    final userDebts = _fromUserId != null
        ? BalanceEngine.calculateUserDebtsFromIndividual(
            individualDebts,
            _fromUserId!,
          )
        : <String, double>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.recordPayment),
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
              // Amount input
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.success.withValues(alpha: 0.15),
                      context.colors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      context.l10n.paymentAmountLabel,
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
                  ],
                ),
              ),

              SizedBox(height: 28),

              // From (Payer)
              _SectionLabel(context.l10n.whoPaidLabel),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.members.map((member) {
                  final isSelected = _fromUserId == member.id;
                  final isMe = currentUser?.id == member.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _fromUserId = member.id;
                        // Clear toUserId if same person
                        if (_toUserId == member.id) _toUserId = null;
                      });
                    },
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
                            isMe
                                ? context.l10n.youOnly
                                : (member.username?.isNotEmpty == true
                                      ? member.username!
                                      : member.name),
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

              SizedBox(height: 28),

              // Arrow indicator
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.success.withValues(alpha: 0.12),
                    border: Border.all(
                      color: context.colors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: context.colors.success,
                  ),
                ),
              ),

              SizedBox(height: 28),

              // To (Recipient)
              _SectionLabel(context.l10n.paidToLabel),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.members.where((m) => m.id != _fromUserId).map((
                  member,
                ) {
                  final isSelected = _toUserId == member.id;
                  final isMe = currentUser?.id == member.id;
                  final debtAmount = userDebts[member.id] ?? 0.0;
                  final hasDebt = debtAmount > 0.01;

                  return GestureDetector(
                    onTap: () => setState(() => _toUserId = member.id),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.success.withValues(alpha: 0.15)
                            : context.colors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.success
                              : context.colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AvatarCircle(name: member.name, size: 22),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isMe
                                        ? context.l10n.youOnly
                                        : (member.username?.isNotEmpty == true
                                              ? member.username!
                                              : member.name),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? context.colors.success
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
                              if (hasDebt)
                                Text(
                                  '${context.l10n.owesPrefix}${CurrencyUtils.formatAmount(debtAmount, group.currency)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.colors.danger,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          if (hasDebt) ...[
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _toUserId = member.id;
                                  _amountController.text = debtAmount
                                      .toStringAsFixed(2);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.l10n.fullAmountBtn,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
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

              SizedBox(height: 40),

              // Record payment button
              GradientButton(
                label: _isLoading ? context.l10n.pendingStatus : context.l10n.recordPayment,
                icon: _isLoading ? Icons.hourglass_empty : Icons.check_rounded,
                width: double.infinity,
                onPressed: (_isValid && !_isLoading) ? _addPayment : null,
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _amountFocusNode.hasFocus
          ? Container(
              color: context.colors.surfaceElevated,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _amountFocusNode.unfocus(),
                    child: Text(
                      'Done',
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
