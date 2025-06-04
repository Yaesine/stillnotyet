// lib/widgets/optimized_swipe_card.dart - Update to reposition common interests

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/profile_view_tracker.dart';
import '../theme/app_theme.dart';
import '../widgets/components/letter_avatar.dart';

class OptimizedSwipeCard extends StatefulWidget {
  final User user;
  final bool isTop;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSuperLike;
  final VoidCallback? onViewProfile;

  const OptimizedSwipeCard({
    Key? key,
    required this.user,
    required this.isTop,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSuperLike,
    this.onViewProfile,
  }) : super(key: key);

  @override
  _OptimizedSwipeCardState createState() => _OptimizedSwipeCardState();
}

class _OptimizedSwipeCardState extends State<OptimizedSwipeCard> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragAngle = 0;
  int _currentImageIndex = 0;
  bool _showInfo = false;
  bool _isImageLoaded = false;

  // Add vertical drag tracking
  double _verticalDragOffset = 0;
  bool _isVerticalDrag = false;

  // Animation controller for bounce back
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _verticalSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _verticalSlideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addListener(() {
      setState(() {
        _dragOffset = _slideAnimation.value;
        _dragAngle = _rotationAnimation.value;
        _verticalDragOffset = _verticalSlideAnimation.value;
      });
    });

    // Set initial state of image loaded
    _isImageLoaded = widget.user.imageUrls.isEmpty;

    // Schedule image preloading for after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages();
    });
  }

  // Preload images outside of initState
  void _preloadImages() {
    if (widget.user.imageUrls.isNotEmpty) {
      precacheImage(NetworkImage(widget.user.imageUrls[0]), context).then((_) {
        if (mounted) {
          setState(() {
            _isImageLoaded = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate opacity based on drag offset
    final opacity = widget.isTop && (_dragOffset.abs() > 20 || _verticalDragOffset.abs() > 20)
        ? max(0.5, min(1.0, 1.0 - max(_dragOffset.abs(), _verticalDragOffset.abs()) / 500))
        : 1.0;

    final fontSize = MediaQuery.of(context).size.width * 0.3;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Make sure we have safe margins - fit the card within available space
        final double horizontalMargin = max(12.0, min(16.0, constraints.maxWidth * 0.05));
        final double topMargin = max(80.0, min(100.0, constraints.maxHeight * 0.15));
        final double bottomMargin = max(60.0, min(78.0, constraints.maxHeight * 0.12));

        return GestureDetector(
          onHorizontalDragStart: widget.isTop ? (_) {
            _isVerticalDrag = false;
          } : null,
          onHorizontalDragUpdate: widget.isTop ? _handleDragUpdate : null,
          onHorizontalDragEnd: widget.isTop ? _handleDragEnd : null,
          onVerticalDragStart: widget.isTop ? (_) {
            _isVerticalDrag = true;
          } : null,
          onVerticalDragUpdate: widget.isTop ? _handleVerticalDragUpdate : null,
          onVerticalDragEnd: widget.isTop ? _handleVerticalDragEnd : null,
          onTap: () {
            if (widget.isTop) {
              setState(() {
                _showInfo = !_showInfo;
              });
              // Track profile view
              final tracker = ProfileViewTracker();
              tracker.trackProfileView(widget.user.id);

              if (_showInfo && widget.onViewProfile != null) {
                widget.onViewProfile!();
              }
            }
          },
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(
                  widget.isTop && _dragOffset.abs() > 0 ? _dragOffset : 0,
                  widget.isTop && _verticalDragOffset < 0 ? _verticalDragOffset : 0
              ),
              child: Transform.rotate(
                angle: widget.isTop && _dragOffset.abs() > 0 ? (_dragOffset / 1000) : 0,
                child: Container(
                  // Updated margins to ensure card fits within screen bounds
                  margin: EdgeInsets.fromLTRB(horizontalMargin, topMargin, horizontalMargin, bottomMargin),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Profile Image with optimized loading
                        if (!_isImageLoaded)
                        // Show a placeholder while waiting for image to load
                          Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          )
                        else if (widget.user.imageUrls.isEmpty || _currentImageIndex >= widget.user.imageUrls.length)
                        // Show letter avatar if no images
                          Container(
                            key: ValueKey<String>('letter-avatar-${widget.user.id}'),
                            color: AppColors.primary,
                            alignment: Alignment.center,
                            child: Text(
                              widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                        // Use CachedNetworkImage for better caching
                          Hero(
                            tag: 'profile_image_${widget.user.id}',
                            child: CachedNetworkImage(
                              key: ValueKey<int>(_currentImageIndex),
                              imageUrl: widget.user.imageUrls[_currentImageIndex],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primary,
                                alignment: Alignment.center,
                                child: Text(
                                  widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Shiny border glow effect when card is active
                        if (widget.isTop)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _verticalDragOffset < -50
                                      ? Colors.blue.withOpacity(0.8)
                                      : _dragOffset > 50
                                      ? Colors.green.withOpacity(0.8)
                                      : _dragOffset < -50
                                      ? Colors.red.withOpacity(0.8)
                                      : Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                        // Image pagination dots
                        if (widget.user.imageUrls.length > 1)
                          Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.user.imageUrls.length,
                                    (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _currentImageIndex == index ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentImageIndex == index
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Swipe indicators
                        if (widget.isTop)
                          _buildSwipeIndicator(),

                        // User info with gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _showInfo ? 280 : 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.9),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.9],
                              ),
                            ),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User name, verified badge and common interests row
                                    _buildUserInfoHeader(context),

                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.user.location,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_showInfo) ...[
                                      const SizedBox(height: 24),
                                      const Text(
                                        'About',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.user.bio,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Interests',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: widget.user.interests.map((interest) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            interest,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )).toList(),
                                      ),

                                      // View Full Profile button
                                      if (widget.onViewProfile != null) ...[
                                        const SizedBox(height: 16),
                                        Center(
                                          child: ElevatedButton.icon(
                                            onPressed: widget.onViewProfile,
                                            icon: const Icon(Icons.person, size: 18),
                                            label: const Text('View Full Profile'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Icon(
                                        _showInfo ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Left/Right image navigation
                        if (widget.isTop && widget.user.imageUrls.length > 1)
                          Row(
                            children: [
                              // Left side (previous image)
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: _previousImage,
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _currentImageIndex > 0
                                          ? Container(
                                        margin: const EdgeInsets.only(left: 12),
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_left,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),

                              // Middle area (open/close profile details)
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showInfo = !_showInfo;
                                    });
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),

                              // Right side (next image)
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: _nextImage,
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _currentImageIndex < widget.user.imageUrls.length - 1
                                          ? Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Full profile view "hotspot" icon
                        if (widget.isTop && widget.onViewProfile != null)
                          Positioned(
                            top: 24,
                            right: 24,
                            child: GestureDetector(
                              onTap: widget.onViewProfile,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
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
      },
    );
  }

  // New method to build the user info header with name, verified badge, and common interests
  // Update the _buildUserInfoHeader method in lib/widgets/optimized_swipe_card.dart
  Widget _buildUserInfoHeader(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;

    // Check for matching interests
    int commonInterestsCount = 0;
    if (currentUser != null && currentUser.interests.isNotEmpty && widget.user.interests.isNotEmpty) {
      final commonInterests = widget.user.interests.where((interest) =>
          currentUser.interests.contains(interest)).toList();
      commonInterestsCount = commonInterests.length;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Name and age - with constrained width
        Flexible(
          child: Text(
            '${widget.user.name}, ${widget.user.age}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),

        // Horizontal row of badges
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Verified badge - ONLY show if user.isVerified is true
            if (widget.user.isVerified)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),

            // Common interests badge if any exist
            if (commonInterestsCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$commonInterestsCount',
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
      ],
    );
  }

  // Keep the existing methods for other functionality (moved this one here)
  Widget _buildSwipeIndicator() {
    // Handle horizontal swipe indicators
    if (_dragOffset.abs() > 20 && !_isVerticalDrag) {
      return Positioned(
        top: 24,
        left: _dragOffset > 0 ? 24 : null,
        right: _dragOffset < 0 ? 24 : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: _dragOffset > 0 ? Colors.green : Colors.red,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
            color: (_dragOffset.abs() > 50)
                ? (_dragOffset > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                _dragOffset > 0 ? Icons.favorite : Icons.close,
                color: _dragOffset > 0 ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                _dragOffset > 0 ? 'LIKE' : 'NOPE',
                style: TextStyle(
                  color: _dragOffset > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Handle vertical swipe indicator (Super Like)
    else if (_verticalDragOffset < -20 && _isVerticalDrag) {
      return Positioned(
        top: 24,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _verticalDragOffset < -50
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.star,
                  color: Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'SUPER LIKE',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Return empty container if no drag is happening
    return const SizedBox.shrink();
  }

  // Keep all other methods (handleDragUpdate, handleDragEnd, etc.)
  void _handleDragUpdate(DragUpdateDetails details) {
    // Cancel any running animations
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    setState(() {
      _dragOffset += details.delta.dx;
      _dragAngle = _dragOffset / 1000; // Update rotation angle
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    // Cancel any running animations
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    setState(() {
      // Only track upward movement (negative values) for Super Like
      if (details.delta.dy < 0) {
        _verticalDragOffset += details.delta.dy;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final swipeThreshold = MediaQuery.of(context).size.width / 6;

    if (_dragOffset.abs() > swipeThreshold || velocity.abs() > 300) {
      if (_dragOffset > 0) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    } else {
      // Not enough to trigger swipe - animate back to center
      _slideAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).animate(_animationController);

      _rotationAnimation = Tween<double>(
        begin: _dragAngle,
        end: 0,
      ).animate(_animationController);

      _animationController.forward().then((_) {
        _animationController.reset();
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final swipeThreshold = MediaQuery.of(context).size.height / 10;

    if (_verticalDragOffset < -swipeThreshold || velocity < -300) {
      widget.onSuperLike();
    } else {
      // Not enough to trigger Super Like - animate back to center
      _verticalSlideAnimation = Tween<double>(
        begin: _verticalDragOffset,
        end: 0,
      ).animate(_animationController);

      _animationController.forward().then((_) {
        _animationController.reset();
      });
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });

      // Pre-cache the image when changing
      if (widget.user.imageUrls.isNotEmpty && _currentImageIndex < widget.user.imageUrls.length) {
        precacheImage(NetworkImage(widget.user.imageUrls[_currentImageIndex]), context);
      }
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.user.imageUrls.length - 1) {
      setState(() {
        _currentImageIndex++;
      });

      // Pre-cache the image when changing
      if (widget.user.imageUrls.isNotEmpty && _currentImageIndex < widget.user.imageUrls.length) {
        precacheImage(NetworkImage(widget.user.imageUrls[_currentImageIndex]), context);
      }
    }
  }
}