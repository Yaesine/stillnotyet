// lib/screens/terms_of_service_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

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
        title: const Text('Terms of Service'),
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
              'TERMS OF SERVICE',
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
              title: 'Agreement to Terms',
              content: 'By accessing or using the Marifecto mobile application, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this application.\n\nThese Terms of Service apply to all users of the application, including without limitation users who are browsers, vendors, customers, merchants, and/or contributors of content.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Eligibility',
              content: 'You must be at least 18 years old to create an account on Marifecto and use the Service. By creating an account and using the Service, you represent and warrant that:\n\n'
                  '• You are at least 18 years old.\n'
                  '• You can form a binding contract with Marifecto.\n'
                  '• You are not a person who is barred from using the Service under the laws of any applicable jurisdiction.\n'
                  '• You will comply with these Terms of Service and all applicable local, state, national, and international laws, rules, and regulations.\n'
                  '• You have never been convicted of or pled no contest to a felony, a sex crime, or any crime involving violence or a threat of violence, and that you are not required to register as a sex offender with any state, federal, or local sex offender registry.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Your Account',
              content: 'When you create an account with us, you must provide accurate, complete, and current information. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account.\n\n'
                  'You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password. You agree not to disclose your password to any third party. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.\n\n'
                  'You may not use as a username the name of another person or entity or that is not lawfully available for use, a name or trademark that is subject to any rights of another person or entity without appropriate authorization, or a name that is offensive, vulgar, or obscene.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'User Content',
              content: 'Our Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material ("Content"). You are responsible for the Content that you post on or through the Service, including its legality, reliability, and appropriateness.\n\n'
                  'By posting Content on or through the Service, you represent and warrant that:\n\n'
                  '• The Content is yours (you own it) or you have the right to use it and grant us the rights and license as provided in these Terms.\n'
                  '• The posting of your Content on or through the Service does not violate the privacy rights, publicity rights, copyrights, contract rights or any other rights of any person.\n'
                  '• Your Content does not contain any viruses, adware, spyware, worms, or other malicious code.\n\n'
                  'We reserve the right to terminate the account of any user found to be infringing on a copyright or any other intellectual property rights.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Prohibited Activities',
              content: 'You may not access or use the Service for any purpose other than that for which we make the Service available. The Service may not be used in connection with any commercial endeavors except those that are specifically endorsed or approved by us.\n\n'
                  'As a user of the Service, you agree not to:\n\n'
                  '• Use the Service to harass, abuse, or harm another person, or in a way that is threatening, obscene, or defamatory.\n'
                  '• Use the Service for any illegal purpose, or in violation of any local, state, national, or international law.\n'
                  '• Impersonate any person or entity, or falsely state or otherwise misrepresent your affiliation with a person or entity.\n'
                  '• Interfere with or disrupt the Service or servers or networks connected to the Service.\n'
                  '• Attempt to bypass any measures of the Service designed to prevent or restrict access.\n'
                  '• Introduce any viruses, trojan horses, worms, logic bombs, or other harmful material.\n'
                  '• Use the Service to send automated messages, spam, or unsolicited communications.\n'
                  '• Use the Service to collect or harvest personal data about other users.\n'
                  '• Create multiple accounts for disruptive or abusive purposes.\n'
                  '• Use the Service for any commercial solicitation purposes without our prior written consent.\n'
                  '• Post or transmit any content that is unlawful, fraudulent, or violates the rights of others.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Subscriptions and Purchases',
              content: 'Some features of the Service require payment of fees. If you choose to purchase premium features or subscriptions, you agree to pay all applicable fees as described at the time of purchase.\n\n'
                  'All purchases are final and non-refundable, except as required by applicable law or at our sole discretion. We may change the fees for premium features or subscriptions at any time with reasonable notice posted in advance.\n\n'
                  'You are responsible for all charges incurred under your account, including applicable taxes, and all purchases made by you or anyone using your account.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Intellectual Property',
              content: 'The Service and its original content (excluding Content provided by users), features, and functionality are and will remain the exclusive property of Marifecto and its licensors. The Service is protected by copyright, trademark, and other laws of the United Arab Emirates and foreign countries.\n\n'
                  'Our trademarks and trade dress may not be used in connection with any product or service without the prior written consent of Marifecto.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Termination',
              content: 'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.\n\n'
                  'Upon termination, your right to use the Service will immediately cease. If you wish to terminate your account, you may simply discontinue using the Service or delete your account through the application settings.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Limitation of Liability',
              content: 'In no event shall Marifecto, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from:\n\n'
                  '• Your access to or use of or inability to access or use the Service.\n'
                  '• Any conduct or content of any third party on the Service.\n'
                  '• Any content obtained from the Service.\n'
                  '• Unauthorized access, use, or alteration of your transmissions or content.\n\n'
                  'To the maximum extent permitted by applicable law, Marifecto assumes no liability or responsibility for any errors, mistakes, or inaccuracies of content; personal injury or property damage, of any nature whatsoever, resulting from your access to and use of our service; and any unauthorized access to or use of our secure servers and/or any personal information stored therein.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Disclaimer',
              content: 'Your use of the Service is at your sole risk. The Service is provided on an "AS IS" and "AS AVAILABLE" basis. The Service is provided without warranties of any kind, whether express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement, or course of performance.\n\n'
                  'Marifecto, its subsidiaries, affiliates, and licensors do not warrant that:\n\n'
                  '• The Service will function uninterrupted, secure, or available at any particular time or location.\n'
                  '• Any errors or defects will be corrected.\n'
                  '• The Service is free of viruses or other harmful components.\n'
                  '• The results of using the Service will meet your requirements.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Governing Law',
              content: 'These Terms shall be governed and construed in accordance with the laws of the United Arab Emirates, without regard to its conflict of law provisions.\n\n'
                  'Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights. If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions of these Terms will remain in effect.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Changes to Terms',
              content: 'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days\' notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.\n\n'
                  'By continuing to access or use our Service after those revisions become effective, you agree to be bound by the revised terms. If you do not agree to the new terms, please stop using the Service.',
              textColor: textColor,
              cardColor: cardColor,
            ),
            _buildSection(
              title: 'Contact Us',
              content: 'If you have any questions about these Terms, please contact us at:\n\n'
                  'Marifecto Inc.\n'
                  'Email: legal@rankboostads.com\n',
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