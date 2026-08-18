import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'python_execution_result.dart';
import 'python_runtime.dart';

class PyodideRuntime implements PythonRuntime {
  PyodideRuntime() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'PythonBridge',
        onMessageReceived: (message) => _handleMessage(message.message),
      );
  }

  late final WebViewController _controller;
  Completer<void>? _initializing;
  Completer<PythonExecutionResult>? _execution;
  void Function(String)? _onStdout;
  void Function(String)? _onStderr;
  DateTime? _startedAt;
  HttpServer? _assetServer;
  bool _ready = false;
  bool _running = false;
  int _nextExecutionId = 0;

  @override
  bool get isReady => _ready;

  @override
  bool get isRunning => _running;

  @override
  Widget get hostView => IgnorePointer(
    child: SizedBox(
      width: 1,
      height: 1,
      child: Opacity(opacity: 0, child: WebViewWidget(controller: _controller)),
    ),
  );

  @override
  Future<void> initialize() {
    if (_ready) return Future.value();
    if (_initializing != null) return _initializing!.future;
    _initializing = Completer<void>();
    _startAssetServer()
        .then((uri) {
          _controller.loadRequest(uri).catchError((Object error) {
            if (!(_initializing?.isCompleted ?? true)) {
              _initializing!.completeError(error);
            }
          });
        })
        .catchError((Object error) {
          if (!(_initializing?.isCompleted ?? true)) {
            _initializing!.completeError(error);
          }
        });
    return _initializing!.future;
  }

  Future<Uri> _startAssetServer() async {
    if (_assetServer == null) {
      _assetServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _assetServer!.listen(_serveAsset);
    }
    return Uri.parse(
      'http://${_assetServer!.address.address}:${_assetServer!.port}/assets/runtime/index.html',
    );
  }

  Future<void> _serveAsset(HttpRequest request) async {
    try {
      final path = request.uri.path.startsWith('/')
          ? request.uri.path.substring(1)
          : request.uri.path;
      if (!path.startsWith('assets/') || path.contains('..')) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }
      final data = await rootBundle.load(path);
      request.response.headers
        ..set('Cross-Origin-Opener-Policy', 'same-origin')
        ..set('Cross-Origin-Embedder-Policy', 'require-corp')
        ..set('Cache-Control', 'public, max-age=31536000')
        ..contentType = ContentType.parse(_mimeType(path));
      request.response.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (error) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(error);
    }
    await request.response.close();
  }

  String _mimeType(String path) {
    if (path.endsWith('.html')) return 'text/html; charset=utf-8';
    if (path.endsWith('.js') || path.endsWith('.mjs')) {
      return 'text/javascript; charset=utf-8';
    }
    if (path.endsWith('.wasm')) return 'application/wasm';
    if (path.endsWith('.json')) return 'application/json';
    if (path.endsWith('.zip')) return 'application/zip';
    return 'application/octet-stream';
  }

  @override
  Future<PythonExecutionResult> execute(
    String code, {
    required void Function(String text) onStdout,
    required void Function(String text) onStderr,
  }) async {
    await initialize();
    if (_running) throw StateError('Python is already running.');
    _running = true;
    _onStdout = onStdout;
    _onStderr = onStderr;
    _startedAt = DateTime.now();
    _execution = Completer<PythonExecutionResult>();
    final id = ++_nextExecutionId;
    await _controller.runJavaScript(
      'window.tmkPython.execute($id, ${jsonEncode(code)});',
    );
    return _execution!.future;
  }

  @override
  Future<void> provideInput(String input) => _controller.runJavaScript(
    'window.tmkPython.provideInput(${jsonEncode(input)});',
  );

  @override
  Future<void> stop() async {
    if (!_running) return;
    await _controller.runJavaScript('window.tmkPython.stop();');
    _finish(
      const PythonExecutionResult(
        succeeded: false,
        exitCode: 130,
        duration: Duration.zero,
        error: 'Execution stopped by user.',
      ),
    );
    _ready = false;
    _initializing = Completer<void>();
  }

  void _handleMessage(String raw) {
    final message = jsonDecode(raw) as Map<String, dynamic>;
    switch (message['type']) {
      case 'ready':
        _ready = true;
        if (!(_initializing?.isCompleted ?? true)) _initializing!.complete();
      case 'stdout':
        _onStdout?.call(message['data'] as String? ?? '');
      case 'stderr':
        _onStderr?.call(message['data'] as String? ?? '');
      case 'completed':
        _finish(
          PythonExecutionResult(
            succeeded: message['success'] as bool? ?? false,
            exitCode: message['exitCode'] as int? ?? 1,
            duration: DateTime.now().difference(_startedAt ?? DateTime.now()),
            error: message['error'] as String?,
          ),
        );
      case 'runtimeError':
        final error =
            message['data'] as String? ?? 'Unknown Python runtime error.';
        if (!(_initializing?.isCompleted ?? true)) {
          _initializing!.completeError(StateError(error));
        }
        _onStderr?.call('$error\n');
        _finish(
          PythonExecutionResult(
            succeeded: false,
            exitCode: 1,
            duration: DateTime.now().difference(_startedAt ?? DateTime.now()),
            error: error,
          ),
        );
    }
  }

  void _finish(PythonExecutionResult result) {
    _running = false;
    if (!(_execution?.isCompleted ?? true)) _execution!.complete(result);
    _onStdout = null;
    _onStderr = null;
  }

  @override
  void dispose() {
    _finish(
      const PythonExecutionResult(
        succeeded: false,
        exitCode: 130,
        duration: Duration.zero,
        error: 'Runtime disposed.',
      ),
    );
    _assetServer?.close(force: true);
  }
}
