import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/styles/atom-one-dark-reasonable.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../models/console_message.dart';
import '../../models/execution_state.dart';
import '../../providers/app_providers.dart';
import '../programs/program_name_dialog.dart';
import 'python_editing_controller.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  PythonEditingController? _controller;
  Object? _loadedProgramIdentity;
  double _consoleHeight = 150;
  bool _consoleCollapsed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncController(EditorSession session, EditorSettings settings) {
    final program = session.current;
    if (program == null) return;
    final identity = '${program.id}:${program.createdAt.toIso8601String()}';
    if (_controller == null || identity != _loadedProgramIdentity) {
      _controller?.dispose();
      _controller = PythonEditingController.fromText(
        program.code,
        autoIndent: settings.autoIndent,
        tabSize: settings.tabSize,
      );
      _loadedProgramIdentity = identity;
    } else {
      _controller!.autoIndent = settings.autoIndent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(editorSessionProvider);
    final runtime = ref.watch(runtimeControllerProvider);
    final settings = ref.watch(editorSettingsProvider);
    _syncController(session, settings);
    final controller = _controller;

    if (session.loading || controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: InkWell(
          onTap: () => _rename(session.current!.name),
          child: Row(
            children: [
              Image.asset(
                'assets/images/python-snake-mascot.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 9),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Python IDE',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${session.current!.name}.py',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('new-python-file-button'),
            tooltip: 'Create new Python file',
            onPressed: () => _newProgram(session, controller),
            icon: const Icon(Icons.note_add_outlined),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: () => _save(session, controller),
            icon: const Icon(Icons.save_outlined),
          ),
          if (runtime.status == PythonRuntimeStatus.running)
            FilledButton.icon(
              onPressed: runtime.stop,
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('Stop'),
            )
          else
            FilledButton.icon(
              onPressed: runtime.status == PythonRuntimeStatus.starting
                  ? null
                  : () {
                      session.updateCode(controller.text);
                      setState(() => _consoleCollapsed = false);
                      runtime.run(controller.text);
                    },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Run'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _StatusStrip(controller: controller, status: runtime.status),
            Expanded(
              child: CodeEditor(
                controller: controller,
                onChanged: (value) => session.updateCode(controller.text),
                wordWrap: settings.wordWrap,
                autocompleteSymbols: settings.autoClosingBrackets,
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 24),
                style: CodeEditorStyle(
                  fontSize: settings.fontSize,
                  fontFamily: 'monospace',
                  fontFamilyFallback: const [
                    'Menlo',
                    'Noto Sans Myanmar',
                    'sans-serif',
                  ],
                  fontHeight: 1.45,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF101418)
                      : const Color(0xFFFAFAFA),
                  codeTheme: CodeHighlightTheme(
                    languages: {
                      'python': CodeHighlightThemeMode(mode: langPython),
                    },
                    theme: Theme.of(context).brightness == Brightness.dark
                        ? atomOneDarkReasonableTheme
                        : atomOneLightTheme,
                  ),
                ),
                indicatorBuilder: settings.lineNumbers
                    ? (context, editingController, chunkController, notifier) =>
                          DefaultCodeLineNumber(
                            controller: editingController,
                            notifier: notifier,
                          )
                    : null,
                leadingDivider: settings.lineNumbers
                    ? VerticalDivider(
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      )
                    : null,
                chunkAnalyzer: const NonCodeChunkAnalyzer(),
              ),
            ),
            _ConsolePanel(
              height: _consoleCollapsed ? 42 : _consoleHeight,
              collapsed: _consoleCollapsed,
              messages: runtime.messages,
              onToggle: () =>
                  setState(() => _consoleCollapsed = !_consoleCollapsed),
              onClear: runtime.clear,
              onDrag: (delta) => setState(() {
                _consoleCollapsed = false;
                _consoleHeight = (_consoleHeight - delta).clamp(
                  90,
                  MediaQuery.sizeOf(context).height * 0.55,
                );
              }),
            ),
            CodingToolbar(controller: controller),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(String current) async {
    final value = await showProgramNameDialog(
      context,
      title: 'Rename program',
      actionLabel: 'Rename',
      initialName: current,
    );
    if (value == null) return;
    try {
      await ref.read(editorSessionProvider).rename(value);
    } catch (error) {
      if (mounted) _showError('Could not rename program: $error');
    }
  }

  Future<void> _newProgram(
    EditorSession session,
    CodeLineEditingController controller,
  ) async {
    session.updateCode(controller.text);
    if (session.current?.id == null && session.dirty) {
      final create = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create a new file?'),
          content: const Text(
            'Your current unsaved draft will be replaced. Save it first if '
            'you want to keep it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (create != true) return;
    }
    try {
      await session.newProgram();
      ref.read(runtimeControllerProvider).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Python file created')),
        );
      }
    } catch (error) {
      if (mounted) _showError('Could not create a new file: $error');
    }
  }

  Future<void> _save(
    EditorSession session,
    CodeLineEditingController controller,
  ) async {
    session.updateCode(controller.text);
    String? newName;
    if (session.current?.id == null) {
      final currentName = session.current!.name;
      newName = await showProgramNameDialog(
        context,
        title: 'Save program',
        actionLabel: 'Save',
        initialName: currentName == 'Untitled' ? '' : currentName,
      );
      if (newName == null) return;
    }
    try {
      if (newName != null) await session.rename(newName);
      await session.saveAsProgram();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${session.current!.name}.py saved')),
        );
      }
    } catch (error) {
      if (mounted) _showError('Could not save program: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _StatusStrip extends StatefulWidget {
  const _StatusStrip({required this.controller, required this.status});
  final CodeLineEditingController controller;
  final PythonRuntimeStatus status;

  @override
  State<_StatusStrip> createState() => _StatusStripState();
}

class _StatusStripState extends State<_StatusStrip> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.addListener(_changed);
    });
  }

  @override
  void didUpdateWidget(covariant _StatusStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.addListener(_changed);
      });
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: Theme.of(context).colorScheme.surfaceContainer,
    child: Row(
      children: [
        Text(
          'Ln ${widget.controller.selection.extentIndex + 1}, Col ${widget.controller.selection.extentOffset + 1}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        Icon(
          widget.status == PythonRuntimeStatus.ready
              ? Icons.check_circle_outline
              : Icons.circle,
          size: 12,
          color: widget.status == PythonRuntimeStatus.error
              ? Colors.red
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 5),
        Text(
          widget.status.label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}

class CodingToolbar extends StatelessWidget {
  const CodingToolbar({super.key, required this.controller});
  final CodeLineEditingController controller;

  static const symbols = [
    '(',
    ')',
    '[',
    ']',
    '{',
    '}',
    ':',
    '"',
    "'",
    '=',
    '_',
    '#',
    '<',
    '>',
    '+',
    '-',
    '*',
    '/',
    '%',
    ',',
    '.',
  ];

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        children: [
          _button(context, 'Tab', controller.applyIndent, wide: true),
          _button(context, '⇤', controller.applyOutdent),
          _button(context, '↶', controller.undo),
          _button(context, '↷', controller.redo),
          for (final symbol in symbols)
            _button(context, symbol, () => _insert(symbol)),
        ],
      ),
    ),
  );

  Widget _button(
    BuildContext context,
    String text,
    VoidCallback action, {
    bool wide = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: SizedBox(
      width: wide ? 52 : 38,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: action,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );

  void _insert(String symbol) {
    const pairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'"};
    final selection = controller.selection;
    final close = pairs[symbol];
    if (close != null) {
      final selected = controller.selectedText;
      controller.replaceSelection('$symbol$selected$close');
      controller.selection = CodeLineSelection.collapsed(
        index: selection.startIndex,
        offset: selection.startOffset + symbol.length + selected.length,
      );
    } else {
      controller.replaceSelection(symbol);
    }
    controller.makeCursorVisible();
  }
}

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({
    required this.height,
    required this.collapsed,
    required this.messages,
    required this.onToggle,
    required this.onClear,
    required this.onDrag,
  });

  final double height;
  final bool collapsed;
  final List<ConsoleMessage> messages;
  final VoidCallback onToggle;
  final VoidCallback onClear;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final text = messages.map((message) => message.text).join();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF171C21)
            : Colors.white,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) => onDrag(details.delta.dy),
            onTap: onToggle,
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Text(
                    'OUTPUT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  if (!collapsed) ...[
                    IconButton(
                      tooltip: 'Clear',
                      visualDensity: VisualDensity.compact,
                      onPressed: onClear,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 19),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      visualDensity: VisualDensity.compact,
                      onPressed: text.isEmpty
                          ? null
                          : () => Clipboard.setData(ClipboardData(text: text)),
                      icon: const Icon(Icons.copy_outlined, size: 18),
                    ),
                  ],
                  Icon(
                    collapsed
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          if (!collapsed)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final color = switch (message.type) {
                    ConsoleMessageType.stderr => Colors.redAccent,
                    ConsoleMessageType.system => Theme.of(
                      context,
                    ).colorScheme.primary,
                    ConsoleMessageType.input => Colors.amber,
                    ConsoleMessageType.stdout => Theme.of(
                      context,
                    ).colorScheme.onSurface,
                  };
                  return SelectableText(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: color,
                      height: 1.35,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
