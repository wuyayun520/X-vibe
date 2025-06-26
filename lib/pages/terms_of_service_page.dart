import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'X-vibe Terms of Service',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF24F8D5),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildSection(
              'Last updated: ${DateTime.now().year}',
              'These Terms of Service govern your use of the X-vibe mobile application.',
            ),
            
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using the X-vibe app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our app.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'X-vibe is a mobile application that provides food-related services and content. We reserve the right to modify, suspend, or discontinue any aspect of the service at any time.',
            ),
            
            _buildSection(
              '3. User Accounts',
              'You may be required to create an account to access certain features. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
            ),
            
            _buildSection(
              '4. User Conduct',
              'You agree not to use the service for any unlawful purpose or in any way that could damage, disable, or impair the service. You will not attempt to gain unauthorized access to any part of the service.',
            ),
            
            _buildSection(
              '5. Privacy',
              'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the service, to understand our practices.',
            ),
            
            _buildSection(
              '6. Intellectual Property',
              'The service and its original content, features, and functionality are owned by X-vibe and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.',
            ),
            
            _buildSection(
              '7. Limitation of Liability',
              'In no event shall X-vibe be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
            ),
            
            _buildSection(
              '8. Changes to Terms',
              'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect.',
            ),
            
            _buildSection(
              '9. Contact Us',
              'If you have any questions about these Terms of Service, please contact us at support@xvibe.com',
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