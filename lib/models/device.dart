import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Device {
  final String id;
  String state;
  final BluetoothDevice bleDevice;

  Device({required this.id, this.state = "detected", required this.bleDevice});
}
