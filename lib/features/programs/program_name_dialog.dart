import 'package:flutter/material.dart';

Future<String?> showProgramNameDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ProgramNameDialog(
      title: title,
      actionLabel: actionLabel,
      initialName: initialName,
    ),
  );
}

class _ProgramNameDialog extends StatefulWidget {
  const _ProgramNameDialog({
    required this.title,
    required this.actionLabel,
    required this.initialName,
  });

  final String title;
  final String actionLabel;
  final String initialName;

  @override
  State<_ProgramNameDialog> createState() => _ProgramNameDialogState();
}

class _ProgramNameDialogState extends State<_ProgramNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    var name = _controller.text.trim();
    if (name.toLowerCase().endsWith('.py')) {
      name = name.substring(0, name.length - 3).trim();
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter a program name.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Program name',
        hintText: 'my_first_program',
        helperText: 'Use a clear name; .py is added automatically.',
        suffixText: '.py',
        errorText: _error,
      ),
      onSubmitted: (_) => _submit(),
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
