// lib/services/purchase_service.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Product IDs (must match App Store Connect)
  static const String kPremiumMonthly = 'com.marifecto.datechatmeet.prem.monthly';
  static const String kPremium3Months = 'com.marifecto.premium.3months';
  static const String kPremium6Months = 'com.marifecto.premium.6months';
  static const String kBoost1Pack = 'com.marifecto.boost.1pack';
  static const String kBoost5Pack = 'com.marifecto.boost.5pack';
  static const String kBoost10Pack = 'com.marifecto.boost.10pack';
  static const String kSuperLike5Pack = 'com.marifecto.superlike.5pack';
  static const String kSuperLike15Pack = 'com.marifecto.superlike.15pack';
  static const String kSuperLike30Pack = 'com.marifecto.superlike.30pack';

  // State
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPremium = false;
  DateTime? _premiumExpiryDate;

  // Getters
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPremium => _isPremium;
  DateTime? get premiumExpiryDate => _premiumExpiryDate;

  // Initialize the service
  Future<void> initialize() async {
    print('Initializing PurchaseService...');

    // Check if IAP is available
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      print('In-app purchases not available');
      _errorMessage = 'In-app purchases are not available on this device';
      notifyListeners();
      return;
    }

    // Listen to purchase updates
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onError: _onPurchaseError,
    );

    // Load products
    await loadProducts();

    // Restore purchases
    await restorePurchases();

    // Check current premium status
    await checkPremiumStatus();

    print('PurchaseService initialized');
  }

  // Load available products
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Define product IDs
      final Set<String> productIds = {
        kPremiumMonthly,
        kPremium3Months,
        kPremium6Months,
        kBoost1Pack,
        kBoost5Pack,
        kBoost10Pack,
        kSuperLike5Pack,
        kSuperLike15Pack,
        kSuperLike30Pack,
      };

      // Query product details
      final ProductDetailsResponse response =
      await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        _errorMessage = 'Error loading products: ${response.error!.message}';
        print(_errorMessage);
      } else {
        _products = response.productDetails;
        print('Loaded ${_products.length} products');

        // Sort products by price
        _products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      }
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Find the product
      final ProductDetails? product = _products.firstWhere(
            (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      if (product == null) {
        throw Exception('Product not found');
      }

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Initiate purchase
      bool success = false;

      if (_isSubscription(productId)) {
        // For subscriptions
        success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // For consumables (boosts, super likes)
        success = await _iap.buyConsumable(purchaseParam: purchaseParam);
      }

      return success;
    } catch (e) {
      _errorMessage = 'Purchase failed: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('Purchase update: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchaseDetails);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          _handlePurchaseError(purchaseDetails);
          break;

        case PurchaseStatus.canceled:
          print('Purchase canceled');
          _isLoading = false;
          notifyListeners();
          break;
      }
    }
  }

  // Handle pending purchase
  void _handlePendingPurchase(PurchaseDetails purchaseDetails) {
    print('Purchase pending: ${purchaseDetails.productID}');
    // You might want to show a loading indicator
  }

  // Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    print('Purchase successful: ${purchaseDetails.productID}');

    try {
      // Verify the purchase (you should verify with your backend)
      final bool isValid = await _verifyPurchase(purchaseDetails);

      if (isValid) {
        // Grant the purchase
        await _grantPurchase(purchaseDetails);

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    } catch (e) {
      print('Error handling purchase: $e');
      _errorMessage = 'Error processing purchase: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    print('Purchase error: ${purchaseDetails.error}');
    _errorMessage = purchaseDetails.error?.message ?? 'Purchase failed';
    _isLoading = false;
    notifyListeners();

    if (purchaseDetails.pendingCompletePurchase) {
      _iap.completePurchase(purchaseDetails);
    }
  }

  // Handle general purchase error
  void _onPurchaseError(dynamic error) {
    print('Purchase stream error: $error');
    _errorMessage = 'Purchase error: $error';
    _isLoading = false;
    notifyListeners();
  }

  // Verify purchase (should be done server-side in production)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, send the receipt to your server for verification
    // For now, we'll do basic client-side validation

    if (Platform.isIOS) {
      // iOS receipt data is in purchaseDetails.verificationData.serverVerificationData
      // You should send this to your server to verify with Apple
      print('iOS receipt data available for verification');
    }

    // For development, assume all purchases are valid
    // In production, ALWAYS verify on your server
    return true;
  }

  // Grant the purchase to the user
  Future<void> _grantPurchase(PurchaseDetails purchaseDetails) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final productId = purchaseDetails.productID;
    final purchaseTime = DateTime.now();

    try {
      // Handle different product types
      if (_isSubscription(productId)) {
        // Grant premium subscription
        await _grantPremiumSubscription(userId, productId, purchaseTime);
      } else if (productId.contains('boost')) {
        // Grant boosts
        await _grantBoosts(userId, productId);
      } else if (productId.contains('superlike')) {
        // Grant super likes
        await _grantSuperLikes(userId, productId);
      }

      // Log the purchase
      await _logPurchase(userId, purchaseDetails);

    } catch (e) {
      print('Error granting purchase: $e');
      throw e;
    }
  }

  // Grant premium subscription
  Future<void> _grantPremiumSubscription(
      String userId,
      String productId,
      DateTime purchaseTime,
      ) async {
    // Calculate expiry date based on product
    DateTime expiryDate;
    String subscriptionType;

    switch (productId) {
      case kPremiumMonthly:
        expiryDate = purchaseTime.add(Duration(days: 30));
        subscriptionType = 'monthly';
        break;
      case kPremium3Months:
        expiryDate = purchaseTime.add(Duration(days: 90));
        subscriptionType = '3months';
        break;
      case kPremium6Months:
        expiryDate = purchaseTime.add(Duration(days: 180));
        subscriptionType = '6months';
        break;
      default:
        throw Exception('Unknown subscription product');
    }

    // Update user document
    await _firestore.collection('users').doc(userId).update({
      'isPremium': true,
      'premiumUntil': Timestamp.fromDate(expiryDate),
      'premiumType': subscriptionType,
      'premiumStartDate': Timestamp.fromDate(purchaseTime),
      'premiumFeatures': [
        'unlimited_likes',
        'see_who_likes_you',
        'super_likes',
        'rewind',
        'read_receipts',
        'priority_matches',
      ],
    });

    // Update local state
    _isPremium = true;
    _premiumExpiryDate = expiryDate;

    print('Premium subscription granted until: $expiryDate');
  }

  // Grant boosts
  Future<void> _grantBoosts(String userId, String productId) async {
    int boostCount = 0;

    switch (productId) {
      case kBoost1Pack:
        boostCount = 1;
        break;
      case kBoost5Pack:
        boostCount = 5;
        break;
      case kBoost10Pack:
        boostCount = 10;
        break;
    }

    if (boostCount > 0) {
      // Update user's boost count
      await _firestore.collection('users').doc(userId).update({
        'availableBoosts': FieldValue.increment(boostCount),
        'lastBoostPurchase': FieldValue.serverTimestamp(),
      });

      print('Granted $boostCount boosts to user');
    }
  }

  // Grant super likes
  Future<void> _grantSuperLikes(String userId, String productId) async {
    int superLikeCount = 0;

    switch (productId) {
      case kSuperLike5Pack:
        superLikeCount = 5;
        break;
      case kSuperLike15Pack:
        superLikeCount = 15;
        break;
      case kSuperLike30Pack:
        superLikeCount = 30;
        break;
    }

    if (superLikeCount > 0) {
      // Update user's super like count
      await _firestore.collection('users').doc(userId).update({
        'availableSuperLikes': FieldValue.increment(superLikeCount),
        'lastSuperLikePurchase': FieldValue.serverTimestamp(),
      });

      // Also update in streak data if it exists
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('streak_data')
            .doc('current')
            .update({
          'availableSuperLikes': FieldValue.increment(superLikeCount),
        });
      } catch (e) {
        print('Streak data not found, skipping update');
      }

      print('Granted $superLikeCount super likes to user');
    }
  }

  // Log purchase for analytics
  Future<void> _logPurchase(String userId, PurchaseDetails purchaseDetails) async {
    await _firestore.collection('purchases').add({
      'userId': userId,
      'productId': purchaseDetails.productID,
      'purchaseId': purchaseDetails.purchaseID,
      'status': purchaseDetails.status.toString(),
      'timestamp': FieldValue.serverTimestamp(),
      'platform': 'ios',
      'verificationData': purchaseDetails.verificationData.serverVerificationData,
    });
  }

  // Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _iap.restorePurchases();
      print('Restore purchases completed');
    } catch (e) {
      _errorMessage = 'Failed to restore purchases: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check current premium status
  Future<void> checkPremiumStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _isPremium = data?['isPremium'] ?? false;

        if (_isPremium && data?['premiumUntil'] != null) {
          _premiumExpiryDate = (data!['premiumUntil'] as Timestamp).toDate();

          // Check if premium has expired
          if (_premiumExpiryDate!.isBefore(DateTime.now())) {
            // Premium expired, update status
            await _firestore.collection('users').doc(userId).update({
              'isPremium': false,
              'premiumExpiredAt': FieldValue.serverTimestamp(),
            });
            _isPremium = false;
            _premiumExpiryDate = null;
          }
        }
      }
    } catch (e) {
      print('Error checking premium status: $e');
    }

    notifyListeners();
  }

  // Helper to check if product is subscription
  bool _isSubscription(String productId) {
    return productId.contains('premium');
  }

  // Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Get premium products
  List<ProductDetails> getPremiumProducts() {
    return _products.where((p) => _isSubscription(p.id)).toList();
  }

  // Get boost products
  List<ProductDetails> getBoostProducts() {
    return _products.where((p) => p.id.contains('boost')).toList();
  }

  // Get super like products
  List<ProductDetails> getSuperLikeProducts() {
    return _products.where((p) => p.id.contains('superlike')).toList();
  }

  // Format price for display
  String formatPrice(ProductDetails product) {
    return product.price;
  }

  // Calculate savings percentage
  String calculateSavings(String productId) {
    if (!_isSubscription(productId)) return '';

    final monthlyProduct = getProduct(kPremiumMonthly);
    final currentProduct = getProduct(productId);

    if (monthlyProduct == null || currentProduct == null) return '';

    double monthlyPrice = monthlyProduct.rawPrice;
    double totalPrice = currentProduct.rawPrice;
    int months = 1;

    switch (productId) {
      case kPremium3Months:
        months = 3;
        break;
      case kPremium6Months:
        months = 6;
        break;
    }

    double expectedPrice = monthlyPrice * months;
    double savings = ((expectedPrice - totalPrice) / expectedPrice) * 100;

    return savings > 0 ? '${savings.toStringAsFixed(0)}% OFF' : '';
  }

  // Dispose
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}