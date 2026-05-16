import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device.dart';

class BleDiscovery {
  final _controller = StreamController<DeviceCandidate>.broadcast();
  static const int manufacturerId = 0xFEAA; // Example ID

  Stream<DeviceCandidate> get candidates => _controller.stream;

  Future<void> start(String deviceId, int port) async {
    // Note: flutter_blue_plus handles scanning. 
    // Advertising usually requires another package like 'beacon_broadcast' 
    // or 'flutter_ble_peripheral' but the spec asks to use flutter_blue_plus.
    // FBP is primarily for scanning/connecting.
    
    FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        final data = r.advertisementData.manufacturerData[manufacturerId];
        if (data != null && data.length >= 10) {
          // Parse deviceId (first 8 bytes) and port (2 bytes)
          // Simplified for this example
          _controller.add(DeviceCandidate(
            ip: 'ble-${r.device.remoteId}',
            port: port,
            source: 'BLE',
          ));
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10), androidUsesFineLocation: true);
  }

  void stop() {
    FlutterBluePlus.stopScan();
  }
}
