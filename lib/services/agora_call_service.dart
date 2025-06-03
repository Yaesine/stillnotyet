// lib/services/agora_call_service.dart
import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart' as app_models;

class AgoraCallService {
  static final AgoraCallService _instance = AgoraCallService._internal();
  factory AgoraCallService() => _instance;
  AgoraCallService._internal();

  // Agora Configuration
  static const String appId = '1abf8e98afd04b01a8637ddc4bfbf3d1';

  // IMPORTANT: For testing, we'll join without token first
  // In production, always use proper token generation
  static const String? tempToken = null;

  late RtcEngine _engine;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Call state
  bool _isInitialized = false;
  String? _currentChannel;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;

  // Callbacks
  Function(int uid)? onUserJoined;
  Function(int uid, UserOfflineReasonType reason)? onUserOffline;
  Function(String state)? onConnectionStateChanged;
  Function(RtcConnection connection, RtcStats stats)? onRtcStats;
  Function(ErrorCodeType err, String msg)? onError;

  // Getters
  bool get isMuted => _isMuted;
  bool get isVideoDisabled => _isVideoDisabled;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  int? get remoteUid => _remoteUid;
  bool get isInitialized => _isInitialized;

  // Initialize Agora Engine
  Future<bool> initialize() async {
    if (_isInitialized) {
      print('Agora already initialized');
      return true;
    }

    try {
      print('Starting Agora initialization...');

      // Check permissions without requesting (request will be done in UI)
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      print('Permissions status:');
      print('Microphone: $micStatus');
      print('Camera: $cameraStatus');

      // If permissions not granted, return false
      // The UI will handle requesting permissions
      if (cameraStatus != PermissionStatus.granted ||
          micStatus != PermissionStatus.granted) {
        print('ERROR: Required permissions not granted');
        return false;
      }

      // Create engine
      print('Creating Agora RTC Engine...');
      _engine = createAgoraRtcEngine();

      // Initialize with context
      print('Initializing engine with App ID: $appId');
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      print('Setting up event handlers...');
      // Set event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('✅ Local user ${connection.localUid} joined channel ${connection.channelId}');
            print('Time elapsed: ${elapsed}ms');
            _localUserJoined = true;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('✅ Remote user $remoteUid joined channel');
            _remoteUid = remoteUid;
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('👋 Remote user $remoteUid left channel. Reason: $reason');
            _remoteUid = null;
            onUserOffline?.call(remoteUid, reason);
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason) {
            print('🔄 Connection state changed: $state, reason: $reason');
            onConnectionStateChanged?.call(state.toString());
          },
          onRtcStats: (RtcConnection connection, RtcStats stats) {
            print('📊 RTC Stats - Users: ${stats.userCount}, Duration: ${stats.duration}s');
            onRtcStats?.call(connection, stats);
          },
          onError: (ErrorCodeType err, String msg) {
            print('❌ Agora Error: $err - $msg');
            onError?.call(err, msg);
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            print('⚠️ Token will expire soon, need to renew');
            // In production, generate a new token here
            _renewToken(connection.channelId!);
          },
          onRequestToken: (RtcConnection connection) {
            print('🔑 Token requested for channel: ${connection.channelId}');
            _renewToken(connection.channelId!);
          },
          onConnectionLost: (RtcConnection connection) {
            print('📵 Connection lost!');
          },
          onConnectionInterrupted: (RtcConnection connection) {
            print('⚠️ Connection interrupted');
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('👋 Left channel. Duration: ${stats.duration}s');
          },
        ),
      );

      print('Configuring engine settings...');
      // Configure engine
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.enableVideo();
      await _engine.enableAudio();

      // Set video configuration
      await _engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 30,
          bitrate: 0, // 0 = automatic bitrate
          orientationMode: OrientationMode.orientationModeAdaptive,
          mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
        ),
      );

      // Enable audio volume indication
      await _engine.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );

      _isInitialized = true;
      print('✅ Agora initialization complete');
      return true;
    } catch (e) {
      print('❌ Failed to initialize Agora: $e');
      print('Stack trace: ${StackTrace.current}');
      _isInitialized = false;
      return false;
    }
  }

  // Renew token
  Future<void> _renewToken(String channelName) async {
    try {
      final newToken = await AgoraTokenService.generateToken(channelName, 0);
      if (newToken != null && _currentChannel == channelName) {
        await _engine.renewToken(newToken);
        print('✅ Token renewed successfully');
      }
    } catch (e) {
      print('❌ Failed to renew token: $e');
    }
  }

  // Join a channel
  Future<bool> joinChannel(String channelName, {String? token}) async {
    if (!_isInitialized) {
      print('⚠️ Agora not initialized, initializing now...');
      bool initialized = await initialize();
      if (!initialized) {
        print('❌ Failed to initialize Agora');
        return false;
      }
    }

    try {
      _currentChannel = channelName;
      print('🎯 Attempting to join channel: $channelName');

      // Try to get a token from Firebase Functions
      String? finalToken = token;

      // If no token provided, try to generate one
      if (finalToken == null && tempToken == null) {
        try {
          print('🔑 Generating token for channel: $channelName');
          finalToken = await AgoraTokenService.generateToken(channelName, 0);
          print('✅ Token generated successfully');
        } catch (e) {
          print('⚠️ Failed to generate token: $e');
          print('🔓 Attempting to join without token (App Certificate must be disabled)');
        }
      }

      print('📡 Joining channel with configuration:');
      print('  Channel: $channelName');
      print('  Token: ${finalToken != null ? "✅ Provided" : "❌ None"}');
      print('  UID: 0 (auto-assigned)');

      // Join channel with proper options
      await _engine.joinChannel(
        token: finalToken ?? '', // Empty string for no token
        channelId: channelName,
        uid: 0, // 0 means auto-assign UID
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );

      print('⏳ Join channel request sent, waiting for confirmation...');

      // Give it a moment to connect
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      print('❌ Failed to join channel: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      _currentChannel = null;
      return false;
    }
  }

  // Leave channel
  Future<void> leaveChannel() async {
    try {
      print('👋 Leaving channel...');
      await _engine.leaveChannel();
      _remoteUid = null;
      _localUserJoined = false;
      _currentChannel = null;
      print('✅ Left channel successfully');
    } catch (e) {
      print('❌ Failed to leave channel: $e');
    }
  }

  // Toggle mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _engine.muteLocalAudioStream(_isMuted);
      print('🎤 Microphone ${_isMuted ? "muted" : "unmuted"}');
    } catch (e) {
      print('❌ Failed to toggle mute: $e');
    }
  }

  // Toggle video
  Future<void> toggleVideo() async {
    try {
      _isVideoDisabled = !_isVideoDisabled;
      await _engine.muteLocalVideoStream(_isVideoDisabled);
      print('📹 Camera ${_isVideoDisabled ? "disabled" : "enabled"}');
    } catch (e) {
      print('❌ Failed to toggle video: $e');
    }
  }

  // Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _engine.setEnableSpeakerphone(_isSpeakerOn);
      print('🔊 Speaker ${_isSpeakerOn ? "on" : "off"}');
    } catch (e) {
      print('❌ Failed to toggle speaker: $e');
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    try {
      _isFrontCamera = !_isFrontCamera;
      await _engine.switchCamera();
      print('📷 Switched to ${_isFrontCamera ? "front" : "back"} camera');
    } catch (e) {
      print('❌ Failed to switch camera: $e');
    }
  }

  // Create a call room in Firestore
  Future<String?> createCallRoom(String userId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      // Generate unique room ID
      final roomId = '${currentUserId}_${userId}_call';

      print('🏠 Creating call room: $roomId');

      // Create room document
      await _firestore.collection('call_rooms').doc(roomId).set({
        'roomId': roomId,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId],
        'status': 'waiting',
        'isActive': true,
      });

      print('✅ Call room created: $roomId');
      return roomId;
    } catch (e) {
      print('❌ Error creating call room: $e');
      return null;
    }
  }

  // Join an existing call room
  Future<bool> joinCallRoom(String roomId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      print('🏠 Joining call room: $roomId');

      await _firestore.collection('call_rooms').doc(roomId).update({
        'participants': FieldValue.arrayUnion([currentUserId]),
        'status': 'connected',
      });

      print('✅ Joined call room: $roomId');
      return true;
    } catch (e) {
      print('❌ Error joining call room: $e');
      return false;
    }
  }

  // End call room
  Future<void> endCallRoom(String roomId) async {
    try {
      print('🏠 Ending call room: $roomId');
      await _firestore.collection('call_rooms').doc(roomId).update({
        'status': 'ended',
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Call room ended');
    } catch (e) {
      print('❌ Error ending call room: $e');
    }
  }

  // Find a random user for matching
  Future<app_models.User?> findRandomMatch() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      print('🔍 Looking for random match...');

      // Add current user to waiting queue
      await _firestore.collection('call_queue').doc(currentUserId).set({
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'waiting',
      });

      // Look for other waiting users
      final waitingUsers = await _firestore
          .collection('call_queue')
          .where('status', isEqualTo: 'waiting')
          .where('userId', isNotEqualTo: currentUserId)
          .limit(10)
          .get();

      print('Found ${waitingUsers.docs.length} waiting users');

      if (waitingUsers.docs.isNotEmpty) {
        // Pick a random user
        final randomIndex = Random().nextInt(waitingUsers.docs.length);
        final matchedUserId = waitingUsers.docs[randomIndex].id;

        print('✅ Found match: $matchedUserId');

        // Remove both users from queue
        await _firestore.collection('call_queue').doc(currentUserId).delete();
        await _firestore.collection('call_queue').doc(matchedUserId).delete();

        // Get matched user data
        final userDoc = await _firestore.collection('users').doc(matchedUserId).get();
        if (userDoc.exists) {
          return app_models.User.fromFirestore(userDoc);
        }
      } else {
        print('⏳ No matches available, waiting...');
      }

      return null;
    } catch (e) {
      print('❌ Error finding match: $e');
      return null;
    }
  }

  // Remove from queue
  Future<void> removeFromQueue() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _firestore.collection('call_queue').doc(currentUserId).delete();
        print('✅ Removed from queue');
      }
    } catch (e) {
      print('❌ Error removing from queue: $e');
    }
  }

  // Clean up
  Future<void> dispose() async {
    print('🧹 Disposing Agora resources...');
    try {
      await leaveChannel();
      await _engine.release();
      _isInitialized = false;
      print('✅ Agora resources disposed');
    } catch (e) {
      print('❌ Error disposing Agora: $e');
    }
  }

  // Create local video view
  Widget createLocalVideoView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: 0),
      ),
    );
  }

  // Create remote video view
  Widget createRemoteVideoView(int uid) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: _currentChannel!),
      ),
    );
  }
}

// Call queue manager for matching users
class CallQueueManager {
  static final CallQueueManager _instance = CallQueueManager._internal();
  factory CallQueueManager() => _instance;
  CallQueueManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _queueSubscription;

  // Start listening for matches
  void startListening(String userId, Function(String matchedUserId) onMatch) {
    print('👂 Starting to listen for call matches...');
    _queueSubscription = _firestore
        .collection('call_matches')
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final participants = List<String>.from(data?['participants'] ?? []);
          final matchedUserId = participants.firstWhere((id) => id != userId);
          print('🎉 Match found: $matchedUserId');
          onMatch(matchedUserId);
        }
      }
    });
  }

  // Stop listening
  void stopListening() {
    print('🛑 Stopping call queue listener');
    _queueSubscription?.cancel();
  }
}

// Token generation service
class AgoraTokenService {
  // Generate token via Firebase Functions
  static Future<String> generateToken(String channelName, int uid) async {
    try {
      print('🔑 Calling Firebase Function to generate Agora token...');
      print('  Channel: $channelName');
      print('  UID: $uid');

      final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call({
        'channelName': channelName,
        'uid': uid,
      });

      if (result.data != null && result.data['token'] != null) {
        print('✅ Token generated successfully');
        return result.data['token'];
      } else {
        throw Exception('No token returned from function');
      }
    } catch (e) {
      print('❌ Error generating token: $e');
      print('Error details: ${e.toString()}');
      throw e;
    }
  }
}