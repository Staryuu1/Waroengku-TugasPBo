import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import 'package:file_selector/file_selector.dart';
import 'login_page.dart';
import './Main/management_page.dart';
import './Main/pos_page.dart';
import 'Main/reports_pages.dart';

class MainPage extends StatefulWidget {
  final User user;

  const MainPage({super.key, required this.user});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [ManagementPage(), POSPage(), ReportsPage()];
  }

  final BackupService _backupService = BackupService();
  bool _busy = false;

  Future<void> _backupData() async {
    setState(() => _busy = true);
    try {
      final path = await _backupService.backupDatabaseToDocuments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup disimpan di:\n$path'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup gagal: ${e.toString()}')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _restoreData() async {
    setState(() => _busy = true);
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'Database',
        extensions: ['db'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      await _backupService.restoreDatabaseFromPath(file.path);

      // After restore, force logout so user can login to restored DB
      await AuthService().logout();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore berhasil, silakan login ulang.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore gagal: ${e.toString()}')));
    } finally {
      setState(() => _busy = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Keluar Aplikasi?'),
          ],
        ),
        content: const Text('Anda akan keluar dari akun Anda'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan warna untuk setiap tab
    final List<Color> tabColors = [
      const Color(0xFF6C63FF), // Management - Purple
      const Color(0xFF4CAF50), // Cashier - Green
      const Color(0xFFFF6584), // Reports - Pink
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: tabColors[_selectedIndex],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _selectedIndex == 0
                    ? Icons.inventory_2
                    : _selectedIndex == 1
                    ? Icons.store
                    : Icons.bar_chart,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, ${widget.user.username}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _selectedIndex == 0
                        ? 'Management'
                        : _selectedIndex == 1
                        ? 'Kasir'
                        : 'Laporan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'backup') {
                _backupData();
              } else if (value == 'restore') {
                _restoreData();
              } else if (value == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'backup', child: Text('Backup Data')),
              const PopupMenuItem(
                value: 'restore',
                child: Text('Restore Data'),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: tabColors[_selectedIndex],
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Management',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Kasir',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}
