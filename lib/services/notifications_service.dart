// lib/services/notifications_service.dart - Updated with automatic token management

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

      // Automatically get and save FCM token
      await _autoSaveToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await _saveTokenToFirestore(newToken);
      });

      print('Notification services initialized successfully');
    } catch (e) {
      print('Error initializing notification services: $e');
    }
  }

  // Automatically save token on initialization
  Future<void> _autoSaveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token obtained: $token');
        await _saveTokenToFirestore(token);
      } else {
        print('Failed to obtain FCM token');
      }
    } catch (e) {
      print('Error auto-saving FCM token: $e');
    }
  }

  // Save token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Cannot save FCM token: No authenticated user');
        return;
      }

      // Check if token has changed
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final existingToken = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];
        if (existingToken == token) {
          print('FCM token unchanged, skipping update');
          return;
        }
      }

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'ios',
      });

      print('FCM token saved to Firestore successfully');
    } catch (e) {
      print('Error saving FCM token to Firestore: $e');

      // Try with merge as fallback
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('users').doc(userId).set({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
            'platform': 'ios',
          }, SetOptions(merge: true));
          print('FCM token saved with merge option');
        }
      } catch (e2) {
        print('Error saving FCM token with merge: $e2');
      }
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