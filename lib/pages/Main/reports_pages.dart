import 'package:flutter/material.dart';
import '../../models/reports.dart';
import '../../services/report_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ReportService _reportService = ReportService();

  ReportSummary? summary;
  List<TopProduct> topProducts = [];
  List<CategoryReport> categoryReports = [];
  List<SalesByDate> salesByDate = [];

  bool isLoading = true;
  String? errorMessage;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  late NumberFormat currency;
  late DateFormat dateFormat;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    // Initialize Indonesian locale
    await initializeDateFormatting('id_ID', null);
    
    // Initialize formatters after locale is ready
    currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    
    // Load reports
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final summaryData = await _reportService.getSummary();
      final topProductsData = await _reportService.getTopProducts(startDate, endDate);
      final categoryReportsData = await _reportService.getCategoryReport();
      final salesByDateData = await _reportService.getSalesByDate(startDate, endDate);

      setState(() {
        summary = summaryData;
        topProducts = topProductsData;
        categoryReports = categoryReportsData;
        salesByDate = salesByDateData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadReports();
    }
  }

  Future<void> _exportPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Laporan Penjualan',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Periode: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Header(level: 1, text: 'Ringkasan'),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfSummaryCard('Total Transaksi', summary?.totalTransactions.toString() ?? '0'),
                _pdfSummaryCard('Total Item Terjual', summary?.totalItemsSold.toString() ?? '0'),
                _pdfSummaryCard('Total Revenue', summary != null ? currency.format(summary!.totalRevenue) : '-'),
              ],
            ),
            pw.SizedBox(height: 30),

            // Top Products Section
            pw.Header(level: 1, text: 'Produk Terlaris'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['No', 'Produk', 'Qty Terjual', 'Pendapatan'],
                ...topProducts.asMap().entries.map((entry) => [
                      (entry.key + 1).toString(),
                      entry.value.productName,
                      entry.value.qtySold.toString(),
                      currency.format(entry.value.totalRevenue),
                    ]),
              ],
            ),
            pw.SizedBox(height: 30),

            // Category Report Section
            pw.Header(level: 1, text: 'Pendapatan per Kategori'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['No', 'Kategori', 'Pendapatan'],
                ...categoryReports.asMap().entries.map((entry) => [
                      (entry.key + 1).toString(),
                      entry.value.categoryName,
                      currency.format(entry.value.totalRevenue),
                    ]),
              ],
            ),
            pw.SizedBox(height: 30),

            // Sales by Date Section
            if (salesByDate.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Penjualan per Tanggal'),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                data: [
                  ['Tanggal', 'Transaksi', 'Revenue'],
                  ...salesByDate.map((sale) => [
                        dateFormat.format(sale.date),
                        sale.transactionCount.toString(),
                        currency.format(sale.totalRevenue),
                      ]),
                ],
              ),
            ],

            // Footer
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Text(
              'Dicetak pada: ${DateFormat('dd MMM yyyy HH:mm', 'id').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _pdfSummaryCard(String title, String value) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReports,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Range Filter
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Periode Laporan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.edit_calendar, size: 18),
                              label: const Text('Ubah'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              'Total Transaksi',
                              summary?.totalTransactions.toString() ?? '0',
                              Colors.blue,
                              Icons.receipt_long,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              'Item Terjual',
                              summary?.totalItemsSold.toString() ?? '0',
                              Colors.orange,
                              Icons.shopping_cart,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              'Total Revenue',
                              summary != null ? currency.format(summary!.totalRevenue) : '-',
                              Colors.green,
                              Icons.attach_money,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Top Products Section
                      _sectionHeader('Produk Terlaris', Icons.star),
                      const SizedBox(height: 12),
                      Container(
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
                        child: topProducts.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: Text('Tidak ada data produk')),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                                  columns: const [
                                    DataColumn(label: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Qty Terjual', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                    DataColumn(label: Text('Pendapatan', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                  ],
                                  rows: topProducts
                                      .map(
                                        (e) => DataRow(
                                          cells: [
                                            DataCell(Text(e.productName)),
                                            DataCell(Text(e.qtySold.toString())),
                                            DataCell(Text(
                                              currency.format(e.totalRevenue),
                                              style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                                            )),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Category Report Section
                      _sectionHeader('Pendapatan per Kategori', Icons.category),
                      const SizedBox(height: 12),
                      Container(
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
                        child: categoryReports.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: Text('Tidak ada data kategori')),
                              )
                            : Column(
                                children: categoryReports
                                    .map(
                                      (e) => ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                          child: const Icon(Icons.category, color: Color(0xFF4CAF50), size: 20),
                                        ),
                                        title: Text(e.categoryName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        trailing: Text(
                                          currency.format(e.totalRevenue),
                                          style: const TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Sales by Date Section
                      if (salesByDate.isNotEmpty) ...[
                        _sectionHeader('Penjualan per Tanggal', Icons.calendar_today),
                        const SizedBox(height: 12),
                        Container(
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
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                              columns: const [
                                DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                DataColumn(label: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                              ],
                              rows: salesByDate
                                  .map(
                                    (e) => DataRow(
                                      cells: [
                                        DataCell(Text(dateFormat.format(e.date))),
                                        DataCell(Text(e.transactionCount.toString())),
                                        DataCell(Text(
                                          currency.format(e.totalRevenue),
                                          style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                                        )),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Export Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _exportPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}