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
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _onCreateAccount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );

    if (result == true) {
      await _setSetupCompleteAndGoToLogin();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi tidak selesai')),
        );
      }
    }
  }

  Future<void> _onRestoreData() async {
    setState(() => _working = true);
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'Database',
        extensions: ['db'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        setState(() => _working = false);
        return;
      }

      final filePath = file.path;
      await _backupService.restoreDatabaseFromPath(filePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSetupComplete', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Restore berhasil. Aplikasi akan diarahkan ke login.',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore gagal: ${e.toString()}')),
        );
      }
      setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo di kiri atas (PNG)
              Image.asset(
                'assets/images/Logo_text.png',
                height: 60,
                fit: BoxFit.contain,
              ),

              const Spacer(),

              // Ilustrasi karakter (GIF)
              Center(
                child: Column(
                  children: [
                    // GIF Illustration
                    Image.asset(
                      'assets/images/burnice-burnice-go.gif',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),

                    // Text - rata kiri dan lebih besar
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Siap untuk memulai?',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Kelola lebih cepat',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'Tumbuh lebih jauh',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Buttons
              Row(
                children: [
                  // Import Data button - Hijau
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _working ? null : _onRestoreData,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFF3DDC84),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Import Data',
                        style: TextStyle(
                          color: Color(0xFF3DDC84),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Buat Akun button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _working ? null : _onCreateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5BE5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Buat Akun',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Loading indicator
              if (_working)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
