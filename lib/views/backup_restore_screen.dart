import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/custom_snackbar.dart'; // Import snackbar helpers

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _lastBackupDate; // TODO: Get last backup date from service/prefs

  // TODO: Instantiate or get BackupService instance
  // final BackupService _backupService = BackupService(); // Or get from Provider

  Future<void> _performBackup() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Confirm Backup',
      content: const Text(
        'This will create a local backup file of your workout data, profile, and settings. Store this file securely.',
      ),
      confirmText: 'Backup Now',
    );

    if (confirmed == true) {
      setState(() => _isBackingUp = true);
      try {
        // TODO: Implement actual backup logic in BackupService
        // final success = await _backupService.backupData();
        await Future.delayed(const Duration(seconds: 2)); // Simulate backup
        const success = true; // Placeholder

        if (mounted) {
          if (success) {
            showAppSnackBar(context, 'Backup created successfully!');
            // TODO: Update last backup date display
          } else {
            showErrorSnackBar(context, 'Backup failed. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(context, 'Backup error: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isBackingUp = false);
        }
      }
    }
  }

  Future<void> _performRestore() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Confirm Restore',
      content: const Text(
        'Restoring from a backup will OVERWRITE your current data. This action cannot be undone. Ensure you select a valid backup file.',
      ),
      confirmText: 'Restore Data',
    );

    if (confirmed == true) {
      setState(() => _isRestoring = true);
      try {
        // TODO: Implement actual restore logic in BackupService (likely involves file picker)
        // final success = await _backupService.restoreData();
        await Future.delayed(const Duration(seconds: 3)); // Simulate restore
        const success = true; // Placeholder

        if (mounted) {
          if (success) {
            showAppSnackBar(
              context,
              'Data restored successfully! Restarting app...',
            );
            // TODO: Trigger app restart or reload all providers/data
          } else {
            showErrorSnackBar(
              context,
              'Restore failed. Invalid file or error occurred.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(context, 'Restore error: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isRestoring = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Local Data Backup', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create a local backup file of your FitStride data (workouts, profile, settings). Store this file safely, as it\'s the only way to recover your data if you reinstall the app or switch devices.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Last Backup Info (Placeholder)
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Last Backup'),
                subtitle: Text(_lastBackupDate ?? 'No backup created yet'),
              ),
            ),
            const SizedBox(height: 24),

            // Backup Button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: _isBackingUp ? 'Backing Up...' : 'Create Backup File',
                // icon: Icons.cloud_upload, // PrimaryButton doesn't take icon
                onPressed: _isBackingUp || _isRestoring ? null : _performBackup,
              ),
            ),
            const SizedBox(height: 32),

            Text('Restore from Backup', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Restore your data from a previously created backup file. WARNING: This will overwrite all current data in the app.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Restore Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Use ElevatedButton for visual distinction
                icon: const Icon(Icons.cloud_download), // Restore icon
                label: Text(
                  _isRestoring ? 'Restoring...' : 'Restore from File',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.secondary, // Use secondary color
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed:
                    _isRestoring || _isBackingUp ? null : _performRestore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
