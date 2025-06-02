// lib/screens/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/app_button.dart';
import '../animations/animations.dart';
import '../widgets/user_profile_detail.dart';
import 'explore_screen.dart';
import 'premium_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final ExploreEvent event;

  const EventDetailScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasJoined = false;
  List<User> _eventParticipants = [];
  List<String> _eventActivities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEventData();
    _generateEventActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventData() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final allUsers = userProvider.potentialMatches;

      // Simulate event participants
      _eventParticipants = allUsers.take(20).toList();

      // Check if user has joined (simulated)
      _hasJoined = false;
    } catch (e) {
      print('Error loading event data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generateEventActivities() {
    // Generate activities based on event type
    if (widget.event.id == 'summer_vibes') {
      _eventActivities = [
        '🏖️ Beach Hangouts',
        '🌅 Sunset Watching',
        '🏄 Water Sports',
        '🍹 Beach Parties',
        '📸 Photo Challenges',
      ];
    } else if (widget.event.id == 'festival_mode') {
      _eventActivities = [
        '🎵 Music Matching',
        '🎪 Festival Buddies',
        '⛺ Camping Groups',
        '🎤 Artist Discussions',
        '🎉 After Parties',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: _isLoading
          ? const Center(
        child: LoadingIndicator(
          type: LoadingIndicatorType.pulse,
          size: LoadingIndicatorSize.large,
          color: AppColors.primary,
        ),
      )
          : CustomScrollView(
        slivers: [
          // Custom App Bar with Hero Image
          _buildSliverAppBar(isDarkMode),

          // Event Info
          SliverToBoxAdapter(
            child: _buildEventInfo(isDarkMode),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: widget.event.primaryColor,
                labelColor: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                unselectedLabelColor: isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 14), // Reduced size
                        SizedBox(width: 2), // Reduced spacing
                        Flexible( // Wrap text in Flexible
                          child: Text(
                            'Participants',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(text: 'Activities'),
                ],
              ),
              isDarkMode: isDarkMode,
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isDarkMode),
                _buildParticipantsTab(isDarkMode),
                _buildActivitiesTab(isDarkMode),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDarkMode),
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: widget.event.primaryColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: widget.event.imageUrl,
              fit: BoxFit.cover,
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    widget.event.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // Event badge and title
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.event.badge,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.event.isActive
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.event.isActive
                                        ? Icons.circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.event.isActive
                                        ? 'LIVE NOW'
                                        : 'ENDED',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildEventInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Event stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.lock_outline,
                value: 'Private',
                label: 'Participants',
                color: Colors.grey,
              ),
              _buildStatItem(
                icon: Icons.event_busy,
                value: 'Ended',
                label: 'Status',
                color: Colors.red,
              ),
              _buildStatItem(
                icon: Icons.local_fire_department,
                value: 'N/A',
                label: 'Match Rate',
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Event description
          Text(
            widget.event.description,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.event.isPremium) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium Event',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'This was a premium exclusive event',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(bool isDarkMode) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Event rules/guidelines
        _buildSectionCard(
          title: 'Event Guidelines',
          icon: Icons.rule,
          isDarkMode: isDarkMode,
          child: Column(
            children: [
              _buildGuidelineItem(
                '• Be respectful and authentic in your interactions',
                Icons.favorite,
                Colors.red,
              ),
              const SizedBox(height: 8),
              _buildGuidelineItem(
                '• Complete event challenges to earn bonus visibility',
                Icons.star,
                Colors.amber,
              ),
              const SizedBox(height: 8),
              _buildGuidelineItem(
                '• Share your event experiences using #${widget.event.id}',
                Icons.tag,
                Colors.blue,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Special features
        _buildSectionCard(
          title: 'Special Features',
          icon: Icons.auto_awesome,
          isDarkMode: isDarkMode,
          child: Column(
            children: [
              _buildFeatureItem(
                title: 'Themed Icebreakers',
                description: 'Unique conversation starters based on ${widget.event.title}',
                icon: Icons.chat_bubble,
                color: widget.event.primaryColor,
              ),
              const Divider(height: 24),
              _buildFeatureItem(
                title: 'Event Badge',
                description: 'Earn an exclusive badge for your profile',
                icon: Icons.military_tech,
                color: Colors.purple,
              ),
              const Divider(height: 24),
              _buildFeatureItem(
                title: 'Priority Matching',
                description: 'Get matched with other event participants first',
                icon: Icons.rocket_launch,
                color: Colors.orange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Event timeline
        _buildSectionCard(
          title: 'Event Timeline',
          icon: Icons.schedule,
          isDarkMode: isDarkMode,
          child: Column(
            children: [
              _buildTimelineItem(
                time: 'Started',
                date: _formatDate(widget.event.startDate),
                isCompleted: true,
              ),
              _buildTimelineConnector(),
              _buildTimelineItem(
                time: 'Peak Hours',
                date: 'Daily 6PM - 10PM',
                isActive: true,
              ),
              _buildTimelineConnector(),
              _buildTimelineItem(
                time: 'Ends',
                date: _formatDate(widget.event.endDate),
                isCompleted: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40), // Add top padding

          // Lock icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkCard
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 40,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Participants List is Private',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'To protect user privacy, participant information is not available for ended events.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Privacy info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkElevated.withOpacity(0.5)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? AppColors.darkDivider
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDarkMode
                      ? Colors.blue.shade300
                      : Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This helps maintain privacy and security for all users',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.blue.shade300
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40), // Add bottom padding
        ],
      ),
    );
  }

  Widget _buildParticipantCard(User user, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _openUserProfile(user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.event.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // User image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: user.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: user.imageUrls.first,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              )
                  : Container(
                color: widget.event.primaryColor.withOpacity(0.1),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: TextStyle(
                      color: widget.event.primaryColor,
                      fontSize: 32,
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
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // User name
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Event badge indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.event.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.event.badge,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesTab(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _eventActivities.length,
      itemBuilder: (context, index) {
        return FadeInAnimation(
          delay: Duration(milliseconds: index * 100),
          child: _buildActivityCard(
            _eventActivities[index],
            index,
            isDarkMode,
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(String activity, int index, bool isDarkMode) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                activity.split(' ')[0],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.substring(activity.indexOf(' ') + 1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to explore this activity',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _hasJoined
          ? Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'You\'re In!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: widget.event.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                // Share event
              },
              icon: const Icon(
                Icons.share,
                color: Colors.white,
              ),
            ),
          ),
        ],
      )
          : widget.event.isPremium && !_isUserPremium()
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Premium members only',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            text: 'Upgrade to Premium',
            icon: Icons.workspace_premium,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PremiumScreen(),
                ),
              );
            },
            isFullWidth: true,
            gradientColors: [Colors.amber, Colors.orange],
          ),
        ],
      )
          : GradientButton(
        text: 'Join Event',
        icon: Icons.celebration,
        onPressed: _joinEvent,
        isFullWidth: true,
        gradientColors: [
          widget.event.primaryColor,
          widget.event.secondaryColor,
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.event.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: widget.event.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String date,
    bool isCompleted = false,
    bool isActive = false,
  }) {
    final color = isActive
        ? widget.event.primaryColor
        : isCompleted
        ? Colors.green
        : Colors.grey;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted
                ? Icons.check
                : isActive
                ? Icons.circle
                : Icons.schedule,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 19),
      height: 30,
      width: 2,
      color: Colors.grey[300],
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isUserPremium() {
    // Check if user has premium subscription
    // This would be fetched from user provider in production
    return false;
  }

  void _joinEvent() {
    setState(() {
      _hasJoined = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Text('Welcome to ${widget.event.title}!'),
          ],
        ),
        backgroundColor: widget.event.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _openUserProfile(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileDetail(user: user),
      ),
    );
  }
}

// Custom delegate for sticky tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDarkMode;

  _SliverTabBarDelegate(this.tabBar, {required this.isDarkMode});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: isDarkMode ? AppColors.darkBackground : AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}