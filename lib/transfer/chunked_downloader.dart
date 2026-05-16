import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../models/transfer_session.dart';

class ChunkedDownloader {
  final Dio dio;

  ChunkedDownloader(this.dio);

  Stream<TransferProgress> download({
    required String sourceIp,
    required int sourcePort,
    required String fileId,
    required String fileName,
    required String destDir,
    required String sessionId,
  }) async* {
    final tempPath = p.join(destDir, '$fileName.tmp');
    final finalPath = p.join(destDir, fileName);
    
    final tempFile = File(tempPath);
    int offset = 0;
    if (await tempFile.exists()) {
      offset = await tempFile.length();
    }

    final raf = await tempFile.open(mode: FileMode.append);
    final startTime = DateTime.now();
    int totalBytes = 0;

    try {
      final response = await dio.get<ResponseBody>(
        'http://$sourceIp:$sourcePort/api/v1/files/$fileId/download',
        options: Options(
          headers: {'Range': 'bytes=$offset-'},
          responseType: ResponseType.stream,
        ),
      );

      final contentRange = response.headers.value('content-range');
      if (contentRange != null) {
        totalBytes = int.tryParse(contentRange.split('/').last) ?? 0;
      } else {
        totalBytes = int.tryParse(response.headers.value('content-length') ?? '0') ?? 0;
        totalBytes += offset;
      }

      int downloadedInSession = 0;
      
      await for (final chunk in response.data!.stream) {
        await raf.writeFrom(chunk);
        offset += chunk.length;
        downloadedInSession += chunk.length;

        // Yield progress every 512KB
        if (downloadedInSession >= 512 * 1024 || offset == totalBytes) {
          downloadedInSession = 0;
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          final speed = elapsed > 0 ? (offset - (await tempFile.length() - downloadedInSession)) / elapsed : 0.0;
          // Re-calculating speed based on session progress for accuracy
          final sessionElapsed = DateTime.now().difference(startTime).inSeconds;
          final sessionSpeed = sessionElapsed > 0 ? (offset - (offset - chunk.length)) / 1 : 0.0; // simple fallback

          yield TransferProgress(
            sessionId: sessionId,
            fileName: fileName,
            bytesTransferred: offset,
            totalBytes: totalBytes,
            speedBps: sessionElapsed > 0 ? (offset - (offset - downloadedInSession)) / sessionElapsed : 0.0,
            isComplete: offset == totalBytes,
          );
        }
      }

      await raf.close();
      if (offset == totalBytes) {
        if (await File(finalPath).exists()) await File(finalPath).delete();
        await tempFile.rename(finalPath);
        yield TransferProgress(
          sessionId: sessionId,
          fileName: fileName,
          bytesTransferred: offset,
          totalBytes: totalBytes,
          speedBps: 0,
          isComplete: true,
        );
      }
    } catch (e) {
      await raf.close();
      yield TransferProgress(
        sessionId: sessionId,
        fileName: fileName,
        bytesTransferred: offset,
        totalBytes: totalBytes,
        speedBps: 0,
        error: e.toString(),
      );
    }
  }
}
