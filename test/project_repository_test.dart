import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tmk_python_ide/core/database/app_database.dart';
import 'package:tmk_python_ide/models/python_program.dart';
import 'package:tmk_python_ide/models/python_project.dart';
import 'package:tmk_python_ide/repositories/project_repository.dart';

void main() {
  late Database database;
  late ProjectRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        folder_path TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    repository = ProjectRepository(database: () async => database);
  });

  tearDown(() => database.close());

  test('creates, renames, reads and deletes a project', () async {
    final now = DateTime.now();
    final created = await repository.save(
      PythonProject(name: 'Calculator', createdAt: now, updatedAt: now),
    );
    expect(created.id, isNotNull);
    expect((await repository.getAll()).single.name, 'Calculator');

    final renamed = await repository.save(created.copyWith(name: 'Math Lab'));
    expect((await repository.getById(created.id!))!.name, 'Math Lab');
    expect(renamed.name, 'Math Lab');

    await repository.delete(created.id!);
    expect(await repository.getAll(), isEmpty);
  });

  test('deleting a project deletes its programs too', () async {
    final now = DateTime.now();
    final project = await repository.save(
      PythonProject(name: 'Game', createdAt: now, updatedAt: now),
    );
    await database.insert('programs', {
      'project_id': project.id!,
      'folder_path': '',
      'name': 'main',
      'code': 'print(1)',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await database.insert('programs', {
      'project_id': 999,
      'folder_path': '',
      'name': 'other',
      'code': '',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await repository.delete(project.id!);
    final rows = await database.query('programs');
    expect(rows.single['name'], 'other');
    expect(await repository.getAll(), isEmpty);
  });

  test('getDefault returns the default project', () async {
    final defaultProject = await repository.getDefault();
    expect(defaultProject.id, isNotNull);
    expect(defaultProject.name, AppDatabase.defaultProjectName);
    expect((await repository.getAll()).single.name, AppDatabase.defaultProjectName);
  });

  test('search filters by project name', () async {
    final now = DateTime.now();
    for (final name in ['Calculator', 'Guessing Game']) {
      await repository.save(
        PythonProject(name: name, createdAt: now, updatedAt: now),
      );
    }
    expect((await repository.getAll(search: 'calc')).single.name, 'Calculator');
  });

  test('PythonProgram round-trips through the projects table', () async {
    final now = DateTime.now();
    final project = await repository.save(
      PythonProject(name: 'Data', createdAt: now, updatedAt: now),
    );
    final program = PythonProgram(
      projectId: project.id!,
      folderPath: 'analysis',
      name: 'stats',
      code: 'import statistics',
      createdAt: now,
      updatedAt: now,
    );
    final id = await database.insert('programs', program.toMap());
    final restored = PythonProgram.fromMap(
      (await database.query('programs', where: 'id = ?', whereArgs: [id]))
          .single,
    );
    expect(restored.projectId, project.id);
    expect(restored.folderPath, 'analysis');
    expect(restored.code, 'import statistics');
  });
}