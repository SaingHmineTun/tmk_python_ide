import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../models/python_project.dart';

class ProjectRepository {
  ProjectRepository({Future<Database> Function()? database})
    : _database = database ?? (() => AppDatabase.instance.database);

  final Future<Database> Function() _database;

  Future<List<PythonProject>> getAll({String search = ''}) async {
    final db = await _database();
    final rows = await db.query(
      'projects',
      where: search.trim().isEmpty ? null : 'name LIKE ? COLLATE NOCASE',
      whereArgs: search.trim().isEmpty ? null : ['%${search.trim()}%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(PythonProject.fromMap).toList(growable: false);
  }

  Future<PythonProject?> getById(int id) async {
    final db = await _database();
    final rows = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : PythonProject.fromMap(rows.first);
  }

  Future<PythonProject> getDefault() async {
    final db = await _database();
    final rows = await db.query(
      'projects',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [AppDatabase.defaultProjectName],
      limit: 1,
    );
    if (rows.isNotEmpty) return PythonProject.fromMap(rows.first);
    final now = DateTime.now();
    return save(
      PythonProject(
        name: AppDatabase.defaultProjectName,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<PythonProject> save(PythonProject project) async {
    final db = await _database();
    final now = DateTime.now();
    if (project.id == null) {
      final saved = project.copyWith(createdAt: now, updatedAt: now);
      final id = await db.insert(
        'projects',
        saved.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return saved.copyWith(id: id);
    }
    final saved = project.copyWith(updatedAt: now);
    await db.update(
      'projects',
      saved.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
    return saved;
  }

  Future<void> delete(int id) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete('programs', where: 'project_id = ?', whereArgs: [id]);
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
  }
}