class ReportSummary {
  final int totalTransactions;
  final int totalItemsSold;
  final int totalRevenue;

  ReportSummary({
    required this.totalTransactions,
    required this.totalItemsSold,
    required this.totalRevenue,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalTransactions': totalTransactions,
      'totalItemsSold': totalItemsSold,
      'totalRevenue': totalRevenue,
    };
  }

  factory ReportSummary.fromMap(Map<String, dynamic> map) {
    return ReportSummary(
      totalTransactions: map['totalTransactions'] ?? 0,
      totalItemsSold: map['totalItemsSold'] ?? 0,
      totalRevenue: map['totalRevenue'] ?? 0,
    );
  }
}

class TopProduct {
  final String productName;
  final int qtySold;
  final int totalRevenue;

  TopProduct({
    required this.productName,
    required this.qtySold,
    required this.totalRevenue,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'qtySold': qtySold,
      'totalRevenue': totalRevenue,
    };
  }

  factory TopProduct.fromMap(Map<String, dynamic> map) {
    return TopProduct(
      productName: map['productName'] ?? '',
      qtySold: map['qtySold'] ?? 0,
      totalRevenue: map['totalRevenue'] ?? 0,
    );
  }
}

class CategoryReport {
  final String categoryName;
  final int totalRevenue;

  CategoryReport({
    required this.categoryName,
    required this.totalRevenue,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'totalRevenue': totalRevenue,
    };
  }

  factory CategoryReport.fromMap(Map<String, dynamic> map) {
    return CategoryReport(
      categoryName: map['categoryName'] ?? '',
      totalRevenue: map['totalRevenue'] ?? 0,
    );
  }
}

class SalesByDate {
  final DateTime date;
  final int transactionCount;
  final int totalRevenue;

  SalesByDate({
    required this.date,
    required this.transactionCount,
    required this.totalRevenue,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'transactionCount': transactionCount,
      'totalRevenue': totalRevenue,
    };
  }

  factory SalesByDate.fromMap(Map<String, dynamic> map) {
    return SalesByDate(
      date: DateTime.parse(map['date']),
      transactionCount: map['transactionCount'] ?? 0,
      totalRevenue: map['totalRevenue'] ?? 0,
    );
  }
}
