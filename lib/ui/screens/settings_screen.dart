import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader("DEVICE"),
          ListTile(
            title: const Text("Device Name"),
            subtitle: const Text("Galaxy S24 Ultra"),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () {},
          ),
          ListTile(
            title: const Text("Server Port"),
            subtitle: const Text("8080"),
            trailing: const Icon(Icons.settings_input_component, size: 20),
            onTap: () {},
          ),
          ListTile(
            title: const Text("Download Directory"),
            subtitle: const Text("/storage/emulated/0/Download/LocalShare"),
            trailing: const Icon(Icons.folder_open, size: 20),
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSectionHeader("SECURITY"),
          SwitchListTile(
            title: const Text("Require PIN"),
            subtitle: const Text("Ask for PIN before accepting files"),
            value: true,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) {},
          ),
          // PIN Input Section (Animated)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(4, (index) => Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5))),
                child: const Center(child: Text("*", style: TextStyle(fontSize: 24))),
              )),
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          const Divider(height: 32),
          _buildSectionHeader("DISCOVERY"),
          SwitchListTile(
            title: const Text("Auto-start on boot"),
            value: false,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) {},
          ),
          ExpansionTile(
            title: const Text("Discovery Layers"),
            subtitle: const Text("Toggle individual scanning methods"),
            children: [
              _buildDiscoveryToggle("mDNS Discovery", true),
              _buildDiscoveryToggle("UDP Broadcast", true),
              _buildDiscoveryToggle("ARP Cache Polling", true),
              _buildDiscoveryToggle("WiFi Direct", true),
              _buildDiscoveryToggle("BLE Discovery", true),
            ],
          ),
          ListTile(
            title: const Text("Cert Fingerprint"),
            subtitle: const Text("SHA-256: 4A:6B:C9:2D..."),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {},
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => _showClearConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("CLEAR ALL RECEIVED FILES", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const Center(child: Text("v1.0.0 (build 102)", style: TextStyle(color: Colors.grey, fontSize: 10))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
    );
  }

  Widget _buildDiscoveryToggle(String label, bool value) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: AppTheme.primaryColor,
      onChanged: (val) {},
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("This will permanently delete all files in the received folder. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("DELETE ALL", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
