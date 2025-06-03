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

  // Agora Configuration - Replace with your actual credentials
  static const String appId = '1abf8e98afd04b01a8637ddc4bfbf3d1';
  static const String tempToken = ''; // Use token server in production

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

  // Initialize Agora Engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request permissions
      await [Permission.microphone, Permission.camera].request();

      // Create engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Set event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Local user ${connection.localUid} joined channel ${connection.channelId}');
            _localUserJoined = true;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Remote user $remoteUid joined');
            _remoteUid = remoteUid;
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('Remote user $remoteUid left channel');
            _remoteUid = null;
            onUserOffline?.call(remoteUid, reason);
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason) {
            print('Connection state changed to $state, reason: $reason');
            onConnectionStateChanged?.call(state.toString());
          },
          onRtcStats: (RtcConnection connection, RtcStats stats) {
            onRtcStats?.call(connection, stats);
          },
          onError: (ErrorCodeType err, String msg) {
            print('Error: $err - $msg');
            onError?.call(err, msg);
          },
        ),
      );

      // Configure engine
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.enableVideo();
      await _engine.enableAudio();
      await _engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 30,
          bitrate: 0,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Failed to initialize Agora: $e');
      return false;
    }
  }

  // Join a channel
  Future<bool> joinChannel(String channelName, {String? token}) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      _currentChannel = channelName;

      await _engine.joinChannel(
        token: token ?? tempToken,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );

      return true;
    } catch (e) {
      print('Failed to join channel: $e');
      return false;
    }
  }

  // Leave channel
  Future<void> leaveChannel() async {
    try {
      await _engine.leaveChannel();
      _remoteUid = null;
      _localUserJoined = false;
      _currentChannel = null;
    } catch (e) {
      print('Failed to leave channel: $e');
    }
  }

  // Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _engine.muteLocalAudioStream(_isMuted);
  }

  // Toggle video
  Future<void> toggleVideo() async {
    _isVideoDisabled = !_isVideoDisabled;
    await _engine.muteLocalVideoStream(_isVideoDisabled);
  }

  // Toggle speaker
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  // Switch camera
  Future<void> switchCamera() async {
    _isFrontCamera = !_isFrontCamera;
    await _engine.switchCamera();
  }

  // Create a call room in Firestore
  Future<String?> createCallRoom(String userId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      // Generate unique room ID
      final roomId = '${currentUserId}_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create room document
      await _firestore.collection('call_rooms').doc(roomId).set({
        'roomId': roomId,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId],
        'status': 'waiting',
        'isActive': true,
      });

      return roomId;
    } catch (e) {
      print('Error creating call room: $e');
      return null;
    }
  }

  // Join an existing call room
  Future<bool> joinCallRoom(String roomId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('call_rooms').doc(roomId).update({
        'participants': FieldValue.arrayUnion([currentUserId]),
        'status': 'connected',
      });

      return true;
    } catch (e) {
      print('Error joining call room: $e');
      return false;
    }
  }

  // End call room
  Future<void> endCallRoom(String roomId) async {
    try {
      await _firestore.collection('call_rooms').doc(roomId).update({
        'status': 'ended',
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error ending call room: $e');
    }
  }

  // Find a random user for matching
  Future<app_models.User?> findRandomMatch() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

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

      if (waitingUsers.docs.isNotEmpty) {
        // Pick a random user
        final randomIndex = Random().nextInt(waitingUsers.docs.length);
        final matchedUserId = waitingUsers.docs[randomIndex].id;

        // Remove both users from queue
        await _firestore.collection('call_queue').doc(currentUserId).delete();
        await _firestore.collection('call_queue').doc(matchedUserId).delete();

        // Get matched user data
        final userDoc = await _firestore.collection('users').doc(matchedUserId).get();
        if (userDoc.exists) {
          return app_models.User.fromFirestore(userDoc);
        }
      }

      return null;
    } catch (e) {
      print('Error finding match: $e');
      return null;
    }
  }

  // Remove from queue
  Future<void> removeFromQueue() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _firestore.collection('call_queue').doc(currentUserId).delete();
      }
    } catch (e) {
      print('Error removing from queue: $e');
    }
  }

  // Clean up
  Future<void> dispose() async {
    await leaveChannel();
    await _engine.release();
    _isInitialized = false;
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
          onMatch(matchedUserId);
        }
      }
    });
  }

  // Stop listening
  void stopListening() {
    _queueSubscription?.cancel();
  }
}

// Token generation service (implement server-side)
class AgoraTokenService {
  // In production, call your server to generate tokens
  static Future<String> generateToken(String channelName, int uid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call({
        'channelName': channelName,
        'uid': uid,
      });
      return result.data['token'];
    } catch (e) {
      print('Error generating token: $e');
      return '';
    }
  }
}