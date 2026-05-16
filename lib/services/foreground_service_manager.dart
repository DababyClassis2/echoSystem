import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class ForegroundServiceManager extends StateNotifier<bool> {
  ForegroundServiceManager() : super(false);

  static const _channel = MethodChannel('com.localshare/foreground');

  Future<void> start(String localIp) async {
    // 1. Request notification permission (required for Android 13+)
    if (await Permission.notification.request().isGranted) {
      try {
        // 2. Call platform channel to start the native foreground service
        final bool success = await _channel.invokeMethod('startService', {'ip': localIp});
        if (success) {
          state = true;
        }
      } catch (e) {
        print('Failed to start foreground service: $e');
      }
    }
  }

  Future<void> stop() async {
    try {
      final bool success = await _channel.invokeMethod('stopService');
      if (success) {
        state = false;
      }
    } catch (e) {
      print('Failed to stop foreground service: $e');
    }
  }

  Future<void> updateStats(int filesReceived, int activeTransfers) async {
    try {
      final String content = 'Received: $filesReceived | Active: $activeTransfers';
      await _channel.invokeMethod('updateNotification', {'content': content});
    } catch (e) {
      print('Failed to update notification stats: $e');
    }
  }
}

final foregroundServiceProvider = StateNotifierProvider<ForegroundServiceManager, bool>((ref) {
  return ForegroundServiceManager();
});
