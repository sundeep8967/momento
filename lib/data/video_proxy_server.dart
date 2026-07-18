import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class VideoProxyServer {
  static final VideoProxyServer instance = VideoProxyServer._internal();
  VideoProxyServer._internal();

  HttpServer? _server;
  int? get port => _server?.port;

  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      debugPrint('VideoProxyServer started on port $port');
      _server!.listen(_handleRequest);
    } catch (e) {
      debugPrint('Failed to start VideoProxyServer: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  String getProxyUrl(String cloudUrl, String clipId) {
    if (_server == null) return cloudUrl; // Fallback if server failed
    final encodedUrl = Uri.encodeComponent(cloudUrl);
    return 'http://127.0.0.1:$port/proxy?url=$encodedUrl&id=$clipId';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.uri.path != '/proxy') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      final url = request.uri.queryParameters['url'];
      final id = request.uri.queryParameters['id'];

      if (url == null || id == null) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final localFile = File('${docsDir.path}/clip_$id.mp4');

      if (await localFile.exists()) {
        await _serveLocalFile(request, localFile);
      } else {
        // Smart Redirect: File not local, let video player fetch from cloud
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, url)
          ..close();
      }
    } catch (e) {
      debugPrint('Proxy error: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..close();
    }
  }

  Future<void> _serveLocalFile(HttpRequest request, File file) async {
    final response = request.response;
    final fileLength = await file.length();
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

    response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    response.headers.set(HttpHeaders.contentTypeHeader, 'video/mp4');

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.tryParse(parts[0]) ?? 0;
      final end = parts.length > 1 && parts[1].isNotEmpty
          ? int.tryParse(parts[1]) ?? fileLength - 1
          : fileLength - 1;

      if (start >= fileLength || end >= fileLength || start > end) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$fileLength');
        response.close();
        return;
      }

      final contentLength = end - start + 1;
      response.statusCode = HttpStatus.partialContent;
      response.headers.set(HttpHeaders.contentLengthHeader, contentLength.toString());
      response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$fileLength');

      await response.addStream(file.openRead(start, end + 1));
    } else {
      response.headers.set(HttpHeaders.contentLengthHeader, fileLength.toString());
      await response.addStream(file.openRead());
    }

    await response.close();
  }
}
