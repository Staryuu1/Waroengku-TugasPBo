class Product {
  final int? id;
  final String name;
  final int price;
  final int stock;
  final int categoryId;
  final String? imagePath;
  final String? barcode;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.imagePath,
    this.barcode,
  });

  /// Convert Object → Map (untuk SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'image_path': imagePath,
      'barcode': barcode,
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
      imagePath: map['image_path'],
      barcode: map['barcode'],
    );
  }
}
