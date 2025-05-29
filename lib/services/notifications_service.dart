// lib/services/notifications_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No Firebase initialization here - it's done in main.dart
  print('Handling a background message: ${message.messageId}');
  print('Background message data: ${message.data}');
  print('Background notification: ${message.notification?.title}');
}

class NotificationsService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification services
  Future<void> initialize() async {
    try {
      print('Initializing notification services...');

      // Request permission with a more comprehensive request
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      print('User notification permission status: ${settings.authorizationStatus}');

      // For iOS, set the foreground presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Get initial message if app was opened from a terminated state
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from terminated state with message: ${initialMessage.messageId}');
        // Note: You'll handle this navigation in NotificationManager
      }

      // Get the FCM token and print it for debugging
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      print('Notification services initialized successfully');
    } catch (e) {
      print('Error initializing notification services: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Save the FCM token to Firestore for the current user
  Future<void> saveTokenToDatabase(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        print('Saving FCM token to database for user: $userId');
        await _firestore
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': 'ios', // Mark the user's platform
        });
        print('FCM token saved successfully');
      } else {
        print('No FCM token available to save');
      }
    } catch (e) {
      print('Error saving FCM token to database: $e');
    }
  }

  // Remove FCM token when user logs out
  Future<void> removeTokenFromDatabase(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'fcmToken': FieldValue.delete(),
      });
      print('FCM token removed from database for user: $userId');
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }
}