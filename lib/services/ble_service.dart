import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/detection.dart';

class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  StreamSubscription<List<int>>? _notifySub;

  final StreamController<Detection> _controller =
      StreamController<Detection>.broadcast();

  Stream<Detection> get detectionStream => _controller.stream;

  Completer<String>? _responseCompleter;

  String _buffer = '';

  static const String serviceUuid = "12345678-1234-1234-1234-1234567890ab";

  static const String writeUuid = "dcba4321-4321-4321-4321-654321fedcba";

  static const String notifyUuid = "abcd1234-1234-1234-1234-abcdef123456";

  // ================= SCAN =================
  Future<List<BluetoothDevice>> scan(int seconds) async {
    final devices = <BluetoothDevice>[];

    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName;

        if (!name.startsWith("ESP32_")) continue;

        final exists = devices.any((d) => d.remoteId == r.device.remoteId);

        if (!exists) {
          devices.add(r.device);
          print("FOUND: $name");
        }
      }
    });

    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
    );

    await Future.delayed(Duration(seconds: seconds));

    await FlutterBluePlus.stopScan();
    await sub.cancel();

    return devices;
  }

  // ================= CONNECT =================
  Future<void> connect(BluetoothDevice device) async {
    _device = device;

    await device.connect(timeout: const Duration(seconds: 10));

    final services = await device.discoverServices();

    for (final s in services) {
      for (final c in s.characteristics) {
        final uuid = c.uuid.toString().toLowerCase();

        // WRITE
        if (uuid == writeUuid) {
          _writeChar = c;
        }

        // NOTIFY
        if (uuid == notifyUuid) {
          _notifyChar = c;

          await c.setNotifyValue(true);

          _notifySub?.cancel();

          _notifySub = c.lastValueStream.listen(_handleIncoming);
        }
      }
    }

    if (_writeChar == null || _notifyChar == null) {
      throw Exception("UART characteristics not found");
    }
  }

  // ================= RECEIVE =================
  void _handleIncoming(List<int> data) {
    final chunk = utf8.decode(data, allowMalformed: true);

    print("📦 CHUNK: $chunk");

    // fin transmission
    if (chunk.contains("END")) {
      final fullMessage = _buffer;

      _buffer = '';

      _responseCompleter?.complete(fullMessage);

      return;
    }

    _buffer += chunk;
  }

  // ================= SEND =================
  Future<String> fetchData() async {
    if (_writeChar == null) {
      throw Exception("Not connected");
    }

    _buffer = '';

    _responseCompleter = Completer<String>();

    print("➡️ sending GET_ALL");

    await _writeChar!.write(utf8.encode("GET_ALL"), withoutResponse: false);

    // attend END
    return _responseCompleter!.future;
  }

  Future<void> disconnect() async {
    print("🔌 DISCONNECT");

    try {
      await _notifyChar?.setNotifyValue(false);
    } catch (_) {}

    try {
      await _notifySub?.cancel();
    } catch (_) {}

    try {
      await _device?.disconnect();
    } catch (_) {}

    _notifySub = null;

    _device = null;
    _writeChar = null;
    _notifyChar = null;

    _buffer = '';
  }
}
