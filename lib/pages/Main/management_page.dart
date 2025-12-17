import 'package:flutter/material.dart';
import './SubPages/category_pages.dart';
import './SubPages/product_page.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  Widget _menuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _menuCard(
          context: context,
          title: 'Kategori Produk',
          icon: Icons.category,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            );
          },
        ),
        _menuCard(
          context: context,
          title: 'Produk',
          icon: Icons.inventory_2,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductPage()),
            );
          },
        ),
      ],
    );
  }
}
