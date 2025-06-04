// lib/widgets/fake_video_player.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/fake_video_call_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/letter_avatar.dart';

class FakeVideoPlayer extends StatefulWidget {
  final FakeCallSession session;
  final VoidCallback onCallEnd;
  final bool showControls;
  final VoidCallback onControlsToggle;

  const FakeVideoPlayer({
    Key? key,
    required this.session,
    required this.onCallEnd,
    required this.showControls,
    required this.onControlsToggle,
  }) : super(key: key);

  @override
  State<FakeVideoPlayer> createState() => _FakeVideoPlayerState();
}

class _FakeVideoPlayerState extends State<FakeVideoPlayer>
    with TickerProviderStateMixin {

  late AnimationController _videoController;
  late AnimationController _gestureController;
  late Animation<double> _gestureAnimation;

  Timer? _eventTimer;
  Timer? _textTimer;
  StreamSubscription? _eventSubscription;

  bool _isVideoLoaded = false;
  bool _showingGesture = false;
  String _currentText = '';
  bool _showText = false;
  int _textIndex = 0;

  final List<String> _conversationTexts = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConversationTexts();
    _startVideoSimulation();
    _startEventSubscription();
  }

  void _initializeAnimations() {
    _videoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _gestureController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _gestureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gestureController,
      curve: Curves.easeInOut,
    ));
  }

  void _loadConversationTexts() {
    final service = FakeVideoCallService();
    _conversationTexts.addAll(service.getConversationStarters());
    _conversationTexts.addAll(service.getFakeResponses());
  }

  void _startVideoSimulation() {
    // Simulate video loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isVideoLoaded = true;
        });
        _videoController.repeat();
      }
    });

    // Start showing conversation texts
    _startConversationTexts();
  }

  void _startConversationTexts() {
    _textTimer = Timer.periodic(Duration(seconds: 8 + _random.nextInt(7)), (timer) {
      if (mounted && _conversationTexts.isNotEmpty) {
        setState(() {
          _currentText = _conversationTexts[_textIndex % _conversationTexts.length];
          _showText = true;
          _textIndex++;
        });

        // Hide text after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showText = false;
            });
          }
        });
      }
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

  void _handleFakeEvent(FakeCallEvent event) {
    setState(() {
      _showingGesture = true;
    });

    _gestureController.forward().then((_) {
      _gestureController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showingGesture = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _gestureController.dispose();
    _eventTimer?.cancel();
    _textTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onControlsToggle,
      child: Stack(
        children: [
          // Video background
          Positioned.fill(
            child: _buildVideoBackground(),
          ),

          // Fake gesture overlay
          if (_showingGesture)
            Positioned.fill(
              child: _buildGestureOverlay(),
            ),

          // Conversation text overlay
          if (_showText)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: _buildConversationText(),
            ),

          // User info overlay
          if (widget.showControls)
            Positioned(
              bottom: 180,
              left: 16,
              child: _buildUserInfo(),
            ),

          // Loading overlay
          if (!_isVideoLoaded)
            Positioned.fill(
              child: _buildLoadingOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    if (!_isVideoLoaded) {
      return Container(
        color: Colors.grey.shade900,
        child: Center(
          child: LetterAvatar(
            name: widget.session.fakeVideo.user.name,
            size: 150,
            imageUrls: [widget.session.fakeVideo.thumbnailUrl],
            showBorder: false,
          ),
        ),
      );
    }

    // Since we can't actually play video from Google Drive URLs directly,
    // we'll create a simulated video effect using the thumbnail
    return AnimatedBuilder(
      animation: _videoController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background image with subtle animation
              Positioned.fill(
                child: Transform.scale(
                  scale: 1.0 + (_videoController.value * 0.02), // Subtle zoom effect
                  child: CachedNetworkImage(
                    imageUrl: widget.session.fakeVideo.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade800,
                      child: Center(
                        child: LetterAvatar(
                          name: widget.session.fakeVideo.user.name,
                          size: 100,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade800,
                      child: Center(
                        child: LetterAvatar(
                          name: widget.session.fakeVideo.user.name,
                          size: 100,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Subtle overlay to simulate video movement
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _videoController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            sin(_videoController.value * 2 * pi) * 0.1,
                            cos(_videoController.value * 2 * pi) * 0.1,
                          ),
                          radius: 1.5,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGestureOverlay() {
    return AnimatedBuilder(
      animation: _gestureAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: _gestureAnimation.value * 2,
              colors: [
                Colors.white.withOpacity(0.1 * _gestureAnimation.value),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Transform.scale(
              scale: 0.5 + (_gestureAnimation.value * 0.5),
              child: Icon(
                Icons.favorite,
                color: Colors.pink.withOpacity(_gestureAnimation.value),
                size: 60,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationText() {
    return AnimatedOpacity(
      opacity: _showText ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _currentText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LetterAvatar(
            name: widget.session.fakeVideo.user.name,
            size: 40,
            imageUrls: [widget.session.fakeVideo.thumbnailUrl],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.session.fakeVideo.user.name}, ${widget.session.fakeVideo.user.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.session.fakeVideo.user.location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 24),
            Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
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
}