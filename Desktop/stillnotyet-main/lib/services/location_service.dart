// lib/services/location_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Mock location data for testing
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    print('Using mock location data for faster startup');

    // Return mock data that mimics what geolocator would return
    // but without the actual plugin dependency
    return {
      'latitude': 25.2048 + (_random.nextDouble() * 0.1 - 0.05),
      'longitude': 55.2708 + (_random.nextDouble() * 0.1 - 0.05),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'accuracy': 10.0,
      'altitude': 0.0,
      'heading': 0.0,
      'speed': 0.0,
      'speedAccuracy': 0.0,
    };
  }

  // Update user location in Firestore without using geocoding
  Future<void> updateUserLocation(String userId) async {
    try {
      // Get mock location
      final mockLocation = await getCurrentLocation();
      if (mockLocation == null) return;

      // Create GeoPoint for Firestore
      GeoPoint geoPoint = GeoPoint(
        mockLocation['latitude'],
        mockLocation['longitude'],
      );

      // Just use a default location name since geocoding isn't available
      String locationName = "Dubai, UAE"; // Default location

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'location': locationName,
        'geoPoint': geoPoint,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'locationAccuracy': mockLocation['accuracy'],
      });

      print('Updated user location with mock data: $locationName');
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  // Calculate distance between two GeoPoints without geolocator
  // Using Haversine formula for distance calculation
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // Radius of the earth in km

    // Convert latitude and longitude from degrees to radians
    double lat1 = _degreesToRadians(point1.latitude);
    double lon1 = _degreesToRadians(point1.longitude);
    double lat2 = _degreesToRadians(point2.latitude);
    double lon2 = _degreesToRadians(point2.longitude);

    // Haversine formula
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    double a = sin(dLat/2) * sin(dLat/2) +
        cos(lat1) * cos(lat2) *
            sin(dLon/2) * sin(dLon/2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    double distance = earthRadius * c;

    return distance;
  }

  // Helper method to convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get nearby users based on GeoPoint
  Future<List<Map<String, dynamic>>> getNearbyUsers(
      String currentUserId,
      GeoPoint currentLocation,
      double maxDistance,
      {int limit = 50}
      ) async {
    try {
      // Get all users except current user
      final usersSnapshot = await _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> nearbyUsers = [];

      // Filter users by distance
      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();

        if (userData.containsKey('geoPoint')) {
          final userGeoPoint = userData['geoPoint'] as GeoPoint;
          final distance = calculateDistance(currentLocation, userGeoPoint);

          if (distance <= maxDistance) {
            nearbyUsers.add({
              ...userData,
              'distance': distance.toStringAsFixed(1),
            });
          }
        }
      }

      // Sort by distance
      nearbyUsers.sort((a, b) =>
          double.parse(a['distance']).compareTo(double.parse(b['distance']))
      );

      return nearbyUsers;
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  // Get user's last known location
  Future<GeoPoint?> getUserLastLocation(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null && userData.containsKey('geoPoint')) {
        return userData['geoPoint'] as GeoPoint;
      }

      return null;
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }
}