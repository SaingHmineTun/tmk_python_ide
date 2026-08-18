import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shell/ide_shell.dart';
import '../providers/app_providers.dart';
import 'theme.dart';

const appName = 'Python IDE';

class TmkPythonIdeApp extends ConsumerWidget {
  const TmkPythonIdeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsProvider);
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const IdeShell(),
    );
  }
}
