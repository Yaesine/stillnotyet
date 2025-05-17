// lib/services/notifications_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No need to initialize Firebase as it's done in main.dart
  print('Handling a background message: ${message.messageId}');
}

class NotificationsService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Use in-app dialog instead of local notification
        _showInAppDialog(message);
      }
    });

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // We'll handle navigation in NotificationManager
    });

    // Get the token each time the application loads
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  void _showInAppDialog(RemoteMessage message) {
    // The context isn't available here.
    // This functionality is handled in NotificationManager instead
    print('Would show in-app dialog for: ${message.notification?.title}');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Save the FCM token to Firestore for the current user
  Future<void> saveTokenToDatabase(String userId) async {
    String? token = await getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }
}