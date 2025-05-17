import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animations/modern_match_animation.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/profile_view_tracker.dart';
import '../utils/custom_page_route.dart';
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

      if (_currentUser == null || _currentUser!.geoPoint == null) {
        // Update location first
        final userId = _firestoreService.currentUserId;
        if (userId != null) {
          await _locationService.updateUserLocation(userId);
          _currentUser = await _firestoreService.getCurrentUserData();
        }
      }

      if (_currentUser == null || _currentUser!.geoPoint == null) {
        // Still no location data
        setState(() {
          _isLoading = false;
          _nearbyUsers = [];
        });
        return;
      }

      // Get all users
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final potentialMatches = await _firestoreService.getPotentialMatches();

      // Filter and sort by distance
      List<Map<String, dynamic>> usersWithDistance = [];

      for (var user in potentialMatches) {
        if (user.geoPoint != null) {
          final distance = _locationService.calculateDistance(
            _currentUser!.geoPoint!,
            user.geoPoint!,
          );

          usersWithDistance.add({
            'user': user,
            'distance': distance,
          });
        }
      }

      // Sort by distance
      usersWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Extract users
      _nearbyUsers = usersWithDistance
          .map((item) => item['user'] as User)
          .toList();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('People Nearby'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nearbyUsers.isEmpty
          ? _buildEmptyView()
          : _buildUsersList(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No people nearby',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try expanding your distance preference to see more people',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadNearbyUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyUsers.length,
      itemBuilder: (context, index) {
        final user = _nearbyUsers[index];
        double distance = 0;

        if (_currentUser?.geoPoint != null && user.geoPoint != null) {
          distance = _locationService.calculateDistance(
            _currentUser!.geoPoint!,
            user.geoPoint!,
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(user.imageUrls[0]),
            ),
            title: Text(
              '${user.name}, ${user.age}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${distance.toStringAsFixed(1)} km away'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
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
    );
  }
}

// User Profile Detail Screen
class UserProfileDetail extends StatelessWidget {
  final User user;

  const UserProfileDetail({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tracker = ProfileViewTracker();
      tracker.trackProfileView(user.id);
    });
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                user.imageUrls.isNotEmpty ? user.imageUrls[0] : 'https://i.pravatar.cc/300?img=33',
                fit: BoxFit.cover,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(user.location),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user.bio),
                  const SizedBox(height: 24),
                  const Text(
                    'Interests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) => Chip(
                      label: Text(interest),
                      backgroundColor: Colors.red.shade100,
                      labelStyle: TextStyle(color: Colors.red.shade800),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (user.imageUrls.length > 1)
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (user.imageUrls.length > 1)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: user.imageUrls.length - 1, // Skip the first one (already shown in app bar)
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                user.imageUrls[index + 1],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Dislike user
                  Provider.of<UserProvider>(context, listen: false).swipeLeft(user.id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.close, size: 32),
              ),
              ElevatedButton(
                onPressed: () {
                  // Super like user
                  Provider.of<UserProvider>(context, listen: false).superLike(user.id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.star, size: 32),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Like user
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final matchedUser = await userProvider.swipeRight(user.id);
                  Navigator.of(context).pop();

                  // Show match animation if there's a match
                  if (matchedUser != null && context.mounted) {
                    final currentUser = userProvider.currentUser;
                    if (currentUser != null) {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return ModernMatchAnimation(
                              currentUser: currentUser,
                              matchedUser: matchedUser,
                              onDismiss: () {
                                Navigator.of(context).pop();
                              },
                              onSendMessage: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  CustomPageRoute(
                                    child: const ModernChatScreen(),
                                    settings: RouteSettings(arguments: matchedUser),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.favorite, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}