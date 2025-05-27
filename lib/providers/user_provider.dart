// lib/providers/user_provider.dart - Updated with history functionality
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;  // Use alias for Firebase Auth
import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/user_model.dart';  // Only import once
import '../models/match_model.dart';
import '../services/firestore_service.dart';


class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<User> _potentialMatches = [];
  List<Match> _matches = [];
  List<User> _matchedUsers = [];
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Properties for likes tab
  List<User> _usersWhoLikedMe = [];
  List<Map<String, dynamic>> _profileVisitors = [];

  // New properties for history
  List<Map<String, dynamic>> _likesHistory = [];
  List<Map<String, dynamic>> _visitsHistory = [];

  // Getters
  List<User> get potentialMatches => _potentialMatches;
  List<Match> get matches => _matches;
  List<User> get matchedUsers => _matchedUsers;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters for likes tab
  List<User> get usersWhoLikedMe => _usersWhoLikedMe;
  List<Map<String, dynamic>> get profileVisitors => _profileVisitors;

  // New getters for history
  List<Map<String, dynamic>> get likesHistory => _likesHistory;
  List<Map<String, dynamic>> get visitsHistory => _visitsHistory;

  // Initialize and load current user data
  Future<void> initialize() async {
    await loadCurrentUser();
    await loadPotentialMatches();
    await loadMatches();
    await loadUsersWhoLikedMe();
    await loadProfileVisitors();
    await loadLikesHistory();
    await loadVisitsHistory();
  }

  // New methods to load history
  Future<void> loadLikesHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _likesHistory = await _firestoreService.getLikesHistory();
      print('Loaded ${_likesHistory.length} likes history entries');
    } catch (e) {
      print('Error loading likes history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVisitsHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _visitsHistory = await _firestoreService.getVisitsHistory();
      print('Loaded ${_visitsHistory.length} visits history entries');
    } catch (e) {
      print('Error loading visits history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Improved SuperLike function with visual feedback and special match handling
  Future<User?> superLike(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      bool isMatch = await _firestoreService.recordSwipe(userId, true, isSuperLike: true);
      User? matchedUser;

      if (isMatch) {
        // If it's a match, load the matched user
        matchedUser = await _firestoreService.getUserData(userId);
        if (matchedUser != null) {
          // Create match objects
          final newMatch = Match(
            id: '${_firestoreService.currentUserId}-$userId',
            userId: _firestoreService.currentUserId!,
            matchedUserId: userId,
            timestamp: DateTime.now(),
            // Add superLike flag to indicate this was a super like match
            superLike: true,
          );

          _matches.add(newMatch);
          _matchedUsers.add(matchedUser);

          // Send special notification for SuperLike matches
          await _firestoreService.sendSuperLikeMatchNotification(
              userId,
              _currentUser?.name ?? 'Someone'
          );
        }
      } else {
        // Even if not a match, notify the user about the SuperLike
        await _firestoreService.sendSuperLikeNotification(
            userId,
            _currentUser?.name ?? 'Someone'
        );
      }

      // Remove from potential matches list
      _potentialMatches.removeWhere((user) => user.id == userId);

      _isLoading = false;
      notifyListeners();

      // Return the matched user if there was a match
      return matchedUser;
    } catch (e) {
      print('Error super liking: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Load current user data
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getCurrentUserData();
      print('Current user loaded: ${_currentUser?.name}');
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
      print('Error loading current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load potential matches
// Update this method in lib/providers/user_provider.dart

  Future<void> loadPotentialMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('==== LOADING POTENTIAL MATCHES ====');
      print('Current user ID: ${_firestoreService.currentUserId}');

      if (_firestoreService.currentUserId == null) {
        print('ERROR: No current user ID available');
        throw Exception('No current user ID available');
      }

      print('Attempting to load potential matches from Firestore with filters applied...');
      _potentialMatches = await _firestoreService.getPotentialMatches();
      print('Loaded ${_potentialMatches.length} potential matches');

      // Print each potential match for debugging
      if (_potentialMatches.isNotEmpty) {
        print('Potential matches:');
        for (var match in _potentialMatches) {
          print('- User: ${match.name} (ID: ${match.id}, Age: ${match.age})');
        }
      }

      // Only use dummy data if Firebase returned no results and we're in development mode
      if (_potentialMatches.isEmpty && const bool.fromEnvironment('dart.vm.product') == false) {
        print('No potential matches found in Firestore, using dummy data');
        _potentialMatches = DummyData.getDummyUsers();

        // Apply basic filtering to dummy data as well
        if (_currentUser != null) {
          // Filter dummy data by age
          _potentialMatches = _potentialMatches.where((user) {
            return user.age >= _currentUser!.ageRangeStart &&
                user.age <= _currentUser!.ageRangeEnd;
          }).toList();

          // Filter by gender if looking for specific gender
          if (_currentUser!.lookingFor.isNotEmpty) {
            _potentialMatches = _potentialMatches.where((user) {
              return user.gender == _currentUser!.lookingFor;
            }).toList();
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load potential matches: $e';
      print('ERROR loading potential matches: $e');
      // Fall back to dummy data on error in development mode
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        print('Falling back to dummy data due to error');
        _potentialMatches = DummyData.getDummyUsers();

        // Apply basic filtering to dummy data
        if (_currentUser != null) {
          // Filter dummy data by age and gender (as above)
          _potentialMatches = _potentialMatches.where((user) {
            bool ageMatch = user.age >= _currentUser!.ageRangeStart &&
                user.age <= _currentUser!.ageRangeEnd;
            bool genderMatch = _currentUser!.lookingFor.isEmpty ||
                user.gender == _currentUser!.lookingFor;
            return ageMatch && genderMatch;
          }).toList();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      print('==== FINISHED LOADING POTENTIAL MATCHES ====');
    }
  }
  // Load users who have liked the current user
  Future<void> loadUsersWhoLikedMe() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_firestoreService.currentUserId == null) {
        throw Exception('No current user ID available');
      }

      _usersWhoLikedMe = await _firestoreService.getUsersWhoLikedMe();
      print('Loaded ${_usersWhoLikedMe.length} users who liked me');
    } catch (e) {
      print('Error loading users who liked me: $e');
      _usersWhoLikedMe = []; // Reset to empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load users who have visited current user's profile
  Future<void> loadProfileVisitors() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_firestoreService.currentUserId == null) {
        throw Exception('No current user ID available');
      }

      _profileVisitors = await _firestoreService.getProfileVisitors();
      print('Loaded ${_profileVisitors.length} profile visitors');
    } catch (e) {
      print('Error loading profile visitors: $e');
      _profileVisitors = []; // Reset to empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forceSyncCurrentUser() async {
    try {
      // Get the current Firebase Auth user
      final authInstance = auth.FirebaseAuth.instance;
      final userId = authInstance.currentUser?.uid;

      if (userId == null) {
        print('No authenticated user found');
        return;
      }

      // Check if user exists in Firestore
      User? existingUser = await _firestoreService.getUserData(userId);

      if (existingUser == null) {
        print('User document does not exist in Firestore. Creating it now...');

        // Get user's name from Firebase Auth
        final userName = authInstance.currentUser?.displayName ?? 'New User';

        // Create basic profile - without any default profile image
        User newUser = User(
          id: userId,
          name: userName,
          age: 25,
          bio: 'Tell others about yourself...',
          imageUrls: [], // Empty array - we won't add any default image
          interests: ['Travel', 'Music', 'Movies'],
          location: 'New York, NY',
          gender: '',
          lookingFor: '',
          distance: 50,
          ageRangeStart: 18,
          ageRangeEnd: 50,
        );

        // Use the update method from FirestoreService
        await _firestoreService.updateUserProfile(newUser);
        print('Created user document in Firestore');

        // Update current user
        _currentUser = newUser;
        notifyListeners();
      } else {
        print('User document exists in Firestore');
        _currentUser = existingUser;
        notifyListeners();
      }
    } catch (e) {
      print('Error in forceSyncCurrentUser: $e');
    }
  }

  // Load user matches
  Future<void> loadMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _matches = await _firestoreService.getUserMatches();
      _matchedUsers = await _firestoreService.getMatchedUsers();
      print('Loaded ${_matches.length} matches and ${_matchedUsers.length} matched users');
    } catch (e) {
      _errorMessage = 'Failed to load matches: $e';
      print('Error loading matches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Swipe left (dislike)
  Future<void> swipeLeft(String userId) async {
    try {
      await _firestoreService.recordSwipe(userId, false);
      _potentialMatches.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      print('Error swiping left: $e');
    }
  }

  // Swipe right (like)
  Future<User?> swipeRight(String userId) async {
    try {
      bool isMatch = await _firestoreService.recordSwipe(userId, true);
      User? matchedUser;

      if (isMatch) {
        // If it's a match, load the matched user
        matchedUser = await _firestoreService.getUserData(userId);
        if (matchedUser != null) {
          // Create match objects
          final newMatch = Match(
            id: '${_firestoreService.currentUserId}-$userId',
            userId: _firestoreService.currentUserId!,
            matchedUserId: userId,
            timestamp: DateTime.now(),
          );

          _matches.add(newMatch);
          _matchedUsers.add(matchedUser);

          // Send match notification
          await _firestoreService.sendMatchNotification(
              userId,
              _currentUser?.name ?? 'Someone'
          );
        }
      }

      // Remove from potential matches list
      _potentialMatches.removeWhere((user) => user.id == userId);
      notifyListeners();

      // Return the matched user if there was a match
      return matchedUser;
    } catch (e) {
      print('Error swiping right: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(User updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      print('User profile updated successfully: ${updatedUser.name}');
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      print('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Listen to matches stream
  void startMatchesStream() {
    _firestoreService.matchesStream().listen((matches) {
      _matches = matches;
      _loadMatchedUsers();
      notifyListeners();
    });
  }

  // Start visitors and likes streams
// Modify the startVisitorsAndLikesStreams method in lib/providers/user_provider.dart
  void removeProfileLocally(String userId) {
    // Remove the profile from the potential matches list
    _potentialMatches.removeWhere((user) => user.id == userId);

    // Notify listeners to update the UI immediately
    notifyListeners();
  }
// Update this method in UserProvider class
  void startVisitorsAndLikesStreams() {
    // Listen for profile visitors (recent)
    _firestoreService.profileVisitorsStream().listen((visitors) {
      // Update with recent visitors but preserve historical ones
      List<Map<String, dynamic>> newVisitors = [...visitors];

      // Keep any historical visitors that aren't in the recent list
      for (var historicalVisit in _visitsHistory) {
        String historicalUserId = (historicalVisit['user'] as User).id;
        // Check if this historical visitor is not in the recent visitors list
        bool existsInRecent = newVisitors.any((visit) =>
        (visit['user'] as User).id == historicalUserId);

        if (!existsInRecent) {
          newVisitors.add(historicalVisit);
        }
      }

      // Sort by timestamp (newest first)
      newVisitors.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      _profileVisitors = newVisitors;
      notifyListeners();
    });

    // Add a new listener for historical visits
    _firestoreService.visitsHistoryStream().listen((historyVisitors) {
      _visitsHistory = historyVisitors;

      // Update the combined visitors list
      List<Map<String, dynamic>> combinedVisitors =
      _combineCurrentAndHistoricalVisits(_profileVisitors, _visitsHistory);

      _profileVisitors = combinedVisitors;
      notifyListeners();
    });

    // Listen for users who liked me
    _firestoreService.usersWhoLikedMeStream().listen((users) {
      _usersWhoLikedMe = users;
      notifyListeners();
    });
  }

// Helper method to combine visitors lists
  List<Map<String, dynamic>> _combineCurrentAndHistoricalVisits(
      List<Map<String, dynamic>> currentVisitors,
      List<Map<String, dynamic>> visitsHistory) {
    // Map to store unique entries by user ID, with most recent timestamp
    Map<String, Map<String, dynamic>> combinedMap = {};

    // Add current visitors
    for (var visit in currentVisitors) {
      String userId = (visit['user'] as User).id;
      combinedMap[userId] = {
        'user': visit['user'],
        'timestamp': visit['timestamp'],
        'isRecent': true, // This is a recent visitor
      };
    }

    // Add historical visits, only if not already added from current visitors or if more recent
    for (var visit in visitsHistory) {
      String userId = (visit['user'] as User).id;

      // If this user is not in the map OR the historical entry is more recent
      if (!combinedMap.containsKey(userId) ||
          (visit['timestamp'] as DateTime).isAfter(combinedMap[userId]!['timestamp'] as DateTime)) {

        // Add with historical data
        combinedMap[userId] = {
          'user': visit['user'],
          'timestamp': visit['timestamp'],
          'isRecent': false, // This is a historical visit
        };
      }
    }

    // Convert map to list and sort by timestamp (most recent first)
    List<Map<String, dynamic>> combined = combinedMap.values.toList();
    combined.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return combined;
  }
  // Helper method to load matched users
  Future<void> _loadMatchedUsers() async {
    _matchedUsers = [];
    for (var match in _matches) {
      final user = await _firestoreService.getUserData(match.matchedUserId);
      if (user != null) {
        _matchedUsers.add(user);
      }
    }
    notifyListeners();
  }
}