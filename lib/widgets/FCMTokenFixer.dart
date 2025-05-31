// Add this to your MainScreen's initState or create a button to call this

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FCMTokenFixer {
  static Future<bool> fixMyFCMToken() async {
    try {
      print('\n🔧 FIXING FCM TOKEN...');

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in!');
        return false;
      }

      print('👤 Current user: ${currentUser.uid}');

      // Request notification permission first
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('🔔 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('❌ Notification permission denied!');
        return false;
      }

      // Get fresh FCM token
      String? token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        print('❌ Failed to get FCM token!');
        return false;
      }

      print('✅ Got FCM token: ${token.substring(0, 20)}...');

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'ios',
        'appVersion': '1.0.0',
      });

      print('✅ FCM token saved to Firestore!');

      // Verify it was saved
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final savedToken = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];

      if (savedToken == token) {
        print('✅ Token verified in Firestore!');
        print('\n🎉 FCM TOKEN FIXED SUCCESSFULLY!\n');
        return true;
      } else {
        print('❌ Token verification failed!');
        return false;
      }

    } catch (e) {
      print('❌ Error fixing FCM token: $e');
      return false;
    }
  }

  static Future<void> debugNotificationPermissions() async {
    try {
      print("\n🔍 DEBUGGING NOTIFICATION PERMISSIONS");

      // Check current permission status
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      print("📱 Current permission status: ${settings.authorizationStatus}");

      // Request permissions if not authorized
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print("⚠️ Notifications not authorized. Requesting permissions...");
        final newSettings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          criticalAlert: false,
          carPlay: false,
          announcement: false,
          provisional: false,
        );
        print("📱 New permission status: ${newSettings.authorizationStatus}");
      }

      // Check FCM token
      final token = await FirebaseMessaging.instance.getToken();
      print(token != null
          ? "✅ FCM token available: ${token.substring(0, 10)}..."
          : "❌ FCM token not available");

      // Check user document
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final storedToken = userData?['fcmToken'];

          print(storedToken != null
              ? "✅ Token in Firestore: ${storedToken.toString().substring(0, 10)}..."
              : "❌ No token in Firestore");

          if (token != storedToken) {
            print("⚠️ Token mismatch - updating in Firestore");
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'fcmToken': token,
              'tokenUpdatedAt': FieldValue.serverTimestamp(),
            });
            print("✅ Token updated in Firestore");
          }
        }
      }

      // Send test notification
      print("📤 Sending test notification...");
      await sendTestNotification();

      print("🔍 NOTIFICATION DEBUGGING COMPLETE\n");
    } catch (e) {
      print("❌ Error debugging notifications: $e");
    }
  }

  static Future<void> sendTestNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final notificationId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
        'type': 'test',
        'title': 'Test Notification',
        'body': 'This is a test notification',
        'recipientId': user.uid,
        'fcmToken': token,
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios',
        'priority': 'high',
      });

      print("✅ Test notification created with ID: $notificationId");
    } catch (e) {
      print("❌ Error sending test notification: $e");
    }
  }

  // Add this to the FCMTokenFixer class
  static Future<bool> sendTestMatchNotification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Get current user's FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return false;

      // Create a test match notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'match',
        'title': '🎉 New Match!',
        'body': 'You and Someone liked each other!',
        'recipientId': currentUser.uid,
        'fcmToken': token,
        'data': {
          'type': 'match',
          'senderId': 'test_user',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios',
        'priority': 'high',
        'isTest': true,
      });

      print('Test match notification created');
      return true;
    } catch (e) {
      print('Error creating test match notification: $e');
      return false;
    }
  }

  // Add this to your FCMTokenFixer class in lib/widgets/FCMTokenFixer.dart
  static Future<void> debugMatchNotifications() async {
    try {
      print("\n🔍 DEBUGGING MATCH NOTIFICATIONS");

      // 1. Check FCM token
      final token = await FirebaseMessaging.instance.getToken();
      print(token != null
          ? "✅ FCM token available: ${token.substring(0, 10)}..."
          : "❌ FCM token not available");

      // 2. Create a test match notification document
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No user logged in");
        return;
      }

      // 3. Create test notification
      final notificationId = 'test_match_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
        'type': 'match',
        'title': '🎉 Test Match Notification',
        'body': 'This is a test match notification',
        'recipientId': user.uid,
        'fcmToken': token,
        'data': {
          'type': 'match',
          'senderId': 'test_sender',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios',
        'priority': 'high',
        'urgent': true,
      });

      print("✅ Test match notification created with ID: $notificationId");
      print("🔍 MATCH NOTIFICATION DEBUGGING COMPLETE\n");
    } catch (e) {
      print("❌ Error debugging match notifications: $e");
    }
  }

  // Also add this method to fix token on every app launch
  static Future<void> ensureTokenOnStartup() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Check if user has a token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final existingToken = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];

      if (existingToken == null || existingToken.toString().isEmpty) {
        print('🔧 User missing FCM token, fixing...');
        await fixMyFCMToken();
      } else {
        print('✅ User has FCM token');

        // Still get a fresh token to ensure it's current
        String? freshToken = await FirebaseMessaging.instance.getToken();
        if (freshToken != null && freshToken != existingToken) {
          print('🔄 Token changed, updating...');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'fcmToken': freshToken,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error ensuring token: $e');
    }
  }
}

// Add this button to your UI temporarily
class FixTokenButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final success = await FCMTokenFixer.fixMyFCMToken();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '✅ FCM token fixed! Try sending a message now.'
                : '❌ Failed to fix token. Check console for details.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      },
      child: Text('Fix My Notifications'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}