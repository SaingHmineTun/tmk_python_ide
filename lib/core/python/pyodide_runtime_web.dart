import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'python_execution_result.dart';
import 'python_runtime.dart';

class PyodideRuntime implements PythonRuntime {
  Completer<void>? _initializing;
  Completer<PythonExecutionResult>? _execution;
  void Function(String)? _onStdout;
  void Function(String)? _onStderr;
  void Function()? _onOutputReset;
  void Function(String)? _onInputRequested;
  DateTime? _startedAt;
  web.Worker? _worker;
  bool _ready = false;
  bool _running = false;
  int _nextExecutionId = 0;

  @override
  bool get isReady => _ready;

  @override
  bool get isRunning => _running;

  @override
  Widget get hostView => const SizedBox.shrink();

  @override
  Future<void> initialize() {
    if (_ready) return Future.value();
    if (_initializing != null) return _initializing!.future;
    _initializing = Completer<void>();
    _startWorker();
    return _initializing!.future;
  }

  void _startWorker() {
    try {
      final worker = web.Worker(
        'assets/assets/runtime/pyodide_worker.mjs'.toJS,
        web.WorkerOptions(type: 'module'),
      );
      worker.onmessage = ((web.MessageEvent event) {
        final value = event.data?.dartify();
        if (value is Map) _handleMessage(value.cast<Object?, Object?>());
      }).toJS;
      worker.onerror = ((web.Event _) {
        _handleRuntimeError('Python worker failed to start.');
      }).toJS;
      _worker = worker;
    } catch (error) {
      _handleRuntimeError('Python worker failed to start: $error');
    }
  }

  @override
  Future<PythonExecutionResult> execute(
    String code, {
    required void Function(String text) onStdout,
    required void Function(String text) onStderr,
    required void Function() onOutputReset,
    required void Function(String prompt) onInputRequested,
  }) async {
    await initialize();
    if (_running) throw StateError('Python is already running.');
    _running = true;
    _onStdout = onStdout;
    _onStderr = onStderr;
    _onOutputReset = onOutputReset;
    _onInputRequested = onInputRequested;
    _startedAt = DateTime.now();
    _execution = Completer<PythonExecutionResult>();
    _worker!.postMessage(
      {'type': 'execute', 'id': ++_nextExecutionId, 'code': code}.jsify(),
    );
    return _execution!.future;
  }

  @override
  Future<void> provideInput(String input) async {
    _worker?.postMessage({'type': 'input', 'input': input}.jsify());
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _worker?.terminate();
    _worker = null;
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
    _startWorker();
  }

  void _handleMessage(Map<Object?, Object?> message) {
    switch (message['type']) {
      case 'ready':
        _ready = true;
        if (!(_initializing?.isCompleted ?? true)) _initializing!.complete();
      case 'stdout':
        _onStdout?.call(message['data'] as String? ?? '');
      case 'stderr':
        _onStderr?.call(message['data'] as String? ?? '');
      case 'resetOutput':
        _onOutputReset?.call();
      case 'inputRequest':
        _onInputRequested?.call(message['prompt'] as String? ?? '');
      case 'completed':
        _finish(
          PythonExecutionResult(
            succeeded: message['success'] as bool? ?? false,
            exitCode: (message['exitCode'] as num?)?.toInt() ?? 1,
            duration: DateTime.now().difference(_startedAt ?? DateTime.now()),
            error: message['error'] as String?,
          ),
        );
      case 'runtimeError':
        _handleRuntimeError(
          message['data'] as String? ?? 'Unknown Python runtime error.',
        );
    }
  }

  void _handleRuntimeError(String error) {
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

  void _finish(PythonExecutionResult result) {
    _running = false;
    if (!(_execution?.isCompleted ?? true)) _execution!.complete(result);
    _onStdout = null;
    _onStderr = null;
    _onOutputReset = null;
    _onInputRequested = null;
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
    _worker?.terminate();
    _worker = null;
  }
}
