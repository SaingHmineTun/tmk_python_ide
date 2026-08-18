import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:tmk_python_ide/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled Python executes and streams output into Flutter', (
    tester,
  ) async {
    app.main();
    await tester.pump();

    await _pumpUntil(
      tester,
      find.text('Python Ready'),
      const Duration(seconds: 60),
    );
    if (find.text('Python Ready').evaluate().isEmpty) {
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .toList();
      debugPrint('VISIBLE TEXT: $labels');
      final console = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((widget) => widget.data)
          .whereType<String>()
          .toList();
      debugPrint('CONSOLE TEXT: $console');
    }
    expect(find.text('Python Ready'), findsOneWidget);

    await tester.tap(find.text('Run'));
    await tester.pump();

    await _pumpUntil(
      tester,
      find.textContaining('Hello, World!'),
      const Duration(seconds: 30),
    );
    expect(find.textContaining('Hello, World!'), findsWidgets);
    expect(find.textContaining('Finished successfully'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pump();
    final editor = tester
        .widget<CodeEditor>(find.byType(CodeEditor))
        .controller!;
    editor.text = 'print(undefined_variable)';
    await tester.tap(find.text('Run'));
    await _pumpUntil(
      tester,
      find.textContaining('NameError'),
      const Duration(seconds: 20),
    );
    if (find.textContaining('NameError').evaluate().isEmpty) {
      final console = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((widget) => widget.data)
          .whereType<String>()
          .toList();
      debugPrint('ERROR TEST CONSOLE: $console; EDITOR: ${editor.text}');
    }
    expect(find.textContaining('NameError'), findsWidgets);

    editor.text = 'while True:\n    pass';
    await tester.tap(find.text('Run'));
    await _pumpUntil(tester, find.text('Stop'), const Duration(seconds: 5));
    expect(find.text('Stop'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    await _pumpUntil(tester, find.text('Stopped'), const Duration(seconds: 5));
    expect(find.text('Stopped'), findsOneWidget);
    expect(find.textContaining('Stopped'), findsWidgets);
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder,
  Duration timeout,
) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}
