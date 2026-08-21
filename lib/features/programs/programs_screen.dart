import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/python_program.dart';
import '../../providers/app_providers.dart';
import 'program_name_dialog.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsProvider(_search));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Programs'),
        actions: [
          IconButton(
            tooltip: 'Import .py',
            onPressed: _import,
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: 'New program',
            onPressed: _new,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              hintText: 'Search programs…',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: programs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Could not load programs: $error')),
              data: (items) => items.isEmpty
                  ? const _EmptyPrograms()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(programsProvider(_search).future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _ProgramTile(
                          program: items[index],
                          onOpen: () => _open(items[index]),
                          onAction: (action) => _action(action, items[index]),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _new,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  Future<void> _new() async {
    final name = await showProgramNameDialog(
      context,
      title: 'Create Python file',
      actionLabel: 'Create',
    );
    if (name == null) return;
    final session = ref.read(editorSessionProvider);
    await session.newProgram(name: name);
    await session.saveAsProgram();
    widget.onOpen();
  }

  Future<void> _open(PythonProgram program) async {
    await ref.read(editorSessionProvider).open(program);
    widget.onOpen();
  }

  Future<void> _import() async {
    final imported = await ref.read(programFileServiceProvider).importPython();
    if (imported == null) return;
    await ref
        .read(editorSessionProvider)
        .newProgram(name: imported.name, code: imported.code);
    await ref.read(editorSessionProvider).saveAsProgram();
    widget.onOpen();
  }

  Future<void> _action(String action, PythonProgram program) async {
    final repository = ref.read(programRepositoryProvider);
    try {
      switch (action) {
        case 'rename':
          final name = await _askName(program.name);
          if (name != null) {
            await ref.read(editorSessionProvider).renameProgram(program, name);
          }
        case 'duplicate':
          await repository.duplicate(program);
        case 'delete':
          if (await _confirmDelete(program)) {
            await repository.delete(program.id!);
          }
        case 'shareText':
          await ref.read(programFileServiceProvider).shareText(program);
        case 'shareFile':
          await ref.read(programFileServiceProvider).shareFile(program);
        case 'export':
          await ref.read(programFileServiceProvider).exportFile(program);
      }
      ref.invalidate(programsProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not $action program: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _askName(String current) async {
    return showProgramNameDialog(
      context,
      title: 'Rename program',
      actionLabel: 'Rename',
      initialName: current,
    );
  }

  Future<bool> _confirmDelete(PythonProgram program) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete "${program.name}"?'),
          content: const Text('This program will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({
    required this.program,
    required this.onOpen,
    required this.onAction,
  });
  final PythonProgram program;
  final VoidCallback onOpen;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onOpen,
    leading: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'py',
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
    ),
    title: Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(_updatedLabel(program.updatedAt)),
    trailing: PopupMenuButton<String>(
      onSelected: onAction,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Rename'),
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy_all_outlined),
            title: Text('Duplicate'),
          ),
        ),
        PopupMenuItem(
          value: 'shareText',
          child: ListTile(
            leading: Icon(Icons.text_snippet_outlined),
            title: Text('Share code'),
          ),
        ),
        PopupMenuItem(
          value: 'shareFile',
          child: ListTile(
            leading: Icon(Icons.share_outlined),
            title: Text('Share .py file'),
          ),
        ),
        PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.download_outlined),
            title: Text('Export .py'),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
          ),
        ),
      ],
    ),
  );

  String _updatedLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    if (DateUtils.isSameDay(local, now)) return 'Updated today';
    if (DateUtils.isSameDay(local, now.subtract(const Duration(days: 1)))) {
      return 'Updated yesterday';
    }
    return 'Updated ${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyPrograms extends StatelessWidget {
  const _EmptyPrograms();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code, size: 56),
          SizedBox(height: 16),
          Text(
            'No saved programs yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Create a program and start writing Python.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
