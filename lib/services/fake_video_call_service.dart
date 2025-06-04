// lib/services/fake_video_call_service.dart
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

  // Fake video URLs from Google Drive (you'll need to replace these with actual URLs)
  final List<FakeVideoData> _fakeVideos = [
    FakeVideoData(
      videoUrl: 'https://drive.google.com/uc?id=14DWArOTvKk4KYxljVQv4SLLU-8GAErLH&export=download',
      thumbnailUrl: 'https://images.unsplash.com/photo-1742832599361-7aa7decd73b4?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxmZWF0dXJlZC1waG90b3MtZmVlZHwxfHx8ZW58MHx8fHx8',
      duration: Duration(minutes: 3),
      user: FakeUserData(
        name: 'Emma',
        age: 24,
        location: 'New York',
        interests: ['Travel', 'Photography', 'Coffee'],
      ),
    ),
    FakeVideoData(
      videoUrl: 'https://drive.google.com/file/d/14DWArOTvKk4KYxljVQv4SLLU-8GAErLH/view?usp=drive_link',
      thumbnailUrl: 'https://images.unsplash.com/photo-1742832599361-7aa7decd73b4?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxmZWF0dXJlZC1waG90b3MtZmVlZHwxfHx8ZW58MHx8fHx8',
      duration: Duration(minutes: 4),
      user: FakeUserData(
        name: 'Sarah',
        age: 26,
        location: 'London',
        interests: ['Art', 'Music', 'Cooking'],
      ),
    ),
    FakeVideoData(
      videoUrl: 'https://drive.google.com/uc?id=YOUR_VIDEO_ID_3',
      thumbnailUrl: 'https://drive.google.com/uc?id=YOUR_THUMBNAIL_ID_3',
      duration: Duration(minutes: 2, seconds: 30),
      user: FakeUserData(
        name: 'Jessica',
        age: 28,
        location: 'Paris',
        interests: ['Fitness', 'Movies', 'Dancing'],
      ),
    ),
    // Add more fake videos as needed
  ];

  // Get a random fake video for simulation
  FakeVideoData getRandomFakeVideo() {
    return _fakeVideos[_random.nextInt(_fakeVideos.length)];
  }

  // Simulate finding a match with delay
  Future<app_models.User?> simulateFindingMatch() async {
    print('Starting fake video call simulation...');

    // Add some realistic delay
    await Future.delayed(Duration(seconds: 3 + _random.nextInt(5)));

    // Get random fake video
    final fakeVideo = getRandomFakeVideo();

    // Create a fake user model
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

  // Check if we should use fake video (when no real users available)
  Future<bool> shouldUseFakeVideo() async {
    try {
      // Check if there are any other users in the call queue
      final queueSnapshot = await _firestore
          .collection('call_queue')
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      // If no users in queue, use fake video
      return queueSnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking queue: $e');
      return true; // Default to fake video on error
    }
  }

  // Start fake video call session
  Future<FakeCallSession?> startFakeVideoCall() async {
    try {
      final fakeVideo = getRandomFakeVideo();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) return null;

      // Create fake call session
      final session = FakeCallSession(
        sessionId: 'fake_session_${DateTime.now().millisecondsSinceEpoch}',
        fakeVideo: fakeVideo,
        startTime: DateTime.now(),
        currentUserId: currentUserId,
      );

      // Log the fake call session
      await _logFakeCallSession(session);

      return session;
    } catch (e) {
      print('Error starting fake video call: $e');
      return null;
    }
  }

  // Log fake call session for analytics
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

  // End fake call session
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

  // Generate realistic call events
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

  // Get conversation starters for fake calls
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

  // Get fake responses
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

// Data models for fake video calls
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