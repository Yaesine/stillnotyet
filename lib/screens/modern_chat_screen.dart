// lib/screens/modern_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _matchedUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _isBlocked = false;
  bool _isBlockedByOther = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure we have route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _checkBlockStatus();
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

  // Check if either user has blocked the other
  Future<void> _checkBlockStatus() async {
    if (_matchedUser == null) return;

    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Check if current user blocked the matched user
      final blockedByMeDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(_matchedUser!.id)
          .get();

      // Check if matched user blocked the current user
      final blockedByOtherDoc = await _firestore
          .collection('users')
          .doc(_matchedUser!.id)
          .collection('blocked_users')
          .doc(currentUserId)
          .get();

      if (mounted) {
        setState(() {
          _isBlocked = blockedByMeDoc.exists;
          _isBlockedByOther = blockedByOtherDoc.exists;
        });
      }
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  // Block user function
  Future<void> _blockUser() async {
    if (_matchedUser == null) return;

    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Block User'),
            content: Text('Are you sure you want to block ${_matchedUser!.name}? You won\'t be able to send or receive messages from this user.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Block'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Add to blocked users collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(_matchedUser!.id)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
        'blockedUserId': _matchedUser!.id,
        'blockedUserName': _matchedUser!.name,
      });

      // Remove from matches if exists
      await _firestore
          .collection('matches')
          .doc('$currentUserId-${_matchedUser!.id}')
          .delete();

      await _firestore
          .collection('matches')
          .doc('${_matchedUser!.id}-$currentUserId')
          .delete();

      if (mounted) {
        setState(() {
          _isBlocked = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_matchedUser!.name} has been blocked'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error blocking user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to block user. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Unblock user function
  Future<void> _unblockUser() async {
    if (_matchedUser == null) return;

    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Unblock User'),
            content: Text('Are you sure you want to unblock ${_matchedUser!.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('Unblock'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Remove from blocked users collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(_matchedUser!.id)
          .delete();

      if (mounted) {
        setState(() {
          _isBlocked = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_matchedUser!.name} has been unblocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error unblocking user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unblock user. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Report user function
  Future<void> _reportUser() async {
    if (_matchedUser == null) return;

    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Show report reason dialog
      final String? reason = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          String selectedReason = 'Inappropriate behavior';
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Report User'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why are you reporting ${_matchedUser!.name}?'),
                    const SizedBox(height: 16),
                    RadioListTile<String>(
                      title: const Text('Inappropriate behavior'),
                      value: 'Inappropriate behavior',
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() => selectedReason = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Fake profile'),
                      value: 'Fake profile',
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() => selectedReason = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Harassment or bullying'),
                      value: 'Harassment or bullying',
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() => selectedReason = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Spam or scam'),
                      value: 'Spam or scam',
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() => selectedReason = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Other'),
                      value: 'Other',
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() => selectedReason = value!);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(selectedReason),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Report'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (reason == null) return;

      // Create report document
      await _firestore.collection('reports').add({
        'reporterId': currentUserId,
        'reportedUserId': _matchedUser!.id,
        'reportedUserName': _matchedUser!.name,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'context': 'chat',
      });

      if (mounted) {
        // Show additional options dialog
        final bool? shouldBlock = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Report Submitted'),
              content: const Text('Thank you for reporting. Our team will review this report.\n\nWould you also like to block this user?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Yes, Block User'),
                ),
              ],
            );
          },
        );

        if (shouldBlock == true) {
          await _blockUser();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error reporting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show options menu
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                leading: Icon(
                  _isBlocked ? Icons.check_circle : Icons.block,
                  color: _isBlocked ? Colors.green : Colors.red,
                ),
                title: Text(_isBlocked ? 'Unblock User' : 'Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _isBlocked ? _unblockUser() : _blockUser();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileDetail(user: _matchedUser!),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // Update the existing _loadMessages method
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
    // Check if blocked
    if (_isBlocked || _isBlockedByOther) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBlocked
              ? 'You have blocked this user. Unblock to send messages.'
              : 'You cannot send messages to this user.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
        actions: [
          if (_matchedUser != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showOptionsMenu,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Show blocked status banner
          if (_isBlocked || _isBlockedByOther)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: isDarkMode ? Colors.orange.shade900 : Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: isDarkMode ? Colors.orange.shade100 : Colors.orange.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isBlocked
                          ? 'You have blocked this user. Unblock to send messages.'
                          : 'You cannot send messages to this user.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.orange.shade100 : Colors.orange.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

    // Show different message if blocked
    if (_isBlocked || _isBlockedByOther) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _isBlocked
                  ? 'You have blocked ${_matchedUser!.name.split(' ')[0]}'
                  : 'You cannot message this user',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_isBlocked)
              TextButton(
                onPressed: _unblockUser,
                child: const Text('Unblock User'),
              ),
          ],
        ),
      );
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
    final canSendMessages = !_isBlocked && !_isBlockedByOther;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSendMessages,
              decoration: InputDecoration(
                hintText: canSendMessages
                    ? 'Type a message...'
                    : (_isBlocked ? 'You have blocked this user' : 'You cannot message this user'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                fillColor: canSendMessages ? null : Colors.grey.shade200,
                filled: !canSendMessages,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: canSendMessages ? (_) => _sendMessage() : null,
            ),
          ),
          const SizedBox(width: 8),
          MaterialButton(
            onPressed: (_isSending || !canSendMessages) ? null : _sendMessage,
            color: canSendMessages ? Theme.of(context).primaryColor : Colors.grey,
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