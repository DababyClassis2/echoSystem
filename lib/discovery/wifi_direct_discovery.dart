import 'dart:async';
import 'package:nearby_connections/nearby_connections.dart';
import '../models/device.dart';

class WifiDirectDiscovery {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String serviceId = 'com.localshare';
  final _controller = StreamController<DeviceCandidate>.broadcast();

  Stream<DeviceCandidate> get candidates => _controller.stream;

  Future<void> start(String deviceName) async {
    try {
      await Nearby().startAdvertising(
        deviceName,
        strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(id, onPayLoadRecieved: (_, __) {});
        },
        onConnectionResult: (id, status) {},
        onDisconnected: (id) {},
        serviceId: serviceId,
      );

      await Nearby().startDiscovery(
        deviceName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          // In Nearby Connections, the IP isn't directly exposed in the callback.
          // This would usually involve a connection step to exchange IP/Port.
          // For this spec, we emit a candidate if we can resolve it.
          _controller.add(DeviceCandidate(
            ip: 'wifi-direct-$id', // Placeholder/Internal ID
            port: 8080,
            source: 'WiFi_Direct',
          ));
        },
        onEndpointLost: (id) {},
        serviceId: serviceId,
      );
    } catch (e) {
      // Handle error
    }
  }

  void stop() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
  }
}
