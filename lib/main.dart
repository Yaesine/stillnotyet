// lib/main.dart - Updated with Explore tab
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const EnhancedHomeScreen(),
    const ExploreScreen(),  // Add the new ExploreScreen here
    const LikesScreen(),
    const MatchesScreen(),
    const StyleProfileScreen(),
  ];

  final PageController _pageController = PageController();

  // In your MainScreen class
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FCMTokenFixer.ensureTokenOnStartup();

      _initializeNotificationHandler();

      // First load user data and ui components
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      await authProvider.ensureFCMToken(); // Add this line
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



// Replace the _initializeNotificationHandler method in your _MainScreenState class

  void _initializeNotificationHandler() {
    try {
      print('Initializing notification handler in MainScreen');

      // Get and save the current token
      _getAndSaveToken();

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        print('FCM Token refreshed: $token');
        _saveTokenToFirestore(token);
      });

      // Configure notification handlers
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground message:');
        print('  Title: ${message.notification?.title}');
        print('  Body: ${message.notification?.body}');
        print('  Data: ${message.data}');

        _showInAppNotification(message);
      });

      // Check for notification that opened the app
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('App opened from terminated state with notification');
          _handleNotificationTap(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from background with notification');
        _handleNotificationTap(message);
      });

      print('Notification handler initialized successfully');
    } catch (e) {
      print('Error initializing notification handler: $e');
    }
  }

// Add these new methods to your _MainScreenState class
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
            _currentIndex = 3; // Switch to Matches tab
          });
          _pageController.animateToPage(
            3,
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
              _currentIndex = 3; // Switch to Matches tab
            });
            _pageController.animateToPage(
              3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            setState(() {
              _currentIndex = 3; // Switch to Matches tab
            });
            _pageController.animateToPage(
              3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          break;

        case 'super_like':
        case 'profile_view':
          setState(() {
            _currentIndex = 2; // Switch to Likes tab
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
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isDarkMode ? 8 : 10,
              offset: const Offset(0, -2),
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
              ? AppColors.darkTextSecondary
              : Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          backgroundColor: isDarkMode
              ? AppColors.darkSurface
              : Colors.white,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Likes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
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