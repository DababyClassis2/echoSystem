import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as p;

class FileHandler {
  final String baseDir;
  // Map<sessionId, RandomAccessFile>
  final Map<String, RandomAccessFile> _uploadSessions = {};

  FileHandler(this.baseDir) {
    Directory(baseDir).createSync(recursive: true);
  }

  Router get router {
    final router = Router();

    // GET /files - List shared files
    router.get('/', (Request request) async {
      final dir = Directory(baseDir);
      if (!await dir.exists()) return Response.ok('[]');
      
      final files = await dir.list().where((e) => e is File).map((e) {
        final f = e as File;
        return {
          'name': p.basename(f.path),
          'size': f.lengthSync(),
          'modified': f.lastModifiedSync().toIso8601String(),
        };
      }).toList();
      
      return Response.ok(jsonEncode(files), headers: {'Content-Type': 'application/json'});
    });

    // GET /files/<id>/download - Download file
    router.get('/<id>/download', (Request request, String id) async {
      final file = File(p.join(baseDir, id));
      if (!await file.exists()) return Response.notFound('File not found');

      final length = await file.length();
      final range = request.headers['range'];

      if (range != null && range.startsWith('bytes=')) {
        final parts = range.substring(6).split('-');
        final start = int.parse(parts[0]);
        final end = parts.length > 1 && parts[1].isNotEmpty 
            ? int.parse(parts[1]) 
            : length - 1;

        if (start >= length) {
          return Response(416, body: 'Requested Range Not Satisfiable');
        }

        final stream = file.openRead(start, end + 1);
        return Response(206, body: stream, headers: {
          'Content-Range': 'bytes $start-$end/$length',
          'Accept-Ranges': 'bytes',
          'Content-Length': '${end - start + 1}',
          'Content-Type': 'application/octet-stream',
        });
      }

      return Response.ok(file.openRead(), headers: {
        'Content-Length': '$length',
        'Content-Type': 'application/octet-stream',
        'Accept-Ranges': 'bytes',
      });
    });

    // HEAD /files/upload-chunk - Resume check
    router.head('/upload-chunk', (Request request) async {
      final sessionId = request.headers['X-Session-Id'];
      final fileName = request.headers['X-File-Name'];
      if (sessionId == null || fileName == null) return Response.badRequest();

      final tempFile = File(p.join(baseDir, '$fileName.tmp'));
      final receivedBytes = await tempFile.exists() ? await tempFile.length() : 0;

      return Response.ok(null, headers: {
        'X-Received-Bytes': '$receivedBytes',
      });
    });

    // PUT /files/upload-chunk - Chunked upload
    router.put('/upload-chunk', (Request request) async {
      final sessionId = request.headers['X-Session-Id'];
      final fileName = request.headers['X-File-Name'];
      final contentRange = request.headers['Content-Range']; // bytes start-end/total

      if (sessionId == null || fileName == null || contentRange == null) {
        return Response.badRequest(body: 'Missing headers');
      }

      final regExp = RegExp(r'bytes (\d+)-(\d+)/(\d+)');
      final match = regExp.firstMatch(contentRange);
      if (match == null) return Response.badRequest(body: 'Invalid Content-Range');

      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2)!);
      final total = int.parse(match.group(3)!);

      final tempPath = p.join(baseDir, '$fileName.tmp');
      RandomAccessFile raf;

      if (_uploadSessions.containsKey(sessionId)) {
        raf = _uploadSessions[sessionId]!;
      } else {
        raf = await File(tempPath).open(mode: FileMode.append);
        _uploadSessions[sessionId] = raf;
      }

      // Verify offset
      if (await raf.length() != start) {
        return Response(409, body: 'Conflict: Expected offset ${await raf.length()}');
      }

      final bytes = await request.read().toList();
      for (var chunk in bytes) {
        await raf.writeFrom(chunk);
      }

      if (end + 1 >= total) {
        await raf.close();
        _uploadSessions.remove(sessionId);
        final finalFile = File(p.join(baseDir, fileName));
        if (await finalFile.exists()) await finalFile.delete();
        await File(tempPath).rename(finalFile.path);
        
        // In a real app, we'd emit an event here via the Isolate's SendPort
        return Response.ok(jsonEncode({'status': 'completed', 'file': fileName}));
      }

      return Response.ok(jsonEncode({'status': 'chunk_received', 'offset': end + 1}));
    });

    // DELETE /files/<id>
    router.delete('/<id>', (Request request, String id) async {
      final file = File(p.join(baseDir, id));
      if (await file.exists()) {
        await file.delete();
        return Response.ok('Deleted');
      }
      return Response.notFound('File not found');
    });

    return router;
  }
}
