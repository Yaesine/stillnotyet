// lib/screens/nearby_users_screen.dart
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_tinder_clone/screens/premium_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../animations/modern_match_animation.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/profile_view_tracker.dart';
import '../utils/custom_page_route.dart';
import '../theme/app_theme.dart';
import '../widgets/user_profile_detail.dart';
import 'modern_chat_screen.dart';

class NearbyUsersScreen extends StatefulWidget {
  const NearbyUsersScreen({Key? key}) : super(key: key);

  @override
  _NearbyUsersScreenState createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<User> _nearbyUsers = [];
  User? _currentUser;
  GeoPoint? _currentLocation;
  double _maxDistance = 50.0; // Default 50km radius

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  Future<void> _loadNearbyUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      _currentUser = await _firestoreService.getCurrentUserData();

      if (_currentUser == null) {
        print('No current user found');
        setState(() {
          _isLoading = false;
          _nearbyUsers = [];
        });
        return;
      }

      // Get or update current location
      if (_currentUser!.geoPoint == null) {
        print('Updating user location...');
        final userId = _firestoreService.currentUserId;
        if (userId != null) {
          await _locationService.updateUserLocation(userId);
          _currentUser = await _firestoreService.getCurrentUserData();
        }
      }

      _currentLocation = _currentUser!.geoPoint;

      if (_currentLocation == null) {
        print('Still no location data available');
        setState(() {
          _isLoading = false;
          _nearbyUsers = [];
        });
        return;
      }

      print('Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');

      // Get all users from Firestore
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: _currentUser!.id)
          .get();

      print('Found ${usersSnapshot.docs.length} other users in database');

      // Filter and sort by distance
      List<Map<String, dynamic>> usersWithDistance = [];

      for (var doc in usersSnapshot.docs) {
        try {
          final userData = doc.data() as Map<String, dynamic>;

          // Skip users without location data
          if (userData['geoPoint'] == null) {
            print('User ${userData['name']} has no location data');
            continue;
          }

          User user = User.fromFirestore(doc);

          if (user.geoPoint != null) {
            final distance = _locationService.calculateDistance(
              _currentLocation!,
              user.geoPoint!,
            );

            print('User ${user.name} is ${distance.toStringAsFixed(1)}km away');

            // Only include users within max distance
            if (distance <= _maxDistance) {
              usersWithDistance.add({
                'user': user,
                'distance': distance,
              });
            }
          }
        } catch (e) {
          print('Error processing user: $e');
        }
      }

      // Sort by distance
      usersWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Extract users
      _nearbyUsers = usersWithDistance
          .map((item) => item['user'] as User)
          .toList();

      print('Found ${_nearbyUsers.length} nearby users within ${_maxDistance}km');

    } catch (e) {
      print('Error loading nearby users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('People Nearby'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        actions: [
          // Distance filter button
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showDistanceFilter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_currentLocation == null) {
      return _buildLocationError(isDarkMode);
    }

    if (_nearbyUsers.isEmpty) {
      return _buildEmptyView(isDarkMode);
    }

    return _buildUsersList(isDarkMode);
  }

  Widget _buildLocationError(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Location not available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please enable location services to see people nearby',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              // Try to update location
              final userId = _firestoreService.currentUserId;
              if (userId != null) {
                await _locationService.updateUserLocation(userId);
                _loadNearbyUsers();
              }
            },
            icon: const Icon(Icons.location_on),
            label: const Text('Enable Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No people nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try expanding your distance preference to see more people',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showDistanceFilter,
                icon: const Icon(Icons.tune),
                label: Text('Distance: ${_maxDistance.round()}km'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loadNearbyUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _loadNearbyUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nearbyUsers.length,
        itemBuilder: (context, index) {
          final user = _nearbyUsers[index];
          double distance = 0;

          if (_currentLocation != null && user.geoPoint != null) {
            distance = _locationService.calculateDistance(
              _currentLocation!,
              user.geoPoint!,
            );
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isDarkMode ? 0 : 2,
            color: isDarkMode ? AppColors.darkCard : Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 32,
                backgroundImage: user.imageUrls.isNotEmpty
                    ? NetworkImage(user.imageUrls[0])
                    : null,
                backgroundColor: AppColors.primary,
                child: user.imageUrls.isEmpty
                    ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              title: Row(
                children: [
                  Text(
                    '${user.name}, ${user.age}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (distance < 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Very Close',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
                ),
                onPressed: () {
                  // Navigate to profile detail
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileDetail(user: user),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDistanceFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Maximum Distance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_maxDistance.round()} km',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: AppColors.primary,
                    inactiveColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade300,
                    onChanged: (value) {
                      setModalState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                            _loadNearbyUsers();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

