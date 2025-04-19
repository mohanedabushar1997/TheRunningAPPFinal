import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleBody = theme.textTheme.bodyLarge;
    final textStyleHeading = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FitStride Privacy Policy',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', // Placeholder date
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              Text('Your Privacy Matters', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'FitStride is designed with your privacy as a top priority. We believe you should have full control over your personal fitness data. This policy outlines how we handle your information.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text('1. Data Storage: Strictly Local', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'All data you generate while using FitStride, including your profile information (name, gender, height, weight, birth date), workout history, GPS routes, achievements, and settings, is stored exclusively on your device\'s local storage. We utilize secure methods, including database encryption (SQLCipher), to protect this data on your device.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text('2. No External Data Transmission', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'FitStride does NOT transmit any of your personal data, workout details, or usage patterns to any external servers, cloud services, or third parties. Your information stays on your phone.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text(
                '3. Identification: Device ID Only',
                style: textStyleHeading,
              ),
              const SizedBox(height: 12),
              Text(
                'FitStride uses a randomly generated unique identifier (Device ID) stored locally to associate your data with your device. We do not require user accounts, email addresses, or any other personally identifiable information for registration or login. This Device ID is not shared externally.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text(
                '4. Data Backup and Restore: Local Control',
                style: textStyleHeading,
              ),
              const SizedBox(height: 12),
              Text(
                'FitStride provides functionality to back up your application data to a file stored locally on your device (e.g., in your Downloads folder or a location you choose). You are responsible for managing this backup file. You can use this file to restore your data on the same or a different device. This backup process is entirely manual and local; no data is sent to cloud backup services automatically.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text('5. Permissions', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'FitStride requires certain permissions to function correctly:\n'
                '- Location: To track your runs/walks using GPS.\n'
                '- Notifications: To provide workout reminders or alerts (optional).\n'
                '- Storage (Optional): To save backup files or export data if you choose to use these features.\n'
                'These permissions are used solely for the app\'s core functionality on your device.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text('6. Analytics and Tracking', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'FitStride does not include any third-party analytics or tracking libraries. We do not monitor your usage patterns or collect data for advertising or analytical purposes.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text('7. Data Deletion', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'You can delete your profile and associated workout data from within the app settings. This action permanently removes the data from your device\'s local storage.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text('8. Changes to This Policy', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'We may update this privacy policy occasionally. Any changes will be reflected in the app, and the "Last Updated" date will be revised. We encourage you to review this policy periodically.',
                style: textStyleBody,
              ),
              const SizedBox(height: 20),

              Text('Contact Us', style: textStyleHeading),
              const SizedBox(height: 12),
              Text(
                'If you have any questions about this privacy policy, please contact us through the app\'s support channel (if available) or via [Placeholder for Contact Method - e.g., support email if one exists, otherwise remove].',
                style: textStyleBody,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
