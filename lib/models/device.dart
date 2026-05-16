import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';
part 'device.g.dart';

@freezed
class DeviceCandidate with _$DeviceCandidate {
  const factory DeviceCandidate({
    required String ip,
    required int port,
    required String source,
  }) = _DeviceCandidate;

  factory DeviceCandidate.fromJson(Map<String, dynamic> json) => _$DeviceCandidateFromJson(json);
}

@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String name,
    required String ip,
    required String os,
    required int port,
    required bool isPaired,
    required DateTime lastSeen,
    int? latencyMs,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}
