import 'dart:io';

class NetworkInfo {
  final String name;
  final String ip;
  final String broadcast;

  NetworkInfo({required this.name, required this.ip, required this.broadcast});
}

class NetworkInterfaceScanner {
  static Future<List<NetworkInfo>> scan() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    final List<NetworkInfo> results = [];

    for (var interface in interfaces) {
      // Filter out virtual/tunnel interfaces
      final name = interface.name.toLowerCase();
      if (name.startsWith('tun') ||
          name.startsWith('ppp') ||
          name.startsWith('lo') ||
          name.startsWith('docker') ||
          name.startsWith('virbr')) {
        continue;
      }

      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          final ip = addr.address;
          final broadcast = _calculateBroadcast(ip);
          results.add(NetworkInfo(
            name: interface.name,
            ip: ip,
            broadcast: broadcast,
          ));
        }
      }
    }
    return results;
  }

  static String _calculateBroadcast(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return '255.255.255.255';
    // Assuming /24 for local networks for simplicity, as dart:io doesn't provide netmask easily
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }
}
