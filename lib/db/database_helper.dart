import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'waroengku.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price INTEGER,
            stock INTEGER,
            category_id INTEGER,
            image_path TEXT,
            barcode TEXT UNIQUE
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total INTEGER,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE transaction_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id INTEGER,
            product_id INTEGER,
            price INTEGER,
            qty INTEGER
          )
        ''');
      },
    );
  }

  // Insert User (untuk register)
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  //check jika table user kosong
  Future<bool> isUserTableEmpty() async {
    final db = await database;
    final result = await db.query('users', limit: 1);
    return result.isEmpty; // true jika kosong, false jika ada data
  }

  // Check Login
  Future<User?> login(String username, String password) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  /// Ambil semua kategori (Map nama -> id)
  Future<Map<String, int>> getAllCategoriesAsMap() async {
    final db = await database;
    final result = await db.query('categories');
    final Map<String, int> map = {};
    for (final row in result) {
      map[(row['name'] as String).toLowerCase()] = row['id'] as int;
    }
    return map;
  }

  /// Insert kategori jika belum ada, return id-nya
  Future<int> insertCategoryIfNotExists(String name) async {
    final db = await database;

    // Cek apakah sudah ada (case-insensitive)
    final existing = await db.query(
      'categories',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase().trim()],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    // Belum ada, insert baru
    return await db.insert('categories', {'name': name.trim()});
  }

  /// Bulk insert produk dari excel
  /// Mengembalikan [ImportResult] berisi jumlah sukses, skip, dan error
  Future<ImportResult> bulkInsertProducts(
    List<Map<String, dynamic>> products,
  ) async {
    final db = await database;

    int successCount = 0;
    int skipCount = 0;
    List<String> errors = [];

    for (final product in products) {
      try {
        await db.insert(
          'products',
          product,
          conflictAlgorithm: ConflictAlgorithm.ignore,
          // ignore = skip jika barcode duplikat (UNIQUE constraint)
        );

        // Cek apakah benar-benar diinsert atau di-skip
        if (product['barcode'] != null &&
            (product['barcode'] as String).isNotEmpty) {
          final check = await db.query(
            'products',
            where: 'barcode = ?',
            whereArgs: [product['barcode']],
          );
          if (check.isNotEmpty) {
            successCount++;
          } else {
            skipCount++;
          }
        } else {
          successCount++;
        }
      } catch (e) {
        errors.add('Produk "${product['name']}": $e');
      }
    }

    return ImportResult(
      successCount: successCount,
      skipCount: skipCount,
      errors: errors,
    );
  }

  /// Bulk insert kategori dari excel (sheet Kategori)
  Future<int> bulkInsertCategories(List<String> categoryNames) async {
    int insertedCount = 0;
    for (final name in categoryNames) {
      if (name.trim().isEmpty) continue;
      final db = await database;
      final existing = await db.query(
        'categories',
        where: 'LOWER(name) = ?',
        whereArgs: [name.toLowerCase().trim()],
      );
      if (existing.isEmpty) {
        await db.insert('categories', {'name': name.trim()});
        insertedCount++;
      }
    }
    return insertedCount;
  }
}

/// Model hasil import untuk ditampilkan ke user
class ImportResult {
  final int successCount;
  final int skipCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.skipCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;

  String get summary =>
      '$successCount data berhasil diimport, $skipCount data diskip (duplikat)';
}
