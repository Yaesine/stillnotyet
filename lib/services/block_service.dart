import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/blocked_user_model.dart';
import '../models/user_model.dart' as app_user;

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Block a user
  Future<void> blockUser(app_user.User userToBlock) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Add to blocked users collection
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(userToBlock.id)
        .set({
      'userId': userToBlock.id,
      'userName': userToBlock.name,
      'blockedAt': FieldValue.serverTimestamp(),
    });

    // Remove any existing matches between the users
    await _removeMatches(currentUserId, userToBlock.id);
  }

  // Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(blockedUserId)
        .delete();
  }

  // Get all blocked users
  Stream<List<BlockedUser>> getBlockedUsers() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BlockedUser.fromMap(doc.data()))
          .toList();
    });
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(userId)
        .get();

    return doc.exists;
  }

  // Remove matches between users
  Future<void> _removeMatches(String userId1, String userId2) async {
    // Remove match from user1's matches
    final matchQuery1 = await _firestore
        .collection('matches')
        .where('userId', isEqualTo: userId1)
        .where('matchedUserId', isEqualTo: userId2)
        .get();

    for (var doc in matchQuery1.docs) {
      await doc.reference.delete();
    }

    // Remove match from user2's matches
    final matchQuery2 = await _firestore
        .collection('matches')
        .where('userId', isEqualTo: userId2)
        .where('matchedUserId', isEqualTo: userId1)
        .get();

    for (var doc in matchQuery2.docs) {
      await doc.reference.delete();
    }
  }
}