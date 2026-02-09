import 'package:flutter/material.dart';
import '../../../constants.dart';

class TermsOfServicesScreen extends StatelessWidget {
  const TermsOfServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Service"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: blackColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Terms of Service",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            const SizedBox(height: defaultPadding),
            Text(
              "Last updated: ${DateTime.now().year}",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: blackColor40,
              ),
            ),
            const SizedBox(height: defaultPadding * 2),
            
            _buildSection(
              context,
              "1. Acceptance of Terms",
              "By accessing and using Rituals, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.",
            ),
            
            _buildSection(
              context,
              "2. Use License",
              "Permission is granted to temporarily download one copy of Rituals app per device for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• modify or copy the materials\n• use the materials for any commercial purpose\n• attempt to decompile or reverse engineer any software\n• remove any copyright or other proprietary notations",
            ),
            
            _buildSection(
              context,
              "3. Account Registration",
              "To access certain features of our service, you may be required to create an account. You are responsible for:\n\n• maintaining the confidentiality of your account\n• all activities that occur under your account\n• ensuring that all information provided is accurate and current",
            ),
            
            _buildSection(
              context,
              "4. Privacy Policy",
              "Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our service. By using our service, you agree to the collection and use of information in accordance with our Privacy Policy.",
            ),
            
            _buildSection(
              context,
              "5. Product Information",
              "We strive to ensure that product information on our platform is accurate. However, we do not warrant that product descriptions, pricing, or other content is accurate, complete, reliable, current, or error-free.",
            ),
            
            _buildSection(
              context,
              "6. Orders and Payment",
              "All orders are subject to availability and confirmation of the order price. We reserve the right to refuse any order you place with us. Payment must be received by us before we dispatch your order.",
            ),
            
            _buildSection(
              context,
              "7. Shipping and Delivery",
              "Delivery times are estimates and may vary depending on your location and product availability. We are not responsible for delays caused by shipping carriers or circumstances beyond our control.",
            ),
            
            _buildSection(
              context,
              "8. Returns and Refunds",
              "We offer returns and refunds in accordance with our Return Policy. Items must be returned in their original condition within the specified time frame.",
            ),
            
            _buildSection(
              context,
              "9. Limitation of Liability",
              "In no event shall Rituals or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Rituals's website or app.",
            ),
            
            _buildSection(
              context,
              "10. Governing Law",
              "These terms and conditions are governed by and construed in accordance with the laws of the jurisdiction in which Rituals operates and you irrevocably submit to the exclusive jurisdiction of the courts in that state or location.",
            ),
            
            _buildSection(
              context,
              "11. Changes to Terms",
              "Rituals reserves the right, at its sole discretion, to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect.",
            ),
            
            _buildSection(
              context,
              "12. Contact Information",
              "If you have any questions about these Terms of Service, please contact us at:\n\nEmail: support@Rituals.com\nPhone: +1 (555) 123-4567\nAddress: 123 Commerce Street, Business City, BC 12345",
            ),
            
            const SizedBox(height: defaultPadding * 3),
            
            Center(
              child: Text(
                "Thank you for using Rituals!",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: blackColor,
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: blackColor40,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
