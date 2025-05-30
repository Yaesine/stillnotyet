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