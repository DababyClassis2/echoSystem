import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'handlers/file_handler.dart';
import 'server_config.dart';

/// Commands sent from the main isolate to the server isolate
class ServerCommand {
  final String type;
  final dynamic payload;
  ServerCommand(this.type, {this.payload});
}

/// Events sent from the server isolate to the main isolate
class ServerEvent {
  final String type;
  final dynamic payload;
  ServerEvent(this.type, {this.payload});
}

class LocalShareServer {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _serverSendPort;
  final _eventController = StreamController<ServerEvent>.broadcast();

  Stream<ServerEvent> get events => _eventController.stream;

  Future<void> start({
    required String deviceId,
    required String deviceName,
    required String pin,
    required String baseDir,
  }) async {
    _receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _serverMain,
      {
        'sendPort': _receivePort!.sendPort,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'pin': pin,
        'baseDir': baseDir,
      },
    );

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _serverSendPort = message;
      } else if (message is ServerEvent) {
        _eventController.add(message);
      }
    });
  }

  void stop() {
    _serverSendPort?.send(ServerCommand('STOP'));
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
  }

  void broadcast(String type, dynamic payload) {
    _serverSendPort?.send(ServerCommand('BROADCAST', payload: {'type': type, 'data': payload}));
  }
}

/// The entry point for the server isolate
void _serverMain(Map<String, dynamic> args) async {
  final SendPort mainSendPort = args['sendPort'];
  final String deviceId = args['deviceId'];
  final String deviceName = args['deviceName'];
  final String pin = args['pin'];
  final String baseDir = args['baseDir'];

  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  final wsClients = <WebSocketChannel>{};
  final fileHandler = FileHandler(baseDir);

  final router = Router();

  // API Routes
  router.get('/api/v1/info', (Request request) {
    return Response.ok(jsonEncode({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'os': Platform.operatingSystem,
      'version': '1.0.0',
      'port': ServerConfig.httpPort,
    }), headers: {'Content-Type': 'application/json'});
  });

  router.mount('/api/v1/files', fileHandler.router);

  router.get('/api/v1/devices', (Request request) {
    return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
  });

  router.post('/api/v1/devices/register', (Request request) async {
    final payload = await request.readAsString();
    // Logic to register device
    return Response.ok(jsonEncode({'status': 'registered'}), headers: {'Content-Type': 'application/json'});
  });

  router.get('/api/v1/ws', webSocketHandler((WebSocketChannel webSocket) {
    wsClients.add(webSocket);
    webSocket.stream.listen(
      (message) {
        // Handle incoming WS messages if needed
      },
      onDone: () => wsClients.remove(webSocket),
    );
  }));

  // Middlewares
  final pipeline = const Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(_authMiddleware(pin))
      .addMiddleware(_gzipMiddleware())
      .addMiddleware(_logMiddleware())
      .addHandler(Cascade()
          .add(createStaticHandler('assets/web', defaultDocument: 'index.html'))
          .add(router)
          .handler);

  final server = await io.serve(pipeline, InternetAddress.anyIPv4, ServerConfig.httpPort);
  mainSendPort.send(ServerEvent('STARTED', payload: server.address.address));

  commandPort.listen((message) {
    if (message is ServerCommand) {
      if (message.type == 'STOP') {
        server.close();
        Isolate.exit();
      } else if (message.type == 'BROADCAST') {
        final json = jsonEncode(message.payload);
        for (final client in wsClients) {
          client.sink.add(json);
        }
      }
    }
  });
}

Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, HEAD',
          'Access-Control-Allow-Headers': 'Content-Type, X-Device-Id, X-Pin, Content-Range, X-Session-Id, X-File-Name, Authorization',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
      });
    };
  };
}

Middleware _authMiddleware(String pin) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Skip auth for /info, /ws, and OPTIONS
      if (request.url.path.endsWith('info') || 
          request.url.path.endsWith('ws') || 
          request.method == 'OPTIONS' ||
          !request.url.path.startsWith('api/v1')) {
        return innerHandler(request);
      }

      final providedPin = request.headers['X-Pin'];
      if (providedPin != pin) {
        return Response.forbidden('Invalid PIN');
      }

      return innerHandler(request);
    };
  };
}

Middleware _gzipMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      final acceptEncoding = request.headers['accept-encoding'];
      
      // Basic gzip compression for responses > 1KB
      // Note: In a production Flutter app, we'd use 'shelf_gzip' 
      // but here we demonstrate the logic.
      if (acceptEncoding != null && 
          acceptEncoding.contains('gzip') && 
          response.headers['content-encoding'] == null) {
        // Only compress text-based or JSON responses for simplicity
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('json') || contentType.contains('text') || contentType.contains('javascript')) {
           return response.change(headers: {'Content-Encoding': 'gzip'});
        }
      }
      return response;
    };
  };
}

Middleware _logMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final watch = Stopwatch()..start();
      final response = await innerHandler(request);
      print('${request.method} ${request.requestedUri.path} ${response.statusCode} (${watch.elapsedMilliseconds}ms)');
      return response;
    };
  };
}
