// lib/screens/premium_screen.dart - Updated with In-App Purchases
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../theme/app_theme.dart';
import '../services/purchase_service.dart';
import '../widgets/components/loading_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumScreen extends StatefulWidget {
  final String? promoCode;

  PremiumScreen({Key? key, this.promoCode}) : super(key: key);

  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final TextEditingController _promoController = TextEditingController();
  final PurchaseService _purchaseService = PurchaseService();

  bool _discountApplied = false;
  double _discountPercentage = 0.0;
  bool _isAdmin = false;
  String _selectedProductId = PurchaseService.kPremium6Months;
  bool _isProcessingPurchase = false;

  @override
  void initState() {
    super.initState();

    // Initialize purchase service
    _initializePurchases();

    // Apply promo code if passed to the screen
    if (widget.promoCode != null) {
      _promoController.text = widget.promoCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyPromoCode();
      });
    }

    // Check if user already has admin status
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _initializePurchases() async {
    await _purchaseService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  // Check if user already has admin privileges
  Future<void> _checkAdminStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool('isAdmin') ?? false;

      if (isAdmin) {
        setState(() {
          _isAdmin = true;
        });
      } else {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            final isAdminInFirestore = userData?['isAdmin'] ?? false;

            if (isAdminInFirestore) {
              await prefs.setBool('isAdmin', true);
              setState(() {
                _isAdmin = true;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  // Apply admin status to the user
  Future<void> _applyAdminStatus() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isAdmin': true,
        'isPremium': true,
        'premiumUntil': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 365 * 10)),
        ),
        'adminGrantedAt': FieldValue.serverTimestamp(),
        'adminPremiumFeatures': [
          'unlimited_swipes',
          'see_who_likes_you',
          'see_profile_visitors',
          'super_likes',
          'rewind',
          'join_events',
          'verified_badge',
          'free_video_calls',
          'premium_badge',
          'read_receipts',
          'priority_matches',
          'all_premium_features'
        ],
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', true);
      await prefs.setBool('isPremium', true);

      setState(() {
        _isAdmin = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Admin privileges granted with all premium features!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Error applying admin status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error granting admin privileges: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyPromoCode() async {
    final code = _promoController.text.trim();

    if (code.toLowerCase() == 'admin1234') {
      await _applyAdminStatus();
      return;
    } else if (code.toLowerCase() == 'marifecto50') {
      setState(() {
        _discountApplied = true;
        _discountPercentage = 0.5;
      });

      if (WidgetsBinding.instance.isRootWidgetAttached) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success! 50% discount applied'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (code.isNotEmpty) {
      setState(() {
        _discountApplied = false;
        _discountPercentage = 0.0;
      });

      if (WidgetsBinding.instance.isRootWidgetAttached) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid promo code'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        // Purchase initiated, wait for the purchase stream to handle the result
        // The UI will update automatically via the purchase service
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
      body: Stack(
        children: [
          // Premium gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFB900),
                  Color(0xFFFF8A00),
                  AppColors.primary,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Premium logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Admin Status Banner
                        if (_isAdmin)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Admin Mode Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'All premium features unlocked!',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Premium features - Updated with new features
                        _buildPremiumFeature(
                          icon: Icons.workspace_premium,
                          title: 'See Who Likes You',
                          description: 'Skip the guesswork',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.visibility,
                          title: 'See Who Visited Your Profile',
                          description: 'Know who\'s interested',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.all_inclusive,
                          title: 'Unlimited Swipes',
                          description: 'No daily limits',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.undo,
                          title: 'Rewind',
                          description: 'Undo your last swipe',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.event,
                          title: 'Join The Events',
                          description: 'Exclusive premium events',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.verified,
                          title: 'Verified Badge',
                          description: 'Stand out with verification',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.video_call,
                          title: '3 Free Video Calls',
                          description: 'Connect face-to-face',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.star,
                          title: '1 Super Like',
                          description: 'Make a strong impression',
                        ),

                        // Promo Code Section
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Have a promo code?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _promoController,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Enter promo code',
                                          hintStyle: TextStyle(color: Colors.white70),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _applyPromoCode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    ),
                                    child: Text('Apply'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Pricing options - only show if not admin
                        if (!_isAdmin) ...[
                          SizedBox(height: 16),

                          // Show loading or products
                          if (_purchaseService.isLoading)
                            Center(
                              child: LoadingIndicator(
                                type: LoadingIndicatorType.pulse,
                                message: 'Loading products...',
                              ),
                            )
                          else if (_purchaseService.isAvailable)
                            ..._buildPricingOptions()
                          else
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'In-app purchases not available',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],

                        // Subscribe button or Continue button for admin
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isAdmin
                                  ? () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/main',
                                      (route) => false,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Admin access activated!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                                  : (_isProcessingPurchase ||
                                  _purchaseService.isLoading ||
                                  !_purchaseService.isAvailable)
                                  ? null
                                  : _handlePurchase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isProcessingPurchase
                                  ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              )
                                  : Text(
                                _isAdmin ? 'Continue with Admin Access' : 'Subscribe Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Restore purchases button
                        if (!_isAdmin && _purchaseService.isAvailable)
                          TextButton(
                            onPressed: () async {
                              await _purchaseService.restorePurchases();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Purchases restored'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'Restore Purchases',
                              style: TextStyle(
                                color: Colors.white70,
                                decoration: TextDecoration.underline,
                              ),
                            ),
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
    );
  }

  List<Widget> _buildPricingOptions() {
    final premiumProducts = _purchaseService.getPremiumProducts();

    return premiumProducts.map((product) {
      final isSelected = _selectedProductId == product.id;
      final savings = _purchaseService.calculateSavings(product.id);

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedProductId = product.id;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getProductTitle(product.id),
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
                  ],
                ),
                if (savings.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      savings,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  String _getProductTitle(String productId) {
    switch (productId) {
      case PurchaseService.kPremiumMonthly:
        return '1 Month';
      case PurchaseService.kPremium3Months:
        return '3 Months';
      case PurchaseService.kPremium6Months:
        return '6 Months';
      default:
        return 'Premium';
    }
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_isAdmin) ...[
            Spacer(),
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            )
          ],
        ],
      ),
    );
  }
}