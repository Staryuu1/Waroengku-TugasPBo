import '../db/database_helper.dart';
import '../models/reports.dart';

class ReportService {
  /// Get summary of all transactions
  Future<ReportSummary> getSummary() async {
    final db = await DatabaseHelper.instance.database;

    // Get total transactions
    final transactionResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions',
    );
    final totalTransactions = transactionResult.first['count'] as int? ?? 0;

    // Get total items sold and total revenue
    final itemsResult = await db.rawQuery('''
      SELECT 
        SUM(ti.qty) as totalItems,
        SUM(ti.qty * ti.price) as totalRevenue
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
    ''');

    final totalItemsSold = itemsResult.first['totalItems'] as int? ?? 0;
    final totalRevenue = itemsResult.first['totalRevenue'] as int? ?? 0;

    return ReportSummary(
      totalTransactions: totalTransactions,
      totalItemsSold: totalItemsSold,
      totalRevenue: totalRevenue,
    );
  }

  /// Get top products by quantity sold within date range
  Future<List<TopProduct>> getTopProducts(DateTime startDate, DateTime endDate, {int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT 
        p.name as productName,
        SUM(ti.qty) as qtySold,
        SUM(ti.qty * ti.price) as totalRevenue
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      INNER JOIN products p ON ti.product_id = p.id
      WHERE t.created_at BETWEEN ? AND ?
      GROUP BY ti.product_id, p.name
      ORDER BY qtySold DESC
      LIMIT ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String(), limit]);

    return result.map((e) => TopProduct.fromMap(e)).toList();
  }

  /// Get revenue per category
  Future<List<CategoryReport>> getCategoryReport() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(c.name, 'Tanpa Kategori') as categoryName,
        SUM(ti.qty * ti.price) as totalRevenue
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      INNER JOIN products p ON ti.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      GROUP BY c.name
      ORDER BY totalRevenue DESC
    ''');

    return result.map((e) => CategoryReport.fromMap(e)).toList();
  }

  /// Get sales grouped by date within date range
  Future<List<SalesByDate>> getSalesByDate(DateTime startDate, DateTime endDate) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT 
        DATE(t.created_at) as date,
        COUNT(DISTINCT t.id) as transactionCount,
        COALESCE(SUM(ti.qty * ti.price), 0) as totalRevenue
      FROM transactions t
      LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.created_at BETWEEN ? AND ?
      GROUP BY DATE(t.created_at)
      ORDER BY date ASC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return result.map((e) => SalesByDate.fromMap(e)).toList();
  }

  /// Get revenue within specific date range
  Future<int> getRevenueByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.qty * ti.price), 0) as totalRevenue
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return result.first['totalRevenue'] as int? ?? 0;
  }
}