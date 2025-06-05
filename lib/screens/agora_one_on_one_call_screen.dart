// lib/screens/agora_one_on_one_call_screen.dart - Complete implementation with fake video integration
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

class AgoraOneOnOneCallScreen extends StatefulWidget {
  final bool isFullScreen;


  const AgoraOneOnOneCallScreen({
    Key? key,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  _AgoraOneOnOneCallScreenState createState() => _AgoraOneOnOneCallScreenState();
}

class _AgoraOneOnOneCallScreenState extends State<AgoraOneOnOneCallScreen>
    with TickerProviderStateMixin {
  bool _fakeCallCameraEnabled = true;
  bool _fakeCallMicEnabled = true;
  // Services
  final AgoraCallService _agoraService = AgoraCallService();
  final CallQueueManager _queueManager = CallQueueManager();
  final FakeVideoCallService _fakeVideoService = FakeVideoCallService();

  // State management
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

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Search configuration
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
    _checkPermissionsAndInitialize();
    _ensurePermissionsInSettings();

    if (widget.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Dispose animation controllers
    _pulseController.dispose();
    _slideController.dispose();

    // Cancel all timers
    _searchTimer?.cancel();
    _callTimer?.cancel();
    _messageTimer?.cancel();
    _hideControlsTimer?.cancel();
    _matchingTimeout?.cancel();
    _fakeCallTimer?.cancel();

    // Cleanup services
    _queueManager.stopListening();
    _agoraService.removeFromQueue();
    _agoraService.dispose();

    // End fake call session if active
    if (_fakeCallSession != null) {
      _fakeVideoService.endFakeCallSession(_fakeCallSession!.sessionId);
    }

    super.dispose();
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

  Future<void> _checkPermissionsAndInitialize() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    if (cameraStatus == PermissionStatus.granted &&
        micStatus == PermissionStatus.granted) {
      await _initializeAgora();
    }
  }

  Future<void> _ensurePermissionsInSettings() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    if (cameraStatus == PermissionStatus.denied && micStatus == PermissionStatus.denied) {
      await Permission.camera.status;
      await Permission.microphone.status;
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

// Update your _startSearching() method in AgoraOneOnOneCallScreen

// Replace the _startSearching method in AgoraOneOnOneCallScreen with this fixed version:

  void _startSearching() async {
    bool hasPermissions = await PermissionHandlerDialog.checkAndRequestPermissions(context);
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and microphone permissions are required for video calls'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // AUTO FULLSCREEN: Check if we're not already in fullscreen mode
    if (!widget.isFullScreen) {
      // Navigate to fullscreen version and start the call there
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AgoraOneOnOneCallScreen(isFullScreen: true),
          fullscreenDialog: true,
        ),
      ).then((_) {
        // When user returns from fullscreen, reset the state
        setState(() {
          _callState = CallState.idle;
          _matchedUser = null;
          _callDuration = 0;
          _showControls = true;
          _currentRoomId = null;
          _isFakeCall = false;
        });
      });

      return; // Exit here, the fullscreen version will handle the rest
    }

    // If we're already in fullscreen mode, proceed with normal search logic
    setState(() {
      _callState = CallState.searching;
      _matchedUser = null;
      _callDuration = 0;
      _isFakeCall = false;
    });

    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _searchingMessages.length;
        });
      }
    });

    // FIXED: Always try to find real users first
    print('🔍 Starting search for real users...');

    // Start finding real match
    bool foundRealUser = await _findRealMatchWithTimeout();

    // If no real user found and still searching, start fake video
    if (!foundRealUser && _callState == CallState.searching && mounted) {
      print('📹 No real users found, starting fake video call...');
      await _startFakeVideoCall();
    }
  }

// Add this new method to handle the real user search with proper timeout:
  // Replace the _findRealMatchWithTimeout method in AgoraOneOnOneCallScreen:

  Future<bool> _findRealMatchWithTimeout() async {
    if (!_agoraService.isInitialized) {
      bool initialized = await _agoraService.initialize();
      if (!initialized) {
        setState(() {
          _callState = CallState.error;
        });
        return false;
      }
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    // Start listening for matches in the queue
    _queueManager.startListening(currentUserId, (matchedUserId) async {
      if (_callState == CallState.searching) {
        await _handleRealMatch(matchedUserId);
      }
    });

    try {
      // Add current user to the queue
      print('📝 Adding user to call queue...');
      await FirebaseFirestore.instance.collection('call_queue').doc(currentUserId).set({
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'waiting',
      });

      // REDUCED: Only search for 10 seconds (was 20)
      final timeout = DateTime.now().add(const Duration(seconds: 10));

      // REDUCED: Only make 3 attempts
      int attempts = 0;
      const maxAttempts = 3;

      while (DateTime.now().isBefore(timeout) &&
          _callState == CallState.searching &&
          attempts < maxAttempts) {

        attempts++;
        print('🔄 Search attempt $attempts of $maxAttempts for real users...');

        final matchedUser = await _agoraService.findRandomMatch();
        if (matchedUser != null && mounted && _callState == CallState.searching) {
          print('✅ Found real user match!');
          await _handleRealMatch(matchedUser.id);
          return true; // Found a real user
        }

        // Only wait if we haven't reached max attempts
        if (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      print('⏱️ Completed $attempts attempts - no real users found');

      // Remove from queue if still searching
      if (_callState == CallState.searching) {
        await FirebaseFirestore.instance.collection('call_queue').doc(currentUserId).delete();
      }

      return false; // No real user found

    } catch (e) {
      print('❌ Error finding real match: $e');
      // Clean up on error
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

      setState(() {
        _callState = CallState.connecting;
      });

      // IMPORTANT: Initialize Agora for local camera even in fake calls
      if (!_agoraService.isInitialized) {
        print('📹 Initializing Agora for fake call camera...');
        bool initialized = await _agoraService.initialize();
        if (!initialized) {
          print('⚠️ Warning: Agora not initialized for fake call camera');
        }
      }

      // Join a dummy channel for local camera to work
      if (_agoraService.isInitialized) {
        print('📹 Joining dummy channel for camera preview...');
        String dummyChannel = 'fake_call_${DateTime.now().millisecondsSinceEpoch}';
        await _agoraService.joinChannel(dummyChannel);

        // Ensure camera is enabled
        if (_agoraService.isVideoDisabled) {
          await _agoraService.toggleVideo();
        }
      }

      await Future.delayed(const Duration(seconds: 2));

      final session = await _fakeVideoService.startFakeVideoCall();
      if (session == null) {
        setState(() {
          _callState = CallState.error;
        });
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
        _fakeCallCameraEnabled = true; // Start with camera enabled
        _fakeCallMicEnabled = true;    // Start with mic enabled
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
      setState(() {
        _callState = CallState.error;
      });
    }
  }
  Future<void> _findRealMatch() async {
    if (!_agoraService.isInitialized) {
      bool initialized = await _agoraService.initialize();
      if (!initialized) {
        setState(() {
          _callState = CallState.error;
        });
        return;
      }
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      // Start listening for matches in the queue
      _queueManager.startListening(currentUserId, (matchedUserId) async {
        await _handleRealMatch(matchedUserId);
      });

      // Add current user to the queue
      print('📝 Adding user to call queue...');
      await FirebaseFirestore.instance.collection('call_queue').doc(currentUserId).set({
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'waiting',
      });
    }

    try {
      // Try multiple times to find a match
      for (int attempt = 0; attempt < 3; attempt++) {
        if (_callState != CallState.searching) break;

        print('🔄 Attempt ${attempt + 1} to find real users...');

        final matchedUser = await _agoraService.findRandomMatch();
        if (matchedUser != null && mounted && _callState == CallState.searching) {
          print('✅ Found real user match!');
          await _handleRealMatch(matchedUser.id);
          return;
        }

        // Wait a bit before trying again
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 5));
        }
      }

      print('❌ No real users found after multiple attempts');
    } catch (e) {
      print('❌ Error finding real match: $e');
    }
  }

  Future<void> _handleRealMatch(String matchedUserId) async {
    try {
      _matchingTimeout?.cancel();

      setState(() {
        _callState = CallState.connecting;
      });

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
        setState(() {
          _callState = CallState.error;
        });
      }
    } catch (e) {
      print('Error handling real match: $e');
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
    _fakeCallTimer?.cancel();

    if (_fakeCallSession != null) {
      await _fakeVideoService.endFakeCallSession(_fakeCallSession!.sessionId);
      _fakeCallSession = null;
    }

    // Always leave channel and cleanup Agora, even for fake calls
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

  Widget _buildOpenFullscreenButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.fullscreen,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AgoraOneOnOneCallScreen(isFullScreen: true),
                fullscreenDialog: true,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (widget.isFullScreen) {
      return WillPopScope(
        onWillPop: () async {
          if (_callState == CallState.connected || _callState == CallState.fakeCall) {
            final shouldLeave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('End Call?'),
                content: const Text('Are you sure you want to end this call?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('End Call'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            );

            if (shouldLeave ?? false) {
              await _endCall();
              return true;
            }
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _buildMainContent(),
              if ((_callState == CallState.connected || _callState == CallState.fakeCall) && _showControls)
                _buildCallControls(),
              _buildTopBar(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey.shade900,
      body: Stack(
        children: [
          _buildMainContent(),
          if ((_callState == CallState.connected || _callState == CallState.fakeCall) && _showControls)
            _buildCallControls(),
          _buildTopBar(),
          if (!widget.isFullScreen && _callState != CallState.idle)
            _buildOpenFullscreenButton(),
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
      case CallState.fakeCall:
        return _buildFakeCallState();
      case CallState.error:
        return _buildErrorState();
      case CallState.disconnected:
        return _buildDisconnectedState();
    }
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
            setState(() {
              _showControls = !_showControls;
            });
            if (_showControls) {
              _resetHideControlsTimer();
            }
          },
        ),

        // Local camera preview overlay (like in real calls)
        if (_fakeCallCameraEnabled)
          Positioned(
            top: MediaQuery.of(context).padding.top + (widget.isFullScreen ? 20 : 80),
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

        // Camera off overlay for local video
        if (!_fakeCallCameraEnabled)
          Positioned(
            top: MediaQuery.of(context).padding.top + (widget.isFullScreen ? 20 : 80),
            right: 16,
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
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.white70,
                  size: 30,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 20),
          FutureBuilder<Map<Permission, PermissionStatus>>(
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
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Permissions Required',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please grant camera and microphone permissions to start video calls',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 20),
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
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
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

          Positioned(
            top: MediaQuery.of(context).padding.top + (widget.isFullScreen ? 20 : 80),
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
            if (widget.isFullScreen)
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (_callState == CallState.connected || _callState == CallState.fakeCall) {
                    final shouldLeave = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('End Call?'),
                        content: const Text('Are you sure you want to end this call?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('End Call'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                    );

                    if (shouldLeave ?? false) {
                      await _endCall();
                      Navigator.of(context).pop();
                    }
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),

            if (_callState == CallState.connected || _callState == CallState.fakeCall)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isFakeCall ? Colors.orange : Colors.red,
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

            if (_callState == CallState.idle && !widget.isFullScreen)
              IconButton(
                onPressed: () {
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
            // Microphone control (now works for fake calls)
            _buildControlButton(
              icon: _isFakeCall
                  ? (_fakeCallMicEnabled ? Icons.mic : Icons.mic_off)
                  : (_agoraService.isMuted ? Icons.mic_off : Icons.mic),
              onPressed: _isFakeCall
                  ? () {
                setState(() {
                  _fakeCallMicEnabled = !_fakeCallMicEnabled;
                });
                // Optionally still control real mic for fake calls
                _agoraService.toggleMute();
              }
                  : () async {
                await _agoraService.toggleMute();
                setState(() {});
              },
              isActive: _isFakeCall
                  ? _fakeCallMicEnabled
                  : !_agoraService.isMuted,
            ),

            // Camera control (now works for fake calls)
            _buildControlButton(
              icon: _isFakeCall
                  ? (_fakeCallCameraEnabled ? Icons.videocam : Icons.videocam_off)
                  : (_agoraService.isVideoDisabled ? Icons.videocam_off : Icons.videocam),
              onPressed: _isFakeCall
                  ? () async {
                setState(() {
                  _fakeCallCameraEnabled = !_fakeCallCameraEnabled;
                });
                // Actually toggle the real camera for fake calls too
                if (_agoraService.isInitialized) {
                  await _agoraService.toggleVideo();
                }
              }
                  : () async {
                await _agoraService.toggleVideo();
                setState(() {});
              },
              isActive: _isFakeCall
                  ? _fakeCallCameraEnabled
                  : !_agoraService.isVideoDisabled,
            ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              onPressed: () async {
                setState(() => _callState = CallState.disconnected);
                await _endCall();
                if (widget.isFullScreen) {
                  Navigator.of(context).pop();
                }
              },
              isEndCall: true,
            ),

            // Camera switch (works for fake calls too)
            _buildControlButton(
              icon: Icons.cameraswitch,
              onPressed: () async {
                await _agoraService.switchCamera();
              },
              isActive: true, // Always active now
            ),

            // Skip to next
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