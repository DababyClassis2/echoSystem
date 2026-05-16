import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../models/transfer_session.dart';

class ChunkedUploader {
  final Dio dio;
  static const int chunkSize = 4 * 1024 * 1024; // 4MB

  ChunkedUploader(this.dio);

  Stream<TransferProgress> upload({
    required String targetIp,
    required int targetPort,
    required File file,
    required String sessionId,
  }) async* {
    final fileName = p.basename(file.path);
    final totalBytes = await file.length();
    final baseUrl = 'http://$targetIp:$targetPort/api/v1/files/upload-chunk';
    
    int offset = 0;
    try {
      final headRes = await dio.head(
        baseUrl,
        options: Options(headers: {
          'X-Session-Id': sessionId,
          'X-File-Name': fileName,
        }),
      );
      offset = int.tryParse(headRes.headers['X-Received-Bytes']?.first ?? '0') ?? 0;
    } catch (_) {
      offset = 0;
    }

    final raf = await file.open();
    await raf.setPosition(offset);
    
    final startTime = DateTime.now();
    
    try {
      while (offset < totalBytes) {
        final length = (offset + chunkSize > totalBytes) ? (totalBytes - offset) : chunkSize;
        final buffer = await raf.read(length);
        
        bool success = false;
        int retries = 0;
        
        while (!success && retries < 3) {
          try {
            await dio.put(
              baseUrl,
              data: Stream.fromIterable([buffer]),
              options: Options(headers: {
                'X-Session-Id': sessionId,
                'X-File-Name': fileName,
                'Content-Range': 'bytes $offset-${offset + length - 1}/$totalBytes',
                'Content-Type': 'application/octet-stream',
              }),
            );
            success = true;
          } on DioException catch (e) {
            retries++;
            if (retries >= 3) rethrow;
            await Future.delayed(Duration(seconds: 1 << retries));
          }
        }

        offset += length;
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final speed = elapsed > 0 ? offset / elapsed : 0.0;

        yield TransferProgress(
          sessionId: sessionId,
          fileName: fileName,
          bytesTransferred: offset,
          totalBytes: totalBytes,
          speedBps: speed,
          isComplete: offset == totalBytes,
        );
      }
    } catch (e) {
      yield TransferProgress(
        sessionId: sessionId,
        fileName: fileName,
        bytesTransferred: offset,
        totalBytes: totalBytes,
        speedBps: 0,
        error: e.toString(),
      );
    } finally {
      await raf.close();
    }
  }
}
