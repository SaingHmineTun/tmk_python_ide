import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/python_program.dart';

class ProgramRepository {
  static const _programsKey = 'web_programs_v1';
  static const _nextIdKey = 'web_programs_next_id_v1';

  Future<List<PythonProgram>> getAll({String search = ''}) async {
    final programs = await _load();
    final query = search.trim().toLowerCase();
    final filtered = query.isEmpty
        ? programs
        : programs
              .where((program) => program.name.toLowerCase().contains(query))
              .toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
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
      final id = prefs.getInt(_nextIdKey) ?? 1;
      saved = program.copyWith(id: id, createdAt: now, updatedAt: now);
      programs.add(saved);
      await prefs.setInt(_nextIdKey, id + 1);
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
        name: '${source.name} Copy',
        code: source.code,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<PythonProgram>> _load([SharedPreferences? preferences]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_programsKey);
    if (raw == null || raw.isEmpty) return <PythonProgram>[];
    final rows = jsonDecode(raw) as List<dynamic>;
    return rows
        .map(
          (row) => PythonProgram.fromMap(
            (row as Map<dynamic, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList();
  }

  Future<void> _write(SharedPreferences prefs, List<PythonProgram> programs) =>
      prefs.setString(
        _programsKey,
        jsonEncode(programs.map((program) => program.toMap()).toList()),
      );
}
