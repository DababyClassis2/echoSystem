import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../network/network_interface_scanner.dart';
import '../discovery/arp_discovery.dart';
import '../discovery/udp_broadcast_discovery.dart';
import '../discovery/mdns_discovery.dart';
import '../discovery/wifi_direct_discovery.dart';
import '../discovery/ble_discovery.dart';
import '../discovery/discovery_orchestrator.dart';
import '../transfer/chunked_uploader.dart';
import '../transfer/chunked_downloader.dart';
import '../transfer/file_transfer_manager.dart';
import '../security/pairing_manager.dart';
import '../services/foreground_service_manager.dart';
import '../server/local_share_server.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Networking & Discovery
  sl.registerLazySingleton(() => NetworkInterfaceScanner());
  sl.registerLazySingleton(() => ArpDiscovery());
  sl.registerLazySingleton(() => UdpBroadcastDiscovery());
  sl.registerLazySingleton(() => MdnsDiscovery());
  sl.registerLazySingleton(() => WifiDirectDiscovery());
  sl.registerLazySingleton(() => BleDiscovery());
  sl.registerLazySingleton(() => DiscoveryOrchestrator());

  // Dio configuration
  sl.registerLazySingleton(() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    // In a real app, add a logging interceptor here if in debug mode
    return dio;
  });

  // Transfer
  sl.registerLazySingleton(() => ChunkedUploader(sl()));
  sl.registerLazySingleton(() => ChunkedDownloader(sl()));
  sl.registerLazySingleton(() => FileTransferManager());

  // Security & Services
  sl.registerLazySingleton(() => PairingManager());
  sl.registerLazySingleton(() => ForegroundServiceManager());
  sl.registerLazySingleton(() => LocalShareServer());
}
