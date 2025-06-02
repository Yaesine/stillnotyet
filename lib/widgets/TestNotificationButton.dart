// lib/widgets/TestNotificationButton.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../theme/app_theme.dart';

class TestNotificationButton extends StatelessWidget {
  final String? recipientId; // Optional: pass the chat partner's ID

  const TestNotificationButton({Key? key, this.recipientId}) : super(key: key);

  Future<void> testNotification(BuildContext context) async {
    try {
      print('\n🧪 STARTING NOTIFICATION TEST');

      // Test 1: Check current user's FCM token
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ No current user!');
        _showSnackBar(context, '❌ No user logged in', Colors.red);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;
      final myToken = userData?['fcmToken'];

      print('✅ Current user ID: $currentUserId');
      print('✅ My FCM token: ${myToken != null ? '${myToken.substring(0, 20)}...' : 'NO TOKEN'}');

      // Test 2: Check recipient's FCM token (if provided)
      String? recipientName = 'Test User';
      if (recipientId != null) {
        final recipientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientId!)
            .get();

        final recipientData = recipientDoc.data() as Map<String, dynamic>?;
        final recipientToken = recipientData?['fcmToken'];
        recipientName = recipientData?['name'] ?? 'Unknown User';

        print('✅ Recipient ID: $recipientId');
        print('✅ Recipient name: $recipientName');
        print('✅ Recipient token: ${recipientToken != null ? '${recipientToken.substring(0, 20)}...' : 'NO TOKEN'}');
      }

      // Test 3: Try to get a fresh FCM token
      print('\n📱 Requesting fresh FCM token...');
      String? freshToken = await FirebaseMessaging.instance.getToken();
      print('✅ Fresh token: ${freshToken != null ? '${freshToken.substring(0, 20)}...' : 'FAILED TO GET TOKEN'}');

      // If current token is missing, update it
      if (myToken == null && freshToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'fcmToken': freshToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': 'ios',
        });
        print('✅ Updated missing FCM token in Firestore');
      }

      // Show test options dialog
      if (context.mounted) {
        _showTestOptionsDialog(context, currentUserId, myToken ?? freshToken, recipientName!);
      }

    } catch (e) {
      print('❌ Test error: $e');
      if (context.mounted) {
        _showSnackBar(context, '❌ Test error: $e', Colors.red);
      }
    }
  }

  void _showTestOptionsDialog(BuildContext context, String currentUserId, String? token, String recipientName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '🧪 Test Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),

                // Test notification options
                _buildTestOption(
                  context: context,
                  icon: Icons.message,
                  title: 'Test Message from $recipientName',
                  subtitle: 'Simulate a message notification',
                  color: Colors.blue,
                  onTap: () => _sendTestNotification(context, 'message', currentUserId, token),
                ),

                _buildTestOption(
                  context: context,
                  icon: Icons.favorite,
                  title: 'Test Match Notification',
                  subtitle: 'Simulate a new match',
                  color: Colors.pink,
                  onTap: () => _sendTestNotification(context, 'match', currentUserId, token),
                ),

                _buildTestOption(
                  context: context,
                  icon: Icons.thumb_up,
                  title: 'Test Like Notification',
                  subtitle: 'Simulate someone liking you',
                  color: Colors.purple,
                  onTap: () => _sendTestNotification(context, 'like', currentUserId, token),
                ),

                _buildTestOption(
                  context: context,
                  icon: Icons.visibility,
                  title: 'Test Profile View',
                  subtitle: 'Simulate profile view notification',
                  color: Colors.orange,
                  onTap: () => _sendTestNotification(context, 'profile_view', currentUserId, token),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _sendTestNotification(
      BuildContext context,
      String type,
      String currentUserId,
      String? token,
      ) async {
    Navigator.pop(context); // Close the bottom sheet

    if (token == null) {
      _showSnackBar(context, '❌ No FCM token available', Colors.red);
      return;
    }

    try {
      print('\n📬 Creating test $type notification...');

      // Create notification document based on type
      Map<String, dynamic> notificationData = {
        'recipientId': currentUserId,
        'fcmToken': token,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios',
        'priority': 'high',
        'isTest': true,
      };

      switch (type) {
        case 'message':
          notificationData.addAll({
            'type': 'message',
            'title': 'Marifactor',
            'body': recipientId != null
                ? '💬 Test message notification from chat'
                : '💬 Test message: Hello!',
            'data': {
              'type': 'message',
              'senderId': recipientId ?? 'test_user',
              'messageText': 'This is a test message',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          });
          break;

        case 'match':
          notificationData.addAll({
            'type': 'match',
            'title': 'Marifecto',
            'body': '🎉 Test Match! You\'ve got a new match!',
            'data': {
              'type': 'match',
              'senderId': 'test_user',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          });
          break;

        case 'like':
          notificationData.addAll({
            'type': 'like',
            'title': 'Marifecto',
            'body': '😍 Test Like: Someone likes you!',
            'data': {
              'type': 'like',
              'senderId': 'test_user',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          });
          break;

        case 'profile_view':
          notificationData.addAll({
            'type': 'profile_view',
            'title': 'Marifecto',
            'body': '👀 Test: Someone viewed your profile!',
            'data': {
              'type': 'profile_view',
              'viewerId': 'test_user',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          });
          break;
      }

      // Create the notification
      final testNotificationRef = await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);

      print('✅ Test notification created: ${testNotificationRef.id}');

      // Monitor the notification status
      _monitorNotificationStatus(context, testNotificationRef.id, type);

    } catch (e) {
      print('❌ Error creating test notification: $e');
      _showSnackBar(context, '❌ Error: $e', Colors.red);
    }
  }

  Future<void> _monitorNotificationStatus(BuildContext context, String notificationId, String type) async {
    _showSnackBar(context, '⏳ Sending test $type notification...', Colors.blue);

    // Monitor for 10 seconds
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));

      final notificationDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!notificationDoc.exists) continue;

      final data = notificationDoc.data() as Map<String, dynamic>?;
      final status = data?['status'];

      print('   Check ${i + 1}: Status = $status');

      if (status == 'sent') {
        print('   ✅ Notification sent successfully!');
        if (context.mounted) {
          _showSnackBar(context, '✅ Test $type notification sent!', Colors.green);
        }
        return;
      } else if (status == 'error') {
        final error = data?['error'] ?? 'Unknown error';
        print('   ❌ Error: $error');
        if (context.mounted) {
          _showSnackBar(context, '❌ Error: $error', Colors.red);
        }
        return;
      }
    }

    // If still pending after 10 seconds
    if (context.mounted) {
      _showSnackBar(context, '⏳ Notification still processing...', Colors.orange);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.science, color: Colors.orange),
      onPressed: () => testNotification(context),
      tooltip: 'Test Notifications',
    );
  }
}