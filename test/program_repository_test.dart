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
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    repository = ProgramRepository(database: () async => database);
  });

  tearDown(() => database.close());

  test('creates, reads, updates, duplicates and deletes a program', () async {
    final now = DateTime.now();
    final created = await repository.save(
      PythonProgram(
        name: 'Hello World',
        code: 'print("Hello")',
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(created.id, isNotNull);
    expect((await repository.getAll()).single.code, 'print("Hello")');

    await repository.save(created.copyWith(code: 'print("မႂ်ႇသုင်ၶႃႈ")'));
    expect((await repository.getById(created.id!))!.code, contains('မႂ်ႇသုင်'));

    await repository.save(created.copyWith(name: 'Renamed Program'));
    expect((await repository.getById(created.id!))!.name, 'Renamed Program');

    final copy = await repository.duplicate(created);
    expect(copy.name, 'Hello World Copy');
    expect(await repository.getAll(), hasLength(2));

    await repository.delete(created.id!);
    expect((await repository.getAll()).single.id, copy.id);
  });

  test('search filters by program name', () async {
    final now = DateTime.now();
    for (final name in ['Calculator', 'Guessing Game']) {
      await repository.save(
        PythonProgram(name: name, code: '', createdAt: now, updatedAt: now),
      );
    }
    expect((await repository.getAll(search: 'calc')).single.name, 'Calculator');
  });
}
