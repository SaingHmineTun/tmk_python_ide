import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const defaultProjectName = 'My Programs';
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      p.join(root, 'tmk_python_ide.db'),
      version: 2,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
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
    await db.insert(
      'projects',
      {'name': defaultProjectName, 'created_at': now, 'updated_at': now},
    );
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'ALTER TABLE programs ADD COLUMN project_id INTEGER',
      );
      await db.execute(
        "ALTER TABLE programs ADD COLUMN folder_path TEXT NOT NULL DEFAULT ''",
      );
      final now = DateTime.now().toIso8601String();
      final id = await db.insert(
        'projects',
        {'name': defaultProjectName, 'created_at': now, 'updated_at': now},
      );
      await db.update(
        'programs',
        {'project_id': id},
        where: 'project_id IS NULL',
      );
    }
  }
}