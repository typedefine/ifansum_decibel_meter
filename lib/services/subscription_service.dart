import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;

/// Handles Apple / Google subscription purchases.
///
/// This is a light client wrapper. The actual purchase verification
/// must be implemented on your backend and configured via
/// [verificationEndpoint].
class SubscriptionService {
  SubscriptionService._internal();

  static final SubscriptionService instance = SubscriptionService._internal();

  // Replace with your real product identifiers.
  static const String _kSubscriptionProductId = 'ifansum_decibel_pro_subscription';

  // Replace with your backend verification endpoint.
  static const String verificationEndpoint =
      'https://your-backend.com/api/verify-subscription';

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  late final StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _purchaseSub.cancel(),
      onError: (Object error) {
        debugPrint('Purchase stream error: $error');
      },
    );

    final response =
        await _iap.queryProductDetails({_kSubscriptionProductId});
    _products = response.productDetails;
  }

  Future<void> buySubscription() async {
    if (!_isAvailable) return;
    if (_products.isEmpty) {
      final response =
          await _iap.queryProductDetails({_kSubscriptionProductId});
      _products = response.productDetails;
      if (_products.isEmpty) return;
    }

    final product = _products.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdate(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.error) {
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        continue;
      }

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        final verified = await _verifyWithServer(purchaseDetails);
        if (verified && purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> _verifyWithServer(PurchaseDetails purchaseDetails) async {
    try {
      final response = await http.post(
        Uri.parse(verificationEndpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': defaultTargetPlatform.name,
          'productId': purchaseDetails.productID,
          'purchaseId': purchaseDetails.purchaseID,
          'verificationData': {
            'source': purchaseDetails.verificationData.source,
            'serverVerificationData':
                purchaseDetails.verificationData.serverVerificationData,
          },
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['isValid'] == true;
      }
    } catch (e) {
      debugPrint('Verify purchase error: $e');
    }
    return false;
  }

  Future<void> dispose() async {
    await _purchaseSub.cancel();
  }
}

