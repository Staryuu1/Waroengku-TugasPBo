import '../db/database_helper.dart';
import '../models/category.dart';
import 'product_service.dart';

class CategoryService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(Category category) async {
    final db = await _db.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final result = await db.query('categories');

    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> update(Category category) async {
    final db = await _db.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    if ( (await ProductService().getByCategoryId(id)).isNotEmpty) {
      return -1;
    }
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
