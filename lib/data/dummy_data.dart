import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/match_model.dart';

class DummyData {
  // Remote data source URL
  static const String _remoteDataUrl = 'https://rankboostads.com/Marifecto.json';

  // Cache for the fetched data
  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetchTime;

  // Fetch data from remote source with caching
  static Future<Map<String, dynamic>> _fetchData({bool forceRefresh = false}) async {
    // Check if we have cached data that's less than 15 minutes old
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedData != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!).inMinutes < 15) {
      print('Using cached dummy data (age: ${now.difference(_lastFetchTime!).inMinutes} minutes)');
      return _cachedData!;
    }

    try {
      print('Fetching remote dummy data from $_remoteDataUrl');
      final response = await http.get(
        Uri.parse(_remoteDataUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          _cachedData = json.decode(response.body);
          _lastFetchTime = now;
          print('Successfully loaded remote dummy data');
          return _cachedData!;
        } catch (e) {
          print('Error parsing JSON data: $e');
          return _getFallbackData();
        }
      } else {
        print('Failed to load data: HTTP ${response.statusCode}');
        return _getFallbackData();
      }
    } catch (e) {
      print('Error fetching remote data: $e');
      return _getFallbackData();
    }
  }

  // Get fallback data structure if remote fetch fails
  static Map<String, dynamic> _getFallbackData() {
    print('Using fallback dummy data');
    if (_cachedData != null) {
      return _cachedData!; // Use previously cached data if available
    }

    // Return minimal fallback data structure
    return {
      'users': [
        {
          'id': 'fallback_user_1',
          'name': 'Sophia',
          'age': 28,
          'bio': 'Travel enthusiast and coffee addict.',
          'imageUrls': ['https://images.unsplash.com/photo-1484608856193-968d2be4080e'],
          'interests': ['Travel', 'Coffee'],
          'location': 'Abu Dhabi',
          'gender': 'Female',
          'lookingFor': 'Male',
          'distance': 15,
          'ageRangeStart': 26,
          'ageRangeEnd': 35
        }
      ],
      'currentUser': {
        'id': 'user_123',
        'name': 'Alex',
        'age': 29,
        'bio': 'Tech enthusiast and fitness lover.',
        'imageUrls': ['https://i.pravatar.cc/300?img=33'],
        'interests': ['Technology', 'Fitness'],
        'location': 'Abu Dhabi',
        'gender': 'Male',
        'lookingFor': 'Female',
        'distance': 50,
        'ageRangeStart': 24,
        'ageRangeEnd': 35
      },
      'matches': []
    };
  }

  // Asynchronously get dummy users
  static Future<List<User>> getDummyUsersAsync() async {
    final data = await _fetchData();

    List<User> users = [];
    if (data.containsKey('users') && data['users'] is List) {
      for (var userData in data['users']) {
        try {
          users.add(User.fromJson(userData));
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }
    }

    print('Loaded ${users.length} dummy users from remote data');
    return users;
  }

  // For backward compatibility - calls async method and waits for result
  static List<User> getDummyUsers() {
    print('Warning: Using synchronous getDummyUsers() - consider migrating to getDummyUsersAsync()');

    // Since we can't use await in a sync method, return an empty list
    // The app should be updated to use the async version
    return [];
  }

  // Get current user from remote data
  static Future<User?> getCurrentUserAsync() async {
    final data = await _fetchData();

    if (data.containsKey('currentUser') && data['currentUser'] != null) {
      try {
        return User.fromJson(data['currentUser']);
      } catch (e) {
        print('Error parsing current user data: $e');
      }
    }

    return null;
  }

  // For backward compatibility
  static User getCurrentUser() {
    print('Warning: Using synchronous getCurrentUser() - consider migrating to getCurrentUserAsync()');

    // Return a minimal user object
    return User(
      id: 'user_123',
      name: 'Alex',
      age: 29,
      bio: 'Tech enthusiast and fitness lover.',
      imageUrls: ['https://i.pravatar.cc/300?img=33'],
      interests: ['Technology'],
      location: 'Abu Dhabi',
    );
  }

  // Get dummy matches from remote data
  static Future<List<Match>> getDummyMatchesAsync() async {
    final data = await _fetchData();

    List<Match> matches = [];
    if (data.containsKey('matches') && data['matches'] is List) {
      for (var matchData in data['matches']) {
        try {
          matches.add(Match(
            id: matchData['id'],
            userId: matchData['userId'],
            matchedUserId: matchData['matchedUserId'],
            timestamp: matchData['timestamp'] is String
                ? DateTime.parse(matchData['timestamp'])
                : DateTime.now(),
            superLike: matchData['superLike'] ?? false,
          ));
        } catch (e) {
          print('Error parsing match data: $e');
        }
      }
    }

    print('Loaded ${matches.length} dummy matches from remote data');
    return matches;
  }

  // For backward compatibility
  static List<Match> getDummyMatches() {
    print('Warning: Using synchronous getDummyMatches() - consider migrating to getDummyMatchesAsync()');
    return [];
  }

  // Get user by ID - tries local users first, then searches remote data
  static Future<User?> getUserByIdAsync(String id) async {
    final data = await _fetchData();

    // Try to find in the dummy users list
    if (data.containsKey('users') && data['users'] is List) {
      for (var userData in data['users']) {
        if (userData['id'] == id) {
          try {
            return User.fromJson(userData);
          } catch (e) {
            print('Error parsing user data: $e');
          }
        }
      }
    }

    // Try current user
    if (data.containsKey('currentUser') &&
        data['currentUser'] != null &&
        data['currentUser']['id'] == id) {
      try {
        return User.fromJson(data['currentUser']);
      } catch (e) {
        print('Error parsing current user data: $e');
      }
    }

    return null;
  }

  // For backward compatibility
  static User? getUserById(String id) {
    print('Warning: Using synchronous getUserById() - consider migrating to getUserByIdAsync()');

    // Get the current user and check if it matches
    final currentUser = getCurrentUser();
    if (currentUser.id == id) {
      return currentUser;
    }

    return null;
  }

  // Force refresh of cached data
  static Future<void> refreshData() async {
    await _fetchData(forceRefresh: true);
  }
}