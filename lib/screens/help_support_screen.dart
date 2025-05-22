// lib/screens/help_support_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isSubmittingTicket = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // FAQ Categories
  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.person,
      'title': 'Account',
      'color': Colors.blue,
    },
    {
      'icon': Icons.message,
      'title': 'Messaging',
      'color': Colors.green,
    },
    {
      'icon': Icons.credit_card,
      'title': 'Billing',
      'color': Colors.purple,
    },
    {
      'icon': Icons.favorite,
      'title': 'Matching',
      'color': Colors.red,
    },
    {
      'icon': Icons.security,
      'title': 'Safety',
      'color': Colors.orange,
    },
    {
      'icon': Icons.settings,
      'title': 'Technical',
      'color': Colors.teal,
    },
  ];

  // FAQ questions and answers
  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Account',
      'question': 'How do I reset my password?',
      'answer': 'To reset your password, go to the login screen and tap on "Forgot Password". You will receive an email with instructions to reset your password.',
    },
    {
      'category': 'Account',
      'question': 'How do I change my profile picture?',
      'answer': 'Go to your profile tab, tap on your current profile picture or the "Edit Profile" button, then select the photo icon to upload a new image.',
    },
    {
      'category': 'Account',
      'question': 'Can I change my username?',
      'answer': 'Yes, you can change your display name in the Edit Profile section. However, your login email cannot be changed.',
    },
    {
      'category': 'Messaging',
      'question': 'Why can\'t I send messages?',
      'answer': 'You can only send messages to users you\'ve matched with. If you\'re having trouble sending messages to a match, try restarting the app or checking your internet connection.',
    },
    {
      'category': 'Messaging',
      'question': 'How do I delete a conversation?',
      'answer': 'To delete a conversation, go to the Matches tab, swipe left on the conversation you want to delete, and tap the Delete button.',
    },
    {
      'category': 'Billing',
      'question': 'How do I cancel my subscription?',
      'answer': 'To cancel your subscription, go to your Profile, tap on Premium or Subscription, then select "Manage Subscription" and follow the cancellation process.',
    },
    {
      'category': 'Billing',
      'question': 'When will I be charged?',
      'answer': 'Your subscription will automatically renew and your payment method will be charged at the end of each billing cycle, unless you cancel at least 24 hours before the end of the current period.',
    },
    {
      'category': 'Matching',
      'question': 'How does the matching algorithm work?',
      'answer': 'Our matching algorithm takes into account your preferences, location, interests, and behavior on the app to suggest potential matches that are most likely to be compatible with you.',
    },
    {
      'category': 'Matching',
      'question': 'What is a Super Like?',
      'answer': 'A Super Like lets someone know you\'re really interested in them. When you Super Like someone, they\'ll see a blue star on your profile when you appear in their card stack.',
    },
    {
      'category': 'Safety',
      'question': 'How do I report inappropriate behavior?',
      'answer': 'You can report inappropriate behavior by going to the user\'s profile, tapping the "..." or menu icon, and selecting "Report". You can also report inappropriate messages directly from the chat screen.',
    },
    {
      'category': 'Safety',
      'question': 'How do I block someone?',
      'answer': 'To block someone, go to their profile, tap the "..." or menu icon in the top right, and select "Block". You can manage your blocked users in Privacy & Safety settings.',
    },
    {
      'category': 'Technical',
      'question': 'The app keeps crashing, what should I do?',
      'answer': 'Try the following steps: 1) Restart the app, 2) Update to the latest version, 3) Restart your device, 4) Check your internet connection, 5) Clear the app cache, or 6) Reinstall the app.',
    },
    {
      'category': 'Technical',
      'question': 'How do I enable notifications?',
      'answer': 'Go to your Profile, tap on Notifications, and make sure notifications are turned on. Also check your device settings to ensure notifications are enabled for this app.',
    },
  ];

  // Selected category (null means show all)
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Filter FAQs based on search query and selected category
  List<Map<String, dynamic>> get _filteredFaqs {
    return _faqs.where((faq) {
      // First check category filter
      bool categoryMatch = _selectedCategory == null || faq['category'] == _selectedCategory;

      // Then check search query
      bool searchMatch = _searchQuery.isEmpty ||
          faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();
  }

  // Launch URL helper method
  Future<void> _launchUrl(String url) async {
    try {
      // Simple approach to avoid using the url_launcher package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // In a real app with url_launcher:
      // final Uri uri = Uri.parse(url);
      // if (!await launchUrl(uri)) {
      //   throw Exception('Could not launch $url');
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Show contact support dialog
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a message';
                    }
                    if (value.trim().length < 10) {
                      return 'Message is too short';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          _isSubmittingTicket
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() {
                  _isSubmittingTicket = true;
                });

                // Close the dialog first
                Navigator.pop(context);

                // Simulate sending the ticket
                await Future.delayed(const Duration(seconds: 2));

                setState(() {
                  _isSubmittingTicket = false;
                });

                // Clear the form
                _subjectController.clear();
                _messageController.clear();

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support ticket submitted successfully! We\'ll respond within 24 hours.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: !_isSearching
            ? const Text('Help & Support')
            : TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search FAQs...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: subTextColor),
          ),
          style: TextStyle(color: textColor),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          if (!_isSearching) ...[
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['title'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategory = null; // Deselect
                        } else {
                          _selectedCategory = category['title'];
                        }
                      });
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category['color'].withOpacity(0.2)
                            : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? category['color']
                              : isDarkMode ? Colors.transparent : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            color: category['color'],
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['title'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? category['color'] : textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // FAQ list - using Expanded with ListView for scrolling
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 72,
                    color: subTextColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term or category',
                    style: TextStyle(
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showContactSupportDialog,
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFaqs.length + 2, // +2 for additional content
              itemBuilder: (context, index) {
                // Add contact support section at the top
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.support_agent,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Need more help?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Can\'t find what you\'re looking for? Our support team is here to help you!',
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _showContactSupportDialog,
                              icon: const Icon(Icons.email),
                              label: const Text('Contact Support'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                // Add "Still need help?" section at the bottom
                if (index == _filteredFaqs.length + 1) {
                  return Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Still need help?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.forum,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            'Community Forums',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Connect with other users',
                            style: TextStyle(
                              color: subTextColor,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right, color: subTextColor),
                          onTap: () {
                            // TODO: Navigate to forums or launch URL
                            _launchUrl('https://community.stillapp.com');
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emergency,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            'Safety Center',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Resources for dating safely',
                            style: TextStyle(
                              color: subTextColor,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right, color: subTextColor),
                          onTap: () {
                            // TODO: Navigate to safety center or launch URL
                            _launchUrl('https://safety.stillapp.com');
                          },
                        ),
                      ],
                    ),
                  );
                }

                // Regular FAQ items
                final faqIndex = index - 1; // Adjust for the header
                final faq = _filteredFaqs[faqIndex];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(faq['category']).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(faq['category']),
                        color: _getCategoryColor(faq['category']),
                      ),
                    ),
                    title: Text(
                      faq['question'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      faq['category'],
                      style: TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                    children: [
                      Text(
                        faq['answer'],
                        style: TextStyle(
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Was this helpful?',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up_alt_outlined),
                                color: Colors.green,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Thanks for your feedback!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.thumb_down_alt_outlined),
                                color: Colors.red,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Thanks for your feedback!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    expandedAlignment: Alignment.topLeft,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showContactSupportDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.message),
        tooltip: 'Contact Support',
      ),
    );
  }

  // Helper methods to get category icon and color
  IconData _getCategoryIcon(String category) {
    final categoryData = _categories.firstWhere(
          (cat) => cat['title'] == category,
      orElse: () => {'icon': Icons.help_outline},
    );
    return categoryData['icon'];
  }

  Color _getCategoryColor(String category) {
    final categoryData = _categories.firstWhere(
          (cat) => cat['title'] == category,
      orElse: () => {'color': AppColors.primary},
    );
    return categoryData['color'];
  }
}