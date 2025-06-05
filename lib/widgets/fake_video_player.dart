// lib/widgets/fake_video_player.dart - Updated to actually play videos
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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

  // Video Player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  String? _videoErrorMessage;
  bool _isVideoLoading = true;

  // Animation controllers
  late AnimationController _gestureController;
  late Animation<double> _gestureAnimation;

  // Timers and subscriptions
  Timer? _eventTimer;
  Timer? _textTimer;
  StreamSubscription? _eventSubscription;

  // State
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
    _initializeVideo(); // Initialize actual video player
    _startEventSubscription();
  }

  void _initializeAnimations() {
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

  // NEW: Initialize actual video player
  Future<void> _initializeVideo() async {
    try {
      final videoUrl = widget.session.fakeVideo.videoUrl;
      print('🎥 Initializing fake video: $videoUrl');

      // Create video controller based on URL type
      if (videoUrl.startsWith('assets/')) {
        _videoController = VideoPlayerController.asset(videoUrl);
      } else {
        _videoController = VideoPlayerController.network(videoUrl);
      }

      // Add error listener
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

      // Initialize the controller
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoLoading = false;
          _hasVideoError = false;
        });

        // Start playing automatically
        _videoController!.play();
        _videoController!.setLooping(true);

        print('✅ Fake video initialized and playing');

        // Start conversation texts after video loads
        _startConversationTexts();
      }
    } catch (e) {
      print('❌ Error initializing fake video: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _videoErrorMessage = e.toString();
          _isVideoLoading = false;
        });

        // Still start conversation texts even if video fails
        _startConversationTexts();
      }
    }
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
    _gestureController.dispose();
    _videoController?.dispose(); // Dispose video controller
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
          // Video background - NOW WITH REAL VIDEO
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
          if (_isVideoLoading)
            Positioned.fill(
              child: _buildLoadingOverlay(),
            ),

          // Video controls (optional)
          //    if (widget.showControls && _isVideoInitialized && !_hasVideoError)
            //     Positioned(
            //      bottom: 100,
            //     right: 20,
            //     child: _buildVideoControls(),
          //  ),
        ],
      ),
    );
  }

  // UPDATED: Now uses real video player
  Widget _buildVideoBackground() {
    // If video is working, show it
    if (_isVideoInitialized && !_hasVideoError && _videoController != null) {
      return VideoPlayer(_videoController!);
    }

    // If video failed or loading, show fallback
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: Colors.grey.shade900,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
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

          // Error overlay if video failed
          if (_hasVideoError)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_off,
                      size: 64,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Video unavailable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Showing profile photo instead',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (_videoErrorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Error: ${_videoErrorMessage!.length > 60 ? _videoErrorMessage!.substring(0, 60) + "..." : _videoErrorMessage!}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isVideoLoading = true;
                          _hasVideoError = false;
                          _videoErrorMessage = null;
                        });
                        _initializeVideo();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry Video'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Video controls
  Widget _buildVideoControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
              setState(() {});
            },
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              _videoController!.seekTo(Duration.zero);
              _videoController!.play();
            },
            icon: const Icon(
              Icons.replay,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
              'Loading...',
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