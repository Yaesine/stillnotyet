// lib/screens/privacy_safety_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:new_tinder_clone/screens/premium_screen.dart';
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
  bool _isLoading = true;
  bool _isBlocking = false;
  List<Map<String, dynamic>> _blockedUsers = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Load user privacy settings
    _loadPrivacySettings();
    // Load blocked users
    _loadBlockedUsers();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user's privacy settings from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // Load privacy settings with defaults if not present
          setState(() {
            _profileVisibility = userData['privacySettings']?['profileVisibility'] ?? true;
            _locationPrecise = userData['privacySettings']?['locationPrecise'] ?? true;
            _allowMessagesFromMatches = userData['privacySettings']?['allowMessagesFromMatches'] ?? true;
            _showOnlineStatus = userData['privacySettings']?['showOnlineStatus'] ?? true;
            _readReceipts = userData['privacySettings']?['readReceipts'] ?? true;
            _dataCollection = userData['privacySettings']?['dataCollection'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
      _showErrorSnackBar('Failed to load privacy settings');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get the list of blocked user IDs
      final blockListDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .get();

      List<Map<String, dynamic>> blockedUsersData = [];

      // For each blocked user ID, fetch the user data
      for (var doc in blockListDoc.docs) {
        final blockedUserId = doc.id;
        try {
          final blockedUserDoc = await _firestore.collection('users').doc(blockedUserId).get();

          if (blockedUserDoc.exists) {
            final userData = blockedUserDoc.data() as Map<String, dynamic>;
            blockedUsersData.add({
              'id': blockedUserId,
              'name': userData['name'] ?? 'Unknown User',
              'imageUrl': userData['imageUrls'] != null && (userData['imageUrls'] as List).isNotEmpty
                  ? userData['imageUrls'][0]
                  : '',
              'blockDate': doc.data()['timestamp'] ?? Timestamp.now(),
            });
          }
        } catch (e) {
          print('Error fetching blocked user $blockedUserId: $e');
        }
      }

      // Sort blocked users by most recently blocked first
      blockedUsersData.sort((a, b) {
        final aDate = a['blockDate'] as Timestamp;
        final bDate = b['blockDate'] as Timestamp;
        return bDate.compareTo(aDate);
      });

      setState(() {
        _blockedUsers = blockedUsersData;
      });
    } catch (e) {
      print('Error loading blocked users: $e');
    }
  }

  Future<void> _updateSetting(String settingName, bool value) async {
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

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a map of all privacy settings
      final privacySettings = {
        'profileVisibility': _profileVisibility,
        'locationPrecise': _locationPrecise,
        'allowMessagesFromMatches': _allowMessagesFromMatches,
        'showOnlineStatus': _showOnlineStatus,
        'readReceipts': _readReceipts,
        'dataCollection': _dataCollection,
      };

      // Update privacy settings in Firestore
      await _firestore.collection('users').doc(userId).update({
        'privacySettings': privacySettings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // If profile visibility changed, update visibility in search index
      if (settingName == 'profile_visibility') {
        await _firestore.collection('users').doc(userId).update({
          'visibleInSearch': value,
        });
      }

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
    } catch (e) {
      print('Error updating setting: $e');
      _showErrorSnackBar('Failed to update setting');

      // Revert the local state change
      setState(() {
        switch (settingName) {
          case 'profile_visibility':
            _profileVisibility = !value;
            break;
          case 'location_precise':
            _locationPrecise = !value;
            break;
          case 'allow_messages':
            _allowMessagesFromMatches = !value;
            break;
          case 'online_status':
            _showOnlineStatus = !value;
            break;
          case 'read_receipts':
            _readReceipts = !value;
            break;
          case 'data_collection':
            _dataCollection = !value;
            break;
        }
      });
    }
  }

  Future<void> _blockUser(String userId, String userName) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Add to blocked users collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update matches to prevent further communication
      // Get all matches between these users
      final matchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: currentUserId)
          .where('matchedUserId', isEqualTo: userId)
          .get();

      // Add blocked flag to matches
      for (var doc in matchesQuery.docs) {
        await doc.reference.update({'blocked': true});
      }

      // Also check reverse matches
      final reverseMatchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .where('matchedUserId', isEqualTo: currentUserId)
          .get();

      for (var doc in reverseMatchesQuery.docs) {
        await doc.reference.update({'blocked': true});
      }

      // Refresh the blocked users list
      await _loadBlockedUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been blocked'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error blocking user: $e');
      _showErrorSnackBar('Failed to block user');
    }
  }

  Future<void> _unblockUser(String userId) async {
    setState(() {
      _isBlocking = true;
    });

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Remove from blocked users collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .delete();

      // Update matches to allow communication again
      final matchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: currentUserId)
          .where('matchedUserId', isEqualTo: userId)
          .get();

      for (var doc in matchesQuery.docs) {
        await doc.reference.update({'blocked': false});
      }

      // Also update reverse matches
      final reverseMatchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .where('matchedUserId', isEqualTo: currentUserId)
          .get();

      for (var doc in reverseMatchesQuery.docs) {
        await doc.reference.update({'blocked': false});
      }

      // Update local state by removing the user from blocked list
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

      print('Error unblocking user: $e');
      _showErrorSnackBar('Error unblocking user');
    }
  }

  Future<void> _pauseAccount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Update user's active status in Firestore
      await _firestore.collection('users').doc(userId).update({
        'accountStatus': 'paused',
        'visibleInSearch': false,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account paused'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error pausing account: $e');
      _showErrorSnackBar('Failed to pause account');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // First, show a dialog asking why they want to delete their account
      final deletionReason = await _showDeletionReasonDialog();

      // If user canceled (returned null), exit the flow
      if (deletionReason == null) return;

      // Second, try to retain the user with a discount offer
      final continueWithDeletion = await _showRetentionDialog();

      // If user accepted the offer (returned false), exit the flow
      if (!continueWithDeletion) return;

      // Finally, show email verification instructions
      await _showEmailVerificationDialog();

      // No automatic account deletion - this will be handled manually after email verification
    } catch (e) {
      print('Error in delete account flow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showDeletionReasonDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String? selectedReason;

    // Common reasons for account deletion
    final reasons = [
      'I found a relationship',
      'I\'m taking a break from dating',
      'I\'m not getting enough matches',
      'The app is too expensive',
      'I\'m having technical issues',
      'I don\'t like the user experience',
      'Privacy concerns',
      'Other reason'
    ];

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'We\'re sorry to see you go',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Would you mind telling us why you\'re leaving?',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: reasons.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(reasons[index]),
                        onTap: () {
                          selectedReason = reasons[index];
                          Navigator.of(context).pop();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tileColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade50,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        hoverColor: AppColors.primary.withOpacity(0.1),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
        );
      },
    );

    return selectedReason;
  }

  Future<bool> _showRetentionDialog() async {
    bool continueWithDeletion = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.secondary,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.discount,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Wait! Special Offer Just for You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'d love to keep you around! How about 30% OFF your next Premium subscription?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Marifecto30',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.white, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: 'Marifecto30'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coupon code copied to clipboard')),
                          );
                        },
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Accept offer button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      continueWithDeletion = false;
                      Navigator.pop(context);
                      // Navigate to premium screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PremiumScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Get 30% OFF Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Continue with deletion button
                TextButton(
                  onPressed: () {
                    continueWithDeletion = true;
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'No thanks, continue with deletion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return continueWithDeletion;
  }

  Future<void> _showEmailVerificationDialog() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "your registered email";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Deletion Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For security reasons, account deletion is handled by our team.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please send an email to:',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'support@marifecto.com',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: AppColors.primary, size: 18),
                      onPressed: () {
                        // Copy email to clipboard
                        Clipboard.setData(ClipboardData(text: 'support@marifecto.com'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied to clipboard')),
                        );
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'With the subject line: ',
                    ),
                    TextSpan(
                      text: '"DELETE ACCOUNT"',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'In the body of the email, simply write "delete" and we will verify your request with the account email:',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  userEmail,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our team will process your request within 48 hours.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Optionally, log the user out after this
                Provider.of<AppAuthProvider>(context, listen: false).logout().then((_) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('I confirm'),
            ),
          ],
        );
      },
    );
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
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
                      child: user['imageUrl'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          user['imageUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            user['name'][0],
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                          : Text(
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
                      child: const Icon(
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
                                _pauseAccount();
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
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
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
                                        onPressed: () {
                                          Navigator.pop(context);
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

                                          // Execute account deletion
                                          _deleteAccount().then((_) {
                                            // Dialog will be dismissed when navigating to login
                                          }).catchError((error) {
                                            // Pop loading dialog on error
                                            Navigator.pop(context);
                                            _showErrorSnackBar('Error deleting account: $error');
                                          });
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