import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class MessageProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _messagesSubscription;
  String? _currentChatUserId;

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load messages for a specific match
  Future<void> loadMessages(String matchedUserId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentChatUserId = matchedUserId;
    notifyListeners();

    try {
      print('MessageProvider: Loading messages for chat with $matchedUserId');

      // Stop any existing subscription first
      stopMessagesStream();

      // Load initial messages
      _messages = await _firestoreService.getMessages(matchedUserId);
      print('MessageProvider: Loaded ${_messages.length} initial messages');

      // Mark all messages from the matched user as read
      await _firestoreService.markMessagesAsRead(matchedUserId);

      // Start listening for new messages
      _startMessagesStream(matchedUserId);
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      print('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<bool> sendMessage(String receiverId, String text) async {
    try {
      print('MessageProvider: Sending message to $receiverId: "$text"');

      bool success = await _firestoreService.sendMessage(receiverId, text);

      if (success) {
        print('MessageProvider: Message sent successfully');
        // Force refresh the messages to make sure new message appears
        if (_currentChatUserId == receiverId) {
          _messages = await _firestoreService.getMessages(receiverId);
          notifyListeners();
        }
        return true;
      } else {
        print('MessageProvider: Message sending failed');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }


  // Listen to messages stream
  void _startMessagesStream(String matchedUserId) {
    // Cancel previous subscription if it exists
    _messagesSubscription?.cancel();

    print('MessageProvider: Starting message stream for $matchedUserId');

    _messagesSubscription = _firestoreService.messagesStream(matchedUserId)
        .listen((updatedMessages) {
      print('MessageProvider: Stream update with ${updatedMessages.length} messages');

      if (updatedMessages.isNotEmpty) {
        print('MessageProvider: Latest message - "${updatedMessages.first.text}"');
      }

      _messages = updatedMessages;

      // Mark any new messages as read
      _firestoreService.markMessagesAsRead(matchedUserId);

      notifyListeners();
    },
        onError: (error) {
          print('MessageProvider: Error in message stream: $error');
        });
  }

  // Stop listening to messages stream
  void stopMessagesStream() {
    print('MessageProvider: Stopping message stream');
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _currentChatUserId = null;
  }
  @override
  void dispose() {
    stopMessagesStream();
    super.dispose();
  }
}