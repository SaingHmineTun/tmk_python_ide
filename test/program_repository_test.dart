import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tmk_python_ide/models/python_program.dart';
import 'package:tmk_python_ide/repositories/program_repository.dart';

void main() {
  late Database database;
  late ProgramRepository repository;

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
    final now = DateTime.now().toIso8601String();
    await database.insert(
      'projects',
      {'name': 'Alpha', 'created_at': now, 'updated_at': now},
    );
    await database.insert(
      'projects',
      {'name': 'Beta', 'created_at': now, 'updated_at': now},
    );
    repository = ProgramRepository(database: () async => database);
  });

  tearDown(() => database.close());

  PythonProgram newProgram({
    required int projectId,
    String name = 'module',
    String code = '',
    String folderPath = '',
  }) {
    final now = DateTime.now();
    return PythonProgram(
      projectId: projectId,
      folderPath: folderPath,
      name: name,
      code: code,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('creates, reads, updates, duplicates and deletes a program', () async {
    final created = await repository.save(newProgram(projectId: 1));
    expect(created.id, isNotNull);
    expect((await repository.getAll(projectId: 1)).single.code, '');

    await repository.save(created.copyWith(code: 'print("မႂ်ႇသုင်ၶႃႈ")'));
    expect(
      (await repository.getById(created.id!))!.code,
      contains('မႂ်ႇသုင်'),
    );

    await repository.save(created.copyWith(name: 'Renamed Program'));
    expect((await repository.getById(created.id!))!.name, 'Renamed Program');

    final copy = await repository.duplicate(created);
    expect(copy.name, 'module Copy');
    expect(copy.projectId, 1);
    expect(await repository.getAll(projectId: 1), hasLength(2));

    await repository.delete(created.id!);
    expect((await repository.getAll(projectId: 1)).single.id, copy.id);
  });

  test('search filters by program name within a project', () async {
    for (final name in ['Calculator', 'Guessing Game']) {
      await repository.save(newProgram(projectId: 1, name: name));
    }
    expect(
      (await repository.getAll(projectId: 1, search: 'calc')).single.name,
      'Calculator',
    );
  });

  test('getAll is scoped to a project', () async {
    await repository.save(newProgram(projectId: 1, name: 'alpha_mod'));
    await repository.save(newProgram(projectId: 2, name: 'beta_mod'));
    final alpha = await repository.getAll(projectId: 1);
    final all = await repository.getAll();
    expect(alpha.single.name, 'alpha_mod');
    expect(all.map((program) => program.name), containsAll(['alpha_mod', 'beta_mod']));
  });

  test('getAll keeps folders grouped with root files first', () async {
    await repository.save(
      newProgram(projectId: 1, name: 'helpers', folderPath: 'utils'),
    );
    await repository.save(newProgram(projectId: 1, name: 'main'));
    await repository.save(
      newProgram(projectId: 1, name: 'geometry', folderPath: 'math'),
    );
    final names = (await repository.getAll(projectId: 1))
        .map((program) => program.name)
        .toList();
    expect(names, ['main', 'geometry', 'helpers']);
  });
}