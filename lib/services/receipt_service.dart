import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

/// =====================
/// MODEL ITEM STRUK
/// =====================
class ReceiptItem {
  final String name;
  final int price;
  final int qty;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.qty,
  });

  int get subtotal => price * qty;
}

/// =====================
/// SERVICE STRUK (PDF)
/// =====================
class ReceiptService {
  /// BUILD PDF
  static Future<pw.Document> _buildPdf({
    required int total,
    required int paid,
    required int change,
    required List<ReceiptItem> items,
  }) async {
    final pdf = pw.Document();
    final format = NumberFormat('#,###', 'id_ID');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'WAROENGKU',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Divider(),

              ...items.map(
                (e) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${e.name} x${e.qty}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      format.format(e.subtotal),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.Divider(),
              _row('Total', format.format(total)),
              _row('Bayar', format.format(paid)),
              _row('Kembali', format.format(change), bold: true),

              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Terima kasih',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      ],
    );
  }


  static Future<void> previewReceipt({
    required int total,
    required int paid,
    required int change,
    required List<ReceiptItem> items,
  }) async {
    final pdf = await _buildPdf(
      total: total,
      paid: paid,
      change: change,
      items: items,
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
    );
  }

  
  static Future<File> savePdf({
    required int total,
    required int paid,
    required int change,
    required List<ReceiptItem> items,
  }) async {
    final pdf = await _buildPdf(
      total: total,
      paid: paid,
      change: change,
      items: items,
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/struk_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
