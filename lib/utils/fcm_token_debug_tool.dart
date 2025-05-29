// lib/utils/fcm_token_debug_tool.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class FCMTokenDebugTool {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check FCM token status for a specific user
  static Future<Map<String, dynamic>> checkUserFCMToken(String userId) async {
    try {
      print('Checking FCM token for user: $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {
          'status': 'error',
          'message': 'User document not found',
          'userId': userId,
        };
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      final fcmToken = data?['fcmToken'];
      final tokenTimestamp = data?['tokenUpdatedAt'] as Timestamp?;
      final platform = data?['platform'];

      return {
        'status': fcmToken != null ? 'has_token' : 'no_token',
        'userId': userId,
        'hasToken': fcmToken != null,
        'tokenPrefix': fcmToken != null ? '${fcmToken.substring(0, 20)}...' : null,
        'lastUpdated': tokenTimestamp?.toDate().toString(),
        'platform': platform,
        'userName': data?['name'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
        'userId': userId,
      };
    }
  }

  // Check all users and find those without FCM tokens
  static Future<Map<String, dynamic>> findUsersWithoutTokens() async {
    try {
      print('=== Checking all users for FCM tokens ===');

      final usersSnapshot = await _firestore.collection('users').get();

      int totalUsers = 0;
      int usersWithTokens = 0;
      int usersWithoutTokens = 0;
      List<Map<String, dynamic>> usersWithoutTokensList = [];

      for (var doc in usersSnapshot.docs) {
        totalUsers++;
        final data = doc.data();
        final fcmToken = data['fcmToken'];

        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          usersWithTokens++;
        } else {
          usersWithoutTokens++;
          usersWithoutTokensList.add({
            'userId': doc.id,
            'name': data['name'] ?? 'Unknown',
            'email': data['email'] ?? 'No email',
            'lastActive': data['lastActive'],
          });
        }
      }

      print('\n=== FCM Token Report ===');
      print('Total users: $totalUsers');
      print('Users with tokens: $usersWithTokens');
      print('Users without tokens: $usersWithoutTokens');

      if (usersWithoutTokensList.isNotEmpty) {
        print('\nUsers without FCM tokens:');
        for (var user in usersWithoutTokensList) {
          print('- ${user['name']} (${user['userId']}) - ${user['email']}');
        }
      }

      print('=== End Report ===\n');

      return {
        'totalUsers': totalUsers,
        'usersWithTokens': usersWithTokens,
        'usersWithoutTokens': usersWithoutTokens,
        'usersWithoutTokensList': usersWithoutTokensList,
      };
    } catch (e) {
      print('Error checking users: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  // Fix missing FCM token for current user
  static Future<bool> fixCurrentUserToken() async {
    try {
      print('Attempting to fix FCM token for current user...');

      // Request permission first
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('Notification permission denied');
        return false;
      }

      // Get fresh token
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('Failed to get FCM token');
        return false;
      }

      print('Got FCM token: ${token.substring(0, 20)}...');

      // Save to current user's document
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        print('No current user logged in');
        return false;
      }

      await _firestore.collection('users').doc(currentUserId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'ios',
        'tokenFixed': true,
        'tokenFixedAt': DateTime.now().toIso8601String(),
      });

      print('FCM token saved successfully for user: $currentUserId');
      return true;
    } catch (e) {
      print('Error fixing FCM token: $e');
      return false;
    }
  }

  // Fix FCM token for a specific user (admin function)
  static Future<bool> fixTokenForUser(String userId) async {
    try {
      print('Attempting to fix FCM token for user: $userId');

      // Get current user's token as a fallback for testing
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('Failed to get FCM token');
        return false;
      }

      // Note: In production, you should NOT use the same token for multiple users
      // This is only for testing purposes
      print('WARNING: Using current device token for testing purposes');

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'ios',
        'tokenFixed': true,
        'tokenFixedBy': FirebaseAuth.instance.currentUser?.uid,
        'tokenFixedAt': DateTime.now().toIso8601String(),
      });

      print('FCM token saved for user: $userId (TEST MODE)');
      return true;
    } catch (e) {
      print('Error fixing FCM token for user: $e');
      return false;
    }
  }

  // Test notification sending
  static Future<bool> testNotificationToUser(String recipientUserId) async {
    try {
      print('Testing notification to user: $recipientUserId');

      // Get the actual FCM token from the user document
      final userDoc = await _firestore.collection('users').doc(recipientUserId).get();
      if (!userDoc.exists) {
        print('User document not found');
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      final fcmToken = userData?['fcmToken'];

      if (fcmToken == null || fcmToken.toString().isEmpty) {
        print('ERROR: Recipient does not have FCM token!');
        return false;
      }

      // Create test notification
      await _firestore.collection('notifications').add({
        'type': 'test',
        'title': '🧪 Test Notification',
        'body': 'This is a test notification to verify FCM is working',
        'recipientId': recipientUserId,
        'fcmToken': fcmToken,
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios',
      });

      print('Test notification document created');
      return true;
    } catch (e) {
      print('Error testing notification: $e');
      return false;
    }
  }
}

// Debug widget to add to your settings or profile screen
class FCMDebugWidget extends StatefulWidget {
  const FCMDebugWidget({Key? key}) : super(key: key);

  @override
  State<FCMDebugWidget> createState() => _FCMDebugWidgetState();
}

class _FCMDebugWidgetState extends State<FCMDebugWidget> {
  bool _isLoading = false;
  String? _lastResult;

  void _showResult(String message) {
    setState(() {
      _lastResult = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _performAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await action();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FCM Token Debug Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use these tools to diagnose notification issues',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            Column(
              children: [
                _buildDebugButton(
                  'Check My FCM Token',
                  Icons.search,
                      () async {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      final status = await FCMTokenDebugTool.checkUserFCMToken(userId);
                      _showResult(status['hasToken']
                          ? 'You have an FCM token ✅'
                          : 'You do NOT have an FCM token ❌');
                    } else {
                      _showResult('Not logged in');
                    }
                  },
                ),
                const SizedBox(height: 12),

                _buildDebugButton(
                  'Fix My FCM Token',
                  Icons.build,
                      () async {
                    final fixed = await FCMTokenDebugTool.fixCurrentUserToken();
                    _showResult(fixed
                        ? 'FCM token fixed successfully! ✅'
                        : 'Failed to fix FCM token ❌');
                  },
                ),
                const SizedBox(height: 12),

                _buildDebugButton(
                  'Check All Users Tokens',
                  Icons.group,
                      () async {
                    final result = await FCMTokenDebugTool.findUsersWithoutTokens();
                    final total = result['totalUsers'] ?? 0;
                    final withTokens = result['usersWithTokens'] ?? 0;
                    final withoutTokens = result['usersWithoutTokens'] ?? 0;

                    _showResult('Total: $total, With tokens: $withTokens, Without: $withoutTokens');
                  },
                ),
                const SizedBox(height: 12),

                _buildDebugButton(
                  'Send Test Notification',
                  Icons.notifications,
                      () async {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      final sent = await FCMTokenDebugTool.testNotificationToUser(userId);
                      _showResult(sent
                          ? 'Test notification sent! 📱'
                          : 'Failed to send test notification ❌');
                    } else {
                      _showResult('Not logged in');
                    }
                  },
                ),
              ],
            ),

          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkBackground.withOpacity(0.5)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastResult!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugButton(String label, IconData icon, VoidCallback onPressed) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _performAction(() async => onPressed()),
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}