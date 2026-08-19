import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:tmk_python_ide/features/editor/ios_web_editor_workarounds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS web Space shortcut inserts one literal space', () {
    final controller = CodeLineEditingController.fromText('print()');
    addTearDown(controller.dispose);
    controller.selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 6,
    );

    final overrides = buildIosWebEditorShortcutOverrides(
      controller,
      enabled: true,
    );
    final action = overrides![DoNothingAndStopPropagationTextIntent]!;
    ActionDispatcher().invokeAction(
      action,
      const DoNothingAndStopPropagationTextIntent(),
    );

    expect(controller.text, 'print( )');
    expect(controller.selection.extentOffset, 7);
  });

  test('workaround stays disabled on other platforms', () {
    final controller = CodeLineEditingController.fromText('print()');
    addTearDown(controller.dispose);

    expect(
      buildIosWebEditorShortcutOverrides(controller, enabled: false),
      isNull,
    );
  });

  test('iPhone web detection enables the workaround automatically', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final controller = CodeLineEditingController.fromText('print()');
    addTearDown(controller.dispose);

    expect(buildIosWebEditorShortcutOverrides(controller), isNotNull);
  }, skip: !kIsWeb);
}
