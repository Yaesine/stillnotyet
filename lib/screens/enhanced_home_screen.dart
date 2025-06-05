// Modified version of lib/screens/enhanced_home_screen.dart with improved super like animation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../animations/modern_match_animation.dart';
import '../services/rewind_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';
import '../widgets/enhanced_swipe_card.dart';
import '../widgets/components/loading_indicator.dart';
import '../screens/modern_chat_screen.dart';
import '../widgets/optimized_swipe_card.dart';
import 'nearby_users_screen.dart';
import 'premium_screen.dart';
import 'boost_screen.dart';
import 'streak_screen.dart';
import '../utils/custom_page_route.dart';
import '../widgets/user_profile_detail.dart' as widget_profile;

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  _EnhancedHomeScreenState createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  bool _showFilters = false;

  // Added for enhanced UI/UX
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Load potential matches when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  // Modify the AppBar's filter button handler
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(60),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.whatshot,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Marifecto',
              style: TextStyle(
                color: _isLoading ? Colors.white : AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          // Premium button
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PremiumScreen()),
                );
              },
              tooltip: 'Premium',
            ),
          ),

          // Nearby users button
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.location_on,
                color: AppColors.primary,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NearbyUsersScreen(),
                  ),
                );
              },
              tooltip: 'Nearby',
            ),
          ),
        ],
        // Modify the filter button handler to reload matches after filter changes
        leading: Container(
          margin: EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: Colors.orange,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
              // Navigate to filters screen and reload matches when returning
              Navigator.of(context).pushNamed('/filters').then((_) {
                // Show loading indicator
                setState(() {
                  _isLoading = true;
                });
                // Reload matches with new filters
                _loadMatches();
              });
            },
            tooltip: 'Filters',
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading indicator for at least 800ms for better UX
      await Future.wait([
        Provider.of<UserProvider>(context, listen: false).loadPotentialMatches(),
        Future.delayed(const Duration(milliseconds: 800)), // Minimum loading time
      ]);
    } catch (e) {
      print('Error loading matches: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matches: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(bottom: 10, left: 10, right: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Show user profile detail - using the widget version
  void _showUserProfile(User user) {
    // Track profile view and navigate to detail screen
    Navigator.of(context).push(
      CustomPageRoute(
        child: widget_profile.UserProfileDetail(user: user),
        settings: RouteSettings(arguments: user),
      ),
    );
  }

  // Add this to your EnhancedHomeScreen class in lib/screens/enhanced_home_screen.dart

  void _handleRewind() async {
    if (_isActionInProgress) return;

    setState(() {
      _isActionInProgress = true;
    });

    try {
      // First check if user has premium with rewind feature or is admin
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hasRewindFeature = await userProvider.hasFeature('rewind');

      if (!hasRewindFeature) {
        // User doesn't have premium or admin - show premium screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rewind is a premium feature. Upgrade to use it!'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'PREMIUM',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PremiumScreen()),
                );
              },
            ),
          ),
        );
        setState(() {
          _isActionInProgress = false;
        });
        return;
      }

      // For premium/admin users, proceed with rewind operation
      final rewindService = RewindService();
      final result = await userProvider.rewindLastSwipe();

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Swipe rewound! You have another chance.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error handling rewind: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing rewind: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isActionInProgress = false;
      });
    }
  }
  void _handleSwipeLeft(String userId) {
    // Immediately update UI to show next profile
    Provider.of<UserProvider>(context, listen: false).removeProfileLocally(userId);

    // Process the swipe action in the background without waiting
    Provider.of<UserProvider>(context, listen: false).swipeLeft(userId).catchError((error) {
      // Only show critical errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  void _handleSuperLike(String userId) {
    // Immediately update UI to show next profile
    Provider.of<UserProvider>(context, listen: false).removeProfileLocally(userId);

    // Process the swipe action in the background without waiting
    Provider.of<UserProvider>(context, listen: false).superLike(userId).then((matchedUser) {
      // Only show UI for matches
      if (matchedUser != null && mounted) {
        final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (currentUser != null) {
          // Show match animation
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
    }).catchError((error) {
      // Only show critical errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  void _handleSwipeRight(String userId) {
    // Immediately update UI to show next profile
    Provider.of<UserProvider>(context, listen: false).removeProfileLocally(userId);

    // Process the swipe action in the background without waiting
    Provider.of<UserProvider>(context, listen: false).swipeRight(userId).then((matchedUser) {
      // Only show UI for matches
      if (matchedUser != null && mounted) {
        final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (currentUser != null) {
          // Show match animation
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
    }).catchError((error) {
      // Only show critical errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadMatches,
        color: AppColors.primary,
        child: _isLoading
            ? Center(
          child: LoadingIndicator(
            type: LoadingIndicatorType.pulse,
            size: LoadingIndicatorSize.large,
            color: AppColors.primary,
            message: 'Finding your matches...',
          ),
        )
            : Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            // Get profiles from provider
            List<User> profiles = userProvider.potentialMatches;

            // If no profiles are available, show empty state
            if (profiles.isEmpty) {
              return _buildEmptyState();
            }

            // Display swipe cards
            return _buildSwipeCardStack(profiles);
          },
        ),
      ),
    );
  }

  // NEW: Separate method for swipe controls
  Widget _buildSwipeControls(String userId) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 10,
          left: 24,
          right: 24
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind button (could be premium feature)
          SwipeActionButton(
            icon: Icons.replay,
            color: Colors.amber,
            onTap: _handleRewind,  // Updated to use our rewind handler
            size: 44,
          ),


          // Dislike button
          SwipeActionButton(
            icon: Icons.close,
            color: Colors.red,
            onTap: () => _handleSwipeLeft(userId),
            size: 64,
          ),

          // Super like button
          SwipeActionButton(
            icon: Icons.star,
            color: Colors.blue,
            onTap: () => _handleSuperLike(userId),
            isSuper: true,
            size: 54,
          ),

          // Like button
          SwipeActionButton(
            icon: Icons.favorite,
            color: AppColors.primary,
            onTap: () => _handleSwipeRight(userId),
            size: 64,
          ),

          // Boost button
          SwipeActionButton(
            icon: Icons.bolt,
            color: Colors.purple,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => BoostScreen()),
              );
            },
            size: 44,
          ),
        ],
      ),
    );
  }


  Widget _buildSwipeCardStack(List<User> profiles) {
    // Create visual depth with decorative containers that won't interfere with gestures
    List<Widget> stackChildren = [];

    // Background decoration circles
    stackChildren.add(
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    stackChildren.add(
      Positioned(
        bottom: -80,
        left: -80,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    // Add shadow cards for visual depth ONLY if there are multiple profiles
    // These are positioned BELOW the swipe area to avoid interference
    if (profiles.length > 2) {
      stackChildren.add(
        Positioned(
          left: 16,
          right: 16,
          top: 130, // Positioned lower to show only the top edge
          bottom: 48,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.grey.shade200,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (profiles.length > 1) {
      stackChildren.add(
        Positioned(
          left: 20,
          right: 20,
          top: 115, // Positioned to show slightly more
          bottom: 63,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.grey.shade300,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Add the actual swipe card last so it's on top
    if (profiles.isNotEmpty) {
      stackChildren.add(
        Positioned.fill(
          child: OptimizedSwipeCard(
            key: ValueKey(profiles.first.id),
            user: profiles.first,
            isTop: true,
            onSwipeLeft: () => _handleSwipeLeft(profiles.first.id),
            onSwipeRight: () => _handleSwipeRight(profiles.first.id),
            onSuperLike: () => _handleSuperLike(profiles.first.id),
            onViewProfile: () => _showUserProfile(profiles.first),
          ),
        ),
      );
    }

    // Control buttons at the bottom for the top card
    if (profiles.isNotEmpty) {
      stackChildren.add(
        Positioned(
          bottom: 10, //five button position height
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Rewind button (could be premium feature)
                // Rewind button (could be premium feature)
                // Rewind button
                SwipeActionButton( //hade
                  icon: Icons.replay,
                  color: Colors.amber,
                  onTap: _handleRewind,
                  size: 44,
                ),

                // Dislike button
                SwipeActionButton(
                  icon: Icons.close,
                  color: Colors.red,
                  onTap: () => _handleSwipeLeft(profiles.first.id),
                  size: 64,
                ),

                // Super like button
                SwipeActionButton(
                  icon: Icons.star,
                  color: Colors.blue,
                  onTap: () => _handleSuperLike(profiles.first.id),
                  isSuper: true,
                  size: 54,
                ),

                // Like button
                SwipeActionButton(
                  icon: Icons.favorite,
                  color: AppColors.primary,
                  onTap: () => _handleSwipeRight(profiles.first.id),
                  size: 64,
                ),

                // Boost button
                SwipeActionButton(
                  icon: Icons.bolt,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => BoostScreen()),
                    );
                  },
                  size: 44,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(children: stackChildren);
  }



  // NEW: Swipe instruction overlay
  Widget _buildSwipeInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          // Swipe Up instruction
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Super Like',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration with animation
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: Duration(seconds: 2),
            curve: Curves.elasticInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'No more profiles to show',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We\'re working on finding more matches for you. Check back later or adjust your preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                GradientButton(
                  text: 'Boost Your Profile',
                  icon: Icons.bolt,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => BoostScreen()),
                    );
                  },
                  isFullWidth: true,
                  gradientColors: [Colors.purple, Colors.deepPurple],
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Adjust Preferences',
                  icon: Icons.tune,
                  onPressed: () {
                    Navigator.of(context).pushNamed('/filters');
                  },
                  type: AppButtonType.outline,
                  isFullWidth: true,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: _loadMatches,
                  type: AppButtonType.text,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}