import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

Map<Type, Action<Intent>>? buildIosWebEditorShortcutOverrides(
  CodeLineEditingController controller, {
  bool? enabled,
}) {
  final useWorkaround =
      enabled ?? (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);
  if (!useWorkaround) return null;

  return {
    DoNothingAndStopPropagationTextIntent:
        CallbackAction<DoNothingAndStopPropagationTextIntent>(
          onInvoke: (_) {
            controller.replaceSelection(' ');
            controller.makeCursorVisible();
            return null;
          },
        ),
  };
}
