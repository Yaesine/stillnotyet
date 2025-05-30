// Save this as test_notification_button.dart in your lib/widgets/ folder

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
      if (recipientId != null) {
        final recipientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientId!)
            .get();

        final recipientData = recipientDoc.data() as Map<String, dynamic>?;
        final recipientToken = recipientData?['fcmToken'];

        print('✅ Recipient ID: $recipientId');
        print('✅ Recipient token: ${recipientToken != null ? '${recipientToken.substring(0, 20)}...' : 'NO TOKEN'}');
      }

      // Test 3: Try to get a fresh FCM token
      print('\n📱 Requesting fresh FCM token...');
      String? freshToken = await FirebaseMessaging.instance.getToken();
      print('✅ Fresh token: ${freshToken != null ? '${freshToken.substring(0, 20)}...' : 'FAILED TO GET TOKEN'}');

      // Test 4: Create a test notification to myself
      print('\n📬 Creating test notification document...');

      final testNotificationRef = await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'type': 'test',
        'title': '🧪 Test Notification',
        'body': 'If you see this, notifications are working!',
        'recipientId': currentUserId,
        'fcmToken': myToken ?? freshToken,
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios',
        'priority': 'high',
      });

      print('✅ Test notification created: ${testNotificationRef.id}');

      // Test 5: Monitor the notification status
      print('\n⏳ Monitoring notification status...');

      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(seconds: 2));

        final notificationDoc = await testNotificationRef.get();
        final notificationData = notificationDoc.data() as Map<String, dynamic>?;
        final status = notificationData?['status'];

        print('   Check ${i + 1}: Status = $status');

        if (status == 'sent') {
          print('   ✅ Notification sent successfully!');

          // Show success snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Notification test successful!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        } else if (status == 'error') {
          print('   ❌ Error: ${notificationData?['error']}');
          print('   Error code: ${notificationData?['errorCode']}');

          // Show error snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Notification error: ${notificationData?['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        }
      }

      print('\n🧪 NOTIFICATION TEST COMPLETE\n');

    } catch (e) {
      print('❌ Test error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.science, color: Colors.orange),
      onPressed: () => testNotification(context),
      tooltip: 'Test Notifications',
    );
  }
}