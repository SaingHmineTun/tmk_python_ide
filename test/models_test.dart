import 'package:flutter_test/flutter_test.dart';
import 'package:tmk_python_ide/models/console_message.dart';
import 'package:tmk_python_ide/models/python_program.dart';

void main() {
  test('PythonProgram preserves Unicode through map conversion', () {
    final now = DateTime.utc(2026, 8, 16);
    final program = PythonProgram(
      id: 7,
      name: 'မႂ်ႇသုင်',
      code: 'print("မႂ်ႇသုင်ၶႃႈ 👋")',
      createdAt: now,
      updatedAt: now,
    );

    final restored = PythonProgram.fromMap(program.toMap());
    expect(restored.name, program.name);
    expect(restored.code, program.code);
    expect(restored.id, 7);
  });

  test('ConsoleMessage retains type and text', () {
    final message = ConsoleMessage(
      type: ConsoleMessageType.stderr,
      text: 'NameError: name is not defined\n',
      timestamp: DateTime.now(),
    );
    expect(message.type, ConsoleMessageType.stderr);
    expect(message.text, contains('NameError'));
  });
}
