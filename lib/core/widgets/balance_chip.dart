import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BalanceChip extends StatelessWidget {
  final double amount;
  final bool compact;

  const BalanceChip({
    super.key,
    required this.amount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount > 0;
    final isZero = amount.abs() < 0.01;
    final color = isZero
        ? context.colors.textTertiary
        : isPositive
            ? context.colors.success
            : context.colors.danger;
    final label = isZero
        ? 'settled'
        : isPositive
            ? 'you are owed'
            : 'you owe';
    final amountStr = '\$${amount.abs().toStringAsFixed(2)}';

    if (compact) {
      return Text(
        '${isPositive ? '+' : '-'}$amountStr',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isZero)
            Icon(
              isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color,
              size: 14,
            ),
          if (!isZero) SizedBox(width: 4),
          Text(
            isZero ? label : '$label $amountStr',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
