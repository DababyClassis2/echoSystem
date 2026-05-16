import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/device.dart';

class MdnsDiscovery {
  final String serviceType = '_localshare._tcp';
  final MDnsClient _client = MDnsClient();
  final _controller = StreamController<DeviceCandidate>.broadcast();

  Stream<DeviceCandidate> get candidates => _controller.stream;

  Future<void> start(String deviceName, int port) async {
    await _client.start();
    
    // In a real app, we'd also register our own service here.
    // multicast_dns doesn't support service registration directly on all platforms,
    // usually handled by native system calls or other packages.
    
    _discover();
    Timer.periodic(const Duration(seconds: 10), (_) => _discover());
  }

  Future<void> _discover() async {
    try {
      await for (final PtrRecord ptr in _client.lookup<PtrRecord>(
        ResourceRecordQuery.serverPointer(serviceType),
      )) {
        await for (final SrvRecord srv in _client.lookup<SrvRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final IPAddressRecord ip in _client.lookup<IPAddressRecord>(
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
      // Handle or log error
    }
  }

  void stop() {
    _client.stop();
  }
}
