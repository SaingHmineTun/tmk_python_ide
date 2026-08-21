import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

import 'apple_mobile_web.dart';

Map<Type, Action<Intent>>? buildIosWebEditorShortcutOverrides(
  CodeLineEditingController controller, {
  bool? enabled,
}) {
  final useWorkaround = enabled ?? (kIsWeb && isAppleMobileWeb);
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
