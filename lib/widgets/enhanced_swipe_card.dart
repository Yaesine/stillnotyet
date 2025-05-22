// Modified version of lib/widgets/enhanced_swipe_card.dart
// with improved profile viewing functionality

import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../services/profile_view_tracker.dart';
import '../theme/app_theme.dart';
import '../widgets/components/letter_avatar.dart';

class EnhancedSwipeCard extends StatefulWidget {
  final User user;
  final bool isTop;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSuperLike;
  // NEW: Add callback for viewing profile
  final VoidCallback? onViewProfile;

  const EnhancedSwipeCard({
    Key? key,
    required this.user,
    required this.isTop,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSuperLike,
    this.onViewProfile, // NEW: Optional callback to view profile
  }) : super(key: key);

  @override
  _EnhancedSwipeCardState createState() => _EnhancedSwipeCardState();
}

class _EnhancedSwipeCardState extends State<EnhancedSwipeCard> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragAngle = 0;
  int _currentImageIndex = 0;
  bool _showInfo = false;

  // Animation controller for bounce back
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addListener(() {
      setState(() {
        _dragOffset = _slideAnimation.value;
        _dragAngle = _rotationAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate opacity based on drag offset (fades when dragging away)
    final opacity = widget.isTop
        ? max(0.5, min(1.0, 1.0 - _dragOffset.abs() / 500))
        : 1.0;

    return GestureDetector(
      onHorizontalDragUpdate: widget.isTop ? _handleDragUpdate : null,
      onHorizontalDragEnd: widget.isTop ? _handleDragEnd : null,
      onTap: () {
        if (widget.isTop) {
          setState(() {
            _showInfo = !_showInfo;
          });
          // Track profile view
          final tracker = ProfileViewTracker();
          tracker.trackProfileView(widget.user.id);

          // If more info is shown and onViewProfile callback exists, call it
          if (_showInfo && widget.onViewProfile != null) {
            widget.onViewProfile!();
          }
        }
      },
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(widget.isTop ? _dragOffset : 0, 0),
          child: Transform.rotate(
            angle: widget.isTop ? (_dragOffset / 1000) : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.fromLTRB(16, 100, 16, 78),
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
                    // Profile Image or Letter Avatar
                    Hero(
                      tag: 'profile_image_${widget.user.id}',
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: widget.user.imageUrls.isNotEmpty && _currentImageIndex < widget.user.imageUrls.length
                            ? Container(
                          key: ValueKey<int>(_currentImageIndex),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.user.imageUrls[_currentImageIndex],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            : Container(
                          key: ValueKey<String>('letter-avatar-${widget.user.id}'),
                          color: AppColors.primary, // Use app's primary color as background
                          alignment: Alignment.center,
                          child: Text(
                            widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width * 0.3, // Responsive font size
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
                              color: _dragOffset > 50
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
                    if (widget.isTop && _dragOffset.abs() > 20)
                      Positioned(
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
                              color: _dragOffset > 0 ? Colors.green : AppColors.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: (_dragOffset.abs() > 50)
                                ? (_dragOffset > 0 ? Colors.green.withOpacity(0.2) : AppColors.primary.withOpacity(0.2))
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _dragOffset > 0 ? Icons.favorite : Icons.close,
                                color: _dragOffset > 0 ? Colors.green : AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _dragOffset > 0 ? 'LIKE' : 'NOPE',
                                style: TextStyle(
                                  color: _dragOffset > 0 ? Colors.green : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

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
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${widget.user.name}, ${widget.user.age}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
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
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.user.location,
                                      style: const TextStyle(
                                        color: Colors.white70,
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

                                  // NEW: Add a "View Full Profile" button
                                  if (widget.onViewProfile != null) ...[
                                    const SizedBox(height: 16),
                                    Center(
                                      child: ElevatedButton.icon(
                                        onPressed: widget.onViewProfile,
                                        icon: Icon(Icons.person, size: 18),
                                        label: Text('View Full Profile'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                    // NEW: Full profile view "hotspot" icon to make it more obvious
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
                            child: Icon(
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
  }

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

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final swipeThreshold = MediaQuery.of(context).size.width / 4;

    if (_dragOffset.abs() > swipeThreshold || velocity.abs() > 800) {
      // Swipe completed - animate card off screen
      final screenWidth = MediaQuery.of(context).size.width;
      final endPosition = _dragOffset > 0 ? screenWidth * 1.5 : -screenWidth * 1.5;

      _slideAnimation = Tween<double>(
        begin: _dragOffset,
        end: endPosition,
      ).animate(_animationController);

      _rotationAnimation = Tween<double>(
        begin: _dragAngle,
        end: _dragOffset > 0 ? pi / 8 : -pi / 8,
      ).animate(_animationController);

      _animationController.forward().then((_) {
        if (_dragOffset > 0) {
          widget.onSwipeRight();
        } else {
          widget.onSwipeLeft();
        }
      });
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
        // Reset controller for next use
        _animationController.reset();
      });
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.user.imageUrls.length - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }
}