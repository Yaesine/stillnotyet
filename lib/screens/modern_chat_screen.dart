// lib/screens/modern_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';
import '../widgets/FCMTokenFixer.dart';
import '../widgets/TestNotificationButton.dart';
import '../widgets/components/letter_avatar.dart';

import '../providers/app_auth_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/user_profile_detail.dart';

class ModernChatScreen extends StatefulWidget {
  const ModernChatScreen({Key? key}) : super(key: key);

  @override
  _ModernChatScreenState createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  User? _matchedUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure we have route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.stopMessagesStream();
    super.dispose();
  }

  // Also update the _loadMessages method:
  Future<void> _loadMessages() async {
    try {
      print("Attempting to load messages");

      // Get matched user from route arguments with null safety
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
        print("No arguments passed to ModernChatScreen");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No user data provided'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _matchedUser = args as User;
        _isLoading = true;
      });

      print("Matched user ID: ${_matchedUser!.id}, Name: ${_matchedUser!.name}");

      // Load messages for this match using the Provider
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);

      // Make sure we stop any existing stream first
      messageProvider.stopMessagesStream();

      // Then load messages fresh
      await messageProvider.loadMessages(_matchedUser!.id);

      print("Messages loaded successfully");

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show typing indicator randomly sometimes
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && messageProvider.messages.isEmpty) {
            setState(() {
              _isTyping = true;
            });

            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _isTyping = false;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    // Validation: Don't send empty messages
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _matchedUser == null) {
      return;
    }

    // Clear text field first for better UX
    _messageController.clear();

    // Set sending state
    setState(() {
      _isSending = true;
    });

    try {
      print("Sending message: $messageText to ${_matchedUser!.id}");

      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      bool success = await messageProvider.sendMessage(_matchedUser!.id, messageText);

      print("Message send result: $success");

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Force a refresh of the messages
        if (mounted) {
          // Reload messages to ensure the UI updates
          await messageProvider.loadMessages(_matchedUser!.id);
        }

        // Scroll to bottom after sending
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // Show typing indicator after you send a message
        if (mounted) {
          setState(() {
            _isTyping = true;
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isTyping = false;
              });
            }
          });
        }
      }
    } catch (e) {
      print("Error sending message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  // Update your build method's AppBar to include the test button

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _matchedUser != null
            ? Row(
          children: [
            // Make the avatar clickable to navigate to profile
            GestureDetector(
              onTap: () {
                // Navigate to user profile detail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileDetail(user: _matchedUser!),
                  ),
                );
              },
              child: LetterAvatar(
                name: _matchedUser!.name,
                size: 36,
                imageUrls: _matchedUser!.imageUrls.isEmpty ? null : _matchedUser!.imageUrls,
              ),
            ),
            const SizedBox(width: 8),
            // Display only the first name
            Text(_matchedUser!.name.split(' ')[0]),
          ],
        )
            : const Text("Chat"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // ADD THIS: Actions with the test button
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, _) {
                final messages = messageProvider.messages;

                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Add typing indicator at the top when typing
                    if (_isTyping && index == 0) {
                      return _buildTypingIndicator();
                    }

                    // Adjust index for messages when typing indicator is present
                    final messageIndex = _isTyping ? index - 1 : index;
                    if (messageIndex < 0) return const SizedBox.shrink();

                    final message = messages[messageIndex];
                    final isMe = message.senderId ==
                        Provider.of<AppAuthProvider>(context, listen: false).currentUserId;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    if (_matchedUser == null) {
      return const Center(child: Text("No user data"));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use LetterAvatar instead of CircleAvatar
          SizedBox(
            width: 100,
            height: 100,
            child: LetterAvatar(
              name: _matchedUser!.name,
              size: 100,
              imageUrls: _matchedUser!.imageUrls,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You matched with ${_matchedUser!.name.split(' ')[0]}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Send a message to start the conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _messageController.text = 'Hi ${_matchedUser!.name}, nice to meet you!';
            },
            child: const Text('Start with a greeting'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Use LetterAvatar for the typing indicator
          LetterAvatar(
            name: _matchedUser!.name,
            size: 32,
            imageUrls: _matchedUser!.imageUrls,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildDot(300),
                const SizedBox(width: 4),
                _buildDot(600),
                const SizedBox(width: 4),
                _buildDot(900),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int milliseconds) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: milliseconds),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: const Text(
            '•',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show the matched user's avatar on their messages
          if (!isMe && _matchedUser != null) ...[
            LetterAvatar(
              name: _matchedUser!.name,
              size: 32,
              imageUrls: _matchedUser!.imageUrls,
            ),
            const SizedBox(width: 8),
          ],

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Show the current user's avatar on their messages
          if (isMe) ...[
            const SizedBox(width: 8),
            const LetterAvatar(
              name: "Me", // Or get the current user's name
              size: 32,
              backgroundColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          MaterialButton(
            onPressed: _isSending ? null : _sendMessage,
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            minWidth: 0,
            child: _isSending
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}