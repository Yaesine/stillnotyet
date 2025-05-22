// lib/services/firestore_service.dart - Updated with history preservation
//update new features to be private
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import 'notification_manager.dart';

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
  Future<void> createNewUser(String userId, String name, String email) async {
    try {
      print('Creating user profile for $userId in Firestore');

      // Check if user already exists
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        print('User profile for $userId already exists');
        return;
      }

      // Create basic user profile WITHOUT a default profile image
      Map<String, dynamic> userData = {
        'id': userId,
        'name': name,
        'email': email,
        'age': 25,
        'bio': '',
        'imageUrls': [], // Empty array - no default picture
        'interests': [],
        'location': 'Abu Dhabi',
        'gender': '',
        'lookingFor': '',
        'distance': 50,
        'ageRangeStart': 18,
        'ageRangeEnd': 50,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
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

  // Get potential matches (users that are not current user and not already matched or swiped)
  Future<List<User>> getPotentialMatches() async {
    try {
      if (currentUserId == null) {
        print('No current user ID available for potential matches');
        return [];
      }

      print('Fetching ALL users from Firestore to find potential matches');

      // Get ALL users except the current user
      List<User> allUsers = [];

      // Fetch all users from Firestore
      QuerySnapshot usersSnapshot = await _usersCollection.get();

      print('Found ${usersSnapshot.docs.length} total users in database');

      // Filter out the current user
      for (var doc in usersSnapshot.docs) {
        String userId = doc.id;
        if (userId != currentUserId) {
          try {
            User user = User.fromFirestore(doc);
            allUsers.add(user);
            print('Added user ${user.name} (ID: ${user.id}) to potential matches list');
          } catch (e) {
            print('Error parsing user data for $userId: $e');
          }
        }
      }

      // Get all swipes by current user
      QuerySnapshot swipesSnapshot = await _swipesCollection
          .where('swiperId', isEqualTo: currentUserId)
          .get();

      print('User has ${swipesSnapshot.docs.length} swipe records');

      // Extract swiped user IDs
      List<String> swipedUserIds = [];
      for (var doc in swipesSnapshot.docs) {
        try {
          String swipedId = (doc.data() as Map<String, dynamic>)['swipedId'] as String;
          swipedUserIds.add(swipedId);
        } catch (e) {
          print('Error parsing swipe record: $e');
        }
      }

      // Filter out users that have already been swiped
      List<User> potentialMatches = allUsers.where((user) =>
      !swipedUserIds.contains(user.id)).toList();

      print('After filtering, found ${potentialMatches.length} potential matches');

      return potentialMatches;
    } catch (e) {
      print('Error getting potential matches from Firestore: $e');
      throw e;
    }
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
  Future<List<Message>> getMessages(String matchedUserId) async {
    try {
      if (currentUserId == null) return [];

      // Query messages where the conversation is between the current user and the matched user
      QuerySnapshot messagesSnapshot = await _messagesCollection
          .where('senderId', whereIn: [currentUserId, matchedUserId])
          .where('receiverId', whereIn: [currentUserId, matchedUserId])
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      List<Message> messages = [];
      for (var doc in messagesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Only include messages between these two specific users
        if ((data['senderId'] == currentUserId && data['receiverId'] == matchedUserId) ||
            (data['senderId'] == matchedUserId && data['receiverId'] == currentUserId)) {
          messages.add(Message.fromFirestore(doc));
        }
      }

      return messages;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Send a message - improved implementation
  Future<bool> sendMessage(String receiverId, String text) async {
    try {
      if (currentUserId == null) return false;

      print('Sending message from $currentUserId to $receiverId: "$text"');

      // Create the message document
      DocumentReference messageRef = await _messagesCollection.add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'isDelivered': true, // Mark as delivered when sent
        'type': 'text', // Default to text message
      });

      print('Message sent with ID: ${messageRef.id}');

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
  Stream<List<Message>> messagesStream(String matchedUserId) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    print('Setting up messages stream between $currentUserId and $matchedUserId');

    // Create a broader query and then filter in memory
    return _messagesCollection
        .orderBy('timestamp', descending: true)
        .limit(100) // Add a reasonable limit
        .snapshots()
        .map((snapshot) {
      List<Message> messages = [];

      print('Got ${snapshot.docs.length} total message documents');

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String senderId = data['senderId'] ?? '';
          String receiverId = data['receiverId'] ?? '';

          // Only include messages that are between these two users
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
    });
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