// lib/screens/modern_enhanced_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/interest_chip.dart';
import '../widgets/components/profile_avatar.dart';
import '../widgets/components/section_card.dart';
import '../screens/modern_profile_edit_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/photo_manager_screen.dart';
import '../screens/profile_verification_screen.dart';
import '../animations/animations.dart';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({Key? key}) : super(key: key);

  @override
  _EnhancedProfileScreenState createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  bool _showPreview = false;
  int _profileCompletion = 0;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser();

      if (mounted) {
        final user = userProvider.currentUser;

        // Calculate profile completion percentage
        if (user != null) {
          int completionScore = 0;

          // Check different profile elements
          if (user.imageUrls.isNotEmpty) completionScore += 20;
          if (user.bio.length > 20) completionScore += 20;
          if (user.interests.length >= 3) completionScore += 20;
          if (user.location.isNotEmpty) completionScore += 20;
          if (user.gender.isNotEmpty && user.lookingFor.isNotEmpty) completionScore += 20;

          setState(() {
            _profileCompletion = completionScore;
          });
        }

        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile: $e';
        });
      }
    }
  }

  void _toggleProfilePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.currentUser;

          if (user == null) {
            return _buildNoUserView();
          }

          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _loadUserData,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Modern app bar with profile picture
                SliverAppBar(
                  expandedHeight: 260.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  leading: const SizedBox.shrink(),
                  actions: [
                    // Settings button
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/filters');
                      },
                    ),
                    // Logout button
                    IconButton(
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      onPressed: () async {
                        try {
                          await Provider.of<AppAuthProvider>(context, listen: false).logout();
                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error logging out: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  flexibleSpace: FadeTransition(
                    opacity: _headerAnimation,
                    child: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Gradient background
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),

                          // Wave pattern at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipPath(
                              clipper: WaveClipper(),
                              child: Container(
                                height: 50,
                                color: AppColors.background,
                              ),
                            ),
                          ),

                          // Profile image and name with animation
                          Positioned(
                            bottom: 70,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    // Profile image
                                    Hero(
                                      tag: 'profile_image',
                                      child: Container(
                                        width: 130,
                                        height: 130,
                                        decoration: AppDecorations.profileImageAvatar,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(65),
                                          child: CachedNetworkImage(
                                            imageUrl: user.imageUrls.isNotEmpty
                                                ? user.imageUrls[0]
                                                : 'https://i.pravatar.cc/300?img=33',
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.person, size: 60),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Edit photo button
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const PhotoManagerScreen(),
                                          ),
                                        ).then((_) => _loadUserData());
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
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
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // User name and verification badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${user.name}, ${user.age}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4,
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Location
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.location,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
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
                ),

                // Profile content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile preview mode toggle
                        GestureDetector(
                          onTap: _toggleProfilePreview,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _showPreview ? AppColors.primary.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: _showPreview ? null : AppShadows.small,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showPreview ? Icons.visibility : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showPreview ? "Viewing as others see you" : "Preview your profile",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: _showPreview ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Profile completion card
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 200),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getCompletionColor().withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getCompletionIcon(),
                                          color: _getCompletionColor(),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Profile Completion",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getCompletionMessage(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: _getCompletionColor(),
                                            width: 3,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$_profileCompletion%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: _getCompletionColor(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: LinearProgressIndicator(
                                      value: _profileCompletion / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(_getCompletionColor()),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Premium card with improved design
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 300),
                          child: Card(
                            elevation: 6,
                            shadowColor: Colors.amber.withOpacity(0.3),
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
                                    Colors.amber.shade300,
                                    Colors.amber.shade700,
                                  ],
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => PremiumScreen()),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.workspace_premium,
                                            color: Colors.white,
                                            size: 34,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Get Premium',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'POPULAR',
                                                      style: TextStyle(
                                                        color: Colors.amber.shade700,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              const Text(
                                                'See who likes you & unlock premium features',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color: Colors.white,
                                                          size: 12,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '5 Super Likes',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.bolt,
                                                          color: Colors.white,
                                                          size: 12,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '1 Boost',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
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
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Verification card with blue color scheme
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 400),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Colors.blue.withOpacity(0.1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProfileVerificationScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.verified_user, color: Colors.blue, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Verify Your Profile',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Get a blue checkmark and increase your matches',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Verify',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bio section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 500),
                          child: SectionCard(
                            title: 'About Me',
                            icon: Icons.person_outline,
                            iconColor: AppColors.primary,
                            action: IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ModernProfileEditScreen(),
                                  ),
                                ).then((_) => _loadUserData());
                              },
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.bio.isNotEmpty ? user.bio : 'Add something about yourself...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: user.bio.isNotEmpty ? Colors.black87 : Colors.black38,
                                    ),
                                  ),
                                  // Suggestions to improve bio
                                  if(user.bio.length < 50)
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb_outline, color: Colors.amber.shade800, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Tip: Profiles with detailed bios get up to 50% more matches!',
                                              style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Interests section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 600),
                          child: SectionCard(
                            title: 'My Interests',
                            icon: Icons.favorite_border,
                            iconColor: AppColors.error,
                            action: IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ModernProfileEditScreen(),
                                  ),
                                ).then((_) => _loadUserData());
                              },
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: user.interests.isNotEmpty
                                  ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.interests.map((interest) => InterestChip(
                                  label: interest,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  textColor: AppColors.primary,
                                )).toList(),
                              )
                                  : Center(
                                child: Text(
                                  'Add your interests to help us find better matches',
                                  style: TextStyle(color: Colors.grey.shade400),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Photos section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 700),
                          child: SectionCard(
                            title: 'My Photos',
                            icon: Icons.photo_library_outlined,
                            iconColor: AppColors.secondary,
                            action: IconButton(
                              icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const PhotoManagerScreen(),
                                  ),
                                ).then((_) => _loadUserData());
                              },
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 160,
                                  padding: const EdgeInsets.all(16),
                                  child: user.imageUrls.length > 1
                                      ? ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: user.imageUrls.length,
                                    itemBuilder: (context, index) {
                                      if (index == 0) return const SizedBox.shrink(); // Skip the first image (already shown in the header)

                                      return Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: user.imageUrls[index],
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(color: Colors.grey[200]),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                      : Center(
                                    child: Text(
                                      'Add more photos to your profile',
                                      style: TextStyle(color: Colors.grey.shade400),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                if (user.imageUrls.length < 4)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue.shade800, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Profiles with 4+ photos get more attention and matches!',
                                              style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Discovery preferences section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 800),
                          child: SectionCard(
                            title: 'Discovery Settings',
                            icon: Icons.tune,
                            iconColor: Colors.purple,
                            action: IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () {
                                Navigator.of(context).pushNamed('/filters')
                                    .then((_) => _loadUserData());
                              },
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildSettingRow(
                                    'Age Range',
                                    '${user.ageRangeStart} - ${user.ageRangeEnd}',
                                    Icons.calendar_today,
                                  ),
                                  const Divider(),
                                  _buildSettingRow(
                                    'Distance',
                                    '${user.distance} km',
                                    Icons.place,
                                  ),
                                  const Divider(),
                                  _buildSettingRow(
                                    'Looking For',
                                    user.lookingFor.isNotEmpty ? user.lookingFor : 'Everyone',
                                    Icons.person_search,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Additional settings
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 900),
                          child: SectionCard(
                            title: 'Account Settings',
                            icon: Icons.settings,
                            iconColor: Colors.grey.shade700,
                            child: Column(
                              children: [
                                _buildSettingsOption(
                                  'Notifications',
                                  'Manage your notifications',
                                  Icons.notifications_none,
                                      () {},
                                ),
                                const Divider(),
                                _buildSettingsOption(
                                  'Privacy',
                                  'Control your privacy settings',
                                  Icons.lock_outline,
                                      () {},
                                ),
                                const Divider(),
                                _buildSettingsOption(
                                  'App Settings',
                                  'Language, theme and more',
                                  Icons.phone_android,
                                      () {},
                                ),
                                const Divider(),
                                _buildSettingsOption(
                                  'Help & Support',
                                  'Contact us with any questions',
                                  Icons.help_outline,
                                      () {},
                                  isDanger: false,
                                ),
                                const Divider(),
                                _buildSettingsOption(
                                  'Logout',
                                  'Sign out of your account',
                                  Icons.exit_to_app,
                                      () async {
                                    try {
                                      await Provider.of<AppAuthProvider>(context, listen: false).logout();
                                      if (mounted) {
                                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error logging out: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                                  isDanger: true,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _isLoading || _errorMessage.isNotEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernProfileEditScreen(),
            ),
          ).then((_) => _loadUserData());
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        elevation: 4,
      ),
    );
  }

  Widget _buildSettingRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap, {
        bool isDanger = false,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger ? AppColors.error.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDanger ? AppColors.error : Colors.grey.shade700,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDanger ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDanger ? AppColors.error.withOpacity(0.8) : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDanger ? AppColors.error : Colors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Color _getCompletionColor() {
    if (_profileCompletion >= 80) return Colors.green;
    if (_profileCompletion >= 50) return Colors.amber;
    return AppColors.error;
  }

  IconData _getCompletionIcon() {
    if (_profileCompletion >= 80) return Icons.check_circle;
    if (_profileCompletion >= 50) return Icons.auto_awesome;
    return Icons.warning_amber;
  }

  String _getCompletionMessage() {
    if (_profileCompletion >= 80) return 'Your profile looks great!';
    if (_profileCompletion >= 50) return 'Keep improving your profile to get more matches';
    return 'Complete your profile to increase your chances';
  }

  Widget _buildLoadingView() {
    return const Center(
      child: LoadingIndicator(
        type: LoadingIndicatorType.pulse,
        size: LoadingIndicatorSize.large,
        message: 'Loading your profile...',
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage),
          const SizedBox(height: 24),
          AppButton(
            text: 'Try Again',
            icon: Icons.refresh,
            onPressed: _loadUserData,
            type: AppButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNoUserView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_circle,
                size: 80,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profile Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your profile could not be loaded. Please create a profile to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Create Profile',
              icon: Icons.person_add,
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.forceSyncCurrentUser();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Creating user profile...')),
                  );
                  _loadUserData();
                }
              },
              type: AppButtonType.primary,
              size: AppButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}