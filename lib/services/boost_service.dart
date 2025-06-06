import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final BoostService _instance = BoostService._internal();
  factory BoostService() => _instance;
  BoostService._internal();

  // Get current user's available boosts
  Future<int> getAvailableBoosts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['availableBoosts'] ?? 0;
    } catch (e) {
      print('Error getting available boosts: $e');
      return 0;
    }
  }

  // Activate a boost
  Future<bool> activateBoost() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Get user's current boost count
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final availableBoosts = userDoc.data()?['availableBoosts'] ?? 0;

      if (availableBoosts <= 0) {
        return false;
      }

      // Check if user already has an active boost
      final activeBoost = userDoc.data()?['activeBoost'];
      if (activeBoost != null) {
        final boostEndTime = (activeBoost['endTime'] as Timestamp).toDate();
        if (boostEndTime.isAfter(DateTime.now())) {
          return false; // Boost already active
        }
      }

      // Calculate boost end time (30 minutes from now)
      final boostEndTime = DateTime.now().add(Duration(minutes: 30));

      // Update user document with active boost and decrement available boosts
      await _firestore.collection('users').doc(userId).update({
        'activeBoost': {
          'startTime': FieldValue.serverTimestamp(),
          'endTime': Timestamp.fromDate(boostEndTime),
        },
        'availableBoosts': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error activating boost: $e');
      return false;
    }
  }

  // Check if user has an active boost
  Future<bool> hasActiveBoost() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final activeBoost = userDoc.data()?['activeBoost'];

      if (activeBoost == null) return false;

      final boostEndTime = (activeBoost['endTime'] as Timestamp).toDate();
      return boostEndTime.isAfter(DateTime.now());
    } catch (e) {
      print('Error checking active boost: $e');
      return false;
    }
  }

  // Get remaining boost time in minutes
  Future<int> getRemainingBoostTime() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final activeBoost = userDoc.data()?['activeBoost'];

      if (activeBoost == null) return 0;

      final boostEndTime = (activeBoost['endTime'] as Timestamp).toDate();
      final now = DateTime.now();

      if (boostEndTime.isBefore(now)) return 0;

      return boostEndTime.difference(now).inMinutes;
    } catch (e) {
      print('Error getting remaining boost time: $e');
      return 0;
    }
  }
}