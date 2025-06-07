import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUser {
  final String id;
  final String name;
  final DateTime blockedAt;

  BlockedUser({
    required this.id,
    required this.name,
    required this.blockedAt,
  });

  factory BlockedUser.fromMap(Map<String, dynamic> map) {
    return BlockedUser(
      id: map['userId'] as String,
      name: map['userName'] as String,
      blockedAt: (map['blockedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': id,
      'userName': name,
      'blockedAt': Timestamp.fromDate(blockedAt),
    };
  }
} 