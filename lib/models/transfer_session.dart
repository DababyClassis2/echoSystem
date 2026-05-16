import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_session.freezed.dart';
part 'transfer_session.g.dart';

enum TransferDirection { upload, download }
enum TransferState { queued, active, paused, complete, failed, cancelled }

@freezed
class TransferSession with _$TransferSession {
  const factory TransferSession({
    required String id,
    required String fileName,
    required int totalBytes,
    required int transferredBytes,
    required double speedBps,
    required TransferDirection direction,
    required TransferState state,
    required String targetDeviceId,
    required DateTime startedAt,
    DateTime? completedAt,
  }) = _TransferSession;

  factory TransferSession.fromJson(Map<String, dynamic> json) => _$TransferSessionFromJson(json);
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
