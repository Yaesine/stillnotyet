// Solution 1: Rename our Badge model to UserBadge
// lib/models/user_badge_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBadge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final DateTime unlockedAt;
  final UserBadgeType type;

  UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.unlockedAt,
    required this.type,
  });

  factory UserBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBadge(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      iconUrl: data['iconUrl'],
      unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
      type: UserBadgeType.values.firstWhere((e) => e.toString() == data['type']),
    );
  }
}

enum UserBadgeType {
  match,
  conversation,
  profile,
  premium,
  achievement,
}