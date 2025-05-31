// lib/screens/enhanced_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../providers/app_auth_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/TestNotificationButton.dart';
import '../widgets/components/typing_indicator.dart';
import '../widgets/components/profile_avatar.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/letter_avatar.dart'; // Import the new widget

class EnhancedChatScreen extends StatefulWidget {
  const EnhancedChatScreen({Key? key}) : super(key: key);

  @override
  _EnhancedChatScreenState createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  User? _matchedUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _showScrollButton = false;
  bool _isTyping = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scrollController.addListener(_scrollListener);

    // Use post-frame callback to ensure we have route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.position.pixels > 300;
      if (showButton != _showScrollButton) {
        setState(() {
          _showScrollButton = showButton;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.stopMessagesStream();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      // Get matched user from route arguments with null safety
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
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

      // Load messages for this match using the Provider
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.loadMessages(_matchedUser!.id);

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
    if (_messageController.text.trim().isEmpty || _matchedUser == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      bool success = await messageProvider.sendMessage(_matchedUser!.id, messageText);

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: _matchedUser != null ? _buildAppBarTitle() : const Text("Chat"),
        centerTitle: false,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TestNotificationButton(
            recipientId: _matchedUser?.id, // Pass the chat partner's ID
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator(
        type: LoadingIndicatorType.pulse,
        size: LoadingIndicatorSize.large,
        message: 'Loading messages...',
      ))
          : Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Consumer<MessageProvider>(
                  builder: (context, messageProvider, _) {
                    final messages = messageProvider.messages;

                    if (messages.isEmpty && !_isTyping) {
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
                          return TypingIndicator(
                            userName: _matchedUser?.name ?? '',
                          );
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

                // Scroll to bottom button
                if (_showScrollButton)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.arrow_downward, color: Colors.white),
                      onPressed: _scrollToBottom,
                    ),
                  ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        // Use ProfileAvatar with the user's name
        ProfileAvatar(
          imageUrl: _matchedUser!.imageUrls.isNotEmpty ? _matchedUser!.imageUrls[0] : '',
          userName: _matchedUser!.name,
          size: 40,
          status: ProfileAvatarStatus.online,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _matchedUser!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Online now',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 16 : 4),
      topRight: Radius.circular(isMe ? 4 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    final bgColor = isMe ? AppColors.primary : Colors.white;
    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final timestampColor = isMe ? Colors.white.withOpacity(0.7) : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && _matchedUser != null) ...[
            // Use LetterAvatar directly for matched user
            LetterAvatar(
              name: _matchedUser!.name,
              imageUrls: _matchedUser!.imageUrls,
              size: 32,
            ),
            const SizedBox(width: 8),
          ],

          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: timestampColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue[300] : timestampColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            // Use LetterAvatar for current user
            // Get current user's name from a provider if available, or use "Me"
            LetterAvatar(
              name: "Me", // Ideally you would get current user's name from a provider
              size: 32,
              backgroundColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: () {
                // Show attachment options
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                      onPressed: () {
                        // Show emoji picker
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Use LetterAvatar for the empty chat view
          SizedBox(
            width: 120,
            height: 120,
            child: _matchedUser != null
                ? LetterAvatar(
              name: _matchedUser!.name,
              size: 120,
              imageUrls: _matchedUser!.imageUrls,
              showBorder: true,
            )
                : Container(),
          ),
          const SizedBox(height: 24),
          Text(
            'It\'s a Match!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _matchedUser != null
                  ? 'You have got a new match 🎉🎉🎉. Start the conversation now!'
                  : 'You matched with this person. Start the conversation now!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                // Message suggestions
                _buildSuggestionButton('👋 Hey there! How\'s your day going?'),
                const SizedBox(height: 12),
                _buildSuggestionButton('I noticed you like ${_matchedUser?.interests.isNotEmpty == true ? _matchedUser!.interests[0] : "traveling"}. That\'s cool!'),
                const SizedBox(height: 12),
                _buildSuggestionButton('What do you like to do for fun?'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _messageController.text = text;
          _sendMessage();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('View Photos'),
              onTap: () {
                Navigator.pop(context);
                // Show photos
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // Show report options
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Unmatch'),
              onTap: () {
                Navigator.pop(context);
                _showUnmatchConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUnmatchConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch'),
        content: Text('Are you sure you want to unmatch with ${_matchedUser?.name ?? "this person"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // Perform unmatch action
            },
            child: const Text('Unmatch', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}