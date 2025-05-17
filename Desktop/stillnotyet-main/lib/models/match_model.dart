// lib/models/match_model.dart - Updated to support SuperLike
import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String userId;
  final String matchedUserId;
  final DateTime timestamp;
  final bool superLike; // New field to track if this match was from a SuperLike

  Match({
    required this.id,
    required this.userId,
    required this.matchedUserId,
    required this.timestamp,
    this.superLike = false, // Default to false for normal matches
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      userId: json['userId'],
      matchedUserId: json['matchedUserId'],
      timestamp: (json['timestamp'] is Timestamp)
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']),
      superLike: json['superLike'] ?? false,
    );
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      userId: data['userId'] ?? '',
      matchedUserId: data['matchedUserId'] ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      superLike: data['superLike'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'matchedUserId': matchedUserId,
      'timestamp': timestamp.toIso8601String(),
      'superLike': superLike,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'matchedUserId': matchedUserId,
      'timestamp': Timestamp.fromDate(timestamp),
      'superLike': superLike,
    };
  }
}