import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmk_python_ide/features/programs/projects_screen.dart';
import 'package:tmk_python_ide/models/python_program.dart';
import 'package:tmk_python_ide/models/python_project.dart';
import 'package:tmk_python_ide/providers/app_providers.dart';
import 'package:tmk_python_ide/repositories/program_repository.dart';
import 'package:tmk_python_ide/repositories/project_repository.dart';

class _FakeProgramRepository extends ProgramRepository {
  final List<PythonProgram> items = [];
  int nextId = 1;

  @override
  Future<List<PythonProgram>> getAll({
    int? projectId,
    String search = '',
  }) async {
    final query = search.trim().toLowerCase();
    return items
        .where((item) => projectId == null || item.projectId == projectId)
        .where(
          (item) => query.isEmpty || item.name.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Future<PythonProgram?> getById(int id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<PythonProgram> save(PythonProgram program) async {
    if (program.id == null) {
      final saved = program.copyWith(id: nextId++);
      items.add(saved);
      return saved;
    }
    final saved = program;
    final index = items.indexWhere((item) => item.id == program.id);
    if (index == -1) {
      items.add(saved);
    } else {
      items[index] = saved;
    }
    return saved;
  }

  @override
  Future<void> delete(int id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<PythonProgram> duplicate(PythonProgram source) {
    final now = DateTime.now();
    return save(
      PythonProgram(
        projectId: source.projectId,
        folderPath: source.folderPath,
        name: '${source.name} Copy',
        code: source.code,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _FakeProjectRepository extends ProjectRepository {
  final List<PythonProject> items = [];
  int nextId = 1;

  @override
  Future<List<PythonProject>> getAll({String search = ''}) async {
    final query = search.trim().toLowerCase();
    return items
        .where(
          (item) => query.isEmpty || item.name.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Future<PythonProject?> getById(int id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<PythonProject> getDefault() async {
    for (final item in items) {
      if (item.name == 'My Programs') return item;
    }
    final now = DateTime.now();
    return save(
      PythonProject(name: 'My Programs', createdAt: now, updatedAt: now),
    );
  }

  @override
  Future<PythonProject> save(PythonProject project) async {
    if (project.id == null) {
      final saved = project.copyWith(id: nextId++);
      items.add(saved);
      return saved;
    }
    final index = items.indexWhere((item) => item.id == project.id);
    if (index == -1) {
      items.add(project);
    } else {
      items[index] = project;
    }
    return project;
  }

  @override
  Future<void> delete(int id) async {
    items.removeWhere((item) => item.id == id);
  }
}

void main() {
  testWidgets('create a project and land in its file list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final programs = _FakeProgramRepository();
    final projects = _FakeProjectRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programRepositoryProvider.overrideWithValue(programs),
          projectRepositoryProvider.overrideWithValue(projects),
        ],
        child: MaterialApp(home: ProjectsScreen(onOpen: () {})),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No projects yet'), findsOneWidget);

    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'My Calculator');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(projects.items.single.name, 'My Calculator');
    expect(programs.items.single.name, 'main');
    expect(find.text('main.py'), findsOneWidget);
    expect(find.text('My Calculator'), findsWidgets);
  });

  testWidgets('create a Python package inside a project', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final programs = _FakeProgramRepository();
    final projects = _FakeProjectRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programRepositoryProvider.overrideWithValue(programs),
          projectRepositoryProvider.overrideWithValue(projects),
        ],
        child: MaterialApp(home: ProjectsScreen(onOpen: () {})),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Data Lab');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Python package'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'viz/');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final package = programs.items.singleWhere(
      (item) => item.name == '__init__',
    );
    expect(package.folderPath, 'viz');
    expect(find.text('viz'), findsOneWidget);
    expect(find.text('__init__.py'), findsOneWidget);
  });
}