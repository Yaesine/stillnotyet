// lib/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

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
        title: const Text('Privacy Policy'),
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
              'PRIVACY POLICY',
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
              title: 'Introduction',
              content: 'Welcome to Marifecto ("we," "our," or "us"). At Marifecto, we value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.\n\nBy accessing or using Marifecto, you agree to this Privacy Policy. If you do not agree with our policies and practices, please do not use our application.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Information We Collect',
              content: 'We collect several types of information from and about users of our application, including:\n\n'
                  '• Personal Information: Name, email address, telephone number, date of birth, gender, sexual orientation, photos, and biographical information you provide in your profile.\n\n'
                  '• Location Information: With your consent, we collect your precise or approximate location to provide location-based services such as finding potential matches in your area.\n\n'
                  '• Usage Information: Information about your activity on our application, including your interactions with other users (likes, matches, messages), profile views, and app usage statistics.\n\n'
                  '• Device Information: Information about your mobile device including device ID, model, operating system, and browser type.\n\n'
                  '• Photos and Content: Any photos, messages, or other content you upload to the application.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'How We Use Your Information',
              content: 'We use the information we collect about you for various purposes, including to:\n\n'
                  '• Provide, maintain, and improve our services.\n'
                  '• Create and manage your account.\n'
                  '• Process your transactions.\n'
                  '• Connect you with other users based on mutual interests and preferences.\n'
                  '• Send you technical notices, updates, security alerts, and support messages.\n'
                  '• Respond to your comments, questions, and customer service requests.\n'
                  '• Develop new features and services.\n'
                  '• Monitor and analyze trends, usage, and activities.\n'
                  '• Detect, prevent, and address technical issues, fraud, or illegal activities.\n'
                  '• Personalize your experience by delivering content and recommendations.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'How We Share Your Information',
              content: 'We may share your personal information in the following situations:\n\n'
                  '• With Other Users: Your profile information and content you post will be available to other users of the application based on your privacy settings.\n\n'
                  '• With Service Providers: We may share your information with third-party vendors, service providers, and contractors who perform services for us.\n\n'
                  '• For Business Transfers: We may share or transfer your information in connection with a merger, acquisition, reorganization, sale of assets, or bankruptcy.\n\n'
                  '• For Legal Purposes: We may disclose your information to comply with legal obligations, enforce our agreements, and protect our rights or the rights of others.\n\n'
                  '• With Your Consent: We may disclose your personal information for any other purpose with your consent.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Your Privacy Choices',
              content: 'You have several choices regarding your personal information:\n\n'
                  '• Account Information: You can review and update your account information through your profile settings.\n\n'
                  '• Location Information: You can control location permissions through your device settings or in-app settings.\n\n'
                  '• Notifications: You can manage notification preferences in your account settings or device settings.\n\n'
                  '• Profile Visibility: You can control who can see your profile and information through privacy settings.\n\n'
                  '• Account Deletion: You can request to delete your account through the app settings or by contacting our support team.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Data Retention',
              content: 'We store your personal information for as long as your account is active or as needed to provide you services. If you delete your account, we will delete or anonymize your personal information, unless we need to retain certain information for legitimate business purposes or to comply with legal obligations.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Data Security',
              content: 'We implement appropriate technical and organizational measures to protect the security of your personal information. However, please be aware that no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Children\'s Privacy',
              content: 'Our application is not intended for children under 18 years of age. We do not knowingly collect personal information from children under 18. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'International Data Transfers',
              content: 'Your information may be transferred to, stored, and processed in countries other than the one in which you reside. By using our application, you consent to the transfer of your information to countries which may have different data protection rules than your country.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Changes to This Privacy Policy',
              content: 'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Contact Us',
              content: 'If you have any questions about this Privacy Policy, please contact us at:\n\n'
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