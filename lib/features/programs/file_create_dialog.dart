import 'package:flutter/material.dart';

Future<({String name, String folder})?> showFileCreateDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) {
  return showDialog<({String name, String folder})>(
    context: context,
    builder: (context) => _FileCreateDialog(title: title, actionLabel: actionLabel),
  );
}

class _FileCreateDialog extends StatefulWidget {
  const _FileCreateDialog({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  State<_FileCreateDialog> createState() => _FileCreateDialogState();
}

class _FileCreateDialogState extends State<_FileCreateDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  void _submit() {
    var name = _nameController.text.trim();
    if (name.toLowerCase().endsWith('.py')) {
      name = name.substring(0, name.length - 3).trim();
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter a file name.');
      return;
    }
    final folder = _normalizeFolder(_folderController.text.trim());
    Navigator.pop(context, (name: name, folder: folder));
  }

  /// Normalizes a folder/package path such as "utils/helpers" to "utils/helpers"
  /// without leading or trailing slashes. Empty means the project root.
  String _normalizeFolder(String value) {
    var path = value.replaceAll('\\', '/');
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'File name',
              hintText: 'my_module',
              helperText: 'Use a clear name; .py is added automatically.',
              suffixText: '.py',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _folderController,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Package or folder (optional)',
              hintText: 'math/geo',
              helperText: 'e.g. utils/helpers. Leave empty for the project root.',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
    ],
  );
}