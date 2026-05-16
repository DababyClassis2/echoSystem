import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock states for UI demonstration
    const bool isServerRunning = true;
    const String localIp = "192.168.1.15";
    const String deviceName = "Galaxy S24 Ultra";

    return Scaffold(
      appBar: AppBar(title: const Text('LocalShare Hub')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Pulsing Status Indicator
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isServerRunning ? Colors.green : Colors.red).withOpacity(0.1),
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isServerRunning ? Colors.green : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: (isServerRunning ? Colors.green : Colors.red).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                 .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1000.ms, curve: Curves.easeInOut)
                 .then()
                 .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 1000.ms, curve: Curves.easeInOut),
              ),
            ),
            const SizedBox(height: 24),
            Text(deviceName, style: Theme.of(context).textTheme.headlineMedium),
            Text(localIp, style: AppTheme.monoStyle.copyWith(color: AppTheme.primaryColor, fontSize: 18)),
            const SizedBox(height: 32),
            
            // Start/Stop Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isServerRunning ? Colors.red.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.2),
                foregroundColor: isServerRunning ? Colors.red : AppTheme.primaryColor,
                minimumSize: const Size(200, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                side: BorderSide(color: isServerRunning ? Colors.red : AppTheme.primaryColor),
              ),
              child: Text(isServerRunning ? "STOP SERVER" : "START SERVER", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),

            // QR Code
            GestureDetector(
              onTap: () => _showFullscreenQR(context, "http://$localIp:8080"),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: "http://$localIp:8080",
                    version: QrVersions.auto,
                    size: 160.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.onSurfaceColor),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.onSurfaceColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text("Tap to expand QR", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 40),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Files", "12"),
                _buildStatItem("Active", "1"),
                _buildStatItem("Devices", "3"),
              ],
            ),
            const SizedBox(height: 40),

            // Discovery Chips
            Wrap(
              spacing: 8,
              children: [
                _buildDiscoveryChip("mDNS", true),
                _buildDiscoveryChip("ARP", true),
                _buildDiscoveryChip("BLE", true),
                _buildDiscoveryChip("UDP", false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTheme.monoStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildDiscoveryChip(String label, bool active) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: active ? Colors.green : Colors.grey),
      backgroundColor: AppTheme.surfaceColor,
      side: BorderSide(color: active ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.2)),
    );
  }

  void _showFullscreenQR(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 300.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }
}
