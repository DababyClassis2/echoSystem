import 'dart:async';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import 'mdns_discovery.dart';
import 'udp_broadcast_discovery.dart';
import 'arp_discovery.dart';
import 'wifi_direct_discovery.dart';
import 'ble_discovery.dart';

class DiscoveryOrchestrator extends StateNotifier<Map<String, Device>> {
  DiscoveryOrchestrator() : super({});

  final _mdns = MdnsDiscovery();
  final _udp = UdpBroadcastDiscovery();
  final _arp = ArpDiscovery();
  final _wifiDirect = WifiDirectDiscovery();
  final _ble = BleDiscovery();

  final Set<String> _seenIps = {};
  final Map<String, int> _healthCheckFailures = {};
  StreamSubscription? _subscription;
  Timer? _healthCheckTimer;

  void start({
    required String deviceId,
    required String deviceName,
    required int port,
  }) {
    _mdns.start(deviceName, port);
    _udp.start(deviceId, deviceName, port);
    _arp.start();
    _wifiDirect.start(deviceName);
    _ble.start(deviceId, port);

    final mergedStream = StreamGroup.merge<DeviceCandidate>([
      _mdns.candidates,
      _udp.candidates,
      _arp.candidates,
      _wifiDirect.candidates,
      _ble.candidates,
    ]);

    _subscription = mergedStream.listen(_handleCandidate);

    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) => _runHealthChecks());
  }

  void _handleCandidate(DeviceCandidate candidate) async {
    if (_seenIps.contains(candidate.ip)) return;
    _seenIps.add(candidate.ip);

    final device = await DeviceVerifier.verify(candidate.ip, candidate.port);
    if (device != null) {
      state = {...state, device.id: device};
      _healthCheckFailures[device.id] = 0;
    } else {
      _seenIps.remove(candidate.ip);
    }
  }

  Future<void> _runHealthChecks() async {
    final devices = state.values.toList();
    final chunks = <List<Device>>[];
    for (var i = 0; i < devices.length; i += 8) {
      chunks.add(devices.sublist(i, i + 8 > devices.length ? devices.length : i + 8));
    }

    for (var chunk in chunks) {
      await Future.wait(chunk.map((device) async {
        final verified = await DeviceVerifier.verify(device.ip, device.port);
        if (verified == null) {
          _healthCheckFailures[device.id] = (_healthCheckFailures[device.id] ?? 0) + 1;
          if (_healthCheckFailures[device.id]! >= 3) {
            state = Map.from(state)..remove(device.id);
            _seenIps.remove(device.ip);
          }
        } else {
          _healthCheckFailures[device.id] = 0;
          state = {...state, verified.id: verified};
        }
      }));
    }
  }

  void stop() {
    _subscription?.cancel();
    _healthCheckTimer?.cancel();
    _mdns.stop();
    _udp.stop();
    _arp.stop();
    _wifiDirect.stop();
    _ble.stop();
  }
}

class DeviceVerifier {
  static Future<Device?> verify(String ip, int port) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:$port/api/v1/info'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Device(
          id: data['deviceId'],
          name: data['deviceName'],
          ip: ip,
          os: data['os'],
          port: port,
          isPaired: false,
          lastSeen: DateTime.now(),
        );
      }
    } catch (e) {
      // Verification failed
    }
    return null;
  }
}
