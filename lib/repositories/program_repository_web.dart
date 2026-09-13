import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/python_program.dart';
import 'web_storage_keys.dart';

class ProgramRepository {
  Future<List<PythonProgram>> getAll({
    int? projectId,
    String search = '',
  }) async {
    final programs = await _load();
    final query = search.trim().toLowerCase();
    final filtered = projectId == null
        ? programs
        : programs.where((program) => program.projectId == projectId);
    final matched = query.isEmpty
        ? filtered.toList()
        : filtered
              .where((program) => program.name.toLowerCase().contains(query))
              .toList();
    matched.sort((a, b) {
      final compared = a.folderPath.compareTo(b.folderPath);
      if (compared != 0) return compared;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return matched;
  }

  Future<PythonProgram?> getById(int id) async {
    final programs = await _load();
    for (final program in programs) {
      if (program.id == id) return program;
    }
    return null;
  }

  Future<PythonProgram> save(PythonProgram program) async {
    final prefs = await SharedPreferences.getInstance();
    final programs = await _load(prefs);
    final now = DateTime.now();
    late final PythonProgram saved;
    if (program.id == null) {
      final id = prefs.getInt(WebStorageKeys.programsNextId) ?? 1;
      saved = program.copyWith(id: id, createdAt: now, updatedAt: now);
      programs.add(saved);
      await prefs.setInt(WebStorageKeys.programsNextId, id + 1);
    } else {
      saved = program.copyWith(updatedAt: now);
      final index = programs.indexWhere((item) => item.id == program.id);
      if (index == -1) {
        programs.add(saved);
      } else {
        programs[index] = saved;
      }
    }
    await _write(prefs, programs);
    return saved;
  }

  Future<void> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final programs = await _load(prefs)
      ..removeWhere((program) => program.id == id);
    await _write(prefs, programs);
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

  Future<List<PythonProgram>> _load([SharedPreferences? preferences]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(WebStorageKeys.programs);
    if (raw == null || raw.isEmpty) return <PythonProgram>[];
    final rows = jsonDecode(raw) as List<dynamic>;
    final defaultId = prefs.getInt(WebStorageKeys.defaultProjectId) ?? 1;
    var migrated = false;
    final programs = rows.map((row) {
      final map = (row as Map<dynamic, dynamic>).cast<String, Object?>();
      if (map['project_id'] == null) {
        map['project_id'] = defaultId;
        migrated = true;
      }
      return PythonProgram.fromMap(map);
    }).toList();
    if (migrated) await _write(prefs, programs);
    return programs;
  }

  Future<void> _write(SharedPreferences prefs, List<PythonProgram> programs) =>
      prefs.setString(
        WebStorageKeys.programs,
        jsonEncode(programs.map((program) => program.toMap()).toList()),
      );
}