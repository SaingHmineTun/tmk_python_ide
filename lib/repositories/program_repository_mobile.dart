import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../models/python_program.dart';

class ProgramRepository {
  ProgramRepository({Future<Database> Function()? database})
    : _database = database ?? (() => AppDatabase.instance.database);

  final Future<Database> Function() _database;

  Future<List<PythonProgram>> getAll({String search = ''}) async {
    final db = await _database();
    final rows = await db.query(
      'programs',
      where: search.trim().isEmpty ? null : 'name LIKE ? COLLATE NOCASE',
      whereArgs: search.trim().isEmpty ? null : ['%${search.trim()}%'],
      orderBy: 'updated_at DESC',
    );
    return rows.map(PythonProgram.fromMap).toList(growable: false);
  }

  Future<PythonProgram?> getById(int id) async {
    final db = await _database();
    final rows = await db.query(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : PythonProgram.fromMap(rows.first);
  }

  Future<PythonProgram> save(PythonProgram program) async {
    final db = await _database();
    final now = DateTime.now();
    if (program.id == null) {
      final saved = program.copyWith(createdAt: now, updatedAt: now);
      final id = await db.insert(
        'programs',
        saved.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return saved.copyWith(id: id);
    }
    final saved = program.copyWith(updatedAt: now);
    await db.update(
      'programs',
      saved.toMap(),
      where: 'id = ?',
      whereArgs: [program.id],
    );
    return saved;
  }

  Future<void> delete(int id) async {
    final db = await _database();
    await db.delete('programs', where: 'id = ?', whereArgs: [id]);
  }

  Future<PythonProgram> duplicate(PythonProgram source) {
    final now = DateTime.now();
    return save(
      PythonProgram(
        name: '${source.name} Copy',
        code: source.code,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
