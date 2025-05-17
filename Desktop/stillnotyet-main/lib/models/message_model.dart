// lib/models/message_model.dart - Enhanced
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? mediaUrl;
  final Map<String, dynamic>? reactions;
  final bool isDelivered;
  final int? replyToId;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.mediaUrl,
    this.reactions,
    this.isDelivered = false,
    this.replyToId,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      type: MessageType.values.firstWhere(
            (e) => e.toString() == data['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: data['mediaUrl'],
      reactions: data['reactions'] as Map<String, dynamic>?,
      isDelivered: data['isDelivered'] ?? false,
      replyToId: data['replyToId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.toString(),
      'mediaUrl': mediaUrl,
      'reactions': reactions,
      'isDelivered': isDelivered,
      'replyToId': replyToId,
    };
  }
}

enum MessageType {
  text,
  image,
  gif,
  audio,
  sticker,
}