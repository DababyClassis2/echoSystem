import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/device.dart';

class MdnsDiscovery {
  final String serviceType = '_localshare._tcp';
  final MDnsClient _client = MDnsClient();
  final _controller = StreamController<DeviceCandidate>.broadcast();

  Stream<DeviceCandidate> get candidates => _controller.stream;

  void start(String deviceName, int port) {
    // Service registration is usually platform-specific, 
    // here we focus on the discovery part.
    _discover();
    Timer.periodic(const Duration(seconds: 10), (_) => _discover());
  }

  Future<void> _discover() async {
    try {
      await _client.start();
      await for (final PtrResourceRecord ptr in _client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_localshare._tcp.local'),
      )) {
        await for (final SrvResourceRecord srv in _client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final IPAddressResourceRecord ip in _client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            _controller.add(DeviceCandidate(
              ip: ip.address.address,
              port: srv.port,
              source: 'mDNS',
            ));
          }
        }
      }
    } catch (e) {
      // ignore
    } finally {
      _client.stop();
    }
  }

  void stop() {
    _client.stop();
  }
}
