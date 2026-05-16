enum TransferDirection { upload, download }
enum TransferState { queued, active, paused, complete, failed, cancelled }

class TransferSession {
  final String id;
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final double speedBps;
  final TransferDirection direction;
  final TransferState state;
  final String targetDeviceId;
  final DateTime startedAt;
  final DateTime? completedAt;

  TransferSession({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.speedBps,
    required this.direction,
    required this.state,
    required this.targetDeviceId,
    required this.startedAt,
    this.completedAt,
  });

  TransferSession copyWith({
    String? id,
    String? fileName,
    int? totalBytes,
    int? transferredBytes,
    double? speedBps,
    TransferDirection? direction,
    TransferState? state,
    String? targetDeviceId,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TransferSession(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      speedBps: speedBps ?? this.speedBps,
      direction: direction ?? this.direction,
      state: state ?? this.state,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'totalBytes': totalBytes,
    'transferredBytes': transferredBytes,
    'speedBps': speedBps,
    'direction': direction.name,
    'state': state.name,
    'targetDeviceId': targetDeviceId,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory TransferSession.fromJson(Map<String, dynamic> json) => TransferSession(
    id: json['id'] as String,
    fileName: json['fileName'] as String,
    totalBytes: json['totalBytes'] as int,
    transferredBytes: json['transferredBytes'] as int,
    speedBps: (json['speedBps'] as num).toDouble(),
    direction: TransferDirection.values.byName(json['direction'] as String),
    state: TransferState.values.byName(json['state'] as String),
    targetDeviceId: json['targetDeviceId'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
  );
}

class TransferProgress {
  final String sessionId;
  final String fileName;
  final int bytesTransferred;
  final int totalBytes;
  final double speedBps;
  final bool isComplete;
  final String? error;

  TransferProgress({
    required this.sessionId,
    required this.fileName,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.speedBps,
    this.isComplete = false,
    this.error,
  });

  double get percent => totalBytes > 0 ? (bytesTransferred / totalBytes) : 0;

  String get speedLabel {
    if (speedBps >= 1024 * 1024) {
      return '${(speedBps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else {
      return '${(speedBps / 1024).toStringAsFixed(1)} KB/s';
    }
  }

  String get eta {
    if (speedBps <= 0 || isComplete) return "--";
    final remainingBytes = totalBytes - bytesTransferred;
    final remainingSeconds = (remainingBytes / speedBps).round();
    
    final minutes = (remainingSeconds / 60).floor();
    final seconds = remainingSeconds % 60;
    
    if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }
}
