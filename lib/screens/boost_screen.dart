// lib/screens/boost_screen.dart - Updated with IAP
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';
import '../services/purchase_service.dart';
import '../widgets/components/loading_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoostScreen extends StatefulWidget {
  @override
  _BoostScreenState createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isProcessingPurchase = false;
  int _currentBoosts = 0;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([
      _purchaseService.initialize(),
      _loadCurrentBoosts(),
    ]);
    if (mounted) {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _loadCurrentBoosts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _currentBoosts = userDoc.data()?['availableBoosts'] ?? 0;
        });
      }
    }
  }

  Future<void> _handleSingleBoostPurchase() async {
    if (_isProcessingPurchase) return;

    setState(() {
      _isProcessingPurchase = true;
    });

    try {
      final success = await _purchaseService.purchaseProduct(PurchaseService.kBoost1Pack);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase could not be initiated'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPurchase = false;
        });
      }
    }
  }

  void _showMoreBoostOptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoostPurchaseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primaryDark,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Spacer(),
                      // Current boosts indicator
                      if (_currentBoosts > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.flash_on, color: Colors.yellow, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '$_currentBoosts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.restore, color: Colors.white),
                        onPressed: () async {
                          await _purchaseService.restorePurchases();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Purchases restored'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoadingUserData
                      ? Center(
                    child: LoadingIndicator(
                      type: LoadingIndicatorType.pulse,
                      color: Colors.white,
                      message: 'Loading...',
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Boost icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      SizedBox(height: 32),

                      // Title
                      Text(
                        'Get Boost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Be one of the top profiles in your area for 30 minutes and get more matches!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 48),

                      // Show loading or purchase options
                      if (_purchaseService.isLoading)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      else if (_purchaseService.isAvailable)
                        Column(
                          children: [
                            // Single boost button with actual price
                            ElevatedButton(
                              onPressed: _isProcessingPurchase ? null : _handleSingleBoostPurchase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isProcessingPurchase
                                  ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                                  : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on),
                                  SizedBox(width: 8),
                                  Text(
                                    'Get 1 Boost - ${_getBoostPrice()}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // More options button
                            TextButton(
                              onPressed: _showMoreBoostOptions,
                              child: Text(
                                'See more boost packages',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'In-app purchases not available',
                          style: TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBoostPrice() {
    final product = _purchaseService.getProduct(PurchaseService.kBoost1Pack);
    return product?.price ?? '\$4.99';
  }
}

// Boost Purchase Screen for multiple options
class BoostPurchaseScreen extends StatefulWidget {
  const BoostPurchaseScreen({Key? key}) : super(key: key);

  @override
  _BoostPurchaseScreenState createState() => _BoostPurchaseScreenState();
}

class _BoostPurchaseScreenState extends State<BoostPurchaseScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  String _selectedProductId = PurchaseService.kBoost5Pack;
  bool _isProcessingPurchase = false;
  int _currentBoosts = 0;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
    _loadCurrentBoosts();
  }

  Future<void> _initializePurchases() async {
    await _purchaseService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCurrentBoosts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _currentBoosts = userDoc.data()?['availableBoosts'] ?? 0;
        });
      }
    }
  }

  Future<void> _handlePurchase() async {
    if (_isProcessingPurchase) return;

    setState(() {
      _isProcessingPurchase = true;
    });

    try {
      final success = await _purchaseService.purchaseProduct(_selectedProductId);

      if (success) {
        // Purchase initiated, the purchase service will handle the rest
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase could not be initiated'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isProcessingPurchase = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade400,
              Colors.purple.shade700,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Boost Packages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Current boosts
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, color: Colors.yellow, size: 32),
                    SizedBox(width: 8),
                    Text(
                      'Current Boosts: $_currentBoosts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Pricing options
              Expanded(
                child: _purchaseService.isLoading
                    ? Center(
                  child: LoadingIndicator(
                    type: LoadingIndicatorType.pulse,
                    message: 'Loading products...',
                  ),
                )
                    : _purchaseService.isAvailable
                    ? ListView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  children: _buildBoostOptions(),
                )
                    : Center(
                  child: Text(
                    'In-app purchases not available',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

              // Purchase button
              Padding(
                padding: EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isProcessingPurchase ||
                        _purchaseService.isLoading ||
                        !_purchaseService.isAvailable)
                        ? null
                        : _handlePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.purple.shade900,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isProcessingPurchase
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.shade900,
                        ),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Get Boosts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBoostOptions() {
    final boostProducts = _purchaseService.getBoostProducts();

    return boostProducts.map((product) {
      final isSelected = _selectedProductId == product.id;
      final boostCount = _getBoostCount(product.id);
      final pricePerBoost = _calculatePricePerBoost(product);

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedProductId = product.id;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.yellow
                  : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    boostCount.toString(),
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$boostCount ${boostCount == 1 ? 'Boost' : 'Boosts'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.price,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    if (boostCount > 1)
                      Text(
                        '$pricePerBoost per boost',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (product.id == PurchaseService.kBoost10Pack)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.yellow,
                  size: 24,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  int _getBoostCount(String productId) {
    switch (productId) {
      case PurchaseService.kBoost1Pack:
        return 1;
      case PurchaseService.kBoost5Pack:
        return 5;
      case PurchaseService.kBoost10Pack:
        return 10;
      default:
        return 0;
    }
  }

  String _calculatePricePerBoost(ProductDetails product) {
    final count = _getBoostCount(product.id);
    if (count <= 1) return '';

    final pricePerBoost = product.rawPrice / count;
    return '\$${pricePerBoost.toStringAsFixed(2)}';
  }
}