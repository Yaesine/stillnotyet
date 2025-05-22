import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({Key? key, required this.child}) : super(key: key);

  @override
  _NotificationHandlerState createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    // Listen for FCM token changes
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('FCM Token: $token');
      // Save token to Firestore
      _saveTokenToFirestore(token);
    });

    // Handle notification tap while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showInAppNotification(message);
    });
  }

  void _showInAppNotification(RemoteMessage message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child; // Wrap the child widget
  }
}