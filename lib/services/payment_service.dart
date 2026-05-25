import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool available = false;

  Future<void> initialize() async {
    available = await _iap.isAvailable();
    if (available) {
      final bool isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        available = false;
      }
    }
  }

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<void> buyProduct(String productId) async {
    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty) {
      throw Exception('Product not found');
    }
    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}