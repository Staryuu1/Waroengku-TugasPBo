import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';


class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text("Dashboard WaroengKu"),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await AuthService().logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        )
      ],
    ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _menuButton(
              context,
              title: "Management",
              icon: Icons.inventory,
              onTap: () {
                // nanti ke halaman management
              },
            ),
            _menuButton(
              context,
              title: "Transaksi (POS)",
              icon: Icons.point_of_sale,
              onTap: () {
                // nanti ke POS
              },
            ),
            _menuButton(
              context,
              title: "Reports",
              icon: Icons.bar_chart,
              onTap: () {
                // nanti ke laporan
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
