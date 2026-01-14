import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import 'login_page.dart';
import '../services/backup_service.dart';
import 'package:file_selector/file_selector.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  bool _working = false;
  final BackupService _backupService = BackupService();

  Future<void> _setSetupCompleteAndGoToLogin() async {
    setState(() => _working = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSetupComplete', true);
    setState(() => _working = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _onCreateAccount() async {
    // Navigate to register page and only complete setup if register succeeded
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );

    if (result == true) {
      // successful register -> mark setup complete and go to login
      await _setSetupCompleteAndGoToLogin();
    } else {
      // registration canceled or failed -> stay on setup
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration not completed')),
      );
    }
  }

  void _onRestoreData() {
    _restoreFlow();
  }

  Future<void> _restoreFlow() async {
    setState(() => _working = true);
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'Database',
        extensions: ['db'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        setState(() => _working = false);
        return; // user canceled
      }

      final filePath = file.path;

      await _backupService.restoreDatabaseFromPath(filePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSetupComplete', true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore berhasil. Aplikasi akan diarahkan ke login.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore gagal: ${e.toString()}')));
      setState(() => _working = false);
    }
  }

  Future<void> _onBackupData() async {
    setState(() => _working = true);
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final suggested = 'waroengku_backup_$timestamp.db';
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'Database',
        extensions: ['db'],
      );

      String? savePath;
      try {
        savePath = await getSavePath(
          suggestedName: suggested,
          acceptedTypeGroups: [typeGroup],
        );
      } catch (e) {
        // Not implemented on some platforms; fallback to internal backup
        savePath = null;
      }

      String path;
      if (savePath != null) {
        path = await _backupService.backupDatabaseToPath(savePath);
      } else {
        path = await _backupService.backupDatabase();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup disimpan: $path')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup gagal: ${e.toString()}')));
    } finally {
      setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup WaroengKu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selamat datang! Sebelum mulai, Anda dapat melakukan salah satu tindakan berikut untuk menyiapkan aplikasi:',
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _working ? null : _onRestoreData,
              icon: const Icon(Icons.restore),
              label: const Text('Restore Data'),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _working ? null : _onBackupData,
              icon: const Icon(Icons.backup),
              label: const Text('Backup Data'),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _working ? null : _onCreateAccount,
              icon: const Icon(Icons.person_add),
              label: const Text('Buat Akun'),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _working ? null : _setSetupCompleteAndGoToLogin,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Lanjut (Lewati)'),
            ),
            const Spacer(),

            if (_working) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
