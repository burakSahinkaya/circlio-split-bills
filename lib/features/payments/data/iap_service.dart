import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class IAPService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool isAvailable = false;
  List<ProductDetails> products = [];
  
  // A callback triggered upon successful purchase.
  void Function(PurchaseDetails purchase, ProductDetails originalProduct)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;

  // Constants
  static String get fiveRightsId => Platform.isAndroid 
      ? 'com.splitcircle.splitcircle.fiveexpense' 
      : 'com.splitcircle.splitCircle.fiveExpense';
      
  static String get fifteenRightsId => Platform.isAndroid 
      ? 'com.splitcircle.splitcircle.fifteenexpense' 
      : 'com.splitcircle.splitCircle.fifeteenExpense';
      
  static String get twentyFiveRightsId => Platform.isAndroid 
      ? 'com.splitcircle.splitcircle.twentyfiveexpense' 
      : 'com.splitcircle.splitCircle.twentyFiveExpense';

  IAPService(this._ref) {
    _initIAP();
  }

  void _initIAP() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        if (onPurchaseError != null) onPurchaseError!(error.toString());
      },
    );
  }

  Future<void> initialize() async {
    isAvailable = await _iap.isAvailable();
    if (isAvailable) {
      await loadProducts();
    } else {
      // Mock flow for emulator tests where store is totally unavailable
      await _injectMockProducts([]);
    }
  }

  Future<void> loadProducts() async {
    final Set<String> kIds = <String>{
      fiveRightsId,
      fifteenRightsId,
      twentyFiveRightsId,
    };
    final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);

    await _injectMockProducts(response.productDetails);
  }

  Future<void> _injectMockProducts(List<ProductDetails> existingProducts) async {
    // If the store is available, ONLY show products actually fetched from Apple/Google.
    // This prevents fake products from showing up and crashing if they aren't configured in the store.
    if (isAvailable && existingProducts.isNotEmpty) {
      products = List.from(existingProducts);
      products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      return;
    }

    // Fallback for emulators where the store is completely unavailable
    double fivePrice = 4.99;
    products = [
      _createMockProduct(fiveRightsId, '5 Expense Rights', fivePrice, 'Get 5 expense rights.'),
      _createMockProduct(fifteenRightsId, '15 Expense Rights', fivePrice * 2.5, 'Get 15 expense rights.'),
      _createMockProduct(twentyFiveRightsId, '25 Expense Rights', fivePrice * 3.8, 'Get 25 expense rights.'),
    ];
  }
  
  ProductDetails _createMockProduct(String id, String title, double doublePrice, String desc) {
    return ProductDetails(
      id: id,
      title: title,
      description: desc,
      price: '\$${doublePrice.toStringAsFixed(2)}',
      rawPrice: doublePrice,
      currencyCode: 'USD',
      currencySymbol: '\$',
    );
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    // If store is unavailable (e.g. running on an emulator), mock the purchase process
    if (!isAvailable) {
      // Simulate success for emulator testing
      _listenToPurchaseUpdated([
        PurchaseDetails(
           productID: productDetails.id, 
           purchaseID: 'mock_purchase_id', 
           status: PurchaseStatus.purchased,
           transactionDate: DateTime.now().millisecondsSinceEpoch.toString(), 
           verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'mock')
        )
      ]);
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Pending state
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          if (onPurchaseError != null) onPurchaseError!(purchaseDetails.error?.message ?? 'Unknown error');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          
          final product = products.firstWhere((p) => p.id == purchaseDetails.productID, orElse: () => products.first);
          
          if (onPurchaseSuccess != null) {
            onPurchaseSuccess!(purchaseDetails, product);
          }
        }
        
        // Always complete purchases
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  int getRightsFromProductId(String id) {
    if (id == fiveRightsId) return 5;
    if (id == fifteenRightsId) return 15;
    if (id == twentyFiveRightsId) return 25;
    return 0;
  }

  Future<void> deliverGroupRights(String groupId, String productId) async {
    final int rightsToAdd = getRightsFromProductId(productId);
    if (rightsToAdd > 0) {
      await _firestore.collection('groups').doc(groupId).update({
        'expenseRights': FieldValue.increment(rightsToAdd),
      });
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
