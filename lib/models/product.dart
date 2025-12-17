class Product {
  final int? id;
  final String name;
  final int price;
  final int stock;
  final int categoryId;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
  });

  /// Convert Object → Map (untuk SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
    };
  }

  /// Convert Map → Object (dari SQLite)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      categoryId: map['category_id'],
    );
  }
}
