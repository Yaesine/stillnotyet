// lib/screens/cookie_policy_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CookiePolicyScreen extends StatelessWidget {
  const CookiePolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Cookie Policy'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COOKIE POLICY',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: May 15, 2025',
              style: TextStyle(
                fontSize: 14,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'What Are Cookies',
              content: 'Cookies are small text files that are placed on your device when you visit a website or use a mobile application. They are widely used to make websites and apps work more efficiently and provide information to the owners of the site or app.\n\nIn addition to cookies, we may also use similar technologies such as pixel tags, web beacons, and local storage to collect information about how you use Marifecto and provide features to you.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'How We Use Cookies and Similar Technologies',
              content: 'We use cookies and similar technologies for the following purposes:\n\n'
                  '• Authentication: To recognize you when you sign in to use our services and to keep you logged in.\n\n'
                  '• Security: To help identify and prevent security risks, including detecting and preventing fraudulent activity and protecting user data.\n\n'
                  '• Preferences: To remember information about your browser and your preferences, such as your preferred language or the region you are in.\n\n'
                  '• Analytics: To understand how visitors interact with our application, which helps us improve our service and provide better user experiences. We analyze this information to improve and customize our services.\n\n'
                  '• Performance: To improve how our application functions by monitoring system performance and error reporting.\n\n'
                  '• Advertising: To deliver personalized advertisements on our application and on third-party websites based on your interests and browsing history.\n\n'
                  '• Features and Services: To provide functionality that you have requested, such as enabling you to watch videos, participate in interactive features, and share content on social media platforms.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Types of Cookies We Use',
              content: 'We use the following types of cookies and similar technologies:\n\n'
                  '• Essential Cookies: These cookies are necessary for the application to function and cannot be switched off in our systems. They are usually set in response to actions made by you such as setting your privacy preferences, logging in, or filling in forms.\n\n'
                  '• Preference Cookies: These cookies enable our application to provide enhanced functionality and personalization. They may be set by us or by third-party providers whose services we have added to our pages.\n\n'
                  '• Analytical/Performance Cookies: These cookies allow us to count visits and traffic sources, to measure and improve the performance of our application. They help us know which pages are the most and least popular and see how visitors move around the application.\n\n'
                  '• Marketing Cookies: These cookies are used to track visitors across websites. The intention is to display ads that are relevant and engaging for the individual user.\n\n'
                  '• Session Storage and Local Storage: Similar to cookies, these technologies store information on your device but can store larger amounts of data and are not transferred to the server with each request.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Third-Party Cookies',
              content: 'We may allow third parties to place cookies on your device when you use our application. These third parties include:\n\n'
                  '• Analytics providers (like Google Analytics) that help us understand how our application is being used.\n\n'
                  '• Advertising partners who may use cookies to collect information about your browsing habits and provide you with relevant advertisements on other sites.\n\n'
                  '• Social media platforms that provide features like sharing buttons or login functionality.\n\n'
                  'These third parties may use cookies, pixel tags, and similar technologies to collect information about your use of our application and other websites. This information may be used by these third parties to serve advertisements that are more relevant to your interests.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Mobile Device Identifiers',
              content: 'In our mobile application, we use device identifiers instead of cookies. Device identifiers are small data files stored on your mobile device that uniquely identify your device. Like cookies, device identifiers help us recognize you when you return to our application, measure your engagement with our services, and improve your user experience.\n\n'
                  'We use device identifiers for the same purposes we use cookies, including to remember your preferences, analyze app usage, measure the effectiveness of our marketing campaigns, and personalize content and advertisements.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Your Choices',
              content: 'You have several options to control or limit how we and our partners use cookies and similar technologies:\n\n'
                  '• Mobile Device Settings: You can control device identifiers through your mobile device settings, including to reset your device\'s advertising identifier or opt-out of personalized ads.\n\n'
                  '• App Settings: You can adjust your preferences for certain types of cookies and data collection through the settings in our application.\n\n'
                  '• Third-Party Opt-Outs: Many third parties that use cookies for advertising provide ways to opt out of advertising cookies specifically. Please visit the websites of these third parties to learn more about their privacy and cookie policies.\n\n'
                  'Please note that if you choose to block cookies or similar technologies, some features and services on our application may not work properly.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Updates to This Cookie Policy',
              content: 'We may update this Cookie Policy from time to time to reflect changes in technology, regulation, or our business practices. Any changes will become effective when we post the revised Cookie Policy. If we make any material changes, we will notify you through a notice in the application or by other means as required by applicable law.\n\n'
                  'We encourage you to periodically review this page for the latest information on our cookie practices.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Contact Us',
              content: 'If you have any questions about our use of cookies or this Cookie Policy, please contact us at:\n\n'
                  'Marifecto Inc.\n'
                  'Email: privacy@rankboostads.com\n',
              textColor: textColor,
              cardColor: cardColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color textColor,
    required Color cardColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}