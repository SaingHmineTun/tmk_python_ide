import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../models/python_program.dart';

class ProgramRepository {
  ProgramRepository({Future<Database> Function()? database})
    : _database = database ?? (() => AppDatabase.instance.database);

  final Future<Database> Function() _database;

  Future<List<PythonProgram>> getAll({
    int? projectId,
    String search = '',
  }) async {
    final db = await _database();
    final where = <String>[];
    final args = <Object?>[];
    if (projectId != null) {
      where.add('project_id = ?');
      args.add(projectId);
    }
    if (search.trim().isNotEmpty) {
      where.add('name LIKE ? COLLATE NOCASE');
      args.add('%${search.trim()}%');
    }
    final rows = await db.query(
      'programs',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return _organize(rows.map(PythonProgram.fromMap).toList());
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
        projectId: source.projectId,
        folderPath: source.folderPath,
        name: '${source.name} Copy',
        code: source.code,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Sorts root files first, then files grouped by folder, each group
  /// alphabetically.
  List<PythonProgram> _organize(List<PythonProgram> programs) {
    programs.sort((a, b) {
      final compared = a.folderPath.compareTo(b.folderPath);
      if (compared != 0) return compared;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return programs;
  }
}