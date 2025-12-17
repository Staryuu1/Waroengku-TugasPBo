import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../services/category_service.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CategoryService _service = CategoryService();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await _service.getAll();
    setState(() => _categories = data);
  }

  void _showForm({Category? category}) {
    final ctrl = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;

              if (category == null) {
                await _service.insert(Category(name: name));
              } else {
                await _service.update(Category(id: category.id, name: name));
              }

              Navigator.pop(context);
              _loadCategories();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _delete(Category category) async {
    await _service.delete(category.id!);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Produk')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _categories.isEmpty
          ? const Center(child: Text('Belum ada kategori'))
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final c = _categories[i];
                return Card(
                  child: ListTile(
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(category: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _delete(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
