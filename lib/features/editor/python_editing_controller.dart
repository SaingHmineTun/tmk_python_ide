import 'package:re_editor/re_editor.dart';

class PythonEditingController extends CodeLineEditingControllerDelegate {
  PythonEditingController._({
    required super.delegate,
    required this.autoIndent,
  });

  factory PythonEditingController.fromText(
    String text, {
    bool autoIndent = true,
    int tabSize = 4,
  }) {
    return PythonEditingController._(
      delegate: CodeLineEditingController.fromText(
        text,
        CodeLineOptions(indentSize: tabSize),
      ),
      autoIndent: autoIndent,
    );
  }

  bool autoIndent;

  @override
  void applyNewLine() {
    final cursor = selection.extent;
    final beforeCursor = extentLine.text
        .substring(0, cursor.offset)
        .trimRight();
    final shouldIndent = autoIndent && beforeCursor.endsWith(':');
    super.applyNewLine();
    if (shouldIndent) super.applyIndent();
  }
}
