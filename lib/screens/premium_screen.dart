// lib/screens/premium_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
  bool _discountApplied = false;
  double _discountPercentage = 0.0;
  bool _isAdmin = false;
  bool _isLoading = false;

  // Original prices
  final Map<String, double> _originalPrices = {
    '6 months': 14.99,
    '3 months': 19.99,
    '1 month': 29.99,
  };

  @override
  void initState() {
    super.initState();
    // Apply promo code if passed to the screen
    if (widget.promoCode != null) {
      _promoController.text = widget.promoCode!;

      // Use post-frame callback to ensure the widget is fully built
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

  // Check if user already has admin privileges
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check in SharedPreferences first (for quick access)
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool('isAdmin') ?? false;

      if (isAdmin) {
        setState(() {
          _isAdmin = true;
        });
      } else {
        // Also check Firestore for admin status
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
              // Update local preference
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Apply admin status to the user
  Future<void> _applyAdminStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isAdmin': true,
        'isPremium': true,
        'premiumUntil': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 365 * 10)), // 10 years of premium
        ),
        'adminGrantedAt': FieldValue.serverTimestamp(),
        'adminPremiumFeatures': [
          'unlimited_likes',
          'see_who_likes_you',
          'super_likes',
          'rewind',
          'boosts',
          'advanced_filters',
          'premium_badge',
          'read_receipts',
          'priority_matches',
          'all_premium_features'
        ],
      });

      // Update local preferences
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyPromoCode() async {
    final code = _promoController.text.trim();

    // Check for admin code
    if (code.toLowerCase() == 'admin1234') {
      // Apply admin privileges
      await _applyAdminStatus();
      return;
    }
    // Check for discount code
    else if (code.toLowerCase() == 'marifecto50') {
      setState(() {
        _discountApplied = true;
        _discountPercentage = 0.5; // 50% discount
      });

      // Only show SnackBar if the widget is fully built
      if (WidgetsBinding.instance.isRootWidgetAttached) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success! 50% discount applied'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    // Invalid code
    else if (code.isNotEmpty) {
      setState(() {
        _discountApplied = false;
        _discountPercentage = 0.0;
      });

      // Only show SnackBar if the widget is fully built
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

  // Get discounted price
  double _getDiscountedPrice(double originalPrice) {
    if (_discountApplied) {
      return originalPrice * (1 - _discountPercentage);
    }
    return originalPrice;
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
                        Image.asset(
                          'assets/images/premium_logo.png',
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image not found
                            return Container(
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
                            );
                          },
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

                        // Premium features
                        _buildPremiumFeature(
                          icon: Icons.workspace_premium,
                          title: 'See Who Likes You',
                          description: 'Skip the guesswork',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.favorite_border,
                          title: 'Unlimited Likes',
                          description: 'No daily limits',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.star_border,
                          title: '1 Free Super Like per week',
                          description: 'Stand out from the crowd',
                        ),
                        _buildPremiumFeature(
                          icon: Icons.cancel_outlined,
                          title: 'Rewind',
                          description: 'Undo your last swipe',
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
                                    onPressed: _isLoading ? null : _applyPromoCode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    )
                                        : Text('Apply'),
                                  ),
                                ],
                              ),
                              if (_discountApplied && !_isAdmin) ...[
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Discount applied: 50% off!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Pricing options - only show if not admin
                        if (!_isAdmin) ...[
                          SizedBox(height: 16),
                          _buildPriceOption('6 months', _originalPrices['6 months']!, 'Save 50%'),
                          _buildPriceOption('3 months', _originalPrices['3 months']!, 'Save 33%'),
                          _buildPriceOption('1 month', _originalPrices['1 month']!, ''),
                        ],

                        // Subscribe button or Continue button for admin
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isAdmin) {
                                  // Admin doesn't need to subscribe
                                  Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Admin access activated!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  // Regular subscribe flow
                                  Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Subscription successful!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                _isAdmin ? 'Continue with Admin Access' : 'Subscribe Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildPriceOption(String duration, double originalPrice, String savings) {
    final discountedPrice = _getDiscountedPrice(originalPrice);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_discountApplied) ...[
                  Row(
                    children: [
                      Text(
                        '\$${originalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '\$${discountedPrice.toStringAsFixed(2)}/month',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '\$${originalPrice.toStringAsFixed(2)}/month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            if (savings.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            if (_discountApplied && !savings.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PROMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}