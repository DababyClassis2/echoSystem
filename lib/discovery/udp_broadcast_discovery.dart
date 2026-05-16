import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/device.dart';
import '../network/network_interface_scanner.dart';

class UdpBroadcastDiscovery {
  static const int udpPort = 45678;
  RawDatagramSocket? _socket;
  final _controller = StreamController<DeviceCandidate>.broadcast();
  Timer? _beaconTimer;

  Stream<DeviceCandidate> get candidates => _controller.stream;

  Future<void> start(String deviceId, String deviceName, int port) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort, reuseAddress: true, reusePort: true);
    _socket?.broadcastEnabled = true;

    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket?.receive();
        if (dg != null) {
          try {
            final data = jsonDecode(utf8.decode(dg.data));
            if (data['deviceId'] != deviceId) {
              _controller.add(DeviceCandidate(
                ip: dg.address.address,
                port: data['port'] ?? 8080,
                source: 'UDP_Broadcast',
              ));
            }
          } catch (e) {
            // Invalid packet
          }
        }
      }
    });

    _beaconTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final interfaces = await NetworkInterfaceScanner.scan();
      final beacon = jsonEncode({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'port': port,
        'version': '1.0',
      });
      final bytes = utf8.encode(beacon);

      for (var interface in interfaces) {
        _socket?.send(bytes, InternetAddress(interface.broadcast), udpPort);
      }
    });
  }

  void stop() {
    _beaconTimer?.cancel();
    _socket?.close();
  }
}
