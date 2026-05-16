import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/device.dart';
import '../theme/app_theme.dart';

// Mock provider for demonstration
final devicesProvider = StateProvider<Map<String, Device>>((ref) => {
  "1": Device(id: "1", name: "MacBook Pro", ip: "192.168.1.10", os: "macos", port: 8080, isPaired: true, lastSeen: DateTime.now(), latencyMs: 25),
  "2": Device(id: "2", name: "iPad Air", ip: "192.168.1.12", os: "ios", port: 8080, isPaired: false, lastSeen: DateTime.now(), latencyMs: 120),
  "3": Device(id: "3", name: "Windows PC", ip: "192.168.1.25", os: "windows", port: 8080, isPaired: false, lastSeen: DateTime.now(), latencyMs: 210),
});

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesMap = ref.watch(devicesProvider);
    final devices = devicesMap.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        actions: [
          IconButton(icon: const Icon(Icons.add_link), onPressed: () => _showManualIpDialog(context)),
        ],
      ),
      body: devices.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return _buildDeviceCard(context, device)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                    .slideX(begin: 0.1, end: 0);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 100, color: AppTheme.primaryColor.withOpacity(0.2))
              .animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds)
              .fadeOut(duration: 2.seconds),
          const SizedBox(height: 24),
          const Text("Scanning for peers...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, Device device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _getOSIcon(device.os),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(device.ip, style: AppTheme.monoStyle.copyWith(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPingBadge(device.latencyMs ?? 0),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text("SEND", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getOSIcon(String os) {
    IconData icon;
    Color color;
    switch (os.toLowerCase()) {
      case 'android': icon = FontAwesomeIcons.android; color = Colors.green; break;
      case 'ios': icon = FontAwesomeIcons.apple; color = Colors.white; break;
      case 'macos': icon = FontAwesomeIcons.apple; color = Colors.white; break;
      case 'windows': icon = FontAwesomeIcons.windows; color = Colors.blue; break;
      case 'linux': icon = FontAwesomeIcons.linux; color = Colors.orange; break;
      default: icon = Icons.device_unknown; color = Colors.grey;
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildPingBadge(int ms) {
    Color color = Colors.green;
    if (ms > 50) color = Colors.yellow;
    if (ms > 150) color = Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.side(color: color.withOpacity(0.5))),
      child: Text("${ms}ms", style: AppTheme.monoStyle.copyWith(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showManualIpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manual Connection"),
        content: const TextField(
          decoration: InputDecoration(
            hintText: "Enter IP Address (e.g. 192.168.1.10)",
            prefixIcon: Icon(Icons.lan),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("CONNECT")),
        ],
      ),
    );
  }
}
