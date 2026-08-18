import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import 'about_developer_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsProvider);
    final controller = ref.read(editorSettingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _SectionTitle('Appearance'),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (value) => value == null
                  ? null
                  : controller.update(settings.copyWith(themeMode: value)),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          ListTile(
            title: const Text('Editor font size'),
            subtitle: Slider(
              value: settings.fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              label: settings.fontSize.round().toString(),
              onChanged: (value) =>
                  controller.update(settings.copyWith(fontSize: value)),
            ),
            trailing: Text(settings.fontSize.round().toString()),
          ),
          const _SectionTitle('Editor'),
          SwitchListTile(
            title: const Text('Line numbers'),
            value: settings.lineNumbers,
            onChanged: (value) =>
                controller.update(settings.copyWith(lineNumbers: value)),
          ),
          SwitchListTile(
            title: const Text('Word wrap'),
            value: settings.wordWrap,
            onChanged: (value) =>
                controller.update(settings.copyWith(wordWrap: value)),
          ),
          SwitchListTile(
            title: const Text('Auto indent'),
            subtitle: const Text('Indent after Python block colons'),
            value: settings.autoIndent,
            onChanged: (value) =>
                controller.update(settings.copyWith(autoIndent: value)),
          ),
          SwitchListTile(
            title: const Text('Auto-close brackets'),
            value: settings.autoClosingBrackets,
            onChanged: (value) => controller.update(
              settings.copyWith(autoClosingBrackets: value),
            ),
          ),
          const _SectionTitle('Python'),
          const ListTile(
            leading: Icon(Icons.offline_bolt_outlined),
            title: Text('On-device Pyodide'),
            subtitle: Text(
              'Python and the standard library are bundled for offline use. Code stays on this device.',
            ),
          ),
          const _SectionTitle('About'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('About Developer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AboutDeveloperScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );
}
