// lib/screens/premium_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
      _applyPromoCode();
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim();

    if (code.toLowerCase() == 'marifecto50') {
      setState(() {
        _discountApplied = true;
        _discountPercentage = 0.5; // 50% discount
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Success! 50% discount applied'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (code.isNotEmpty) {
      setState(() {
        _discountApplied = false;
        _discountPercentage = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                              if (_discountApplied) ...[
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

                        // Pricing options
                        SizedBox(height: 16),
                        _buildPriceOption('6 months', _originalPrices['6 months']!, 'Save 50%'),
                        _buildPriceOption('3 months', _originalPrices['3 months']!, 'Save 33%'),
                        _buildPriceOption('1 month', _originalPrices['1 month']!, ''),

                        // Subscribe button
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Implement subscription logic
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Subscription successful!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
                                'Subscribe Now',
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