import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Model item untuk receipt
class ReceiptItem {
  final String name;
  final int price;
  final int qty;

  ReceiptItem({required this.name, required this.price, required this.qty});

  int get subtotal => price * qty;
}

class PrinterService {
  static final PrinterService instance = PrinterService._();
  PrinterService._();

  // ─── SharedPreferences keys ───
  static const _keyDeviceAddress = 'printer_device_address';
  static const _keyDeviceName = 'printer_device_name';
  static const _keyStoreName = 'store_name';
  static const _keyStoreAddress = 'store_address';

  // ─────────────────────────────────────────────
  // SETTINGS — simpan & baca
  // ─────────────────────────────────────────────

  Future<void> saveStoreInfo({
    required String name,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStoreName, name);
    await prefs.setString(_keyStoreAddress, address);
  }

  Future<Map<String, String>> getStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyStoreName) ?? 'Waroengku',
      'address': prefs.getString(_keyStoreAddress) ?? '',
    };
  }

  Future<void> savePrinterDevice(BluetoothInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceAddress, device.macAdress);
    await prefs.setString(_keyDeviceName, device.name);
  }

  Future<Map<String, String?>> getSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'address': prefs.getString(_keyDeviceAddress),
      'name': prefs.getString(_keyDeviceName),
    };
  }

  Future<void> clearSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceAddress);
    await prefs.remove(_keyDeviceName);
  }

  // ─────────────────────────────────────────────
  // BLUETOOTH — scan & connect
  // ─────────────────────────────────────────────

  Future<List<BluetoothInfo>> getBondedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Connect ke device tersimpan (auto-connect)
  Future<bool> connectToSaved() async {
    final saved = await getSavedDevice();
    if (saved['address'] == null || saved['address']!.isEmpty) return false;

    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: saved['address']!,
      );
      return result;
    } catch (_) {
      return false;
    }
  }

  /// Connect ke device pilihan user
  Future<bool> connectToDevice(BluetoothInfo device) async {
    final connected = await isConnected();
    if (connected) await PrintBluetoothThermal.disconnect;

    final result = await PrintBluetoothThermal.connect(
      macPrinterAddress: device.macAdress,
    );

    if (result) await savePrinterDevice(device);
    return result;
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    await clearSavedDevice();
  }

  // ─────────────────────────────────────────────
  // PRINT RECEIPT
  // ─────────────────────────────────────────────

  String _formatRupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<PrintResult> printReceipt({
    required int transactionId,
    required List<ReceiptItem> items,
    required int total,
    required int paid,
    required int change,
  }) async {
    // Pastikan terkoneksi
    bool connected = await isConnected();
    if (!connected) {
      connected = await connectToSaved();
      if (!connected) return PrintResult.notConnected;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final store = await getStoreInfo();
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
      final noTrx = transactionId.toString().padLeft(6, '0');

      // ── Header ──
      bytes += generator.feed(1);
      bytes += generator.text(
        store['name'] ?? 'Waroengku',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      if ((store['address'] ?? '').isNotEmpty) {
        bytes += generator.text(
          store['address']!,
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.feed(1);
      bytes += generator.hr();

      // ── Info transaksi ──
      bytes += generator.row([
        PosColumn(text: 'No. Trx', width: 6),
        PosColumn(
          text: ': #$noTrx',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Tanggal', width: 6),
        PosColumn(
          text: ': $dateStr',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.hr();

      // ── Items ──
      for (final item in items) {
        bytes += generator.text(item.name);
        bytes += generator.row([
          PosColumn(
            text: '  ${item.qty} x Rp ${_formatRupiah(item.price)}',
            width: 8,
          ),
          PosColumn(
            text: 'Rp ${_formatRupiah(item.subtotal)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr();

      // ── Total ──
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'Rp ${_formatRupiah(total)}',
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Bayar', width: 6),
        PosColumn(
          text: 'Rp ${_formatRupiah(paid)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Kembalian', width: 6),
        PosColumn(
          text: 'Rp ${_formatRupiah(change)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.hr();

      // ── Footer ──
      bytes += generator.feed(1);
      bytes += generator.text(
        'Terima kasih!',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Selamat datang kembali :)',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      // ── Kirim ke printer ──
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result ? PrintResult.success : PrintResult.error;
    } catch (e) {
      return PrintResult.error;
    }
  }
}

enum PrintResult { success, notConnected, error }
