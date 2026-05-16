class DeviceCandidate {
  final String ip;
  final int port;
  final String source;

  DeviceCandidate({
    required this.ip,
    required this.port,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'port': port,
    'source': source,
  };

  factory DeviceCandidate.fromJson(Map<String, dynamic> json) => DeviceCandidate(
    ip: json['ip'] as String,
    port: json['port'] as int,
    source: json['source'] as String,
  );
}

class Device {
  final String id;
  final String name;
  final String ip;
  final String os;
  final int port;
  final bool isPaired;
  final DateTime lastSeen;
  final int? latencyMs;

  Device({
    required this.id,
    required this.name,
    required this.ip,
    required this.os,
    required this.port,
    required this.isPaired,
    required this.lastSeen,
    this.latencyMs,
  });

  Device copyWith({
    String? id,
    String? name,
    String? ip,
    String? os,
    int? port,
    bool? isPaired,
    DateTime? lastSeen,
    int? latencyMs,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      os: os ?? this.os,
      port: port ?? this.port,
      isPaired: isPaired ?? this.isPaired,
      lastSeen: lastSeen ?? this.lastSeen,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': id,
    'deviceName': name,
    'ip': ip,
    'os': os,
    'port': port,
    'isPaired': isPaired,
    'lastSeen': lastSeen.toIso8601String(),
    'latencyMs': latencyMs,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['deviceId'] as String,
    name: json['deviceName'] as String,
    ip: json['ip'] as String,
    os: json['os'] as String,
    port: json['port'] as int,
    isPaired: json['isPaired'] as bool? ?? false,
    lastSeen: DateTime.parse(json['lastSeen'] as String),
    latencyMs: json['latencyMs'] as int?,
  );
}
