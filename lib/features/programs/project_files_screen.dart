import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/python_program.dart';
import '../../models/python_project.dart';
import '../../providers/app_providers.dart';
import 'file_create_dialog.dart';
import 'program_name_dialog.dart';
import 'project_name_dialog.dart';

class ProjectFilesScreen extends ConsumerStatefulWidget {
  const ProjectFilesScreen({
    super.key,
    required this.project,
    required this.onOpen,
  });
  final PythonProject project;
  final VoidCallback onOpen;

  @override
  ConsumerState<ProjectFilesScreen> createState() => _ProjectFilesScreenState();
}

class _ProjectFilesScreenState extends ConsumerState<ProjectFilesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(
      programsProvider(programsKey(widget.project.id!, _search)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) => _moreAction(value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'package',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder_outlined),
                  title: Text('New Python package'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload_file_outlined),
                  title: Text('Import .py'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              hintText: 'Search files in project…',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: programs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Could not load files: $error'),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyFiles()
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(
                        programsProvider(
                          programsKey(widget.project.id!, _search),
                        ).future,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                        children: _buildEntries(items),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newFile,
        icon: const Icon(Icons.add),
        label: const Text('New file'),
      ),
    );
  }

  List<Widget> _buildEntries(List<PythonProgram> items) {
    final rootFiles = items
        .where((item) => item.folderPath.isEmpty)
        .toList()
      ..sort(_compare);
    final folders = items
        .map((item) => item.folderPath)
        .where((folder) => folder.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final children = <Widget>[
      for (final file in rootFiles) _fileTile(file),
    ];
    for (final folder in folders) {
      final files = items.where((item) => item.folderPath == folder).toList()
        ..sort(_compare);
      children.add(_FolderHeader(name: folder, count: files.length));
      for (final file in files) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 18),
          child: _fileTile(file),
        ));
      }
    }
    return children;
  }

  int _compare(PythonProgram a, PythonProgram b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  Future<void> _newFile() async {
    final result = await showFileCreateDialog(
      context,
      title: 'Create Python file',
      actionLabel: 'Create',
    );
    if (result == null || !mounted) return;
    final session = ref.read(editorSessionProvider);
    try {
      await session.newProgram(
        projectId: widget.project.id!,
        name: result.name,
        folderPath: result.folder,
      );
      await session.saveAsProgram();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.name}.py created')),
      );
    } catch (error) {
      if (mounted) _showError('Could not create file: $error');
    }
  }

  Future<void> _newPackage() async {
    final name = await showProjectNameDialog(
      context,
      title: 'Create Python package',
      actionLabel: 'Create',
    );
    if (name == null || !mounted) return;
    final now = DateTime.now();
    try {
      await ref.read(programRepositoryProvider).save(
        PythonProgram(
          projectId: widget.project.id!,
          folderPath: normalizeFolderPath(name),
          name: '__init__',
          code: '# $name package\n',
          createdAt: now,
          updatedAt: now,
        ),
      );
      ref.invalidate(programsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package "$name" created')),
      );
    } catch (error) {
      if (mounted) _showError('Could not create package: $error');
    }
  }

  Future<void> _importFile() async {
    final imported = await ref.read(programFileServiceProvider).importPython();
    if (imported == null || !mounted) return;
    final now = DateTime.now();
    try {
      await ref.read(programRepositoryProvider).save(
        PythonProgram(
          projectId: widget.project.id!,
          folderPath: '',
          name: imported.name,
          code: imported.code,
          createdAt: now,
          updatedAt: now,
        ),
      );
      ref.invalidate(programsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.name}.py imported')),
      );
    } catch (error) {
      if (mounted) _showError('Could not import file: $error');
    }
  }

  Future<void> _moreAction(String value) async {
    switch (value) {
      case 'package':
        await _newPackage();
      case 'import':
        await _importFile();
    }
  }

  Future<void> _open(PythonProgram program) async {
    await ref.read(editorSessionProvider).open(program);
    widget.onOpen();
  }

  Future<void> _rename(PythonProgram program) async {
    final name = await showProgramNameDialog(
      context,
      title: 'Rename file',
      actionLabel: 'Rename',
      initialName: program.name,
    );
    if (name == null || !mounted) return;
    try {
      await ref.read(editorSessionProvider).renameProgram(program, name);
    } catch (error) {
      if (mounted) _showError('Could not rename file: $error');
    }
  }

  Future<void> _action(String action, PythonProgram program) async {
    final repository = ref.read(programRepositoryProvider);
    final session = ref.read(editorSessionProvider);
    try {
      switch (action) {
        case 'rename':
          await _rename(program);
        case 'duplicate':
          await repository.duplicate(program);
        case 'delete':
          if (await _confirmDelete(program)) {
            await repository.delete(program.id!);
            if (session.current?.id == program.id) {
              await session.newProgram(projectId: widget.project.id!);
            }
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
          content: Text('Could not $action file: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _confirmDelete(PythonProgram program) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete "${program.name}.py"?'),
          content: const Text('This file will be permanently deleted.'),
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

  Widget _fileTile(PythonProgram program) {
    final displayName = program.name == '__init__'
        ? '__init__.py'
        : '${program.name}.py';
    return ListTile(
      onTap: () => _open(program),
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
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_updatedLabel(program.updatedAt)),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _action(action, program),
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
  }

  String _updatedLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    if (DateUtils.isSameDay(local, now)) return 'Updated today';
    if (DateUtils.isSameDay(local, now.subtract(const Duration(days: 1)))) {
      return 'Updated yesterday';
    }
    return 'Updated ${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
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

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({required this.name, required this.count});
  final String name;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 8, 4),
    child: Row(
      children: [
        Icon(
          Icons.folder_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _EmptyFiles extends StatelessWidget {
  const _EmptyFiles();
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
            'No Python files yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Create a Python file or package to get started.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}