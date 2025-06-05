// lib/services/fake_video_call_service.dart - Updated with working video URLs
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' as app_models;

class FakeVideoCallService {
  static final FakeVideoCallService _instance = FakeVideoCallService._internal();
  factory FakeVideoCallService() => _instance;
  FakeVideoCallService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  final List<FakeVideoData> _fakeVideos = [
    FakeVideoData(
      videoUrl: 'https://res.cloudinary.com/do5u0hen5/video/upload/v1749131937/Video_Ready_Enthusiastic_Young_Woman_1_xvqma6.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=500&auto=format&fit=crop&q=60',
      duration: Duration(minutes: 1),
      user: FakeUserData(
        name: 'Emma',
        age: 24,
        location: 'New York',
        interests: ['Travel', 'Photography', 'Coffee'],
      ),
    ),
    FakeVideoData(
      videoUrl: 'https://res.cloudinary.com/do5u0hen5/video/upload/v1749131931/Video_Generation_Young_Woman_Chat_1_bvphzc.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=500&auto=format&fit=crop&q=60',
      duration: Duration(minutes: 1),
      user: FakeUserData(
        name: 'Sarah',
        age: 26,
        location: 'London',
        interests: ['Art', 'Music', 'Cooking'],
      ),
    ),
    FakeVideoData(
      videoUrl: 'https://res.cloudinary.com/do5u0hen5/video/upload/v1749131814/Video_Request_Silent_Vlog_1_hqlwnt.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60',
      duration: Duration(minutes: 1, seconds: 30),
      user: FakeUserData(
        name: 'Jessica',
        age: 28,
        location: 'Paris',
        interests: ['Fitness', 'Movies', 'Dancing'],
      ),
    ),


  ];


  FakeVideoData getRandomFakeVideo() {
    return _fakeVideos[_random.nextInt(_fakeVideos.length)];
  }

  Future<app_models.User?> simulateFindingMatch() async {
    print('Starting fake video call simulation...');
    await Future.delayed(Duration(seconds: 3 + _random.nextInt(5)));

    final fakeVideo = getRandomFakeVideo();
    final fakeUser = app_models.User(
      id: 'fake_${DateTime.now().millisecondsSinceEpoch}',
      name: fakeVideo.user.name,
      age: fakeVideo.user.age,
      bio: 'Love ${fakeVideo.user.interests.join(", ")}',
      imageUrls: [fakeVideo.thumbnailUrl],
      interests: fakeVideo.user.interests,
      location: fakeVideo.user.location,
    );

    print('Fake match found: ${fakeUser.name}');
    return fakeUser;
  }

  Future<bool> shouldUseFakeVideo() async {
    try {
      final queueSnapshot = await _firestore
          .collection('call_queue')
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();
      return queueSnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking queue: $e');
      return true;
    }
  }

  Future<FakeCallSession?> startFakeVideoCall() async {
    try {
      final fakeVideo = getRandomFakeVideo();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) return null;

      final session = FakeCallSession(
        sessionId: 'fake_session_${DateTime.now().millisecondsSinceEpoch}',
        fakeVideo: fakeVideo,
        startTime: DateTime.now(),
        currentUserId: currentUserId,
      );

      await _logFakeCallSession(session);
      return session;
    } catch (e) {
      print('Error starting fake video call: $e');
      return null;
    }
  }

  Future<void> _logFakeCallSession(FakeCallSession session) async {
    try {
      await _firestore.collection('fake_call_sessions').add({
        'sessionId': session.sessionId,
        'userId': session.currentUserId,
        'fakeUserName': session.fakeVideo.user.name,
        'startTime': Timestamp.fromDate(session.startTime),
        'videoUrl': session.fakeVideo.videoUrl,
        'status': 'active',
      });
    } catch (e) {
      print('Error logging fake call session: $e');
    }
  }

  Future<void> endFakeCallSession(String sessionId) async {
    try {
      final sessionQuery = await _firestore
          .collection('fake_call_sessions')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (sessionQuery.docs.isNotEmpty) {
        await sessionQuery.docs.first.reference.update({
          'endTime': Timestamp.now(),
          'status': 'ended',
        });
      }
    } catch (e) {
      print('Error ending fake call session: $e');
    }
  }

  Stream<FakeCallEvent> generateCallEvents() {
    return Stream.periodic(Duration(seconds: 2 + _random.nextInt(8)), (index) {
      final events = [
        FakeCallEvent.gesture,
        FakeCallEvent.smile,
        FakeCallEvent.wave,
        FakeCallEvent.nod,
        FakeCallEvent.laugh,
      ];
      return events[_random.nextInt(events.length)];
    });
  }

  List<String> getConversationStarters() {
    return [
      "Hi there! How's your day going?",
      "Nice to meet you! What brings you here?",
      "Love your style! Where are you from?",
      "This is fun! Do you use this app often?",
      "You seem interesting! Tell me about yourself.",
      "Great to connect! What are your hobbies?",
    ];
  }

  List<String> getFakeResponses() {
    return [
      "That's so cool!",
      "I love that too!",
      "Really? Tell me more!",
      "Haha, that's funny!",
      "I've always wanted to try that.",
      "You seem really nice!",
      "This is fun!",
      "I'm having a great time chatting!",
    ];
  }
}

// Keep your existing data model classes unchanged
class FakeVideoData {
  final String videoUrl;
  final String thumbnailUrl;
  final Duration duration;
  final FakeUserData user;

  FakeVideoData({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.user,
  });
}

class FakeUserData {
  final String name;
  final int age;
  final String location;
  final List<String> interests;

  FakeUserData({
    required this.name,
    required this.age,
    required this.location,
    required this.interests,
  });
}

class FakeCallSession {
  final String sessionId;
  final FakeVideoData fakeVideo;
  final DateTime startTime;
  final String currentUserId;

  FakeCallSession({
    required this.sessionId,
    required this.fakeVideo,
    required this.startTime,
    required this.currentUserId,
  });
}

enum FakeCallEvent {
  gesture,
  smile,
  wave,
  nod,
  laugh,
}