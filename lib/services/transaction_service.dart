import '../db/database_helper.dart';


class TransactionService {
  final dbHelper = DatabaseHelper.instance;

  Future<void> saveTransaction(
    int total,
    List<CartItemData> items,
  ) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      // 1️⃣ Insert transaksi
      final trxId = await txn.insert('transactions', {
        'total': total,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2️⃣ Insert detail + kurangi stok
      for (final item in items) {
        await txn.insert('transaction_items', {
          'transaction_id': trxId,
          'product_id': item.productId,
          'price': item.price,
          'qty': item.qty,
        });

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.qty, item.productId],
        );
      }
    });
  }
}

/// DATA SEDERHANA UNTUK CART
class CartItemData {
  final int productId;
  final int price;
  final int qty;

  CartItemData({
    required this.productId,
    required this.price,
    required this.qty,
  });
}
