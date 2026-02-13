import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';

class ExcelImportHelper {
  // ─────────────────────────────────────────────
  // NAMA SHEET & KOLOM
  // ─────────────────────────────────────────────
  static const String _sheetKategori = 'Kategori';
  static const String _sheetProduk = 'Produk';

  static const String _colKategoriNama = 'nama_kategori';
  static const String _colNama = 'nama';
  static const String _colHarga = 'harga';
  static const String _colStok = 'stok';
  static const String _colKategori = 'kategori';
  static const String _colBarcode = 'barcode';
  static const String _colImagePath = 'path_gambar';

  // ─────────────────────────────────────────────
  // PICK FILE
  // ─────────────────────────────────────────────

  static Future<String?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single.path;
  }

  // ─────────────────────────────────────────────
  // CORE: PROSES IMPORT
  // ─────────────────────────────────────────────

  static Future<ExcelImportSummary> processImport(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File tidak ditemukan: $filePath');
    }

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    int kategoriInserted = 0;
    final sheetNames = excel.tables.keys.toList();

    if (sheetNames.contains(_sheetKategori)) {
      final kategoriNames = _parseKategoriSheet(excel.tables[_sheetKategori]!);
      kategoriInserted = await DatabaseHelper.instance.bulkInsertCategories(
        kategoriNames,
      );
    }

    ImportResult? produkResult;

    if (sheetNames.contains(_sheetProduk)) {
      final produkList = await _parseProdukSheet(excel.tables[_sheetProduk]!);
      produkResult = await DatabaseHelper.instance.bulkInsertProducts(
        produkList,
      );
    } else {
      throw Exception(
        'Sheet "$_sheetProduk" tidak ditemukan.\nPastikan nama sheet sudah benar.',
      );
    }

    return ExcelImportSummary(
      kategoriInserted: kategoriInserted,
      produkResult: produkResult!,
    );
  }

  // ─────────────────────────────────────────────
  // PARSER: Sheet Kategori
  // ─────────────────────────────────────────────

  static List<String> _parseKategoriSheet(Sheet sheet) {
    final List<String> names = [];
    final rows = sheet.rows;
    if (rows.isEmpty) return names;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final nama = _cellToString(row.isNotEmpty ? row[0] : null);
      if (nama.isNotEmpty) names.add(nama);
    }
    return names;
  }

  // ─────────────────────────────────────────────
  // PARSER: Sheet Produk
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _parseProdukSheet(
    Sheet sheet,
  ) async {
    final List<Map<String, dynamic>> products = [];
    final rows = sheet.rows;
    if (rows.isEmpty) return products;

    final headerRow = rows[0];
    final Map<String, int> headerIndex = {};

    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value != null) {
        headerIndex[cell!.value.toString().toLowerCase().trim()] = i;
      }
    }

    _validateHeaders(headerIndex);

    final existingCategories = await DatabaseHelper.instance
        .getAllCategoriesAsMap();

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isRowEmpty(row)) continue;

      final nama = _getStringFromRow(row, headerIndex, _colNama);
      final hargaStr = _getStringFromRow(row, headerIndex, _colHarga);
      final stokStr = _getStringFromRow(row, headerIndex, _colStok);
      final kategoriName = _getStringFromRow(row, headerIndex, _colKategori);
      final barcode = _getStringFromRow(row, headerIndex, _colBarcode);
      final imagePath = _getStringFromRow(row, headerIndex, _colImagePath);

      if (nama.isEmpty) continue;

      int? categoryId;
      if (kategoriName.isNotEmpty) {
        final key = kategoriName.toLowerCase();
        if (existingCategories.containsKey(key)) {
          categoryId = existingCategories[key];
        } else {
          categoryId = await DatabaseHelper.instance.insertCategoryIfNotExists(
            kategoriName,
          );
          existingCategories[key] = categoryId;
        }
      }

      products.add({
        'name': nama,
        'price': int.tryParse(hargaStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        'stock': int.tryParse(stokStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        'category_id': categoryId,
        'barcode': barcode.isEmpty ? null : barcode,
        'image_path': imagePath.isEmpty ? null : imagePath,
      });
    }

    return products;
  }

  // ─────────────────────────────────────────────
  // GENERATE TEMPLATE — border rapi + save ke Downloads
  // ─────────────────────────────────────────────

  static Future<String> generateAndShareTemplate() async {
    final excel = Excel.createExcel();

    // ── Style helpers ──
    CellStyle headerStyle() => CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#1B5E20'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#1B5E20'),
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#1B5E20'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#1B5E20'),
      ),
    );

    CellStyle dataStyle({bool isAlt = false}) => CellStyle(
      backgroundColorHex: ExcelColor.fromHexString(
        isAlt ? '#F1F8E9' : '#FFFFFF',
      ),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#A5D6A7'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#A5D6A7'),
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#A5D6A7'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#A5D6A7'),
      ),
    );

    // ── Sheet Kategori ──
    final sheetKategori = excel[_sheetKategori];
    sheetKategori.setColumnWidth(0, 30);

    final headerKat = sheetKategori.cell(CellIndex.indexByString('A1'));
    headerKat.value = TextCellValue('nama_kategori');
    headerKat.cellStyle = headerStyle();

    final kategoriData = ['Makanan', 'Minuman', 'Snack'];
    for (int i = 0; i < kategoriData.length; i++) {
      final cell = sheetKategori.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1),
      );
      cell.value = TextCellValue(kategoriData[i]);
      cell.cellStyle = dataStyle(isAlt: i.isOdd);
    }

    // ── Sheet Produk ──
    final sheetProduk = excel[_sheetProduk];

    final colWidths = [28.0, 15.0, 10.0, 20.0, 20.0, 25.0];
    for (int i = 0; i < colWidths.length; i++) {
      sheetProduk.setColumnWidth(i, colWidths[i]);
    }

    final headers = [
      'nama',
      'harga',
      'stok',
      'kategori',
      'barcode',
      'path_gambar',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheetProduk.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle();
    }

    final row1 = [
      TextCellValue('Nasi Goreng'),
      IntCellValue(15000),
      IntCellValue(10),
      TextCellValue('Makanan'),
      TextCellValue('8991234567890'),
      TextCellValue(''),
    ];
    for (int i = 0; i < row1.length; i++) {
      final cell = sheetProduk.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
      );
      cell.value = row1[i];
      cell.cellStyle = dataStyle(isAlt: false);
    }

    final row2 = [
      TextCellValue('Es Teh Manis'),
      IntCellValue(5000),
      IntCellValue(50),
      TextCellValue('Minuman'),
      TextCellValue('8997654321098'),
      TextCellValue(''),
    ];
    for (int i = 0; i < row2.length; i++) {
      final cell = sheetProduk.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
      );
      cell.value = row2[i];
      cell.cellStyle = dataStyle(isAlt: true);
    }

    if (excel.tables.containsKey('Sheet1')) excel.delete('Sheet1');
    excel.setDefaultSheet(_sheetKategori);

    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Gagal membuat file template');

    // ── Simpan ke Downloads (Android) atau temp (iOS) ──
    String savedPath;
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        savedPath = '${downloadsDir.path}/template_import_waroengku.xlsx';
      } else {
        final dir =
            await getExternalStorageDirectory() ??
            await getTemporaryDirectory();
        savedPath = '${dir.path}/template_import_waroengku.xlsx';
      }
    } catch (_) {
      final dir = await getTemporaryDirectory();
      savedPath = '${dir.path}/template_import_waroengku.xlsx';
    }

    await File(savedPath).writeAsBytes(fileBytes);

    // Share sheet agar user iOS bisa pilih lokasi simpan
    await Share.shareXFiles([
      XFile(savedPath),
    ], subject: 'Template Import Waroengku');

    return savedPath;
  }

  // ─────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────

  static void _validateHeaders(Map<String, int> headerIndex) {
    final requiredColumns = [_colNama, _colHarga, _colStok, _colKategori];
    final missing = <String>[];
    for (final col in requiredColumns) {
      if (!headerIndex.containsKey(col)) missing.add(col);
    }
    if (missing.isNotEmpty) {
      throw Exception(
        'Kolom wajib tidak ditemukan di sheet "$_sheetProduk":\n'
        '${missing.join(', ')}\n\n'
        'Download template terlebih dahulu untuk format yang benar.',
      );
    }
  }

  static String _cellToString(Data? cell) {
    if (cell?.value == null) return '';
    return cell!.value.toString().trim();
  }

  static String _getStringFromRow(
    List<Data?> row,
    Map<String, int> headerIndex,
    String colName,
  ) {
    final idx = headerIndex[colName];
    if (idx == null || idx >= row.length) return '';
    return _cellToString(row[idx]);
  }

  static bool _isRowEmpty(List<Data?> row) {
    return row.every(
      (cell) => cell?.value == null || cell!.value.toString().trim().isEmpty,
    );
  }
}

// ─────────────────────────────────────────────
// SUMMARY MODEL
// ─────────────────────────────────────────────

class ExcelImportSummary {
  final int kategoriInserted;
  final ImportResult produkResult;

  ExcelImportSummary({
    required this.kategoriInserted,
    required this.produkResult,
  });

  String get fullSummary {
    final buffer = StringBuffer();
    if (kategoriInserted > 0) {
      buffer.writeln('✅ $kategoriInserted kategori baru ditambahkan');
    }
    buffer.writeln('✅ ${produkResult.successCount} produk berhasil diimport');
    if (produkResult.skipCount > 0) {
      buffer.writeln(
        '⚠️ ${produkResult.skipCount} produk diskip (barcode duplikat)',
      );
    }
    if (produkResult.hasErrors) {
      buffer.writeln('❌ ${produkResult.errors.length} produk gagal:');
      for (final err in produkResult.errors) {
        buffer.writeln('   • $err');
      }
    }
    return buffer.toString().trim();
  }

  bool get hasErrors => produkResult.hasErrors;
}
