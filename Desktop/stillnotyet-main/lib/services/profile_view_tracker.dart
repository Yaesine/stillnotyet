// lib/services/profile_view_tracker.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_manager.dart';

class ProfileViewTracker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationManager _notificationManager = NotificationManager();

  // Track profile view
  Future<void> trackProfileView(String viewedUserId) async {
    try {
      String? viewerId = FirebaseAuth.instance.currentUser?.uid;
      if (viewerId == null || viewerId == viewedUserId) return;

      // Save profile view
      await _firestore.collection('profile_views').add({
        'viewerId': viewerId,
        'viewedUserId': viewedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get viewer's name
      DocumentSnapshot viewerDoc =
      await _firestore.collection('users').doc(viewerId).get();
      Map<String, dynamic>? viewerData = viewerDoc.data() as Map<String, dynamic>?;
      String viewerName = viewerData?['name'] ?? 'Someone';

      // Send notification
      await _notificationManager.sendProfileViewNotification(
          viewedUserId,
          viewerName
      );
    } catch (e) {
      print('Error tracking profile view: $e');
    }
  }
}


// Update FirestoreService to include notifications