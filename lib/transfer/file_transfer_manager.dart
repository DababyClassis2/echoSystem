import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';

import '../models/transfer_session.dart';
import '../models/device.dart';
import 'chunked_uploader.dart';
import 'chunked_downloader.dart';

class FileTransferManager extends StateNotifier<List<TransferSession>> {
  FileTransferManager() : super([]) {
    _loadSessions();
  }

  final _lock = Lock();
  final _semaphore = Lock(); // Used as a simple semaphore for 3 concurrent
  int _activeCount = 0;
  final _dio = Dio();
  
  static const String _prefKey = 'transfer_sessions';

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefKey);
    if (json != null) {
      final List<dynamic> list = jsonDecode(json);
      state = list.map((e) => TransferSession.fromJson(e)).toList();
      _resumeTransfers();
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_prefKey, json);
  }

  void _resumeTransfers() {
    for (var session in state) {
      if (session.state == TransferState.active || session.state == TransferState.queued) {
        _processSession(session.id);
      }
    }
  }

  Future<void> queueUpload(File file, Device targetDevice) async {
    final session = TransferSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: file.path.split('/').last,
      totalBytes: await file.length(),
      transferredBytes: 0,
      speedBps: 0,
      direction: TransferDirection.upload,
      state: TransferState.queued,
      targetDeviceId: targetDevice.id,
      startedAt: DateTime.now(),
    );

    state = [...state, session];
    await _saveSessions();
    _processSession(session.id, file: file, device: targetDevice);
  }

  Future<void> queueDownload(String fileId, String fileName, Device sourceDevice) async {
    final session = TransferSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      totalBytes: 0, // Will be updated on start
      transferredBytes: 0,
      speedBps: 0,
      direction: TransferDirection.download,
      state: TransferState.queued,
      targetDeviceId: sourceDevice.id,
      startedAt: DateTime.now(),
    );

    state = [...state, session];
    await _saveSessions();
    _processSession(session.id, fileId: fileId, device: sourceDevice);
  }

  Future<void> _processSession(String sessionId, {File? file, Device? device, String? fileId}) async {
    await _semaphore.synchronized(() async {
      while (_activeCount >= 3) {
        await Future.delayed(const Duration(seconds: 1));
      }
      _activeCount++;
      
      try {
        final session = state.firstWhere((s) => s.id == sessionId);
        if (session.state == TransferState.complete || session.state == TransferState.cancelled) return;

        state = [
          for (final s in state)
            if (s.id == sessionId) s.copyWith(state: TransferState.active) else s
        ];

        if (session.direction == TransferDirection.upload) {
          final uploader = ChunkedUploader(_dio);
          await for (final progress in uploader.upload(
            targetIp: device!.ip,
            targetPort: device.port,
            file: file!,
            sessionId: sessionId,
          )) {
            _updateState(progress);
          }
        } else {
          final downloader = ChunkedDownloader(_dio);
          final destDir = (await getApplicationDocumentsDirectory()).path + '/localshare/received/';
          await Directory(destDir).create(recursive: true);
          
          await for (final progress in downloader.download(
            sourceIp: device!.ip,
            sourcePort: device.port,
            fileId: fileId!,
            fileName: session.fileName,
            destDir: destDir,
            sessionId: sessionId,
          )) {
            _updateState(progress);
          }
        }
      } finally {
        _activeCount--;
      }
    });
  }

  void _updateState(TransferProgress progress) {
    state = [
      for (final s in state)
        if (s.id == progress.sessionId)
          s.copyWith(
            transferredBytes: progress.bytesTransferred,
            totalBytes: progress.totalBytes > 0 ? progress.totalBytes : s.totalBytes,
            speedBps: progress.speedBps,
            state: progress.isComplete 
                ? TransferState.complete 
                : (progress.error != null ? TransferState.failed : TransferState.active),
            completedAt: progress.isComplete ? DateTime.now() : null,
          )
        else
          s
    ];
    _saveSessions();
  }
}
