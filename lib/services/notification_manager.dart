// lib/services/notification_manager.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/navigation.dart';
import '../theme/app_theme.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // A flag to track if the manager has been initialized
  bool _isInitialized = false;

  // Initialize notifications with better error handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {

      print('Initializing NotificationManager...');
      await _configureFirebaseMessaging();
      _isInitialized = true;
      print('NotificationManager initialized successfully');
    } catch (e) {
      print('Error initializing NotificationManager: $e');
    }
    await checkNotificationStatus();

  }

  // Configure Firebase messaging handlers
  Future<void> _configureFirebaseMessaging() async {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteNotificationTap);

    // Check if the app was opened from a notification when it was terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state with notification');
      // Delay handling to ensure the app is fully initialized
      Future.delayed(Duration(seconds: 1), () {
        _handleRemoteNotificationTap(initialMessage);
      });
    }

    // Re-save the token to ensure it's up to date
    await _saveTokenToFirestore();
  }

  // Handle foreground messages with better error handling
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print('Received foreground message:');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
      print('  Data: ${message.data}');

      if (message.notification != null) {
        _showInAppNotification(message);
      }
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  // Show in-app notification with improved UI and error handling
  void _showInAppNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('Cannot show in-app notification: No context available');
      return;
    }

    try {
      // Get theme information
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final backgroundColor = isDarkMode ? AppColors.darkCard : Colors.white;
      final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
      final actionColor = AppColors.primary;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            message.notification?.title ?? 'Notification',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message.notification?.body ?? '',
            style: TextStyle(color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Dismiss', style: TextStyle(color: textColor)),
            ),
            if (message.data['type'] != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleRemoteNotificationTap(message);
                },
                child: Text('View', style: TextStyle(color: actionColor, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing in-app notification: $e');
    }
  }

  // Handle notification tap with improved logging and error handling
  void _handleRemoteNotificationTap(RemoteMessage message) {
    try {
      print('User tapped on notification:');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
      print('  Data: ${message.data}');

      final type = message.data['type'];
      final id = message.data['id'] ?? message.data['senderId'];

      _navigateBasedOnType(type, id);
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Navigate based on notification type with better routing
  void _navigateBasedOnType(String? type, String? id) {
    if (type == null) {
      print('Cannot navigate: Notification type is null');
      return;
    }

    try {
      print('Navigating based on notification type: $type, ID: $id');

      switch (type) {
        case 'match':
        // First make sure we're at the main screen, then navigate to the matches tab
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/main',
                (route) => false,
            arguments: {'initialTab': 3}, // Index of matches tab
          );
          break;

        case 'message':
          if (id != null) {
            // Get user data before navigating
            _getUserDataAndNavigate(id);
          } else {
            // If no specific user ID, go to matches tab
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/main',
                  (route) => false,
              arguments: {'initialTab': 3}, // Index of matches tab
            );
          }
          break;

        case 'super_like':
        case 'profile_view':
        // Navigate to likes tab
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/main',
                (route) => false,
            arguments: {'initialTab': 2}, // Index of likes tab
          );
          break;

        default:
        // Default to home tab
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/main',
                (route) => false,
          );
      }
    } catch (e) {
      print('Error navigating from notification: $e');
      // Fallback to main screen if navigation fails
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }

  // Get user data and navigate to chat with better error handling
  Future<void> _getUserDataAndNavigate(String userId) async {
    try {
      print('Getting user data for chat navigation: $userId');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // Extract the minimum data needed for chat
          final user = {
            'id': userId,
            'name': userData['name'] ?? 'User',
            'imageUrls': userData['imageUrls'] ?? [],
          };

          // Navigate to chat screen with user data
          navigatorKey.currentState?.pushNamed(
            '/chat',
            arguments: user,
          );
          print('Navigated to chat with user: ${userData['name']}');
        } else {
          print('User data is null');
          // Fallback to matches screen
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/main',
                (route) => false,
            arguments: {'initialTab': 3},
          );
        }
      } else {
        print('User document does not exist');
        // Fallback to matches screen
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/main',
              (route) => false,
          arguments: {'initialTab': 3},
        );
      }
    } catch (e) {
      print('Error getting user data for navigation: $e');
      // Fallback to main screen if all else fails
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }

  // Save FCM token to Firestore with retry logic
  Future<void> _saveTokenToFirestore() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (token != null && userId != null) {
        print('Saving FCM token to Firestore: $token');

        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'tokenTimestamp': FieldValue.serverTimestamp(),
          'platform': 'ios', // Mark iOS platform specifically
          'appVersion': '1.0.0', // Add app version for tracking
        });

        print('FCM Token saved to Firestore successfully');
      } else {
        print('Cannot save FCM token: token=$token, userId=$userId');
      }
    } catch (e) {
      print('Error saving FCM token to Firestore: $e');
      // Retry once after a delay
      await Future.delayed(Duration(seconds: 5));
      try {
        String? token = await _firebaseMessaging.getToken();
        String? userId = FirebaseAuth.instance.currentUser?.uid;

        if (token != null && userId != null) {
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': token,
            'tokenTimestamp': FieldValue.serverTimestamp(),
          });
          print('FCM Token saved to Firestore on retry');
        }
      } catch (retryError) {
        print('Error on retry saving FCM token: $retryError');
      }
    }
  }

  // Create notification in Firestore (for cloud functions to send)
  Future<void> _createNotificationDocument({
    required String type,
    required String title,
    required String body,
    required String recipientId,
    required String? fcmToken,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (fcmToken == null) {
        print('Cannot create notification: FCM token is null');
        return;
      }

      final notificationId = 'notification_${DateTime.now().millisecondsSinceEpoch}_${recipientId}';

      await _firestore.collection('notifications').doc(notificationId).set({
        'type': type,
        'title': title,
        'body': body,
        'recipientId': recipientId,
        'fcmToken': fcmToken,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios', // Specify iOS platform for platform-specific formatting
        'priority': 'high', // Set high priority for important notifications
      });

      print('Notification document created for $recipientId: $type');
    } catch (e) {
      print('Error creating notification document: $e');
    }
  }

  // Send match notification with improved handling
  Future<void> sendMatchNotification(String recipientId, String senderName) async {
    try {
      print('Preparing match notification for $recipientId from $senderName');

      // Use the new method to get the FCM token
      String? fcmToken = await _getFcmTokenForUser(recipientId);

      if (fcmToken == null || fcmToken.isEmpty) {
        print('Cannot send match notification: FCM token not found for $recipientId');

        // Create notification without token
        await _createNotificationDocumentWithoutToken(
          type: 'match',
          title: '🎉 New Match!',
          body: 'You and $senderName liked each other!',
          recipientId: recipientId,
          data: {
            'type': 'match',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        return;
      }

      // Original notification creation with token
      await _createNotificationDocument(
        type: 'match',
        title: '🎉 New Match!',
        body: 'You and $senderName liked each other!',
        recipientId: recipientId,
        fcmToken: fcmToken,
        data: {
          'type': 'match',
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      print('Match notification prepared for $recipientId');
    } catch (e) {
      print('Error preparing match notification: $e');
    }
  }

  // Add this function to your notification_manager.dart

  Future<void> sendTestNotification() async {
    try {
      final myToken = await FirebaseMessaging.instance.getToken();
      if (myToken == null) {
        print('Cannot get FCM token for test notification');
        return;
      }

      // Create a test notification document
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Test Notification',
        'body': 'This is a test notification from the app',
        'fcmToken': myToken,
        'recipientId': FirebaseAuth.instance.currentUser!.uid,
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'ios',
      });

      print('Test notification document created');
    } catch (e) {
      print('Error creating test notification: $e');
    }
  }
  // Add this method to the NotificationManager class
  Future<void> checkNotificationStatus() async {
    try {
      // Get the current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('No current user ID available');
        return;
      }

      // Call the cloud function
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('checkNotificationStatus').call({
        'userId': userId,
      });

      // Print the result
      print('Notification status check result:');
      print(result.data);
    } catch (e) {
      print('Error checking notification status: $e');
    }
  }
  // Send SuperLike notification with improved handling
  Future<void> sendSuperLikeNotification(String recipientId, String senderName) async {
    try {
      print('Preparing SuperLike notification for $recipientId from $senderName');

      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(recipientId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _createNotificationDocument(
          type: 'super_like',
          title: '⭐ Super Like!',
          body: '$senderName super liked your profile!',
          recipientId: recipientId,
          fcmToken: fcmToken,
          data: {
            'type': 'super_like',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        print('SuperLike notification prepared for $recipientId');
      } else {
        print('Cannot send SuperLike notification: FCM token not found for $recipientId');
      }
    } catch (e) {
      print('Error preparing SuperLike notification: $e');
    }
  }

  // Send SuperLike match notification with improved handling
  Future<void> sendSuperLikeMatchNotification(String recipientId, String senderName) async {
    try {
      print('Preparing SuperLike match notification for $recipientId from $senderName');

      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(recipientId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _createNotificationDocument(
          type: 'match',
          title: '✨ SUPER Match!',
          body: '$senderName super liked you and it\'s a match!',
          recipientId: recipientId,
          fcmToken: fcmToken,
          data: {
            'type': 'match',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        print('SuperLike match notification prepared for $recipientId');
      } else {
        print('Cannot send SuperLike match notification: FCM token not found for $recipientId');
      }
    } catch (e) {
      print('Error preparing SuperLike match notification: $e');
    }
  }

  // New method to handle missing FCM tokens
  Future<String?> _getFcmTokenForUser(String userId) async {
    try {
      print('Getting FCM token for user: $userId');
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('User document not found for ID: $userId');
        return null;
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        print('No FCM token found for user: $userId');

        // For testing purposes only: If the user doesn't have a token,
        // provide a fallback token for debug users
        if (userId == 'M1uABjXQ13dPxiTGVgi7UI6NKYf1' || userId.startsWith('test_user')) {
          String debugToken = await _firebaseMessaging.getToken() ?? '';
          print('Using debug token for testing: $debugToken');

          // Only update test user documents
          if (userId.startsWith('test_user')) {
            try {
              await _firestore.collection('users').doc(userId).update({
                'fcmToken': debugToken,
                'tokenTimestamp': FieldValue.serverTimestamp(),
                'platform': 'ios', // Assuming iOS for testing
              });
              print('Updated test user with debug token');
            } catch (e) {
              print('Error updating test user token: $e');
            }
          }

          return debugToken;
        }

        return null;
      }

      print('Found FCM token for user: $userId');
      return fcmToken;
    } catch (e) {
      print('Error getting FCM token for user: $e');
      return null;
    }
  }


  // Send profile view notification with improved handling
  Future<void> sendProfileViewNotification(String profileOwnerId, String viewerName) async {
    try {
      print('Preparing profile view notification for $profileOwnerId from $viewerName');

      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(profileOwnerId).get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        await _createNotificationDocument(
          type: 'profile_view',
          title: '👀 Profile View',
          body: '$viewerName viewed your profile',
          recipientId: profileOwnerId,
          fcmToken: fcmToken,
          data: {
            'type': 'profile_view',
            'viewerId': FirebaseAuth.instance.currentUser?.uid,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        print('Profile view notification prepared for $profileOwnerId');
      } else {
        print('Cannot send profile view notification: FCM token not found for $profileOwnerId');
      }
    } catch (e) {
      print('Error preparing profile view notification: $e');
    }
  }
  Future<void> _createNotificationDocumentWithoutToken({
    required String type,
    required String title,
    required String body,
    required String recipientId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notificationId = 'notification_${DateTime.now().millisecondsSinceEpoch}_${recipientId}';

      await _firestore.collection('notifications').doc(notificationId).set({
        'type': type,
        'title': title,
        'body': body,
        'recipientId': recipientId,
        'fcmToken': null, // No token available
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending_token', // Special status to indicate waiting for token
        'platform': 'unknown',
        'priority': 'high',
      });

      print('Created notification document without token for $recipientId: $type');
    } catch (e) {
      print('Error creating notification document without token: $e');
    }
  }
  // Send message notification with improved handling
  Future<void> sendMessageNotification(
      String recipientId,
      String senderName,
      String messageText
      ) async {
    try {
      print('Preparing message notification for $recipientId from $senderName');

      // Use the new method to get the FCM token
      String? fcmToken = await _getFcmTokenForUser(recipientId);

      if (fcmToken == null || fcmToken.isEmpty) {
        print('Cannot send message notification: FCM token not found for $recipientId');

        // Still create a notification document even without a token
        // This way when the user gets a token, pending notifications can be processed
        await _createNotificationDocumentWithoutToken(
          type: 'message',
          title: '💌 New Message',
          body: '$senderName: ${messageText.length > 50 ? messageText.substring(0, 47) + '...' : messageText}',
          recipientId: recipientId,
          data: {
            'type': 'message',
            'senderId': FirebaseAuth.instance.currentUser?.uid,
            'messageText': messageText.length > 100 ? messageText.substring(0, 97) + '...' : messageText,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        return;
      }

      // Original notification creation with token
      await _createNotificationDocument(
        type: 'message',
        title: '💌 New Message',
        body: '$senderName: ${messageText.length > 50 ? messageText.substring(0, 47) + '...' : messageText}',
        recipientId: recipientId,
        fcmToken: fcmToken,
        data: {
          'type': 'message',
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'messageText': messageText.length > 100 ? messageText.substring(0, 97) + '...' : messageText,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      print('Message notification prepared for $recipientId');
    } catch (e) {
      print('Error preparing message notification: $e');
    }
  }

}