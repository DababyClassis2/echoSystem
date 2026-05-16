enum ServerState { stopped, starting, running, error }

class ServerConfig {
  static const int httpPort = 8080;
  static const String serviceName = '_localshare._tcp';
  static const int chunkSize = 4 * 1024 * 1024; // 4MB
}
