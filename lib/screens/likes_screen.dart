// lib/screens/likes_screen.dart - Updated with one-on-one call feature
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/letter_avatar.dart';
import '../utils/custom_page_route.dart';
import '../animations/modern_match_animation.dart';
import '../animations/animations.dart';
import '../screens/modern_chat_screen.dart';
import '../screens/premium_screen.dart';
import 'agora_one_on_one_call_screen.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({Key? key}) : super(key: key);

  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  // Premium state - set to false by default to require upgrade
  bool _hasPremium = false;

  @override
  void initState() {
    super.initState();
    // Update tab controller to have 3 tabs instead of 2
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // This will force a rebuild when the tab changes
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;

    setState(() {
      _isLoading = !_isRefreshing;
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Load both current and historical data
      await userProvider.loadUsersWhoLikedMe();
      await userProvider.loadProfileVisitors();
      await userProvider.loadLikesHistory();
      await userProvider.loadVisitsHistory();

      // Start streams for real-time updates
      userProvider.startVisitorsAndLikesStreams();

      // TODO: In a real app, check if user has premium subscription
      // setState(() {
      //   _hasPremium = true; // This would come from your subscription service
      // });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
      });
      print('Error loading likes data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadData,
        color: AppColors.primary,
        child: Column(
          children: [
            // Tab bar
            _buildTabBar(),

            // Tab content
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _errorMessage != null
                  ? _buildErrorView()
                  : Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  // Merge current and historical data
                  List<Map<String, dynamic>> allLikes = _combineCurrentAndHistoricalLikes(
                      userProvider.usersWhoLikedMe,
                      userProvider.likesHistory
                  );

                  List<Map<String, dynamic>> allVisitors = _combineCurrentAndHistoricalVisits(
                      userProvider.profileVisitors,
                      userProvider.visitsHistory
                  );

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Combined Likes Tab (current + history)
                      _buildLikesTab(allLikes),

                      // Combined Visitors Tab (current + history)
                      _buildVisitorsTab(allVisitors),

                      // New One-on-One Call Tab
                      //const AgoraOneOnOneCallScreen(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to combine current likes and likes history
  List<Map<String, dynamic>> _combineCurrentAndHistoricalLikes(
      List<User> currentLikes,
      List<Map<String, dynamic>> likesHistory
      ) {
    // Map to store unique entries by user ID, with most recent timestamp
    Map<String, Map<String, dynamic>> combinedMap = {};

    // Add current likes
    for (var user in currentLikes) {
      combinedMap[user.id] = {
        'user': user,
        'timestamp': DateTime.now(), // Assume current for active likes
        'isSuperLike': false, // We don't know from the current likes list
        'becameMatch': false, // Default
        'isActive': true, // This is a current like
      };
    }

    // Add historical likes, only if not already added from current likes
    for (var like in likesHistory) {
      String userId = (like['user'] as User).id;

      // If this user is not in the map OR the historical entry is more recent
      if (!combinedMap.containsKey(userId) ||
          (like['timestamp'] as DateTime).isAfter(combinedMap[userId]!['timestamp'] as DateTime)) {

        // Add with historical data
        combinedMap[userId] = {
          'user': like['user'],
          'timestamp': like['timestamp'],
          'isSuperLike': like['isSuperLike'] ?? false,
          'becameMatch': like['becameMatch'] ?? false,
          'isActive': false, // This is a historical like
        };
      }
    }

    // Convert map to list and sort by timestamp (most recent first)
    List<Map<String, dynamic>> combined = combinedMap.values.toList();
    combined.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return combined;
  }

  // Helper method to combine current visitors and visits history
  List<Map<String, dynamic>> _combineCurrentAndHistoricalVisits(
      List<Map<String, dynamic>> currentVisitors,
      List<Map<String, dynamic>> visitsHistory
      ) {
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

    // Add historical visits, only if not already added from current visitors
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

  PreferredSizeWidget _buildAppBar() {
    // Get current theme brightness to determine if we're in dark mode
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return AppBar(
      title: const Text(
        'Activity',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      // Use theme-appropriate colors instead of hardcoded colors
      backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
      foregroundColor: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
      elevation: 0,
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.filter_list),
            // Use theme-appropriate colors
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black87,
            onPressed: () {
              // Show filter options
              _showFilterOptions();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    // Get the current brightness to determine dark mode status
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    // Set colors based on the current theme
    final backgroundColor = isDarkMode ? AppColors.darkCard : Colors.grey.shade200;
    final selectedBgColor = isDarkMode ? AppColors.primary : AppColors.primary;
    final unselectedTextColor = isDarkMode ? AppColors.darkTextSecondary : Colors.grey;
    final selectedTextColor = Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 56, // Main tab bar height
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          // Likes Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(0);
              },
              child: Center(
                child: Container(
                  // Make colored indicator taller but not full height
                  height: 48, // Taller than text but not full container height
                  width: double.infinity, // Make it fill the width
                  decoration: BoxDecoration(
                    color: _tabController.index == 0 ? selectedBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabController.index == 0 ? Icons.favorite : Icons.favorite_border,
                        color: _tabController.index == 0 ? selectedTextColor : unselectedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Likes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _tabController.index == 0 ? selectedTextColor : unselectedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Visitors Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(1);
              },
              child: Center(
                child: Container(
                  // Make colored indicator taller but not full height
                  height: 48, // Taller than text but not full container height
                  width: double.infinity, // Make it fill the width
                  decoration: BoxDecoration(
                    color: _tabController.index == 1 ? selectedBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabController.index == 1 ? Icons.visibility : Icons.visibility_outlined,
                        color: _tabController.index == 1 ? selectedTextColor : unselectedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Visitors',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _tabController.index == 1 ? selectedTextColor : unselectedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Call Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(2);
              },
              child: Center(
                child: Container(
                  // Make colored indicator taller but not full height
                  height: 48, // Taller than text but not full container height
                  width: double.infinity, // Make it fill the width
                  decoration: BoxDecoration(
                    color: _tabController.index == 2 ? selectedBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabController.index == 2 ? Icons.video_call : Icons.video_call_outlined,
                        color: _tabController.index == 2 ? selectedTextColor : unselectedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Call',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _tabController.index == 2 ? selectedTextColor : unselectedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: LoadingIndicator(
        type: LoadingIndicatorType.pulse,
        size: LoadingIndicatorSize.large,
        message: 'Loading activity...',
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Failed to load data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesTab(List<Map<String, dynamic>> allLikes) {
    if (allLikes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'No likes yet',
        message: 'When someone likes you, they will appear here',
        iconColor: AppColors.primary,
        iconBackgroundColor: AppColors.primary.withOpacity(0.1),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium promo card (if not premium)
          if (!_hasPremium)
            _buildPremiumPromoCard(allLikes.length),

          const SizedBox(height: 16),

          // Section title
          Text(
            '${allLikes.length} people liked you',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Likes grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: allLikes.length,
              itemBuilder: (context, index) {
                var likeData = allLikes[index];
                User user = likeData['user'] as User;
                DateTime timestamp = likeData['timestamp'] as DateTime;
                bool isSuperLike = likeData['isSuperLike'] as bool;
                bool becameMatch = likeData['becameMatch'] as bool;

                return FadeInAnimation(
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildLikeCard(
                      user,
                      timestamp,
                      isSuperLike,
                      becameMatch
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorsTab(List<Map<String, dynamic>> allVisitors) {
    if (allVisitors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.visibility_off,
        title: 'No profile visitors yet',
        message: 'When someone views your profile, they will appear here',
        iconColor: Colors.blue,
        iconBackgroundColor: Colors.blue.withOpacity(0.1),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium promo card for visitors tab
        if (!_hasPremium)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildPremiumPromoCard(allVisitors.length, isVisitors: true),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${allVisitors.length} people visited your profile',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allVisitors.length,
            itemBuilder: (context, index) {
              var visitorData = allVisitors[index];
              User user = visitorData['user'] as User;
              DateTime timestamp = visitorData['timestamp'] as DateTime;
              bool isRecent = visitorData['isRecent'] ?? false;

              return FadeInAnimation(
                delay: Duration(milliseconds: 50 * index),
                child: _buildVisitorCard(
                    user,
                    timestamp,
                    isRecent
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color iconColor,
    required Color iconBackgroundColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to discover/swipe screen
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.whatshot),
            label: const Text('Go Find Matches'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPromoCard(int count, {bool isVisitors = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFB900),
              Color(0xFFFF8A00),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isVisitors
                            ? 'See who visited your profile & unlock all premium features'
                            : 'See who likes you & unlock all premium features',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => PremiumScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeCard(
      User user,
      DateTime timestamp,
      bool isSuperLike,
      bool becameMatch
      ) {
    // We blur the image for non-premium users
    final bool isBlurred = !_hasPremium;

    return GestureDetector(
      onTap: () => isBlurred ? _promptPremiumUpgrade() : _showUserProfile(user),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Profile Image with LetterAvatar as fallback
              Hero(
                tag: 'profile_${user.id}',
                child: user.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: user.imageUrls[0],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => LetterAvatar(
                    name: user.name,
                    size: double.infinity,
                    showBorder: false,
                  ),
                )
                    : LetterAvatar(
                  name: user.name,
                  size: double.infinity,
                  showBorder: false,
                ),
              ),

              // Blur overlay for non-premium users
              if (isBlurred)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                ),

              // Status badges (match, super like) - only for premium users
              if (!isBlurred && (becameMatch || isSuperLike))
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: becameMatch
                          ? Colors.red.withOpacity(0.8)
                          : Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          becameMatch ? Icons.favorite : Icons.star,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          becameMatch ? 'Match' : 'Super Like',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Gradient overlay for user info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.9],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBlurred ? 'Hidden' : '${user.name}, ${user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Show minimal info for non-premium users (just "liked X ago")
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.white70
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Liked you ${timeago.format(timestamp)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Only show additional details for premium users
                      if (!isBlurred) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.location,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Match button
              if (!isBlurred)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: becameMatch ? Colors.blue : AppColors.primary,
                    radius: 18,
                    child: IconButton(
                      icon: Icon(
                          becameMatch ? Icons.chat : Icons.favorite,
                          color: Colors.white,
                          size: 18
                      ),
                      onPressed: () => becameMatch
                          ? _openChat(user)
                          : _matchWithUser(user),
                      tooltip: becameMatch ? 'Open Chat' : 'Like Back',
                    ),
                  ),
                ),

              // Premium lock icon
              if (isBlurred)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        color: AppColors.darkMatchGradientStart,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upgrade to see\nwho likes you',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.darkMatchGradientStart,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(
      User user,
      DateTime timestamp,
      bool isRecent
      ) {
    // Blur for non-premium users
    final bool isBlurred = !_hasPremium;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => isBlurred ? _promptPremiumUpgrade() : _showUserProfile(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // User avatar with blur effect for non-premium
              Stack(
                children: [
                  // The avatar
                  Hero(
                    tag: 'visitor_${user.id}',
                    child: LetterAvatar(
                      name: user.name,
                      size: 60,
                      imageUrls: user.imageUrls,
                    ),
                  ),

                  // Blur overlay
                  if (isBlurred)
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Recent badge
                  if (!isBlurred && isRecent)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // For premium users - show name and age
                    // For non-premium - show "Hidden Profile"
                    Text(
                      isBlurred ? 'Hidden Profile' : '${user.name}, ${user.age}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location is hidden for non-premium
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isBlurred ? "Location hidden" : user.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Always show visit timestamp (but not other details for non-premium)
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Visited ${timeago.format(timestamp)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Add badge for recent visits - only for premium users
                    if (!isBlurred && isRecent)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Recent visitor',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Like button - only for premium users
              if (!isBlurred)
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, color: AppColors.primary, size: 20),
                    onPressed: () => _matchWithUser(user),
                    tooltip: 'Like Back',
                  ),
                )
              else
              // For non-premium, show lock icon
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 20,
                  child: Icon(
                    Icons.lock,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserProfile(User user) {
    // Track profile view when viewing profile
    Navigator.of(context).push(
      CustomPageRoute(
        child: UserProfileDetail(user: user),
        settings: RouteSettings(arguments: user),
      ),
    );
  }

  void _promptPremiumUpgrade() {
    // Show premium upgrade dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _tabController.index == 0
                      ? 'See who likes you and unlock all premium features!'
                      : _tabController.index == 1
                      ? 'See who visited your profile and unlock all premium features!'
                      : 'Join exclusive private calls and unlock all premium features!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PremiumScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'See Plans',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Use theme-appropriate colors for the bottom sheet
      backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Likes & Visitors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // Use theme-appropriate colors for text
                color: isDarkMode ? AppColors.darkTextPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            _buildFilterOption(
              'Most Recent',
              Icons.access_time,
              true,
            ),
            _buildFilterOption(
              'Nearby',
              Icons.location_on,
              false,
            ),
            _buildFilterOption(
              'Age Range',
              Icons.person,
              false,
            ),

            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon, bool isSelected) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        // Implement filter selection
      },
      // Use theme-appropriate splash effect
      splashColor: isDarkMode ? Colors.white12 : Colors.black12,
      highlightColor: isDarkMode ? Colors.white12 : Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              // Use theme-appropriate colors for icons
              color: isSelected
                  ? AppColors.primary
                  : isDarkMode
                  ? AppColors.darkTextSecondary
                  : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                // Use theme-appropriate colors for text
                color: isSelected
                    ? AppColors.primary
                    : isDarkMode
                    ? AppColors.darkTextPrimary
                    : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  // Method to handle chat navigation
  void _openChat(User user) {
    Navigator.of(context).push(
      CustomPageRoute(
        child: const ModernChatScreen(),
        settings: RouteSettings(arguments: user),
      ),
    );
  }

  Future<void> _matchWithUser(User user) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final matchedUser = await userProvider.swipeRight(user.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show match animation if there's a match
      if (matchedUser != null && mounted) {
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
      } else {
        // Show success toast if no match
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You liked ${user.name}! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 10, left: 10, right: 10),
          ),
        );
      }

      // Refresh data
      _loadData();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// User Profile Detail Screen - Keep this from the original file
class UserProfileDetail extends StatelessWidget {
  final User user;

  const UserProfileDetail({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: user.imageUrls.isNotEmpty ? user.imageUrls[0] : '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, error, stackTrace) => LetterAvatar(
                  name: user.name,
                  size: double.infinity,
                  showBorder: false,
                ),
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
                              child: CachedNetworkImage(
                                imageUrl: user.imageUrls[index + 1],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.error),
                                ),
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