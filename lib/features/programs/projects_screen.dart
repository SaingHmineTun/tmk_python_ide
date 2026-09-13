import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/python_project.dart';
import '../../providers/app_providers.dart';
import 'project_files_screen.dart';
import 'project_name_dialog.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider(_search));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          IconButton(
            tooltip: 'New project',
            onPressed: _new,
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              hintText: 'Search projects…',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: projects.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Could not load projects: $error')),
              data: (items) => items.isEmpty
                  ? const _EmptyProjects()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(projectsProvider(_search).future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _ProjectTile(
                          project: items[index],
                          onOpen: () => _openProject(items[index]),
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
        label: const Text('New project'),
      ),
    );
  }

  Future<void> _new() async {
    final name = await showProjectNameDialog(
      context,
      title: 'Create project',
      actionLabel: 'Create',
    );
    if (name == null || !mounted) return;
    final project = await ref.read(editorSessionProvider).newProject(name);
    if (!mounted) return;
    _pushProject(project);
  }

  Future<void> _openProject(PythonProject project) async {
    await ref
        .read(editorSessionProvider)
        .setProjectContext(project);
    if (!mounted) return;
    _pushProject(project);
  }

  void _pushProject(PythonProject project) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProjectFilesScreen(
          project: project,
          onOpen: widget.onOpen,
        ),
      ),
    );
  }

  Future<void> _action(String action, PythonProject project) async {
    final repository = ref.read(projectRepositoryProvider);
    try {
      switch (action) {
        case 'rename':
          final name = await _askName(project.name);
          if (name != null) {
            await repository.save(project.copyWith(name: name));
          }
        case 'delete':
          if (await _confirmDelete(project)) {
            await repository.delete(project.id!);
            final session = ref.read(editorSessionProvider);
            if (session.currentProject?.id == project.id) {
              await session.resetProjectContext();
            }
          }
      }
      ref.invalidate(projectsProvider);
      ref.invalidate(programsProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not $action project: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _askName(String current) async {
    return showProjectNameDialog(
      context,
      title: 'Rename project',
      actionLabel: 'Rename',
      initialName: current,
    );
  }

  Future<bool> _confirmDelete(PythonProject project) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete "${project.name}"?'),
          content: const Text(
            'This project and all of its Python files will be permanently deleted.',
          ),
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

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.onOpen,
    required this.onAction,
  });
  final PythonProject project;
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
      child: Icon(
        Icons.folder_outlined,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
    title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(_updatedLabel(project.updatedAt)),
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

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 56),
          SizedBox(height: 16),
          Text(
            'No projects yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Create a project to organize your Python files.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}