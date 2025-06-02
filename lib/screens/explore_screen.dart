// lib/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../widgets/components/letter_avatar.dart';
import '../widgets/components/loading_indicator.dart';
import '../animations/animations.dart';
import 'category_users_screen.dart';
import 'event_detail_screen.dart';
import 'filters_screen.dart';
import '../widgets/user_profile_detail.dart';

// Models for Explore features
class ExploreCategory {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final List<String> relatedInterests;
  final int activeUsers;

  ExploreCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.relatedInterests,
    this.activeUsers = 0,
  });
}

class ExploreEvent {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String badge;
  final Color primaryColor;
  final Color secondaryColor;
  final int participants;
  final bool isPremium;
  final bool isSoldOut;

  ExploreEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.badge,
    required this.primaryColor,
    required this.secondaryColor,
    this.participants = 0,
    this.isPremium = false,
    this.isSoldOut = false,

  });

  bool get isActive => false;


  String get timeRemaining => 'Ended';

}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<User> _topPicks = [];
  List<User> _nearbyUsers = [];

  // Sample categories - in production, these would come from backend
  final List<ExploreCategory> _categories = [
    ExploreCategory(
      id: 'music_lovers',
      name: 'Music Lovers',
      emoji: '🎵',
      color: Colors.purple,
      relatedInterests: ['Music', 'Concerts', 'Festivals'],
      activeUsers: 1234,
    ),
    ExploreCategory(
      id: 'foodies',
      name: 'Foodies',
      emoji: '🍕',
      color: Colors.orange,
      relatedInterests: ['Food', 'Cooking', 'Restaurants'],
      activeUsers: 892,
    ),
    ExploreCategory(
      id: 'pet_parents',
      name: 'Pet Parents',
      emoji: '🐾',
      color: Colors.brown,
      relatedInterests: ['Dogs', 'Cats', 'Pets'],
      activeUsers: 756,
    ),
    ExploreCategory(
      id: 'fitness',
      name: 'Fitness Enthusiasts',
      emoji: '💪',
      color: Colors.green,
      relatedInterests: ['Fitness', 'Gym', 'Yoga', 'Running'],
      activeUsers: 1567,
    ),
    ExploreCategory(
      id: 'travelers',
      name: 'World Travelers',
      emoji: '✈️',
      color: Colors.blue,
      relatedInterests: ['Travel', 'Adventure', 'Photography'],
      activeUsers: 2103,
    ),
    ExploreCategory(
      id: 'gamers',
      name: 'Gamers',
      emoji: '🎮',
      color: Colors.red,
      relatedInterests: ['Gaming', 'Esports', 'Technology'],
      activeUsers: 1789,
    ),
  ];

  // Sample events - in production, these would come from backend
  // Sample events - in production, these would come from backend
  final List<ExploreEvent> _events = [
    ExploreEvent(
      id: 'summer_vibes',
      title: 'Summer Vibes',
      description: 'Connect with beach lovers and summer enthusiasts',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      badge: '☀️',
      primaryColor: Colors.orange,
      secondaryColor: Colors.yellow,
      participants: 3421,
      isPremium: true,
    ),
    ExploreEvent(
      id: 'festival_mode',
      title: 'Festival Mode',
      description: 'Find your festival buddy for the upcoming season',
      imageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3',
      startDate: DateTime.now().subtract(const Duration(hours: 12)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      badge: '🎪',
      primaryColor: Colors.purple,
      secondaryColor: Colors.pink,
      participants: 1892,
      isPremium: true,
    ),
    ExploreEvent(
      id: 'coffee_culture',
      title: 'Coffee Culture',
      description: 'Meet fellow coffee enthusiasts and cafe hoppers',
      imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().subtract(const Duration(days: 1)),
      badge: '☕',
      primaryColor: Colors.brown,
      secondaryColor: Colors.amber,
      participants: 5234,
      isPremium: true,
      isSoldOut: true,
    ),
    ExploreEvent(
      id: 'fitness_freaks',
      title: 'Fitness Freaks',
      description: 'Connect with gym buddies and workout partners',
      imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438',
      startDate: DateTime.now().subtract(const Duration(days: 15)),
      endDate: DateTime.now().subtract(const Duration(days: 5)),
      badge: '💪',
      primaryColor: Colors.red,
      secondaryColor: Colors.orange,
      participants: 4892,
      isPremium: true,
      isSoldOut: true,
    ),
    ExploreEvent(
      id: 'foodie_fest',
      title: 'Foodie Fest',
      description: 'Discover culinary companions and restaurant explorers',
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1',
      startDate: DateTime.now().subtract(const Duration(days: 20)),
      endDate: DateTime.now().subtract(const Duration(days: 10)),
      badge: '🍔',
      primaryColor: Colors.green,
      secondaryColor: Colors.lime,
      participants: 6789,
      isPremium: true,
      isSoldOut: true,
    ),
    ExploreEvent(
      id: 'travel_tales',
      title: 'Travel Tales',
      description: 'Share adventures with fellow wanderlust souls',
      imageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828',
      startDate: DateTime.now().subtract(const Duration(days: 25)),
      endDate: DateTime.now().subtract(const Duration(days: 12)),
      badge: '✈️',
      primaryColor: Colors.blue,
      secondaryColor: Colors.cyan,
      participants: 7654,
      isPremium: true,
      isSoldOut: true,
    ),
    ExploreEvent(
      id: 'art_attack',
      title: 'Art Attack',
      description: 'Creative minds unite for artistic connections',
      imageUrl: 'https://images.unsplash.com/photo-1547891654-e66ed7ebb968',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().subtract(const Duration(days: 18)),
      badge: '🎨',
      primaryColor: Colors.pink,
      secondaryColor: Colors.purple,
      participants: 3456,
      isPremium: true,
      isSoldOut: true,
    ),
    ExploreEvent(
      id: 'book_club',
      title: 'Book Club',
      description: 'Literary lovers seeking reading companions',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      startDate: DateTime.now().subtract(const Duration(days: 35)),
      endDate: DateTime.now().subtract(const Duration(days: 22)),
      badge: '📚',
      primaryColor: Colors.indigo,
      secondaryColor: Colors.deepPurple,
      participants: 2890,
      isPremium: true,
      isSoldOut: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Add this listener to update UI when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadExploreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExploreData() async {
    setState(() => _isLoading = true);

    try {
      // Simulate loading data - in production, this would be API calls
      await Future.delayed(const Duration(seconds: 1));

      // Load top picks and nearby users from existing data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final allUsers = userProvider.potentialMatches;

      if (allUsers.isNotEmpty) {
        // Simulate top picks algorithm
        _topPicks = allUsers.take(6).toList();

        // Simulate nearby users
        _nearbyUsers = allUsers.skip(6).take(8).toList();
      }
    } catch (e) {
      print('Error loading explore data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDarkMode),

            // Tab Bar
            _buildTabBar(isDarkMode),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Discover Tab
                  _buildDiscoverTab(isDarkMode),

                  // Categories Tab
                  _buildCategoriesTab(isDarkMode),

                  // Events Tab
                  _buildEventsTab(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'Explore',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const Spacer(),
          // Removed the filter button
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    // Set colors based on the current theme
    final backgroundColor = isDarkMode ? AppColors.darkCard : Colors.grey.shade200;
    final selectedBgColor = isDarkMode ? AppColors.primary : AppColors.primary;
    final unselectedTextColor = isDarkMode ? AppColors.darkTextSecondary : Colors.grey;
    final selectedTextColor = Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      height: 56,
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          // Animated sliding indicator
          AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, child) {
              final double animationValue = _tabController.animation!.value;
              return Positioned(
                left: animationValue * (MediaQuery.of(context).size.width - 40) / 3,
                child: Container(
                  width: (MediaQuery.of(context).size.width - 40) / 3,
                  height: 56,
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedBgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              );
            },
          ),
          // Tab items
          Row(
            children: [
              // Discover Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(0);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _tabController.animation!,
                        builder: (context, child) {
                          final double animationValue = _tabController.animation!.value;
                          final bool isSelected = animationValue >= -0.5 && animationValue < 0.5;
                          return Text(
                            'Discover',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? selectedTextColor : unselectedTextColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Categories Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _tabController.animation!,
                        builder: (context, child) {
                          final double animationValue = _tabController.animation!.value;
                          final bool isSelected = animationValue >= 0.5 && animationValue < 1.5;
                          return Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? selectedTextColor : unselectedTextColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Events Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(2);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _tabController.animation!,
                        builder: (context, child) {
                          final double animationValue = _tabController.animation!.value;
                          final bool isSelected = animationValue >= 1.5;
                          return Text(
                            'Events',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? selectedTextColor : unselectedTextColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildDiscoverTab(bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(
          type: LoadingIndicatorType.pulse,
          size: LoadingIndicatorSize.large,
          color: AppColors.primary,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExploreData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Top Picks Section
          FadeInAnimation(
            delay: const Duration(milliseconds: 100),
            child: _buildTopPicksSection(isDarkMode),
          ),

          const SizedBox(height: 32),

          // Quick Categories
          FadeInAnimation(
            delay: const Duration(milliseconds: 200),
            child: _buildQuickCategories(isDarkMode),
          ),

          const SizedBox(height: 32),

          // Nearby Users
          FadeInAnimation(
            delay: const Duration(milliseconds: 300),
            child: _buildNearbySection(isDarkMode),
          ),

          const SizedBox(height: 32),

          // Featured Event
          if (_events.isNotEmpty)
            FadeInAnimation(
              delay: const Duration(milliseconds: 400),
              child: _buildFeaturedEvent(isDarkMode),
            ),
        ],
      ),
    );
  }

  Widget _buildTopPicksSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Top Picks for You',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _topPicks.length,
            itemBuilder: (context, index) {
              final user = _topPicks[index];
              return _buildTopPickCard(user, isDarkMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopPickCard(User user, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _openUserProfile(user),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // User image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: user.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: user.imageUrls.first,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              )
                  : Container(
                color: AppColors.primary,
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // User info
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name}, ${user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          user.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Premium badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCategories(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Explore',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4, // Show first 4 categories
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildQuickCategoryCard(category, isDarkMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCategoryCard(ExploreCategory category, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _openCategory(category),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: category.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.near_me,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Nearby People',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _nearbyUsers.length.clamp(0, 4),
          itemBuilder: (context, index) {
            final user = _nearbyUsers[index];
            return _buildNearbyUserCard(user, isDarkMode);
          },
        ),
        if (_nearbyUsers.length > 4) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/nearby');
              },
              child: const Text('See All Nearby'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNearbyUserCard(User user, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _openUserProfile(user),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: user.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: user.imageUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
                    : Container(
                  color: AppColors.primary.withOpacity(0.1),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // User info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.name}, ${user.age}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '2.5 km away',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Interests preview
                    if (user.interests.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: user.interests.take(2).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedEvent(bool isDarkMode) {
    final event = _events.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.celebration,
              color: Colors.purple,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Featured Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _openEvent(event),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(event.imageUrl),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: event.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),

                // Event info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.badge,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (event.isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.participants} joined',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.timer,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.timeRemaining,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(bool isDarkMode) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find people who share your interests',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Categories Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return FadeInAnimation(
              delay: Duration(milliseconds: index * 100),
              child: _buildCategoryCard(category, isDarkMode),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ExploreCategory category, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _openCategory(category),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.color.withOpacity(0.8),
              category.color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                _getCategoryIcon(category.id),
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji in a white circle
                  Container(
                    width: 45, // Reduced from 50
                    height: 45, // Reduced from 50
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 24), // Reduced from 28
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Category name
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Reduced from 18
                      fontWeight: FontWeight.bold,
                      height: 1.2, // Add line height
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Active users count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10), // Reduced from 12
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, // Reduced from 6
                          height: 5, // Reduced from 6
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${category.activeUsers} active',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11, // Reduced from 12
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ripple effect
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCategory(category),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
// Helper method to get icons for categories
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'music_lovers':
        return Icons.music_note;
      case 'foodies':
        return Icons.restaurant;
      case 'pet_parents':
        return Icons.pets;
      case 'fitness':
        return Icons.fitness_center;
      case 'travelers':
        return Icons.flight;
      case 'gamers':
        return Icons.sports_esports;
      default:
        return Icons.category;
    }
  }

  Widget _buildEventsTab(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return FadeInAnimation(
          delay: Duration(milliseconds: index * 100),
          child: _buildEventCard(event, isDarkMode),
        );
      },
    );
  }

  Widget _buildEventCard(ExploreEvent event, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _openEvent(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(event.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3), // Darken ended events
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3), // Grey shadow for ended events
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // Event status badge - Always show ENDED
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ENDED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Premium badge
            if (event.isPremium)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Event info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.badge,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [

                        const SizedBox(width: 24),
                        _buildEventStat(
                          Icons.event_busy,
                          'Event',
                          'Ended',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  // Navigation methods
  void _openUserProfile(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileDetail(user: user),
      ),
    );
  }

  void _openCategory(ExploreCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryUsersScreen(category: category),
      ),
    );
  }

  void _openEvent(ExploreEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }
}