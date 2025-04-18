import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart'; // For date formatting in backup filename

class BackupService {
  static const String _dbName = 'fitstride.db';
  static const String _backupFolderName = 'FitStrideBackups';

  // Get the path to the main database file
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _dbName);
  }

  // Get the directory where backups will be stored
  Future<Directory> getBackupDirectory() async {
    // Using external storage directory for easier user access/management
    // Note: Requires appropriate permissions (e.g., MANAGE_EXTERNAL_STORAGE or scoped storage access)
    // Consider using getExternalStorageDirectories(type: StorageDirectory.documents) for more options
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      // Fallback to application documents directory if external storage is unavailable
      print(
        "External storage not available, using application documents directory for backups.",
      );
      externalDir = await getApplicationDocumentsDirectory();
    }
    final backupPath = join(externalDir.path, _backupFolderName);
    final backupDir = Directory(backupPath);
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      print("Created backup directory: ${backupDir.path}");
    }
    return backupDir;
  }

  // Create a backup of the current database
  Future<File?> createBackup() async {
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        print("Database file not found at $dbPath. Cannot create backup.");
        return null;
      }

      final backupDir = await getBackupDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'fitstride_backup_$timestamp.db';
      final backupFilePath = join(backupDir.path, backupFileName);
      final backupFile = File(backupFilePath);

      // Copy the database file to the backup location
      await dbFile.copy(backupFilePath);

      print("Database backup created successfully at: ${backupFile.path}");
      return backupFile;
    } catch (e) {
      print("Error creating database backup: $e");
      return null;
    }
  }

  // List available backup files
  Future<List<File>> listBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final files =
          backupDir.listSync().whereType<File>().where((file) {
            return basename(file.path).startsWith('fitstride_backup_') &&
                basename(file.path).endsWith('.db');
          }).toList();

      // Sort by date descending (newest first)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      print("Found ${files.length} backup files.");
      return files;
    } catch (e) {
      print("Error listing backup files: $e");
      return [];
    }
  }

  // Restore the database from a specific backup file
  // WARNING: This overwrites the current database. Ensure the database is closed first.
  Future<bool> restoreFromBackup(File backupFile) async {
    try {
      if (!await backupFile.exists()) {
        print("Backup file not found: ${backupFile.path}");
        return false;
      }

      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);

      // TODO: Ensure the database connection is closed before restoring
      // This might involve coordinating with DatabaseHelper or StorageService
      // Example: await DatabaseHelper().close();

      // Copy the backup file to the database location, overwriting the existing one
      await backupFile.copy(dbPath);

      print("Database restored successfully from: ${backupFile.path}");
      // TODO: Re-initialize the database connection after restore
      // Example: await DatabaseHelper().database; // Re-opens the DB

      return true;
    } catch (e) {
      print("Error restoring database from backup: $e");
      return false;
    }
  }

  // Delete a specific backup file
  Future<bool> deleteBackup(File backupFile) async {
    try {
      if (await backupFile.exists()) {
        await backupFile.delete();
        print("Deleted backup file: ${backupFile.path}");
        return true;
      } else {
        print("Backup file not found for deletion: ${backupFile.path}");
        return false;
      }
    } catch (e) {
      print("Error deleting backup file: $e");
      return false;
    }
  }

  // TODO: Implement automated backup schedule (Task 9.2.2)
  // TODO: Implement backup integrity verification (Task 9.2.7)
}
