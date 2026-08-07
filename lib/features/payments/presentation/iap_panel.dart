import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../groups/domain/group.dart';
import '../data/iap_service.dart';
import '../../expenses/data/expenses_provider.dart';
import '../../expenses/domain/expense.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/l10n_extension.dart';

class IAPBottomSheet extends ConsumerStatefulWidget {
  final Group group;

  const IAPBottomSheet({super.key, required this.group});

  @override
  ConsumerState<IAPBottomSheet> createState() => _IAPBottomSheetState();
}

class _IAPBottomSheetState extends ConsumerState<IAPBottomSheet> {
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _initIAP();
  }

  Future<void> _initIAP() async {
    final iapService = ref.read(iapServiceProvider);
    
    // Set up callbacks
    iapService.onPurchaseSuccess = _handlePurchaseSuccess;
    iapService.onPurchaseError = _handlePurchaseError;

    await iapService.initialize();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handlePurchaseError(String error) {
    if (!mounted) return;
    setState(() => _isPurchasing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase Failed: $error')));
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchase, ProductDetails product) async {
    if (!mounted) return;
    
    setState(() => _isPurchasing = false);

    final iapService = ref.read(iapServiceProvider);
    
    // 1. Deliver the rights to the group in Firestore
    await iapService.deliverGroupRights(widget.group.id, purchase.productID);

    if (!mounted) return;

    // 2. Pop the existing modal window so we can show dialog cleanly
    Navigator.pop(context);

    // 3. Show dialog asking if they want to add it as an expense
    final shouldAddAsExpense = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: ctx.colors.success),
            SizedBox(width: 8),
            Text(context.l10n.purchaseSuccessful),
          ],
        ),
        content: Text(
          "${context.l10n.iapSuccessBody1}${iapService.getRightsFromProductId(purchase.productID)}${context.l10n.iapSuccessBody2}"
          '${product.price}${context.l10n.iapSuccessBody3}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.noThanks),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: ctx.colors.primary,
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(context.l10n.addGroupExpense),
          ),
        ],
      ),
    );

    if (shouldAddAsExpense == true) {
      _addAsExpense(product);
    }
  }

  Future<void> _addAsExpense(ProductDetails product) async {
    final iapService = ref.read(iapServiceProvider);
    final amount = product.rawPrice;
    final splitAmount = amount / widget.group.memberIds.length;
    
    // Create splits evenly across all members
    final splits = widget.group.memberIds.map((id) => 
      ExpenseSplit(userId: id, amount: splitAmount)
    ).toList();

    // Use currently logged in user as the payer
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) return;

    await addExpenseToFirestore(
      groupId: widget.group.id,
      description: '${iapService.getRightsFromProductId(product.id)} ${context.l10n.expenseRightsCapitalized} (Purchase)',
      amount: amount,
      paidById: uid,
      splits: splits,
      category: 'subscription', // or 'other'
      consumeRight: false, // DO NOT consume an expense right for this!
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final iapService = ref.watch(iapServiceProvider);
    final memberCount = widget.group.memberIds.length;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
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
          Icon(Icons.stars_rounded, color: context.colors.primary, size: 48),
          SizedBox(height: 16),
          Text(
            context.l10n.outOfExpenseRights,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            context.l10n.keepSplittingByBuyingRights,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 24),
          
          if (_isPurchasing) 
             Center(child: CircularProgressIndicator())
          else if (iapService.products.isEmpty)
             Text(context.l10n.noPackagesAvailable)
          else 
            ...iapService.products.map((product) {
              final double perPerson = product.rawPrice / (memberCount > 0 ? memberCount : 1);
              
              return GlassCard(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${iapService.getRightsFromProductId(product.id)} ${context.l10n.expenseRightsCapitalized}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${context.l10n.thatsOnlyPrefix}${product.currencySymbol}${perPerson.toStringAsFixed(2)}${context.l10n.perPersonSuffix}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.colors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            context.l10n.addPurchaseAsExpense,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() => _isPurchasing = true);
                        iapService.buyProduct(product);
                      },
                      child: Text(product.price),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
