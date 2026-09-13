import 'package:flutter_test/flutter_test.dart';
import 'package:tmk_python_ide/models/console_message.dart';
import 'package:tmk_python_ide/models/python_program.dart';
import 'package:tmk_python_ide/models/python_project.dart';

void main() {
  test('PythonProgram preserves Unicode through map conversion', () {
    final now = DateTime.utc(2026, 8, 16);
    final program = PythonProgram(
      id: 7,
      projectId: 3,
      folderPath: 'utils/helpers',
      name: 'မႂ်ႇသုင်',
      code: 'print("မႂ်ႇသုင်ၶႃႈ 👋")',
      createdAt: now,
      updatedAt: now,
    );

    final restored = PythonProgram.fromMap(program.toMap());
    expect(restored.name, program.name);
    expect(restored.code, program.code);
    expect(restored.id, 7);
    expect(restored.projectId, 3);
    expect(restored.folderPath, 'utils/helpers');
  });

  test('PythonProject preserves name and dates through map conversion', () {
    final now = DateTime.utc(2026, 9, 1);
    final project = PythonProject(
      id: 11,
      name: 'Guessing Game',
      createdAt: now,
      updatedAt: now,
    );

    final restored = PythonProject.fromMap(project.toMap());
    expect(restored.id, 11);
    expect(restored.name, 'Guessing Game');
    expect(restored.createdAt, now);
    expect(restored.updatedAt, now);
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