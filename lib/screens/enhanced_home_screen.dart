// fixed version of lib/screens/enhanced_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../animations/modern_match_animation.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';
import '../widgets/enhanced_swipe_card.dart';
import '../widgets/components/loading_indicator.dart';
import '../screens/modern_chat_screen.dart';
import 'nearby_users_screen.dart'; // Importing the whole screen
import 'premium_screen.dart';
import 'boost_screen.dart';
import 'streak_screen.dart';
import '../utils/custom_page_route.dart';
// Using alias to avoid the conflict
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

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<UserProvider>(context, listen: false).loadPotentialMatches();
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

  void _handleSwipeLeft(String userId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      await Provider.of<UserProvider>(context, listen: false).swipeLeft(userId);

      // Show subtle feedback
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passed'),
            backgroundColor: Colors.grey[800],
            duration: Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(bottom: 80, left: 100, right: 100),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _handleSuperLike(String userId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? matchedUser = await userProvider.superLike(userId);

      // Show a star animation
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (ctx) => Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 2.0 * value,
                child: Opacity(
                  opacity: value > 0.8 ? 2.0 - value * 2 : value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              Navigator.of(ctx).pop();

              // If it's a match, show match animation
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
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _handleSwipeRight(String userId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? matchedUser = await userProvider.swipeRight(userId);

      // Show match animation if there's a match
      if (matchedUser != null && mounted) {
        // Get current user
        final currentUser = userProvider.currentUser;

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
      } else {
        // Show subtle like feedback
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Liked!'),
              backgroundColor: AppColors.primary,
              duration: Duration(milliseconds: 500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.only(bottom: 80, left: 100, right: 100),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
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
   //   floatingActionButton: _buildQuickActionFab(),
    );
  }

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
              'STILL',
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
              Navigator.of(context).pushNamed('/filters');
            },
            tooltip: 'Filters',
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildSwipeCardStack(List<User> profiles) {
    return Stack(
      children: [
        // Background decoration
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

        // Swipe cards stack
        ...profiles.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;

          return Positioned.fill(
            child: EnhancedSwipeCard(
              user: user,
              isTop: index == profiles.length - 1,
              onSwipeLeft: () => _handleSwipeLeft(user.id),
              onSwipeRight: () => _handleSwipeRight(user.id),
              onSuperLike: () => _handleSuperLike(user.id),
              // NEW: Add profile view callback
              onViewProfile: () => _showUserProfile(user),
            ),
          );
        }).toList(),



        // Control buttons at the bottom for the top card
        if (profiles.isNotEmpty)
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
                  SwipeActionButton(
                    icon: Icons.replay,
                    color: Colors.amber,
                    onTap: () {
                      // Implement rewind functionality (premium feature)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Upgrade to premium to unlock this feature'),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'UPGRADE',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => PremiumScreen()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    size: 44,
                  ),

                  // Dislike button
                  SwipeActionButton(
                    icon: Icons.close,
                    color: AppColors.error,
                    onTap: () => _handleSwipeLeft(profiles.last.id),
                    size: 64,
                  ),

                  // Super like button
                  SwipeActionButton(
                    icon: Icons.star,
                    color: Colors.blue,
                    onTap: () => _handleSuperLike(profiles.last.id),
                    isSuper: true,
                    size: 54,
                  ),

                  // Like button
                  SwipeActionButton(
                    icon: Icons.favorite,
                    color: AppColors.primary,
                    onTap: () => _handleSwipeRight(profiles.last.id),
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
      ],
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

  Widget _buildQuickActionFab() {
    if (_isLoading) return SizedBox.shrink();

    return Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          bool hasActions = userProvider.potentialMatches.isNotEmpty;

          return hasActions
              ? FloatingActionButton(
            onPressed: _loadMatches,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 4,
            child: Icon(Icons.refresh),
            tooltip: 'Refresh matches',
          )
              : FloatingActionButton.extended(
            onPressed: _loadMatches,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: Icon(Icons.refresh),
            label: Text("Find New Matches"),
          );
        }
    );
  }
}