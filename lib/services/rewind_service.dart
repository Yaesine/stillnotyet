// lib/services/rewind_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/streak_service.dart';
import 'firestore_service.dart';

class RewindService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final StreakService _streakService = StreakService();

  // Singleton pattern
  static final RewindService _instance = RewindService._internal();
  factory RewindService() => _instance;
  RewindService._internal();

  // Get most recent swipe
  Future<Map<String, dynamic>?> getLastSwipe() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // Get most recent swipe (only consider last 24 hours)
      final yesterday = DateTime.now().subtract(Duration(hours: 24));

      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (swipesSnapshot.docs.isEmpty) {
        return null; // No recent swipes
      }

      final swipeDoc = swipesSnapshot.docs.first;
      final swipeData = swipeDoc.data();

      return {
        'id': swipeDoc.id,
        'swipedUserId': swipeData['swipedId'],
        'liked': swipeData['liked'] ?? false,
        'superLiked': swipeData['superLiked'] ?? false,
        'timestamp': (swipeData['timestamp'] as Timestamp).toDate(),
      };
    } catch (e) {
      print('Error getting last swipe: $e');
      return null;
    }
  }

  // Check if user has available rewinds
  Future<bool> canRewind() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // First check if user is admin
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        bool isAdmin = userData['isAdmin'] ?? false;

        // Admin has unlimited rewinds
        if (isAdmin) {
          print('Admin user detected - unlimited rewinds available');
          return true;
        }

        // Also check if they have premium with rewind feature
        bool isPremium = userData['isPremium'] ?? false;
        if (isPremium) {
          // For premium users, check if they have the rewind feature
          List<dynamic> premiumFeatures = userData['premiumFeatures'] ?? [];
          if (premiumFeatures.contains('rewind') ||
              premiumFeatures.contains('all_premium_features')) {
            print('Premium user with rewind feature - unlimited rewinds available');
            return true;
          }
        }
      }

      // For non-admin users, check streak rewards
      final streakData = await _streakService.getStreakData();
      if (streakData == null) return false;

      return streakData.availableRewinds > 0;
    } catch (e) {
      print('Error checking rewind availability: $e');
      return false;
    }
  }

  // Perform rewind operation
// Modified rewind method for lib/services/rewind_service.dart
// This version doesn't deduct rewinds for admin users

  // Perform rewind operation
  Future<Map<String, dynamic>> rewind() async {
    try {
      // Get current user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'user': null
        };
      }

      // Check if user is admin or premium first
      bool isAdminOrPremium = false;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        bool isAdmin = userData['isAdmin'] ?? false;
        bool isPremium = userData['isPremium'] ?? false;

        // Admin or premium users with rewind feature don't consume rewards
        if (isAdmin) {
          print('Admin user detected - unlimited rewinds available');
          isAdminOrPremium = true;
        } else if (isPremium) {
          List<dynamic> premiumFeatures = userData['premiumFeatures'] ?? [];
          if (premiumFeatures.contains('rewind') ||
              premiumFeatures.contains('all_premium_features')) {
            print('Premium user with rewind feature');
            isAdminOrPremium = true;
          }
        }
      }

      // If not admin/premium, check if rewind is available
      if (!isAdminOrPremium) {
        final canDoRewind = await canRewind();
        if (!canDoRewind) {
          return {
            'success': false,
            'message': 'No rewinds available',
            'user': null
          };
        }
      }

      // Get last swipe
      final lastSwipe = await getLastSwipe();
      if (lastSwipe == null) {
        return {
          'success': false,
          'message': 'No recent swipes to rewind',
          'user': null
        };
      }

      // Get the user who was swiped
      final User? swipedUser = await _firestoreService.getUserData(lastSwipe['swipedUserId']);
      if (swipedUser == null) {
        return {
          'success': false,
          'message': 'User not found',
          'user': null
        };
      }

      // Delete the swipe record
      await _firestore.collection('swipes').doc(lastSwipe['id']).delete();

      // If it was a match, we need to undo that as well
      if (lastSwipe['liked'] || lastSwipe['superLiked']) {
        final matchId = '$userId-${lastSwipe['swipedUserId']}';
        final reverseMatchId = '${lastSwipe['swipedUserId']}-$userId';

        // Check if match exists
        final matchDoc = await _firestore.collection('matches').doc(matchId).get();
        if (matchDoc.exists) {
          // Delete both match records
          await _firestore.collection('matches').doc(matchId).delete();
          await _firestore.collection('matches').doc(reverseMatchId).delete();
        }
      }

      // Only use a rewind from streak rewards if NOT admin/premium
      if (!isAdminOrPremium) {
        await _streakService.useReward(RewardType.rewind, 1);
      } else {
        print('Admin/Premium user rewind - no rewards consumed');
      }

      // Return success with the recovered user
      return {
        'success': true,
        'message': 'Swipe rewound successfully',
        'user': swipedUser
      };
    } catch (e) {
      print('Error performing rewind: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'user': null
      };
    }
  }
}