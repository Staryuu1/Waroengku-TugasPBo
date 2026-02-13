import 'package:flutter/material.dart';
import '../../../services/excel_import_helper.dart';

class ImportExcelPage extends StatefulWidget {
  const ImportExcelPage({super.key});

  @override
  State<ImportExcelPage> createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  // ── State ──
  _PageState _state = _PageState.idle;
  String? _selectedFileName;
  String? _selectedFilePath;
  ExcelImportSummary? _importSummary;
  String? _errorMessage;

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

  Future<void> _downloadTemplate() async {
    setState(() {
      _state = _PageState.downloading;
      _errorMessage = null;
    });

    try {
      await ExcelImportHelper.generateAndShareTemplate();
      if (!mounted) return;
      setState(() => _state = _PageState.idle);

      _showSnackbar('Template berhasil dibagikan!', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _PageState.idle;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _importSummary = null;
    });

    try {
      final path = await ExcelImportHelper.pickExcelFile();
      if (path == null) return; // user cancel

      final fileName = path.split('/').last;
      setState(() {
        _selectedFilePath = path;
        _selectedFileName = fileName;
        _state = _PageState.fileSelected;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memilih file: $e');
    }
  }

  Future<void> _startImport() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _state = _PageState.importing;
      _errorMessage = null;
      _importSummary = null;
    });

    try {
      final summary = await ExcelImportHelper.processImport(_selectedFilePath!);

      if (!mounted) return;
      setState(() {
        _state = _PageState.done;
        _importSummary = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _PageState.fileSelected;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _PageState.idle;
      _selectedFileName = null;
      _selectedFilePath = null;
      _importSummary = null;
      _errorMessage = null;
    });
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Import Excel',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF43A047),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Step 1: Download Template ──
            _StepCard(
              stepNumber: 1,
              title: 'Download Template',
              subtitle: 'Gunakan template resmi agar format sesuai',
              icon: Icons.download_rounded,
              color: const Color(0xFF1976D2),
              child: _buildDownloadSection(),
            ),

            const SizedBox(height: 16),

            // ── Step 2: Pilih File ──
            _StepCard(
              stepNumber: 2,
              title: 'Pilih File Excel',
              subtitle: 'Pilih file .xlsx yang sudah diisi',
              icon: Icons.folder_open_rounded,
              color: const Color(0xFF7B1FA2),
              child: _buildPickFileSection(),
            ),

            const SizedBox(height: 16),

            // ── Step 3: Import ──
            _StepCard(
              stepNumber: 3,
              title: 'Import Data',
              subtitle: 'Proses import ke database',
              icon: Icons.upload_rounded,
              color: const Color(0xFF43A047),
              child: _buildImportSection(),
            ),

            // ── Error Message ──
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: _errorMessage!),
            ],

            // ── Result ──
            if (_importSummary != null) ...[
              const SizedBox(height: 16),
              _ResultCard(summary: _importSummary!, onImportAgain: _reset),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION BUILDERS
  // ─────────────────────────────────────────────

  Widget _buildDownloadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info format
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Format template:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.table_chart,
                text: 'Sheet "Kategori": kolom nama_kategori',
              ),
              _InfoRow(
                icon: Icons.table_chart,
                text:
                    'Sheet "Produk": nama, harga, stok, kategori, barcode, path_gambar',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _state == _PageState.downloading
                ? null
                : _downloadTemplate,
            icon: _state == _PageState.downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _state == _PageState.downloading
                  ? 'Menyiapkan...'
                  : 'Download Template',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickFileSection() {
    return Column(
      children: [
        // File yang dipilih
        if (_selectedFileName != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_rounded,
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedFileName!,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _state == _PageState.importing ? null : _reset,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.green[700],
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _state == _PageState.importing ? null : _pickFile,
            icon: const Icon(Icons.folder_open_rounded),
            label: Text(
              _selectedFileName == null ? 'Pilih File .xlsx' : 'Ganti File',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7B1FA2),
              side: const BorderSide(color: Color(0xFF7B1FA2), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportSection() {
    final bool canImport =
        _selectedFilePath != null &&
        _state != _PageState.importing &&
        _state != _PageState.done;

    return Column(
      children: [
        if (_state == _PageState.importing)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                LinearProgressIndicator(
                  color: Color(0xFF43A047),
                  backgroundColor: Color(0xFFC8E6C9),
                ),
                SizedBox(height: 8),
                Text(
                  'Sedang memproses data...',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canImport ? _startImport : null,
            icon: const Icon(Icons.upload_rounded),
            label: Text(
              _state == _PageState.importing
                  ? 'Sedang Import...'
                  : _state == _PageState.done
                  ? 'Import Selesai ✓'
                  : 'Mulai Import',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              disabledBackgroundColor: _state == _PageState.done
                  ? Colors.green[200]
                  : Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_selectedFilePath == null && _state == _PageState.idle)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Pilih file Excel terlebih dahulu',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// STATE ENUM
// ─────────────────────────────────────────────

enum _PageState { idle, downloading, fileSelected, importing, done }

// ─────────────────────────────────────────────
// WIDGET COMPONENTS
// ─────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.blue[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: Colors.red[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ExcelImportSummary summary;
  final VoidCallback onImportAgain;

  const _ResultCard({required this.summary, required this.onImportAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green[700],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Import Selesai!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Detail hasil
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              summary.fullSummary,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onImportAgain,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Import File Lain'),
              style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
            ),
          ),
        ],
      ),
    );
  }
}
