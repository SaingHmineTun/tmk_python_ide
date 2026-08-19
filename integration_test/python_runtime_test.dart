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

    final codeEditor = tester.widget<CodeEditor>(find.byType(CodeEditor));
    final editor = codeEditor.controller!;
    await tester.tap(find.byType(CodeEditor));
    await tester.pump();
    editor.text = 'abc';
    editor.selection = const CodeLineSelection.collapsed(index: 0, offset: 1);
    await tester.tap(find.text('→'));
    await tester.pump();
    expect(editor.selection.extentOffset, 2);
    await tester.tap(find.text('←'));
    await tester.pump();
    expect(editor.selection.extentOffset, 1);
    await tester.tap(find.text('('));
    await tester.pump();
    expect(codeEditor.focusNode?.hasFocus, isTrue);
    expect(editor.text, contains('()'));
    editor.text = 'print("Hello, World!")';

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
    editor.text = 'print("No newline", end="")';
    await tester.tap(find.text('Run'));
    await _pumpUntil(
      tester,
      find.textContaining('No newline'),
      const Duration(seconds: 20),
    );
    if (find.textContaining('No newline').evaluate().isEmpty) {
      final console = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((widget) => widget.data)
          .whereType<String>()
          .toList();
      debugPrint('NO-NEWLINE TEST CONSOLE: $console; EDITOR: ${editor.text}');
    }
    expect(find.textContaining('No newline'), findsWidgets);
    expect(find.textContaining('Finished successfully'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pump();
    editor.text =
        "name = input('Your name: ')\n"
        "level = input('Learning level: ')\n"
        "print(f'Hello, {name}! Level: {level}')";
    await tester.tap(find.text('Run'));
    await _pumpUntil(
      tester,
      find.text('Python input'),
      const Duration(seconds: 20),
    );
    if (find.text('Python input').evaluate().isEmpty) {
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .toList();
      final console = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((widget) => widget.data)
          .whereType<String>()
          .toList();
      debugPrint('INPUT TEST VISIBLE TEXT: $labels');
      debugPrint('INPUT TEST CONSOLE: $console');
    }
    expect(find.text('Python input'), findsOneWidget);
    expect(find.text('Your name: '), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.text('Send'));
    await _pumpUntil(
      tester,
      find.text('Learning level: '),
      const Duration(seconds: 20),
    );
    expect(find.text('Learning level: '), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Beginner');
    await tester.tap(find.text('Send'));
    await _pumpUntil(
      tester,
      find.textContaining('Hello, Ada! Level: Beginner'),
      const Duration(seconds: 20),
    );
    expect(find.textContaining('Hello, Ada! Level: Beginner'), findsWidgets);
    expect(find.textContaining('OSError: [Errno 29]'), findsNothing);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pump();
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
