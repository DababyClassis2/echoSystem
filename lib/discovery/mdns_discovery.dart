import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/device.dart';
import '../server/server_config.dart';

class MdnsDiscovery {
  final _client = MDnsClient();
  final _controller = StreamController<DeviceCandidate>.broadcast();
  bool _isRunning = false;

  Stream<DeviceCandidate> discover() async* {
    _isRunning = true;
    while (_isRunning) {
      try {
        await _client.start();
        
        // Query for PTR records
        final ptrStream = _client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_localshare._tcp.local'),
        );
        await for (final ptr in ptrStream) {
          final serviceName = ptr.domainName;
          // Query for SRV record
          final srvStream = _client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(serviceName),
          );
          await for (final srv in srvStream) {
            final hostName = srv.target;
            final port = srv.port;
            // Query for A record
            final ipStream = _client.lookup<AResourceRecord>(
              ResourceRecordQuery.address(hostName),
            );
            await for (final ip in ipStream) {
              _controller.add(DeviceCandidate(
                ip: ip.address.address,
                port: port,
                source: 'mdns',
              ));
            }
          }
        }
        await _client.stop();
      } catch (e) {
        // ignore
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  void stop() {
    _isRunning = false;
    _client.stop();
    _controller.close();
  }
}