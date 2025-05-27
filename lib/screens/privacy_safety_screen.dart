// lib/screens/privacy_safety_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_tinder_clone/screens/privacy_policy_screen.dart';
import 'package:new_tinder_clone/screens/terms_of_service_screen.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import 'dart:io' show Platform;

import 'cookie_policy_screen.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  // Privacy settings state
  bool _profileVisibility = true;
  bool _locationPrecise = true;
  bool _allowMessagesFromMatches = true;
  bool _showOnlineStatus = true;
  bool _readReceipts = true;
  bool _dataCollection = true;
  bool _isBlocking = false;

  // Placeholder list of blocked users
  final List<Map<String, dynamic>> _blockedUsers = [
    {'id': '1', 'name': 'James Wilson', 'imageUrl': ''},
    {'id': '2', 'name': 'Sarah Peterson', 'imageUrl': ''},
  ];

  @override
  void initState() {
    super.initState();
    // Load user privacy settings
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    // TODO: In a real implementation, these would be loaded from your backend
    // For now, we'll use default values

    // Simulate loading with delay
    setState(() {
      // Default settings - in real app, get these from user's profile
    });
  }

  Future<void> _updateSetting(String settingName, bool value) async {
    // TODO: In a real implementation, this would update the setting on your backend
    // For now, we'll just update the local state

    // Show a saving indicator
    setState(() {
      switch (settingName) {
        case 'profile_visibility':
          _profileVisibility = value;
          break;
        case 'location_precise':
          _locationPrecise = value;
          break;
        case 'allow_messages':
          _allowMessagesFromMatches = value;
          break;
        case 'online_status':
          _showOnlineStatus = value;
          break;
        case 'read_receipts':
          _readReceipts = value;
          break;
        case 'data_collection':
          _dataCollection = value;
          break;
      }
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setting updated'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _unblockUser(String userId) async {
    setState(() {
      _isBlocking = true;
    });

    try {
      // In a real app, call your API to unblock the user
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call

      setState(() {
        _blockedUsers.removeWhere((user) => user['id'] == userId);
        _isBlocking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isBlocking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unblocking user: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrivacyInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final dividerColor = isDarkMode ? AppColors.darkDivider : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Safety'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Settings Section
            Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            // Profile Visibility
            _buildSettingCard(
              title: 'Profile Visibility',
              subtitle: 'Control who can see your profile',
              icon: Icons.visibility,
              value: _profileVisibility,
              onChanged: (value) => _updateSetting('profile_visibility', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Profile Visibility',
                  'When turned off, your profile won\'t be shown to new people in Discover. Matches can still see your profile.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Location Settings
            _buildSettingCard(
              title: 'Precise Location',
              subtitle: 'Show your exact location to matches',
              icon: Icons.location_on,
              value: _locationPrecise,
              onChanged: (value) => _updateSetting('location_precise', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Precise Location',
                  'When enabled, your exact location is used for distance calculations. When disabled, only your approximate area is shown.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Messaging Settings
            _buildSettingCard(
              title: 'Allow Messages',
              subtitle: 'Only receive messages from matches',
              icon: Icons.message,
              value: _allowMessagesFromMatches,
              onChanged: (value) => _updateSetting('allow_messages', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Messaging Settings',
                  'When enabled, only users you\'ve matched with can send you messages.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Online Status
            _buildSettingCard(
              title: 'Show Online Status',
              subtitle: 'Let others see when you\'re active',
              icon: Icons.circle,
              value: _showOnlineStatus,
              onChanged: (value) => _updateSetting('online_status', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Online Status',
                  'When enabled, your matches can see when you\'re active on the app.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Read Receipts
            _buildSettingCard(
              title: 'Read Receipts',
              subtitle: 'Show when you\'ve read messages',
              icon: Icons.done_all,
              value: _readReceipts,
              onChanged: (value) => _updateSetting('read_receipts', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Read Receipts',
                  'When enabled, others can see when you\'ve read their messages. You\'ll also see when they\'ve read yours.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Data Collection
            _buildSettingCard(
              title: 'Activity Data',
              subtitle: 'Allow app to collect usage data',
              icon: Icons.analytics,
              value: _dataCollection,
              onChanged: (value) => _updateSetting('data_collection', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Activity Data',
                  'When enabled, we collect anonymous usage data to improve your experience and provide better matches.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            const SizedBox(height: 24),

            // Blocking Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blocked Users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: subTextColor, size: 20),
                  onPressed: () => _showPrivacyInfoDialog(
                      'Blocked Users',
                      'Blocked users cannot see your profile, send you messages, or interact with you in any way.'
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Blocked Users List
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: _blockedUsers.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.block,
                        size: 48,
                        color: subTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Users you block will appear here',
                        style: TextStyle(
                          color: subTextColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _blockedUsers.length,
                separatorBuilder: (context, index) => Divider(
                  color: dividerColor,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        user['name'][0],
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: _isBlocking
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : TextButton(
                      onPressed: () => _unblockUser(user['id']),
                      child: const Text('Unblock'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Account Deactivation Section
            Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pause_circle_outline,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      'Pause Account',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Hide your profile temporarily',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Pause Account'),
                          content: const Text(
                              'Your profile will be hidden from discovery until you unpause. Existing matches can still message you.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Account paused'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Text('Pause'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(color: dividerColor, height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently delete your account and data',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                              'This action cannot be undone. All your data, including matches and messages, will be permanently deleted.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                // Confirm with second dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: const Text('Are you absolutely sure you want to delete your account?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);

                                          try {
                                            // Show loading dialog
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => const AlertDialog(
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    CircularProgressIndicator(),
                                                    SizedBox(height: 16),
                                                    Text('Deleting account...'),
                                                  ],
                                                ),
                                              ),
                                            );

                                            // TODO: In a real app, call your API to delete the account
                                            await Future.delayed(const Duration(seconds: 2));

                                            // Pop loading dialog and navigate to login
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              await Provider.of<AppAuthProvider>(context, listen: false).logout();
                                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                            }
                                          } catch (e) {
                                            // Pop loading dialog and show error
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error deleting account: $e'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Delete'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal section
            Text(
              'Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: dividerColor, height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Terms of Service',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: dividerColor, height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cookie_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Cookie Policy',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CookiePolicyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required Function() onInfoTap,
    required bool isDarkMode,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onInfoTap,
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Platform.isIOS
                ? CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            )
                : Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}