// lib/screens/agora_one_on_one_call_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart' as app_models;
import '../services/agora_call_service.dart';
import '../widgets/components/letter_avatar.dart';

enum CallState {
  idle,
  searching,
  connecting,
  connected,
  disconnected,
  error
}

class AgoraOneOnOneCallScreen extends StatefulWidget {
  const AgoraOneOnOneCallScreen({Key? key}) : super(key: key);

  @override
  _AgoraOneOnOneCallScreenState createState() => _AgoraOneOnOneCallScreenState();
}

class _AgoraOneOnOneCallScreenState extends State<AgoraOneOnOneCallScreen>
    with TickerProviderStateMixin {
  // Services
  final AgoraCallService _agoraService = AgoraCallService();
  final CallQueueManager _queueManager = CallQueueManager();

  // State
  CallState _callState = CallState.idle;
  app_models.User? _matchedUser;
  String? _currentRoomId;
  Timer? _searchTimer;
  Timer? _matchingTimeout;
  int _callDuration = 0;
  Timer? _callTimer;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Search messages
  final List<String> _searchingMessages = [
    'Finding someone interesting...',
    'Connecting you with new people...',
    'Looking for the perfect match...',
    'Almost there...',
    'Searching worldwide...',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAgora();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeAgora() async {
    // Set up Agora callbacks
    _agoraService.onUserJoined = (uid) {
      print('Remote user joined: $uid');
      setState(() {
        _callState = CallState.connected;
      });
      _startCall();
    };

    _agoraService.onUserOffline = (uid, reason) {
      print('Remote user left: $uid, reason: $reason');
      setState(() {
        _callState = CallState.disconnected;
      });
      _endCall();
    };

    _agoraService.onError = (err, msg) {
      print('Agora error: $err - $msg');
      setState(() {
        _callState = CallState.error;
      });
    };

    // Initialize Agora engine
    bool initialized = await _agoraService.initialize();
    if (!initialized) {
      setState(() {
        _callState = CallState.error;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _searchTimer?.cancel();
    _callTimer?.cancel();
    _messageTimer?.cancel();
    _hideControlsTimer?.cancel();
    _matchingTimeout?.cancel();
    _queueManager.stopListening();
    _agoraService.removeFromQueue();
    _agoraService.dispose();
    super.dispose();
  }

  void _startSearching() {
    setState(() {
      _callState = CallState.searching;
      _matchedUser = null;
      _callDuration = 0;
    });

    // Start rotating messages
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _searchingMessages.length;
        });
      }
    });

    // Start listening for matches
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      _queueManager.startListening(currentUserId, (matchedUserId) async {
        // Found a match!
        await _handleMatch(matchedUserId);
      });
    }

    // Try to find a match
    _findMatch();

    // Set timeout for matching
    _matchingTimeout = Timer(const Duration(seconds: 30), () {
      if (_callState == CallState.searching) {
        setState(() {
          _callState = CallState.error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matches found. Try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _findMatch() async {
    try {
      // Find a random match using the service
      final matchedUser = await _agoraService.findRandomMatch();

      if (matchedUser != null && mounted) {
        await _handleMatch(matchedUser.id);
      }
    } catch (e) {
      print('Error finding match: $e');
      if (mounted) {
        setState(() {
          _callState = CallState.error;
        });
      }
    }
  }

  Future<void> _handleMatch(String matchedUserId) async {
    try {
      _matchingTimeout?.cancel();

      setState(() {
        _callState = CallState.connecting;
      });

      // Get matched user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(matchedUserId)
          .get();

      if (!userDoc.exists) return;

      final matchedUser = app_models.User.fromFirestore(userDoc);

      // Create or join call room
      String? roomId = await _agoraService.createCallRoom(matchedUserId);
      if (roomId == null) {
        // Try to join existing room
        roomId = '${matchedUserId}_${FirebaseAuth.instance.currentUser?.uid}_call';
        await _agoraService.joinCallRoom(roomId);
      }

      _currentRoomId = roomId;

      // Join Agora channel
      bool joined = await _agoraService.joinChannel(roomId);

      if (joined && mounted) {
        setState(() {
          _matchedUser = matchedUser;
          _callState = CallState.connected;
        });

        _slideController.forward();
        _startCall();
      } else {
        setState(() {
          _callState = CallState.error;
        });
      }
    } catch (e) {
      print('Error handling match: $e');
      setState(() {
        _callState = CallState.error;
      });
    }
  }

  void _startCall() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });

    // Auto-hide controls after 3 seconds
    _resetHideControlsTimer();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _endCall() async {
    _searchTimer?.cancel();
    _callTimer?.cancel();
    _messageTimer?.cancel();
    _hideControlsTimer?.cancel();
    _matchingTimeout?.cancel();

    // Leave Agora channel
    await _agoraService.leaveChannel();

    // End call room
    if (_currentRoomId != null) {
      await _agoraService.endCallRoom(_currentRoomId!);
    }

    // Remove from queue
    await _agoraService.removeFromQueue();

    setState(() {
      _callState = CallState.idle;
      _matchedUser = null;
      _callDuration = 0;
      _showControls = true;
      _currentRoomId = null;
    });
  }

  void _skipToNext() async {
    await _endCall();
    _startSearching();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey.shade900,
      body: Stack(
        children: [
          // Main content
          _buildMainContent(),

          // Controls overlay
          if (_callState == CallState.connected && _showControls)
            _buildCallControls(),

          // Top bar
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_callState) {
      case CallState.idle:
        return _buildIdleState();
      case CallState.searching:
        return _buildSearchingState();
      case CallState.connecting:
        return _buildConnectingState();
      case CallState.connected:
        return _buildConnectedState();
      case CallState.error:
        return _buildErrorState();
      case CallState.disconnected:
        return _buildDisconnectedState();
    }
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.video_camera_front,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Meet New People',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start a random video call with someone new',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 60),
          // Start button
          GestureDetector(
            onTap: _startSearching,
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Start Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated circles
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer circle
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 200 * _pulseAnimation.value,
                      height: 200 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                // Middle circle
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 150 * _pulseAnimation.value,
                      height: 150 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                // Center icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Animated text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _searchingMessages[_currentMessageIndex],
              key: ValueKey(_currentMessageIndex),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 60),
          // Cancel button
          TextButton(
            onPressed: () async {
              await _agoraService.removeFromQueue();
              _queueManager.stopListening();
              await _endCall();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connecting...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Found someone! Setting up the call...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedState() {
    if (_matchedUser == null) return Container();

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
        if (_showControls) {
          _resetHideControlsTimer();
        }
      },
      child: Stack(
        children: [
          // Remote user video
          Positioned.fill(
            child: _agoraService.remoteUid != null
                ? _agoraService.createRemoteVideoView(_agoraService.remoteUid!)
                : Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LetterAvatar(
                      name: _matchedUser!.name,
                      size: 150,
                      imageUrls: _matchedUser!.imageUrls,
                      showBorder: false,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Waiting for ${_matchedUser!.name} to turn on camera...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Blur effect when camera is off
          if (_agoraService.isVideoDisabled)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 60,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your camera is off',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Local user video (small preview in corner)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _agoraService.createLocalVideoView(),
                ),
              ),
            ),
          ),

          // User info overlay
          if (_showControls)
            Positioned(
              bottom: 120,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    LetterAvatar(
                      name: _matchedUser!.name,
                      size: 40,
                      imageUrls: _matchedUser!.imageUrls,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_matchedUser!.name}, ${_matchedUser!.age}',
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
                              _matchedUser!.location,
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'Connection Failed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to connect. Please try again.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _startSearching,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_end,
            size: 80,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 24),
          const Text(
            'Call Ended',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The call has been disconnected',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _startSearching,
                icon: const Icon(Icons.search),
                label: const Text('Find New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => setState(() => _callState = CallState.idle),
                child: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Call duration
            if (_callState == CallState.connected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox.shrink(),

            // Status
            if (_callState == CallState.searching)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Searching',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Settings
            if (_callState == CallState.idle)
              IconButton(
                onPressed: () {
                  // Show settings or filters
                  _showCallSettings();
                },
                icon: const Icon(
                  Icons.tune,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
              onPressed: () async {
                await _agoraService.toggleMute();
                setState(() {});
              },
              isActive: !_agoraService.isMuted,
            ),

            // Camera toggle
            _buildControlButton(
              icon: _agoraService.isVideoDisabled ? Icons.videocam_off : Icons.videocam,
              onPressed: () async {
                await _agoraService.toggleVideo();
                setState(() {});
              },
              isActive: !_agoraService.isVideoDisabled,
            ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              onPressed: () async {
                setState(() => _callState = CallState.disconnected);
                await _endCall();
              },
              isEndCall: true,
            ),

            // Switch camera
            _buildControlButton(
              icon: Icons.cameraswitch,
              onPressed: () async {
                await _agoraService.switchCamera();
              },
              isActive: true,
            ),

            // Next button
            _buildControlButton(
              icon: Icons.skip_next,
              onPressed: _skipToNext,
              isActive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = true,
    bool isEndCall = false,
  }) {
    return GestureDetector(
      onTap: () {
        onPressed();
        _resetHideControlsTimer();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEndCall
              ? Colors.red
              : isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isEndCall
                ? Colors.red
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showCallSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Call Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Match by location'),
              subtitle: const Text('Find people nearby'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // Implement location-based matching
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language preferences'),
              subtitle: const Text('Match by common languages'),
              onTap: () {
                // Show language selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Blocked users'),
              subtitle: const Text('Manage blocked list'),
              onTap: () {
                // Show blocked users
              },
            ),
          ],
        ),
      ),
    );
  }
}