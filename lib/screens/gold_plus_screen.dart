import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gold_plus_service.dart';
import '../widgets/gold_feature_card.dart';

class GoldPlusScreen extends StatefulWidget {
  const GoldPlusScreen({Key? key}) : super(key: key);

  @override
  State<GoldPlusScreen> createState() => _GoldPlusScreenState();
}

class _GoldPlusScreenState extends State<GoldPlusScreen> {
  bool _isLoading = false;

  Future<void> _handleUpgrade() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<GoldPlusService>().upgradeToGoldPlus();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully upgraded to Gold Plus!'),
            backgroundColor: Color(0xFFFFD700),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Return to previous screen after successful upgrade
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upgrade. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Gold Plus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF2D2D2D),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Color(0xFFFFD700),
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Upgrade to Gold Plus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Get exclusive VIP features and priority matching',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exclusive Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GoldFeatureCard(
                    icon: Icons.workspace_premium,
                    title: 'Priority Matching',
                    description: 'Get your profile shown first to potential matches',
                  ),
                  const SizedBox(height: 16),
                  GoldFeatureCard(
                    icon: Icons.visibility,
                    title: 'See Who Likes You',
                    description: 'View all users who have liked your profile',
                  ),
                  const SizedBox(height: 16),
                  GoldFeatureCard(
                    icon: Icons.message,
                    title: 'Unlimited Messages',
                    description: 'Chat with anyone without restrictions',
                  ),
                  const SizedBox(height: 16),
                  GoldFeatureCard(
                    icon: Icons.verified,
                    title: 'Verified Badge',
                    description: 'Stand out with an exclusive Gold Plus badge',
                  ),
                ],
              ),
            ),

            // Upgrade Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
                    : const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}