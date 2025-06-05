// lib/widgets/enhanced_fake_video_player.dart - Instagram-style fake video player
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/fake_video_call_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/letter_avatar.dart';

class EnhancedFakeVideoPlayer extends StatefulWidget {
  final FakeCallSession session;
  final VoidCallback onCallEnd;
  final bool showControls;
  final VoidCallback onControlsToggle;

  const EnhancedFakeVideoPlayer({
    Key? key,
    required this.session,
    required this.onCallEnd,
    required this.showControls,
    required this.onControlsToggle,
  }) : super(key: key);

  @override
  State<EnhancedFakeVideoPlayer> createState() => _EnhancedFakeVideoPlayerState();
}

class _EnhancedFakeVideoPlayerState extends State<EnhancedFakeVideoPlayer>
    with TickerProviderStateMixin {

  // Video Player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  String? _videoErrorMessage;
  bool _isVideoLoading = true;

  // Animation controllers for Instagram-like effects
  late AnimationController _heartController;
  late AnimationController _waveController;
  late AnimationController _textController;
  late AnimationController _shimmerController;
  late AnimationController _breathingController;

  late Animation<double> _heartAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _breathingAnimation;

  // Timers and subscriptions
  Timer? _eventTimer;
  Timer? _textTimer;
  Timer? _interactionTimer;
  StreamSubscription? _eventSubscription;

  // State
  bool _showingHeart = false;
  bool _showingWave = false;
  String _currentText = '';
  bool _showText = false;
  int _textIndex = 0;
  bool _isUserEngaged = false;

  final List<String> _conversationTexts = [];
  final List<String> _reactions = ['😍', '😘', '🥰', '😊', '🤗', '👋', '💕'];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConversationTexts();
    _initializeVideo();
    _startEventSubscription();
    _startInteractionSimulation();
  }

  void _initializeAnimations() {
    // Heart animation for likes/reactions
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Wave animation for gestures
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Text animation for messages
    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Shimmer effect for engagement
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Breathing effect for video border
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Initialize animations
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOutBack),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Start continuous animations
    _shimmerController.repeat();
    _breathingController.repeat(reverse: true);
  }

  void _loadConversationTexts() {
    final service = FakeVideoCallService();
    _conversationTexts.addAll(service.getConversationStarters());
    _conversationTexts.addAll(service.getFakeResponses());

    // Add Instagram-style texts
    _conversationTexts.addAll([
      'You look amazing! ✨',
      'Love your vibe! 💫',
      'This is so fun! 🎉',
      'You have beautiful eyes 👀',
      'Where are you from? 🌍',
      'What do you love doing? 💭',
      'You seem really cool! 😎',
      'I love this energy! ⚡',
    ]);
  }

  Future<void> _initializeVideo() async {
    try {
      final videoUrl = widget.session.fakeVideo.videoUrl;
      print('🎥 Initializing enhanced fake video: $videoUrl');

      if (videoUrl.startsWith('assets/')) {
        _videoController = VideoPlayerController.asset(videoUrl);
      } else {
        _videoController = VideoPlayerController.network(videoUrl);
      }

      _videoController!.addListener(() {
        if (_videoController!.value.hasError) {
          print('❌ Video player error: ${_videoController!.value.errorDescription}');
          if (mounted) {
            setState(() {
              _hasVideoError = true;
              _videoErrorMessage = _videoController!.value.errorDescription;
              _isVideoLoading = false;
            });
          }
        }
      });

      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoLoading = false;
          _hasVideoError = false;
        });

        _videoController!.play();
        _videoController!.setLooping(true);

        print('✅ Enhanced fake video initialized and playing');
        _startConversationTexts();
      }
    } catch (e) {
      print('❌ Error initializing enhanced fake video: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _videoErrorMessage = e.toString();
          _isVideoLoading = false;
        });

        _startConversationTexts();
      }
    }
  }

  void _startConversationTexts() {
    _textTimer = Timer.periodic(Duration(seconds: 6 + _random.nextInt(8)), (timer) {
      if (mounted && _conversationTexts.isNotEmpty) {
        _showConversationText();
      }
    });
  }

  void _showConversationText() {
    setState(() {
      _currentText = _conversationTexts[_textIndex % _conversationTexts.length];
      _showText = true;
      _textIndex++;
    });

    _textController.forward().then((_) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _textController.reverse().then((_) {
            setState(() {
              _showText = false;
            });
          });
        }
      });
    });
  }

  void _startEventSubscription() {
    final service = FakeVideoCallService();
    _eventSubscription = service.generateCallEvents().listen((event) {
      if (mounted) {
        _handleFakeEvent(event);
      }
    });
  }

  void _startInteractionSimulation() {
    _interactionTimer = Timer.periodic(Duration(seconds: 8 + _random.nextInt(12)), (timer) {
      if (mounted) {
        _simulateUserInteraction();
      }
    });
  }

  void _simulateUserInteraction() {
    final interactions = ['heart', 'wave', 'smile'];
    final interaction = interactions[_random.nextInt(interactions.length)];

    switch (interaction) {
      case 'heart':
        _showHeartReaction();
        break;
      case 'wave':
        _showWaveGesture();
        break;
      case 'smile':
        _showSmileReaction();
        break;
    }
  }

  void _showHeartReaction() {
    setState(() {
      _showingHeart = true;
      _isUserEngaged = true;
    });

    _heartController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _heartController.reverse().then((_) {
            setState(() {
              _showingHeart = false;
              _isUserEngaged = false;
            });
          });
        }
      });
    });
  }

  void _showWaveGesture() {
    setState(() {
      _showingWave = true;
    });

    _waveController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _waveController.reverse().then((_) {
            setState(() {
              _showingWave = false;
            });
          });
        }
      });
    });
  }

  void _showSmileReaction() {
    // Show a random emoji reaction
    final emoji = _reactions[_random.nextInt(_reactions.length)];

    if (mounted) {
      _showFloatingEmoji(emoji);
    }
  }

  void _showFloatingEmoji(String emoji) {
    // This would show a floating emoji animation
    // For now, we'll just trigger the shimmer effect
    _shimmerController.reset();
    _shimmerController.forward();
  }

  void _handleFakeEvent(FakeCallEvent event) {
    switch (event) {
      case FakeCallEvent.gesture:
        _showWaveGesture();
        break;
      case FakeCallEvent.smile:
        _showSmileReaction();
        break;
      case FakeCallEvent.wave:
        _showWaveGesture();
        break;
      case FakeCallEvent.nod:
      // Show a subtle nod animation
        break;
      case FakeCallEvent.laugh:
        _showHeartReaction();
        break;
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _waveController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _breathingController.dispose();
    _videoController?.dispose();
    _eventTimer?.cancel();
    _textTimer?.cancel();
    _interactionTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onControlsToggle,
      child: Stack(
        children: [
          // Main video background with breathing effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathingAnimation.value,
                  child: _buildVideoBackground(),
                );
              },
            ),
          ),

          // Shimmer overlay for engagement
          if (_isUserEngaged)
            Positioned.fill(
              child: _buildShimmerOverlay(),
            ),

          // Heart reaction overlay
          if (_showingHeart)
            Positioned.fill(
              child: _buildHeartOverlay(),
            ),

          // Wave gesture overlay
          if (_showingWave)
            Positioned.fill(
              child: _buildWaveOverlay(),
            ),

          // Conversation text overlay
          if (_showText)
            _buildConversationTextOverlay(),

          // User info overlay
          if (widget.showControls)
            _buildUserInfoOverlay(),

          // Loading overlay
          if (_isVideoLoading)
            Positioned.fill(
              child: _buildLoadingOverlay(),
            ),

          // Floating reactions
          _buildFloatingReactions(),

          // Connection quality indicator
          _buildConnectionQualityIndicator(),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    if (_isVideoInitialized && !_hasVideoError && _videoController != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background image with parallax effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.1 * _breathingAnimation.value,
                  child: CachedNetworkImage(
                    imageUrl: widget.session.fakeVideo.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade800,
                            Colors.grey.shade900,
                          ],
                        ),
                      ),
                      child: Center(
                        child: LetterAvatar(
                          name: widget.session.fakeVideo.user.name,
                          size: 120,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade800,
                            Colors.grey.shade900,
                          ],
                        ),
                      ),
                      child: Center(
                        child: LetterAvatar(
                          name: widget.session.fakeVideo.user.name,
                          size: 120,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Error overlay if video failed
          if (_hasVideoError)
            _buildVideoErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.2),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                size: 64,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Video temporarily unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Showing profile instead',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isVideoLoading = true;
                  _hasVideoError = false;
                  _videoErrorMessage = null;
                });
                _initializeVideo();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Retry Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: [
                0.0,
                _shimmerAnimation.value.clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeartOverlay() {
    return AnimatedBuilder(
      animation: _heartAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: _heartAnimation.value * 2,
              colors: [
                Colors.pink.withOpacity(0.3 * _heartAnimation.value),
                Colors.red.withOpacity(0.2 * _heartAnimation.value),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Transform.scale(
              scale: _heartAnimation.value,
              child: Transform.rotate(
                angle: _heartAnimation.value * 0.1,
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.pink.withOpacity(_heartAnimation.value),
                  size: 80,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveOverlay() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Positioned(
          right: 40 + (50 * _waveAnimation.value),
          top: MediaQuery.of(context).size.height * 0.3,
          child: Transform.scale(
            scale: _waveAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Text(
                '👋',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationTextOverlay() {
    return Positioned(
      bottom: 140,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _textAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _textAnimation.value)),
            child: Opacity(
              opacity: _textAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.grey.shade900.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoOverlay() {
    return Positioned(
      bottom: 200,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: LetterAvatar(
                name: widget.session.fakeVideo.user.name,
                size: 50,
                imageUrls: [widget.session.fakeVideo.thumbnailUrl],
                showBorder: true,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${widget.session.fakeVideo.user.name}, ${widget.session.fakeVideo.user.age}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.session.fakeVideo.user.location,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: widget.session.fakeVideo.user.interests
                      .take(2)
                      .map((interest) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.grey.shade900.withOpacity(0.9),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Setting up video call',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingReactions() {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        children: _reactions
            .take(3)
            .map((emoji) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _heartAnimation.value),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
            },
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildConnectionQualityIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.green.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'HD',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}