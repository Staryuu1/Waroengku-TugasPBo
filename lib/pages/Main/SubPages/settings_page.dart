import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../services/printer_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _printerService = PrinterService.instance;

  // ── Store info controllers ──
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // ── Printer state ──
  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _connectedDevice;
  Map<String, String?> _savedDevice = {};
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isSavingStore = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final store = await _printerService.getStoreInfo();
    _nameCtrl.text = store['name'] ?? '';
    _addressCtrl.text = store['address'] ?? '';

    _savedDevice = await _printerService.getSavedDevice();

    final connected = await _printerService.isConnected();
    if (connected && _savedDevice['address'] != null) {
      _connectedDevice = BluetoothInfo(
        name: _savedDevice['name'] ?? '',
        macAdress: _savedDevice['address'] ?? '',
      );
    }

    setState(() {});
  }

  // ─────────────────────────────────────────────
  // STORE INFO
  // ─────────────────────────────────────────────

  Future<void> _saveStoreInfo() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnackbar('Nama toko tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isSavingStore = true);
    await _printerService.saveStoreInfo(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    setState(() => _isSavingStore = false);
    _showSnackbar('Info toko berhasil disimpan');
  }

  // ─────────────────────────────────────────────
  // PRINTER
  // ─────────────────────────────────────────────

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      final devices = await _printerService.getBondedDevices();
      setState(() => _devices = devices);

      if (devices.isEmpty) {
        _showSnackbar(
          'Tidak ada perangkat terpasang.\nPair printer di Pengaturan Bluetooth HP terlebih dahulu.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar('Gagal scan: $e', isError: true);
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectDevice(BluetoothInfo device) async {
    setState(() => _isConnecting = true);

    try {
      final result = await _printerService.connectToDevice(device);
      if (result) {
        _savedDevice = await _printerService.getSavedDevice();
        setState(() => _connectedDevice = device);
        _showSnackbar('Terhubung ke ${device.name}');
      } else {
        _showSnackbar('Gagal terhubung ke ${device.name}', isError: true);
      }
    } catch (e) {
      _showSnackbar('Gagal terhubung: $e', isError: true);
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    setState(() {
      _connectedDevice = null;
      _savedDevice = {};
    });
    _showSnackbar('Printer dilepas');
  }

  Future<void> _testPrint() async {
    final result = await _printerService.printReceipt(
      transactionId: 0,
      items: [
        ReceiptItem(name: 'Test Produk A', price: 10000, qty: 2),
        ReceiptItem(name: 'Test Produk B', price: 5000, qty: 1),
      ],
      total: 25000,
      paid: 30000,
      change: 5000,
    );

    switch (result) {
      case PrintResult.success:
        _showSnackbar('Test print berhasil!');
        break;
      case PrintResult.notConnected:
        _showSnackbar('Printer tidak terhubung', isError: true);
        break;
      case PrintResult.error:
        _showSnackbar('Gagal print', isError: true);
        break;
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Section: Info Toko ──
          _SectionHeader(title: 'Info Toko', icon: Icons.store_rounded),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Toko',
                    prefixIcon: const Icon(Icons.storefront_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Alamat Toko',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingStore ? null : _saveStoreInfo,
                    icon: _isSavingStore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Simpan Info Toko'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section: Printer ──
          _SectionHeader(
            title: 'Printer Thermal Bluetooth',
            icon: Icons.print_rounded,
          ),
          const SizedBox(height: 12),

          // Status koneksi
          _Card(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connectedDevice != null
                        ? Colors.green
                        : Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connectedDevice != null
                            ? 'Terhubung'
                            : 'Tidak ada printer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _connectedDevice != null
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                      ),
                      if (_connectedDevice != null)
                        Text(
                          _connectedDevice!.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_connectedDevice != null) ...[
                  IconButton(
                    onPressed: _testPrint,
                    icon: const Icon(Icons.print_rounded),
                    color: Colors.blue[700],
                    tooltip: 'Test Print',
                  ),
                  IconButton(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.link_off_rounded),
                    color: Colors.red[700],
                    tooltip: 'Lepas Printer',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scan button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isScanning ? null : _scanDevices,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching_rounded),
              label: Text(
                _isScanning ? 'Scanning...' : 'Cari Perangkat Bluetooth',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1976D2),
                side: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (_devices.isEmpty && !_isScanning)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Pastikan printer sudah di-pair di Pengaturan Bluetooth HP sebelum mencari.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),

          // Daftar device
          if (_devices.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perangkat Tersedia (${_devices.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_devices.length, (i) {
                    final device = _devices[i];
                    final isActive =
                        _connectedDevice?.macAdress == device.macAdress;

                    return Column(
                      children: [
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.print_rounded,
                            color: isActive
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                          title: Text(
                            device.name,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive ? Colors.green[700] : null,
                            ),
                          ),
                          subtitle: Text(
                            device.macAdress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          trailing: _isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : isActive
                              ? Chip(
                                  label: const Text(
                                    'Terhubung',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.green[50],
                                  labelStyle: TextStyle(
                                    color: Colors.green[700],
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _connectDevice(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Hubungkan'),
                                ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET HELPERS
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
