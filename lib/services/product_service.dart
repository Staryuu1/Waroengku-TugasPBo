import '../db/database_helper.dart';
import '../models/product.dart';

class ProductService {
  Future<int> insert(Product product) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('products');
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> update(Product product) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Product?> getByBarcode(String barcode) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

}
