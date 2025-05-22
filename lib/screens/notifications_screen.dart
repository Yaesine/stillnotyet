import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import '../theme/app_theme.dart';
import '../widgets/components/letter_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  // Tab controller for switching between notifications and settings
  late TabController _tabController;

  // Notification settings state
  bool _pushNotificationsEnabled = true;
  bool _newMatchesEnabled = true;
  bool _messagesEnabled = true;
  bool _likesEnabled = true;
  bool _superLikesEnabled = true;
  bool _profileViewsEnabled = true;
  bool _remindersEnabled = true;
  bool _promotionsEnabled = false;

  // Mock notifications data - in a real app, this would come from your backend
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'match',
      'title': 'New Match!',
      'message': 'You and Sarah matched! Send them a message to start the conversation.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'read': false,
      'data': <String, dynamic>{
        'userId': 'user123',
        'userName': 'Sarah',
        'imageUrl': '',
      },
    },
    {
      'id': '2',
      'type': 'message',
      'title': 'New Message',
      'message': 'James: Hey there! How\'s your day going?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'read': true,
      'data': <String, dynamic>{
        'userId': 'user456',
        'userName': 'James',
        'imageUrl': '',
        'conversationId': 'conv123',
      },
    },
    {
      'id': '3',
      'type': 'super_like',
      'title': 'Super Like Received!',
      'message': 'Michael super liked your profile!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
      'read': false,
      'data': <String, dynamic>{
        'userId': 'user789',
        'userName': 'Michael',
        'imageUrl': '',
      },
    },
    {
      'id': '4',
      'type': 'profile_view',
      'title': 'Profile View',
      'message': 'Emma viewed your profile',
      'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
      'read': true,
      'data': <String, dynamic>{
        'userId': 'user101',
        'userName': 'Emma',
        'imageUrl': '',
      },
    },
    {
      'id': '5',
      'type': 'reminder',
      'title': 'Daily Picks Ready!',
      'message': 'Your daily recommended matches are ready for you!',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
      'data': <String, dynamic>{},
    },
    {
      'id': '6',
      'type': 'promotion',
      'title': '50% Off Premium!',
      'message': 'Limited time offer: Get 50% off your first month of Premium!',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'read': true,
      'data': <String, dynamic>{
        'promoCode': 'SPRING50',
      },
    },
    {
      'id': '7',
      'type': 'message',
      'title': 'New Message',
      'message': 'Alex: Would you like to grab coffee sometime?',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'read': true,
      'data': <String, dynamic>{
        'userId': 'user202',
        'userName': 'Alex',
        'imageUrl': '',
        'conversationId': 'conv456',
      },
    },
    {
      'id': '8',
      'type': 'like',
      'title': 'New Like',
      'message': 'Someone liked your profile! Upgrade to Premium to see who.',
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
      'read': true,
      'data': <String, dynamic>{
        'userId': 'user303',
      },
    },
  ];

  bool _isMarkingAllAsRead = false;
  bool _isUpdatingSetting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get notification icon based on type
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'match':
        return Icons.favorite;
      case 'message':
        return Icons.message;
      case 'super_like':
        return Icons.star;
      case 'like':
        return Icons.thumb_up;
      case 'profile_view':
        return Icons.visibility;
      case 'reminder':
        return Icons.notifications_active;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  // Get notification color based on type
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'match':
        return Colors.red;
      case 'message':
        return Colors.blue;
      case 'super_like':
        return Colors.purple;
      case 'like':
        return Colors.pink;
      case 'profile_view':
        return Colors.teal;
      case 'reminder':
        return Colors.amber;
      case 'promotion':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  // Format notification timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Mark all notifications as read
  Future<void> _markAllAsRead() async {
    setState(() {
      _isMarkingAllAsRead = true;
    });

    try {
      // In a real app, call your API to mark all notifications as read
      await Future.delayed(const Duration(milliseconds: 800)); // Simulated API call

      setState(() {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
        _isMarkingAllAsRead = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isMarkingAllAsRead = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    setState(() {
      notification['read'] = true;
    });

    // In a real app, navigate to the appropriate screen based on notification type
    final type = notification['type'];
    final Map<String, dynamic> data = Map<String, dynamic>.from(notification['data'] as Map<String, dynamic>);

    switch (type) {
      case 'match':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to match with ${data['userName'] != null ? data['userName'].toString() : ''}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'message':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to conversation with ${data['userName'] != null ? data['userName'].toString() : ''}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'super_like':
      case 'like':
      case 'profile_view':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to profile of ${data['userName'] != null ? data['userName'].toString() : ''}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'reminder':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to daily recommendations'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'promotion':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to premium subscription page'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  // Update notification settings
  Future<void> _updateNotificationSetting(String setting, bool value) async {
    setState(() {
      _isUpdatingSetting = true;
    });

    try {
      // In a real app, call your API to update the setting
      await Future.delayed(const Duration(milliseconds: 500)); // Simulated API call

      setState(() {
        switch (setting) {
          case 'push_notifications':
            _pushNotificationsEnabled = value;
            break;
          case 'new_matches':
            _newMatchesEnabled = value;
            break;
          case 'messages':
            _messagesEnabled = value;
            break;
          case 'likes':
            _likesEnabled = value;
            break;
          case 'super_likes':
            _superLikesEnabled = value;
            break;
          case 'profile_views':
            _profileViewsEnabled = value;
            break;
          case 'reminders':
            _remindersEnabled = value;
            break;
          case 'promotions':
            _promotionsEnabled = value;
            break;
        }
        _isUpdatingSetting = false;
      });
    } catch (e) {
      setState(() {
        _isUpdatingSetting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating setting: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isDarkMode ? AppColors.darkDivider : Colors.grey.shade200;

    // Count unread notifications
    final unreadCount = _notifications.where((notification) => notification['read'] == false).length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: subTextColor,
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Settings'),
          ],
        ),
        actions: [
          // Only show mark all as read button in notifications tab and if there are unread notifications
          if (_tabController.index == 0 && unreadCount > 0)
            _isMarkingAllAsRead
                ? Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              ),
            )
                : TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notifications tab
          _buildNotificationsTab(cardColor, textColor, subTextColor, dividerColor),

          // Settings tab
          _buildSettingsTab(cardColor, textColor, subTextColor, dividerColor),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(Color cardColor, Color textColor, Color subTextColor, Color dividerColor) {
    return _notifications.isEmpty
    // Empty state
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: subTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get new matches, messages, or likes,\nyou\'ll see them here.',
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
    // Notifications list
        : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final isRead = notification['read'] as bool;
        final type = notification['type'] as String;
        final Map<String, dynamic> data = Map<String, dynamic>.from(notification['data'] as Map<String, dynamic>);

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: !isRead
                ? Border.all(
              color: AppColors.primary,
              width: 1.5,
            )
                : null,
          ),
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar or icon
                  _buildNotificationAvatar(data, type),
                  const SizedBox(width: 16),

                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatTimestamp(notification['timestamp']),
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message'],
                          style: TextStyle(
                            color: isRead ? subTextColor : textColor,
                            fontSize: 14,
                          ),
                        ),

                        // Action buttons for certain notification types
                        if (type == 'match' || type == 'message')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        notification['read'] = true;
                                      });
                                      // In a real app, navigate to the appropriate screen
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(type == 'match'
                                              ? 'Navigating to match with ${data['userName'] != null ? data['userName'].toString() : ''}'
                                              : 'Navigating to conversation with ${data['userName'] != null ? data['userName'].toString() : ''}'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: Text(type == 'match' ? 'Say Hello' : 'Reply'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(Color cardColor, Color textColor, Color subTextColor, Color dividerColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master switch for all push notifications
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _pushNotificationsEnabled
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: _pushNotificationsEnabled ? AppColors.primary : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Push Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pushNotificationsEnabled
                              ? 'You will receive push notifications'
                              : 'You will not receive any push notifications',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _isUpdatingSetting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Platform.isIOS
                      ? CupertinoSwitch(
                    value: _pushNotificationsEnabled,
                    onChanged: (value) => _updateNotificationSetting('push_notifications', value),
                    activeColor: AppColors.primary,
                  )
                      : Switch(
                    value: _pushNotificationsEnabled,
                    onChanged: (value) => _updateNotificationSetting('push_notifications', value),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Notification Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 12),

          // Only show notification type settings if master switch is on
          if (_pushNotificationsEnabled) ...[
            // New Matches
            _buildNotificationSetting(
              title: 'New Matches',
              subtitle: 'When you get a new match',
              icon: Icons.favorite,
              iconColor: Colors.red,
              value: _newMatchesEnabled,
              onChanged: (value) => _updateNotificationSetting('new_matches', value),
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              dividerColor: dividerColor,
            ),

            // Messages
            _buildNotificationSetting(
              title: 'Messages',
              subtitle: 'When you receive a new message',
              icon: Icons.message,
              iconColor: Colors.blue,
              value: _messagesEnabled,
              onChanged: (value) => _updateNotificationSetting('messages', value),
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              dividerColor: dividerColor,
            ),

            // Likes
            _buildNotificationSetting(
              title: 'Likes',
              subtitle: 'When someone likes your profile',
              icon: Icons.thumb_up,
              iconColor: Colors.pink,
              value: _likesEnabled,
              onChanged: (value) => _updateNotificationSetting('likes', value),
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              dividerColor: dividerColor,
            ),

            // Super Likes
            _buildNotificationSetting(
              title: 'Super Likes',
              subtitle: 'When someone super likes your profile',
              icon: Icons.star,
              iconColor: Colors.purple,
              value: _superLikesEnabled,
              onChanged: (value) => _updateNotificationSetting('super_likes', value),
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              dividerColor: dividerColor,
            ),

            // Profile Views
            _buildNotificationSetting(
              title: 'Profile Views',
              subtitle: 'When someone views your profile',
              icon: Icons.visibility,
              iconColor: Colors.teal,
              value: _profileViewsEnabled,
              onChanged: (value) => _updateNotificationSetting('profile_views', value),
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              dividerColor: dividerColor,
            ),

            // Reminders
            _buildNotificationSetting(
              title: 'Reminders',
              subtitle: 'Daily recommendations and streak reminders',
              icon: Icons.notifications_active,
              iconColor: Colors.amber,
              value: _remindersEnabled,
              onChanged: (value) => _updateNotificationSetting('reminders', value),
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              dividerColor: dividerColor,
            ),

            // Promotions
            _buildNotificationSetting(
              title: 'Promotions',
              subtitle: 'Discounts and special offers',
              icon: Icons.local_offer,
              iconColor: Colors.green,
              value: _promotionsEnabled,
              onChanged: (value) => _updateNotificationSetting('promotions', value),
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              dividerColor: dividerColor,
              isLast: true,
            ),
          ] else ...[
            // Show message when notifications are disabled
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 48,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notifications are disabled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable push notifications to receive updates about matches, messages, and more.',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _updateNotificationSetting('push_notifications', true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Enable Notifications'),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Email Notifications Section
          Text(
            'Email Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Email Notification Settings Button
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Email Preferences',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Manage what emails you receive',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: subTextColor,
                    size: 16,
                  ),
                  onTap: () {
                    // In a real app, navigate to email settings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email preferences would open here'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                Divider(
                  color: dividerColor,
                  height: 1,
                ),

                // Unsubscribe Button
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.unsubscribe,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Unsubscribe from All',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Stop receiving all email notifications',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: subTextColor,
                    size: 16,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Unsubscribe from All Emails'),
                        content: const Text(
                          'Are you sure you want to unsubscribe from all email notifications? You will no longer receive important updates about your matches and messages.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unsubscribed from all emails'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text('Unsubscribe'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNotificationAvatar(Map<String, dynamic> data, String type) {
    bool hasValidImage = data.containsKey('imageUrl') &&
        data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty;

    if (hasValidImage) {
      String name = data['userName'] != null ? data['userName'].toString() : '';
      return LetterAvatar(
        name: name,
        size: 50,
        imageUrls: [data['imageUrl'].toString()],
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _getNotificationColor(type).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getNotificationIcon(type),
          color: _getNotificationColor(type),
          size: 24,
        ),
      );
    }
  }

  Widget _buildNotificationSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color dividerColor,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: isLast
            ? BorderRadius.circular(12)
            : const BorderRadius.vertical(
          top: Radius.circular(12),
          bottom: Radius.zero,
        ),
        boxShadow: isLast
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ]
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: value ? iconColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: value ? iconColor : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _isUpdatingSetting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Platform.isIOS
                    ? CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                )
                    : Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          if (!isLast)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: dividerColor,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}