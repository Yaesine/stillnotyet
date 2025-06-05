// lib/screens/enhanced_agora_call_screen.dart - Instagram-style professional video call UI
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart' as app_models;
import '../services/agora_call_service.dart';
import '../services/fake_video_call_service.dart';
import '../widgets/components/letter_avatar.dart';
import '../widgets/permission_handler_dialog.dart';
import '../widgets/fake_video_player.dart';

enum CallState {
  idle,
  searching,
  connecting,
  connected,
  fakeCall,
  disconnected,
  error
}

class EnhancedAgoraCallScreen extends StatefulWidget {
  final bool isFullScreen;

  const EnhancedAgoraCallScreen({
    Key? key,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  _EnhancedAgoraCallScreenState createState() => _EnhancedAgoraCallScreenState();
}

class _EnhancedAgoraCallScreenState extends State<EnhancedAgoraCallScreen>
    with TickerProviderStateMixin {
  // Core services and state
  final AgoraCallService _agoraService = AgoraCallService();
  final CallQueueManager _queueManager = CallQueueManager();
  final FakeVideoCallService _fakeVideoService = FakeVideoCallService();

  // Call state
  CallState _callState = CallState.idle;
  app_models.User? _matchedUser;
  String? _currentRoomId;
  FakeCallSession? _fakeCallSession;
  Timer? _searchTimer;
  Timer? _matchingTimeout;
  Timer? _fakeCallTimer;
  int _callDuration = 0;
  Timer? _callTimer;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isFakeCall = false;
  bool _fakeCallCameraEnabled = true;
  bool _fakeCallMicEnabled = true;

  // Animation controllers for Instagram-like effects
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rippleController;

  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  // UI state
  bool _isMinimized = false;
  bool _showParticipantInfo = false;
  Timer? _infoTimer;

  // Search configuration
  final List<String> _searchingMessages = [
    'Finding someone amazing...',
    'Connecting you with new people...',
    'Looking for your next conversation...',
    'Searching worldwide...',
    'Almost ready...',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissionsAndInitialize();

    if (widget.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Dispose all animation controllers
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _rippleController.dispose();

    // Cancel all timers
    _searchTimer?.cancel();
    _callTimer?.cancel();
    _messageTimer?.cancel();
    _hideControlsTimer?.cancel();
    _matchingTimeout?.cancel();
    _fakeCallTimer?.cancel();
    _infoTimer?.cancel();

    // Cleanup services
    _queueManager.stopListening();
    _agoraService.removeFromQueue();
    _agoraService.dispose();

    if (_fakeCallSession != null) {
      _fakeVideoService.endFakeCallSession(_fakeCallSession!.sessionId);
    }

    super.dispose();
  }

  void _initializeAnimations() {
    // Pulse animation for search state
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Slide animation for UI elements
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Fade animation for overlays
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Scale animation for buttons
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Ripple animation for connection state
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize animations
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    if (cameraStatus == PermissionStatus.granted &&
        micStatus == PermissionStatus.granted) {
      await _initializeAgora();
    }
  }

  Future<void> _initializeAgora() async {
    _agoraService.onUserJoined = (uid) {
      print('Remote user joined: $uid');
      setState(() {
        _callState = CallState.connected;
        _isFakeCall = false;
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

    bool initialized = await _agoraService.initialize();
    if (!initialized) {
      print('Failed to initialize Agora');
    }
  }

  void _startSearching() async {
    bool hasPermissions = await PermissionHandlerDialog.checkAndRequestPermissions(context);
    if (!hasPermissions) {
      _showPermissionSnackbar();
      return;
    }

    if (!widget.isFullScreen) {
      _navigateToFullscreen();
      return;
    }

    setState(() {
      _callState = CallState.searching;
      _matchedUser = null;
      _callDuration = 0;
      _isFakeCall = false;
    });

    _rippleController.repeat();
    _startSearchMessages();

    print('🔍 Starting search for real users...');
    bool foundRealUser = await _findRealMatchWithTimeout();

    if (!foundRealUser && _callState == CallState.searching && mounted) {
      print('📹 No real users found, starting fake video call...');
      await _startFakeVideoCall();
    }
  }

  void _showPermissionSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Camera and microphone permissions are required for video calls',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const EnhancedAgoraCallScreen(isFullScreen: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
      ),
    ).then((_) {
      setState(() {
        _callState = CallState.idle;
        _matchedUser = null;
        _callDuration = 0;
        _showControls = true;
        _currentRoomId = null;
        _isFakeCall = false;
      });
    });
  }

  void _startSearchMessages() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _callState == CallState.searching) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _searchingMessages.length;
        });
      }
    });
  }

  Future<bool> _findRealMatchWithTimeout() async {
    if (!_agoraService.isInitialized) {
      bool initialized = await _agoraService.initialize();
      if (!initialized) {
        setState(() => _callState = CallState.error);
        return false;
      }
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    _queueManager.startListening(currentUserId, (matchedUserId) async {
      if (_callState == CallState.searching) {
        await _handleRealMatch(matchedUserId);
      }
    });

    try {
      await FirebaseFirestore.instance.collection('call_queue').doc(currentUserId).set({
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'waiting',
      });

      final timeout = DateTime.now().add(const Duration(seconds: 10));
      int attempts = 0;
      const maxAttempts = 3;

      while (DateTime.now().isBefore(timeout) &&
          _callState == CallState.searching &&
          attempts < maxAttempts) {
        attempts++;

        final matchedUser = await _agoraService.findRandomMatch();
        if (matchedUser != null && mounted && _callState == CallState.searching) {
          await _handleRealMatch(matchedUser.id);
          return true;
        }

        if (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      if (_callState == CallState.searching) {
        await FirebaseFirestore.instance.collection('call_queue').doc(currentUserId).delete();
      }

      return false;
    } catch (e) {
      print('❌ Error finding real match: $e');
      try {
        await FirebaseFirestore.instance.collection('call_queue').doc(currentUserId).delete();
      } catch (_) {}
      return false;
    }
  }

  Future<void> _startFakeVideoCall() async {
    try {
      _matchingTimeout?.cancel();
      _messageTimer?.cancel();
      _rippleController.stop();

      setState(() => _callState = CallState.connecting);

      if (!_agoraService.isInitialized) {
        bool initialized = await _agoraService.initialize();
        if (!initialized) {
          print('⚠️ Warning: Agora not initialized for fake call camera');
        }
      }

      if (_agoraService.isInitialized) {
        String dummyChannel = 'fake_call_${DateTime.now().millisecondsSinceEpoch}';
        await _agoraService.joinChannel(dummyChannel);

        if (_agoraService.isVideoDisabled) {
          await _agoraService.toggleVideo();
        }
      }

      await Future.delayed(const Duration(seconds: 2));

      final session = await _fakeVideoService.startFakeVideoCall();
      if (session == null) {
        setState(() => _callState = CallState.error);
        return;
      }

      final fakeUser = app_models.User(
        id: session.sessionId,
        name: session.fakeVideo.user.name,
        age: session.fakeVideo.user.age,
        bio: 'Love ${session.fakeVideo.user.interests.join(", ")}',
        imageUrls: [session.fakeVideo.thumbnailUrl],
        interests: session.fakeVideo.user.interests,
        location: session.fakeVideo.user.location,
      );

      setState(() {
        _fakeCallSession = session;
        _matchedUser = fakeUser;
        _callState = CallState.fakeCall;
        _isFakeCall = true;
        _fakeCallCameraEnabled = true;
        _fakeCallMicEnabled = true;
      });

      _slideController.forward();
      _startCall();

      _fakeCallTimer = Timer(session.fakeVideo.duration, () {
        if (_callState == CallState.fakeCall) {
          _endCall();
        }
      });
    } catch (e) {
      print('Error starting fake video call: $e');
      setState(() => _callState = CallState.error);
    }
  }

  Future<void> _handleRealMatch(String matchedUserId) async {
    try {
      _matchingTimeout?.cancel();
      _rippleController.stop();

      setState(() => _callState = CallState.connecting);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(matchedUserId)
          .get();

      if (!userDoc.exists) return;

      final matchedUser = app_models.User.fromFirestore(userDoc);

      String? roomId = await _agoraService.createCallRoom(matchedUserId);
      if (roomId == null) {
        roomId = '${matchedUserId}_${FirebaseAuth.instance.currentUser?.uid}_call';
        await _agoraService.joinCallRoom(roomId);
      }

      _currentRoomId = roomId;
      bool joined = await _agoraService.joinChannel(roomId);

      if (joined && mounted) {
        setState(() {
          _matchedUser = matchedUser;
          _callState = CallState.connected;
          _isFakeCall = false;
        });

        _slideController.forward();
        _startCall();
      } else {
        setState(() => _callState = CallState.error);
      }
    } catch (e) {
      print('Error handling real match: $e');
      setState(() => _callState = CallState.error);
    }
  }

  void _startCall() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration++);
      }
    });

    _resetHideControlsTimer();
    _showParticipantInfoBriefly();
  }

  void _showParticipantInfoBriefly() {
    setState(() => _showParticipantInfo = true);
    _infoTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showParticipantInfo = false);
      }
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _endCall() async {
    _searchTimer?.cancel();
    _callTimer?.cancel();
    _messageTimer?.cancel();
    _hideControlsTimer?.cancel();
    _matchingTimeout?.cancel();
    _fakeCallTimer?.cancel();
    _infoTimer?.cancel();
    _rippleController.stop();

    if (_fakeCallSession != null) {
      await _fakeVideoService.endFakeCallSession(_fakeCallSession!.sessionId);
      _fakeCallSession = null;
    }

    if (_agoraService.isInitialized) {
      await _agoraService.leaveChannel();
    }

    if (!_isFakeCall && _currentRoomId != null) {
      await _agoraService.endCallRoom(_currentRoomId!);
    }

    await _agoraService.removeFromQueue();

    setState(() {
      _callState = CallState.idle;
      _matchedUser = null;
      _callDuration = 0;
      _showControls = true;
      _currentRoomId = null;
      _isFakeCall = false;
      _fakeCallCameraEnabled = true;
      _fakeCallMicEnabled = true;
      _showParticipantInfo = false;
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
    if (widget.isFullScreen) {
      return _buildFullscreenCall();
    }

    return _buildEmbeddedCall();
  }

  Widget _buildFullscreenCall() {
    return WillPopScope(
      onWillPop: () async {
        if (_callState == CallState.connected || _callState == CallState.fakeCall) {
          return await _showEndCallDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildMainContent(),
            _buildTopOverlay(),
            if (_showControls) _buildBottomControls(),
            if (_showParticipantInfo) _buildParticipantInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedCall() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey.shade900,
      body: Stack(
        children: [
          _buildMainContent(),
          _buildTopOverlay(),
          if (_showControls) _buildBottomControls(),
          if (_showParticipantInfo) _buildParticipantInfo(),
          if (_callState != CallState.idle) _buildFullscreenButton(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) {
          _resetHideControlsTimer();
        }
      },
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _getContentForState(),
          );
        },
      ),
    );
  }

  Widget _getContentForState() {
    switch (_callState) {
      case CallState.idle:
        return _buildIdleState();
      case CallState.searching:
        return _buildSearchingState();
      case CallState.connecting:
        return _buildConnectingState();
      case CallState.connected:
        return _buildConnectedState();
      case CallState.fakeCall:
        return _buildFakeCallState();
      case CallState.error:
        return _buildErrorState();
      case CallState.disconnected:
        return _buildDisconnectedState();
    }
  }

  Widget _buildIdleState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedCallIcon(),
            const SizedBox(height: 40),
            _buildWelcomeText(),
            const SizedBox(height: 60),
            _buildPermissionStatus(),
            const SizedBox(height: 40),
            _buildStartCallButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCallIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                  Colors.purple.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.video_camera_front_rounded,
              size: 70,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: const Text(
            'Meet New People',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Connect with amazing people from around the world through video calls',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionStatus() {
    return FutureBuilder<Map<Permission, PermissionStatus>>(
      future: Future.wait([
        Permission.camera.status,
        Permission.microphone.status,
      ]).then((statuses) => {
        Permission.camera: statuses[0],
        Permission.microphone: statuses[1],
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final statuses = snapshot.data!;
          final cameraGranted = statuses[Permission.camera] == PermissionStatus.granted;
          final micGranted = statuses[Permission.microphone] == PermissionStatus.granted;

          if (!cameraGranted || !micGranted) {
            return _buildPermissionWarning();
          }

          return _buildPermissionSuccess();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPermissionWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade400,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Permissions Required',
            style: TextStyle(
              color: Colors.orange.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please allow camera and microphone access to start video calls',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSuccess() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.teal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Ready to start calling',
            style: TextStyle(
              color: Colors.green.shade400,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartCallButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: _startSearching,
            child: Container(
              width: 220,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                    Colors.purple.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Start Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade900,
            Colors.purple.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSearchAnimation(),
            const SizedBox(height: 60),
            _buildSearchText(),
            const SizedBox(height: 80),
            _buildCancelSearchButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAnimation() {
    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple
              Container(
                width: 280 * _rippleAnimation.value,
                height: 280 * _rippleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3 * (1 - _rippleAnimation.value)),
                    width: 2,
                  ),
                ),
              ),
              // Middle ripple
              Container(
                width: 200 * _rippleAnimation.value,
                height: 200 * _rippleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.5 * (1 - _rippleAnimation.value)),
                    width: 3,
                  ),
                ),
              ),
              // Inner ripple
              Container(
                width: 120 * _rippleAnimation.value,
                height: 120 * _rippleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.7 * (1 - _rippleAnimation.value)),
                    width: 4,
                  ),
                ),
              ),
              // Center icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchText() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _searchingMessages[_currentMessageIndex],
            key: ValueKey(_currentMessageIndex),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Searching worldwide...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelSearchButton() {
    return GestureDetector(
      onTap: () async {
        await _agoraService.removeFromQueue();
        _queueManager.stopListening();
        await _endCall();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade900,
            Colors.teal.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.teal.shade400],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Found someone amazing! Setting up the call...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedState() {
    if (_matchedUser == null) return Container();

    return Stack(
      children: [
        // Main video view
        Positioned.fill(
          child: _agoraService.remoteUid != null
              ? _agoraService.createRemoteVideoView(_agoraService.remoteUid!)
              : _buildVideoPlaceholder(),
        ),

        // Video disabled overlay
        if (_agoraService.isVideoDisabled)
          Positioned.fill(
            child: _buildVideoDisabledOverlay(),
          ),

        // Local video preview (Instagram-style)
        _buildLocalVideoPreview(),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LetterAvatar(
              name: _matchedUser!.name,
              size: 120,
              imageUrls: _matchedUser!.imageUrls,
              showBorder: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Waiting for ${_matchedUser!.name}...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask them to turn on their camera',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDisabledOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off_rounded,
                size: 80,
                color: Colors.white70,
              ),
              SizedBox(height: 20),
              Text(
                'Your camera is off',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the camera button to turn it on',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalVideoPreview() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + (widget.isFullScreen ? 20 : 80),
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _fakeCallCameraEnabled || !_isFakeCall
                ? _agoraService.createLocalVideoView()
                : _buildCameraOffIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOffIndicator() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(
          Icons.videocam_off_rounded,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildFakeCallState() {
    if (_fakeCallSession == null) return Container();

    return Stack(
      children: [
        // Main fake video
        FakeVideoPlayer(
          session: _fakeCallSession!,
          onCallEnd: _endCall,
          showControls: _showControls,
          onControlsToggle: () {
            setState(() => _showControls = !_showControls);
            if (_showControls) {
              _resetHideControlsTimer();
            }
          },
        ),

        // Local camera preview overlay
        _buildLocalVideoPreview(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade400.withOpacity(0.2),
                border: Border.all(
                  color: Colors.red.shade400,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 32),
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
              'Unable to connect. Please check your internet and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Try Again',
                  onPressed: _startSearching,
                  isPrimary: true,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.home_rounded,
                  label: 'Back',
                  onPressed: () => setState(() => _callState = CallState.idle),
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedState() {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade600.withOpacity(0.2),
                border: Border.all(
                  color: Colors.grey.shade600,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.call_end_rounded,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
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
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.search_rounded,
                  label: 'Find New',
                  onPressed: _startSearching,
                  isPrimary: true,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.home_rounded,
                  label: 'Back',
                  onPressed: () => setState(() => _callState = CallState.idle),
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBackButton(),
            _buildCallStatusBadge(),
            _buildTopActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    if (!widget.isFullScreen) return const SizedBox(width: 40);

    return GestureDetector(
      onTap: () async {
        if (_callState == CallState.connected || _callState == CallState.fakeCall) {
          bool shouldLeave = await _showEndCallDialog();
          if (shouldLeave) {
            await _endCall();
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCallStatusBadge() {
    if (_callState != CallState.connected && _callState != CallState.fakeCall) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isFakeCall
            ? Colors.orange.withOpacity(0.9)
            : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_callDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButton() {
    if (_callState == CallState.searching) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(width: 40);
  }

  Widget _buildBottomControls() {
    if (_callState != CallState.connected && _callState != CallState.fakeCall) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 24,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: _isFakeCall
                  ? (_fakeCallMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded)
                  : (_agoraService.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
              onPressed: _isFakeCall ? _toggleFakeMic : _toggleMic,
              isActive: _isFakeCall ? _fakeCallMicEnabled : !_agoraService.isMuted,
            ),
            _buildControlButton(
              icon: _isFakeCall
                  ? (_fakeCallCameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded)
                  : (_agoraService.isVideoDisabled ? Icons.videocam_off_rounded : Icons.videocam_rounded),
              onPressed: _isFakeCall ? _toggleFakeCamera : _toggleCamera,
              isActive: _isFakeCall ? _fakeCallCameraEnabled : !_agoraService.isVideoDisabled,
            ),
            _buildControlButton(
              icon: Icons.call_end_rounded,
              onPressed: _endCallWithConfirmation,
              isEndCall: true,
            ),
            _buildControlButton(
              icon: Icons.cameraswitch_rounded,
              onPressed: _switchCamera,
              isActive: true,
            ),
            _buildControlButton(
              icon: Icons.skip_next_rounded,
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
        HapticFeedback.lightImpact();
        onPressed();
        _resetHideControlsTimer();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isEndCall
              ? LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade800],
          )
              : isActive
              ? LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
          )
              : null,
          color: isEndCall || isActive ? null : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isEndCall
                ? Colors.red.shade400
                : isActive
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    if (_matchedUser == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 160,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
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
              ),
              child: Row(
                children: [
                  LetterAvatar(
                    name: _matchedUser!.name,
                    size: 50,
                    imageUrls: _matchedUser!.imageUrls,
                    showBorder: true,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_matchedUser!.name}, ${_matchedUser!.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _matchedUser!.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isFakeCall)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullscreenButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: GestureDetector(
        onTap: _navigateToFullscreen,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
          ),
          child: const Icon(
            Icons.fullscreen_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Future<bool> _showEndCallDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Call?'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );

    return result ?? false;
  }


  // Control button action methods
  void _toggleFakeMic() {
    setState(() {
      _fakeCallMicEnabled = !_fakeCallMicEnabled;
    });
    if (_agoraService.isInitialized) {
      _agoraService.toggleMute();
    }
  }

  void _toggleFakeCamera() async {
    setState(() {
      _fakeCallCameraEnabled = !_fakeCallCameraEnabled;
    });
    if (_agoraService.isInitialized) {
      await _agoraService.toggleVideo();
    }
  }

  Future<void> _toggleMic() async {
    await _agoraService.toggleMute();
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    await _agoraService.toggleVideo();
    setState(() {});
  }

  Future<void> _switchCamera() async {
    await _agoraService.switchCamera();
  }

  void _endCallWithConfirmation() async {
    if (widget.isFullScreen) {
      bool shouldEnd = await _showEndCallDialog();
      if (shouldEnd) {
        await _endCall();
        Navigator.of(context).pop();
      }
    } else {
      await _endCall();
    }
  }
}