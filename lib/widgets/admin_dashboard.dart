// lib/widgets/admin_dashboard.dart

import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final PremiumService _premiumService = PremiumService();
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isPremium = false;
  DateTime? _premiumExpiry;
  List<String> _availableFeatures = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user status
      _isAdmin = await _premiumService.isAdmin();
      _isPremium = await _premiumService.isPremium();
      _premiumExpiry = await _premiumService.getPremiumExpiryDate();

      // Determine available features
      _availableFeatures = _isAdmin
          ? PremiumService.adminFeatures
          : (_isPremium ? PremiumService.premiumFeatures : []);
    } catch (e) {
      print('Error loading status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isAdmin
                    ? Icons.admin_panel_settings
                    : (_isPremium ? Icons.workspace_premium : Icons.person),
                color: _isAdmin
                    ? Colors.purple
                    : (_isPremium ? Colors.amber : AppColors.primary),
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAdmin
                          ? 'Admin Account'
                          : (_isPremium ? 'Premium Account' : 'Standard Account'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (_premiumExpiry != null && (_isAdmin || _isPremium))
                      Text(
                        'Valid until: ${DateFormat('MMM dd, yyyy').format(_premiumExpiry!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isAdmin || _isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isAdmin ? Colors.purple : Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isAdmin ? 'ADMIN' : 'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Available Features',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          if (_availableFeatures.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No premium features available. Upgrade to premium!',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableFeatures.map((feature) {
                return Chip(
                  label: Text(
                    _formatFeatureName(feature),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: _isAdmin
                      ? Colors.purple
                      : AppColors.primary,
                );
              }).toList(),
            ),
          SizedBox(height: 16),
          if (!_isAdmin && !_isPremium)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/premium');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Upgrade to Premium'),
            ),
          if (_isAdmin)
            Text(
              'Admin account has all premium features unlocked permanently.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  String _formatFeatureName(String feature) {
    // Convert snake_case to Title Case with spaces
    return feature
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }
}