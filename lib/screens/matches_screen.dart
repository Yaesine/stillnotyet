// lib/screens/matches_screen.dart with enhanced dark mode support
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/user_provider.dart';
import '../providers/message_provider.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import '../widgets/components/letter_avatar.dart';
import '../widgets/components/loading_indicator.dart';
import '../animations/animations.dart';
import 'modern_chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Load matches when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadMatches();
    } catch (e) {
      print('Error loading matches data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load matches: $e')),
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme brightness
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    // Select colors based on theme
    final backgroundColor = isDarkMode ? AppColors.darkBackground : Colors.white;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isDarkMode ? AppColors.darkDivider : AppColors.divider;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.1);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar - Dark mode compatible
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      'Connections',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.search, color: AppColors.primary),
                      onPressed: () {
                        // Implement search functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Search coming soon'),
                            backgroundColor: isDarkMode ? AppColors.darkCard : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Tab Bar - Dark mode compatible
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkCard : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_tabController.index == 0
                              ? Icons.favorite
                              : Icons.favorite_border),
                          const SizedBox(width: 8),
                          const Text('Matches'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_tabController.index == 1
                              ? Icons.chat_bubble
                              : Icons.chat_bubble_outline),
                          const SizedBox(width: 8),
                          const Text('Messages'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: _isLoading
                    ? Center(
                  child: LoadingIndicator(
                    type: LoadingIndicatorType.pulse,
                    size: LoadingIndicatorSize.large,
                    color: AppColors.primary,
                    message: 'Loading your connections...',
                  ),
                )
                    : Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    if (userProvider.matchedUsers.isEmpty) {
                      return _buildEmptyState(isDarkMode);
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMatchesTab(userProvider, isDarkMode, cardColor, textColor, secondaryTextColor, shadowColor),
                        _buildMessagesTab(userProvider, isDarkMode, cardColor, textColor, secondaryTextColor, dividerColor),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final backgroundColor = isDarkMode ? AppColors.darkElevated.withOpacity(0.1) : AppColors.primary.withOpacity(0.1);
    final iconColor = isDarkMode ? AppColors.primary.withOpacity(0.3) : AppColors.primary.withOpacity(0.5);
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final descriptionColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final buttonColor = isDarkMode ? AppColors.darkSurface : Colors.white;

    return FadeInAnimation(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
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
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _tabController.index == 0 ? Icons.favorite_border : Icons.chat_bubble_outline,
                        size: 70,
                        color: iconColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                _tabController.index == 0 ? 'No matches yet' : 'No messages yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  _tabController.index == 0
                      ? 'Start swiping to find your perfect match!'
                      : 'Match with someone to start chatting',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: descriptionColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: isDarkMode ? 0 : 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.whatshot),
                    SizedBox(width: 8),
                    Text('Start Swiping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesTab(
      UserProvider userProvider,
      bool isDarkMode,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      Color shadowColor
      ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: userProvider.matchedUsers.length,
      itemBuilder: (context, index) {
        final user = userProvider.matchedUsers[index];
        // Find match data to show when it was matched
        final match = userProvider.matches.firstWhere(
              (match) => match.matchedUserId == user.id,
          orElse: () => userProvider.matches.first,
        );

        return FadeInAnimation(
          delay: Duration(milliseconds: 100 * index),
          child: _buildMatchCard(user, match.timestamp, isDarkMode, cardColor, textColor, secondaryTextColor, shadowColor),
        );
      },
    );
  }

  Widget _buildMatchCard(
      User user,
      DateTime matchTime,
      bool isDarkMode,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      Color shadowColor
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CustomPageRoute(
            child: const ModernChatScreen(),
            settings: RouteSettings(arguments: user),
          ),
        );
      },
      child: Stack(
        children: [
          // Card with image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile Image with letter avatar fallback
                  Hero(
                    tag: 'profile_${user.id}',
                    child: user.imageUrls.isNotEmpty
                        ? Image.network(
                      user.imageUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary,
                          child: Center(
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        : Container(
                      color: AppColors.primary,
                      child: Center(
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
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

                  // User info at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Matched ${timeago.format(matchTime, locale: 'en_short')}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Message button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ripple effect for tap
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  CustomPageRoute(
                    child: const ModernChatScreen(),
                    settings: RouteSettings(arguments: user),
                  ),
                );
              },
              highlightColor: Colors.transparent,
              splashColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab(
      UserProvider userProvider,
      bool isDarkMode,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      Color dividerColor
      ) {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: userProvider.matchedUsers.length,
      itemBuilder: (context, index) {
        final user = userProvider.matchedUsers[index];
        return FadeInAnimation(
          delay: Duration(milliseconds: 50 * index),
          child: _buildMessageListItem(
              user,
              messageProvider,
              isDarkMode,
              cardColor,
              textColor,
              secondaryTextColor,
              dividerColor
          ),
        );
      },
    );
  }

  Widget _buildMessageListItem(
      User user,
      MessageProvider messageProvider,
      bool isDarkMode,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      Color dividerColor
      ) {
    // Mock last message and time for UI purposes
    // In a real app, you'd fetch the last message from the message provider
    final mockLastMessageTime = DateTime.now().subtract(Duration(minutes: 30 * (user.id.hashCode % 10)));
    final isOnline = user.id.hashCode % 3 == 0; // Mock online status based on user id

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isDarkMode ? 0 : 2,
      color: cardColor,
      shadowColor: isDarkMode ? Colors.transparent : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDarkMode
            ? BorderSide(color: dividerColor)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            CustomPageRoute(
              child: const ModernChatScreen(),
              settings: RouteSettings(arguments: user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Profile avatar with online indicator
              Stack(
                children: [
                  LetterAvatar(
                    name: user.name,
                    size: 60,
                    imageUrls: user.imageUrls,
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDarkMode ? AppColors.darkCard : Colors.white,
                              width: 2
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Message preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(mockLastMessageTime, locale: 'en_short'),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.id.hashCode % 2 == 0
                                ? "Hey, how's it going? Would you like to meet up sometime?"
                                : "Start a conversation with ${user.name}",
                            style: TextStyle(
                              color: user.id.hashCode % 2 == 0
                                  ? textColor
                                  : secondaryTextColor,
                              fontSize: 14,
                              fontStyle: user.id.hashCode % 2 == 0
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user.id.hashCode % 4 == 0)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
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
    );
  }
}