import 'package:flutter/material.dart';
import '../../models/reports.dart';
import '../../services/report_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
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
    currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
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
      final topProductsData = await _reportService.getTopProducts(
        startDate,
        endDate,
      );
      final categoryReportsData = await _reportService.getCategoryReport();
      final salesByDateData = await _reportService.getSalesByDate(
        startDate,
        endDate,
      );

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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: Color(0xFF4CAF50)),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
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
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Periode: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
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
                _pdfSummaryCard(
                  'Total Transaksi',
                  summary?.totalTransactions.toString() ?? '0',
                ),
                _pdfSummaryCard(
                  'Total Item Terjual',
                  summary?.totalItemsSold.toString() ?? '0',
                ),
                _pdfSummaryCard(
                  'Total Revenue',
                  summary != null
                      ? currency.format(summary!.totalRevenue)
                      : '-',
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Top Products Section
            pw.Header(level: 1, text: 'Produk Terlaris'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['No', 'Produk', 'Qty Terjual', 'Pendapatan'],
                ...topProducts.asMap().entries.map(
                  (entry) => [
                    (entry.key + 1).toString(),
                    entry.value.productName,
                    entry.value.qtySold.toString(),
                    currency.format(entry.value.totalRevenue),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Category Report Section
            pw.Header(level: 1, text: 'Pendapatan per Kategori'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['No', 'Kategori', 'Pendapatan'],
                ...categoryReports.asMap().entries.map(
                  (entry) => [
                    (entry.key + 1).toString(),
                    entry.value.categoryName,
                    currency.format(entry.value.totalRevenue),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Sales by Date Section
            if (salesByDate.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Penjualan per Tanggal'),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                data: [
                  ['Tanggal', 'Transaksi', 'Revenue'],
                  ...salesByDate.map(
                    (sale) => [
                      dateFormat.format(sale.date),
                      sale.transactionCount.toString(),
                      currency.format(sale.totalRevenue),
                    ],
                  ),
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
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: Colors.red,
          ),
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
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? Border.all(color: Colors.white.withOpacity(0.08))
                          : null,
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? []
                          : [
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
                              Text(
                                'Periode Laporan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                          context,
                          'Total Transaksi',
                          summary?.totalTransactions.toString() ?? '0',
                          Colors.blue,
                          Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          context,
                          'Item Terjual',
                          summary?.totalItemsSold.toString() ?? '0',
                          Colors.orange,
                          Icons.shopping_cart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          context,
                          'Total Revenue',
                          summary != null
                              ? currency.format(summary!.totalRevenue)
                              : '-',
                          Colors.green,
                          Icons.attach_money,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sales Chart Section
                  _sectionHeader('Grafik Penjualan', Icons.bar_chart_rounded),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? Border.all(color: Colors.white.withOpacity(0.08))
                          : null,
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: salesByDate.isEmpty
                        ? const Center(child: Text('Tidak ada data penjualan'))
                        : _buildSalesChart(context),
                  ),
                  const SizedBox(height: 24),

                  // Top Products Section
                  _sectionHeader('Produk Terlaris', Icons.star),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? Border.all(color: Colors.white.withOpacity(0.08))
                          : null,
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? []
                          : [
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
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLow,
                                    ),
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'Produk',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Qty Terjual',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Pendapatan',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        numeric: true,
                                      ),
                                    ],
                                    rows: topProducts
                                        .map(
                                          (e) => DataRow(
                                            cells: [
                                              DataCell(Text(e.productName)),
                                              DataCell(Text(e.qtySold.toString())),
                                              DataCell(
                                                Text(
                                                  currency.format(e.totalRevenue),
                                                  style: const TextStyle(
                                                    color: Color(0xFF4CAF50),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Category Report Section
                  _sectionHeader('Pendapatan per Kategori', Icons.category),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? Border.all(color: Colors.white.withOpacity(0.08))
                          : null,
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? []
                          : [
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
                            child: Center(
                              child: Text('Tidak ada data kategori'),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      Theme.of(context).colorScheme.surfaceContainerLow,
                                    ),
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'Kategori',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Pendapatan',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        numeric: true,
                                      ),
                                    ],
                                    rows: categoryReports
                                        .map(
                                          (e) => DataRow(
                                            cells: [
                                              DataCell(Text(e.categoryName)),
                                              DataCell(
                                                Text(
                                                  currency.format(e.totalRevenue),
                                                  style: const TextStyle(
                                                    color: Color(0xFF4CAF50),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Sales by Date Section
                  if (salesByDate.isNotEmpty) ...[
                    _sectionHeader(
                      'Penjualan per Tanggal',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(color: Colors.white.withOpacity(0.08))
                            : null,
                        boxShadow: Theme.of(context).brightness == Brightness.dark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Theme.of(context).colorScheme.surfaceContainerLow,
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Tanggal',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Transaksi',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Revenue',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                ],
                                rows: salesByDate
                                    .map(
                                      (e) => DataRow(
                                        cells: [
                                          DataCell(Text(dateFormat.format(e.date))),
                                          DataCell(
                                            Text(e.transactionCount.toString()),
                                          ),
                                          DataCell(
                                            Text(
                                              currency.format(e.totalRevenue),
                                              style: const TextStyle(
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          );
                        },
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _summaryCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.08))
            : null,
        boxShadow: isDark
            ? []
            : [
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
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    final maxRevenue = salesByDate
        .map((sale) => sale.totalRevenue.toDouble())
        .fold<double>(0, (prev, value) => value > prev ? value : prev);
    final maxY = maxRevenue > 0 ? maxRevenue * 1.2 : 1.0;
    final interval = maxY / 4;

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: interval > 0 ? interval : 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= salesByDate.length) {
                    return const SizedBox.shrink();
                  }
                  final sale = salesByDate[index];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('dd/MM').format(sale.date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: List.generate(salesByDate.length, (index) {
            final sale = salesByDate[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: sale.totalRevenue.toDouble(),
                  width: 14,
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
