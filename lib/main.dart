// lib/main.dart - Updated with Explore tab
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_tinder_clone/providers/theme_provider.dart';
import 'package:new_tinder_clone/screens/StyleProfileScreen.dart';
import 'package:new_tinder_clone/screens/cookie_policy_screen.dart';
import 'package:new_tinder_clone/screens/help_support_screen.dart';
import 'package:new_tinder_clone/screens/likes_screen.dart';
import 'package:new_tinder_clone/screens/notifications_screen.dart';
import 'package:new_tinder_clone/screens/privacy_policy_screen.dart';
import 'package:new_tinder_clone/screens/privacy_safety_screen.dart';
import 'package:new_tinder_clone/screens/splash_screen.dart';
import 'package:new_tinder_clone/screens/terms_of_service_screen.dart';
import 'package:new_tinder_clone/screens/theme_settings_screen.dart';
import 'package:new_tinder_clone/screens/video_call_screen.dart';
import 'package:new_tinder_clone/services/purchase_service.dart';
import 'package:new_tinder_clone/widgets/FCMTokenFixer.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Providers
import 'firebase_options.dart';
import 'providers/message_provider.dart';
import 'providers/user_provider.dart';
import 'providers/app_auth_provider.dart';

// Services
import 'services/firestore_service.dart';
import 'services/location_service.dart';
import 'services/notification_manager.dart';
import 'services/notifications_service.dart';
import 'services/gold_plus_service.dart';

// Screens
import 'screens/enhanced_home_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/enhanced_profile_screen.dart';
import 'screens/enhanced_chat_screen.dart';
import 'screens/modern_login_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/photo_manager_screen.dart';
import 'screens/boost_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/nearby_users_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/profile_verification_screen.dart';
import 'screens/explore_screen.dart';
import 'dart:developer' as developer;

// Theme
import 'theme/app_theme.dart';

// Utils
import 'utils/navigation.dart';
import 'utils/theme_system_listener.dart';
import 'widgets/notification_handler.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    // Initialize notifications service early
    final notificationsService = NotificationsService();
    await notificationsService.initialize();

    // Initialize notification manager
    final notificationManager = NotificationManager();
    await notificationManager.initialize();

    final purchaseService = PurchaseService();
    await purchaseService.initialize();

  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(MyApp());
}



Future<void> _initializeAppInBackground() async {
  try {
    // Initialize Firebase after UI is shown
    await Firebase.initializeApp();
    print('Firebase initialized successfully in background');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}
Future<void> _completeInitialization() async {
  try {
    // Lower priority initialization that can happen after UI is shown
    final firestoreService = FirestoreService();
    await firestoreService.verifyFirestoreConnection();
    await ensureUserAuthenticated();

    // DO NOT initialize any location or geocoding services
  } catch (e) {
    print('Background initialization error: $e');
  }
}


// Add this function outside of your main() function
Future<void> ensureUserAuthenticated() async {
  try {
    final authProvider = FirebaseAuth.instance;
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      print('No authenticated user at startup');
      return;
    } else {
      print('Auth state changed: User authenticated');

      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        print('Creating new user profile in Firestore');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'id': currentUser.uid,
          'name': currentUser.displayName ?? 'New User',
          'email': currentUser.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        print('Found existing user profile');

        // Update last login timestamp
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
      }
    }
  } catch (e) {
    print('Error during authentication check: $e');
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, _) {
        // Always show splash screen first, then navigate based on auth state
        return const SplashScreen();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseService()),
        ChangeNotifierProvider(create: (_) => GoldPlusService()),
      ],
      child: ThemeSystemListener(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => NotificationHandler(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Marifecto - Dating App',
              // Update theme configuration with enhanced themes
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              debugShowCheckedModeBanner: false,
              home: const SplashScreen(),
              routes: {
                '/login': (context) => const ModernLoginScreen(),
                '/phone-login': (context) => const PhoneLoginScreen(),
                '/main': (context) => const MainScreen(),
                '/chat': (context) => const EnhancedChatScreen(),
                '/photoManager': (context) => const PhotoManagerScreen(),
                '/filters': (context) => const FiltersScreen(),
                '/boost': (context) => BoostScreen(),
                '/premium': (context) => PremiumScreen(),
                '/modernProfile': (context) => StyleProfileScreen(),
                '/achievements': (context) => AchievementsScreen(
                  unlockedBadges: [],
                  availableBadges: [],
                ),
                '/streak': (context) => const StreakScreen(),

                '/verification': (context) => ProfileVerificationScreen(),
                '/themeSettings': (context) => ThemeSettingsScreen(),
                '/privacy': (context) => const PrivacySafetyScreen(),
                '/help': (context) => const HelpSupportScreen(),
                '/notifications': (context) => const NotificationsScreen(),
                '/nearby': (context) => const NearbyUsersScreen(),
                // Add to routes in MaterialApp
                '/privacy_policy': (context) => const PrivacyPolicyScreen(),
                '/terms_of_service': (context) => const TermsOfServiceScreen(),
                '/cookie_policy': (context) => const CookiePolicyScreen(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

// Updated MainScreen class from lib/main.dart
class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const EnhancedHomeScreen(),
    const ExploreScreen(),
    const VideoCallScreen(),
    const LikesScreen(),
    const MatchesScreen(),
    const StyleProfileScreen(),
  ];

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // FIRST - Ensure FCM token exists for new users
      await FCMTokenFixer.ensureTokenOnStartup();

      // Force token refresh for new accounts
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      await authProvider.ensureFCMToken();

      // Then continue with other initialization
      _initializeNotificationHandler();

      // Load user data and ui components
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.forceSyncCurrentUser();
      await userProvider.loadCurrentUser();

      // Load matches and other data
      await userProvider.loadMatches();
      await userProvider.loadUsersWhoLikedMe();
      await userProvider.loadProfileVisitors();
      await userProvider.loadLikesHistory();
      await userProvider.loadVisitsHistory();

      // Start streams
      userProvider.startMatchesStream();
      userProvider.startVisitorsAndLikesStreams();

      // ONLY NOW load potential matches which might depend on location
      await userProvider.loadPotentialMatches();

      // Delay location services further
      await Future.delayed(const Duration(seconds: 2));

      // Only now update location if user is authenticated
      final userId = authProvider.currentUserId;
      if (userId.isNotEmpty) {
        try {
          final locationService = LocationService();
          await locationService.updateUserLocation(userId);
        } catch (e) {
          print('Error updating location: $e');
          // Don't let location errors affect app usage
        }
      }
    });

    // Also listen to app lifecycle to refresh token when app becomes active
    WidgetsBinding.instance.addObserver(_LifecycleObserver(
      onResume: () async {
        final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
        await authProvider.refreshFCMTokenIfNeeded();
      },
    ));
  }

  void _initializeNotificationHandler() {
    try {
      print('Initializing notification handler in MainScreen');

      // Get and save the current token
      _getAndSaveToken();

      // IMPORTANT: Clear any existing listeners first
      // This prevents duplicate listeners if the method is called multiple times

      // Listen for token refreshes - use a single listener
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        print('FCM Token refreshed: $token');
        _saveTokenToFirestore(token);
      }, cancelOnError: false);

      // Configure notification handlers - ensure single listeners
      // Use StreamSubscription to manage listeners properly
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground message:');
        print('  Title: ${message.notification?.title}');
        print('  Body: ${message.notification?.body}');
        print('  Data: ${message.data}');

        // Check if we've already shown this notification
        // You can use message.messageId to track shown notifications
        _showInAppNotification(message);
      }, cancelOnError: false);

      // Check for notification that opened the app - only once
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('App opened from terminated state with notification');
          _handleNotificationTap(message);
        }
      });

      // Single listener for app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from background with notification');
        _handleNotificationTap(message);
      }, cancelOnError: false);

      print('Notification handler initialized successfully');
    } catch (e) {
      print('Error initializing notification handler: $e');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      print('Getting FCM token...');
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveTokenToFirestore(token);
      } else {
        print('Failed to get FCM token');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    if (!mounted) return;

    // Use the appropriate theme colors based on current theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final actionColor = AppColors.primary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          message.notification?.title ?? 'Notification',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          message.notification?.body ?? '',
          style: TextStyle(color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: actionColor)),
          ),
          if (message.data['type'] != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleNotificationTap(message);
              },
              child: Text('View', style: TextStyle(color: actionColor, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

// Updated _handleNotificationTap method to account for the new tab indexes
  void _handleNotificationTap(RemoteMessage message) {
    try {
      print('Handling notification tap:');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
      print('  Data: ${message.data}');

      final type = message.data['type'];
      final senderId = message.data['senderId'];

      if (type == null) return;

      switch (type) {
        case 'match':
          setState(() {
            _currentIndex = 4; // Updated index for Matches tab
          });
          _pageController.animateToPage(
            4,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          break;

        case 'message':
          if (senderId != null) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);

            // Find the matched user by ID
            for (final user in userProvider.matchedUsers) {
              if (user.id == senderId) {
                Navigator.of(context).pushNamed('/chat', arguments: user);
                return;
              }
            }

            // If user not found in matches, just go to matches tab
            setState(() {
              _currentIndex = 4; // Updated index for Matches tab
            });
            _pageController.animateToPage(
              4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            setState(() {
              _currentIndex = 4; // Updated index for Matches tab
            });
            _pageController.animateToPage(
              4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          break;

        case 'like':        // NEW: Handle like notifications
        case 'super_like':
        case 'profile_view':
          setState(() {
            _currentIndex = 3; // Updated index for Likes tab
          });
          _pageController.animateToPage(
            3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          break;

        case 'video_call':  // NEW: Handle video call notifications
          setState(() {
            _currentIndex = 2; // Index for Video Call tab
          });
          _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          break;

        default:
        // Default to home
          setState(() {
            _currentIndex = 0;
          });
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        print('Saving FCM token to Firestore: $token');

        // First check if token is different from existing one
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final existingToken = userData?['fcmToken'];

          if (existingToken == token) {
            print('FCM token unchanged, skipping update');
            return;
          }
        }

        // Update token in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'tokenTimestamp': FieldValue.serverTimestamp(),
          'platform': 'ios',
          'appVersion': '1.0.0',
        });

        print('FCM token saved successfully to Firestore');
      } else {
        print('Cannot save FCM token: No user ID available');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void _handleNotificationAction(RemoteMessage message) {
    final type = message.data['type'];

    // Navigate based on notification type
    switch (type) {
      case 'match':
        setState(() {
          _currentIndex = 3; // Switch to Matches tab (index updated)
        });
        _pageController.animateToPage(
          3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case 'super_like':
      case 'profile_view':
        setState(() {
          _currentIndex = 2; // Switch to Likes tab (index updated)
        });
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case 'message':
      // Navigate to the chat screen if a specific user is referenced
        if (message.data['senderId'] != null) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);

          // Find the matched user by ID
          for (final user in userProvider.matchedUsers) {
            if (user.id == message.data['senderId']) {
              Navigator.of(context).pushNamed('/chat', arguments: user);
              return;
            }
          }
        } else {
          // Otherwise just go to matches tab
          setState(() {
            _currentIndex = 3; // Switch to Matches tab (index updated)
          });
          _pageController.animateToPage(
            3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        break;
      default:
      // Default to the home tab
        setState(() {
          _currentIndex = 0;
        });
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme brightness for styling
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isDarkMode ? 12 : 20,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDarkMode
              ? AppColors.darkTextSecondary.withOpacity(0.7)
              : Colors.grey.withOpacity(0.8),
          showSelectedLabels: false,  // Hide labels
          showUnselectedLabels: false, // Hide labels
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: isDarkMode
              ? AppColors.darkSurface
              : Colors.white,
          iconSize: 28, // Base icon size for all icons
          items: [
            // Discover tab with enhanced icon
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentIndex == 0
                      ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.secondary.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _currentIndex == 0 ? 1.2 : 1.0,
                  child: Icon(
                    Icons.whatshot_rounded,
                    size: 28,
                    color: _currentIndex == 0
                        ? AppColors.primary
                        : isDarkMode
                        ? AppColors.darkTextSecondary.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.8),
                  ),
                ),
              ),
              label: '',
            ),
            // Explore tab with enhanced icon
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentIndex == 1
                      ? LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.2),
                      Colors.deepPurple.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _currentIndex == 1 ? 1.2 : 1.0,
                  child: Icon(
                    Icons.explore_rounded,
                    size: 28,
                    color: _currentIndex == 1
                        ? Colors.purple
                        : isDarkMode
                        ? AppColors.darkTextSecondary.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.8),
                  ),
                ),
              ),
              label: '',
            ),
            // Video Call tab with enhanced icon
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentIndex == 2
                      ? LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.2),
                      Colors.teal.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _currentIndex == 2 ? 1.2 : 1.0,
                  child: Icon(
                    Icons.video_call_rounded,
                    size: 28,
                    color: _currentIndex == 2
                        ? Colors.green
                        : isDarkMode
                        ? AppColors.darkTextSecondary.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.8),
                  ),
                ),
              ),
              label: '',
            ),
            // Likes tab with enhanced icon
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentIndex == 3
                      ? LinearGradient(
                    colors: [
                      Colors.pink.withOpacity(0.2),
                      Colors.red.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                ),
                child: Stack(
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _currentIndex == 3 ? 1.2 : 1.0,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 28,
                        color: _currentIndex == 3
                            ? Colors.pink
                            : isDarkMode
                            ? AppColors.darkTextSecondary.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.8),
                      ),
                    ),
                    // Optional: Add a notification badge
                    if (false) // Replace with actual condition for new likes
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode ? AppColors.darkSurface : Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              label: '',
            ),
            // Matches/Chat tab with enhanced icon
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentIndex == 4
                      ? LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.2),
                      Colors.lightBlue.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                ),
                child: Stack(
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _currentIndex == 4 ? 1.2 : 1.0,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 28,
                        color: _currentIndex == 4
                            ? Colors.blue
                            : isDarkMode
                            ? AppColors.darkTextSecondary.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.8),
                      ),
                    ),
                    // Optional: Add a notification badge for unread messages
                    if (false) // Replace with actual condition for unread messages
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode ? AppColors.darkSurface : Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              label: '',
            ),
            // Profile tab with enhanced icon
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentIndex == 5
                      ? LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.2),
                      Colors.amber.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _currentIndex == 5 ? 1.2 : 1.0,
                  child: Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: _currentIndex == 5
                        ? Colors.orange
                        : isDarkMode
                        ? AppColors.darkTextSecondary.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.8),
                  ),
                ),
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }


}

// Add this helper class at the bottom of your main.dart file
class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback? onResume;

  _LifecycleObserver({this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && onResume != null) {
      onResume!();
    }
  }
}