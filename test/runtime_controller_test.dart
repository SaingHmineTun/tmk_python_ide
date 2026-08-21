import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmk_python_ide/core/python/python_execution_result.dart';
import 'package:tmk_python_ide/core/python/python_runtime.dart';
import 'package:tmk_python_ide/models/execution_state.dart';
import 'package:tmk_python_ide/providers/app_providers.dart';

void main() {
  test('runtime stays lazy until syntax check or run', () async {
    final runtime = _FakePythonRuntime();
    final controller = RuntimeController(runtime);
    addTearDown(controller.dispose);

    expect(controller.status, PythonRuntimeStatus.idle);
    expect(runtime.initializeCalls, 0);

    expect(await controller.checkSyntax('print("hello")'), isTrue);
    expect(runtime.initializeCalls, 1);
    expect(controller.status, PythonRuntimeStatus.ready);
    expect(controller.messages.single.text, 'Syntax check passed\n');
  });

  test('syntax failure is reported without running learner code', () async {
    final runtime = _FakePythonRuntime(syntaxSucceeds: false);
    final controller = RuntimeController(runtime);
    addTearDown(controller.dispose);

    expect(await controller.checkSyntax('if True print()'), isFalse);
    expect(
      controller.messages.last.text,
      'Fix the syntax error before running.\n',
    );
  });
}

class _FakePythonRuntime implements PythonRuntime {
  _FakePythonRuntime({this.syntaxSucceeds = true});

  final bool syntaxSucceeds;
  int initializeCalls = 0;
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  bool get isRunning => false;

  @override
  Widget get hostView => const SizedBox.shrink();

  @override
  Future<void> initialize() async {
    initializeCalls++;
    _ready = true;
  }

  @override
  Future<PythonExecutionResult> execute(
    String code, {
    required void Function(String text) onStdout,
    required void Function(String text) onStderr,
    required void Function() onOutputReset,
    required void Function(String prompt) onInputRequested,
  }) async {
    if (!syntaxSucceeds) onStderr('SyntaxError: invalid syntax\n');
    return PythonExecutionResult(
      succeeded: syntaxSucceeds,
      exitCode: syntaxSucceeds ? 0 : 1,
      duration: const Duration(milliseconds: 1),
    );
  }

  @override
  Future<void> provideInput(String input) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
