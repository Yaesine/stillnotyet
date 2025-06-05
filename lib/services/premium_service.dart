// lib/services/premium_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  // Singleton pattern
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache mechanism to avoid frequent Firestore checks
  bool? _cachedIsAdmin;
  bool? _cachedIsPremium;
  DateTime? _cacheExpiry;

  // Admin features list
  static const List<String> adminFeatures = [
    'unlimited_likes',
    'see_who_likes_you',
    'super_likes',
    'rewind',
    'boosts',
    'advanced_filters',
    'premium_badge',
    'read_receipts',
    'priority_matches',
    'all_premium_features'
  ];

  // Premium features (subset of admin features)
  static const List<String> premiumFeatures = [
    'see_who_likes_you',
    'unlimited_likes',
    'super_likes',
    'rewind'
  ];

  // Check if user has admin privileges
  Future<bool> isAdmin() async {
    // Check cache first (valid for 10 minutes)
    if (_cachedIsAdmin != null && _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _cachedIsAdmin!;
    }

    try {
      // Check SharedPreferences first (faster)
      final prefs = await SharedPreferences.getInstance();
      bool isAdmin = prefs.getBool('isAdmin') ?? false;

      if (!isAdmin) {
        // Double-check with Firestore
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          final userDoc = await _firestore.collection('users').doc(userId).get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            isAdmin = userData?['isAdmin'] ?? false;

            // Update local cache if user is admin
            if (isAdmin) {
              await prefs.setBool('isAdmin', true);
            }
          }
        }
      }

      // Update cache
      _cachedIsAdmin = isAdmin;
      _cacheExpiry = DateTime.now().add(Duration(minutes: 10));

      return isAdmin;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Check if user has premium status
  Future<bool> isPremium() async {
    // Admin users always have premium features
    if (await isAdmin()) {
      return true;
    }

    // Check cache
    if (_cachedIsPremium != null && _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _cachedIsPremium!;
    }

    try {
      // Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      bool isPremium = prefs.getBool('isPremium') ?? false;

      if (!isPremium) {
        // Check Firestore
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          final userDoc = await _firestore.collection('users').doc(userId).get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            isPremium = userData?['isPremium'] ?? false;

            // Check if premium is expired
            if (isPremium) {
              final premiumUntil = userData?['premiumUntil'] as Timestamp?;
              if (premiumUntil != null) {
                isPremium = premiumUntil.toDate().isAfter(DateTime.now());
              }
            }

            // Update local cache
            await prefs.setBool('isPremium', isPremium);
          }
        }
      }

      // Update cache
      _cachedIsPremium = isPremium;
      _cacheExpiry = DateTime.now().add(Duration(minutes: 10));

      return isPremium;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Check if a specific feature is available to the user
  Future<bool> hasFeature(String featureName) async {
    if (await isAdmin()) {
      return true; // Admin has all features
    }

    if (await isPremium()) {
      return premiumFeatures.contains(featureName);
    }

    return false;
  }

  // Grant admin privileges (used by promo code)
  Future<bool> grantAdminPrivileges() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
        'isPremium': true,
        'premiumUntil': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 365 * 10)), // 10 years of premium
        ),
        'adminGrantedAt': FieldValue.serverTimestamp(),
        'adminPremiumFeatures': adminFeatures,
      });

      // Update local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', true);
      await prefs.setBool('isPremium', true);

      // Update cache
      _cachedIsAdmin = true;
      _cachedIsPremium = true;
      _cacheExpiry = DateTime.now().add(Duration(minutes: 10));

      return true;
    } catch (e) {
      print('Error granting admin privileges: $e');
      return false;
    }
  }

  // Get premium expiry date
  Future<DateTime?> getPremiumExpiryDate() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      final premiumUntil = userData?['premiumUntil'] as Timestamp?;

      return premiumUntil?.toDate();
    } catch (e) {
      print('Error getting premium expiry date: $e');
      return null;
    }
  }

  // Clear cache (call when user logs out)
  void clearCache() {
    _cachedIsAdmin = null;
    _cachedIsPremium = null;
    _cacheExpiry = null;
  }
}