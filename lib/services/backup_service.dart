import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  Future<String> _getDatabasePath() async {
    return join(await getDatabasesPath(), 'waroengku.db');
  }

  /// Backup database ke /Documents/WaroengKu/
  Future<String> backupDatabaseToDocuments() async {
    final dbPath = await _getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    // 📁 Ambil Documents folder
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('External storage not available');
    }

    // 🔥 Ubah path ke Documents
    final documentsPath = '/storage/emulated/0/Documents/WaroengKu';
    final backupDir = Directory(documentsPath);

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = join(backupDir.path, 'waroengku_backup_$timestamp.db');

    final copied = await dbFile.copy(backupPath);
    return copied.path;
  }

  /// Restore database dari path tertentu
  Future<void> restoreDatabaseFromPath(String sourcePath) async {
    final dbPath = await _getDatabasePath();

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
