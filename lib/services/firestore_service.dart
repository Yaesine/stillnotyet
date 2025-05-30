// lib/services/firestore_service.dart - Updated with history preservation
//update new features to be private
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import 'notification_manager.dart';
import 'package:rxdart/rxdart.dart' as Rx;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final NotificationManager _notificationManager = NotificationManager();

  // Collection references
  final CollectionReference _usersCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference _matchesCollection =
  FirebaseFirestore.instance.collection('matches');
  final CollectionReference _messagesCollection =
  FirebaseFirestore.instance.collection('messages');
  final CollectionReference _swipesCollection =
  FirebaseFirestore.instance.collection('swipes');
  final CollectionReference _profileViewsCollection =
  FirebaseFirestore.instance.collection('profile_views');

  // New collections for history preservation
  final CollectionReference _likesHistoryCollection =
  FirebaseFirestore.instance.collection('likes_history');
  final CollectionReference _visitsHistoryCollection =
  FirebaseFirestore.instance.collection('visits_history');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add this to FirestoreService class
  Future<void> verifyFirestoreConnection() async {
    try {
      print('Verifying Firestore connection...');
      final snapshot = await _firestore.collection('users').limit(5).get();

      print('Firestore connection successful');
      print('Number of users in database: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('WARNING: No users found in the database!');
      } else {
        print('Users found in database:');
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          print('- ${data['name'] ?? 'Unknown'} (ID: ${doc.id})');
        }
      }
    } catch (e) {
      print('ERROR connecting to Firestore: $e');
      throw e;
    }
  }

  // Add to FirestoreService class
  Future<void> createTestUsersIfNeeded() async {
    try {
      // Check if we have at least 3 users
      final snapshot = await _firestore.collection('users').limit(3).get();
      if (snapshot.docs.length < 3) {
        print('Creating test users for development...');

        // Create test users with different data
        List<Map<String, dynamic>> testUsers = [
          {
            'id': 'test_user_1',
            'name': 'Sophia',
            'age': 28,
            'bio': 'Travel enthusiast and coffee addict',
            'imageUrls': ['https://images.unsplash.com/photo-1484608856193-968d2be4080e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTUyfHxXT01BTnxlbnwwfHwwfHx8MA%3D%3D','https://images.unsplash.com/photo-1469460340997-2f854421e72f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDN8fHxlbnwwfHx8fHw%3D','https://images.unsplash.com/photo-1462804993656-fac4ff489837?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDJ8fHxlbnwwfHx8fHw%3D', 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTU0fHxXT01BTnxlbnwwfHwwfHx8MA%3D%3D'],
            'interests': ['Travel', 'Coffee', 'Photography'],
            'location': 'Abu dhabi',
            'gender': 'Female',
            'lookingFor': 'Male',
            'distance': 12,
            'ageRangeStart': 25,
            'ageRangeEnd': 35,
          },

        ];

        // Add test users to Firestore
        for (var userData in testUsers) {
          String id = userData['id'];
          await _firestore.collection('users').doc(id).set(userData);
        }

        print('Test users created successfully');
      }
    } catch (e) {
      print('ERROR creating test users: $e');
    }
  }


  // Add this method to your FirestoreService class for debugging

/* Future<void> debugMessageNotification(String receiverId, String messageText) async {
    try {
      print('\n🔍 DEBUG: Starting message notification process');
      print('📤 Sender ID: $currentUserId');
      print('📥 Receiver ID: $receiverId');
      print('💬 Message: $messageText');

      // Step 1: Check if receiver exists
      DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) {
        print('❌ ERROR: Receiver document does not exist!');
        return;
      }

      Map<String, dynamic>? receiverData = receiverDoc.data() as Map<String, dynamic>?;
      print('✅ Receiver found: ${receiverData?['name']}');

      // Step 2: Check FCM token
      String? fcmToken = receiverData?['fcmToken'];
      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ ERROR: Receiver has NO FCM token!');
        print('   Attempting to create notification without token...');
      } else {
        print('✅ FCM Token found: ${fcmToken.substring(0, 20)}...');
      }

      // Step 3: Get sender name
      DocumentSnapshot senderDoc = await _firestore.collection('users').doc(currentUserId).get();
      Map<String, dynamic>? senderData = senderDoc.data() as Map<String, dynamic>?;
      String senderName = senderData?['name'] ?? 'Someone';
      print('✅ Sender name: $senderName');

      // Step 4: Create notification document directly
      print('📝 Creating notification document...');

      DocumentReference notificationRef = await _firestore.collection('notifications').add({
        'type': 'message',
        'title': 'Marifactor',
        'body': '$senderName +sent you a new message',
        'recipientId': receiverId,
        'fcmToken': fcmToken,
        'data': {
          'type': 'message',
          'senderId': currentUserId,
          'messageText': messageText,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': fcmToken != null ? 'pending' : 'pending_token',
        'platform': 'ios',
        'priority': 'high',
      });

      print('✅ Notification document created with ID: ${notificationRef.id}');

      // Step 5: Check if the notification document was processed
      await Future.delayed(Duration(seconds: 2));

      DocumentSnapshot notificationDoc = await notificationRef.get();
      Map<String, dynamic>? notificationData = notificationDoc.data() as Map<String, dynamic>?;
      String? status = notificationData?['status'];

      print('📊 Notification status after 2 seconds: $status');

      if (status == 'error') {
        print('❌ Notification error: ${notificationData?['error']}');
        print('   Error code: ${notificationData?['errorCode']}');
      } else if (status == 'sent') {
        print('✅ Notification sent successfully!');
      } else {
        print('⏳ Notification still pending...');
      }

      print('🔍 DEBUG: Notification process complete\n');

    } catch (e) {
      print('❌ DEBUG ERROR: $e');
    }
  }*/


  // Create or update user profile
  Future<void> updateUserProfile(User user) async {
    try {
      print('Updating user profile for ${user.id}');
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Create new user after registration
// Create new user after registration
  Future<void> createNewUser(String userId, String name, String email) async {
    try {
      print('Creating user profile for $userId in Firestore');

      // Check if user already exists
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        print('User profile for $userId already exists');
        return;
      }

      // Create a default GeoPoint for Dubai area with slight randomization
      final random = Random();
      final lat = 25.2048 + (random.nextDouble() * 0.1 - 0.05); // Dubai latitude with variation
      final lng = 55.2708 + (random.nextDouble() * 0.1 - 0.05); // Dubai longitude with variation

      // Create basic user profile WITHOUT a default profile image
      Map<String, dynamic> userData = {
        'id': userId,
        'name': name,
        'email': email,
        'age': 25,
        'bio': '',
        'imageUrls': [], // Empty array - no default picture
        'interests': [],
        'location': 'Dubai, UAE',
        'geoPoint': GeoPoint(lat, lng), // Add GeoPoint on creation
        'gender': '',
        'lookingFor': '',
        'distance': 50,
        'ageRangeStart': 18,
        'ageRangeEnd': 50,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'profileComplete': false, // Add a flag to track profile completion
      };

      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        transaction.set(_usersCollection.doc(userId), userData);
      });

      print('User profile created successfully for $userId');
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }
  // Get user data
  Future<User?> getUserData(String userId) async {
    try {
      print('Fetching user data for $userId');
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      print('User $userId not found');
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Get current user data
  Future<User?> getCurrentUserData() async {
    if (currentUserId == null) {
      print('No current user ID available');
      return null;
    }
    print('Getting current user data for $currentUserId');
    return await getUserData(currentUserId!);
  }




  Future<List<User>> getPotentialMatches() async {
    try {
      if (currentUserId == null) {
        print('ERROR: No current user ID available');
        throw Exception('No current user ID available');
      }

      print('===== GETTING ALL POTENTIAL MATCHES WITHOUT GENDER FILTER =====');

      // Get current user data first
      DocumentSnapshot userDoc = await _usersCollection.doc(currentUserId).get();
      if (!userDoc.exists) {
        throw Exception('Current user document not found');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Extract filter preferences but DON'T apply gender filter yet
      String lookingFor = userData['lookingFor'] ?? '';
      int ageRangeStart = userData['ageRangeStart'] ?? 18;
      int ageRangeEnd = userData['ageRangeEnd'] ?? 50;
      int maxDistance = userData['distance'] ?? 50;
      bool showProfilesWithPhoto = userData['showProfilesWithPhoto'] ?? true;

      print('Filter preferences:');
      print('- Looking for: $lookingFor');
      print('- Age range: $ageRangeStart to $ageRangeEnd');
      print('- Max distance: $maxDistance km');

      // SIMPLER QUERY - just age filter
      QuerySnapshot usersSnapshot = await _usersCollection
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .where('age', isGreaterThanOrEqualTo: ageRangeStart)
          .where('age', isLessThanOrEqualTo: ageRangeEnd)
          .limit(100)  // Get more to filter in memory
          .get();

      print('Retrieved ${usersSnapshot.docs.length} users from Firestore before filtering');

      // FILTERING IN MEMORY - more flexible and robust
      List<User> filteredUsers = [];
      GeoPoint? currentUserLocation = userData['geoPoint'] as GeoPoint?;

      for (var doc in usersSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // 1. Check for photos if required
          if (showProfilesWithPhoto &&
              (data['imageUrls'] == null || (data['imageUrls'] as List).isEmpty)) {
            continue;
          }

          // 2. GENDER FILTER - very flexible matching
          if (lookingFor.isNotEmpty) {
            String userGender = data['gender'] ?? '';

            // Debug info
            print('User ${doc.id} gender: "$userGender", looking for: "$lookingFor"');

            bool genderMatches = false;

            // Check with flexible matching
            if (lookingFor == 'Men' || lookingFor == 'Male') {
              genderMatches = userGender.toLowerCase() == 'men' ||
                  userGender.toLowerCase() == 'male' ||
                  userGender.toLowerCase() == 'man';
            }
            else if (lookingFor == 'Women' || lookingFor == 'Female') {
              genderMatches = userGender.toLowerCase() == 'women' ||
                  userGender.toLowerCase() == 'female' ||
                  userGender.toLowerCase() == 'woman';
            }
            else {
              // Exact match for other genders
              genderMatches = userGender.toLowerCase() == lookingFor.toLowerCase();
            }

            if (!genderMatches) {
              print('Skipping user ${doc.id} because gender does not match');
              continue;
            }
          }

          // 3. DISTANCE FILTER - if locations available
          if (currentUserLocation != null && data['geoPoint'] != null) {
            GeoPoint userLocation = data['geoPoint'] as GeoPoint;
            double distance = calculateDistance(currentUserLocation, userLocation);

            if (distance > maxDistance) {
              continue;
            }
          }

          // Add user to filtered results
          User user = User.fromFirestore(doc);
          filteredUsers.add(user);
          print('Added user ${user.id} (${user.name}) to potential matches');

        } catch (e) {
          print('Error processing user ${doc.id}: $e');
        }
      }

      print('FILTERED RESULT: ${filteredUsers.length} potential matches after filtering');

      // Get users already swiped on
      QuerySnapshot swipesSnapshot = await _swipesCollection
          .where('swiperId', isEqualTo: currentUserId)
          .get();

      List<String> swipedUserIds = [];
      for (var doc in swipesSnapshot.docs) {
        String swipedId = (doc.data() as Map<String, dynamic>)['swipedId'] as String;
        swipedUserIds.add(swipedId);
      }

      // Filter out already swiped users
      filteredUsers = filteredUsers
          .where((user) => !swipedUserIds.contains(user.id))
          .toList();

      print('FINAL RESULT: ${filteredUsers.length} potential matches after removing swiped users');

      return filteredUsers;
    } catch (e) {
      print('Error getting potential matches: $e');
      return [];
    }
  }

  Future<int> getUserCount() async {
    try {
      QuerySnapshot snapshot = await _usersCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting user count: $e');
      return 0;
    }
  }

// Helper method to calculate distance between two GeoPoints
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
  // Get users who have liked the current user
  Future<List<User>> getUsersWhoLikedMe() async {
    try {
      if (currentUserId == null) {
        print('No current user ID available');
        return [];
      }

      // Find swipes where other users liked the current user
      QuerySnapshot swipesSnapshot = await _swipesCollection
          .where('swipedId', isEqualTo: currentUserId)
          .where('liked', isEqualTo: true)
          .orderBy('timestamp', descending: true) // Get most recent first
          .limit(50) // Limit to recent likes for performance
          .get();

      print('Found ${swipesSnapshot.docs.length} users who liked me');

      // Extract user IDs of users who liked the current user
      List<String> likedByUserIds = [];
      Map<String, bool> isSuperLike = {};
      Map<String, DateTime> likeTimestamps = {};

      for (var doc in swipesSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          String swiperId = data['swiperId'] as String;
          bool superLiked = data['superLiked'] ?? false;
          DateTime timestamp = (data['timestamp'] as Timestamp).toDate();

          // Include ALL users who liked me, even if matched
          likedByUserIds.add(swiperId);
          isSuperLike[swiperId] = superLiked;
          likeTimestamps[swiperId] = timestamp;
        } catch (e) {
          print('Error parsing swipe record: $e');
        }
      }

      // Get user details for each liker with additional metadata
      List<User> likedByUsers = [];
      for (String userId in likedByUserIds) {
        User? user = await getUserData(userId);
        if (user != null) {
          // Store the like metadata in a way we can access it
          // (in a real app, you'd extend the User model)
          likedByUsers.add(user);

          // Store in a separate collection for quick access
          await _firestore.collection('user_likes')
              .doc('${currentUserId}_$userId')
              .set({
            'likedUserId': currentUserId,
            'likedByUserId': userId,
            'timestamp': Timestamp.fromDate(likeTimestamps[userId]!),
            'isSuperLike': isSuperLike[userId] ?? false,
            'isViewed': false, // New - track if the user has viewed this like
          });
        }
      }

      return likedByUsers;
    } catch (e) {
      print('Error getting users who liked me: $e');
      return [];
    }
  }


  Future<void> markLikeAsViewed(String likedByUserId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('user_likes')
          .doc('${currentUserId}_$likedByUserId')
          .update({'isViewed': true});
    } catch (e) {
      print('Error marking like as viewed: $e');
    }
  }

  // Updated to preserve ALL profile views in history
// Update the trackProfileView method in lib/services/firestore_service.dart

  Future<void> trackProfileView(String viewedUserId) async {
    try {
      String? viewerId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (viewerId == null || viewerId == viewedUserId) return;

      // Get current timestamp
      final timestamp = FieldValue.serverTimestamp();
      final currentTime = Timestamp.now();

      // ALWAYS add to the history collection - this preserves ALL visits
      await _visitsHistoryCollection.add({
        'viewerId': viewerId,
        'viewedUserId': viewedUserId,
        'timestamp': timestamp,
        'viewCount': 1,
        'isRead': false, // Add isRead flag for consistency
      });
      print('Added profile view to history collection: $viewerId viewed $viewedUserId');

      // For recent views - we still use the existing system
      // Check if this user has viewed this profile recently (for UI purposes only)
      final last24Hours = DateTime.now().subtract(Duration(hours: 24));

      QuerySnapshot recentViews = await _firestore.collection('profile_views')
          .where('viewerId', isEqualTo: viewerId)
          .where('viewedUserId', isEqualTo: viewedUserId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last24Hours))
          .limit(1)
          .get();

      // If already viewed in the last 24 hours, just update timestamp
      if (recentViews.docs.isNotEmpty) {
        await recentViews.docs.first.reference.update({
          'timestamp': timestamp,
          'viewCount': FieldValue.increment(1),
        });
      } else {
        // New view
        await _firestore.collection('profile_views').add({
          'viewerId': viewerId,
          'viewedUserId': viewedUserId,
          'timestamp': timestamp,
          'viewCount': 1,
          'isRead': false,
        });
        print('Added profile view to recent collection: $viewerId viewed $viewedUserId');

        // Get viewer's name for notification
        DocumentSnapshot viewerDoc = await _firestore.collection('users').doc(viewerId).get();
        Map<String, dynamic>? viewerData = viewerDoc.data() as Map<String, dynamic>?;
        String viewerName = viewerData?['name'] ?? 'Someone';

        // Send notification
        await _notificationManager.sendProfileViewNotification(
            viewedUserId,
            viewerName
        );
      }
    } catch (e) {
      print('Error tracking profile view: $e');
    }
  }

  Future<void> markProfileViewsAsRead() async {
    if (currentUserId == null) return;

    try {
      // Find all unread views
      QuerySnapshot unreadViews = await _firestore.collection('profile_views')
          .where('viewedUserId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch update
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadViews.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking profile views as read: $e');
    }
  }

  // Check if a user is already matched with the current user
  Future<bool> isMatched(String otherUserId) async {
    if (currentUserId == null) return false;

    // Check if there's a match document where the users are matched
    QuerySnapshot matchSnapshot = await _matchesCollection
        .where('userId', isEqualTo: currentUserId)
        .where('matchedUserId', isEqualTo: otherUserId)
        .limit(1)
        .get();

    return matchSnapshot.docs.isNotEmpty;
  }

  // Get profile visitors - keep this for recent visitors
  Future<List<Map<String, dynamic>>> getProfileVisitors() async {
    try {
      if (currentUserId == null) {
        print('No current user ID available');
        return [];
      }

      // Get profile views where the current user's profile was viewed
      QuerySnapshot viewsSnapshot = await _profileViewsCollection
          .where('viewedUserId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(50)  // Limit to the most recent 50 visitors
          .get();

      // Create a list to store visitors with their metadata
      List<Map<String, dynamic>> visitors = [];

      // Process each profile view
      for (var doc in viewsSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String viewerId = data['viewerId'] as String;
          DateTime timestamp = (data['timestamp'] as Timestamp).toDate();

          // Get the visitor's user data
          User? user = await getUserData(viewerId);
          if (user != null) {
            visitors.add({
              'user': user,
              'timestamp': timestamp,
            });
          }
        } catch (e) {
          print('Error processing profile view: $e');
        }
      }

      return visitors;
    } catch (e) {
      print('Error getting profile visitors: $e');
      return [];
    }
  }

  // New method - Get ALL historical profile visitors
  Future<List<Map<String, dynamic>>> getVisitsHistory() async {
    try {
      if (currentUserId == null) {
        print('No current user ID available');
        return [];
      }

      // Get ALL historical profile views from the history collection
      QuerySnapshot viewsSnapshot = await _visitsHistoryCollection
          .where('viewedUserId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .get();  // No limit - we want ALL history

      print('Found ${viewsSnapshot.docs.length} historical profile visitors');

      // Create a list to store visitors with their metadata
      List<Map<String, dynamic>> visitors = [];

      // Process each historical profile view
      for (var doc in viewsSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String viewerId = data['viewerId'] as String;
          DateTime timestamp = (data['timestamp'] as Timestamp).toDate();

          // Get the visitor's user data
          User? user = await getUserData(viewerId);
          if (user != null) {
            visitors.add({
              'user': user,
              'timestamp': timestamp,
            });
          }
        } catch (e) {
          print('Error processing visit history: $e');
        }
      }

      return visitors;
    } catch (e) {
      print('Error getting visits history: $e');
      return [];
    }
  }

  // Updated to preserve like history
  Future<bool> recordSwipe(String swipedUserId, bool isLike, {bool isSuperLike = false}) async {
    try {
      if (currentUserId == null) return false;

      // Current timestamp
      final timestamp = Timestamp.now();

      // Record the swipe decision
      await _swipesCollection.add({
        'swiperId': currentUserId,
        'swipedId': swipedUserId,
        'liked': isLike,
        'superLiked': isSuperLike,
        'timestamp': timestamp,
      });

      print('${isLike ? (isSuperLike ? "SuperLike" : "Like") : "Dislike"} recorded from $currentUserId to $swipedUserId');

      // If it was a dislike, we don't need to check for a match
      if (!isLike) return false;

      // Save to likes history if it's a like (even if it becomes a match later)
      String historyDocId = '${currentUserId}_${swipedUserId}_${DateTime.now().millisecondsSinceEpoch}';
      await _likesHistoryCollection.doc(historyDocId).set({
        'likerId': currentUserId,
        'likedUserId': swipedUserId,
        'isSuperLike': isSuperLike,
        'timestamp': timestamp,
        'becameMatch': false, // Will update this if it becomes a match
      });

      // Check if swiped user also liked current user or if this is a super like
      QuerySnapshot mutualLikeCheck = await _swipesCollection
          .where('swiperId', isEqualTo: swipedUserId)
          .where('swipedId', isEqualTo: currentUserId)
          .where('liked', isEqualTo: true)
          .get();

      // If mutual like or super like, create a match
      if (mutualLikeCheck.docs.isNotEmpty || isSuperLike) {
        String matchId = '$currentUserId-$swipedUserId';

        // Create match document with super like info
        await _matchesCollection.doc(matchId).set({
          'userId': currentUserId,
          'matchedUserId': swipedUserId,
          'timestamp': timestamp,
          'superLike': isSuperLike,
        });

        // Create reverse match for other user
        String reverseMatchId = '$swipedUserId-$currentUserId';
        await _matchesCollection.doc(reverseMatchId).set({
          'userId': swipedUserId,
          'matchedUserId': currentUserId,
          'timestamp': timestamp,
          'superLike': isSuperLike,
        });

        // Update the history record to indicate this became a match
        await _likesHistoryCollection.doc(historyDocId).update({
          'becameMatch': true
        });

        // If this is a mutual like, also update the other user's like history record
        QuerySnapshot otherUserLikeHistory = await _likesHistoryCollection
            .where('likerId', isEqualTo: swipedUserId)
            .where('likedUserId', isEqualTo: currentUserId)
            .limit(5) // Get the most recent ones
            .get();

        for (var doc in otherUserLikeHistory.docs) {
          await doc.reference.update({'becameMatch': true});
        }

        print('Match created between $currentUserId and $swipedUserId');
        return true; // Match created
      }

      print('No match yet between $currentUserId and $swipedUserId');
      return false; // No match yet
    } catch (e) {
      print('Error recording swipe: $e');
      return false;
    }
  }

  // New method - Get all historical likes
  Future<List<Map<String, dynamic>>> getLikesHistory() async {
    try {
      if (currentUserId == null) {
        print('No current user ID available');
        return [];
      }

      // Get all likes where the current user was liked
      QuerySnapshot likesSnapshot = await _likesHistoryCollection
          .where('likedUserId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .get(); // No limit - we want ALL history

      print('Found ${likesSnapshot.docs.length} historical likes');

      // Create a list to store likes with metadata
      List<Map<String, dynamic>> likesHistory = [];

      // Process each historical like
      for (var doc in likesSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String likerId = data['likerId'] as String;
          DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
          bool isSuperLike = data['isSuperLike'] ?? false;
          bool becameMatch = data['becameMatch'] ?? false;

          // Get the liker's user data
          User? user = await getUserData(likerId);
          if (user != null) {
            likesHistory.add({
              'user': user,
              'timestamp': timestamp,
              'isSuperLike': isSuperLike,
              'becameMatch': becameMatch,
            });
          }
        } catch (e) {
          print('Error processing like history: $e');
        }
      }

      return likesHistory;
    } catch (e) {
      print('Error getting likes history: $e');
      return [];
    }
  }

  // Get user matches
  Future<List<Match>> getUserMatches() async {
    try {
      if (currentUserId == null) return [];

      print('Getting matches for user $currentUserId');
      QuerySnapshot matchesSnapshot = await _matchesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Match> matches = [];
      for (var doc in matchesSnapshot.docs) {
        matches.add(Match.fromFirestore(doc));
      }

      print('Found ${matches.length} matches');
      return matches;
    } catch (e) {
      print('Error getting matches: $e');
      return [];
    }
  }

  // Get matched users' profiles
  Future<List<User>> getMatchedUsers() async {
    try {
      List<Match> matches = await getUserMatches();
      List<User> matchedUsers = [];

      print('Loading profile details for ${matches.length} matches');
      for (var match in matches) {
        User? user = await getUserData(match.matchedUserId);
        if (user != null) {
          matchedUsers.add(user);
        }
      }

      print('Loaded ${matchedUsers.length} matched user profiles');
      return matchedUsers;
    } catch (e) {
      print('Error getting matched users: $e');
      return [];
    }
  }

  // Get messages for a specific match

// Replace the getMessages method in lib/services/firestore_service.dart with this improved version
  Future<List<Message>> getMessages(String matchedUserId) async {
    try {
      if (currentUserId == null) {
        print('Cannot get messages: No current user ID available');
        return [];
      }

      print('Getting messages between $currentUserId and $matchedUserId');

      // Use a more direct query approach instead of whereIn filters
      // First get messages where current user is sender and matched user is receiver
      QuerySnapshot sentMessagesSnapshot = await _messagesCollection
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: matchedUserId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      // Then get messages where current user is receiver and matched user is sender
      QuerySnapshot receivedMessagesSnapshot = await _messagesCollection
          .where('senderId', isEqualTo: matchedUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      // Combine both sets of messages
      List<Message> messages = [];

      // Add sent messages
      for (var doc in sentMessagesSnapshot.docs) {
        messages.add(Message.fromFirestore(doc));
      }

      // Add received messages
      for (var doc in receivedMessagesSnapshot.docs) {
        messages.add(Message.fromFirestore(doc));
      }

      // Sort by timestamp, newest first
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Take only the most recent 50 messages if there are more
      if (messages.length > 50) {
        messages = messages.sublist(0, 50);
      }

      print('Retrieved ${messages.length} messages between $currentUserId and $matchedUserId');
      return messages;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Replace your sendMessage method in FirestoreService with this version

  // In lib/services/firestore_service.dart
// Update the sendMessage method to NOT create notifications

  Future<bool> sendMessage(String receiverId, String text) async {
    try {
      if (currentUserId == null) return false;

      print('Sending message from $currentUserId to $receiverId: "$text"');

      // Create the conversation ID
      String conversationId = _getConversationId(currentUserId!, receiverId);

      // Create the message document
      DocumentReference messageRef = await _messagesCollection.add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'conversationId': conversationId,
        'text': text,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'isDelivered': true,
        'type': 'text',
      });

      print('Message sent with ID: ${messageRef.id}');

      try {
        // Get sender's name for the notification
        DocumentSnapshot senderDoc = await _usersCollection.doc(currentUserId).get();
        Map<String, dynamic>? senderData = senderDoc.data() as Map<String, dynamic>?;
        String senderName = senderData?['name'] ?? 'Someone';

        // Send message notification
        await _notificationManager.sendMessageNotification(
            receiverId,
            senderName,
            text
        );

        print('Message notification sent successfully');
      } catch (notificationError) {
        print('Error in notification process: $notificationError');
        // Don't fail the message send if notification fails
      }
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }


  // Mark messages as read
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      if (currentUserId == null) return;

      QuerySnapshot unreadMessages = await _messagesCollection
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('Marked ${unreadMessages.docs.length} messages as read');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Listen to new messages stream
// Also replace the messagesStream method with this improved version
// Updated messagesStream method with correct rxdart syntax
  Stream<List<Message>> messagesStream(String matchedUserId) {
    if (currentUserId == null) {
      print('Cannot start messages stream: No current user ID available');
      return Stream.value([]);
    }

    print('Setting up messages stream between $currentUserId and $matchedUserId');

    // Create two streams: one for sent messages, one for received
    Stream<QuerySnapshot> sentMessagesStream = _messagesCollection
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: matchedUserId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();

    Stream<QuerySnapshot> receivedMessagesStream = _messagesCollection
        .where('senderId', isEqualTo: matchedUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();

    // Use Rx.CombineLatestStream instead of combineLatest2
    return Rx.CombineLatestStream.combine2(
        sentMessagesStream,
        receivedMessagesStream,
            (QuerySnapshot sentSnapshot, QuerySnapshot receivedSnapshot) {
          List<Message> messages = [];

          // Add sent messages
          for (var doc in sentSnapshot.docs) {
            try {
              messages.add(Message.fromFirestore(doc));
            } catch (e) {
              print('Error parsing sent message: $e');
            }
          }

          // Add received messages
          for (var doc in receivedSnapshot.docs) {
            try {
              messages.add(Message.fromFirestore(doc));
            } catch (e) {
              print('Error parsing received message: $e');
            }
          }

          // Sort by timestamp, newest first
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Take only the most recent 50 messages if there are more
          if (messages.length > 50) {
            messages = messages.sublist(0, 50);
          }

          print('Got ${sentSnapshot.docs.length + receivedSnapshot.docs.length} total message documents');
          print('Processed ${messages.length} messages for chat UI');

          return messages;
        }
    ).handleError((error) {
      print('Error in messages stream: $error');
      return [];
    });
  }

// Alternative implementation without rxdart (if you prefer not to add the dependency)
  Stream<List<Message>> messagesStreamWithoutRxdart(String matchedUserId) {
    if (currentUserId == null) {
      print('Cannot start messages stream: No current user ID available');
      return Stream.value([]);
    }

    print('Setting up messages stream between $currentUserId and $matchedUserId');

    // Just use one broader query that will include all messages between the two users
    return _messagesCollection
        .orderBy('timestamp', descending: true)
        .limit(100)  // Get a larger number to filter
        .snapshots()
        .map((snapshot) {
      List<Message> messages = [];
      print('Got ${snapshot.docs.length} total message documents');

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String senderId = data['senderId'] ?? '';
          String receiverId = data['receiverId'] ?? '';

          // Only include messages between these two specific users
          if ((senderId == currentUserId && receiverId == matchedUserId) ||
              (senderId == matchedUserId && receiverId == currentUserId)) {
            messages.add(Message.fromFirestore(doc));
          }
        } catch (e) {
          print('Error parsing message: $e');
        }
      }

      print('Filtered to ${messages.length} relevant messages for chat UI');

      return messages;
    })
        .handleError((error) {
      print('Error in messages stream: $error');
      return <Message>[];
    });
  }

// Use this import at the top of the file


  // Add this helper method
  String _getConversationId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
  // Listen to matches stream
  Stream<List<Match>> matchesStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _matchesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromFirestore(doc))
          .toList();
    });
  }

  // Listen to profile visitors stream
  Stream<List<Map<String, dynamic>>> profileVisitorsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _profileViewsCollection
        .where('viewedUserId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> visitors = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String viewerId = data['viewerId'] as String;
          DateTime timestamp = (data['timestamp'] as Timestamp).toDate();

          // Get the visitor's user data
          User? user = await getUserData(viewerId);
          if (user != null) {
            visitors.add({
              'user': user,
              'timestamp': timestamp,
            });
          }
        } catch (e) {
          print('Error processing profile view in stream: $e');
        }
      }

      return visitors;
    });
  }

  // Listen to users who liked me stream - modified to include ALL likes
  Stream<List<User>> usersWhoLikedMeStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _swipesCollection
        .where('swipedId', isEqualTo: currentUserId)
        .where('liked', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      Set<String> likerIds = {};

      // Extract user IDs but DON'T filter out matched users
      for (var doc in snapshot.docs) {
        try {
          String swiperId = (doc.data() as Map<String, dynamic>)['swiperId'] as String;
          likerIds.add(swiperId);
        } catch (e) {
          print('Error in users who liked me stream: $e');
        }
      }

      // Get user details for each liker
      List<User> likers = [];
      for (String userId in likerIds) {
        User? user = await getUserData(userId);
        if (user != null) {
          likers.add(user);
        }
      }

      return likers;
    });
  }

  // Get all users (for debugging)
  Future<List<User>> getAllUsers() async {
    try {
      print('GETTING ALL USERS FOR DEBUGGING');

      List<User> allUsers = [];
      QuerySnapshot usersSnapshot = await _usersCollection.get();

      print('Total users in database: ${usersSnapshot.docs.length}');

      for (var doc in usersSnapshot.docs) {
        try {
          User user = User.fromFirestore(doc);
          allUsers.add(user);
          print('Found user: ${user.name} (ID: ${user.id})');
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }

      return allUsers;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Add this method to the FirestoreService class in lib/services/firestore_service.dart

// Stream for historical visits data
  Stream<List<Map<String, dynamic>>> visitsHistoryStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _visitsHistoryCollection
        .where('viewedUserId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> visitors = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String viewerId = data['viewerId'] as String;
          DateTime timestamp = (data['timestamp'] as Timestamp).toDate();

          // Get the visitor's user data
          User? user = await getUserData(viewerId);
          if (user != null) {
            visitors.add({
              'user': user,
              'timestamp': timestamp,
              'isHistorical': true, // Mark as coming from history collection
            });
          }
        } catch (e) {
          print('Error processing visit history in stream: $e');
        }
      }

      return visitors;
    });
  }


  // Send match notification
  Future<void> sendMatchNotification(String recipientId, String senderName) async {
    try {
      await _notificationManager.sendMatchNotification(recipientId, senderName);
    } catch (e) {
      print('Error sending match notification: $e');
    }
  }

  // Send SuperLike notification
  Future<void> sendSuperLikeNotification(String recipientId, String senderName) async {
    try {
      await _notificationManager.sendSuperLikeNotification(recipientId, senderName);
    } catch (e) {
      print('Error sending SuperLike notification: $e');
    }
  }

  // Send SuperLike match notification
  Future<void> sendSuperLikeMatchNotification(String recipientId, String senderName) async {
    try {
      await _notificationManager.sendSuperLikeMatchNotification(recipientId, senderName);
    } catch (e) {
      print('Error sending SuperLike match notification: $e');
    }
  }
}