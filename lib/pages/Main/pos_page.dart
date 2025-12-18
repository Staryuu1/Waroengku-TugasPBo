import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';

/// =======================
/// CART ITEM
/// =======================
class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  int get subtotal => product.price * qty;
}

/// =======================
/// POS PAGE
/// =======================
class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final TransactionService _transactionService = TransactionService();

  List<Product> _products = [];
  List<Category> _categories = [];
  Category? _selectedCategory;

  final List<CartItem> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    _categories = await _categoryService.getAll();
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final all = await _productService.getAll();

    if (_selectedCategory == null) {
      _products = all;
    } else {
      _products = all
          .where((p) => p.categoryId == _selectedCategory!.id)
          .toList();
    }

    setState(() {});
  }

  /// =======================
  /// CART LOGIC
  /// =======================
  void _addToCart(Product product) {
    final index = _cart.indexWhere((e) => e.product.id == product.id);

    if (index >= 0) {
      if (_cart[index].qty < product.stock) {
        _cart[index].qty++;
      }
    } else {
      if (product.stock > 0) {
        _cart.add(CartItem(product: product));
      }
    }
    setState(() {});
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      if (item.qty > 1) {
        item.qty--;
      } else {
        _cart.remove(item);
      }
    });
  }

  int get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  String _format(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  /// =======================
  /// PAYMENT + CHANGE UI
  /// =======================
  void _pay() {
    final payCtrl = TextEditingController();
    int paid = 0;
    int change = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _row('Total', 'Rp ${_format(_total)}', bold: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: payCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Uang Dibayar',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (v) {
                  paid = int.tryParse(v) ?? 0;
                  change = paid - _total;
                  setDialog(() {});
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: change >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: change >= 0 ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: _row(
                  'Kembalian',
                  change >= 0 ? 'Rp ${_format(change)}' : 'Uang Kurang',
                  color: change >= 0 ? Colors.green : Colors.red,
                  bold: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: change < 0
                  ? null
                  : () async {
                      final items = _cart
                          .map(
                            (e) => CartItemData(
                              productId: e.product.id!,
                              price: e.product.price,
                              qty: e.qty,
                            ),
                          )
                          .toList();

                      await _transactionService.saveTransaction(
                        _total,
                        items,
                      );

                      Navigator.pop(context);
                      setState(() => _cart.clear());
                      await _loadProducts();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Transaksi berhasil • Kembalian Rp ${_format(change)}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                'KONFIRMASI',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : null,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// =======================
  /// BARCODE
  /// =======================
  void _scanBarcode() {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (scannerContext) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Scan Barcode'),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          body: Stack(
            children: [
              /// =======================
              /// CAMERA
              /// =======================
              MobileScanner(
                controller: controller,
                onDetect: (capture) async {
                  final code = capture.barcodes.first.rawValue;
                  if (code == null) return;

                  // ⛔ STOP CAMERA DULU
                  await controller.stop();

                  final product =
                      await _productService.getByBarcode(code);

                  if (!scannerContext.mounted) return;
                  Navigator.pop(scannerContext);

                  if (product == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Produk tidak ditemukan'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  _addToCart(product);
                },
              ),

              /// =======================
              /// FRAME SCAN
              /// =======================
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 3,
                    ),
                  ),
                ),
              ),

              /// =======================
              /// TEXT BAWAH
              /// =======================
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Arahkan kamera ke barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // 🧹 CLEANUP
      controller.dispose();
    });
  }

  /// =======================
  /// UI
  /// =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: Column(
        children: [
          /// FILTER KATEGORI & SCAN BARCODE
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Filter Kategori',
                      prefixIcon: const Icon(Icons.filter_list),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Kategori'),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _selectedCategory = v;
                      _loadProducts();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    onPressed: _scanBarcode,
                    iconSize: 28,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          /// PRODUK
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada produk',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _products.length,
                      itemBuilder: (_, i) {
                        final p = _products[i];
                        final inStock = p.stock > 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p.imagePath != null
                                    ? Image.file(
                                        File(p.imagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.grey[400],
                                      ),
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Text(
                                    'Rp ${_format(p.price)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.inventory_outlined,
                                    size: 14,
                                    color: inStock ? Colors.grey[600] : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p.stock}',
                                    style: TextStyle(
                                      color: inStock ? Colors.grey[600] : Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: inStock ? const Color(0xFF4CAF50) : Colors.grey,
                                size: 32,
                              ),
                              onPressed: inStock ? () => _addToCart(p) : null,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          Container(
            height: 1,
            color: Colors.grey[300],
          ),

          /// CART
          Expanded(
            child: Container(
              color: Colors.white,
              child: _cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keranjang kosong',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _cart.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = _cart[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.qty} x Rp ${_format(item.product.price)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      color: Colors.red,
                                      onPressed: () => _removeFromCart(item),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      color: Colors.green,
                                      onPressed: item.qty < item.product.stock
                                          ? () {
                                              setState(() {
                                                item.qty++;
                                              });
                                            }
                                          : null,
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Rp ${_format(item.subtotal)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          /// TOTAL BAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_format(_total)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _cart.isEmpty ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.payment, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'BAYAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}