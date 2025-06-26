import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peach7 Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF24F8D5),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildSection(
              'Last updated: ${DateTime.now().year}',
              'This Privacy Policy describes how Peach7 collects, uses, and protects your information when you use our mobile application.',
            ),
            
            _buildSection(
              '1. Information We Collect',
              'We may collect information you provide directly to us, such as when you create an account, use our services, or contact us for support. This may include your name, email address, and other contact information.',
            ),
            
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to:\n• Provide, maintain, and improve our services\n• Process transactions and send related information\n• Send technical notices and support messages\n• Communicate with you about products, services, and events',
            ),
            
            _buildSection(
              '3. Information Sharing',
              'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this Privacy Policy or as required by law.',
            ),
            
            _buildSection(
              '4. Data Security',
              'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
            ),
            
            _buildSection(
              '5. Data Retention',
              'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required by law.',
            ),
            
            _buildSection(
              '6. Your Rights',
              'You have the right to:\n• Access your personal information\n• Correct inaccurate information\n• Request deletion of your information\n• Object to processing of your information\n• Request data portability',
            ),
            
            _buildSection(
              '7. Cookies and Tracking',
              'Our app may use cookies and similar tracking technologies to enhance your experience. You can control cookie settings through your device settings.',
            ),
            
            _buildSection(
              '8. Children\'s Privacy',
              'Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            ),
            
            _buildSection(
              '9. Changes to Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
            ),
            
            _buildSection(
              '10. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n• Email: privacy@peach7.com\n• Address: Peach7 Privacy Team',
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
} 