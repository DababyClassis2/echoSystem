import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'di/service_locator.dart';
import 'discovery/discovery_orchestrator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize GetIt service locator
  await setupServiceLocator();

  // 3. Request all required permissions upfront
  await _requestPermissions();

  runApp(
    const ProviderScope(
      child: LocalShareApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.location,
    Permission.notification,
    Permission.nearbyWifiDevices,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
  ];

  if (Platform.isAndroid) {
    // Media permissions for Android 13+
    permissions.addAll([
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ]);
    // Storage for Android 12 and below
    permissions.add(Permission.storage);
  }

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  // Handle graceful denial (logging/warnings could be added here)
  if (statuses[Permission.location]?.isDenied ?? false) {
    print('WiFi Direct discovery may be limited due to location permission denial.');
  }
  if (statuses[Permission.bluetoothScan]?.isDenied ?? false) {
    print('BLE discovery will be disabled due to bluetooth permission denial.');
  }
}

class LocalShareAppWrapper extends StatefulWidget {
  final Widget child;
  const LocalShareAppWrapper({super.key, required this.child});

  @override
  State<LocalShareAppWrapper> createState() => _LocalShareAppWrapperState();
}

class _LocalShareAppWrapperState extends State<LocalShareAppWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 5. On app resume: restart discovery if orchestrator is registered
      final orchestrator = sl<DiscoveryOrchestrator>();
      // Logic to restart if it was previously running
    }
    // 6. On app detach: do NOT stop server (let foreground service keep it running)
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
