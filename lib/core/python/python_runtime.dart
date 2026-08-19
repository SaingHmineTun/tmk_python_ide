import 'package:flutter/widgets.dart';

import 'python_execution_result.dart';

abstract class PythonRuntime {
  Future<void> initialize();

  Future<PythonExecutionResult> execute(
    String code, {
    required void Function(String text) onStdout,
    required void Function(String text) onStderr,
    required void Function() onOutputReset,
    required void Function(String prompt) onInputRequested,
  });

  Future<void> provideInput(String input);
  Future<void> stop();
  bool get isReady;
  bool get isRunning;

  /// The invisible platform host required by embedded runtimes.
  Widget get hostView;

  void dispose();
}
