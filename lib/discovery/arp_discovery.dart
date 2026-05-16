import 'dart:async';
import 'package:flutter/services.dart';
import '../models/device.dart';

/**
 * ArpDiscovery Layer
 * 
 * WHY Layer 2 ARP bypasses VPN:
 * ARP (Address Resolution Protocol) operates at the Data Link Layer (Layer 2).
 * Most VPNs operate at the Network Layer (Layer 3) or higher.
 * When a VPN is active, it creates a virtual network interface and routes IP traffic
 * through it. However, the physical network interface still maintains its own 
 * ARP cache for direct neighbors on the local link (WiFi/Ethernet).
 * By reading /proc/net/arp (the system ARP cache), we can identify physical 
 * neighbors regardless of the VPN overlay network, making this highly reliable 
 * for tools like PdaNet or corporate VPNs.
 */
class ArpDiscovery {
  static const _channel = MethodChannel('com.localshare/arp');
  final _controller = StreamController<DeviceCandidate>.broadcast();
  Timer? _timer;

  Stream<DeviceCandidate> get candidates => _controller.stream;

  void start() {
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final List<dynamic>? ips = await _channel.invokeMethod('getArpEntries');
      if (ips != null) {
        for (var ip in ips) {
          _controller.add(DeviceCandidate(
            ip: ip.toString(),
            port: 8080,
            source: 'ARP_Cache',
          ));
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  void stop() {
    _timer?.cancel();
  }
}
