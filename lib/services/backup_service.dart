import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  Future<String> _getDatabasePath() async {
    return join(await getDatabasesPath(), 'waroengku.db');
  }

  /// Copies the app database to application's documents/backups folder and
  /// returns the created backup file path.
  Future<String> backupDatabase() async {
    final dbPath = await _getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(docs.path, 'backups'));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = join(backupDir.path, 'waroengku_backup_$timestamp.db');

    final backupFile = await dbFile.copy(backupPath);
    return backupFile.path;
  }

  /// Copies the app database to the given destination path.
  /// Caller is responsible for providing a valid file path (including filename).
  Future<String> backupDatabaseToPath(String destinationPath) async {
    final dbPath = await _getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    final destFile = File(destinationPath);
    // Ensure parent directory exists
    final parent = destFile.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final copied = await dbFile.copy(destinationPath);
    return copied.path;
  }

  /// Replaces the app database with the provided source file path.
  Future<void> restoreDatabaseFromPath(String sourcePath) async {
    final dbPath = await _getDatabasePath();

    // Delete existing db (this closes it as well) before copying
    try {
      await deleteDatabase(dbPath);
    } catch (_) {}

    final src = File(sourcePath);
    if (!await src.exists()) {
      throw Exception('Source backup file not found');
    }

    await src.copy(dbPath);
  }
}
