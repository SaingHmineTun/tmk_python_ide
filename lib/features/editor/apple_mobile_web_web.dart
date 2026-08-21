import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

bool detectAppleMobileWeb() {
  final navigator = web.window.navigator;
  final userAgent = navigator.userAgent;
  final appleMobileUserAgent = RegExp(
    r'iPhone|iPad|iPod',
    caseSensitive: false,
  ).hasMatch(userAgent);
  final ipadDesktopMode =
      navigator.platform == 'MacIntel' && navigator.maxTouchPoints > 1;

  return defaultTargetPlatform == TargetPlatform.iOS ||
      appleMobileUserAgent ||
      ipadDesktopMode;
}
