// lib/widgets/user_profile_detail.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../animations/modern_match_animation.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/profile_view_tracker.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import '../screens/modern_chat_screen.dart';
import 'components/letter_avatar.dart';
import 'components/interest_chip.dart';

class UserProfileDetail extends StatefulWidget {
  final User user;

  const UserProfileDetail({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _UserProfileDetailState createState() => _UserProfileDetailState();
}

class _UserProfileDetailState extends State<UserProfileDetail> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isSwipingDown = false;
  double _startDragY = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _showFullBio = false;

  @override
  void initState() {
    super.initState();

    // Track profile view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tracker = ProfileViewTracker();
      tracker.trackProfileView(widget.user.id);
    });

    // Initialize page controller for image gallery
    _pageController = PageController(initialPage: 0);

    // Initialize animation controller for dismissible animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSwipeDown(DragEndDetails details) {
    if (_isSwipingDown && details.velocity.pixelsPerSecond.dy > 300) {
      _animationController.forward().then((_) {
        Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _isSwipingDown = false;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _startDragY = details.globalPosition.dy;
    setState(() {
      _isSwipingDown = false;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (details.globalPosition.dy - _startDragY > 50) {
      setState(() {
        _isSwipingDown = true;
      });
    }
  }

  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.user.imageUrls.length > 1;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleSwipeDown,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Flexible app bar with image gallery
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.55,
                pinned: true,
                backgroundColor: Colors.black,
                leading: _buildFloatingBackButton(),
                actions: [
                  _buildFloatingActionButton(
                    icon: Icons.report_outlined,
                    tooltip: 'Report',
                    onPressed: () => _showReportDialog(context),
                  ),
                ],
                flexibleSpace: Stack(
                  children: [
                    // Image gallery
                    Positioned.fill(
                      child: _buildImageGallery(hasMultipleImages),
                    ),

                    // Gradient overlay for better visibility of icons
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Image pagination indicators
                    if (hasMultipleImages)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildPageIndicators(widget.user.imageUrls.length),
                        ),
                      ),

                    // User like/dislike swipe actions
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSwipeActionButton(
                            color: Colors.white,
                            icon: Icons.close,
                            iconColor: AppColors.primary,
                            onTap: () => _handleDislike(context),
                          ),
                          _buildSwipeActionButton(
                            color: Colors.blue,
                            icon: Icons.star,
                            iconColor: Colors.white,
                            onTap: () => _handleSuperLike(context),
                            isLarge: false,
                          ),
                          _buildSwipeActionButton(
                            color: Colors.white,
                            icon: Icons.favorite,
                            iconColor: AppColors.primary,
                            onTap: () => _handleLike(context),
                          ),
                        ],
                      ),
                    ),

                    // Pull down indicator
                    if (_isSwipingDown)
                      Positioned(
                        top: 80,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Pull down to dismiss',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // User information section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name, age and verification
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.user.name}, ${widget.user.age}',
                              style: AppTextStyles.headline2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location with icon
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.user.location,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Bio section with expandable text
                      const Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFullBio = !_showFullBio;
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.bio,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.grey[800],
                              ),
                              maxLines: _showFullBio ? null : 3,
                              overflow: _showFullBio ? null : TextOverflow.ellipsis,
                            ),
                            if (widget.user.bio.length > 100 && !_showFullBio) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Read more',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Interests section with chips
                      const Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.user.interests.map((interest) =>
                            InterestChip(
                              label: interest,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              textColor: AppColors.primary,
                              icon: _getInterestIcon(interest),
                            )
                        ).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Basic info section
                      const Text(
                        'Basic Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.person_outline, 'Gender', widget.user.gender.isEmpty ? 'Not specified' : widget.user.gender),
                      _buildInfoRow(Icons.search, 'Looking for', widget.user.lookingFor.isEmpty ? 'Not specified' : widget.user.lookingFor),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => _handleLike(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.favorite, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Like Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(bool hasMultipleImages) {
    return widget.user.imageUrls.isEmpty
        ? Center(
      child: LetterAvatar(
        name: widget.user.name,
        size: 150,
        showBorder: false,
      ),
    )
        : PageView.builder(
      controller: _pageController,
      onPageChanged: _handlePageChanged,
      itemCount: widget.user.imageUrls.length,
      itemBuilder: (context, index) {
        return Hero(
          tag: index == 0 ? 'profile_image_${widget.user.id}' : 'profile_image_${widget.user.id}_$index',
          child: CachedNetworkImage(
            imageUrl: widget.user.imageUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            errorWidget: (context, url, error) => LetterAvatar(
              name: widget.user.name,
              size: double.infinity,
              showBorder: false,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPageIndicators(int count) {
    return List.generate(count, (index) {
      return Container(
        width: _currentPage == index ? 16 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
        ),
      );
    });
  }

  Widget _buildFloatingBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSwipeActionButton({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLarge = true,
  }) {
    final size = isLarge ? 64.0 : 50.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: isLarge ? 32 : 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData? _getInterestIcon(String interest) {
    final Map<String, IconData> interestIcons = {
      'Travel': Icons.flight_takeoff,
      'Music': Icons.music_note,
      'Sports': Icons.sports_basketball,
      'Cooking': Icons.restaurant,
      'Reading': Icons.menu_book,
      'Movies': Icons.movie,
      'Art': Icons.palette,
      'Photography': Icons.camera_alt,
      'Fitness': Icons.fitness_center,
      'Gaming': Icons.sports_esports,
      'Dancing': Icons.nightlife,
      'Technology': Icons.devices,
      'Fashion': Icons.shopping_bag,
      'Food': Icons.fastfood,
      'Outdoors': Icons.terrain,
      'cat': Icons.pets, // For the test data
      'Coffee': Icons.coffee,
    };

    return interestIcons[interest];
  }

  Future<void> _handleLike(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matchedUser = await userProvider.swipeRight(widget.user.id);
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
    } else {
      // Show a success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You liked ${widget.user.name}!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleDislike(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).swipeLeft(widget.user.id);
    Navigator.of(context).pop();
  }

  Future<void> _handleSuperLike(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matchedUser = await userProvider.superLike(widget.user.id);
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
    } else {
      // Show a success message for the super like
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You super liked ${widget.user.name}!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Report ${widget.user.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please select a reason for reporting this profile:',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildReportOption('Inappropriate photos'),
                      _buildReportOption('Fake profile / Scam'),
                      _buildReportOption('Offensive behavior'),
                      _buildReportOption('Underage user'),
                      _buildReportOption('Other reason'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(reason),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Close report dialog
        Navigator.pop(context);

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you for your report. We\'ll review it shortly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}